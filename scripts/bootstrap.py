"""Explicit Arch system integration, separate from reversible home-file installation."""
import datetime
import pwd
import os
from pathlib import Path
import shlex
import shutil
import subprocess

CORE = '''hyprland quickshell hyprlock hyprpolkitagent
qt6-declarative qt6-svg qt6-imageformats python python-pillow
pipewire pipewire-pulse wireplumber libpulse fftw
networkmanager wpa_supplicant bluez bluez-utils upower
wl-clipboard cliphist grim slurp jq brightnessctl playerctl libnotify pavucontrol
imagemagick fontconfig ttf-jetbrains-mono-nerd adwaita-icon-theme
gtk3 gtk4 xdg-desktop-portal-hyprland xdg-desktop-portal-gtk nano'''.split()
BUILD = ['base-devel', 'clang', 'pkgconf']
APP_PACKAGES = {name: name for name in ('firefox', 'chromium', 'kitty', 'foot', 'alacritty', 'yazi', 'btop', 'thunar', 'dolphin', 'gnome-terminal', 'konsole', 'htop')}

def selected_programs(c):
    programs = set()
    for command in [c[k] for k in ('browser', 'terminal', 'files', 'monitor')] + [a['command'] for a in c['extra_apps']]:
        argv = shlex.split(command)
        programs.add(argv[0])
        terminal = shlex.split(c['terminal'])
        prefix = terminal + shlex.split(c['terminal_exec'])
        if argv[:len(prefix)] == prefix and len(argv) > len(prefix):
            programs.add(argv[len(prefix)])
    return programs

def package_plan(actions, c):
    packages = CORE.copy()
    if actions.get('overview'): packages += BUILD
    if actions.get('login'): packages += ['sddm', 'sudo']
    if actions.get('apps'): packages += [APP_PACKAGES[p] for p in sorted(selected_programs(c)) if p in APP_PACKAGES]
    return sorted(set(packages))

def choose_actions(args, home):
    if args.files_only or home != Path.home().resolve() or (args.yes and not args.full): return {}
    if not Path('/etc/arch-release').exists():
        if args.full: raise ValueError('Automatic dependencies currently support Arch Linux only; use --files-only elsewhere.')
        print('Non-Arch system: using files-only setup. See README for dependencies.')
        return {}
    actions = {}
    for key, label in [('packages', 'Install/update desktop dependencies with pacman'), ('apps', 'Install supported apps you selected'), ('overview', 'Build the workspace overview for this Hyprland'), ('services', 'Enable NetworkManager, Bluetooth, and user audio services'), ('login', 'Install matching SDDM login themes and enable SDDM at next boot')]:
        actions[key] = args.full or input(label + '? [Y/n]: ').strip().lower() not in ('n', 'no')
    if actions['apps'] and not actions['packages']:
        print('App installation skipped because package installation was declined.')
        actions['apps'] = False
    dm = Path('/etc/systemd/system/display-manager.service')
    if dm.exists() and dm.resolve().name != 'sddm.service':
        print('Keeping existing display manager: ' + dm.resolve().name + '. SDDM setup skipped.')
        actions['login'] = False
    return actions

def describe_actions(actions, c):
    if not actions:
        print('Files-only installation: no package, service, or login-manager changes.')
        return
    print('System integration: ' + ', '.join(k for k, enabled in actions.items() if enabled))
    if actions.get('packages'):
        print(shlex.join(['sudo', 'pacman', '-Syu', '--needed', *package_plan(actions, c)]))
    unknown = sorted(p for p in selected_programs(c) if p not in APP_PACKAGES and not shutil.which(p))
    if unknown: print('Install these custom application commands yourself: ' + ', '.join(unknown))
    print('No services or desktop sessions will be restarted. File rollback does not undo package/service changes.')

def run_actions(root, home, c, actions):
    if not any(actions.values()): return True
    if home != Path.home().resolve(): raise ValueError('System integration requires your actual home.')
    folder = home / '.local/state/quickshell-dotfiles'
    folder.mkdir(parents=True, exist_ok=True)
    log = folder / ('setup-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f') + '.log')
    failures = []
    def record(message):
        print(message, flush=True)
        with log.open('a') as stream: stream.write(message + '\n')
        log.chmod(0o600)
    def step(label, argv, interactive=False):
        record(label + ': ' + shlex.join(argv))
        try:
            if interactive:
                result = subprocess.run(argv, check=False)
            else:
                with log.open('a') as stream:
                    result = subprocess.run(argv, stdout=stream, stderr=subprocess.STDOUT, check=False)
            if result.returncode: raise RuntimeError('exit status ' + str(result.returncode))
        except (OSError, RuntimeError) as exc:
            failures.append(label); record(label + ': FAILED (' + str(exc) + ')'); return False
        record(label + ': OK'); return True
    if not actions.get('packages') and (actions.get('services') or actions.get('login')):
        if not step('Administrator authorization', ['sudo', '-v'], interactive=True): return False
    if actions.get('packages'):
        if not step('Dependencies', ['sudo', 'pacman', '-Syu', '--needed', *package_plan(actions, c)], interactive=True):
            record('Stopped system setup after package failure. Fix pacman, then rerun setup. Log: ' + str(log))
            return False
    if actions.get('overview'):
        step('Workspace overview', [str(home / '.local/bin/desktop-overview'), '--build'])
    step('Wallpaper assets', [str(home / '.local/bin/desktop-wallpaper'), '--prepare'])
    step('User service definitions', ['systemctl', '--user', 'daemon-reload'])
    if actions.get('services'):
        step('Audio on next login', ['systemctl', '--user', 'enable', 'pipewire.socket', 'pipewire-pulse.socket', 'wireplumber.service'])
        conflicts = []
        for unit in ('systemd-networkd.service', 'iwd.service', 'netctl.service'):
            if any(subprocess.run(['systemctl', state, '--quiet', unit], capture_output=True).returncode == 0 for state in ('is-active', 'is-enabled')):
                conflicts.append(unit)
        if conflicts:
            failures.append('NetworkManager')
            record('NetworkManager not enabled: existing network manager(s): ' + ', '.join(conflicts) + '. Choose your network manager manually.')
        else:
            step('NetworkManager on next boot', ['sudo', 'systemctl', 'enable', 'NetworkManager.service'])
        step('Bluetooth on next boot', ['sudo', 'systemctl', 'enable', 'bluetooth.service'])
    if actions.get('login'):
        if step('Login themes', ['sudo', 'python3', str(root / 'scripts/install-login-themes.py'), '--user', pwd.getpwuid(os.getuid()).pw_name]):
            dm = Path('/etc/systemd/system/display-manager.service')
            if not dm.exists() or dm.resolve().name == 'sddm.service':
                if step('SDDM on next boot', ['sudo', 'systemctl', 'enable', 'sddm.service']):
                    step('Graphical login on boot', ['sudo', 'systemctl', 'set-default', 'graphical.target'])
            else:
                failures.append('SDDM'); record('Existing display manager retained; SDDM not enabled.')
    step('Desktop diagnostics', [str(home / '.local/bin/desktop-doctor'), *([] if actions.get('overview') else ['--skip-overview'])])
    record(('Setup needs attention: ' + ', '.join(failures) if failures else 'Selected setup steps completed. Reboot to start enabled system services.') + '\nLog: ' + str(log))
    return not failures
