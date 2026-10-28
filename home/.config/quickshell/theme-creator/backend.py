#!/usr/bin/env python3
"""Create isolated, portable theme copies. Never edits shared settings or layouts."""
import configparser, copy, datetime, fcntl, hashlib, json, math, os, re, shutil, subprocess, sys, tempfile
from pathlib import Path
from urllib.parse import unquote, urlparse
HOME=Path.home(); THEMES=HOME/'.config/themes'; STATE=HOME/'.local/state/theme-creator'
SCHEMA=[]
def field(section,key,label,kind,default,low=None,high=None,options=None):
 d=dict(section=section,key=key,label=label,type=kind,default=default)
 if low is not None:d.update(min=low,max=high)
 if options:d['options']=options
 SCHEMA.append(d)
for key,label,default in [('background','Background','#07121d'),('panel','Panel surface','#102635'),('text','Text / font color','#e5f6ff'),('muted','Secondary text','#99b4c2'),('accent','Primary highlight','#58b8d7'),('highlight','Secondary highlight','#eab96c'),('border','Outlines','#36718c'),('inactiveBorder','Inactive window outlines','#294655'),('selection','Selected text background','#285c78'),('error','Errors / urgent','#ef8790')]:field('Colors',key,label,'color',default)
field('Wallpaper','wallpaper','Background image','file','')
for key,label,default,lo,hi in [('windowRadius','Window / tile rounding',12,0,60),('windowBorder','Window outline thickness',2,0,10),('gapsIn','Gap between tiles',5,0,40),('gapsOut','Outer desktop gap',12,0,80),('roundingPower','Window corner curve',2,2,10),('activeOpacity','Standard active-window opacity',1,0.2,1),('inactiveOpacity','Standard inactive-window opacity',1,0.2,1),('blurSize','Blur size',6,1,20),('blurPasses','Blur passes',3,1,6),('shadowRange','Shadow spread',12,1,60)]:field('Windows',key,label,'number',default,lo,hi)
for key,label,value in [('blur','Background blur',True),('shadows','Window shadows',False),('animations','Window animations',True)]:field('Windows',key,label,'bool',value)
for key,label,value,lo,hi in [('widgetRadius','Widget / panel rounding',12,0,80),('widgetBorder','Widget outline thickness',1,0,10),('panelOpacity','Panel opacity',0.85,0.1,1),('buttonRadius','Button / icon-box rounding',10,0,50),('widgetWidth','Monitor widget width',260,180,500),('widgetHeight','Monitor widget height',100,80,220),('widgetPadding','Widget inner padding',14,4,35)]:field('Widgets & icons',key,label,'number',value,lo,hi)
field('Widgets & icons','iconShape','Status-bar icon boxes','enum','Rounded',options=['Square','Rounded','Pill'])
field('Widgets & icons','launcherSymbol','Launcher symbol','enum','diamond',options=['square','circle','triangle','diamond','bar','ring','crescent'])
field('Widgets & icons','ringAccents','Outlined highlight style','bool',False)
field('Typography','fontFamily','Desktop / widget font','font','JetBrainsMono Nerd Font')
field('Typography','fontSize','Widget text size','number',12,8,24)
field('GTK','gtkTheme','GTK base theme','gtkTheme','Adwaita-dark')
field('GTK','iconTheme','Application icon theme','iconTheme','Adwaita')
field('GTK','gtkFont','GTK font','font','Sans')
field('GTK','gtkFontSize','GTK font size (points)','number',11,8,24)
field('GTK','gtkDark','Prefer dark application appearance','bool',True)
field('GTK','gtkRadius','GTK control rounding','number',10,0,40)
field('GTK','gtkBorder','GTK control outline thickness','number',1,0,6)
for key,label,value,kind,lo,hi in [('kittyFont','Terminal font','monospace','font',None,None),('kittySize','Terminal font size',13,'number',6,32),('kittyOpacity','Terminal background opacity',0.88,'number',0.1,1),('kittyPadding','Terminal padding',6,'number',0,40)]:field('Kitty',key,label,kind,value,lo,hi)
field('Kitty','kittyCursor','Cursor shape','enum','block',options=['block','beam','underline'])
field('Kitty','kittyTabs','Tab style','enum','powerline',options=['powerline','slant','separator','fade','hidden'])
field('Kitty','kittyTabEdge','Tab position','enum','bottom',options=['top','bottom'])
field('Kitty','kittyLigatures','Font ligatures','bool',False)
ansi=['#151b22','#e87882','#79c89a','#e5c07b','#73a9e6','#b69be5','#6dcbd0','#d8e1e9','#617184','#ff9ba4','#a0e3b8','#ffe0a0','#9ac6ff','#d6baff','#9eeaf0','#ffffff']
for i,value in enumerate(ansi):field('Terminal palette','ansi'+str(i),'ANSI color '+str(i),'color',value)

