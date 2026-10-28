# Quickshell settings

Edit `~/.config/quickshell/settings.json`. Valid JSON changes are reloaded live.
Keep `version` at 1. Invalid JSON keeps the previous loaded settings and logs a warning.

- `shared`: settings for shared bar, launcher, notifications, power menu, and controls.
- `themes`: separate component settings for all five named themes.
- `layout`: saved monitor and positions for CPU, temperature, memory, network, and Spotify.

Component groups match QML filenames. `shell` contains the top-level instances.
Keys with `_2`, `_3`, etc. distinguish repeated properties in source order. For
example, shell implicitWidth through implicitWidth_4 are CPU, temperature,
memory, and network widths. Theme shell palette properties appear in Spotify,
power menu, then desktop UI order. Colors use Qt's #RRGGBB or #AARRGGBB format.
Pixel sizes use logical pixels. opacity ranges from 0 to 1; timer intervals are
milliseconds. Preserve valid dimensions and positive timer intervals.

Dragging saves only layout while preserving other settings. Reset with
`~/.local/bin/reset-quickshell-widget-layout`. The old layout JSON is retained
for rollback but is no longer read by the desktop.

QML files still contain implementation details, calculated geometry, animation
logic, and some inline styling. The centralized file exposes existing standalone
appearance, dimensions, spacing, font, and interval values; it is not a visual
editor and does not make every implementation constant a user preference.
Missing keys use the original QML value as a fallback.

Backup before migration:
`~/Archive/dotfiles-backups/quickshell-centralize-20261004-005417/`
