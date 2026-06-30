#!/usr/bin/env bash
# Import-then-run. Always runs an (incremental) import before launch so a fresh
# clone OR a `git pull` that brings new/changed assets is fully imported —
# otherwise class_name globals and imported textures are missing and the game
# renders a black screen. Incremental import only re-processes changed files, so
# it's cheap after the first run.
# Usage: ./run.sh [extra godot args]   (e.g. ./run.sh --headless --quit-after 30)
set -euo pipefail
cd "$(dirname "$0")"

GODOT="${GODOT:-$(command -v godot || echo "$HOME/.local/bin/godot")}"
[ -x "$GODOT" ] || { echo "Godot not found. Set \$GODOT or install godot on PATH." >&2; exit 1; }

echo "Using $("$GODOT" --version 2>/dev/null | head -1) at $GODOT"
echo "Importing assets (incremental)…"
"$GODOT" --headless --path . --import

exec "$GODOT" --path . "$@"