def write(path,data):
 path.parent.mkdir(parents=True,exist_ok=True);path.write_text(data)
def atomic(path,data):
 path.parent.mkdir(parents=True,exist_ok=True);fd,tmp=tempfile.mkstemp(dir=path.parent)
 try:
  with os.fdopen(fd,'w') as out:out.write(data);out.flush();os.fsync(out.fileno())
  os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
def valid_name(name):
 if not isinstance(name,str) or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9 _-]{0,47}',name) or name.lower()=='current':raise ValueError('Use 1–48 letters, numbers, spaces, hyphens or underscores for the theme name.')
 return name.strip()
def theme_path(name):
 valid_name(name);p=THEMES/name
 if p.is_symlink() or not (p/'quickshell/shell.qml').is_file():raise ValueError('Select an existing desktop theme.')
 return p
def revision(p):
 h=hashlib.sha256()
 for f in sorted(p.rglob('*')):
  if f.is_file() and not f.is_symlink():h.update(str(f.relative_to(p)).encode());h.update(f.read_bytes())
 return h.hexdigest()
def values_for(p):
 custom=p/'creator-settings.json'
 if custom.exists():return json.loads(custom.read_text())['values']
 values={}
 pattern=r'Config\.Settings\.value\("'+re.escape(p.name)+r'",\s*"([^"\n]+)",\s*"([^"\n]+)",\s*("(?:\\.|[^"\\])*"|true|false|-?[0-9]+(?:\.[0-9]+)?)\s*\)'
 for qml in (p/'quickshell').rglob('*.qml'):
  if qml.is_symlink():continue
  for component,key,raw in re.findall(pattern,qml.read_text()):values.setdefault(component,{})[key]=json.loads(raw)
 for component,fields in json.loads((HOME/'.config/quickshell/settings.json').read_text())['themes'].get(p.name,{}).items():values.setdefault(component,{}).update(fields)
 return values
def infer(p):
 manifest=p/'creator.json'
 if manifest.exists():return json.loads(manifest.read_text())['values']
 d={f['key']:f['default'] for f in SCHEMA};values=values_for(p);shell=values.get('shell',{})
 for key,src in [('panel','panelColor_3'),('text','textColor_3'),('accent','accentColor_3'),('border','edgeColor_3')]:
  c=shell.get(src,d[key]);d[key]='#'+c[-6:]
 d.update(background=d['panel'],widgetRadius=shell.get('cornerRadius_3',12),widgetBorder=shell.get('edgeWidth_3',1),launcherSymbol=shell.get('launcherSymbol','diamond'))
 wall=next((p/n for n in ('wallpaper.png','wallpaper.jpg') if (p/n).is_file()),None);d['wallpaper']=str(wall or '')
 config=(p/'hyprland.lua').read_text()
 for key,option in [('windowRadius','rounding'),('windowBorder','border_size'),('gapsIn','gaps_in'),('gapsOut','gaps_out'),('roundingPower','rounding_power'),('activeOpacity','active_opacity'),('inactiveOpacity','inactive_opacity')]:
  m=re.search(r'\b'+option+r'\s*=\s*([0-9.]+)',config)
  if m:d[key]=float(m.group(1))
 kitty=(p/'kitty/kitty.conf').read_text()
 for key,option in [('kittyFont','font_family'),('kittySize','font_size'),('kittyPadding','window_padding_width'),('kittyCursor','cursor_shape'),('kittyTabs','tab_bar_style'),('kittyTabEdge','tab_bar_edge')]+[('ansi'+str(i),'color'+str(i)) for i in range(16)]:
  m=re.search(r'^'+option+r'\s+([^\n#]+|#[a-fA-F0-9]{6})',kitty,re.M)
  if m:
   value=m.group(1).strip();d[key]=float(value) if key in ('kittySize','kittyPadding') else value
 return d

