#!/usr/bin/env python3
"""Local calendar adapter: serialized provider access, private cache, reminders.

Providers
---------
proton  Local proton-cal CLI (read/write), signing in with ~/.config/proton-cal.
ics     Read-only iCalendar subscriptions. One entry covers a Google Calendar
        "secret address in iCal format", a Proton Calendar share link, a CalDAV
        export, or any other ICS URL.

The active provider is stored in ~/.config/quickshell-calendar/config.toml. When
that file does not name one, the provider is auto-detected so an existing Proton
sign-in keeps working without reconnecting.
"""
import datetime as dt
import fcntl
import hashlib
import html
import json
import os
from pathlib import Path
import queue
import re
import socket
import socketserver
import subprocess
import sys
import threading
import time
import tomllib
import urllib.parse
import urllib.request
from zoneinfo import ZoneInfo

HOME = Path.home()
DATA = HOME / '.local/state/quickshell-calendar'
SOCKET = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')) / 'quickshell-calendar.sock'
CLI = HOME / '.local/bin/proton-cal'
STATE = DATA / 'state.json'
SENT = DATA / 'reminders.json'
CONFIG = HOME / '.config/quickshell-calendar/config.toml'
PROTON_SESSION = HOME / '.config/proton-cal/session.json'

try:
    from dateutil.rrule import rrulestr as _rrulestr
except Exception:  # pragma: no cover - optional dependency
    _rrulestr = None


# --- provider configuration -------------------------------------------------

def read_config():
    try:
        return tomllib.loads(CONFIG.read_text())
    except (OSError, ValueError):
        return {}


def write_config(cfg):
    lines = []
    if cfg.get('provider'):
        lines.append('provider = ' + json.dumps(cfg['provider']))
    for source in cfg.get('ics', []):
        lines += ['', '[[ics]]', 'name = ' + json.dumps(source.get('name', '')),
                  'url = ' + json.dumps(source.get('url', ''))]
    CONFIG.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    tmp = CONFIG.with_suffix('.tmp')
    tmp.write_text('\n'.join(lines) + '\n')
    os.chmod(tmp, 0o600)
    tmp.replace(CONFIG)


def ics_sources(cfg=None):
    sources = []
    for item in (cfg or read_config()).get('ics', []) or []:
        if isinstance(item, dict) and item.get('url'):
            sources.append({'name': item.get('name') or item['url'], 'url': item['url']})
    return sources


def detect_provider(cfg=None):
    cfg = cfg if cfg is not None else read_config()
    if cfg.get('provider') in ('proton', 'ics'):
        return cfg['provider']
    if PROTON_SESSION.is_file():
        return 'proton'
    if ics_sources(cfg):
        return 'ics'
    return ''


def provider_ready(cfg=None):
    provider = detect_provider(cfg)
    if provider == 'proton':
        return PROTON_SESSION.is_file()
    if provider == 'ics':
        return bool(ics_sources(cfg))
    return False


# --- time helpers -----------------------------------------------------------

def read(path, default):
    try: return json.loads(path.read_text())
    except (OSError, ValueError): return default

def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    tmp = path.with_suffix('.tmp')
    with tmp.open('w') as f:
        os.chmod(tmp, 0o600)
        json.dump(data, f); f.flush(); os.fsync(f.fileno())
    tmp.replace(path)

def timezone():
    try:
        cfg = tomllib.loads((HOME / '.config/proton-cal/config.toml').read_text())
        if cfg.get('timezone'): return ZoneInfo(cfg['timezone'])
    except (OSError, ValueError, KeyError): pass
    try:
        cfg = read_config()
        if cfg.get('timezone'): return ZoneInfo(cfg['timezone'])
    except (ValueError, KeyError): pass
    try: return ZoneInfo(str(Path('/etc/localtime').resolve()).split('/zoneinfo/')[1])
    except (IndexError, ValueError, KeyError): return ZoneInfo('UTC')

