# Clipboard history
Super+H opens/closes the themed clipboard picker (replaces first-workspace shortcut;
Super+1 still selects workspace 1). Type to search, use arrows/Enter or click to
copy an entry, then paste normally in the destination app. Escape/outside click
closes the picker. Delete removes one entry; Clear all requires a second click.
Pause stops recording until Resume, including across restarts.

Requires cliphist and wl-clipboard. clipboard-history.service records at login.
History is private to this device: ~/.local/state/desktop-clipboard, mode 0700.
It is never included in desktop deployment. Up to 200 entries, 5 MiB per entry.
Text and images are restored byte-for-byte. Sensitive clipboard hints are skipped;
apps that do not provide such hints cannot be reliably identified as sensitive.

Appearance reads the same theme resolver as the keyboard shortcut helper.
