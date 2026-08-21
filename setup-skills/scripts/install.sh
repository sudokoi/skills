#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY="${SKILLS_INVENTORY:-$SCRIPT_DIR/inventory.tsv}"
SELECTION_FILE="${SKILLS_SELECTION_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/setup-skills/selection}"
GLOBAL_SKILLS_DIR="$HOME/.agents/skills"

CATEGORIES=(core react kotlin architecture process tooling)

canonical_agent() {
  case "$1" in
    claude) printf 'claude-code' ;;
    gemini) printf 'gemini-cli' ;;
    *) printf '%s' "$1" ;;
  esac
}

AGENTS=""
ALL_MODE=0
WITH_COMMANDS=0
DRY_RUN=0
PRINT_SELECTION=0

usage() {
  cat <<'USAGE'
Usage: install.sh --agents <a,b,...> [--all] [--commands] [--dry-run]

  --agents <list>       Comma-separated agent names (opencode, cursor, codex, claude,
                        gemini, windsurf, zed, warp, github-copilot, ...). `claude`
                        and `gemini` are mapped to claude-code and gemini-cli.
  --all                 Install every inventory skill without the category picker.
  --commands            Also (re)create the opencode slash commands in
                        ~/.config/opencode/commands/.
  --dry-run             Print the full plan instead of installing (never interactive).
  --print-selection     Print the remembered category selection (known entries only)
                        and exit.

Without --all (and outside --dry-run) an interactive category tree is shown.
The picked categories are remembered in
${XDG_CONFIG_HOME:-~/.config}/setup-skills/selection and pre-checked on the
next run. SKILLS_INVENTORY and SKILLS_SELECTION_FILE override the default
inventory and selection paths.

Examples:
  install.sh --agents opencode
  install.sh --agents opencode,cursor,codex --commands
  install.sh --agents opencode --all
  install.sh --agents opencode --dry-run
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agents)
      AGENTS="${2:-}"
      shift 2
      ;;
    --all)
      ALL_MODE=1
      shift
      ;;
    --commands)
      WITH_COMMANDS=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --print-selection)
      PRINT_SELECTION=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$AGENTS" && "$PRINT_SELECTION" -eq 0 ]]; then
  echo "error: --agents is required (comma-separated list)" >&2
  usage >&2
  exit 1
fi

AGENT_LIST=()
oldIFS="$IFS"
IFS=','
for a in $AGENTS; do
  [[ -n "$a" ]] && AGENT_LIST+=("$(canonical_agent "$a")")
done
IFS="$oldIFS"