def timestamp(value, all_day=False, zone=None):
    parsed = dt.datetime.fromisoformat(value.replace('Z', '+00:00'))
    if all_day: parsed = dt.datetime.combine(parsed.date(), dt.time(), tzinfo=zone or timezone())
    elif parsed.tzinfo is None: parsed = parsed.replace(tzinfo=zone or timezone())
    return parsed.timestamp()

def duration(value):
    match = re.fullmatch(r'([+-]?)P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?', value)
    if not match: raise ValueError('Unsupported reminder duration')
    sign, weeks, days, hours, minutes, seconds = match.groups()
    value = sum(int(n or 0) * factor for n, factor in zip((weeks,days,hours,minutes,seconds),(604800,86400,3600,60,1)))
    return -value if sign == '-' else value

def normalize(events, zone):
    result = []
    for event in events:
        start = timestamp(event['start'], event.get('all_day', False), zone)
        end = timestamp(event['end'], event.get('all_day', False), zone)
        # Keep only fields needed by the desktop; no attendees or conferencing credentials.
        result.append({k:event[k] for k in ('id','uid','calendar_id','calendar_name','summary','location','start','end','all_day','recurring','notifications') if k in event} | {'start_ts':start,'end_ts':end,'first_day':dt.datetime.fromtimestamp(start,zone).date().isoformat(),'last_day':dt.datetime.fromtimestamp(max(start,end-1),zone).date().isoformat(),'time_label':dt.datetime.fromtimestamp(start,zone).strftime('%H:%M')})
    return sorted(result, key=lambda e:e['start_ts'])

def due_reminders(events, now, sent, zone=None):
    result=[]
    for e in events:
        start=e.get('start_ts', timestamp(e['start'],e.get('all_day',False),zone))
        for n in e.get('notifications',[]):
            if n.get('type') != 'notify': continue
            try: due=start+duration(n['trigger'])
            except (ValueError,KeyError): continue
            key=hashlib.sha256(json.dumps([e.get('calendar_id'),e.get('uid') or e['id'],start,n['trigger']]).encode()).hexdigest()
            # Catch up briefly after suspend/restart, but never flood old reminders.
            if due <= now < due+900 and key not in sent: result.append((key,e,due))
    return result


# --- iCalendar (ICS) parsing ------------------------------------------------

def fetch_ics(url):
    if url.startswith('webcal://'):
        url = 'https://' + url[len('webcal://'):]
    if not re.match(r'^https?://', url):
        raise ValueError('Only http(s) or webcal subscription URLs are supported')
    try:
        import requests
        response = requests.get(url, timeout=30, headers={'User-Agent': 'quickshell-calendar/1'})
        response.raise_for_status()
        return response.text
    except ImportError:
        with urllib.request.urlopen(url, timeout=30) as resp:
            return resp.read().decode('utf-8', 'replace')

def _unfold(text):
    lines = []
    for line in text.replace('\r\n', '\n').replace('\r', '\n').split('\n'):
        if line[:1] in (' ', '\t') and lines:
            lines[-1] += line[1:]
        else:
            lines.append(line)
    return lines

def _split(line):
    if ':' not in line: return None
    head, value = line.split(':', 1)
    parts = head.split(';')
    params = {}
    for part in parts[1:]:
        if '=' in part:
            key, val = part.split('=', 1)
            params[key.upper()] = val.strip('"')
    return parts[0].upper(), params, value

def _unescape(value):
    return (value.replace('\\n', '\n').replace('\\N', '\n').replace('\\,', ',')
            .replace('\\;', ';').replace('\\\\', '\\'))

