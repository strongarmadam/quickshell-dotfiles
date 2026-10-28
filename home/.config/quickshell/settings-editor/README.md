# Quickshell Settings

Open **Quickshell Settings** from the app launcher, or run `quickshell-settings`.

Choose Theme appearance, Shared components, or Widget positions. The editor
selects the current theme at launch; choosing another theme edits it without
switching your desktop theme. Search filters settings in the selected component.

Edit a value and press Apply or Enter. Toggles save immediately. Color fields
accept #RRGGBB or #AARRGGBB (alpha first). Opacity runs from 0 to 1. Dimensions
are logical pixels; monitoring intervals are milliseconds. Widget Y positions
are relative to the top reserved desktop area.

Shared components → Show / hide widgets controls the five desktop widgets.
Theme appearance → Desktop & widget frames contains their outer dimensions,
as well as Spotify, power menu, and desktop bar palettes. The other sections
expose the existing component styling and spacing. Shared defaults may be
superseded by theme-specific settings.

Reset restores one field to its value when the editor was created. Each successful
save first copies the previous settings to
`~/.local/state/quickshell-settings-history/`. Saves merge into the latest file
and reject stale edits to the same field. Reloading or changing sections discards
unapplied text edits. The editor controls exposed Quickshell settings; Kitty and
Hyprland settings are maintained separately.

The pre-editor backup is in
`~/Archive/dotfiles-backups/quickshell-settings-gui-20261004-010622/`.
