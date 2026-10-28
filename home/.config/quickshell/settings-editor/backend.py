#!/usr/bin/env python3
"""Validate and merge GUI edits without overwriting unrelated settings."""
import json, os, sys, tempfile, shutil, datetime
from pathlib import Path
HOME = Path.home()
CONFIG = HOME / '.config/quickshell/settings.json'
DEFAULTS = Path(__file__).with_name('defaults.json')
def main():
    action = sys.argv[1]
    data = json.loads(CONFIG.read_text())
    if action == 'info':
        return {'theme': (HOME / '.config/themes/current').resolve().name}
    request = json.loads(sys.argv[2])
    path = request['path']
    if not isinstance(path, list) or len(path) != 3 or path[0] not in ('shared', 'themes', 'layout'):
        raise ValueError('Invalid setting path')
    # themes have an extra level: theme / component / field.
    if path[0] == 'themes':
        path = [path[0], request['theme'], *path[1:]]
    parent = data
    for key in path[:-1]: parent = parent[key]
    key = path[-1]
    old = parent[key]
    if old != request['expected']:
        raise ValueError('This setting changed elsewhere. Refresh and try again.')
    if action == 'reset':
        default = json.loads(DEFAULTS.read_text())
        for part in path: default = default[part]
        value = default
    else:
        value = request['value']
    if type(old) is bool:
        if type(value) is not bool: raise ValueError('Expected a toggle')
    elif isinstance(old, (int, float)):
        if type(value) not in (int, float): raise ValueError('Expected a number')
        import math
        if not math.isfinite(value): raise ValueError('Expected a finite number')
        if 'opacity' in key.lower() and not 0 <= value <= 1: raise ValueError('Opacity must be between 0 and 1')
        if key not in ('x', 'y') and value < 0: raise ValueError('Value must be nonnegative')
        if ('width' in key.lower() or 'height' in key.lower() or 'interval' in key or 'pixelSize' in key) and value <= 0: raise ValueError('Value must be greater than zero')
    elif type(value) is not str: raise ValueError('Expected text')
    if isinstance(old, str) and old.startswith('#'):
        import re
        if not re.fullmatch(r'#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?', value): raise ValueError('Use #RRGGBB or #AARRGGBB')
    parent[key] = value
    backup = HOME / '.local/state/quickshell-settings-history'
    backup.mkdir(parents=True, exist_ok=True)
    shutil.copy2(CONFIG, backup / (datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f') + '.json'))
    fd, name = tempfile.mkstemp(dir=CONFIG.parent, prefix='.settings-', suffix='.json')
    try:
        with os.fdopen(fd, 'w') as out:
            json.dump(data, out, indent=2); out.write('\n'); out.flush(); os.fsync(out.fileno())
        os.chmod(name, CONFIG.stat().st_mode & 0o777)
        os.replace(name, CONFIG)
    finally:
        if os.path.exists(name): os.unlink(name)
    return {'ok': True, 'message': 'Saved. Quickshell updates automatically.'}
try:
    print(json.dumps(main()))
except Exception as error:
    print(json.dumps({'ok': False, 'message': str(error)})); sys.exit(1)