def _parse_dt(value, params, zone):
    if params.get('VALUE') == 'DATE' or (len(value) == 8 and value.isdigit()):
        day = dt.datetime.strptime(value, '%Y%m%d').date()
        return dt.datetime.combine(day, dt.time(), tzinfo=zone), True
    fmt = '%Y%m%dT%H%M%SZ' if value.endswith('Z') else ('%Y%m%dT%H%M%S' if len(value) >= 15 else '%Y%m%dT%H%M')
    parsed = dt.datetime.strptime(value, fmt)
    if value.endswith('Z'):
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    else:
        tzid = params.get('TZID')
        try: parsed = parsed.replace(tzinfo=ZoneInfo(tzid) if tzid else zone)
        except (KeyError, ValueError): parsed = parsed.replace(tzinfo=zone)
    return parsed.astimezone(zone), False

def _add_months(moment, months):
    month = moment.month - 1 + months
    year = moment.year + month // 12
    month = month % 12 + 1
    day = min(moment.day, [31,29 if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0) else 28,31,30,31,30,31,31,30,31,30,31][month-1])
    return moment.replace(year=year, month=month, day=day)

def _until(value, zone):
    try: return _parse_dt(value, {}, zone)[0]
    except ValueError: return None

def _expand_fallback(start, span, rrule, window_start, window_end):
    parts = dict(p.split('=', 1) for p in rrule.split(';') if '=' in p)
    freq = parts.get('FREQ', ''); interval = int(parts.get('INTERVAL', 1) or 1)
    count = int(parts['COUNT']) if parts.get('COUNT') else None
    until = _until(parts['UNTIL'], start.tzinfo) if parts.get('UNTIL') else None
    out = []; current = start; index = 0
    while current <= window_end and index < 2000:
        if count is not None and index >= count: break
        if until and current > until: break
        if current >= window_start: out.append((current, current + span))
        index += 1
        if freq == 'DAILY': current += dt.timedelta(days=interval)
        elif freq == 'WEEKLY': current += dt.timedelta(weeks=interval)
        elif freq == 'MONTHLY': current = _add_months(current, interval)
        elif freq == 'YEARLY': current = _add_months(current, 12 * interval)
        else: break
    return out

def expand(start, end, rrule, window_start, window_end):
    span = end - start
    if not rrule:
        return [(start, end)]
    if _rrulestr is not None:
        try:
            rule = _rrulestr(rrule, dtstart=start)
            return [(occ, occ + span) for occ in rule.between(window_start, window_end, inc=True)]
        except (ValueError, TypeError):
            pass
    return _expand_fallback(start, span, rrule, window_start, window_end)

def parse_ics(text, calendar_id, calendar_name, zone, window_start, window_end):
    window_start = dt.datetime.combine(window_start, dt.time(), tzinfo=zone)
    window_end = dt.datetime.combine(window_end, dt.time(), tzinfo=zone)
    events = []; current = None

    def flush(event):
        if not event or 'DTSTART' not in event: return
        start, all_day = event['DTSTART']
        end = event['DTEND'][0] if 'DTEND' in event else (start + dt.timedelta(days=1) if all_day else start)
        uid = event.get('UID', ('', {}))[0] or f'{calendar_id}-{len(events)}'
        summary = _unescape(event['SUMMARY'][0]) if 'SUMMARY' in event else ''
        location = _unescape(event['LOCATION'][0]) if 'LOCATION' in event else ''
        alarms = [{'type': 'notify', 'trigger': trigger}
                  for action, trigger in event.get('ALARMS', []) if action == 'DISPLAY' and trigger]
        rrule = event['RRULE'][0] if 'RRULE' in event else ''
        for occ_start, occ_end in expand(start, end, rrule, window_start, window_end):
            events.append({
                'id': f'{calendar_id}:{uid}:{occ_start.isoformat()}',
                'uid': uid, 'calendar_id': calendar_id, 'calendar_name': calendar_name,
                'summary': summary, 'location': location,
                'start': occ_start.isoformat(), 'end': occ_end.isoformat(),
                'all_day': all_day, 'recurring': bool(rrule), 'notifications': alarms,
            })

    for line in _unfold(text):
        if line == 'BEGIN:VEVENT':
            current = {}
        elif line == 'END:VEVENT':
            flush(current); current = None
        elif line == 'BEGIN:VALARM':
            current = (current or {})
            current['_alarm'] = {}
        elif line == 'END:VALARM':
            if current is not None and '_alarm' in current:
                alarm = current.pop('_alarm')
                current.setdefault('ALARMS', []).append((alarm.get('ACTION', ''), alarm.get('TRIGGER', '')))
        elif current is not None:
            parsed = _split(line)
            if not parsed: continue
            name, params, value = parsed
            if '_alarm' in current:
                if name in ('ACTION', 'TRIGGER'):
                    current['_alarm'][name] = value.split(';')[0]
            elif name in ('DTSTART', 'DTEND'):
                try: current[name] = _parse_dt(value, params, zone)
                except ValueError: pass
            elif name in ('UID', 'SUMMARY', 'LOCATION', 'RRULE'):
                current[name] = (value, params)
    return events


