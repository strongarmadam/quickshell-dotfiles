import argparse
import contextlib
import importlib.machinery
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
from scripts import bootstrap as b
import setup

class BootstrapTests(unittest.TestCase):
    def args(self, **kw):
        return argparse.Namespace(**dict(dict(files_only=False, full=False, yes=True), **kw))

    def test_noninteractive_and_staging_never_offer_system_actions(self):
        with patch('builtins.input', side_effect=AssertionError('Unexpected prompt')):
            self.assertEqual(b.choose_actions(self.args(), Path.home().resolve()), {})
            self.assertEqual(b.choose_actions(self.args(yes=False), Path('/tmp/staging')), {})
            self.assertEqual(b.choose_actions(self.args(files_only=True), Path.home().resolve()), {})

    def test_selected_apps_only_and_terminal_payload(self):
        choices = dict(setup.DEFAULTS, browser='chromium --incognito', extra_apps=[])
        packages = b.package_plan({'apps': True, 'overview': True}, choices)
        self.assertIn('chromium', packages)
        self.assertIn('yazi', packages)
        self.assertIn('btop', packages)
        self.assertNotIn('clang', packages)
        self.assertNotIn('firefox', packages)
        self.assertNotIn('hyprpaper', packages)
        self.assertNotIn('sddm', packages)
        self.assertNotIn('chromium', b.package_plan({}, choices))

    def test_full_staging_rejected_without_writing(self):
        with tempfile.TemporaryDirectory() as folder:
            target = Path(folder) / 'unused'
            result = subprocess.run(['python3', str(setup.ROOT/'setup.py'), '--full', '--yes', '--target-home', str(target)], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(target.exists())

    def test_failed_packages_stop_privileged_steps(self):
        with tempfile.TemporaryDirectory() as folder:
            home = Path(folder)
            with patch.object(Path, 'home', return_value=home), patch.object(b.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1)) as run, contextlib.redirect_stdout(io.StringIO()):
                self.assertFalse(b.run_actions(setup.ROOT, home, setup.DEFAULTS, {'packages':True,'overview':True,'login':True,'services':True}))
                self.assertEqual(run.call_count, 1)
                self.assertEqual(run.call_args.args[0][:3], ['sudo','pacman','-Syu'])

    def test_declined_actions_do_nothing(self):
        with patch.object(b.subprocess, 'run', side_effect=AssertionError('Unexpected command')):
            self.assertTrue(b.run_actions(setup.ROOT, Path('/tmp/not-home'), setup.DEFAULTS, {}))

    def test_network_manager_conflict_preserves_existing_manager(self):
        with tempfile.TemporaryDirectory() as folder:
            home = Path(folder)
            def command(argv, **kwargs):
                rc = 0
                if argv[0] == 'systemctl' and 'is-active' in argv: rc = 0 if argv[-1] == 'iwd.service' else 1
                elif argv[0] == 'systemctl' and 'is-enabled' in argv: rc = 1
                return subprocess.CompletedProcess(argv, rc)
            with patch.object(Path, 'home', return_value=home), patch.object(b.subprocess, 'run', side_effect=command) as run, contextlib.redirect_stdout(io.StringIO()):
                self.assertFalse(b.run_actions(setup.ROOT, home, setup.DEFAULTS, {'services':True}))
                calls = [c.args[0] for c in run.call_args_list]
                self.assertNotIn(['sudo','systemctl','enable','NetworkManager.service'], calls)
                self.assertIn(['sudo','systemctl','enable','bluetooth.service'], calls)

class OverviewTests(unittest.TestCase):
    def test_setup_installs_standalone_overview_without_plugin_source(self):
        files = setup.plan(Path('/tmp/overview-test-home'), setup.DEFAULTS)
        self.assertIn('.config/quickshell/overview/shell.qml', files)
        self.assertIn('.local/bin/workspace-overview', files)
        self.assertFalse(any('overview-source/' in name for name in files))
        self.assertNotIn(b'hl.plugin.load', files['.config/hypr/workspace-overview.lua'][1])
        self.assertIn(b'/tmp/overview-test-home/.local/bin/workspace-overview', files['.config/hypr/workspace-overview.lua'][1])
