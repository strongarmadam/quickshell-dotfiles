#!/usr/bin/env python3
"""NetworkManager UI adapter; no credentials or connection profiles are copied."""
import json, os, subprocess, sys

def nm(*args, timeout=15):
    p=subprocess.run(['nmcli','--colors','no',*args],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,timeout=timeout,env=dict(os.environ,LC_ALL='C'))
    if p.returncode: raise RuntimeError(p.stderr.strip() or 'NetworkManager request failed.')
    return p.stdout.strip()

def split(line):
    fields=[];buf='';escape=False
    for char in line:
        if escape:buf+=char;escape=False
        elif char=='\\':escape=True
        elif char==':':fields.append(buf);buf=''
        else:buf+=char
    if escape:buf+='\\'
    return fields+[buf]

def table(fields,*args):
    return [split(line) for line in nm('-t','-e','yes','-f',fields,*args).splitlines() if line]

def status():
    devices=[]
    for dev,kind,state,connection in table('DEVICE,TYPE,STATE,CONNECTION','device','status'):
        if kind=='loopback':continue
        devices.append(dict(device=dev,type=kind,state=state,connection=connection))
    profiles=[]
    for name,uuid,kind,device in table('NAME,UUID,TYPE,DEVICE','connection','show'):
        if kind=='loopback':continue
        profiles.append(dict(name=name,uuid=uuid,type=kind,device=device,active=bool(device and device!='--')))
    radio=table('WIFI,WIFI-HW','general')[0]
    wifi=[d for d in devices if d['type']=='wifi']
    networks=[]
    if wifi and radio[0]=='enabled':
        for active,ssid,bssid,signal,security,dev in table('IN-USE,SSID,BSSID,SIGNAL,SECURITY,DEVICE','device','wifi','list','--rescan','no'):
            if not ssid:continue
            networks.append(dict(active=active=='*',ssid=ssid,bssid=bssid,signal=int(signal or 0),security=security or 'Open',device=dev))
        # Keep strongest AP per network/security/adapter (prefer currently connected).
        networks.sort(key=lambda n:(not n['active'],-n['signal']))
        seen=set();unique=[]
        for n in networks:
            key=(n['ssid'],n['security'],n['device'])
            if key not in seen:unique.append(n);seen.add(key)
        networks=unique
    return dict(devices=devices,profiles=profiles,networks=networks,wifiAvailable=bool(wifi),wifiEnabled=radio[0]=='enabled',wifiHardware=radio[1]=='enabled')

def terminal(args):
    subprocess.Popen(['systemd-run','--user','--scope','--quiet','--collect','--',os.path.expanduser('~/.local/bin/desktop-app'),'terminal-exec',*args],stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True)
    return {'external':True}

def action(req):
    op=req.get('op','status')
    if op=='status':return {'status':status()}
    if op=='advanced':return terminal(['nmtui'])
    current=status()
    if op=='radio':nm('radio','wifi','on' if req.get('enabled') else 'off')
    elif op=='scan':
        for d in current['devices']:
            if d['type']=='wifi':nm('--wait','15','device','wifi','rescan','ifname',d['device'],timeout=20)
    elif op in ('device-connect','disconnect'):
        dev=next((d for d in current['devices'] if d['device']==req.get('device')),None)
        if not dev:raise ValueError('Network adapter is no longer available. Refresh the list.')
        if op=='device-connect':return terminal(['nmcli','--ask','--wait','60','device','connect',dev['device']])
        nm('--wait','15','device','disconnect',dev['device'],timeout=20)
    elif op in ('profile-connect','profile-disconnect'):
        profile=next((p for p in current['profiles'] if p['uuid']==req.get('uuid')),None)
        if not profile:raise ValueError('Connection profile is no longer available.')
        if op=='profile-connect':return terminal(['nmcli','--ask','--wait','60','connection','up','uuid',profile['uuid']])
        nm('--wait','15','connection','down','uuid',profile['uuid'],timeout=20)
    elif op=='wifi-connect':
        network=next((n for n in current['networks'] if n['bssid']==req.get('bssid') and n['device']==req.get('device')),None)
        if not network:raise ValueError('This access point is no longer visible. Scan again.')
        # A BSSID avoids ambiguous or option-like SSIDs; nmcli owns the password prompt.
        return terminal(['nmcli','--ask','--wait','60','device','wifi','connect',network['bssid'],'ifname',network['device']])
    else:raise ValueError('Unknown network action')
    return {'status':status(),'message':'Updated.'}

if __name__=='__main__':
    try: print(json.dumps(dict(ok=True,**action(json.loads(sys.argv[1]) if len(sys.argv)>1 else {}))))
    except subprocess.TimeoutExpired:print(json.dumps({'ok':False,'message':'NetworkManager timed out. Refresh to check the result.'}))
    except Exception as e:print(json.dumps({'ok':False,'message':str(e)}))
