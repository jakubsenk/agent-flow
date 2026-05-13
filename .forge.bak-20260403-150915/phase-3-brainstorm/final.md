# Phase 3: Brainstorm Synthesis

## Three Perspectives

| Perspective | Core Proposal | Version | Files changed |
|-------------|--------------|---------|---------------|
| **Minimalist** | Scaffolder Batch 6 only | PATCH | 1 (scaffolder.md) |
| **Architect** | Stack-selector `project_type` + spec-writer `spec/design.md` + scaffolder Batch 6 + fixer context | MINOR | 4 agents + 1 skill |
| **Skeptic** | Scaffolder Batch 6 with framework lookup table, NO stack-selector/spec-writer changes, NO DaisyUI | PATCH | 1 (scaffolder.md) |

## Key Agreements

All three agree:
1. **No new agent** — distributing design work across existing agents is sufficient
2. **Tailwind CSS for JS-based web stacks** — highest LLM reliability
3. **Conditional on web project** — CLI/API projects must be unaffected
4. **Scaffolder Batch 6** is the core change — all approaches include it

## Key Disagreements

| Question | Minimalist | Architect | Skeptic |
|----------|-----------|-----------|---------|
| Change stack-selector? | No | Yes (project_type) | No (too risky) |
| Add spec/design.md? | No (later) | Yes | No (scope creep) |
| DaisyUI themes? | Yes (simple) | Yes (categorization) | No (drop to examples/) |
| Non-JS stacks (Django, Rails)? | Tailwind CDN | Tailwind standalone CLI | Classless CSS (Pico) |
| Version impact | PATCH | MINOR | PATCH |

## Judge Decision

**Phased approach — start with Minimalist, prepare for Architect later:**

### Phase A (this PR): PATCH — Scaffolder + Spec-writer only
1. **Scaffolder Batch 6 "Design"** — conditional on detecting web framework in stack input
   - JS-based web stacks (React, Vue, Svelte, Next.js, etc.): install Tailwind CSS + base config
   - Server-rendered with optional JS (Django, Rails, Flask): Tailwind standalone CLI or classless CSS fallback
   - CLI/API/Library: skip batch entirely
   - Output: tailwind.config.js (or equivalent), globals.css with @tailwind directives, base layout styles
2. **Spec-writer conditional section** — when project description or tech stack signals "web":
   - Add "Design & UX" subsection to spec/README.md (not a separate file)
   - Contains: CSS framework choice, responsive requirement, accessibility level
   - This flows to fixer automatically (spec/ is already in fixer's context)
3. **Scaffolder scorecard** — add "Design system" check for web projects
4. **NO stack-selector changes** (skeptic wins — output contract change is risky)
5. **NO DaisyUI** in core (skeptic wins — ship as Agent Override example)
6. **NO new flags** on scaffold command yet (YAGNI)

### Phase B (future MINOR): Stack-selector + formal design signal
- Add `project_type` to stack-selector output
- Add `--web`/`--api`/`--cli` flags
- Add DaisyUI as optional enhancement
- This is a separate version bump when users validate Phase A works

### Rationale
- The skeptic correctly identified that changing stack-selector output is the highest-risk change with questionable value (scaffolder already knows the framework from its input)
- The minimalist correctly identified that 80% of the value comes from just Batch 6
- The architect correctly identified that spec/design.md (as a subsection, not separate file) gives the fixer design context for free
- DaisyUI in core is premature — ship as Agent Override example

### Files Changed (Phase A)
1. `agents/scaffolder.md` — add Batch 6 "Design" + scorecard entry (~20 lines)
2. `agents/spec-writer.md` — add conditional "Design & UX" subsection (~10 lines)
3. `tests/scenarios/` — new test for design batch
4. `examples/` — DaisyUI Agent Override example
5. `docs/plans/roadmap.md` — move from EXPLORING to DONE, add Phase B to PLANNED

**Estimated total change:** ~40 lines across 2 agent files + test + example
**Version:** PATCH (6.1.7) — no new config keys, no output contract changes
