# Floating window memory

Loaded by `~/.config/hypr/floating-window-memory.lua` on Hyprland 0.57.
Closing a normal floating app window saves its logical size and monitor-relative
position. Opening that app restores floating mode and geometry. The last closed
window wins when an app has multiple windows. Closing it tiled clears its saved
floating layout. Fullscreen windows and common file dialogs are excluded.
Quickshell windows use separate initial titles to distinguish its tools.

State is plain data in `~/.local/state/floating-window-memory/windows.tsv`, within
a private directory. It survives config reloads and logins and is never executed.
Disconnected monitors fall back to the opening monitor; geometry is constrained
to available space. Application size constraints can still limit exact sizing.

To disable, remove `require("floating-window-memory")` from hyprland.lua and
reload Hyprland. Original configuration: hyprland.lua.before-floating-window-memory.
