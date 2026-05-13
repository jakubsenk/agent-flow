# Phase 0 — Task Analysis

## Classification

| Dimension | Value | Reasoning |
|-----------|-------|-----------|
| **Type** | feature | Adding new capability (design awareness) to existing scaffold pipeline |
| **Complexity** | medium-high | Touches 3-4 agent definitions + 1 skill orchestration + tests + docs. No runtime code, but design decisions affect plugin architecture. |
| **Ambiguity** | 4/5 (high) | Approach not decided. 5 options with different trade-offs. Requires research phase before spec. |
| **Confidence** | 0.3 | Too early to commit to a specific approach — research must determine which option(s) to pursue |
| **Risk** | medium | Wrong approach could bloat the plugin (unnecessary new agent) or be too shallow (CSS class in a config). Must balance utility vs complexity. |

## Scope Analysis

**Files likely affected (depending on chosen approach):**
- `agents/scaffolder.md` — new design batch (Batch 6) or design-aware instructions in existing batches
- `agents/spec-writer.md` — conditional "Design & UX" section for web projects
- `agents/stack-selector.md` — CSS framework selection awareness
- `skills/scaffold/SKILL.md` — orchestration changes if new agent or new step added
- `agents/fixer.md` — design-aware context injection for frontend tasks (lightweight)
- `CLAUDE.md` — documentation updates if new agent or config section added
- `docs/reference/` — agent and skill reference updates
- `tests/scenarios/` — new test scenario(s) for design pipeline
- Possibly: `agents/ui-designer.md` (new file, if Option 1 chosen)

**Files NOT affected:**
- `core/` — no new pipeline patterns needed
- Bug-fix pipeline agents (triage-analyst, code-analyst, reproducer, browser-verifier, etc.)
- Publisher, rollback-agent, deployment-verifier
- `checklists/` — no new pipeline phase checklist needed

## Key Constraints

1. **Pure markdown plugin** — no runtime code, no npm packages, no build system. All changes are markdown definitions.
2. **LLMs lack visual taste** — solutions must focus on tooling setup (CSS framework installation, Tailwind config, component library setup), not aesthetic decisions.
3. **Backend/CLI projects must be unaffected** — design awareness must be conditional, triggered only for web/frontend/fullstack projects.
4. **100-line diff limit on fixer** — design changes must fit within existing constraints.
5. **19 agents currently** — adding a 20th has cost (documentation, testing, maintenance). Must be justified.
6. **Scaffolder has 5 batches** — adding a 6th is straightforward but increases token usage.
7. **Versioning policy** — new optional agent = MINOR bump; new required config key = MAJOR bump.

## Routing Decision

**Route: Full forge pipeline (research → brainstorm → spec → TDD → plan → execute → verify)**

Rationale: High ambiguity requires research phase. Multiple viable approaches need structured brainstorming with heterogeneous personas. The chosen approach must be specified before implementation to avoid wasted effort on the wrong option.

## Dependencies

- No external dependencies
- No infrastructure requirements
- Research is self-contained within the codebase (reading existing agents, understanding current pipeline)