# --- bridge -----------------------------------------------------------------

class Bridge:
    def __init__(self):
        self.guard=threading.RLock(); self.jobs=queue.Queue(maxsize=16)
        self.month=dt.datetime.now().strftime('%Y-%m')
        self.state=read(STATE,{})
        self.state.update(busy=False,actionBusy=False,actionResult='',message=self.state.get('message') or 'Press Sync to fetch events.')
        self.state.setdefault('events',[]); self.state.setdefault('calendars',[])
        self.state.setdefault('lastSync',0)
        self.reminders=read(DATA/'upcoming.json',[])
        self.sent=read(SENT,{})
        self.update()
    def update(self, **fields):
        with self.guard:
            self.state.update(fields)
            provider=detect_provider()
            self.state['provider']=provider
            self.state['providerLabel']={'proton':'Proton','ics':'Subscription'}.get(provider,'')
            self.state['authenticated']=provider_ready()
            write(STATE,self.state)
    def call(self,args):
        completed=subprocess.run([str(CLI),*args,'-o','json'],capture_output=True,text=True,timeout=120,stdin=subprocess.DEVNULL)
        if completed.returncode:
            raise RuntimeError('Proton request failed. Retry Sync or reconnect your account.')
        return json.loads(completed.stdout)
    def not_connected(self):
        self.reminders=[]
        self.update(events=[],calendars=[],message='Connect a calendar to show your events.',busy=False)
    def sync(self):
        provider=detect_provider()
        if provider=='proton': return self.sync_proton()
        if provider=='ics': return self.sync_ics()
        self.not_connected()
    def sync_proton(self):
        if not PROTON_SESSION.is_file():
            self.not_connected()
            return
        self.update(busy=True,message='Syncing Proton…')
        try:
            zone=timezone(); now=dt.datetime.now(zone)
            calendars=self.call(['calendars'])
            upcoming=normalize(self.call(['events','--all-calendars','--from',(now.date()-dt.timedelta(days=1)).isoformat(),'--days','63','--tz',str(zone)]),zone)
            month_start=dt.date.fromisoformat(self.month+'-01')
            display_start=month_start-dt.timedelta(days=month_start.weekday())
            display_end=display_start+dt.timedelta(days=42)
            if display_start >= now.date()-dt.timedelta(days=1) and display_end <= now.date()+dt.timedelta(days=62):
                display=upcoming
            else:
                display=normalize(self.call(['events','--all-calendars','--from',display_start.isoformat(),'--days','42','--tz',str(zone)]),zone)
            with self.guard: self.reminders=upcoming
            write(DATA/'upcoming.json',upcoming)
            self.update(events=display,calendars=calendars,month=self.month,timezone=str(zone),lastSync=time.time(),message='Synced · '+now.strftime('%H:%M'),busy=False)
        except (RuntimeError,ValueError,KeyError,OSError,subprocess.TimeoutExpired):
            self.update(busy=False,message='Sync failed · cached events shown. Retry Sync or reconnect.')
    def sync_ics(self):
        cfg=read_config(); sources=ics_sources(cfg)
        if not sources:
            self.not_connected()
            return
        self.update(busy=True,message='Syncing calendar…')
        try:
            zone=timezone(); now=dt.datetime.now(zone)
            calendars=[]; raw=[]
            for index, source in enumerate(sources):
                calendar_id=f'ics{index}'
                text=fetch_ics(source['url'])
                raw+=parse_ics(text,calendar_id,source['name'],zone,now.date()-dt.timedelta(days=1),now.date()+dt.timedelta(days=63))
                calendars.append({'id':calendar_id,'name':source['name'],'type':1,'is_default':False})
            upcoming=normalize(raw,zone)
            month_start=dt.date.fromisoformat(self.month+'-01')
            display_start=month_start-dt.timedelta(days=month_start.weekday())
            display_end=display_start+dt.timedelta(days=42)
            display=[e for e in upcoming if e['first_day']<=display_end.isoformat() and e['last_day']>=display_start.isoformat()]
            with self.guard: self.reminders=upcoming
            write(DATA/'upcoming.json',upcoming)
            self.update(events=display,calendars=calendars,month=self.month,timezone=str(zone),lastSync=time.time(),message='Synced · '+now.strftime('%H:%M'),busy=False)
        except (RuntimeError,ValueError,KeyError,OSError,ImportError):
            self.update(busy=False,message='Sync failed · cached events shown. Retry Sync.')
    def create(self, job):
        if detect_provider()!='proton':
            self.update(actionBusy=False,actionResult='error',message='This calendar is read-only. Create events in the source calendar.')
            return
        self.update(actionBusy=True,actionResult='',message='Saving to Proton…')
        try:
            title=str(job.get('title','')).strip()
            if not title or len(title)>300: raise ValueError('Enter an event title (up to 300 characters).')
            day=dt.date.fromisoformat(job['date']); all_day=bool(job.get('allDay',False))
            args=['create','event',title,'--tz',str(timezone())]
            if all_day: args+=['--all-day','--start',day.isoformat()]
            else:
                start=dt.datetime.fromisoformat(day.isoformat()+'T'+job['start'])
                end=dt.datetime.fromisoformat(day.isoformat()+'T'+job['end'])
                if end<=start: raise ValueError('End time must be after start time.')
                args+=['--start',start.strftime('%Y-%m-%d %H:%M'),'--end',end.strftime('%Y-%m-%d %H:%M')]
            if job.get('calendar'): args+=['--calendar',job['calendar']]
            reminder=job.get('reminder','default')
            if reminder=='none': args+=['--no-reminders']
            elif reminder!='default':
                if reminder not in ['0m','5m','15m','30m','1h','1d']: raise ValueError('Invalid reminder')
                args+=['--reminder',reminder]
            self.call(args)
            self.update(actionBusy=False,actionResult='saved',message='Event saved to Proton. Press Sync to refresh events and reminders.')
        except ValueError as exc: self.update(actionBusy=False,actionResult='error',message=str(exc))
        except (RuntimeError,KeyError,OSError,subprocess.TimeoutExpired):
            self.update(actionBusy=False,actionResult='error',message='Save not confirmed. Sync and check before retrying to avoid duplicates.')
    def configure(self, job):
        cfg=read_config()
        if job.get('provider') in ('proton','ics'):
            cfg['provider']=job['provider']
        if job.get('clear'):
            cfg={}
        if 'ics' in job and isinstance(job['ics'],list):
            cfg['ics']=[s for s in job['ics'] if isinstance(s,dict) and s.get('url')]
            if cfg['ics']: cfg['provider']='ics'
        write_config(cfg)
        if job.get('month'): self.month=job['month']
        self.sync()
    def worker(self):
        while True:
            job=self.jobs.get()
            if job['op']=='create': self.create(job)
            elif job['op']=='configure': self.configure(job)
            else:
                if job.get('month'): self.month=job['month']
                self.sync()
    def alarms(self):
        while True:
            now=time.time()
            with self.guard:
                events=list(self.reminders)
                fresh=bool(self.state.get('lastSync',0)) and provider_ready()
            if fresh:
                for key,event,due in due_reminders(events,now,self.sent):
                    start=dt.datetime.fromtimestamp(event['start_ts'],timezone())
                    when=start.strftime('%a %d %b') if event.get('all_day') else start.strftime('%a %d %b, %H:%M')
                    label={'proton':'Proton Calendar'}.get(detect_provider(),'Calendar')
                    try:
                        result=subprocess.run(['notify-send','--app-name='+label,'--urgency=critical','--',event.get('summary') or 'Calendar event',html.escape(when+' · '+event.get('calendar_name','Calendar'))],timeout=10,capture_output=True)
                        if result.returncode==0:
                            self.sent[key]=now
                            self.sent={k:v for k,v in self.sent.items() if now-v<90*86400}
                            write(SENT,self.sent)
                    except (OSError,subprocess.TimeoutExpired): pass
            time.sleep(5)
    def submit(self, job):
        if job.get('op') not in ('sync','create','configure'): raise ValueError('Unknown calendar action')
        if job.get('month'):
            dt.date.fromisoformat(job['month']+'-01')
        if job['op']=='create':
            with self.guard:
                if self.state.get('actionBusy'): raise ValueError('An event is already being saved')
                self.update(actionBusy=True,actionResult='')
        try: self.jobs.put_nowait(job)
        except queue.Full:
            if job['op']=='create': self.update(actionBusy=False)
            raise


