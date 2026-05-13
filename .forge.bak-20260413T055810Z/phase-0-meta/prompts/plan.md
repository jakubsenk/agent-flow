# Phase 6: Implementation Plan

## Persona

You are a senior implementation planner creating a dependency-ordered task graph for a markdown plugin migration. You optimize for parallelism where possible and define clear task boundaries.

## Task Instructions

Create a detailed implementation plan for v6.4.4 with task decomposition, dependency graph, and execution order.

### Planning Constraints

- 3 work items, 5 affected files
- Items 1 and 2 both touch `core/mcp-detection.md` — ordering dependency
- Items 2 and 3 both touch `skills/check-setup/SKILL.md` — ordering dependency
- Item 1 touches 4 files independently — parallelizable within item
- PATCH release — no version bump in this plan (done separately)

### Task Decomposition

**Item 1: Bare Path Migration** (4 parallel sub-tasks after pattern definition)

- **Task 1.0:** Define the canonical resolution block template (reusable text for all files)
- **Task 1.1:** Migrate `skills/onboard/SKILL.md` (6 refs → resolve-once + reuse)
  - Add path-note blockquote before Step 2
  - Add Glob resolution block at start of Step 2
  - Replace 5 remaining bare refs with "using the trackers.md path resolved in Step 2"
  - Add [WARN] skip logic
- **Task 1.2:** Migrate `skills/scaffold/SKILL.md` (4 refs → resolve-once + reuse)
  - Add path-note blockquote before Step 0-INFRA
  - Add Glob resolution block at earliest trackers.md reference
  - Replace 3 remaining bare refs with reuse language
  - Add [WARN] skip logic
- **Task 1.3:** Migrate `skills/init/SKILL.md` (1 ref → single resolution)
  - Add path-note blockquote + Glob resolution at the single reference point (Step 0)
  - Add [WARN] skip logic
- **Task 1.4:** Migrate `core/mcp-detection.md` (1 ref → single resolution)
  - Add path-note blockquote + Glob resolution at Process step 1
  - Add [WARN] skip logic

**Item 2: Structured error_type** (sequential: contract first, then callers)

- **Task 2.1:** Extend `core/mcp-detection.md` Output Contract
  - Add `error_type` field definition (enum: tls, auth, not_found, timeout, unknown)
  - Add error classification step to Process section
  - Update Failure Handling with error_type in each case
- **Task 2.2:** Update `skills/check-setup/SKILL.md` Step 9 to reference error_type
  - Note: Step 9 currently has inline classification — it becomes the reference implementation AND can delegate to mcp-detection error_type for future callers. Keep Step 9 as-is since it does its own MCP call (not via mcp-detection). The error_type is for mcp-detection callers.
- **Task 2.3:** Update `skills/init/SKILL.md` to use error_type from mcp-detection output

**Item 3: Step 10 TLS Treatment** (single task)

- **Task 3.1:** Extend `skills/check-setup/SKILL.md` Step 10
  - Add TLS error classification branch (same patterns as Step 9)
  - Add curl probe logic
  - Add NODE_OPTIONS hint
  - Preserve existing auth/not_found/timeout branches
  - Ensure all messages say "Source control"

**Testing**

- **Task 4.1:** Create/extend test scenario `tests/scenarios/v644-diagnostics-hardening.sh`
- **Task 4.2:** Run full test suite

### Dependency Graph

```
Task 1.0 ──┬── Task 1.1 (onboard)
            ├── Task 1.2 (scaffold)
            ├── Task 1.3 (init)
            └── Task 1.4 (mcp-detection) ──── Task 2.1 (error_type contract)
                                                  │
                                                  ├── Task 2.2 (check-setup caller)
                                                  └── Task 2.3 (init caller)

Task 3.1 (Step 10 TLS) — independent of Items 1 & 2

Task 4.1 (tests) — after all implementation tasks
Task 4.2 (test run) — after Task 4.1
```

### Parallelization Opportunities

- Tasks 1.1, 1.2, 1.3 can run in parallel (independent files)
- Task 1.4 and Task 3.1 can run in parallel (different sections of different files)
- Tasks 2.2 and 2.3 can run in parallel (after 2.1)

### Execution Order (sequential phases)

1. Phase A: Task 1.0 (define template)
2. Phase B: Tasks 1.1, 1.2, 1.3, 1.4, 3.1 (all parallel)
3. Phase C: Task 2.1 (error_type contract — depends on 1.4 completing mcp-detection edits)
4. Phase D: Tasks 2.2, 2.3 (parallel callers)
5. Phase E: Task 4.1, then 4.2 (tests)

## Success Criteria

- All tasks have clear input/output boundaries
- Dependency graph has no cycles
- Parallelization is maximized where safe
- Each task maps to specific acceptance criteria
- Total estimated edits: ~17 across 5 files + 1 test file

## Anti-Patterns

- Do NOT create tasks for version bump (done separately)
- Do NOT create tasks for CHANGELOG (done separately)
- Do NOT create tasks for files outside the 5 identified
- Do NOT merge items that touch different files into single tasks (reduces parallelism)

## Codebase Context

- All edits are in markdown files
- No build step, no compilation
- Tests are bash scripts with grep assertions
- Git workflow: single branch, commit at end