if [[ ${#AGENT_LIST[@]} -eq 0 && "$PRINT_SELECTION" -eq 0 ]]; then
  echo "error: no agents to install to" >&2
  exit 1
fi

INV_REPO=()
INV_SKILL=()
INV_CAT=()

lineno=0
while IFS=$'\t' read -r repo skill cat extra || [[ -n "${repo:-}" ]]; do
  lineno=$((lineno + 1))
  repo="${repo%$'\r'}"
  [[ -z "$repo" || "$repo" == \#* ]] && continue
  skill="${skill%$'\r'}"
  cat="${cat%$'\r'}"
  extra="${extra%$'\r'}"
  if [[ -z "$skill" || -z "$cat" || -n "$extra" ]]; then
    echo "error: $INVENTORY:$lineno: expected '<repo> <skill> <category>'" >&2
    exit 1
  fi
  found=-1
  for ci in "${!CATEGORIES[@]}"; do
    [[ "${CATEGORIES[$ci]}" == "$cat" ]] && found=$ci
  done
  if [[ "$found" -eq -1 ]]; then
    echo "error: $INVENTORY:$lineno: unknown category '$cat' (known: ${CATEGORIES[*]})" >&2
    exit 1
  fi
  INV_REPO+=("$repo")
  INV_SKILL+=("$skill")
  INV_CAT+=("$cat")
done < "$INVENTORY"

if [[ ${#INV_SKILL[@]} -eq 0 ]]; then
  echo "error: inventory is empty: $INVENTORY" >&2
  exit 1
fi

is_installed() {
  [[ -f "$GLOBAL_SKILLS_DIR/$1/SKILL.md" ]]
}

if [[ -n "${NO_COLOR:-}" ]]; then
  BOLD=""
  DIM=""
  RESET=""
else
  BOLD="\033[1m"
  DIM="\033[2m"
  RESET="\033[0m"
fi

SEL=(0 0 0 0 0 0)

load_selection() {
  local c ci
  [[ -r "$SELECTION_FILE" ]] || return 0
  while IFS= read -r c || [[ -n "$c" ]]; do
    c="${c%$'\r'}"
    for ci in "${!CATEGORIES[@]}"; do
      if [[ "${CATEGORIES[$ci]}" == "$c" ]]; then SEL[ci]=1; fi
    done
  done < "$SELECTION_FILE"
  return 0
}

if [[ "$PRINT_SELECTION" -eq 1 ]]; then
  load_selection
  for ci in "${!CATEGORIES[@]}"; do
    if [[ "${SEL[ci]}" -eq 1 ]]; then printf '%s\n' "${CATEGORIES[$ci]}"; fi
  done
  exit 0
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Agents: ${AGENT_LIST[*]}"
  echo "Inventory: $INVENTORY"
  echo
  planned=0
  for i in "${!INV_SKILL[@]}"; do
    for agent in "${AGENT_LIST[@]}"; do
      echo "[plan] ${INV_SKILL[$i]} (${INV_REPO[$i]}, ${INV_CAT[$i]}) -> $agent"
      planned=$((planned + 1))
    done
  done
  echo
  echo "Plan: $planned install(s) across ${#AGENT_LIST[@]} agent(s)."
  exit 0
fi

INTERACTIVE=0
if [[ "$ALL_MODE" -eq 0 ]]; then
  if [[ ! -t 0 || ! -t 1 ]]; then
    echo "error: interactive selection needs a terminal; pass --all to skip it" >&2
    exit 1
  fi
  INTERACTIVE=1
fi

CAT_SKILL_COUNT=()
CAT_INSTALLED=()
for ci in "${!CATEGORIES[@]}"; do
  n=0
  inst=0
  for i in "${!INV_SKILL[@]}"; do
    [[ "${INV_CAT[$i]}" == "${CATEGORIES[$ci]}" ]] || continue
    n=$((n + 1))
    is_installed "${INV_SKILL[$i]}" && inst=$((inst + 1))
  done
  CAT_SKILL_COUNT+=("$n")
  CAT_INSTALLED+=("$inst")
done

if [[ "$INTERACTIVE" -eq 1 ]]; then
  load_selection
fi

if [[ "$ALL_MODE" -eq 1 ]]; then
  for ci in "${!CATEGORIES[@]}"; do
    SEL[ci]=1
  done
fi

SAVE_STTY=""
TUI_ACTIVE=0
LAST_LINES=0
CUR=0
STATUS=""
ABORT=0

restore_tty() {
  if [[ "$TUI_ACTIVE" -eq 1 ]]; then
    TUI_ACTIVE=0
    stty "$SAVE_STTY"
    printf '\033[?25h'
  fi
}
trap restore_tty EXIT
trap 'exit 130' INT TERM

read_key() {
  KEY="none"
  local k k2 k3
  IFS= read -rsn1 k || {
    KEY="eof"
    return 0
  }
  case "$k" in
    $'\033')
      IFS= read -rsn1 k2 || return 0
      if [[ "$k2" == "[" ]]; then
        IFS= read -rsn1 k3 || return 0
        case "$k3" in
          A) KEY="up" ;;
          B) KEY="down" ;;
        esac
      fi
      ;;
    $'\r' | $'\n' | "") KEY="enter" ;;
    ' ') KEY="space" ;;
    a | A) KEY="all" ;;
    j | J) KEY="down" ;;
    k | K) KEY="up" ;;
    q | Q) KEY="quit" ;;
  esac
}

ask_confirm() {
  local default_yes="$2" ans=""
  stty "$SAVE_STTY"
  read -rp "  $1 " ans
  stty raw -echo
  if [[ "$default_yes" -eq 1 ]]; then
    [[ ! "$ans" =~ ^[Nn] ]]
  else
    [[ "$ans" =~ ^[Yy] ]]
  fi
}

render() {
  local out="" ci i cursor box mark
  if [[ "$LAST_LINES" -gt 0 ]]; then
    out+="\033[${LAST_LINES}A"
  fi
  out+="\r\033[K${BOLD}Select skill categories${RESET}\n"
  out+="\r\033[K${DIM}(space toggle · a all/none · arrows move · enter install · q quit)${RESET}\n"
  for ci in "${!CATEGORIES[@]}"; do
    if [[ "$ci" -eq "$CUR" ]]; then
      cursor="${BOLD}❯ ${RESET}"
    else
      cursor="  "
    fi
    if [[ "${SEL[$ci]}" -eq 1 ]]; then box="[x]"; else box="[ ]"; fi
    out+="\r\033[K${cursor}${box} ${CATEGORIES[$ci]}  (${CAT_SKILL_COUNT[$ci]} skills, ${CAT_INSTALLED[$ci]} installed)\n"
    for i in "${!INV_SKILL[@]}"; do
      [[ "${INV_CAT[$i]}" == "${CATEGORIES[$ci]}" ]] || continue
      mark=""
      is_installed "${INV_SKILL[$i]}" && mark="  ✓"
      out+="\r\033[K      · ${INV_SKILL[$i]}${mark}\n"
    done
  done
  out+="\r\033[K${STATUS}\n"
  LAST_LINES=2
  for ci in "${!CATEGORIES[@]}"; do
    LAST_LINES=$((LAST_LINES + 1 + CAT_SKILL_COUNT[ci]))
  done
  LAST_LINES=$((LAST_LINES + 1))
  printf '%b' "$out"
}