def validate(raw):
 if not isinstance(raw,dict):raise ValueError('Invalid theme settings.')
 result={}
 for f in SCHEMA:
  key=f['key'];v=raw.get(key,f['default']);kind=f['type']
  if kind=='number':
   if type(v) not in (int,float) or not math.isfinite(v) or not f['min']<=v<=f['max']:raise ValueError(f"{f['label']}: enter a value from {f['min']} to {f['max']}.")
  elif kind=='bool':
   if type(v) is not bool:raise ValueError(f"Invalid toggle: {f['label']}")
  elif kind=='enum':
   if v not in f['options']:raise ValueError(f"Invalid choice: {f['label']}")
  elif kind=='color':
   if not isinstance(v,str) or not re.fullmatch(r'#[0-9a-fA-F]{6}',v):raise ValueError(f"{f['label']}: use #RRGGBB.")
  elif not isinstance(v,str) or len(v)>4096 or any(ord(c)<32 for c in v):raise ValueError(f"Invalid text: {f['label']}")
  result[key]=v
 for key in ('fontFamily','gtkFont','kittyFont','gtkTheme','iconTheme'):
  if not result[key].strip() or any(c in result[key] for c in '\\";{}'):raise ValueError('Use a plain font or theme name for '+key)
 return result

def render_settings(source,d):
 settings=copy.deepcopy(values_for(source));alpha=f"{round(d['panelOpacity']*255):02x}";panel='#'+alpha+d['panel'][1:]
 for component,fields in settings.items():
  for key,old in list(fields.items()):
   low=key.lower()
   if key.startswith('font.family'):fields[key]=d['fontFamily']
   elif key.startswith('font.pixelSize'):fields[key]=d['fontSize']
   elif key.startswith(('panelColor','glassColor')):fields[key]=panel
   elif key.startswith(('edgeColor','glassBorder','border.color')):fields[key]=d['border']
   elif key.startswith('textColor'):fields[key]=d['text']
   elif key.startswith('accentColor'):fields[key]=d['accent']
   elif key.startswith(('cornerRadius','radius')) and key not in ('radius_2',):fields[key]=d['widgetRadius']
   elif key.startswith(('edgeWidth','border.width')):fields[key]=d['widgetBorder']
   elif key.startswith('panelOpacity'):fields[key]=1
   elif key=='color':fields[key]=panel if component in ('CpuWidget','TempWidget','MemoryWidget','NetworkWidget') else d['text']
   elif key=='color_2':fields[key]=d['accent']
   elif key=='color_3':fields[key]=d['text']
   elif key=='anchors.margins':fields[key]=d['widgetPadding']
  if component in ('CpuWidget','TempWidget','MemoryWidget','NetworkWidget'):
   fields.update(width=d['widgetWidth'],height=d['widgetHeight'],opacity=1)
   if 'height_3' in fields:fields['height_3']=max(20,d['widgetHeight']-52)
   if component=='NetworkWidget':fields['height_2']=max(20,d['widgetHeight']-52)
 shell=settings.setdefault('shell',{})
 for suffix in ('','_2','_3'):
  shell.update({k+suffix:v for k,v in dict(panelColor=panel,textColor=d['text'],accentColor=d['accent'],edgeColor=d['border'],cornerRadius=d['widgetRadius'],edgeWidth=d['widgetBorder'],panelOpacity=1).items()})
 for suffix in ('','_2','_3','_4'):shell.update({'implicitWidth'+suffix:d['widgetWidth'],'implicitHeight'+suffix:d['widgetHeight']})
 shell['launcherSymbol']=d['launcherSymbol']
 return settings

