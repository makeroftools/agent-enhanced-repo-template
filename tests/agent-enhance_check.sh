#!/usr/bin/env bash
# Smoke-test for the `agent-enhance` v0.3.1 script.
#
# Usage: bash tests/agent-enhance_check.sh <path-to-bin/agent-enhance>
#
# Asserts the mission-critical behavioural guarantees:
#   - syntactic validity
#   - --version / --help
#   - default mode creates the full structure and a correct AGENTS.md
#   - existing AGENTS.md is preserved and protocols injected with markers
#   - --synthesize produces AGENTS.md.proposed + handoff and never touches live AGENTS.md
#   - --synthesize discovers broader documents and respects size/exclusion rules
#   - --dry-run writes nothing
#   - re-runs are idempotent
set -euo pipefail

SCRIPT="${1:?usage: $0 <path-to-bin/agent-enhance>}"
[ -x "$SCRIPT" ] || { echo "FAIL: $SCRIPT is not executable" >&2; exit 1; }

fail()  { echo "FAIL: $*" >&2; exit 1; }
pass()  { echo "  ok: $*"; }

BASE="$(mktemp -d)"
trap 'rm -rf "$BASE"' EXIT

# --- 1. syntactic validity ---
bash -n "$SCRIPT" || fail "bash -n failed"
pass "syntactically valid"

# --- 2. version / help ---
[[ "$("$SCRIPT" --version)" == "agent-enhance 0.3.1" ]] || fail "--version"
pass "--version reports 0.3.1"
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

# --- 4b. git working-tree safety gate ---
make_clean_repo() {  # $1 = dir
  mkdir -p "$1"
  ( cd "$1" && git init -q && touch base.txt && git add base.txt \
      && git -c user.email=t@t -c user.name=t commit -qm init --no-gpg-sign )
}
# clean repo -> proceeds
GC="$BASE/gitclean"; make_clean_repo "$GC"
"$SCRIPT" "$GC" >/dev/null 2>&1 || fail "clean repo did not proceed"
pass "clean repo -> proceeds"
# dirty repo, no flag -> refuses non-zero, no files
GD="$BASE/gitdirty"; make_clean_repo "$GD"
echo "dirty" > "$GD/dirty.txt"
"$SCRIPT" "$GD" >/dev/null 2>&1 && fail "dirty repo should refuse"
[ ! -d "$GD/.agents" ] || fail "dirty repo wrote files despite refusal"
pass "dirty repo -> refuses, no files written"
# dirty repo + --allow-dirty -> proceeds with warning
"$SCRIPT" --allow-dirty "$GD" 2>/tmp/gs_allow.err || fail "--allow-dirty should proceed"
grep -q "SAFETY OVERRIDE" /tmp/gs_allow.err || fail "--allow-dirty missing warning"
rm -f /tmp/gs_allow.err
pass "dirty repo + --allow-dirty -> proceeds with warning"
# non-git dir -> warns and proceeds
NG="$BASE/nongit"; mkdir -p "$NG"
"$SCRIPT" "$NG" >/dev/null 2>&1 || fail "non-git dir should proceed"
[ -d "$NG/.agents" ] || fail "non-git dir did not proceed"
pass "non-git dir -> proceeds"
# dry-run on dirty reflects refusal
"$SCRIPT" --dry-run "$GD" >/dev/null 2>&1 && fail "dry-run dirty should refuse"
pass "dry-run on dirty reflects refusal"

