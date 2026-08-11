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
- **Git-safety gate** — in a Git repository, a dirty working tree causes a refusal by
default; proceeding is an explicit, conscious choice (`--allow-dirty`).

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
| `-n, --dry-run` | Show what would be done without writing files
| `--synthesize` | Produce `AGENTS.md.proposed` + review handoff instead of modifying `AGENTS.md` |
| `--force-protocols` | Note that markers already exist (conservative)
| `--allow-dirty` | Permit operation on a dirty Git working tree (default is to refuse)
| `--multi-agent` | Include role charters (coordinator, implementer, reviewer)
| `--sample-skill` | Include a sample Skill under `.agents/skills/`
| `-h, --help` | Show help
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

## --synthesize: retrofit with a reviewable proposal

`--synthesize` does **not** touch the live `AGENTS.md`. Instead it performs a **broader,
safe, bounded** discovery of candidate documents and produces `AGENTS.md.proposed` — a
reviewable proposal combining the mandatory protocols with the discovered material — and
writes a review handoff under `.agents/handoffs/YYYY-MM-DD-synthesis-review.md`.

### Discovery behaviour (v0.3.0)


- **Git-aware**: inside a git repository, discovery uses `git ls-files`; otherwise it
  falls back to `find`. Both paths de-duplicate and sort the candidate set.
- **Candidate matching** (name or path, case-insensitive) on patterns such as
  `agent`, `claude`, `cursor`, `rule`, `instruction`, `convention`, `guideline`,
  `standard`, `playbook`, `runbook`, `decision`, `adr`, `architecture`, `sop`,
  `policy`, `prompt`. Well-known files (`AGENT.md`, `CLAUDE.md`, `.cursorrules`,
  `.clinerules`, `.github/copilot-instructions.md`, `GEMINI.md`, …) are always
  considered.
- **Directories of interest** searched regardless of name: `docs/`, `.github/`,
  `.cursor/`, `.agents/`, `adr/`, `decisions/`, `policies/`, `runbooks/`.
- **Extensions**: `.md`, `.txt`, `.rst`, `.markdown`, and extensionless files matching
  the name patterns.
- **Hard exclusions**: `.git/`, `node_modules/`, `vendor/`, `dist/`, `build/`,
  `__pycache__/`, `.venv/`, plus lockfiles, binaries, and minified assets.
- **Size discipline**: files smaller than 32 KiB are inlined in full; larger files are
  recorded by path with size and a short excerpt, with an explicit “full content
  available at path” reference. Nothing discovered is silently dropped.
- **Complete inventory**: the proposal opens with a Discovery Inventory listing every
  candidate path and its disposition (inlined or referenced), so a reviewer sees the
  full set of sources considered.

### Source classification (v0.4.0)

Every discovered document is assigned a deterministic **tier** from its path/name, so
durable, high-signal material is elevated while historical exhaust stays available under
progressive disclosure. Nothing is silently dropped — the complete inventory lists every
candidate **with its tier**.

| Tier | Intent | Treatment in proposal |
| --- | --- | --- |
| **Canon** | Long-lived identity, immutable laws, architecture, toolchain, core constraints | High priority. Preferred for extraction / full inline when small. Strongly candidate for the final `AGENTS.md`. |
| **Current / Active** | Latest handoff, current status, active memory/decision log | High priority. Surfaced prominently. |
| **Skills** | Reusable agent skills (`SKILL.md` etc.) | High priority. Listed and surfaced. |
| **Historical Archive** | Session logs, volley archives, old handoffs, past-session memory | Inventory + reference only (path + short excerpt). Never bulk-inlined. |
| **General Docs** | Broader documentation, API references, tutorials | Inventory + selective reference. Inline only if small and clearly high-signal. |
| **Other** | Everything else that matched discovery | Inventory; reference or minimal excerpt. |

Classification is path/name-driven and deterministic: `.agents/canon/`, `identity`,
`system-map`, `toolchain`, etc. classify as **Canon**; `current-status.md`,
`decisions.md`, the live `volley/current.md`, and active `*synthesis-review.md`
handoffs classify as **Current**; `**/skills/` and `SKILL.md` classify as **Skills**;
`**/volley/archive/**`, archived/dated handoffs, and past-session memory classify as
**Historical Archive**. Other matched docs fall into **General Docs** or **Other**.

### Proposal structure (v0.4.0)

`AGENTS.md.proposed` is organized to stay reviewable on repositories with large history:

1. **PROPOSAL header** — version, date, and an explicit “do not accept blindly” note.
2. **Session Start + Handoff protocols** (mandatory, unchanged wording).
3. **Progressive disclosure + Definition of Done**.
4. **Prioritized Synthesis** — extracted/referenced material from **Canon + Skills +
   Current/Active** tiers only (the recommended core). Historical-archive and
   low-signal material is intentionally not dumped here.
5. **Source Classification** table (above) documenting how each tier is treated.
6. **Complete Discovery Inventory** — every candidate still listed with its tier and
   disposition (inlined / referenced / archive-referenced).
7. **Reference body** — each source per its tier; archives remain reference-only.
8. **Further Reading / next actions** for the reviewer.

### Size & context discipline (v0.4.0)

- The existing 32 KiB inline threshold is retained for Canon / Current / Skills / Docs.
- **Historical Archive material is never bulk-inlined**, regardless of individual file
  size — it is inventoried and referenced (path + short excerpt only).
- The goal is a reviewable proposal, not a dump of repository history.

```bash
# Produce the proposal without modifying anything
agent-enhance --synthesize

# Preview the same output without writing files
agent-enhance --synthesize --dry-run
```

This is the conservative path for protecting existing knowledge: a human or reviewing
agent inspects and finalises the proposal before it becomes `AGENTS.md`.

## Git working-tree safety check

When the target directory is a Git repository, `agent-enhance` inspects the working
tree for staged, unstaged, and untracked (non-ignored) changes:

- **Clean tree** — proceeds normally, with no extra output.
- **Dirty tree (default)** — refuses to proceed and exits non-zero, stating that
  `--allow-dirty` is required to override. This keeps enhancements reviewable and
  prevents mixing with unrelated local changes.
- **Dirty tree with `--allow-dirty`** — emits an explicit safety-override warning, then
  continues.

When the target is **not** a Git repository, the existing warning is shown and
processing continues (unchanged). `--dry-run` always performs the status check first and
reports the resulting decision without writing files. Git state is never modified —
nothing is staged, committed, or stashed.

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