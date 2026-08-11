#!/usr/bin/env bash
# Smoke-test for the `agent-enhance` v0.2.0 script.
#
# Usage: bash tests/agent-enhance_check.sh <path-to-bin/agent-enhance>
#
# Asserts the mission-critical behavioural guarantees:
#   - syntactic validity
#   - --version / --help
#   - default mode creates the full structure and a correct AGENTS.md
#   - existing AGENTS.md is preserved and protocols injected with markers
#   - --synthesize produces AGENTS.md.proposed + handoff and never touches live AGENTS.md
#   - --dry-run writes nothing
#   - re-runs are idempotent
set -euo pipefail

SCRIPT="${1:?usage: $0 <path-to-bin/agent-enhance>}"
[ -x "$SCRIPT" ] || { echo "FAIL: $SCRIPT is not executable" >&2; exit 1; }

fail()  { echo "FAIL: $*" >&2; exit 1; }
pass()  { echo "  ok: $*"; }
syntax_file(){ :; }

BASE="$(mktemp -d)"
trap 'rm -rf "$BASE"' EXIT

# --- 1. syntactic validity ---
bash -n "$SCRIPT" || fail "bash -n failed"
pass "syntactically valid"

# --- 2. version / help ---
[[ "$("$SCRIPT" --version)" == "agent-enhance 0.2.0" ]] || fail "--version"
pass "--version reports 0.2.0"
"$SCRIPT" --help >/dev/null 2>&1 || fail "--help"
pass "--help exits 0"

# --- 3. default mode on an empty dir ---
EMPTY="$BASE/empty"; mkdir -p "$EMPTY"
"$SCRIPT" "$EMPTY" >/dev/null 2>&1 || fail "default mode run"
for f in \
  AGENTS.md CLAUDE.md \
  .agents/memory/decisions.md .agents/memory/current-status.md \
  .agents/handoffs/template-handoff.md \
  .agents/references/architecture.md .agents/references/conventions.md; do
  [ -f "$EMPTY/$f" ] || fail "missing $f"
done
grep -q "Session Start Protocol (Mandatory)" "$EMPTY/AGENTS.md" || fail "missing Session Start in AGENTS.md"
grep -q "Session End / Handoff Protocol (Mandatory)" "$EMPTY/AGENTS.md" || fail "missing Handoff in AGENTS.md"
grep -q "AGENT-ENHANCE:BEGIN" "$EMPTY/AGENTS.md" || fail "AGENTS.md missing BEGIN marker"
pass "empty-dir structure + AGENTS.md correct"

# --- 4. existing AGENTS.md injected with markers, original preserved ---
INJ="$BASE/inj"; mkdir -p "$INJ"
printf 'ORIGINAL KEEP ME\n' > "$INJ/AGENTS.md"
"$SCRIPT" "$INJ" >/dev/null 2>&1 || fail "injection run"
head -1 "$INJ/AGENTS.md" | grep -q "ORIGINAL KEEP ME" || fail "original not preserved"
grep -q "AGENT-ENHANCE:BEGIN" "$INJ/AGENTS.md" || fail "markers missing on injection"
pass "existing AGENTS.md preserved + protocols injected with markers"

# --- 5. synthesize: proposal + handoff, live AGENTS untouched ---
SYN="$BASE/syn"; mkdir -p "$SYN"
printf 'OLD AGENT\n' > "$SYN/AGENT.md"
printf 'OLD CLAUDE\n' > "$SYN/CLAUDE.md"
grep -q go.mod "$SYN/go.mod" 2>/dev/null || touch "$SYN/go.mod"
"$SCRIPT" --synthesize "$SYN" >/dev/null 2>&1 || fail "synthesize run"
[ -f "$SYN/AGENTS.md.proposed" ] || fail "AGENTS.md.proposed missing"
ls "$SYN"/.agents/handoffs/*synthesis-review.md >/dev/null 2>&1 || fail "synthesis handoff missing"
[ ! -f "$SYN/AGENTS.md" ] || fail "live AGENTS.md was created"
grep -q "Content of: AGENT.md" "$SYN/AGENTS.md.proposed" || fail "proposal missing AGENT.md embed"
grep -q "Content of: CLAUDE.md" "$SYN/AGENTS.md.proposed" || fail "proposal missing CLAUDE.md embed"
grep -q "Session Start Protocol (Mandatory)" "$SYN/AGENTS.md.proposed" || fail "proposal missing protocols"
pass "synthesize produced proposal + handoff, live AGENTS untouched"

# --- 6. dry-run writes nothing ---
DRY="$BASE/dry"; mkdir -p "$DRY"
"$SCRIPT" --dry-run "$DRY" >/dev/null 2>&1 || fail "dry-run run"
[ -z "$(find "$DRY" -type f)" ] || fail "dry-run wrote files"
pass "dry-run wrote nothing"

# --- 7. idempotency: second run of synthesize does not duplicate ---
"$SCRIPT" --synthesize "$SYN" >/dev/null 2>&1 || fail "synthesize re-run"
[ "$(ls "$SYN"/.agents/handoffs/*synthesis-review.md | wc -l)" -eq 1 ] || fail "handoff duplicated"
[ -f "$SYN/AGENTS.md.proposed" ] && [ ! -f "$SYN/AGENTS.md" ] || fail "idempotency structure broken"
pass "re-run is idempotent (single handoff, live AGENTS still untouched)"

echo
echo "PASS: agent-enhance v0.2.0 behavioural checks verified."