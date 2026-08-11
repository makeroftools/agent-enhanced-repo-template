# MISSION-CRITICAL DIRECTIVE — AI Agent Repository Copier Template

**Classification**: Mission-critical  
**Audience**: Coding worker agent  
**Priority**: Highest  
**Success criterion**: The resulting Copier template must be correct, complete, reproducible, and ready for production use with zero ambiguity in agent behavior.

You are directed to implement and finalize a production-grade Copier template that generates AI-agent-native repositories. The design has already been established. Your task is to realize it accurately and optimally. Do not improvise architecture. Do not omit required elements. Do not weaken the protocols.

---

## 1. Objective

Produce a complete, validated Copier template repository whose generated projects enforce:

- Durable session continuity via explicit handoffs and shared memory files
- Tool-agnostic, Zed-compatible agent instructions (`AGENTS.md` as primary)
- Progressive disclosure (lean always-on instructions + on-demand Skills and references)
- Optional multi-agent role charters with clear boundaries
- Git worktree isolation guidance for parallel agents
- Updateability through Copier (`copier update`)

The generated repositories must treat version-controlled files under `.agents/` as the single source of truth. Ephemeral chat history is never authoritative.

---

## 2. Required Repository Layout (Template Side)

The Copier template repository itself must contain exactly this structure (or a strict superset that preserves it):
<copier-template-root>/
├── copier.yml                          # Questionnaire + Copier configuration
├── README.md                           # Template usage and design notes
├── docs/
│   └── design-rationale.md             # Why these choices were made
├── tests/
│   ├── README.md
│   └── generate_and_check.sh           # Smoke-test script that must pass
└── template/                           # Content rendered into consumer projects (_subdirectory)
├── AGENTS.md.jinja
├── CLAUDE.md.jinja                 # Thin bridge that imports AGENTS.md
├── README.md.jinja
├── .gitignore
└── .agents/
├── memory/
│   ├── decisions.md.jinja      # Append-only drop-box
│   └── current-status.md.jinja
├── handoffs/
│   └── template-handoff.md.jinja
├── agents/                     # Role charters (conditional on questionnaire)
│   ├── coordinator.md.jinja
│   ├── implementer.md.jinja
│   └── reviewer.md.jinja
├── skills/
│   └── example-skill/
│       └── SKILL.md.jinja
└── references/
├── architecture.md.jinja
└── conventions.md.jinja


Use `_subdirectory: template` in `copier.yml`. Keep the template repository’s own tests, docs, and tooling cleanly separated from the rendered content.

---

## 3. Mandatory Content Requirements

### 3.1 Root `AGENTS.md` (generated)

Must be lean, imperative, and contain these sections in order:

1. Overview (project name + description + primary language)
2. Commands (language-conditioned, exact and preferred)
3. Hard Constraints (non-negotiable)
4. **Session Start Protocol (Mandatory)** — read current-status.md, decisions.md, and any relevant handoff; summarize before work
5. During Work rules (scope control + decision recording)
6. **Session End / Handoff Protocol (Mandatory)** — write complete handoff file + update status
7. Multi-Agent Coordination (role charters + worktree isolation when enabled)
8. Progressive Disclosure statement
9. Definition of Done
10. Pointers to deeper material under `.agents/`

Do not allow the generated `AGENTS.md` to become encyclopedic. Detail belongs in Skills and references.

### 3.2 Shared Memory (Drop-box)

- `decisions.md` — append-only, structured entries, initial initialization entry present
- `current-status.md` — living high-level summary that agents must keep truthful

### 3.3 Handoff Protocol

A complete, reusable template must exist at `.agents/handoffs/template-handoff.md`. Every incomplete unit of work must produce a handoff file.

### 3.4 Role Charters (when multi-agent is enabled)

Three clear, bounded roles:
- Coordinator
- Implementer
- Reviewer

Each must define Purpose, Responsibilities, Must Never, Inputs, and Outputs.

### 3.5 Skills

At least one correctly formatted sample Skill (`SKILL.md` with name + description + body) under `.agents/skills/`. Format must be compatible with Zed Skills and the broader Agent Skills convention.

### 3.6 Questionnaire (`copier.yml`)

Must expose at minimum:
- project_name
- project_description
- primary_language (with sensible choices and conditional commands)
- include_multi_agent (bool)
- include_sample_skill (bool)
- include_worktree_helpers (bool)
- include_volley_stubs (bool, default false)
- author_name / initial_decision_note (or equivalent)

Use a recent `_min_copier_version`. Prefer clean defaults.

---

## 4. Hard Constraints (Non-Negotiable)

- Prefer explicit, version-controlled file-based continuity over real-time or ephemeral mechanisms.
- File-based drop-box + mandatory handoff protocol is primary. Volley (or any MQTT/real-time layer) is optional and secondary only.
- Generated `AGENTS.md` must force Session Start and Handoff protocols.
- Do not rely on chat history as durable state.
- Keep always-on instructions short and high-signal.
- All non-trivial decisions in generated projects must be recorded in `decisions.md`.
- Isolation of concurrent agents must prefer Git worktrees.
- The template must be updatable via `copier update` without destroying consumer customizations where possible.
- Smoke tests must pass. Structural correctness is required.

---

## 5. Validation Requirements

Before declaring the work complete you must:

1. Generate at least one project with the default / recommended answers.
2. Confirm every required file listed in Section 2 exists and is correctly rendered (no unresolved Jinja, correct protocols present).
3. Confirm `AGENTS.md` contains the Session Start Protocol and Handoff Protocol language.
4. Confirm `decisions.md` and `current-status.md` are present and usable.
5. Run (or create and run) a smoke-test script equivalent to `tests/generate_and_check.sh` that asserts the above.
6. Verify that language-conditioned commands render correctly for at least the primary language choice.

Any missing required element or broken protocol constitutes failure.

---

## 6. Definition of Done

The task is complete only when all of the following are true:

- The Copier template repository matches the required layout and content quality.
- `copier copy` produces a correct, immediately usable agent-native project.
- Session Start and Handoff protocols are mandatory and clearly stated in every generated `AGENTS.md`.
- Shared memory and handoff files are present and correctly structured.
- Multi-agent role charters exist when enabled and have clear boundaries.
- A working smoke test confirms structural correctness.
- The template is ready for versioning (taggable) and subsequent `copier update` use.
- No critical ambiguity remains for future coding or agent workers.

---

## 7. Execution Order

1. Establish the directory layout exactly as specified.
2. Implement `copier.yml` with the required questions and settings.
3. Implement all Jinja templates under `template/` with correct, lean, imperative content.
4. Implement the three role charters, sample Skill, memory files, and handoff template.
5. Write clear README and design-rationale documentation.
6. Create and execute the smoke-test validation.
7. Perform final review against every item in Sections 3–6.
8. Report completion only when Definition of Done is fully satisfied.

---

## 8. Reference Design Intent

This template exists to make AI agent collaboration reliable under mission-critical conditions. Continuity, auditability, and explicit boundaries take precedence over convenience or brevity of implementation. When in doubt, choose the more explicit, more durable, and more reviewable option.

Do not deviate from the protocols or weaken the mandatory language in `AGENTS.md`.

---

**End of directive.**  
Execute completely and correctly. Report only when the Definition of Done is met.

Thoughts
This single document is optimal for a coding worker agent because it is:

