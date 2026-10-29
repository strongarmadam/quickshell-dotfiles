#!/usr/bin/env python3
"""Interactive, user-local installation with preview and reversible file backups."""
import argparse, datetime, hashlib, json, os, re, shlex, shutil, sys
from scripts.bootstrap import choose_actions, describe_actions, run_actions
from pathlib import Path
ROOT=Path(__file__).resolve().parent
DEFAULTS={'theme':'Moonlit Forest','browser':'firefox','terminal':'kitty','terminal_exec':'-e','files':'kitty -e yazi','monitor':'kitty -e btop','browser_key':'SUPER + B','terminal_key':'SUPER + RETURN','files_key':'SUPER + E','keyboard':'us','scale':1.0,'clipboard':True,'media':True,'extra_apps':[]}
def combo(value):
    parts=[p.strip().upper() for p in value.split('+')]
    if len(parts)<2 or any(p not in ('SUPER','SHIFT','CTRL','ALT') for p in parts[:-1]) or not re.fullmatch(r'[A-Z0-9_:]+',parts[-1]):
        raise ValueError('Use a combination such as SUPER + B or SUPER + SHIFT + RETURN.')
    if len(set(parts[:-1]))!=len(parts[:-1]):raise ValueError('Repeated modifier.')
    return ' + '.join([p for p in ('SUPER','CTRL','ALT','SHIFT') if p in parts[:-1]]+[parts[-1]])
def reserved():
    text=(ROOT/'home/.config/hypr/hyprland.lua').read_text().replace('mainMod .. ', '').replace('" + ', '"SUPER + ')
    keys={combo(k) for k in re.findall(r'hl.bind\("([^"]+)"',text) if '+' in k and not k.rstrip().endswith('+') and not 'mouse:' in k}
    for n in range(10):keys.update({f'SUPER + {n}',f'SUPER + SHIFT + {n}'})
    keys.update({'SUPER + SPACE','SUPER + W'})
    return keys

def validate(c):
    themes=[p.name for p in (ROOT/'home/.config/themes').iterdir() if p.is_dir()]
    if c['theme'] not in themes:raise ValueError('Unknown theme.')
    if not re.fullmatch('[a-zA-Z0-9_,+-]+',c['keyboard']):raise ValueError('Invalid XKB layout.')
    if type(c['scale']) not in (int,float) or not 0.5<=c['scale']<=3:raise ValueError('Scale must be between 0.5 and 3.')
    for key in ('clipboard','media'):
        if type(c[key]) is not bool:raise ValueError(key+' must be true or false.')
    used=reserved()
    for key in ('terminal','browser','files','monitor','terminal_exec'):
        if not isinstance(c[key],str) or any(ord(x)<32 for x in c[key]):raise ValueError('Invalid application command.')
        args=shlex.split(c[key])
        if not args:raise ValueError('Application command cannot be empty.')
    entries=[(role,c[role+'_key']) for role in ('terminal','browser','files')]
    if not isinstance(c['extra_apps'],list):raise ValueError('extra_apps must be a list.')
    for app in c['extra_apps']:
        if not re.fullmatch(r'[a-z][a-z0-9_-]*',app['name']) or app['name'] in ('terminal','browser','files','monitor','terminal-exec','terminal_exec'):raise ValueError('Invalid or reserved extra app name.')
        if not isinstance(app['command'],str) or not shlex.split(app['command']) or any(ord(x)<32 for x in app['command']):raise ValueError('Invalid app command.')
        entries.append((app['name'],app['key']))
    if len({role for role,_ in entries})!=len(entries):raise ValueError('Duplicate application name.')
    for role,key in entries:
        key=combo(key)
        if key in used:raise ValueError('Shortcut is already used: '+key)
        used.add(key)
    return c

def ask(label,default):
    return input(f'{label} [{default}]: ').strip() or str(default)
def wizard(c):
    print('Choose your app commands. Dependency installation is offered after these choices.')
    for role in ('browser','terminal'):c[role]=ask(role.title()+' command',c[role])
    c['terminal_exec']=ask('Terminal run-command argument (usually -e; GNOME Terminal uses --)',c['terminal_exec'])
    if c['terminal'] != DEFAULTS['terminal'] or c['terminal_exec'] != DEFAULTS['terminal_exec']:
        for role,app in [('files','yazi'),('monitor','btop')]:
            if c[role] == DEFAULTS[role]:c[role]=c['terminal']+' '+c['terminal_exec']+' '+app
    for role in ('files','monitor'):c[role]=ask(role.title()+' command',c[role])
    for role in ('terminal','browser','files'):c[role+'_key']=ask(role.title()+' shortcut',c[role+'_key'])
    print('Themes: '+', '.join(sorted(p.name for p in (ROOT/'home/.config/themes').iterdir())))
    c['theme']=ask('Initial theme',c['theme']);c['keyboard']=ask('Keyboard layout',c['keyboard']);c['scale']=float(ask('Display scale',c['scale']))
    for key,label in [('clipboard','Enable local clipboard history'),('media','Show media widget when a player is available')]:c[key]=ask(label+' (yes/no)','yes' if c[key] else 'no').lower() in ('yes','y')
    while True:
        name=input('Extra app shortcut name (blank to finish): ').strip()
        if not name:break
        c['extra_apps'].append({'name':name,'command':input('Command: ').strip(),'key':input('Shortcut: ').strip()})
    return validate(c)

