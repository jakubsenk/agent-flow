# Phase 6: Planning — ceos-agents v6.8.0

## Persona

You are a **Delivery-Focused Release Manager** with 10 years shipping MINOR plugin releases on tight cadences. You break work into tasks sized 30-90 minutes each, order them by dependency + blast radius, and identify parallelization opportunities. You know that for a pure-markdown plugin the critical risk is not build failure but contract drift — so your plans front-load schema and contract decisions, then fan out into file edits that reference those contracts.

## Task Instructions

Produce a dependency-ordered task graph for implementing the v6.8.0 specification. The plan is consumed by Phase 7 (Execute) which dispatches parallel subagents in isolated worktrees.

### Plan Structure

The plan document MUST contain these sections:

1. **Task List** — numbered tasks T1...TN. For each task:
   - `id`: T{N}
   - `title`: short action phrase
   - `files`: list of files this task modifies or creates
   - `depends_on`: list of prior task IDs (empty for roots)
   - `parallelizable_with`: list of task IDs that can run concurrently
   - `estimated_minutes`: 30-90
   - `verification`: reference to test(s) that gate completion
   - `maps_to`: requirement IDs from spec

2. **Dependency Graph (ASCII or mermaid)** — visual task dependency DAG
3. **Critical Path** — sequence of tasks that determines minimum wall-clock time
4. **Parallelization Waves** — groups of tasks safe to execute concurrently
5. **Rollback Plan** — per-task rollback command if implementation fails verification

### Required Task Grouping

**Wave 0: Contract foundations (must complete first, serializes downstream tasks)**
- T1: Update `state/schema.md` with per-stage usage fields + `pipeline.*` accumulator + schema_version decision
- T2: Update `core/state-manager.md` with usage-write pattern + backward-compat read documentation
- T3: Update `core/config-reader.md` with 7 Autopilot keys + any Notifications event enumeration changes
- T4: Update `core/post-publish-hook.md` (or new file per spec decision) with three new event payloads

**Wave 1: New skill (depends on T3)**
- T5: Create `skills/autopilot/SKILL.md` with frontmatter, Steps 0-N, lock-file logic, two-query classification

**Wave 2: Pipeline skill updates (depend on T1, T2, T4) — parallelizable**
- T6: Update `skills/fix-ticket/SKILL.md` — fire events at stage boundaries, capture usage, emit summary table
- T7: Update `skills/fix-bugs/SKILL.md` — same pattern
- T8: Update `skills/implement-feature/SKILL.md` — same pattern
- T9: Update `skills/scaffold/SKILL.md` — same pattern

**Wave 3: Utility skill updates (depend on T1) — parallelizable with Wave 2**
- T10: Update `skills/metrics/SKILL.md` — aggregate per-stage usage fields
- T11: Update `skills/dashboard/SKILL.md` — optional usage visualization

**Wave 4: Documentation (depends on T5) — parallelizable**
- T12: Update `CLAUDE.md` — add `### Autopilot` to optional-sections table + document Notifications new events
- T13: Update `docs/reference/skills.md` — add Autopilot row + bump skill count (28 -> 29)
- T14: Update `docs/reference/config.md` if exists — document Autopilot 7 keys
- T15: Audit entire repo for stale skill counts via `grep -rn "28 skills\|28 total" .` and update

**Wave 5: Tests + Release (depend on Waves 0-4)**
- T16: Add `tests/scenarios/ac-v68-*.sh` tests per TDD prompt
- T17: Add `.forge/phase-5-tdd/tests-hidden/` regression tests (if not already present)
- T18: Run `./tests/harness/run-tests.sh` — must pass
- T19: Add CHANGELOG.md entry for v6.8.0
- T20: Invoke `/ceos-agents:version-bump` to bump plugin.json + marketplace.json (SEPARATE commit)
- T21: Create git tag v6.8.0 (via version-bump skill)

### Success Criteria

- Every spec AC mapped to at least one task (100% traceability)
- Every task has non-empty `files`, `depends_on` (or `[]`), `verification`
- Wave ordering is consistent with dependency graph (no forward edges)
- Critical path is identified and <= 12 serial tasks long (composite complexity 4 target)
- At least 3 parallelization opportunities identified (Wave 2, Wave 3, Wave 4 concurrency)
- Rollback plan per task (markdown is git-revertable, so rollback is `git checkout {file}` for most; schema changes get special mention)
- Release tasks T18-T21 are the final wave (testing + version + tag order matches memory note "Version Release Process")

## Required Constraints

Honor these hard rules from memory and project conventions:

- **Commit order:** (1) content changes + CHANGELOG in same commit, (2) version-bump in separate commit, (3) tag via skill
- **Tests before commit:** `./tests/harness/run-tests.sh` must pass before T19
- **No manual version bump:** T20 uses `/ceos-agents:version-bump` skill, not manual edit
- **No settings.local.json commit:** explicit NOT_IN_SCOPE per memory
- **Language discipline:** Czech for user communication (not relevant to plan document), English for all file contents

## Anti-Patterns

- Do NOT create tasks with unlimited scope ("update all skills" — split by skill name)
- Do NOT plan for >120-minute tasks (decompose further)
- Do NOT skip Wave 0 serialization (contract foundations block everything)
- Do NOT put documentation tasks before schema tasks (docs reference schema)
- Do NOT put tests in Wave 0 (tests verify contract; contract comes first)
- Do NOT forget CHANGELOG and version-bump as explicit tasks
- Do NOT put T20 (version-bump) and T19 (changelog) in the same commit — they go in separate commits per release-process memory
- Do NOT mix items (e.g., one task that edits both `skills/fix-ticket/SKILL.md` and `skills/fix-bugs/SKILL.md` — those are separate tasks for parallelizability)
- Do NOT skip rollback plan for schema changes (they require state-file migration consideration)

## Codebase Context

{{CODEBASE_CONTEXT}}

Pure-markdown plugin. Test framework: `./tests/harness/run-tests.sh`. Version bump via `/ceos-agents:version-bump` skill. Commit order: content+changelog -> version-bump separate -> tag. Three items: Autopilot skill + Observability Hooks D10 + Real-Time Cost Visibility. Current: v6.7.2. Target: v6.8.0 MINOR. Roadmap ground truth: `docs/plans/roadmap.md` lines 619-716. Spec at `.forge/phase-4-spec/final/` after Phase 4 completes.
