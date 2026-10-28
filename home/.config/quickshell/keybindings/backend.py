#!/usr/bin/env python3
"""List live bindings and edit their original Lua key expressions."""
import json, os, re, shutil, subprocess, sys, time
from pathlib import Path
HOME = Path.home()
ROOT = HOME / '.config/hypr'
MODS = {'SHIFT': 1, 'CTRL': 4, 'CONTROL': 4, 'ALT': 8, 'SUPER': 64}

def ctl(*args):
    return subprocess.check_output(['hyprctl', *args], text=True, timeout=10)

def identity(combo):
    parts = [p.strip() for p in combo.split('+')]
    mask = 0
    for p in parts[:-1]:
        if p.upper() not in MODS: raise ValueError('Use SUPER, SHIFT, CTRL or ALT as modifiers.')
        mask |= MODS[p.upper()]
    key = parts[-1]
    if not re.fullmatch(r'[A-Za-z0-9_:]+', key):
        raise ValueError('Use a key name such as D, slash, Return, equal or mouse:272.')
    return mask, key.lower()

def combo(b):
    mods = [name for name, bit in [('SUPER',64),('CTRL',4),('ALT',8),('SHIFT',1)] if b['modmask'] & bit]
    key = ('code:' + str(b['keycode'])) if b.get('keycode') else b['key']
    return ' + '.join(mods + [key])

def friendly(label, variable):
    names = {
        '~/.local/bin/close-app': 'Close application',
        '~/.local/bin/workspace-vim first': 'First workspace', '~/.local/bin/workspace-vim left': 'Previous workspace',
        '~/.local/bin/workspace-vim right': 'Next workspace', '~/.local/bin/workspace-vim last': 'Last workspace',
        '~/.local/bin/power-menu': 'Power and lock menu', '~/.local/bin/theme-menu': 'Choose desktop theme',
        'systemctl poweroff': 'Shut down computer', 'bash ~/.config/hypr/scripts/screenshot.sh': 'Take screenshot',
        '~/.config/hypr/scripts/close-all.sh': 'Close all windows', 'playerctl next': 'Next track',
        'playerctl previous': 'Previous track', 'playerctl play-pause': 'Play / pause',
        'echo hello > /tmp/exec-test.txt': 'Write test file',
    }
    if label in names: return names[label]
    for token, name in [('window.fullscreen','Toggle fullscreen'), ('window.pseudo','Toggle pseudo tiling'), ('window.float','Toggle floating'), ('workspace.toggle_special','Toggle scratchpad'), ('window.resize','Resize window'), ('kb_confirm','Select overview workspace'), ('expo("cancel")','Close workspace overview')]:
        if token in label: return name
    if 'kb_focus' in label: return 'Focus overview workspace ' + str(variable)
    direction = re.search(r'direction = "([^"]+)"', label)
    if direction: return 'Focus window ' + direction[1]
    if 'workspace = "e+1"' in label: return 'Next workspace'
    if 'workspace = "e-1"' in label: return 'Previous workspace'
    if 'wpctl set-volume' in label: return 'Volume up' if label.endswith('+') else 'Volume down'
    if 'wpctl set-mute' in label: return 'Mute microphone' if 'SOURCE' in label else 'Mute audio'
    if 'brightnessctl' in label: return 'Brightness up' if label.endswith('+') else 'Brightness down'
    return label

def sources():
    # Follow local requires rather than indexing inactive themes or backups.
    pending = [ROOT / 'hyprland.lua']; seen = set(); result = []
    while pending:
        path = pending.pop(0)
        if path in seen or not path.is_file(): continue
        seen.add(path)
        text = path.read_text()
        submap = ''
        for n, line in enumerate(text.splitlines(), 1):
            if line.lstrip().startswith('--'): continue
            for req in re.findall(r'require\(["\']([^"\']+)["\']\)', line):
                pending.append(path.parent / (req + '.lua'))
            sub = re.search(r'hl.define_submap\("([^"]+)"', line)
            if sub: submap = sub[1]
            if line.startswith('end)'): submap = ''
            m = re.search(r'hl\.bind\((.*?),\s*', line)
            if not m: continue
            expr = m[1].strip()
            def expand(variable=None):
                chunks = []
                for chunk in expr.split('..'):
                    chunk = chunk.strip()
                    if chunk == 'mainMod': chunks.append('SUPER')
                    elif chunk in ('key','direction') and variable is not None: chunks.append(str(variable))
                    elif re.fullmatch(r'"[^"]*"', chunk): chunks.append(chunk[1:-1])
                    else: return None
                return ''.join(chunks)
            generated = bool(re.search(r'\b(key|direction)\b', expr))
            variants = range(10) if re.search(r'\bkey\b',expr) else ['left','right','up','down'] if expr == 'direction' else [None]
            for var in variants:
                value = expand(var)
                if value is None: continue
                try: ident = identity(value)
                except ValueError: continue
                action = line[m.end():].strip()
                desc = re.search(r'description\s*=\s*"([^"]+)"', line)
                label = desc[1] if desc else action
                replacements = {'hl.dsp.exec_cmd(terminal))':'Open terminal', 'hl.dsp.exec_cmd(fileManager))':'Open file manager', 'hl.dsp.exec_cmd(menu))':'App launcher'}
                label = replacements.get(label, label)
                if var is not None and isinstance(var,int):
                    label = ('Move window to workspace ' if 'window.move' in action else 'Switch to workspace ') + str(var or 10)
                elif not desc:
                    cmd = re.search(r'hl.dsp.exec_cmd\("([^"]+)"', action)
                    if cmd: label = cmd[1].replace(str(HOME), '~')
                    else: label = label.replace('hl.dsp.', '').rstrip('), ')
                result.append(dict(identity=ident, submap=submap, path=str(path), line=n, expression=expr, label=friendly(label,var), editable=not generated))
    return result

