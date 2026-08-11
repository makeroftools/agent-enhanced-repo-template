# agent-enhance — usage

`agent-enhance` adds AI-agent-native structure and mandatory continuity protocols to an
**existing** repository. It is the complement to the Copier template: use the template to
scaffold a new agent-native repo, and `agent-enhance` to retrofit one that is already
under way.

## Mission-critical guarantees

- **Additive & non-destructive** — never overwrites or deletes existing content.
- **Idempotent** — safe to re-run; existing files are left untouched.
- **Auditable** — the enhancement itself is recorded in `decisions.md`.
- **Explicit protocols** — every generated `AGENTS.md` enforces Session Start and Handoff.

## Install

From a local clone:

```bash
mkdir -p bin
# place the script at bin/agent-enhance
chmod +x bin/agent-enhance
```

Or install permanently to `~/.local/bin`:

```bash
curl -fsSL https://raw.githubusercontent.com/makeroftools/agent-enhanced-repo-template/main/bin/agent-enhance \
  -o ~/.local/bin/agent-enhance
chmod +x ~/.local/bin/agent-enhance
```

## Usage

```
agent-enhance [OPTIONS] [TARGET_DIR]
```

Run inside a repository, or pass a target directory. `TARGET_DIR` defaults to `.`.

### Options

| Option | Description |
| --- | --- |
| `-n, --dry-run` | Show what would be done without writing files |
| `--force-protocols` | Note that markers already exist (conservative) |
| `--multi-agent` | Include role charters (coordinator, implementer, reviewer) |
| `--sample-skill` | Include a sample Skill under `.agents/skills/` |
| `-h, --help` | Show help |
| `--version` | Show version |

### Examples

```bash
# Preview what would change (recommended first)
agent-enhance --dry-run

# Apply the core structure and protocols
agent-enhance

# Apply core + multi-agent role charters + sample skill
agent-enhance --multi-agent --sample-skill .

# Operate on a different repository
agent-enhance /path/to/other/repo
```

## What it writes

- `.agents/memory/decisions.md` — append-only decision log (with an initialization entry)
- `.agents/memory/current-status.md` — living high-level status
- `.agents/handoffs/template-handoff.md` — reusable handoff template
- `.agents/references/{architecture,conventions}.md` — progressive-disclosure references
- `AGENTS.md` — created if absent; otherwise the mandatory protocol block is injected
  between `<!-- AGENT-ENHANCE:BEGIN -->` / `<!-- AGENT-ENHANCE:END -->` markers
- `CLAUDE.md` — thin bridge referencing `AGENTS.md`
- Optional (`--multi-agent`): `.agents/agents/{coordinator,implementer,reviewer}.md`
- Optional (`--sample-skill`): `.agents/skills/example-skill/SKILL.md`

Nothing existing is overwritten. Re-running is safe.

## Next steps

1. Read `AGENTS.md` (especially the Session Start and Handoff protocols).
2. Keep `current-status.md` and `decisions.md` current.
3. Use `.agents/handoffs/` for any incomplete work spanning sessions.