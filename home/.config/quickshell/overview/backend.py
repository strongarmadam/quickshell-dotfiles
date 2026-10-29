#!/usr/bin/env python3
"""Small public-IPC adapter; no compositor plugins or internal APIs."""
import importlib.util
import json
import subprocess
import sys
from pathlib import Path


def ctl(*args):
    result = subprocess.run(['hyprctl', *args], capture_output=True, text=True, timeout=4)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    return result.stdout


def snapshot():
    monitors = json.loads(ctl('-j', 'monitors'))
    workspaces = json.loads(ctl('-j', 'workspaces'))
    clients = json.loads(ctl('-j', 'clients'))
    monitor = next((m for m in monitors if m.get('focused')), monitors[0])
    active = monitor['activeWorkspace']['id']
    ids = set(range(1, 6))
    ids.update(w['id'] for w in workspaces if w['id'] > 0)
    # Keep contiguous familiar numbered slots, but don't allocate thousands for
    # a deliberately high numbered workspace.
    if max(ids) <= 30:
        ids.update(range(1, max(ids) + 1))
    rows = []
    for wid in sorted(ids):
        ws = next((w for w in workspaces if w['id'] == wid), {})
        mon = next((m for m in monitors if m['id'] == ws.get('monitorID')), monitor)
        scale = mon.get('scale', 1)
        width, height = mon['width'] / scale, mon['height'] / scale
        if mon.get('transform', 0) % 2:
            width, height = height, width
        windows = []
        for c in clients:
            if c.get('workspace', {}).get('id') != wid or not c.get('mapped', True) or c.get('hidden'):
                continue
            windows.append(dict(address=c['address'], title=c.get('title', ''), app=c.get('class', ''),
                                x=c['at'][0]-mon['x'], y=c['at'][1]-mon['y'],
                                width=c['size'][0], height=c['size'][1], floating=c.get('floating', False)))
        windows.sort(key=lambda w: w['floating'])
        rows.append(dict(id=wid, name=ws.get('name', str(wid)), width=width, height=height, windows=windows))
    return dict(ok=True, active=active, monitor=monitor['name'], rows=rows)


def activate(value):
    wid = int(value)
    if wid < 1:
        raise ValueError('Only numbered workspaces are supported.')
    result = ctl('dispatch', f'hl.dsp.focus({{ workspace = {wid} }})')
    if result.strip() != 'ok':
        raise RuntimeError(result.strip())
    return dict(ok=True)


def theme():
    path = Path.home()/'.config/quickshell/keybindings/backend.py'
    spec = importlib.util.spec_from_file_location('desktop_theme', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return dict(ok=True, theme=module.theme(), wallpaper=str((Path.home()/'.config/hypr/theme-wallpaper').resolve()))


if __name__ == '__main__':
    try:
        op = sys.argv[1]
        result = snapshot() if op == 'snapshot' else theme() if op == 'theme' else activate(sys.argv[2]) if op == 'activate' else dict(ok=False, message='Unknown operation')
    except Exception as error:
        result = dict(ok=False, message=str(error))
    print(json.dumps(result))
