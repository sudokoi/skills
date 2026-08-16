#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY="$SCRIPT_DIR/inventory.tsv"

canonical_agent() {
  case "$1" in
    claude) printf 'claude-code' ;;
    gemini) printf 'gemini-cli' ;;
    *) printf '%s' "$1" ;;
  esac
}

AGENTS=""
WITH_COMMANDS=0
INCLUDE_OPTIONAL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agents)
      AGENTS="${2:-}"
      shift 2
      ;;
    --commands)
      WITH_COMMANDS=1
      shift
      ;;
    --include-optional)
      INCLUDE_OPTIONAL=1
      shift
      ;;
    -h | --help)
      cat <<'USAGE'
Usage: install.sh --agents <a,b,...> [--commands] [--include-optional]

  --agents <list>       Comma-separated agent names (opencode, cursor, codex, claude, gemini, ...).
  --commands            Also (re)create the opencode slash commands in ~/.config/opencode/commands/.
  --include-optional    Also install skills marked `optional:` in the inventory.

Examples:
  install.sh --agents opencode
  install.sh --agents opencode,cursor,codex --commands --include-optional
USAGE
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$AGENTS" ]]; then
  echo "error: --agents is required (comma-separated list)" >&2
  exit 1
fi

AGENT_LIST=()
oldIFS="$IFS"
IFS=','
for a in $AGENTS; do
  [[ -n "$a" ]] && AGENT_LIST+=("$(canonical_agent "$a")")
done
IFS="$oldIFS"

if [[ ${#AGENT_LIST[@]} -eq 0 ]]; then
  echo "error: no agents to install to" >&2
  exit 1
fi

echo "Agents: ${AGENT_LIST[*]}"
echo "Inventory: $INVENTORY"
echo

count=0
failed=0
skipped=0
while read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  category="recommended"
  if [[ "$line" == optional:* ]]; then
    category="optional"
    line="${line#optional:}"
    if [[ "$INCLUDE_OPTIONAL" -eq 0 ]]; then
      skipped=$((skipped + 1))
      echo "[skip] $line (optional; pass --include-optional to install)"
      continue
    fi
  fi
  read -r repo skill <<< "$line"
  for agent in "${AGENT_LIST[@]}"; do
    count=$((count + 1))
    echo "[$count] $skill ($repo, $category) -> $agent"
    if ! npx --yes skills add "$repo" --skill "$skill" --global --yes --agent "$agent" </dev/null; then
      echo "error: failed to install $skill for $agent" >&2
      failed=$((failed + 1))
    fi
  done
done < "$INVENTORY"

echo
echo "Done: $((count - failed))/$count installs succeeded, $skipped optional skills skipped."
if [[ "$failed" -gt 0 ]]; then
  exit 1
fi

if [[ "$WITH_COMMANDS" -eq 1 ]]; then
  echo
  "$SCRIPT_DIR/write-commands.sh"
fi
