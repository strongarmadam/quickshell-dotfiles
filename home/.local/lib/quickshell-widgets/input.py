#!/usr/bin/env python3
"""Hyprland cursor/geometry bridge for movable Quickshell desktop widgets."""
import json
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
import time


def request(command):
    runtime = os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')
    signature = os.environ['HYPRLAND_INSTANCE_SIGNATURE']
    path = f'{runtime}/hypr/{signature}/.socket.sock'
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.settimeout(1)
        sock.connect(path)
        sock.sendall(command.encode())
        response = bytearray()
        while True:
            data = sock.recv(65536)
            if not data:
                break
            response.extend(data)
    return json.loads(response)


def ipc(method, *args):
    # Match the service's launch path: Quickshell identifies instances by path,
    # and resolving the current-theme symlink selects a different instance.
    config = Path.home() / '.config/themes/current/quickshell'
    result = subprocess.run(['quickshell', 'ipc', '-p', str(config), 'call',
                             'widgets', method, *map(str, args)],
                            capture_output=True, text=True, timeout=2)
    return result.returncode == 0, result.stdout.strip()


def main():
    mode = sys.argv[1]
    if mode == 'geometry':
        geometry = {}
        for monitor in request('j/monitors'):
            reserved = monitor.get('reserved', [0, 0, 0, 0])
            geometry[monitor['name']] = {
                'x': monitor['x'], 'y': monitor['y'],
                'left': reserved[0], 'top': reserved[1],
                'right': reserved[2], 'bottom': reserved[3]}
        print(json.dumps(geometry), flush=True)
    elif mode == 'cursor':
        signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
        while True:
            started = time.monotonic()
            print(json.dumps(request('j/cursorpos'), separators=(',', ':')), flush=True)
            time.sleep(max(0, 1 / 60 - (time.monotonic() - started)))
    elif mode == 'start':
        cursor = request('j/cursorpos')
        ok, result = ipc('beginDrag', sys.argv[2], cursor['x'], cursor['y'])
        if not ok or result != 'true':
            # The normal native bind handles app windows. This is a fallback if
            # a hovered widget vanished between the button press and IPC call.
            subprocess.run(['hyprctl', 'dispatch', 'hl.dsp.window.drag()'],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    elif mode == 'stop':
        cursor = request('j/cursorpos')
        ipc('moveDrag', cursor['x'], cursor['y'])
        ipc('endDrag')


if __name__ == '__main__':
    try:
        main()
    except (BrokenPipeError, KeyboardInterrupt):
        pass
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print(f'Widget input: {error}', file=sys.stderr)
        sys.exit(1)
