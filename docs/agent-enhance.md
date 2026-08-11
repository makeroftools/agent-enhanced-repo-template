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
| `--synthesize` | Synthesize-and-apply: rewrite the live `AGENTS.md` lean, elevating **Canon / Skills / Current** material, and preserve **all** discovered sources under `.agents/references/` |
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

## --synthesize: synthesize-and-apply (v0.5.0)

`--synthesize` performs a **broader, safe, bounded** discovery of candidate documents,
classifies each into a deterministic **tier**, then **upgrades the live `AGENTS.md`** to a
lean, protocol-compliant version — while **preserving every discovered source** under
progressive disclosure. Nothing is deleted and nothing discovered is dropped.

Run `--synthesize --dry-run` first to preview every intended write (it writes nothing).

### What it writes

1. **Live `AGENTS.md`** — replaced with a lean, always-on contract:
   - Mandatory Session Start + Handoff protocols (unchanged wording, wrapped in the
     `AGENT-ENHANCE:BEGIN/END` markers).
   - Progressive disclosure + Definition of Done.
   - **Elevated content** from the **Canon / Skills / Current / Active** tiers (synthesised,
     never a bulk historical dump).
   - Pointers to the durable knowledge under `.agents/`.
2. **`.agents/references/synthesis-inventory.md`** — the durable knowledge repository: the
   complete Discovery Inventory (every path + tier + disposition) plus the full preserved
   content of every source per its tier. Historical archives are referenced (path + short
   excerpt), never bulk-inlined.
3. **`.agents/references/synthesis-elevated.md`** — a focused note on the elevated
   Canon / Skills / Current material mapped into the live `AGENTS.md`.
4. **`.agents/memory/decisions.md`** — a synthesis-and-apply decision entry is appended
   (idempotent: re-running does not duplicate it).
5. **`.agents/handoffs/YYYY-MM-DD-synthesis-apply.md`** — a handoff describing the change
   and next review steps.

### Discovery behaviour

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
  recorded by path with size and a short excerpt (valid-UTF-8), with an explicit “full
  content available at path” reference. Nothing discovered is silently dropped.

### Source classification (v0.4.0, reused)

Every discovered document is assigned a deterministic **tier** from its path/name, so
long-lived, high-signal material is elevated while historical exhaust stays available under
progressive disclosure. The complete inventory lists every candidate **with its tier**.

| Tier | Intent | Treatment |
| --- | --- | --- |
| **Canon** | Long-lived identity, laws, architecture, toolchain, core constraints | Elevated into the live `AGENTS.md`. |
| **Current / Active** | Latest handoff, current status, active memory/decision log | Elevated into the live `AGENTS.md`. |
| **Skills** | Reusable agent skills (`SKILL.md` etc.) | Listed and surfaced; elevated when small. |
| **Historical Archive** | Session logs, volley archives, old handoffs, past-session memory | Preserved by reference (path + short excerpt). Never bulk-inlined. |
| **General Docs** | Broader documentation, API references, tutorials | Preserved in the inventory; inline only if small and high-signal. |
| **Other** | Everything else that matched discovery | Preserved in the inventory; referenced or minimal excerpt. |

Classification is path/name-driven and deterministic: `.agents/canon/`, `identity`,
`system-map`, `toolchain`, etc. classify as **Canon**; `current-status.md`,
`decisions.md`, the live `volley/current.md`, and active `*synthesis-review.md`
handoffs classify as **Current**; `**/skills/` and `SKILL.md` classify as **Skills**;
`**/volley/archive/**`, archived/dated handoffs, and past-session memory classify as
**Historical Archive**. Other matched docs fall into **General Docs** or **Other**.

### Safety behaviour

- `--dry-run` reports every intended write (live `AGENTS.md`, inventory, elevated notes,
  decision, handoff) and writes nothing.
- The live `AGENTS.md` rewrite is intentional and visible; use `--dry-run` to preview.
- Git working-tree handling is unchanged: a dirty tree is refused by default; use
  `--allow-dirty` to override.
- Never present only a giant intermediate file: the repository actually advances.
- Git state is never modified (no auto-commit).

```bash
# Preview every intended write (writes nothing)
agent-enhance --synthesize --dry-run

# Apply: rewrite the live AGENTS.md lean and preserve all discovered knowledge
agent-enhance --synthesize
```

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

In `--synthesize` mode the files written change: the live `AGENTS.md` is **replaced** by
the lean synthesized version, and the durable knowledge repository is written under
`.agents/references/` (see the synthesize-and-apply section above). Existing discovered
source files are never deleted or overwritten in place.

Nothing else existing is overwritten. Re-running is safe.

## Next steps

1. Read `AGENTS.md` (especially the Session Start and Handoff protocols).
2. Keep `current-status.md` and `decisions.md` current.
3. Use `.agents/handoffs/` for any incomplete work spanning sessions.