if [[ "$INTERACTIVE" -eq 1 ]]; then
  SAVE_STTY="$(stty -g)"
  TUI_ACTIVE=1
  stty raw -echo
  printf '\033[?25l'
  render
  while :; do
    read_key
    case "$KEY" in
      eof)
        ABORT=1
        break
        ;;
      up)
        [[ "$CUR" -gt 0 ]] && CUR=$((CUR - 1))
        STATUS=""
        ;;
      down)
        [[ "$CUR" -lt $((${#CATEGORIES[@]} - 1)) ]] && CUR=$((CUR + 1))
        STATUS=""
        ;;
      space)
        if [[ "${SEL[CUR]}" -eq 1 ]]; then SEL[CUR]=0; else SEL[CUR]=1; fi
        STATUS=""
        ;;
      all)
        any_off=0
        for ci in "${!CATEGORIES[@]}"; do
          [[ "${SEL[$ci]}" -eq 0 ]] && any_off=1
        done
        for ci in "${!CATEGORIES[@]}"; do
          if [[ "$any_off" -eq 1 ]]; then SEL[ci]=1; else SEL[ci]=0; fi
        done
        if [[ "$any_off" -eq 1 ]]; then STATUS="all categories selected"; else STATUS="selection cleared"; fi
        ;;
      enter)
        any_sel=0
        for ci in "${!CATEGORIES[@]}"; do
          [[ "${SEL[$ci]}" -eq 1 ]] && any_sel=1
        done
        if [[ "$any_sel" -eq 0 ]]; then
          if ask_confirm "No categories selected. Quit without installing? [Y/n]" 1; then
            ABORT=1
            break
          fi
          STATUS=""
        else
          break
        fi
        ;;
      quit)
        any_sel=0
        for ci in "${!CATEGORIES[@]}"; do
          [[ "${SEL[$ci]}" -eq 1 ]] && any_sel=1
        done
        if [[ "$any_sel" -eq 0 ]]; then
          ABORT=1
          break
        fi
        if ask_confirm "Discard selection and quit? [y/N]" 0; then
          ABORT=1
          break
        fi
        STATUS=""
        ;;
    esac
    render
  done
  restore_tty
  printf '\r\033[K'
  if [[ "$ABORT" -eq 1 ]]; then
    echo "Aborted — nothing installed."
    exit 0
  fi
fi

echo "Agents: ${AGENT_LIST[*]}"
echo "Inventory: $INVENTORY"
echo

count=0
failed=0
for ci in "${!CATEGORIES[@]}"; do
  [[ "${SEL[$ci]}" -eq 1 ]] || continue
  category="${CATEGORIES[$ci]}"
  for i in "${!INV_SKILL[@]}"; do
    [[ "${INV_CAT[$i]}" == "$category" ]] || continue
    for agent in "${AGENT_LIST[@]}"; do
      count=$((count + 1))
      echo "[$count] ${INV_SKILL[$i]} (${INV_REPO[$i]}, $category) -> $agent"
      if ! npx --yes skills add "${INV_REPO[$i]}" --skill "${INV_SKILL[$i]}" --global --yes --agent "$agent" </dev/null; then
        echo "error: failed to install ${INV_SKILL[$i]} for $agent" >&2
        failed=$((failed + 1))
      fi
    done
  done
done

if [[ "$INTERACTIVE" -eq 1 ]]; then
  mkdir -p "$(dirname "$SELECTION_FILE")"
  : > "$SELECTION_FILE"
  for ci in "${!CATEGORIES[@]}"; do
    [[ "${SEL[$ci]}" -eq 1 ]] && printf '%s\n' "${CATEGORIES[$ci]}" >> "$SELECTION_FILE"
  done
fi

echo
echo "Done: $((count - failed))/$count installs succeeded."
if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
if [[ "$WITH_COMMANDS" -eq 1 ]]; then
  echo
  "$SCRIPT_DIR/write-commands.sh"
fi