# --- 5. synthesize: proposal + handoff, live AGENTS untouched ---
SYN="$BASE/syn"; mkdir -p "$SYN"
printf 'OLD AGENT\n' > "$SYN/AGENT.md"
printf 'OLD CLAUDE\n' > "$SYN/CLAUDE.md"
printf 'CURSOR RULES\n' > "$SYN/.cursorrules"
"$SCRIPT" --synthesize "$SYN" >/dev/null 2>&1 || fail "synthesize run"
[ -f "$SYN/AGENTS.md.proposed" ] || fail "AGENTS.md.proposed missing"
ls "$SYN"/.agents/handoffs/*synthesis-review.md >/dev/null 2>&1 || fail "synthesis handoff missing"
[ ! -f "$SYN/AGENTS.md" ] || fail "live AGENTS.md was created"
grep -q "Session Start Protocol (Mandatory)" "$SYN/AGENTS.md.proposed" || fail "proposal missing protocols"
grep -q "AGENT.md" "$SYN/AGENTS.md.proposed" || fail "proposal missing AGENT.md"
grep -q "CLAUDE.md" "$SYN/AGENTS.md.proposed" || fail "proposal missing CLAUDE.md"
grep -q ".cursorrules" "$SYN/AGENTS.md.proposed" || fail "proposal missing .cursorrules"
grep -q "Discovery Inventory" "$SYN/AGENTS.md.proposed" || fail "proposal missing Discovery Inventory"
pass "synthesize produced proposal + handoff, live AGENTS untouched"

# --- 5b. broader discovery, size discipline, hard exclusions ---
BROAD="$BASE/broad"; mkdir -p "$BROAD/docs" "$BROAD/adr" "$BROAD/policies" "$BROAD/.github" "$BROAD/node_modules"
printf '# Playbook\nP body.\n' > "$BROAD/docs/playbook.md"
printf '# ADR\nChose Postgres.\n' > "$BROAD/adr/0001-db.md"
printf '# Policy\nRetention.\n' > "$BROAD/policies/retention-policy.md"
printf '# Copilot\nCI.\n' > "$BROAD/.github/copilot-instructions.md"
printf 'ignored\n' > "$BROAD/node_modules/ignored.md"
awk 'BEGIN{print "# big"; for(i=0;i<40000;i++) print "x"}' > "$BROAD/docs/big.md"
printf 'int main(){return 0;}\n' > "$BROAD/main.c"
"$SCRIPT" --synthesize "$BROAD" >/dev/null 2>&1 || fail "broad synthesize run"
grep -q "docs/playbook.md" "$BROAD/AGENTS.md.proposed" || fail "missing docs/playbook.md"
grep -q "adr/0001-db.md" "$BROAD/AGENTS.md.proposed" || fail "missing adr/0001-db.md"
grep -q "policies/retention-policy.md" "$BROAD/AGENTS.md.proposed" || fail "missing policies file"
grep -q "copilot-instructions.md" "$BROAD/AGENTS.md.proposed" || fail "missing .github copilot file"
grep -q "docs/big.md.*referenced" "$BROAD/AGENTS.md.proposed" || fail "large file not referenced"
grep -q "ignored.md" "$BROAD/AGENTS.md.proposed" && fail "node_modules content leaked into proposal"
grep -q "main.c" "$BROAD/AGENTS.md.proposed" && fail "source file wrongly treated as candidate"
pass "broader discovery + size/exclusion rules correct"

# --- 6. dry-run writes nothing ---
DRY="$BASE/dry"; mkdir -p "$DRY"
printf 'AGENT\n' > "$DRY/AGENT.md"
"$SCRIPT" --dry-run "$DRY" >/dev/null 2>&1 || fail "dry-run run"
[ ! -f "$DRY/AGENTS.md.proposed" ] || fail "dry-run wrote AGENTS.md.proposed"
[ -z "$(find "$DRY/.agents" -type f 2>/dev/null)" ] || fail "dry-run wrote .agents files"
pass "dry-run wrote nothing"

# --- 7. idempotency: second run of synthesize does not duplicate ---
"$SCRIPT" --synthesize "$SYN" >/dev/null 2>&1 || fail "synthesize re-run"
[ "$(ls "$SYN"/.agents/handoffs/*synthesis-review.md | wc -l)" -eq 1 ] || fail "handoff duplicated"
[ -f "$SYN/AGENTS.md.proposed" ] && [ ! -f "$SYN/AGENTS.md" ] || fail "idempotency structure broken"
pass "re-run is idempotent (single handoff, live AGENTS still untouched)"

echo
echo "PASS: agent-enhance v0.3.1 behavioural checks verified."