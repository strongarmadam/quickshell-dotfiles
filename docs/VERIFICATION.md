# Public export verification

Prepared 2026-10-27 on Arch Linux. The working desktop was not replaced by the
export or its installer.

Completed checks:

- Explicit file allowlist; excluded account integrations, application profiles,
  connection profiles, keyrings, caches, history, backups, and compiled binaries.
- Text scan for private keys, common provider-token formats, embedded secret
  assignments, personal home paths, and private IPv4 addresses; no findings.
- Relative-link audit: exported links remain inside the repository and resolve.
- Artwork re-encoded to remove metadata. Redistribution was confirmed by the owner.
- Python syntax, JSON parsing, shell syntax, Lua syntax, and QML parser checks.
- Seven automated setup tests cover reserved/duplicate shortcuts, all theme
  choices, custom app argv, clipboard/media toggles, fresh installs, replacement
  backups, symlink preservation, permissions, rollback, protection for subsequent
  edits, parent-directory symlink escapes, and write-free dry runs.
- Hyprland `--verify-config` passed for all eight installed stock themes in a
  temporary home and for a new custom theme generated from each.
- Theme generation preserved valid shared links and the generic media widget,
  and did not create optional app integrations.
- The exported Settings / Theme Creator loaded in a temporary home with an
  isolated D-Bus session and Qt's offscreen platform.

Limits: a complete clean-machine installation and login were not performed.
The compositor-dependent panels cannot run under Qt's offscreen platform
(`No PanelWindow backend loaded` is expected); their exported QML was parsed,
but Bluetooth pairing, network connections, live audio, and multi-monitor
behavior were not retested on a new physical machine. These features originated
from the working desktop. The source-only overview extension was not rebuilt
as part of this export. Credentials are not required to run verification.

Re-run `python3 scripts/check.py` after modifying the repository. Source checks
are conditional on the available Lua/Qt tools; Python, JSON, audit, and setup
tests always run. The checker does not start the desktop or change your config.

Theme-switcher regression checks: simulated an unavailable wallpaper daemon and
a failed desktop-service restart. Wallpaper failure no longer prevents the
compositor/widgets from updating; service errors return failure and are logged.
The suite now contains nine tests. This does not establish the cause of an
unexamined guest VM failure.

VM follow-up: the carousel was exercised in a running Arch guest and applied
Moonlit Forest successfully. Its non-accelerated graphics crashed hyprpaper;
a VM-only workaround uses the themes' existing Quickshell wallpaper layers.
The SDDM administrator installer was run in the guest. Both Moonlit Forest and
Coral Lagoon selections succeeded; an invalid name was rejected. SDDM loaded
the Moonlit Forest greeter successfully, and its actual login screen was visually
checked. No password or account configuration was changed.

## Installer integration update — 2026-10-28

- Interactive setup now offers dependency installation, selected supported apps,
  a source-built overview, NetworkManager/Bluetooth/audio enablement, and SDDM setup.
- All eight themes now use their existing Quickshell wallpaper layers by default;
  wallpaper preparation no longer contacts hyprpaper.
- The overview compiled successfully against the local Hyprland 0.56.2 headers
  using clang++, into a temporary home. Its fingerprint check passed. No compiled
  library is included in the public archive or installed into the source desktop.
- Sixteen automated tests pass, including package-failure short-circuiting,
  existing-network-manager preservation, staging restrictions, selected app
  dependencies, and stale/modified overview rejection. Source checks now cover
  the installer and scripts as well as desktop configuration.
- Full setup dry-run prints the proposed pacman transaction without executing it.
- A staged installation passed Hyprland configuration verification for all eight
  themes. Wallpaper preparation generated the overview image without hyprpaper.

The previously used VM is no longer registered with the local system libvirt
connection. The revised privileged package/service flow has automated command
mock tests, but has not been rerun end-to-end in a fresh VM. Earlier VM results
above apply to the earlier theme-switcher and SDDM repairs, not a complete test
of this revised installer. No live source-desktop configuration was replaced.