def digest(path):
    if path.is_symlink():return 'link:'+os.readlink(path)
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None

def safe_target(home,rel):
    rel=Path(rel)
    if rel.is_absolute() or '..' in rel.parts:raise ValueError('Unsafe relative path.')
    target=home/rel
    if not target.parent.resolve().is_relative_to(home):raise ValueError('Parent symlink leaves target home: '+str(rel))
    return target

def plan(home,c):
    result={}
    for p in sorted((ROOT/'home').rglob('*')):
        if p.is_dir() and not p.is_symlink():continue
        rel=str(p.relative_to(ROOT/'home'))
        if '__pycache__' in p.parts or p.suffix=='.pyc':continue
        if p.is_symlink():
            target=p.resolve()
            if not target.is_relative_to(ROOT/'home') or not target.exists():raise ValueError('Broken or external source link: '+rel)
            result[rel]=('link',os.readlink(p),0)
        else:
            data=p.read_bytes()
            try:data=data.decode().replace('@HOME@',str(home)).encode()
            except UnicodeError:pass
            result[rel]=('file',data,p.stat().st_mode&0o777)
    def put(rel,data):result[rel]=('file',data.encode(),0o644)
    apps={key:shlex.split(c[key]) for key in ('browser','terminal','terminal_exec','files','monitor')}
    binds=[]
    for role in ('terminal','browser','files'):binds.append((role,combo(c[role+'_key'])))
    for app in c['extra_apps']:apps[app['name']]=shlex.split(app['command']);binds.append((app['name'],combo(app['key'])))
    put('.config/desktop-apps.json',json.dumps(apps,indent=2)+'\n')
    put('.config/hypr/apps.lua','-- Generated app choices; rerun setup to customize.\n'+'\n'.join('hl.bind('+json.dumps(key)+', hl.dsp.exec_cmd("~/.local/bin/desktop-app '+role+'"), { description = "Launch '+role+'" })' for role,key in binds)+'\n')
    put('.config/hypr/hardware.lua','-- Edit for your monitors, keyboard and input devices.\nhl.monitor({ output = "", mode = "preferred", position = "auto", scale = '+str(c['scale'])+' })\nhl.config({ input = { kb_layout = '+json.dumps(c['keyboard'])+', follow_mouse = 1, sensitivity = 0, touchpad = { natural_scroll = false } } })\n')
    key='.config/quickshell/settings.json';data=json.loads(result[key][1]);data['shared'].setdefault('Visibility',{})['media']=c['media'];put(key,json.dumps(data,indent=2)+'\n')
    key='.config/hypr/hyprland.lua'
    if not c['clipboard']:put(key,result[key][1].decode().replace('quickshell-desktop.service clipboard-history.service','quickshell-desktop.service'))
    for rel,target in {'.config/themes/current':c['theme'],'.config/hypr/theme.lua':'../themes/current/hyprland.lua','.config/gtk-3.0/gtk.css':'../themes/current/gtk-3.0/gtk.css','.config/gtk-4.0/gtk.css':'../themes/current/gtk-4.0/gtk.css','.config/gtk-3.0/file-dialogs.css':'../themes/current/gtk-3.0/file-dialogs.css','.config/gtk-4.0/file-dialogs.css':'../themes/current/gtk-4.0/file-dialogs.css'}.items():result[rel]=('link',target,0)
    wall=next(p.name for p in (ROOT/'home/.config/themes'/c['theme']).glob('wallpaper.*'))
    result['.config/hypr/theme-wallpaper']=('link','../themes/current/'+wall,0)
    # Prepare all destinations before writing anything.
    for rel in result:
        target=safe_target(home,rel)
        if target.exists() and target.is_dir() and not target.is_symlink():raise ValueError('Expected a file, found directory: '+str(target))
    return result