def generate(stage,source,name,d):
 # Copy real theme assets, preserving shared links. Internal links follow the new theme.
 shutil.copytree(source,stage,symlinks=True)
 for p in list(stage.rglob('*')):
  if p.is_symlink():
   dest=os.readlink(p)
   if dest.startswith(str(source)):
    p.unlink();p.symlink_to(str(THEMES/name)+dest[len(str(source)):])
  elif p.is_file() and p.suffix in ('.qml','.lua','.css','.qss','.json','.conf','.ini','.qrc','.desktop','.md'):
   try:text=p.read_text()
   except UnicodeError:continue
   p.write_text(text.replace(str(source),str(THEMES/name)).replace('/.config/themes/'+source.name+'/', '/.config/themes/'+name+'/').replace('"'+source.name+'"','"'+name+'"'))
 for p in stage.glob('wallpaper.*'):p.unlink()
 wall=d['wallpaper'];wall=unquote(urlparse(wall).path) if wall.startswith('file:') else wall
 wall=Path(wall).expanduser().resolve()
 if not wall.is_file() or wall.stat().st_size>100*1024*1024:raise ValueError('Choose a local image smaller than 100 MB.')
 from PIL import Image,ImageOps
 with Image.open(wall) as im:
  im=ImageOps.exif_transpose(im);im.convert('RGB').save(stage/'wallpaper.png')
 for qmlfile in (stage/'quickshell').rglob('*.qml'):
  if qmlfile.is_symlink():continue
  text=qmlfile.read_text();text=re.sub(r'(/.config/themes/'+re.escape(name)+r'/)wallpaper\.(?:jpg|jpeg|png)',r'\1wallpaper.png',text);qmlfile.write_text(text)
 for component in ('CpuWidget','TempWidget','MemoryWidget','NetworkWidget','Glass'):
  widget=stage/'quickshell/widgets'/(component+'.qml')
  if widget.exists() and not widget.is_symlink():
   text=widget.read_text();text=re.sub(r'^    radius:.*$', '    radius: '+str(d['widgetRadius']),text,flags=re.M)
   if component=='NetworkWidget':
    text=re.sub(r'(property color downloadColor:) [^\n]+',r'\1 '+json.dumps(d['accent']),text)
    text=re.sub(r'(property color uploadColor:) [^\n]+',r'\1 '+json.dumps(d['highlight']),text)
   widget.write_text(text)
 graph=stage/'quickshell/widgets/Graph.qml'
 if graph.exists() and not graph.is_symlink():graph.write_text(re.sub(r'(property color lineColor:) [^\n]+',r'\1 '+json.dumps(d['highlight']),graph.read_text()))
 # New copies keep shared DesktopUi and other shared symlinks, including calendar policy.
 for component in ('DesktopUi.qml','UiButton.qml'):
  shared=stage/'quickshell/widgets'/component
  if shared.exists() or shared.is_symlink():shared.unlink()
  shared.symlink_to(os.path.relpath(HOME/'.config/quickshell/components'/component, THEMES/name/'quickshell/widgets'))
 write(stage/'creator-settings.json',json.dumps({'name':name,'values':render_settings(source,d)},indent=2)+'\n')
 qml=stage/'quickshell/shell.qml';text=qml.read_text()
 # Remove prior creator-only properties when editing a custom theme.
 text=re.sub(r'^\s*// Theme Creator appearance\n.*?^\s*// End Theme Creator appearance\n','',text,flags=re.M|re.S)
 text=re.sub(r'^\s*(clockTextColor|barButtonRadius|launcherBubbles|ringAccents|pillVolumeControls):[^\n]*\n','',text,flags=re.M)
 radius=0 if d['iconShape']=='Square' else 999 if d['iconShape']=='Pill' else d['buttonRadius']
 block='\n        // Theme Creator appearance\n'+''.join('        '+k+': '+json.dumps(v)+'\n' for k,v in {'clockTextColor':d['highlight'],'barButtonRadius':radius,'ringAccents':d['ringAccents'],'pillVolumeControls':d['iconShape']=='Pill','themeFontFamily':d['fontFamily'],'themeFontSize':d['fontSize'],'buttonHoverColor':'#18'+d['highlight'][1:],'buttonCornerRadius':radius,'panelOpacity':1}.items())+'        // End Theme Creator appearance\n'
 # shell DesktopUi rarely has a panelOpacity override; use creator override only.
 start=text.index('    DesktopUi {');end=text.index('\n    }',start)
 section=re.sub(r'^\s*panelOpacity:.*\n','',text[start:end],flags=re.M)
 text=text[:start]+section+text[end:];text=text.replace('    DesktopUi {','    DesktopUi {'+block)
 text=re.sub(r'layout.stackTop\(screen\) \+ [0-9]+', lambda m, counter=iter(range(4)): 'layout.stackTop(screen) + '+str(round(next(counter)*(d['widgetHeight']+8))), text)
 write(qml,text)
 lua=stage/'hyprland.lua';text=lua.read_text();text=re.sub(r'\n-- BEGIN THEME CREATOR.*?-- END THEME CREATOR\n','\n',text,flags=re.S)
 rgb=lambda key:'rgba('+d[key][1:]+'ff)'
 text+='\n-- BEGIN THEME CREATOR\nhl.config({\n general = { gaps_in = %s, gaps_out = %s, border_size = %s, col = { active_border = { colors = { "%s", "%s" }, angle = 45 }, inactive_border = "%s" } },\n decoration = { rounding = %s, rounding_power = %s, active_opacity = %s, inactive_opacity = %s, blur = { enabled = %s, size = %s, passes = %s }, shadow = { enabled = %s, range = %s } },\n animations = { enabled = %s }\n})\n-- END THEME CREATOR\n' % (d['gapsIn'],d['gapsOut'],int(d['windowBorder']),rgb('accent'),rgb('highlight'),rgb('inactiveBorder'),int(d['windowRadius']),d['roundingPower'],d['activeOpacity'],d['inactiveOpacity'],str(d['blur']).lower(),int(d['blurSize']),int(d['blurPasses']),str(d['shadows']).lower(),int(d['shadowRange']),str(d['animations']).lower())
 write(lua,text)
 gtk='''/* Generated theme-specific GTK appearance */
@define-color theme_bg_color %(background)s;
@define-color theme_fg_color %(text)s;
@define-color theme_selected_bg_color %(selection)s;
@define-color theme_selected_fg_color %(text)s;
@define-color accent_color %(accent)s;
@define-color accent_bg_color %(accent)s;
@define-color accent_fg_color %(background)s;
* { font-family: "%(gtkFont)s"; font-size: %(gtkFontSize)spt; }
window, window.background, .background { background-color: %(background)s; color: %(text)s; }
headerbar, toolbar, menubar, popover, menu, dialog, .sidebar { background-color: %(panel)s; color: %(text)s; }
headerbar { border-bottom: %(gtkBorder)spx solid %(border)s; box-shadow: none; }
button, entry, spinbutton, combobox, searchentry { background-image: none; background-color: %(panel)s; color: %(text)s; border: %(gtkBorder)spx solid %(border)s; border-radius: %(gtkRadius)spx; box-shadow: none; }
button:hover, button:checked, row:hover { background-color: %(selection)s; color: %(text)s; border-color: %(highlight)s; }
entry:focus, button:focus { border-color: %(accent)s; }
selection, *:selected { background-color: %(selection)s; color: %(text)s; }
progressbar progress, scale highlight, switch:checked { background-color: %(accent)s; }
scrollbar slider { background-color: %(border)s; min-width: 6px; min-height: 6px; border-radius: %(gtkRadius)spx; }
.warning, .error { color: %(error)s; }
'''%d
 for ver in ('gtk-3.0','gtk-4.0'):
  write(stage/ver/'gtk.css',gtk)
  write(stage/ver/'settings.ini','[Settings]\ngtk-theme-name='+d['gtkTheme']+'\ngtk-icon-theme-name='+d['iconTheme']+'\ngtk-font-name='+d['gtkFont']+' '+str(d['gtkFontSize'])+'\ngtk-application-prefer-dark-theme='+str(int(d['gtkDark']))+'\n')
 kitty={'font_family':d['kittyFont'],'font_size':d['kittySize'],'background':d['background'],'foreground':d['text'],'cursor':d['accent'],'selection_background':d['selection'],'selection_foreground':d['text'],'window_padding_width':d['kittyPadding'],'cursor_shape':d['kittyCursor'],'tab_bar_style':d['kittyTabs'],'tab_bar_edge':d['kittyTabEdge'],'disable_ligatures':'never' if d['kittyLigatures'] else 'always','active_tab_background':d['accent'],'active_tab_foreground':d['background'],'inactive_tab_background':d['panel'],'inactive_tab_foreground':d['muted'],'enable_audio_bell':'no'}
 kitty.update({'color'+str(i):d['ansi'+str(i)] for i in range(16)})
 write(stage/'kitty/kitty.conf','\n'.join(str(k)+' '+str(v) for k,v in kitty.items())+'\n')
 write(stage/'kitty/creator-overrides.conf',f"# Theme-specific overrides after shared defaults\nfont_size {d['kittySize']}\nbackground_opacity {d['kittyOpacity']}\ndynamic_background_opacity yes\n")
 p=stage/'kitty.conf'
 if p.exists() or p.is_symlink():p.unlink()
 p.symlink_to('kitty/kitty.conf')
 # Keep a matching login-theme export; installing SDDM themes is a system operation.
 login=stage/'sddm'
 if login.exists():
  cp=configparser.ConfigParser();cp.optionxform=str;cp.read(login/'theme.conf');g=cp['General']
  g.update(ThemeName=name,Wallpaper='wallpaper.png',BackgroundColor=d['background'],PanelColor=d['panel'],OutlineColor=d['border'],TextColor=d['text'],AccentColor=d['accent'],ButtonColor=d['highlight'],PanelRadius=str(d['widgetRadius']),ControlRadius=str(d['buttonRadius']),EdgeWidth=str(d['widgetBorder']))
  with (login/'theme.conf').open('w') as f:cp.write(f,space_around_delimiters=False)
  shutil.copy2(stage/'wallpaper.png',login/'wallpaper.png')
  metadata=login/'metadata.desktop'
  if metadata.exists():
   text=metadata.read_text();text=re.sub(r'^Name=.*$', 'Name='+name,text,flags=re.M);text=re.sub(r'^Theme-Id=.*$','Theme-Id='+name.lower().replace(' ','-'),text,flags=re.M);metadata.write_text(text)
 values=copy.deepcopy(d);values['wallpaper']=str(THEMES/name/'wallpaper.png')
 write(stage/'creator.json',json.dumps({'version':1,'name':name,'base':source.name,'values':values},indent=2)+'\n')
 write(stage/'README.md',f'# {name}\n\nCreated with Quickshell Theme Creator. Edit it from Quickshell Settings.\nShared behavior and machine-local widget positions are preserved.\nGTK apps may need restarting to load a new palette. Login theme assets are exported in sddm/; installing them requires administrator access.\n')