class Handler(socketserver.StreamRequestHandler):
    def handle(self):
        try:
            job=json.loads(self.rfile.readline(16384))
            self.server.bridge.submit(job)
            result={'ok':True}
        except (ValueError,queue.Full,KeyError): result={'ok':False,'message':'Calendar is busy; try again shortly.'}
        self.wfile.write((json.dumps(result)+'\n').encode())


def configure_cli(args):
    cfg=read_config()
    if args[:1]==['set-provider'] and len(args)==2 and args[1] in ('proton','ics'):
        cfg['provider']=args[1]
    elif args[:1]==['add-ics'] and len(args)==3:
        cfg.setdefault('ics',[])
        cfg['ics']=[s for s in cfg['ics'] if s.get('url')!=args[2]]
        cfg['ics'].append({'name':args[1],'url':args[2]})
        cfg['provider']='ics'
    elif args[:1]==['clear-ics']:
        cfg.pop('ics',None)
        if cfg.get('provider')=='ics': cfg['provider']=''
    elif args[:1]==['clear']:
        cfg={}
    else:
        print('usage: bridge.py configure <set-provider PROVIDER|add-ics NAME URL|clear-ics|clear>',file=sys.stderr)
        return 2
    write_config(cfg)
    print('ok')
    return 0


def main():
    os.umask(0o077)
    if len(sys.argv)>1 and sys.argv[1]=='configure':
        sys.exit(configure_cli(sys.argv[2:]))
    if len(sys.argv)>1 and sys.argv[1]=='request':
        try:
            with socket.socket(socket.AF_UNIX) as sock:
                sock.settimeout(5); sock.connect(str(SOCKET)); sock.sendall((sys.argv[2]+'\n').encode())
                print(sock.recv(4096).decode().strip())
        except OSError:
            print(json.dumps({'ok':False,'message':'Calendar service is not running. Reconnect to start it.'}))
        return
    DATA.mkdir(parents=True,exist_ok=True,mode=0o700)
    with (DATA/'daemon.lock').open('w') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        SOCKET.unlink(missing_ok=True)
        bridge=Bridge()
        with socketserver.ThreadingUnixStreamServer(str(SOCKET),Handler) as server:
            os.chmod(SOCKET,0o600); server.bridge=bridge
            threading.Thread(target=bridge.worker,daemon=True).start()
            threading.Thread(target=bridge.alarms,daemon=True).start()
            server.serve_forever()

if __name__=='__main__': main()
