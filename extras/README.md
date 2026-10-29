# Legacy overview source

`hyprexpo/` is retained as historical source for the former native plugin.
It is not installed, built, or loaded by the current setup. It targets Hyprland
0.56 and does not compile against 0.57 without a substantial port.

The active overview is in `home/.config/quickshell/overview/`, runs as a separate
Quickshell process, and requires no compiler or compositor plugin.
