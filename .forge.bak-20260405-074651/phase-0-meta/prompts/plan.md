# Phase 6 — Implementation Plan

You are a **Senior Implementation Planner** creating a detailed, dependency-ordered task graph for a well-defined feature implementation.

## Task Context

Adding two features to `agents/scaffolder.md` in the ceos-agents plugin (v6.2.0 → v6.3.0):

1. **E2E Test Generation** — New conditional Batch 7 for Playwright e2e test suite
2. **Application Documentation for Agents** — New batch for `docs/ARCHITECTURE.md` + Module Docs population

## Codebase Context

- **Primary file:** `agents/scaffolder.md` (144 lines currently)
  - Process: 5 steps (including 4b scorecard)
  - Batches: 1-6 (Batch 6 conditional on web project)
  - Scorecard: 9 items
  - Constraints: ~12 rules
  - File count target in constraints section
- **Secondary files:**
  - `skills/scaffold/SKILL.md` (~500 lines) — may need Module Docs reference
  - `CHANGELOG.md` — new v6.3.0 entry
  - `.claude-plugin/plugin.json` — version bump
  - `.claude-plugin/marketplace.json` — version bump
  - `docs/plans/roadmap.md` — mark items as DONE
  - `tests/scenarios/` — new structural test(s)
- **Versioning:** MINOR bump (6.2.0 → 6.3.0)

## Plan Requirements

### Task Graph

Create a dependency-ordered list of tasks. Each task should specify:
- Task ID (T1, T2, ...)
- Description
- Target file(s)
- Dependencies (which tasks must complete first)
- Estimated size (S/M/L — S = < 20 lines changed, M = 20-50, L = 50+)
- Parallelizable with other tasks? (yes/no)

### Suggested Task Breakdown

1. **T1: Add Batch 7 (E2E Tests) to scaffolder.md** — Insert after Batch 6, with conditional logic matching Batch 6 pattern. Size: M
2. **T2: Add Batch 8 (Application Documentation) to scaffolder.md** — Insert after Batch 7 (or reuse existing Batch 5 extension). Size: M
3. **T3: Update scorecard in scaffolder.md** — Add 2 new items (E2E Test Setup, App Documentation). Size: S
4. **T4: Update constraints in scaffolder.md** — New NEVER/MUST rules + file count ceiling update. Size: S
5. **T5: Update CLAUDE.md config checklist in scaffolder.md** — Add Module Docs to optional sections. Size: S
6. **T6: Update scaffold skill if needed** — Assess whether `skills/scaffold/SKILL.md` needs changes for Module Docs path. Size: S
7. **T7: Write structural tests** — New test file validating the new features. Size: M
8. **T8: Write changelog entry** — v6.3.0 in CHANGELOG.md. Size: S
9. **T9: Update roadmap** — Move items to DONE section. Size: S
10. **T10: Version bump** — plugin.json + marketplace.json. Size: S

### Dependency Graph

```
T1 ──┐
T2 ──┤
T3 ──┼── T7 (tests depend on features being implemented)
T4 ──┤
T5 ──┘
T6 ────── (independent, can parallel with T1-T5)
T7 ────── T8 (changelog after tests pass)
T8 ────── T9 (roadmap after changelog)
T9 ────── T10 (version bump last)
```

### Parallelization Opportunities

- T1, T2, T3, T4, T5 all modify `agents/scaffolder.md` — they CANNOT be parallelized (same file)
- T6 can run in parallel with T1-T5 (different file)
- T7 can run in parallel with T6 after T1-T5 complete
- T8, T9, T10 are sequential (different files, but logical dependency)

## Anti-Patterns

- Do NOT create separate commits for each task — batch logically related changes
- Do NOT modify files that don't need changes (e.g., don't touch agent files that already read Module Docs)
- Do NOT over-engineer — this is a markdown-only change, not a code refactor

## Output Format

```markdown
## Task Graph

| ID | Task | File(s) | Deps | Size | Parallel? |
|----|------|---------|------|------|-----------|
| T1 | ... | ... | none | M | no (same file) |

## Execution Order

1. Phase A (sequential — same file): T1 → T2 → T3 → T4 → T5
2. Phase B (parallel): T6 || T7
3. Phase C (sequential): T8 → T9 → T10

## Commit Strategy

- Commit 1: All scaffolder.md changes (T1-T5) + skill changes (T6) + tests (T7) + changelog (T8)
- Commit 2: Roadmap update (T9)
- Commit 3: Version bump (T10) — separate per project convention
```
