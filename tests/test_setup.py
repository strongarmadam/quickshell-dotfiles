import importlib.util,json,os,subprocess,tempfile,unittest
from pathlib import Path
spec=importlib.util.spec_from_file_location('setup',Path(__file__).resolve().parents[1]/'setup.py');s=importlib.util.module_from_spec(spec);spec.loader.exec_module(s)
class SetupTests(unittest.TestCase):
 def choices(self):return dict(s.DEFAULTS,extra_apps=[])
 def test_reserved_shortcuts(self):
  for key in ['SUPER + Q','SUPER + SHIFT + Q','SUPER + C','SUPER + 3','SUPER + SHIFT + B','SUPER + SPACE','SUPER + W']:
   c=self.choices();c['browser_key']=key
   with self.assertRaises(ValueError,msg=key):s.validate(c)
  c=self.choices();c['browser_key']='SUPER + E'
  with self.assertRaises(ValueError):s.validate(c)
 def test_all_themes_and_custom_choices(self):
  with tempfile.TemporaryDirectory() as t:
   for theme in (s.ROOT/'home/.config/themes').iterdir():
    c=self.choices();c.update(theme=theme.name,browser='chromium --incognito',terminal='foot',files='thunar',clipboard=False,media=False,extra_apps=[{'name':'editor','key':'SUPER + X','command':'code --new-window'}]);s.validate(c)
    plan=s.plan(Path(t),c);apps=json.loads(plan['.config/desktop-apps.json'][1]);self.assertEqual(apps['browser'],['chromium','--incognito']);self.assertIn('editor',apps)
    self.assertNotIn(b'clipboard-history.service',plan['.config/hypr/hyprland.lua'][1]);self.assertFalse(json.loads(plan['.config/quickshell/settings.json'][1])['shared']['Visibility']['media'])
 def test_install_restore_and_links(self):
  with tempfile.TemporaryDirectory() as t:
   h=Path(t);old=h/'.config/hypr/hyprland.lua';old.parent.mkdir(parents=True);old.write_text('original');old.chmod(0o600)
   oldlink=h/'.config/kitty/kitty.conf';oldlink.parent.mkdir();original=h/'original.conf';original.write_text('original kitty');oldlink.symlink_to(original)
   b=s.install(h,s.plan(h,self.choices()))
   for p in h.rglob('*'):
    if '.local/state' in str(p):continue
    if p.is_symlink():self.assertTrue(p.exists(),str(p));self.assertTrue(p.resolve().is_relative_to(h),str(p))
   self.assertEqual(original.read_text(),'original kitty');self.assertNotIn('@HOME@',old.read_text())
   s.restore(h,b);self.assertEqual(old.read_text(),'original');self.assertEqual(old.stat().st_mode&0o777,0o600);self.assertTrue(oldlink.is_symlink());self.assertEqual(oldlink.resolve(),original)
   self.assertFalse((h/'.local/bin/desktop-app').exists())
 def test_restore_protects_new_edits(self):
  with tempfile.TemporaryDirectory() as t:
   h=Path(t);b=s.install(h,{'test':('file',b'installed',0o644)});(h/'test').write_text('user edit')
   with self.assertRaises(ValueError):s.restore(h,b)
   self.assertEqual((h/'test').read_text(),'user edit')
 def test_parent_symlink_cannot_escape(self):
  with tempfile.TemporaryDirectory() as t,tempfile.TemporaryDirectory() as out:
   h=Path(t);(h/'.config').symlink_to(out)
   with self.assertRaises(ValueError):s.plan(h,self.choices())
 def test_dry_run_writes_nothing(self):
  with tempfile.TemporaryDirectory() as t:
   h=Path(t)/'unused';subprocess.run(['python3',str(s.ROOT/'setup.py'),'--yes','--dry-run','--target-home',str(h)],check=True,stdout=subprocess.DEVNULL);self.assertFalse(h.exists())
 def test_invalid_inputs(self):
  for patch in [{'scale':float('nan')},{'keyboard':'us"; os.execute("x")'},{'theme':'../private'},{'extra_apps':[{'name':'browser','command':'firefox','key':'SUPER + X'}]}]:
   c=self.choices();c.update(patch)
   with self.assertRaises(ValueError):s.validate(c)
if __name__=='__main__':unittest.main()
