#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_SRC="$SCRIPT_DIR/../commands"
COMMANDS_DEST="${OPENCODE_COMMANDS_DIR:-$HOME/.config/opencode/commands}"

if [[ ! -d "$COMMANDS_SRC" ]]; then
  echo "error: no commands directory at $COMMANDS_SRC" >&2
  exit 1
fi

mkdir -p "$COMMANDS_DEST"

count=0
for src in "$COMMANDS_SRC"/*.md; do
  [[ -e "$src" ]] || continue
  name="$(basename "$src")"
  dest="$COMMANDS_DEST/$name"
  cp "$src" "$dest"
  count=$((count + 1))
  echo "  wrote $dest"
done

echo "Wrote $count opencode commands to $COMMANDS_DEST"
