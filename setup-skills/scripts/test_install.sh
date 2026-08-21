#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL="$SCRIPT_DIR/install.sh"
WRITE_COMMANDS="$SCRIPT_DIR/write-commands.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

passes=0
failures=0

ok() {
  passes=$((passes + 1))
  printf 'ok - %s\n' "$1"
}

ko() {
  failures=$((failures + 1))
  printf 'not ok - %s\n' "$1"
}

check_eq() {
  if [[ "$2" == "$3" ]]; then
    ok "$1"
  else
    ko "$1"
    printf '  expected: %q\n  actual:   %q\n' "$2" "$3"
  fi
}

check_grep() {
  if grep -qE "$2" "$3"; then
    ok "$1"
  else
    ko "$1"
    printf '  missing pattern %q in %s\n' "$2" "$3"
  fi
}

run_install() {
  OUT="$TMP/out"
  ERR="$TMP/err"
  STATUS=0
  "$@" > "$OUT" 2> "$ERR" || STATUS=$?
}

cat > "$TMP/good.tsv" <<'EOF'
a/b	skill-one	core
c/d	skill-two	react
EOF

printf 'a/b\tskill-one\n' > "$TMP/short.tsv"
printf 'a/b\tskill-one\tweird\n' > "$TMP/badcat.tsv"

run_install env SKILLS_INVENTORY="$TMP/short.tsv" bash "$INSTALL" --agents opencode --dry-run
check_eq "short inventory exits 1" "1" "$STATUS"
check_grep "short inventory message" "expected '<repo> <skill> <category>'" "$ERR"

run_install env SKILLS_INVENTORY="$TMP/badcat.tsv" bash "$INSTALL" --agents opencode --dry-run
check_eq "unknown category exits 1" "1" "$STATUS"
check_grep "unknown category message" "unknown category 'weird'" "$ERR"

run_install env SKILLS_INVENTORY="$TMP/good.tsv" bash "$INSTALL" --agents opencode,cursor --dry-run
check_eq "dry-run exits 0" "0" "$STATUS"
check_eq "plan line count" "4" "$(grep -c '^\[plan\]' "$OUT")"
check_grep "plan line format" '^\[plan\] skill-one \(a/b, core\) -> opencode$' "$OUT"
check_grep "plan summary" '^Plan: 4 install\(s\) across 2 agent\(s\)\.$' "$OUT"

run_install env SKILLS_INVENTORY="$TMP/good.tsv" bash "$INSTALL" --agents opencode </dev/null
check_eq "non-tty exits 1" "1" "$STATUS"
check_grep "non-tty message" "needs a terminal" "$ERR"

printf 'react\nbogus\ncore\n' > "$TMP/sel.tsv"
run_install env SKILLS_INVENTORY="$TMP/good.tsv" SKILLS_SELECTION_FILE="$TMP/sel.tsv" \
  bash "$INSTALL" --print-selection
check_eq "print-selection exits 0" "0" "$STATUS"
check_eq "stale entries dropped, canonical order" $'core\nreact' "$(cat "$OUT")"

run_install env SKILLS_INVENTORY="$TMP/good.tsv" SKILLS_SELECTION_FILE="$TMP/missing.tsv" \
  bash "$INSTALL" --print-selection
check_eq "missing selection file exits 0" "0" "$STATUS"
check_eq "missing selection file prints nothing" "" "$(cat "$OUT")"

SB="$TMP/sandbox"
mkdir -p "$SB/scripts" "$SB/commands" "$SB/dest"
cp "$INSTALL" "$WRITE_COMMANDS" "$SB/scripts/"
cp "$SCRIPT_DIR"/../commands/*.md "$SB/commands/"
printf -- '---\ndescription: old\n---\nLoad the tdd skill and do it.\n\n<!-- managed by setup-skills -->\n' > "$SB/dest/stale.md"
printf 'personal notes\n' > "$SB/dest/mine.md"

run_install env OPENCODE_COMMANDS_DIR="$SB/dest" bash "$SB/scripts/write-commands.sh"
check_eq "write-commands exits 0" "0" "$STATUS"
if [[ -e "$SB/dest/stale.md" ]]; then
  ko "marked stale command pruned"
else
  ok "marked stale command pruned"
fi
if [[ -e "$SB/dest/mine.md" ]]; then
  ok "unmanaged file spared"
else
  ko "unmanaged file spared"
fi
for f in grill-me code-review tdd diagnose-bugs; do
  if [[ -e "$SB/dest/$f.md" ]]; then
    ok "wrote $f.md"
  else
    ko "wrote $f.md"
  fi
done
check_grep "prune summary" "(1 stale removed)" "$OUT"

printf '\n%d passed, %d failed\n' "$passes" "$failures"
if [[ "$failures" -eq 0 ]]; then
  exit 0
fi
exit 1
