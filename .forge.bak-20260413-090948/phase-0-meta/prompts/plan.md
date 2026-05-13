# Phase 6 — Implementation Plan

## Context

You are planning the edit sequence for the feature pipeline agent audit. The specification (Phase 4) defines all required edits. The TDD criteria (Phase 5) define validation checks.

## Instructions

Create a dependency-ordered edit plan. Group edits by priority (P0 first) and by dependency (shared agents before skills that reference them).

## Pre-Implementation

1. Run test harness baseline: `cd C:/gitea_ceos-agents && ./tests/harness/run-tests.sh`
2. Record baseline result

## Edit Sequence

### Group 1: P0 — BLOCKING Fixes (Must complete first)

These fixes eliminate pipeline stalls and dirty git state.

**Task 1.1: Add smoke-check to rollback triggers (CRQ-4)**
- Files: `core/block-handler.md`, `agents/rollback-agent.md`
- Dependency: None
- Edits:
  - `core/block-handler.md` Step 1: Add `smoke-check` to the rollback trigger agent list (alongside fixer, reviewer, test-engineer)
  - `agents/rollback-agent.md` Step 1: Add `smoke-check` to the proceed-with-rollback agent list (alongside fixer, test-engineer, e2e-test-engineer, reviewer)

**Task 1.2: Add mode-branch to fixer Step 1 guard (CRQ-1, CRQ-2)**
- File: `agents/fixer.md`
- Dependency: None
- Edits:
  - Step 1: Add mode-branch — if context includes `Mode: feature-implementation`, accept architectural design + AC as valid input (don't require triage analysis / impact report)

**Task 1.3: Add Mode prefix to implement-feature dispatch points (CRQ-2)**
- File: `skills/implement-feature/SKILL.md`
- Dependency: Task 1.2 (fixer must understand the mode signal)
- Edits:
  - Step 6b fixer context: Prepend `Mode: feature-implementation.`
  - Step 6d reviewer context: Prepend `Mode: feature-implementation.`
  - Step 6e test-engineer context: Prepend `Mode: feature-implementation.`

**Task 1.4: Add NEEDS_DECOMPOSITION handler to implement-feature (CRQ-3)**
- File: `skills/implement-feature/SKILL.md`
- Dependency: None
- Edits:
  - After Step 6b fixer-reviewer loop description, add NEEDS_DECOMPOSITION handler
  - Mirror fix-ticket/SKILL.md step 5 pattern: authoritative revert, decompose_mode check, Block options

### Group 2: P1 — HIGH Quality Fixes

These improve agent output quality in feature mode.

**Task 2.1: Update fixer identity and TDD for feature mode (CRQ-5)**
- File: `agents/fixer.md`
- Dependency: Task 1.2 (Step 1 mode-branch already in place)
- Edits:
  - Frontmatter description: Add feature implementation mention
  - Role statement: Make mode-aware
  - Goal: Add feature-mode variant
  - Step 5 RED phase: Add feature-mode TDD variant

**Task 2.2: Update reviewer for feature mode (CRQ-6)**
- File: `agents/reviewer.md`
- Dependency: Task 1.3 (Mode signal available)
- Edits:
  - Step 1: Add mode-branch for reading feature artifacts
  - Step 4 root cause item: Add feature-mode variant
  - Step 4 completeness item: Add feature-mode variant

**Task 2.3: Update test-engineer for feature mode (CRQ-7)**
- File: `agents/test-engineer.md`
- Dependency: Task 1.3 (Mode signal available)
- Edits:
  - Frontmatter description: Make mode-neutral
  - Step 1: Add mode-branch for reading feature artifacts
  - Step 3: Add feature-mode test framing variant

**Task 2.4: Update e2e-test-engineer for feature mode (CRQ-2)**
- File: `agents/e2e-test-engineer.md`
- Dependency: None
- Edits:
  - Goal: Make mode-neutral
  - Step 1: Add mode-branch for reading feature artifacts

**Task 2.5: Add single-pass acceptance-gate compensating requirement (CRQ-8)**
- File: `skills/implement-feature/SKILL.md`
- Dependency: Task 2.2 (reviewer must understand file:line evidence instruction)
- Edits:
  - Step 6h: Document single-pass skip as explicit tradeoff
  - Add compensating reviewer instruction for file:line evidence

### Group 3: P2 — MEDIUM Technical Debt

Documentation and contract updates.

**Task 3.1: Update fixer-reviewer-loop contract (CRQ-10)**
- File: `core/fixer-reviewer-loop.md`
- Dependency: Tasks 1.2, 1.3 (mode signal exists)
- Edits:
  - Input Contract: Add discriminated union context shapes
  - Failure Handling: Add implement-feature reference

**Task 3.2: Update decomposition-heuristics scope (CRQ-11)**
- File: `core/decomposition-heuristics.md`
- Dependency: None
- Edits:
  - Purpose: Add scope annotation (bug pipeline only)
  - Output Contract: Add feature pipeline reference

**Task 3.3: Update state schema with ac_source (CRQ-12)**
- File: `state/schema.md`
- Dependency: None
- Edits:
  - Add `triage.ac_source` field to schema
  - Update `triage.acceptance_criteria` description

## Post-Implementation

1. Run test harness: `cd C:/gitea_ceos-agents && ./tests/harness/run-tests.sh`
2. Run all TDD criteria (TC-1 through TC-10 from Phase 5)
3. Review git diff to verify no destructive changes
4. Verify bug-fix language preservation (TC-4)

## Parallelization Opportunities

- Task 1.1 and Task 1.2 can run in parallel (no shared files)
- Task 2.1 through 2.4 can run in parallel (different files)
- Task 3.1 through 3.3 can run in parallel (different files)
- Task 1.3 and 1.4 depend on Tasks 1.1/1.2 but share the same file — must be sequential within the file

## Estimated Edit Count

| Group | Files | Edits | Lines added (est.) |
|-------|-------|-------|-------------------|
| P0 | 4 | 7 | ~50 |
| P1 | 5 | 12 | ~80 |
| P2 | 3 | 5 | ~30 |
| **Total** | **10** | **24** | **~160** |
