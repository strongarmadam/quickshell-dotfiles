# Theme Creator

Open Quickshell Settings → Theme Creator, or launch **Theme Creator** directly.

1. Select an existing theme as the starting point.
2. Give the draft a new name. Choose a wallpaper and edit the categorized controls.
3. **Save new theme** creates an independent, portable theme directory.
4. **Apply saved theme** selects it through the existing theme switcher.
5. Load a custom theme later and use **Save changes**. Every update has a backup in
   `~/Archive/dotfiles-backups/theme-creator/`.

The preview is illustrative; actual window blur and app rendering vary.
GTK programs may need reopening. Apps with their own styling may ignore GTK CSS.
Matching SDDM login assets are exported under the theme's `sddm/` directory.
Installing those system assets still requires administrator access.

Each custom theme has `creator.json` (editable draft settings) and
`creator-settings.json` (theme-local Quickshell settings). Shared settings,
shortcuts, widget visibility/home positions, monitor setup, and credentials are
not copied into the draft or modified by saving it. Existing built-in themes
cannot be overwritten from the creator.

GTK preferences are saved before applying the first custom theme, and restored
when returning to a built-in theme. Kitty theme overrides are included after
shared defaults and only exist for creator themes.

Dependencies: Python + Pillow, ImageMagick (existing wallpaper application),
fontconfig, Qt Quick Dialogs.
