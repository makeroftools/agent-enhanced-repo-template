# Design Rationale

Why this Copier template is structured the way it is. This is the reasoning behind the
choices encoded in `copier.yml` and the rendered `template/`.

## Goal
Generate AI-agent-native repositories that are correct, reproducible, and mission-critical
safe. Continuity, auditability, and explicit boundaries take precedence over convenience.

## Core principles

### Repository as source of truth
All durable knowledge — decisions, status, handoffs, instructions — lives in
version-controlled files under `.agents/`. Agent sessions are independent by design in
Zed and most tools; they do not share chat history. Continuity must therefore be made
explicit in the repository itself. Ephemeral chat history is never authoritative.

### Progressive disclosure
The root `AGENTS.md` is intentionally concise and always-on. Detail lives in
`.agents/skills/` (loaded on demand) and `.agents/references/` (loaded when relevant).
Overly long always-on context degrades agent performance and correctness.

### File-based drop-box as primary coordination
Append-only `decisions.md` + living `current-status.md` + explicit handoff files form a
durable, auditable, offline-resilient coordination mechanism. This is the primary path.
Real-time protocols (Volley/MQTT) are optional and secondary only, because they introduce
operational dependencies (broker availability, network) that are undesirable for
mission-critical work.

### Isolation first
When parallel agents may edit overlapping files, prefer Git worktrees over locking or
message brokers. The optional worktree helpers make this one command.

### Explicit over implicit
Every continuity and coordination path is written into the instruction files and shared
memory locations. Nothing is left to chance or chat.

## Questionnaire design
- `primary_language` conditions the exact commands in `AGENTS.md` and `testing.md`, so
  generated projects are immediately usable.
- `include_*` flags let consumers opt into optional components (multi-agent charters,
  sample skill, worktree helpers, volley stubs) without weakening the mandatory core.
- `include_volley_stubs` defaults to `false` to reinforce that file-based coordination is
  primary.
- `_subdirectory: template` keeps the template's own docs/tests/tooling cleanly separated
  from rendered content and enables `copier update`.

## Updateability
`copier update` is supported. Optional files are excluded via `_exclude` so consumers can
toggle components without breaking the template's structure. The mandatory core
(AGENTS.md, memory, handoffs) is always rendered.

## Environmental note: `.copier-answers.yml`

Copier 9.17.1 in this environment does not auto-write `.copier-answers.yml` on
`copier copy` (reproduced with a barebones template). This is environmental, not a
template defect. Since `copier update` requires that answers file for `_src_path` /
`_commit`, a true end-to-end update cannot be bootstrapped here. A real update test needs
an environment that writes the answers file, or a manually generated answers file plus a
pushed, resolvable tag (e.g. `v0.1.0`).
