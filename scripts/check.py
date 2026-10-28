#!/usr/bin/env python3
"""Validate source files and run setup/rollback tests without touching your desktop."""
import ast,json,shutil,subprocess,sys
from pathlib import Path
R=Path(__file__).resolve().parents[1];count=0
subprocess.run([sys.executable,str(R/'scripts/audit.py')],check=True)
for p in R.rglob('*'):
 if p.is_symlink() or not p.is_file() or any(x in p.parts for x in ('__pycache__','.git')):continue
 data=p.read_bytes()
 if p.suffix=='.py' or (p.parent==R/'home/.local/bin' and b'python' in data.split(b'\n')[0]):ast.parse(data,filename=str(p));count+=1
 elif p.suffix=='.json':json.loads(data);count+=1
 elif p.suffix=='.lua' and shutil.which('luac'):subprocess.run(['luac','-p',str(p)],check=True);count+=1
 elif data.startswith((b'#!/bin/bash',b'#!/bin/sh',b'#!/usr/bin/env bash')):subprocess.run(['bash','-n',str(p)],check=True);count+=1
 elif p.suffix=='.qml' and Path('/usr/lib/qt6/bin/qmlformat').exists():subprocess.run(['/usr/lib/qt6/bin/qmlformat',str(p)],stdout=subprocess.DEVNULL,check=True);count+=1
subprocess.run([sys.executable,'-m','unittest','discover','-s',str(R/'tests'),'-v'],check=True)
print(f'Validated {count} source/config files; setup tests passed.')
