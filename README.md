# agent-enhanced-repo-template

A production-grade [Copier](https://copier.readthedocs.io/) template that scaffolds
**AI-agent-native repositories** — projects where durable continuity, shared memory, and
explicit handoffs are baked in from day one.

Generated projects are tool-agnostic and Zed-compatible, using `AGENTS.md` as the
canonical always-on instruction set and `.agents/` as the version-controlled home for
skills, references, shared memory, handoffs, and optional role charters.

> **Why?** Agent sessions are independent by design — they do not share chat history.
> Continuity and coordination must therefore be made explicit in the repository itself.
> This template encodes that principle so every generated project starts correct.

---

## Features

- **Mandatory Session Start & Handoff protocols** in every generated `AGENTS.md` — no
  session starts blind, no incomplete work is left without a handoff.
- **File-based shared memory (drop-box)** — append-only `decisions.md` plus a living
  `current-status.md` as the durable source of truth.
- **Progressive disclosure** — a lean, always-on `AGENTS.md` with detail pushed into
  on-demand Skills and reference files.
- **Optional multi-agent role charters** — bounded Coordinator / Implementer / Reviewer
  definitions with clear responsibilities and boundaries.
- **Git worktree isolation helpers** — one-command scripts for running parallel agents
  without stepping on each other.
- **Language-conditioned commands** — exact build/test/lint commands rendered per stack
  (Python, TypeScript, Rust, Go, or custom).
- **Updateable** — `copier update` pulls upstream changes without destroying consumer
  customizations.

---

## Quick start

Requires Python 3.13+ and [uv](https://docs.astral.sh/uv/) (or any Python 3.13
environment with `copier>=9.17.1`).

```bash
# From this template's root directory
uv run copier copy . /path/to/your-new-project
```

Answer the questionnaire (or pass `--defaults` to accept the recommended answers), then:

```bash
cd /path/to/your-new-project
git init
```

Read the generated `AGENTS.md` first — it is the canonical operating manual for the
project.

### Using the template from a remote repo

```bash
uv run copier copy \
  gh:makeroftools/agent-enhanced-repo-template \
  /path/to/your-new-project
```

---

## Retrofitting an existing repository with `agent-enhance`

New projects can use the Copier template above. To add the same agent-native structure and
mandatory protocols to a repository that already exists, use the bundled `agent-enhance`
binary. It is additive, idempotent, and non-destructive.

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/makeroftools/agent-enhanced-repo-template/main/bin/agent-enhance \
  -o ~/.local/bin/agent-enhance
chmod +x ~/.local/bin/agent-enhance
```

This installs permanently to `~/.local/bin/agent-enhance` (available on your `PATH`).

### Usage

```bash
# Preview what would change (recommended first)
agent-enhance --dry-run

# Apply the core agent-native structure and protocols (default, plain invocation)
agent-enhance .

# Apply the core structure and protocols, plus optional components
agent-enhance --multi-agent --sample-skill .

# If existing alignment files (AGENT.md, .cursorrules, etc.) are present,
# synthesize a reviewable AGENTS.md.proposed without touching the live file
agent-enhance --synthesize .
```

It writes `.agents/memory/`, `.agents/handoffs/`, and `.agents/references/`, creates
`AGENTS.md` (or injects the mandatory protocols between `AGENT-ENHANCE` markers if it
already exists), and adds a thin `CLAUDE.md` bridge. In `--synthesize` mode it instead
produces `AGENTS.md.proposed` (embedding every discovered alignment file verbatim) plus a
review handoff, and never modifies the live `AGENTS.md`. See
[`docs/agent-enhance.md`](docs/agent-enhance.md) for the full reference.

---

## Questionnaire

| Question | Type | Default | Notes |
| --- | --- | --- | --- |
| `project_name` | string | `my-agent-repo` | Lowercase, `[a-z0-9._-]` |
| `project_description` | string | — | One-line description |
| `primary_language` | choice | `python` | `python` / `typescript` / `rust` / `go` / `other` |
| `include_multi_agent` | bool | `true` | Role charters under `.agents/agents/` |
| `include_sample_skill` | bool | `true` | Example Skill under `.agents/skills/` |
| `include_worktree_helpers` | bool | `true` | Worktree scripts under `.agents/worktrees/` |
| `include_volley_stubs` | bool | `false` | Optional real-time stubs; file-based drop-box is primary |
| `author_name` | string | `""` | Used in the initial `decisions.md` entry |
| `initial_decision_note` | string | — | First recorded decision |

Optional components are excluded via `_exclude` when disabled, so consumers can toggle
them freely without breaking the template's structure.

---

## What gets generated

```
your-project/
├── AGENTS.md                     # Canonical, always-on agent instructions
├── CLAUDE.md                     # Thin bridge importing AGENTS.md
├── README.md
├── .gitignore
└── .agents/
    ├── memory/
    │   ├── decisions.md          # Append-only decision log
    │   └── current-status.md     # Living high-level status
    ├── handoffs/
    │   └── template-handoff.md   # Reusable handoff template
    ├── agents/                   # (optional) role charters
    │   ├── coordinator.md
    │   ├── implementer.md
    │   └── reviewer.md
    ├── skills/
    │   └── example-skill/SKILL.md
    ├── references/
    │   ├── architecture.md
    │   ├── conventions.md
    │   └── testing.md
    ├── worktrees/                # (optional) new.sh / remove.sh helpers
    └── volley/                   # (optional) real-time stubs
```

---

## Development & validation

The template ships with a smoke-test suite that asserts structural correctness and the
presence of the mandatory protocols.

```bash
uv sync --dev
uv run copier copy --defaults --data-file tests/answers.yml . /tmp/check-output
bash tests/generate_and_check.sh /tmp/check-output
# → PASS: generated project structure and protocols verified.
```

See [`tests/README.md`](tests/README.md) for details, including an environmental note
about `.copier-answers.yml` and `copier update`.

---

## Design rationale

The reasoning behind every structural and content choice — why the repository is the
source of truth, why file-based coordination is primary, why progressive disclosure
matters, and how updateability is preserved — is documented in
[`docs/design-rationale.md`](docs/design-rationale.md).

---

## License

[Mozilla Public License 2.0](LICENSE)
