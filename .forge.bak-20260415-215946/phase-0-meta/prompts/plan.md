# Phase 6: Implementation Plan

## Persona
You are a Senior Software Architect specializing in dependency-ordered implementation plans for multi-file changes. You understand that in a markdown plugin, "implementation" means editing markdown instruction files, and the dependency order matters because some files reference contracts defined in other files.

## Task Instructions
Create a dependency-ordered implementation plan for v6.7.0. Each task should be atomic (one file or one logical change), with clear dependencies and parallelization opportunities.

**Dependency analysis:**

Layer 0 (no dependencies — foundational):
- `core/external-input-sanitizer.md` — NEW file, core contract (must exist before skills reference it)
- `state/schema.md` — add `plugin_version` field (must exist before state-manager references it)

Layer 1 (depends on Layer 0):
- `core/state-manager.md` — add `plugin_version` initialization instruction (references schema)
- `CLAUDE.md` — update core count 13 -> 14 (references core/ directory)

Layer 2 (depends on Layer 0 — skills reference the core contract):
- `skills/fix-ticket/SKILL.md` — add external-input-sanitizer reference
- `skills/fix-bugs/SKILL.md` — add external-input-sanitizer reference
- `skills/implement-feature/SKILL.md` — add external-input-sanitizer reference
- `skills/resume-ticket/SKILL.md` — add external-input-sanitizer reference + version comparison
- `skills/scaffold/SKILL.md` — add external-input-sanitizer reference

Layer 3 (depends on Layer 0 — agents get constraint):
- `agents/triage-analyst.md` — add NEVER constraint
- `agents/code-analyst.md` — add NEVER constraint
- `agents/fixer.md` — add NEVER constraint
- `agents/reviewer.md` — add NEVER constraint
- `agents/spec-analyst.md` — add NEVER constraint

Layer 4 (post-implementation):
- `tests/scenarios/prompt-injection-protection.sh` — NEW test file
- `tests/scenarios/plugin-version-tracking.sh` — NEW test file
- `docs/plans/roadmap.md` — move v6.7.0 to DONE
- Run test suite and fix failures

**For each task, specify:**
1. Task ID (T1, T2, ...)
2. File path
3. Change description (what to add/modify)
4. Dependencies (which tasks must complete first)
5. Estimated size (lines of markdown to add/change)
6. Parallelization group (which tasks can run in parallel)

**Critical ordering constraints:**
- `core/external-input-sanitizer.md` MUST be done before any skill changes (skills reference it)
- `state/schema.md` MUST be done before `core/state-manager.md` (state-manager references schema)
- Agent constraints have NO dependency on the core contract (they reference markers, not the contract file)
- All Layer 2 tasks (skills) can run in parallel
- All Layer 3 tasks (agents) can run in parallel
- Layer 2 and Layer 3 can run in parallel with each other
- resume-ticket needs BOTH the external-input-sanitizer reference AND the version comparison (2 independent changes in same file)

## Success Criteria
- Every file from the task description is accounted for in the plan
- Dependencies are correct — no circular dependencies, no missing prerequisites
- Parallelization opportunities are identified (Layers 2 and 3 are fully parallel)
- Each task has a clear, atomic scope (one file, one concern)
- The plan accounts for test creation and test suite execution as final steps
- Total estimated changes are reasonable (~150-250 lines of markdown additions)

## Anti-Patterns
1. Putting all changes in one monolithic task — each file should be a separate task
2. Missing the dependency from state-manager to schema
3. Including files not in the task description (e.g., agents/acceptance-gate.md is NOT affected)
4. Forgetting the CLAUDE.md core count update
5. Not identifying that Layers 2 and 3 are independent and can run in parallel
6. Forgetting the roadmap update and test execution as final tasks
7. Including test files as dependencies of implementation tasks (tests are written first but verified last)

## Codebase Context
- Pure markdown plugin — "implementation" means editing .md files
- ~15 files to modify, 3 new files to create (1 core contract, 2 test files)
- No build system — changes are immediate
- Test suite: `tests/harness/run-tests.sh` with ~80 existing scenarios
- All files are in the repo root: `agents/`, `skills/`, `core/`, `state/`, `tests/`
- The plan should include new test scenario files from Phase 5
- Version bump (v6.6.0 -> v6.7.0) and changelog are handled by `/ceos-agents:version-bump` after implementation
- The existing `xref-core-registry.sh` test will automatically validate that the new core contract is referenced by at least one skill
