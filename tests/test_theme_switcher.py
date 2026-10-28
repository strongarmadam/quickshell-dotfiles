import importlib.util,os,subprocess,tempfile,unittest
from pathlib import Path
spec=importlib.util.spec_from_file_location('setup',Path(__file__).resolve().parents[1]/'setup.py');s=importlib.util.module_from_spec(spec);spec.loader.exec_module(s)
class ThemeSwitcherTests(unittest.TestCase):
 def run_switch(self,service_fails=False):
  with tempfile.TemporaryDirectory() as t:
   h=Path(t);s.install(h,s.plan(h,s.DEFAULTS));fake=h/'fakebin';fake.mkdir();trace=h/'calls'
   script='#!/usr/bin/python3\nimport os,sys\nfrom pathlib import Path\nwith open(os.environ["CALL_TRACE"],"a") as f:f.write(Path(sys.argv[0]).name+" "+" ".join(sys.argv[1:])+"\\n")\nif os.environ.get("FAIL_RESTART")=="yes" and "restart" in sys.argv:print("service failed",file=sys.stderr);sys.exit(1)\n'
   for name in ('hyprctl','systemctl','notify-send','pkill'):
    p=fake/name;p.write_text(script);p.chmod(0o755)
   p=h/'.local/bin/desktop-wallpaper';p.write_text('#!/bin/sh\necho "wallpaper daemon unavailable" >&2\nexit 1\n');p.chmod(0o755)
   env=dict(os.environ,HOME=str(h),PATH=str(fake)+':'+os.environ['PATH'],CALL_TRACE=str(trace),FAIL_RESTART='yes' if service_fails else 'no',WAYLAND_DISPLAY='test-wayland')
   result=subprocess.run([str(h/'.local/bin/theme-switcher'),'Coral Lagoon'],env=env,capture_output=True,text=True)
   self.assertEqual((h/'.config/themes/current').resolve().name,'Coral Lagoon')
   calls=trace.read_text();self.assertIn('hyprctl reload',calls);self.assertIn('systemctl --user restart quickshell-desktop.service',calls);self.assertIn('import-environment',calls)
   log=(h/'.local/state/quickshell-dotfiles/theme-switcher.log').read_text();self.assertIn('wallpaper daemon unavailable',log)
   self.assertEqual(result.returncode,1 if service_fails else 0)
   self.assertIn('Theme only partly applied' if service_fails else 'with warnings',calls)
 def test_wallpaper_failure_does_not_block_theme(self):self.run_switch()
 def test_service_failure_is_reported(self):self.run_switch(service_fails=True)
if __name__=='__main__':unittest.main()
