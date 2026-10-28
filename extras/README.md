# Workspace overview source

`hyprexpo/` contains the source snapshot for this desktop's customized overview,
including its blurred theme backdrop. No compiled plugin is distributed.

The interactive wizard offers to build it by default. `setup.py --full --yes`
also builds it. The compiler runs in a temporary directory and only a successful
build replaces the installed plugin. The base desktop still works if building
fails; the setup log contains the compiler output and Super+W shows repair steps.

The installed source remains in `~/.local/share/quickshell-dotfiles/overview-source`.
After Hyprland or its dependencies change, run:

```sh
~/.local/bin/desktop-overview --build
```

Or, from this checkout:

```sh
./scripts/build-overview.sh
```

Build requirements include matching Hyprland headers, `base-devel`, `clang`, and
`pkgconf`. Full setup installs them through pacman. Future Hyprland releases may
require updated plugin source; rebuilding cannot fix an incompatible source API.

A fingerprint of the installed compositor, dependency versions and built plugin
is checked before loading. Stale or modified builds are skipped, leaving the
base desktop available. The plugin also checks the running compositor ABI.
Log out and back in after a successful build; setup never hot-loads the plugin.
