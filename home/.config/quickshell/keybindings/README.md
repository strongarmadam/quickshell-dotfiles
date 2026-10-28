# Keyboard shortcuts

Super + Shift + / toggles this popup. Escape closes it. Search filters the
live Hyprland bindings by action, shortcut or mode, including mouse/media keys.

Type a key combination and Save to edit its original Lua binding and reload
Hyprland. Duplicate combinations in the same mode are rejected. Generated
bindings (workspace numbers and overview arrows) use Edit source, which opens
Nano at the corresponding line: Ctrl+O, Enter saves; Ctrl+X exits. Click Reload
config afterward. Edit source also lets you change an action manually.

Backups are kept in ~/.local/state/keybindings-history. Direct saves roll back
if Hyprland reports a config error. Edits affect the current machine only;
normal desktop deployment can copy them to Portable Arch. App-internal
shortcuts are maintained by the apps and are not included in this list.

Appearance follows the active theme's DesktopUi colors, panel opacity, borders,
and corners, including settings overrides. Changes are picked up within two
seconds while open. Hyprland applies the current theme's compositor blur;
text remains fully opaque while the panel background is translucent.
