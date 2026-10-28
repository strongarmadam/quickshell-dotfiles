# Quickshell desktop dotfiles

An eight-theme Hyprland desktop built around Quickshell: a retractable status bar,
movable system monitors, a theme carousel, and a native theme creator.

This is a curated public export of a working desktop, not a full home-directory
backup. Application binaries, account integrations, credentials, personal state,
and machine-specific monitor settings are excluded.

## Included

- Eight themes: 16-bit Sunset, Annapurna Retro, Autumn Grove, Bakery Hearth,
  Coral Lagoon, Moonlit Forest, Rivendell, and Space Green.
- Animated status bar, workspace buttons, running-app icons, system tray, audio
  controls, battery, disk use, dynamic Wi-Fi strength, and Ethernet status.
- CPU, memory, temperature, and network widgets; drag them with Super + left mouse.
- Generic MPRIS media controls and a live output-audio spectrum. No music app or account required.
- Standalone calendar, notifications, app launcher, clipboard history, Bluetooth,
  network connection picker, power/lock menu, and shortcut editor.
- Theme Creator: wallpaper, colors, highlights, outlines, shapes, fonts, window
  effects, GTK, Kitty, and ANSI colors. Existing themes are protected from overwrite.
- Theme-aware GTK/Kitty styling, session-lock configuration, and SDDM theme assets.
- Source for the customized workspace-overview plugin, built locally by the setup wizard by default.

| Moonlit Forest | Coral Lagoon |
| --- | --- |
| ![Moonlit Forest wallpaper](home/.config/themes/Moonlit%20Forest/wallpaper.jpg) | ![Coral Lagoon wallpaper](home/.config/themes/Coral%20Lagoon/wallpaper.jpg) |

These images show included wallpapers, not screenshots of an installed desktop.

## Requirements