def install(home,items):
    stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup=home/'.local/state/quickshell-dotfiles/backups'/stamp
    if not backup.parent.resolve().is_relative_to(home):raise ValueError('Backup parent must stay inside home.')
    backup.mkdir(parents=True,mode=0o700)
    journal={'home':str(home),'files':[]};manifest=backup/'manifest.json'
    try:
        for rel,(kind,data,mode) in items.items():
            dest=safe_target(home,rel);exists=dest.exists() or dest.is_symlink()
            if exists:
                saved=backup/'files'/rel;saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dest,saved,follow_symlinks=False)
            record={'path':rel,'previous':exists,'installed':None};journal['files'].append(record)
            manifest.write_text(json.dumps(journal,indent=2))
            dest.parent.mkdir(parents=True,exist_ok=True)
            temp=dest.with_name(dest.name+'.dotfiles-'+str(os.getpid()))
            if temp.exists() or temp.is_symlink():raise ValueError('Temporary installation path already exists.')
            if kind=='link':temp.symlink_to(data)
            else:temp.write_bytes(data);temp.chmod(mode)
            os.replace(temp,dest);record['installed']=digest(dest)
            manifest.write_text(json.dumps(journal,indent=2))
    except Exception:
        restore(home,backup,force=True);raise
    return backup

def restore(home,backup,force=False):
    journal=json.loads((backup/'manifest.json').read_text())
    if journal['home']!=str(home):raise ValueError('Backup belongs to a different home directory.')
    records=list(reversed(journal['files']))
    for item in records:
        path=safe_target(home,item['path'])
        if not force and digest(path)!=item['installed']:raise ValueError('Changed since installation; restore stopped: '+item['path'])
    for item in records:
        path=safe_target(home,item['path'])
        if item['previous']:
            saved=backup/'files'/item['path']
            if path.exists() or path.is_symlink():path.unlink()
            shutil.copy2(saved,path,follow_symlinks=False)
        elif path.exists() or path.is_symlink():path.unlink()
    print('Previous files restored. Empty directories may remain. Log out and back in to restart the prior desktop.')

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--target-home',type=Path,default=Path.home(),help='Staging or destination home (default: your home)')
    p.add_argument('--config',type=Path,help='JSON choices; see examples/choices.json')
    p.add_argument('--dry-run',action='store_true',help='Preview without writing files')
    p.add_argument('--yes',action='store_true',help='Use supplied/default choices without interactive prompts')
    p.add_argument('--full',action='store_true',help='Install dependencies, configure services and SDDM (Arch, current user only)')
    p.add_argument('--files-only',action='store_true',help='Copy configuration without system integration')
    p.add_argument('--restore',type=Path,help='Restore an installation backup, preserving files changed afterward')
    args=p.parse_args();home=args.target_home.expanduser().resolve()
    if any(x in str(home) for x in '\n\r\t\"\'`$\\'):raise ValueError('Home path contains unsupported quoting characters.')
    if home==Path('/') or home==ROOT or ROOT.is_relative_to(home) and home!=Path.home():raise ValueError('Choose a normal user home or a separate staging directory.')
    if os.geteuid()==0 and home==Path.home():raise ValueError('Run as your normal user, not root.')
    if args.restore:
        if args.dry_run:raise ValueError('--restore and --dry-run cannot be combined.')
        restore(home,args.restore.resolve());return
    c=dict(DEFAULTS);c['extra_apps']=[]
    if args.config:c.update(json.loads(args.config.read_text()))
    if not args.yes:c=wizard(c)
    validate(c);items=plan(home,c)
    if args.full and args.files_only:raise ValueError('Choose either --full or --files-only.')
    if args.full and home!=Path.home().resolve():raise ValueError('--full cannot be used with a staging home.')
    actions=choose_actions(args,home)
    describe_actions(actions,c)
    print(f'Install {len(items)} files/links into {home}; theme: {c["theme"]}')
    missing=[shlex.split(c[k])[0] for k in ('browser','terminal','files','monitor') if not shutil.which(shlex.split(c[k])[0])]
    if missing:print('Selected commands not on PATH: '+', '.join(sorted(set(missing))))
    for role in ('browser','terminal','files','monitor'):print(role+': '+c[role])
    print('Keyboard: '+c['keyboard']+'; scale: '+str(c['scale']))
    print('Existing configuration files will be backed up. The running desktop will not be restarted.')
    if args.dry_run:
        for rel in items:print(('REPLACE ' if (home/rel).exists() or (home/rel).is_symlink() else 'ADD     ')+rel)
        return
    if not args.yes and input('Install these files? [y/N]: ').lower() not in ('y','yes'):return
    backup=install(home,items)
    print('Installed. Backup: '+str(backup))
    print('Restore: python3 setup.py --restore '+shlex.quote(str(backup)))
    successful=run_actions(ROOT,home,c,actions)
    print('Log out and enter Hyprland after completing any reported repairs.')
    print('Add ~/.local/bin to PATH if it is not already present. Your existing shell profile was left intact.')
    if not successful:raise ValueError('Configuration installed, but some setup steps need attention; see the log printed above.')
if __name__=='__main__':
    try:main()
    except (ValueError,OSError,KeyError,TypeError) as e:print('Setup stopped: '+str(e),file=sys.stderr);sys.exit(1)
