#!/usr/bin/env python3
"""Create a public tarball from tracked files only, with neutral archive metadata."""
from pathlib import Path
import hashlib,io,subprocess,tarfile
R=Path(__file__).resolve().parents[1]
subprocess.run(['python3',str(R/'scripts/audit.py')],check=True)
paths=subprocess.check_output(['git','-C',str(R),'ls-files','-z']).decode().strip('\0').split('\0')
if not paths or not paths[0]:raise SystemExit('Stage the reviewed public files with git add before packaging.')
out=R.parent/(R.name+'.tar.gz')
with tarfile.open(out,'w:gz') as tar:
 for rel in sorted(paths):
  p=R/rel
  info=tar.gettarinfo(str(p),arcname=R.name+'/'+rel);info.uid=info.gid=0;info.uname=info.gname='';info.mtime=0
  if p.is_symlink():
   if not p.resolve().is_relative_to(R) or not p.exists():raise ValueError('Unsafe link: '+rel)
   tar.addfile(info)
  else:
   with p.open('rb') as f:tar.addfile(info,f)
checksum=hashlib.sha256(out.read_bytes()).hexdigest();out.with_name(out.name+'.sha256').write_text(checksum+'  '+out.name+'\n')
print(out);print(checksum)
