#!/usr/bin/env python3
import json, os, subprocess, sys
from pathlib import Path
os.umask(0o077)
BASE=Path.home()/'.local/state/desktop-clipboard'
BASE.mkdir(parents=True,exist_ok=True,mode=0o700)
DB=BASE/'history.db'
PAUSE=BASE/'paused'
def clip(op,data=None):
    p=subprocess.run(['cliphist','-db-path',str(DB),'-max-items','200','-preview-width','220',op],input=data,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=10)
    if p.returncode: raise RuntimeError('Clipboard operation failed. Refresh and try again.')
    return p.stdout

def rows():
    if not DB.exists():return []
    result=[]
    for line in clip('list').decode('utf-8',errors='replace').splitlines():
        ident,sep,label=line.partition('\t')
        if sep and ident.isdigit():result.append({'id':ident,'preview':label,'image':'[[ binary data' in label})
    return result

def main():
    op=sys.argv[1]
    if op=='store':
        if PAUSE.exists() or os.environ.get('CLIPBOARD_STATE') in ('sensitive','nil','clear'):return
        data=sys.stdin.buffer.read(5*1024*1024+1)
        if data and len(data)<=5*1024*1024:clip('store',data)
        return
    if op=='list':result={'rows':rows(),'paused':PAUSE.exists()}
    elif op=='pause':
        if PAUSE.exists():PAUSE.unlink()
        else:PAUSE.touch(mode=0o600)
        result={'rows':rows(),'paused':PAUSE.exists()}
    elif op=='clear':
        if DB.exists():clip('wipe')
        result={'rows':[],'paused':PAUSE.exists()}
    elif op in ('copy','delete'):
        ident=sys.argv[2]
        if ident not in {r['id'] for r in rows()}:raise ValueError('This entry is no longer in history. Refresh the list.')
        encoded=(ident+'\t\n').encode()
        if op=='copy':
            data=clip('decode',encoded)
            # wl-copy infers image/text MIME type and preserves the original bytes.
            subprocess.run(['wl-copy'],input=data,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,check=True,timeout=10)
            result={'copied':True}
        else:
            clip('delete',encoded);result={'rows':rows(),'paused':PAUSE.exists()}
    else:raise ValueError('Unknown clipboard action')
    print(json.dumps(dict(ok=True,**result)))
if __name__=='__main__':
    try:main()
    except Exception as e:
        if sys.argv[1]!='store':print(json.dumps({'ok':False,'message':str(e)}))
        else:sys.exit(1)
