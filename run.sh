#!/usr/bin/env bash
# Import-then-run, so a fresh clone never dies on missing class_name globals.
# Usage: ./run.sh [extra godot args]   (e.g. ./run.sh --headless --quit-after 30)
set -euo pipefail
cd "$(dirname "$0")"

GODOT="${GODOT:-$(command -v godot || echo "$HOME/.local/bin/godot")}"
[ -x "$GODOT" ] || { echo "Godot not found. Set \$GODOT or install to ~/.local/bin/godot" >&2; exit 1; }

# First run only: build .godot/global_script_class_cache.cfg
[ -f .godot/global_script_class_cache.cfg ] || "$GODOT" --headless --path . --import

exec "$GODOT" --path . "$@"
