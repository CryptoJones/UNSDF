#!/usr/bin/env bash
# Self-contained launcher — zero manual steps, ever. Always imports assets before
# launch (incremental, cheap); if the import errors on a stale/corrupt cache it
# wipes .godot and rebuilds from scratch automatically. Guarantees a fresh clone
# OR a `git pull` with new art comes up correctly instead of a black screen.
# Usage: ./run.sh [extra godot args]   (e.g. ./run.sh --headless --quit-after 30)
set -euo pipefail
cd "$(dirname "$0")"

GODOT="${GODOT:-$(command -v godot || echo "$HOME/.local/bin/godot")}"
[ -x "$GODOT" ] || { echo "Godot not found. Set \$GODOT or install godot on PATH." >&2; exit 1; }

echo "Using $("$GODOT" --version 2>/dev/null | head -1)"
echo "Importing assets…"
if ! "$GODOT" --headless --path . --import; then
  echo "Import errored — rebuilding the .godot cache from scratch…"
  rm -rf .godot
  "$GODOT" --headless --path . --import
fi

exec "$GODOT" --path . "$@"
