#!/usr/bin/env python3
"""Machine-local visibility and home positions for the system-monitor drawer."""
import json, os, sys, tempfile
from pathlib import Path
home=Path.home()
path=home/'.local/state/quickshell-widgets/monitor-drawer.json'
ids=('cpu','temperature','memory','network')
def save(data):
 path.parent.mkdir(parents=True,exist_ok=True)
 fd,tmp=tempfile.mkstemp(dir=path.parent)
 try:
  with os.fdopen(fd,'w') as f:json.dump(data,f,indent=2);f.write('\n')
  os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
if path.exists():
 data=json.loads(path.read_text())
else:
 layout=json.loads((home/'.config/quickshell/settings.json').read_text()).get('layout',{})
 data={'shown':True,'defaults':{key:layout[key] for key in ids if key in layout}}
 save(data)
if len(sys.argv)>1 and sys.argv[1]=='save':
 new=json.loads(sys.argv[2]);assert isinstance(new['shown'],bool) and isinstance(new['defaults'],dict)
 data=new;save(data)
print(json.dumps(data))
