#!/usr/bin/env python3
"""Audit the public export without printing matched secret values."""
from pathlib import Path
import re,sys
ROOT=Path(__file__).resolve().parents[1]
errors=[];count=0
patterns={
 'private key':rb'-----BEGIN (?:OPENSSH |RSA |EC |DSA )?PRIVATE KEY-----',
 'provider token':rb'(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|sk-[A-Za-z0-9_-]{30,}|AKIA[A-Z0-9]{16})',
 'embedded credential':rb'(?i)(?:access_token|refresh_token|client_secret|api_key)\s*["\x27]?\s*[:=]\s*["\x27][A-Za-z0-9_./+=-]{16,}',
 'private home path':rb'/home/[A-Za-z0-9_-]+/',
 'private IPv4 address':rb'\b(?:192\.168\.\d{1,3}\.\d{1,3}|10\.\d{1,3}\.\d{1,3}\.\d{1,3})\b',
}
for p in ROOT.rglob('*'):
 rel=p.relative_to(ROOT)
 if any(x in rel.parts for x in ('.git','__pycache__')) or p.suffix=='.pyc':continue
 if p.is_symlink():
  if Path(p.readlink()).is_absolute() or not p.resolve().is_relative_to(ROOT) or not p.exists():errors.append((str(rel),'broken or external symlink'))
  continue
 if not p.is_file():continue
 count+=1
 if any(x in rel.parts for x in ('.ssh','.aws','.gnupg','.cache','.state','node_modules')) or p.name in ('.env','session.json','credentials.json','cookies.sqlite') or p.suffix in ('.pem','.key','.p12','.so','.o'):
  errors.append((str(rel),'excluded filename/type'))
 data=p.read_bytes()
 if data.startswith(b'\x7fELF'):errors.append((str(rel),'compiled executable'))
 if p.suffix.lower() in ('.png','.jpg'):continue
 for label,pattern in patterns.items():
  if re.search(pattern,data):errors.append((str(rel),label))
 if rel.parts[0]=='home' and any(x in rel.parts for x in ('.local/state','proton-cal','calendar-bridge')):errors.append((str(rel),'private state/integration'))
for path,reason in errors:print(f'FAIL {path}: {reason}')
print(f'Audited {count} regular files; {len(errors)} findings. Runtime password-entry code is expected; saved credentials are not.')
sys.exit(bool(errors))
