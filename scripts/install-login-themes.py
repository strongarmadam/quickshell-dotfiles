#!/usr/bin/env python3
"""Install bundled SDDM themes and a fixed-choice selector (explicit administrator step)."""
import argparse,datetime,os,pwd,re,shutil,subprocess,tempfile
from pathlib import Path
NAMES=('16-bit Sunset','Space Green','Autumn Grove','Annapurna Retro','Rivendell','Bakery Hearth','Moonlit Forest','Coral Lagoon')
HELPER='''#!/usr/bin/python3 -I
"""Only select an already-installed, fixed-name login theme."""
import configparser,io,os,sys,tempfile
from pathlib import Path
NAMES = NAMES_VALUE
if os.geteuid()!=0:sys.exit('Administrator access required.')
if len(sys.argv)!=2 or sys.argv[1] not in NAMES:sys.exit('Unknown bundled theme.')
name=sys.argv[1].lower().replace(' ','-')
if not (Path('/usr/share/sddm/themes')/name/'Main.qml').is_file():sys.exit('Login theme is not installed.')
p=Path('/etc/sddm.conf');c=configparser.ConfigParser(interpolation=None);c.optionxform=str
if p.exists():c.read(p)
if not c.has_section('Theme'):c.add_section('Theme')
c.set('Theme','Current',name)
s=io.StringIO();c.write(s,space_around_delimiters=False)
fd,tmp=tempfile.mkstemp(prefix='.sddm-theme-',dir='/etc')
try:
 with os.fdopen(fd,'w') as f:f.write(s.getvalue());f.flush();os.fsync(f.fileno())
 os.chmod(tmp,0o644);os.replace(tmp,p)
finally:
 if os.path.exists(tmp):os.unlink(tmp)
'''.replace('NAMES_VALUE',repr(NAMES))
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--user',default=os.environ.get('SUDO_USER'));a=p.parse_args()
 if os.geteuid()!=0:raise ValueError('Run with sudo after the normal setup wizard.')
 if not a.user or not re.fullmatch(r'[a-z_][a-z0-9_-]*[$]?',a.user):raise ValueError('Specify a normal account with --user USERNAME.')
 account=pwd.getpwnam(a.user)
 if account.pw_uid==0:raise ValueError('Choose a normal desktop account.')
 home=Path(account.pw_dir);source=home/'.config/themes';selected=(source/'current').resolve().name
 if selected not in NAMES:raise ValueError('Select one of the eight bundled themes before installing login assets.')
 allowed={'Main.qml','GlassSurface.qml','theme.conf','metadata.desktop','wallpaper.png','wallpaper.jpg'}
 for name in NAMES:
  folder=source/name/'sddm'
  for required in ('Main.qml','GlassSurface.qml','theme.conf','metadata.desktop'):
   if not (folder/required).is_file():raise ValueError('Missing login asset: '+name+'/'+required)
  if not any((folder/f).is_file() for f in ('wallpaper.png','wallpaper.jpg')):raise ValueError('Missing wallpaper: '+name)
 backup=Path('/var/lib/quickshell-dotfiles/login-backups')/datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f');backup.mkdir(parents=True,mode=0o700)
 def save(path):
  if path.exists() or path.is_symlink():
   dest=backup/str(path).lstrip('/');dest.parent.mkdir(parents=True,exist_ok=True)
   if path.is_dir():shutil.copytree(path,dest,symlinks=True)
   else:shutil.copy2(path,dest,follow_symlinks=False)
 for name in NAMES:
  target=Path('/usr/share/sddm/themes')/name.lower().replace(' ','-')
  if target.is_symlink():raise ValueError('Login theme directory must not be a symlink: '+str(target))
  save(target);target.mkdir(parents=True,exist_ok=True)
  for filename in allowed:
   src=source/name/'sddm'/filename
   if src.is_file():
    dst=target/filename
    if dst.is_symlink():dst.unlink()
    shutil.copyfile(src,dst);dst.chmod(0o644);os.chown(dst,0,0)
  target.chmod(0o755);os.chown(target,0,0)
 helper=Path('/usr/local/bin/quickshell-login-theme');save(helper);helper.parent.mkdir(parents=True,exist_ok=True)
 if helper.is_symlink():helper.unlink()
 helper.write_text(HELPER);helper.chmod(0o755);os.chown(helper,0,0)
 sudoers=Path('/etc/sudoers.d/quickshell-login-theme');save(sudoers)
 text=a.user+' ALL=(root) NOPASSWD: /usr/local/bin/quickshell-login-theme *\n'
 fd,tmp=tempfile.mkstemp(prefix='quickshell-sudoers-')
 try:
  with os.fdopen(fd,'w') as f:f.write(text)
  subprocess.run(['visudo','-cf',tmp],check=True)
  if sudoers.is_symlink():sudoers.unlink()
  shutil.copyfile(tmp,sudoers);sudoers.chmod(0o440);os.chown(sudoers,0,0)
 finally:os.unlink(tmp)
 save(Path('/etc/sddm.conf'))
 subprocess.run([str(helper),selected],check=True)
 print('Installed eight login themes; selected '+selected+'. Backups: '+str(backup))
 print('The new greeter theme appears on the next SDDM start. No session was stopped.')
if __name__=='__main__':
 try:main()
 except (ValueError,OSError,KeyError,subprocess.SubprocessError) as e:raise SystemExit(str(e))