def listing():
    live = json.loads(ctl('-j','binds')); src = sources(); rows = []
    for b in live:
        key = ('code:' + str(b['keycode'])) if b.get('keycode') else b['key'].lower()
        matches = [s for s in src if s['identity'] == (b['modmask'],key) and s['submap'] == b.get('submap','')]
        s = matches[0] if len(matches)==1 else {}
        flags = ', '.join(k for k in ['release','repeat','mouse','locked'] if b.get(k))
        rows.append(dict(shortcut=combo(b), mode=b.get('submap') or 'Desktop', action=b.get('description') or s.get('label') or (b['dispatcher'] + ' ' + b.get('arg','')), flags=flags, path=s.get('path',str(ROOT/'hyprland.lua')), line=s.get('line',1), expression=s.get('expression',''), editable=s.get('editable',False), sourceMatched=bool(s)))
    return rows

def save(req):
    rows = listing()
    old = next((r for r in rows if r['path']==req['path'] and r['line']==req['line'] and r['expression']==req['expression'] and r['shortcut']==req['shortcut'] and r['mode']==req['mode']), None)
    if not old or not old['editable']: raise ValueError('Binding changed or is generated. Refresh, or use Edit source.')
    new = req['value'].strip()
    ident = identity(new)
    if any(identity(r['shortcut'])==ident and r['mode']==old['mode'] and r is not old for r in rows):
        raise ValueError('That shortcut is already assigned in this mode.')
    path = Path(old['path']); original = path.read_text(); lines = original.splitlines(keepends=True)
    line = lines[old['line']-1]
    needle = 'hl.bind(' + old['expression']
    if needle not in line: raise ValueError('Source changed. Refresh before saving.')
    # Only a validated key expression is replaced; callbacks/options stay intact.
    lines[old['line']-1] = line.replace(needle, 'hl.bind(' + json.dumps(new), 1)
    backup = HOME / '.local/state/keybindings-history' / str(time.time_ns())
    backup.mkdir(parents=True, mode=0o700)
    shutil.copy2(path, backup/path.name)
    try:
        path.write_text(''.join(lines))
        ctl('reload')
        errors = ctl('configerrors').strip()
        if errors and errors != 'ok': raise ValueError(errors)
    except Exception:
        path.write_text(original); ctl('reload'); raise
    return 'Saved and applied. Backup: ' + str(backup/path.name)

def theme():
    active = (HOME / '.config/themes/current').resolve()
    settings = json.loads((HOME / '.config/quickshell/settings.json').read_text())
    shell = (active / 'quickshell/shell.qml').read_text()
    defaults = {}
    for key, value in re.findall(r'Config.Settings.value\("[^"\n]+", "shell", "([^"\n]+)", ([^\n]+?)\)', shell):
        try: defaults[key] = json.loads(value)
        except ValueError: pass
    defaults.update(settings.get('themes', {}).get(active.name, {}).get('shell', {}))
    custom = active / 'creator-settings.json'
    if custom.exists():
        defaults.update(json.loads(custom.read_text()).get('values', {}).get('shell', {}))
    shared = settings.get('shared', {}).get('DesktopUi', {})
    fallback = dict(panelColor='#b8030609', textColor='#d7f3ff', accentColor='#3aa9d2', edgeColor='#155779', panelOpacity=1, cornerRadius=4, edgeWidth=1)
    return dict(name=active.name, **{key:defaults.get(key+'_3', shared.get(key, value)) for key,value in fallback.items()})

if __name__ == '__main__':
    try:
        op = sys.argv[1]
        if op == 'theme': result = {'ok':True, 'theme':theme()}
        elif op == 'list': result = {'ok':True, 'rows':listing()}
        elif op == 'save': result = {'ok':True, 'message':save(json.loads(sys.argv[2]))}
        elif op == 'reload':
            ctl('reload'); errors=ctl('configerrors').strip()
            result={'ok':not errors, 'message':errors or 'Configuration reloaded.'}
        elif op == 'edit':
            req=json.loads(sys.argv[2]); path=Path(req['path'])
            if path not in [Path(s['path']) for s in sources()] and path != ROOT/'hyprland.lua': raise ValueError('Unknown source file.')
            backup=HOME/'.local/state/keybindings-history'/str(time.time_ns()); backup.mkdir(parents=True,mode=0o700); shutil.copy2(path,backup/path.name)
            subprocess.Popen([str(HOME/'.local/bin/desktop-app'),'terminal-exec','nano','+'+str(int(req['line'])),str(path)], start_new_session=True, stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            result={'ok':True,'message':'Edit in Nano: Ctrl+O then Enter to save, Ctrl+X to exit. Then click Reload.'}
        else: raise ValueError('Unknown operation')
        print(json.dumps(result))
    except Exception as e: print(json.dumps({'ok':False,'message':str(e)}))
