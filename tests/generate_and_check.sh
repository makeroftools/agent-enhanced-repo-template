#!/usr/bin/env bash
# Smoke-test for the agent-enhanced-repo-template.
#
# Usage: bash tests/generate_and_check.sh <generated-project-dir>
#
# Asserts that a generated project contains every required file and that the
# mandatory Session Start and Handoff protocols are present in AGENTS.md.
set -euo pipefail

PROJECT="${1:?usage: $0 <generated-project-dir>}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[ -d "$PROJECT" ] || fail "generated project directory does not exist: $PROJECT"

# --- Required files (Section 2 of the directive) ---
required_files=(
  "AGENTS.md"
  "CLAUDE.md"
  "README.md"
  ".gitignore"
  ".agents/memory/decisions.md"
  ".agents/memory/current-status.md"
  ".agents/handoffs/template-handoff.md"
  ".agents/agents/coordinator.md"
  ".agents/agents/implementer.md"
  ".agents/agents/reviewer.md"
  ".agents/skills/example-skill/SKILL.md"
  ".agents/references/architecture.md"
  ".agents/references/conventions.md"
)

for f in "${required_files[@]}"; do
  [ -f "$PROJECT/$f" ] || fail "missing required file: $f"
done

# --- No unresolved Jinja ---
if grep -rIl --include='*' '{{' "$PROJECT" >/dev/null 2>&1; then
  fail "unresolved Jinja template markers found in generated output"
fi

# --- Mandatory protocols present in AGENTS.md ---
AGENTS="$PROJECT/AGENTS.md"
[ -f "$AGENTS" ] || fail "AGENTS.md missing"

grep -q "Session Start Protocol (MANDATORY)" "$AGENTS" \
  || fail "AGENTS.md missing Session Start Protocol"
grep -q "Session End / Handoff Protocol (MANDATORY)" "$AGENTS" \
  || fail "AGENTS.md missing Handoff Protocol"
grep -q "current-status.md" "$AGENTS" || fail "AGENTS.md missing current-status reference"
grep -q "decisions.md" "$AGENTS" || fail "AGENTS.md missing decisions reference"

# --- Memory files usable ---
grep -q "Append-only" "$PROJECT/.agents/memory/decisions.md" \
  || fail "decisions.md missing append-only note"
grep -q "Current Status" "$PROJECT/.agents/memory/current-status.md" \
  || fail "current-status.md missing header"

# --- Handoff template usable ---
grep -q "Exact next actions" "$PROJECT/.agents/handoffs/template-handoff.md" \
  || fail "handoff template missing next-actions section"

# --- Role charters have required sections ---
for role in coordinator implementer reviewer; do
  charter="$PROJECT/.agents/agents/$role.md"
  for section in "Purpose" "Responsibilities" "Must never" "Inputs" "Outputs"; do
    grep -q "$section" "$charter" || fail "$role.md missing section: $section"
  done
done

# --- Sample skill well-formed ---
grep -q "^name:" "$PROJECT/.agents/skills/example-skill/SKILL.md" \
  || fail "SKILL.md missing name frontmatter"
grep -q "^description:" "$PROJECT/.agents/skills/example-skill/SKILL.md" \
  || fail "SKILL.md missing description frontmatter"

echo "PASS: generated project structure and protocols verified."