The source machine used **Hyprland 0.56.2**, **Quickshell 0.3.2**, **Qt 6.12**,
on Arch Linux. The compositor configuration uses the
[Hyprland Lua API](https://wiki.hypr.land/configuring/core/); it is not a legacy
`hyprland.conf` setup. Quickshell is the [QtQuick desktop toolkit](https://quickshell.org/).
Other distributions and future compositor versions may need adjustments.

Core runtime packages on Arch (review before installing):

```sh
sudo pacman -Syu --needed hyprland quickshell hyprlock hyprpolkitagent \
  qt6-declarative qt6-svg qt6-imageformats python python-pillow \
  pipewire pipewire-pulse wireplumber libpulse fftw \
  networkmanager wpa_supplicant bluez bluez-utils upower \
  wl-clipboard cliphist grim slurp jq brightnessctl playerctl libnotify pavucontrol \
  imagemagick fontconfig ttf-jetbrains-mono-nerd adwaita-icon-theme \
  gtk3 gtk4 xdg-desktop-portal-hyprland xdg-desktop-portal-gtk nano
```

The interactive wizard offers to install these dependencies, and only the supported
apps you select. Defaults are Firefox, Kitty, Yazi, and btop; each can be changed.
Custom commands are preserved, but unrecognized apps must be installed manually.
No optional app binaries, profiles, or account integrations are bundled.

Quickshell renders the wallpaper in all eight themes. No hyprpaper daemon or
VM-specific wallpaper workaround is needed. ImageMagick prepares the separate
lock/overview assets. A working Hyprland/Wayland graphics setup is still required.

## Setup

On a minimal Arch installation, first install Python (and Git if cloning):

```sh
sudo pacman -Syu --needed python git
```

Clone or extract this repository, then run as your normal user:

```sh
python3 setup.py
```

The wizard asks for app commands and launch shortcuts, initial theme, keyboard
layout, display scale, clipboard history, media-widget visibility, and additional
app shortcuts. It then offers dependency installation, selected app installation,
a local overview build, NetworkManager/Bluetooth/audio enablement, and matching SDDM
login themes. Review the printed plan before confirming. System steps use sudo;
pacman retains its normal transaction confirmation. Commands support arguments using normal shell-style quoting, but
are executed as argument lists: shell pipes, redirects, and command substitutions
are not evaluated. Use a separate script if you need a complex launch action.

For a preview or repeatable install:

```sh
python3 setup.py --config examples/choices.json --yes --dry-run
python3 setup.py --config examples/choices.json --yes
```

For the complete setup with default choices (pacman may still prompt):

```sh
python3 setup.py --full --yes
```

For an existing desktop where you want to manage dependencies yourself:

```sh
python3 setup.py --files-only
```

`--yes` alone remains files-only. `--dry-run` never changes anything, including
packages and services. `--target-home` stages files only; it cannot be combined
with `--full`. You can preview full setup with `--full --yes --dry-run`.

Setup copies the curated configuration and overview source, expands home paths,
creates relative links, and backs up replaced files under
`~/.local/state/quickshell-dotfiles/backups/`. Unrelated files are retained.
The wizard never restarts your session or system services. Enabled services take
effect at the next boot. Choosing SDDM also selects graphical login as the boot
default. It preserves another existing display manager, and
reports conflicting network managers instead of taking over networking.
It does not set a system-wide default browser or alter accounts or passwords.
Do not run it against your working source desktop merely to export it.

Failures produce a nonzero exit status and a log under
`~/.local/state/quickshell-dotfiles/setup-*.log`. Fix the reported issue and rerun.
A failed overview build leaves the base desktop usable; Super+W explains how to
rebuild. Build tools (`base-devel`, `clang`, `pkgconf`) are added when selected.

After installation:

```sh
systemctl --user daemon-reload
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

Log out and select Hyprland in your existing session manager. The session startup
launches the desktop (including its wallpaper), authentication agent, and clipboard watcher (if selected). Stop any
other bar or notification daemon in your own startup configuration; Quickshell
provides both. The installer does not kill those applications for you.

`~/.config/hypr/hardware.lua` contains the new machine's monitor/input choices.
Edit this file for multiple displays. Prefer a scale supported by your monitor;
Super + Shift + `=` / `-` adjusts to the nearest supported scale in 10% steps.
The temperature helper detects common AMD/Intel sensors and falls back to Linux
thermal zones; unsupported machines show zero rather than invented readings.

App choices live in `~/.config/desktop-apps.json`; launch bindings are in
`~/.config/hypr/apps.lua`. The browser choice controls its shortcut and launcher
web searches. Set your distribution's default browser separately if desired.
For terminal execution, Kitty/foot/Alacritty use `-e`; GNOME Terminal uses `--`.

Use Quickshell Settings → Theme Creator, or run:

```sh
~/.local/bin/quickshell-settings creator
```

The media spectrum reads the default audio output only while an MPRIS player is
playing, and never stores audio. Clipboard history is local and can contain
sensitive copied text; choose **no** in setup if you do not want it. Neither
history nor media metadata is part of this repository.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| Super + Return / B / E | Terminal / browser / files; configurable during setup |
| Super + Space | Application launcher |
| Super + Q | Hide/show monitor widgets; restore their home positions |
| Super + Shift + Q | Hide/show status bar |
| Super + Shift + T | Theme carousel |
| Super + Shift + B / N | Bluetooth / network picker |
| Super + D / N / H | Calendar / notifications / clipboard history |
| Super + Shift + slash | Shortcut list and editor |
| Super + Shift + K | Power and lock menu |
| Super + Shift + S | Region screenshot; saves under Pictures/Screenshots |
| Super + Shift + `=` / `-` | Display scaling |
| Super + arrows | Focus window |
| Super + J / K / L | Previous / next / fifth workspace |
| Super + 1…0 | Select workspace; add Shift to move a window |
| Super + C / Shift + C | Close app / close all windows |
| Super + F / V | Fullscreen / floating |
| Super + left/right mouse drag | Move / resize window; left drag also moves widgets |
| Super + Shift + Escape | Immediate system power-off |
| Super + W | Workspace overview; built during full setup |

The close-app helper sends a normal close request, waits, then terminates the
process if it has no mapped windows left (for applications that otherwise hide
in the tray). Adjust this binding if you prefer compositor-only closing.

## Rollback

The installer prints the exact restore command. For example, substitute your
backup directory in:

```sh
python3 setup.py --restore ~/.local/state/quickshell-dotfiles/backups/TIMESTAMP
```

**File rollback does not uninstall packages, undo service enablement, or restore
system-wide login themes.** Login-theme backups are stored separately under
`/var/lib/quickshell-dotfiles/login-backups/`.

Restoration checks all installed files before changing anything and refuses to
overwrite later edits. Save those edits elsewhere, or restore selected original
files manually from the backup's `files/` directory. Original symlinks and modes
are retained. Backups may contain **your old private settings**: never upload them.

Rerunning setup reapplies the supplied settings and creates another backup. It
is not a merge tool for edits made to installed theme/config files.

## Extra components

- **Workspace overview:** see [extras/README.md](extras/README.md). No compiled
  plugin is shipped; the wizard builds it for the installed Hyprland. A stale
  or modified binary is skipped. Rebuild with `~/.local/bin/desktop-overview --build`
  after compositor/dependency upgrades, then log out and back in.
- **Login themes:** offered in the wizard. To add them later, run:

  ```sh
  sudo python3 scripts/install-login-themes.py
  ```

  This installs the eight bundled SDDM themes and selects your current theme.
  A root-owned helper accepts only those eight names; a narrow sudoers entry
  lets your desktop switcher update the next login screen without a password
  prompt. Existing system files are backed up under
  `/var/lib/quickshell-dotfiles/login-backups/`. It does not restart SDDM or
  change PAM, autologin, accounts, or passwords. The matching screen appears on
  the next SDDM start. Custom Theme Creator themes still require a separate
  administrator installation; the helper intentionally accepts bundled names only.
  SDDM is system-wide: on a multi-user computer, the last theme selection wins.
- Keyboard-pointer positioning previously used a separate third-party binary.
  That optional app and its bindings are deliberately not included.

## Verification and sharing

```sh
python3 scripts/check.py
python3 scripts/audit.py
```

The checker validates Python/JSON/shell/Lua, parses QML when Qt's `qmlformat` is
installed, checks links and credential patterns, and exercises install/rollback
in temporary directories. See [docs/VERIFICATION.md](docs/VERIFICATION.md) for
what was tested, and [docs/SHARING.md](docs/SHARING.md) for a GitHub/post checklist.

The author confirmed that the bundled artwork can be redistributed. Image
metadata was removed. Original code uses the MIT license; third-party source
retains its own license. See [THIRD_PARTY.md](THIRD_PARTY.md).

## Theme-switching diagnostics

If the carousel opens but applying a theme fails, run:

```sh
~/.local/bin/theme-switcher "Coral Lagoon"
cat ~/.local/state/quickshell-dotfiles/theme-switcher.log
~/.local/bin/desktop-doctor
```

The switcher refreshes user-service definitions and the session environment.
Wallpaper failures are reported separately and do not block the widgets or
compositor from updating. A desktop-service or compositor failure is reported
as a partial application, with a diagnostic log.
