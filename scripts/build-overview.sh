#!/usr/bin/env bash
set -euo pipefail
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec python3 "$root/home/.local/bin/desktop-overview" --build --source "$root/extras/hyprexpo"
