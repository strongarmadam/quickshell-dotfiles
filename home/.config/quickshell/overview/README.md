# Workspace overview

Super+W opens/closes this separate, on-demand Quickshell process. Click a tile,
use arrows (or H/J/K/L) and Enter, or press 1–9 to select a workspace. Escape
or a click outside the tiles dismisses it. More than three rows scroll.

The interface shows only workspace previews, with no labels or instructions.
Opening and closing use a smooth fade-and-scale transition. Incomplete last
rows are centered. The first five numbered workspaces are always shown. Additional numbered
workspaces expand the grid. Named/special workspaces are not included.
The focused monitor hosts the overview; each workspace uses its owning
monitor's geometry. Theme colors and wallpaper are read when it opens.

`backend.py` is the public Hyprland IPC adapter. It polls metadata only while
open; commands have timeouts and failures remain within this UI. Window
images use Quickshell's Wayland ScreencopyView, not compositor rendering hooks.
Unavailable capture falls back to application icons. Previews
reconstruct workspace layouts; they do not include desktop widgets, panels,
compositor effects, or exact window stacking. Inactive clients may not supply
fresh frames. No images are saved to disk.

For capture troubleshooting:

    OVERVIEW_NO_PREVIEWS=1 ~/.local/bin/workspace-overview

Close any existing overview first. Logs are under `$XDG_RUNTIME_DIR/quickshell`.
The launcher serializes shortcut presses and the process exits when dismissed.
No HyprExpo binary is loaded. Old plugin configuration is backed up in
the source desktop backup.

Update checks: run `python3 backend.py snapshot`, open the UI, verify live and
fallback cards, arrow navigation, Enter selection, Escape dismissal, and
repeated Super+W. `quickshell ipc -p ~/.config/quickshell/overview call overview
state` provides diagnostics while open. `setPreviews false` tests fallback.

## Verified on Hyprland 0.57.0 / Quickshell 0.3.2

- Live window preview and disabled-capture fallback visually inspected.
- Seven-workspace expansion and initial current-workspace selection.
- Arrow/Enter selection, Escape, Super+W dismissal, repeated launcher toggles.
- Configured launch action, QML lint, Python compilation, shell syntax, and
  Hyprland configuration validation.

`python3 tests/desktop-smoke.py` repeats the interactive checks. It briefly
switches workspaces and injects keys into the overview, then restores the
original numbered workspace in a finally block. Run it while not typing.
Synthetic events bypass global compositor shortcuts, so the launch check
invokes the configured action directly; dismissal is tested with Super+W.