def catalog():
 names=[p.name for p in THEMES.iterdir() if not p.is_symlink() and not p.name.startswith('.') and (p/'quickshell/shell.qml').is_file()]
 fonts=subprocess.run(['fc-list',':','family'],capture_output=True,text=True,timeout=10)
 return dict(schema=SCHEMA,themes=sorted(names),custom=[n for n in names if (THEMES/n/'creator.json').exists()],current=(THEMES/'current').resolve().name,fonts=sorted(set(x.split(',')[0].strip() for x in fonts.stdout.splitlines() if x.strip())),gtkThemes=sorted({'Adwaita','Adwaita-dark'} | {p.name for folder in [Path('/usr/share/themes'),HOME/'.themes',HOME/'.local/share/themes'] if folder.exists() for p in folder.iterdir() if p.is_dir()}),iconThemes=sorted({p.name for folder in [Path('/usr/share/icons'),HOME/'.icons',HOME/'.local/share/icons'] if folder.exists() for p in folder.iterdir() if (p/'index.theme').exists()}))
def save_theme(req):
 name=valid_name(req['name']);source=theme_path(req['source']);target=THEMES/name;d=validate(req['values'])
 updating=req.get('update',False)
 if updating:
  if source!=target or not (target/'creator.json').exists():raise ValueError('Only themes made in Theme Creator can be updated. Use Save new theme for a built-in theme.')
 elif target.exists():raise ValueError('That theme name already exists. Choose a new name.')
 if revision(source)!=req.get('revision'):raise ValueError('The source theme changed. Reload it before saving.')
 STATE.mkdir(parents=True,exist_ok=True)
 with (STATE/'lock').open('w') as lock:
  fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
  if revision(source)!=req.get('revision'):raise ValueError('The source changed while saving. Reload it first.')
  if not updating and target.exists():raise ValueError('That theme name already exists.')
  container=Path(tempfile.mkdtemp(dir=STATE));stage=container/name
  try:
   generate(stage,source,name,d)
   backup=None
   if updating:
    backup=HOME/'Archive/dotfiles-backups/theme-creator'/(datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')+'-'+name);backup.parent.mkdir(parents=True,exist_ok=True);os.replace(target,backup)
   try:os.replace(stage,target)
   except Exception:
    if backup:os.replace(backup,target)
    raise
  finally:shutil.rmtree(container)
 return dict(name=name,revision=revision(target),values=infer(target),custom=True,message='Theme saved. Choose Apply to use it. Login theme assets are exported separately.')
def activate(name):
 p=theme_path(name);manifest=p/'creator.json';baseline=STATE/'gtk-baseline.json';STATE.mkdir(parents=True,exist_ok=True)
 keys=('gtk-theme-name','gtk-icon-theme-name','gtk-font-name','gtk-application-prefer-dark-theme')
 saved=json.loads(baseline.read_text()) if baseline.exists() else {}
 for ver in ('gtk-3.0','gtk-4.0'):
  target=HOME/'.config'/ver/'settings.ini';cp=configparser.ConfigParser(interpolation=None);cp.optionxform=str;cp.read(target)
  if 'Settings' not in cp:cp['Settings']={}
  if manifest.exists():
   if ver not in saved:saved[ver]={k:cp['Settings'].get(k) for k in keys}
   src=configparser.ConfigParser();src.read(p/ver/'settings.ini')
   for key in keys:cp['Settings'][key]=src['Settings'][key]
  elif ver in saved:
   for key,value in saved[ver].items():
    if value is None:cp['Settings'].pop(key,None)
    else:cp['Settings'][key]=value
  else:continue
  from io import StringIO
  out=StringIO();cp.write(out,space_around_delimiters=False);atomic(target,out.getvalue())
 if saved and manifest.exists():atomic(baseline,json.dumps(saved,indent=2))
 elif baseline.exists():baseline.unlink()
 return dict(message='Theme-specific application settings applied.')
def main():
 action=sys.argv[1];req=json.loads(sys.argv[2]) if len(sys.argv)>2 else {}
 if action=='catalog':return catalog()
 if action=='load':
  p=theme_path(req['name']);return dict(name=p.name,values=infer(p),revision=revision(p),custom=(p/'creator.json').exists())
 if action=='save':return save_theme(req)
 if action=='activate':return activate(req['name'])
 if action=='apply':
  name=req['name'];theme_path(name)
  result=subprocess.run([str(HOME/'.local/bin/theme-switcher'),name],capture_output=True,text=True,timeout=90)
  if result.returncode:raise RuntimeError(result.stderr[-1200:] or 'Theme could not be applied.')
  return dict(message='Applied '+name+'. Reopen GTK apps if their styling has not refreshed.')
 raise ValueError('Unknown action')
if __name__=='__main__':
 try:print(json.dumps(dict(ok=True,**main())))
 except Exception as e:print(json.dumps(dict(ok=False,message=str(e))));sys.exit(1)
