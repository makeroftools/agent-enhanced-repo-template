#!/usr/bin/env bash
# Smoke-test for the `agent-enhance` v0.5.0 script.
#
# Usage: bash tests/agent-enhance_check.sh <path-to-bin/agent-enhance>
#
# Asserts the mission-critical behavioural guarantees:
#   - syntactic validity
#   - --version / --help
#   - default mode creates the full structure and a correct AGENTS.md
#   - existing AGENTS.md is preserved and protocols injected with markers
#   - --synthesize performs synthesize-and-apply: rewrites the live AGENTS.md
#     lean AND preserves every discovered source under .agents/references/
#   - --dry-run writes nothing and reports intent
#   - historical/lib material is referenced, not bulk-inlined
#   - dirty Git tree refused by default; --allow-dirty works
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
[[ "$("$SCRIPT" --version)" == "agent-enhance 0.5.0" ]] || fail "--version"
pass "--version reports 0.5.0"
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

# --- 5. synthesize: synthesize-and-apply updates live AGENTS.md lean + preserves all ---
SYN="$BASE/syn"; mkdir -p "$SYN"
printf 'OLD AGENT\n' > "$SYN/AGENT.md"
printf 'OLD CLAUDE\n' > "$SYN/CLAUDE.md"
printf 'CURSOR RULES\n' > "$SYN/.cursorrules"
"$SCRIPT" --synthesize "$SYN" >/dev/null 2>&1 || fail "synthesize run"
[ -f "$SYN/AGENTS.md" ] || fail "synthesize did not create live AGENTS.md"
grep -q "Session Start Protocol (Mandatory)" "$SYN/AGENTS.md" || fail "live AGENTS.md missing protocols"
grep -q "synthesis-inventory.md" "$SYN/AGENTS.md" || fail "live AGENTS.md missing pointer to inventory"
[ -f "$SYN/.agents/references/synthesis-inventory.md" ] || fail "missing synthesis-inventory.md"
grep -q "AGENT.md" "$SYN/.agents/references/synthesis-inventory.md" || fail "inventory missing AGENT.md"
grep -q "CLAUDE.md" "$SYN/.agents/references/synthesis-inventory.md" || fail "inventory missing CLAUDE.md"
grep -q ".cursorrules" "$SYN/.agents/references/synthesis-inventory.md" || fail "inventory missing .cursorrules"
ls "$SYN"/.agents/handoffs/*synthesis-apply.md >/dev/null 2>&1 || fail "synthesis handoff missing"
grep -q "Synthesis-and-apply" "$SYN/.agents/memory/decisions.md" || fail "decision entry missing"
pass "synthesize-and-apply: live AGENTS lean + full inventory + handoff + decision"

# --- 5b. broader discovery, size discipline, hard exclusions (synthesize applies) ---
BROAD="$BASE/broad"; mkdir -p "$BROAD/docs" "$BROAD/adr" "$BROAD/policies" "$BROAD/.github" "$BROAD/node_modules"
printf '# Playbook\nP body.\n' > "$BROAD/docs/playbook.md"
printf '# ADR\nChose Postgres.\n' > "$BROAD/adr/0001-db.md"
printf '# Policy\nRetention.\n' > "$BROAD/policies/retention-policy.md"
printf '# Copilot\nCI.\n' > "$BROAD/.github/copilot-instructions.md"
printf 'ignored\n' > "$BROAD/node_modules/ignored.md"
awk 'BEGIN{print "# big"; for(i=0;i<40000;i++) print "x"}' > "$BROAD/docs/big.md"
printf 'int main(){return 0;}\n' > "$BROAD/main.c"
"$SCRIPT" --synthesize "$BROAD" >/dev/null 2>&1 || fail "broad synthesize run"
grep -q "docs/playbook.md" "$BROAD/.agents/references/synthesis-inventory.md" || fail "missing docs/playbook.md"
grep -q "adr/0001-db.md" "$BROAD/.agents/references/synthesis-inventory.md" || fail "missing adr/0001-db.md"
grep -q "policies/retention-policy.md" "$BROAD/.agents/references/synthesis-inventory.md" || fail "missing policies file"
grep -q "copilot-instructions.md" "$BROAD/.agents/references/synthesis-inventory.md" || fail "missing .github copilot file"
grep -q "docs/big.md.*referenced" "$BROAD/.agents/references/synthesis-inventory.md" || fail "large file not referenced"
grep -q "ignored.md" "$BROAD/.agents/references/synthesis-inventory.md" && fail "node_modules content leaked into inventory"
grep -q "main.c" "$BROAD/.agents/references/synthesis-inventory.md" && fail "source file wrongly treated as candidate"
# The live AGENTS.md must stay lean: source content should NOT be bulk-inlined.
grep -q "int main" "$BROAD/AGENTS.md" && fail "live AGENTS.md bulk-inlined source content"
pass "broader discovery + size/exclusion rules correct (apply path)"

# --- 6. dry-run writes nothing ---
DRY="$BASE/dry"; mkdir -p "$DRY"
printf 'AGENT\n' > "$DRY/AGENT.md"
printf 'OLD\n' > "$DRY/AGENTS.md"
"$SCRIPT" --synthesize --dry-run "$DRY" >/dev/null 2>&1 || fail "synthesize dry-run run"
[ "$(cat "$DRY/AGENTS.md")" == "OLD" ] || fail "dry-run modified live AGENTS.md"
[ ! -f "$DRY/.agents/references/synthesis-inventory.md" ] || fail "dry-run wrote synthesis-inventory.md"
[ ! -f "$DRY/.agents/references/synthesis-elevated.md" ] || fail "dry-run wrote synthesis-elevated.md"
[ ! -e "$DRY/.agents" ] || [ -z "$(find "$DRY/.agents" -type f 2>/dev/null)" ] || fail "dry-run wrote .agents files"
pass "synthesize --dry-run wrote nothing, live AGENTS untouched"

# --- 7. idempotency: second synthesize run does not duplicate / regress ---
"$SCRIPT" --synthesize "$SYN" >/dev/null 2>&1 || fail "synthesize re-run"
[ "$(ls "$SYN"/.agents/handoffs/*synthesis-apply.md | wc -l)" -eq 1 ] || fail "synthesis handoff duplicated"
[ ! -f "$SYN/AGENTS.md.proposed" ] || fail "legacy proposed intermediate not removed from $SYN"
grep -q "Session Start Protocol (Mandatory)" "$SYN/AGENTS.md" || fail "re-run dropped live protocols"
grep -q "AGENT.md" "$SYN/.agents/references/synthesis-inventory.md" || fail "re-run lost inventory entry"
pass "re-run is idempotent (single handoff, lean live AGENTS retained)"


# --- 8. tier classification: canon/current/skills elevated, archive referenced ---
TIER="$BASE/tier"; mkdir -p "$TIER/.agents/canon" "$TIER/.agents/memory" \
  "$TIER/.agents/volley/archive" "$TIER/.agents/skills/wf"
printf '# Canon identity\nDurable laws.\n' > "$TIER/.agents/canon/identity.md"
printf '# Status\ncurrent\n' > "$TIER/.agents/memory/current-status.md"
printf '# Skill\nsync\n' > "$TIER/.agents/skills/wf/SKILL.md"
printf '# Old session\nhistorical exhaust\n' > "$TIER/.agents/volley/archive/volley_session1.md"
"$SCRIPT" --synthesize "$TIER" >/dev/null 2>&1 || fail "tier synthesize run"
grep -q "## Full Preserved Content" "$TIER/.agents/references/synthesis-inventory.md" || fail "reference repository missing preserved section"
# The durable inventory holds the source and its archive disposition; never a bulk dump in AGENTS.md.
grep -q "volley_session1.md" "$TIER/.agents/references/synthesis-inventory.md" || fail "archive path missing from inventory"
grep -q "tier: archive" "$TIER/.agents/references/synthesis-inventory.md" || fail "archive tier not labelled in inventory"
grep -q "tier: canon" "$TIER/.agents/references/synthesis-inventory.md" || fail "canon tier not labelled in inventory"
# The archive source file must remain on disk (never deleted), and its content must NOT be
# bulk-inlined into the live AGENTS.md.
[ -f "$TIER/.agents/volley/archive/volley_session1.md" ] || fail "archive source file was deleted"
if grep -q '```markdown.*volley_session1' "$TIER/AGENTS.md"; then
  fail "archive content was bulk-inlined into live AGENTS.md (must be reference-only)"
fi
# Elevated canon content IS surfaced in the live (lean) AGENTS.md.
grep -q "Durable laws" "$TIER/AGENTS.md" || fail "canon content absent from live AGENTS.md"
pass "tier classification: canon elevated into live, archive preserved by reference (not deleted)"

echo
echo "PASS: agent-enhance v0.5.0 behavioural checks verified."
