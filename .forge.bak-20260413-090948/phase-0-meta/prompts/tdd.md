# Phase 5 — TDD (Test Criteria Definition)

## Context

This is a pure markdown plugin — there is no runtime code to test. The test harness at `tests/harness/run-tests.sh` performs structural validation of agent definitions, skill files, and core contracts.

## Instructions

Define the test criteria that must pass after all edits are applied. Since this is markdown-only, "tests" are structural validation checks.

## Pre-Change Baseline

Before making any edits:
1. Run `tests/harness/run-tests.sh` and record the baseline result
2. If any tests fail in baseline, document them as pre-existing failures (not caused by our changes)

## Post-Change Test Criteria

### TC-1: Test Harness Pass
**Command:** `cd C:/gitea_ceos-agents && ./tests/harness/run-tests.sh`
**Expected:** All tests pass (same pass count as baseline, no new failures)
**Rationale:** Structural validation of all agent and skill files

### TC-2: Agent Frontmatter Integrity
**Check:** For each modified agent file (fixer, reviewer, test-engineer, e2e-test-engineer, rollback-agent):
- Frontmatter contains exactly: name, description, model, style
- No extra frontmatter fields added
- description field is a single line
**Method:** Read each file, verify frontmatter block

### TC-3: Agent Section Order Integrity
**Check:** For each modified agent file:
- Sections appear in order: Goal, Expertise, Process, Constraints
- No sections removed or reordered
- No new top-level sections added (subsections within Process are fine)
**Method:** Grep for ## headings in each agent file

### TC-4: Bug-Fix Language Preservation
**Check:** Verify that bug-fix pipeline vocabulary is NOT removed:
- `agents/fixer.md` still contains: "triage analysis", "impact report", "root cause", "reproduce the bug"
- `agents/reviewer.md` still contains: "bug report", "triage analysis", "impact report", "Root cause"
- `agents/test-engineer.md` still contains: "bug report", "regression test"
- `agents/e2e-test-engineer.md` still contains: "bug report"
**Method:** Grep each file for the required terms

### TC-5: Mode-Branch Presence
**Check:** Verify that mode-aware branching was added:
- `agents/fixer.md` Step 1 contains a conditional for feature mode
- `agents/reviewer.md` Step 1 contains a conditional for feature mode
- `agents/test-engineer.md` Step 1 contains a conditional for feature mode
- `agents/e2e-test-engineer.md` Step 1 contains a conditional for feature mode
**Method:** Grep each file for "feature" or "Mode:" or "feature-implementation"

### TC-6: Smoke-Check in Rollback Triggers
**Check:** Verify smoke-check is in both trigger lists:
- `core/block-handler.md` Step 1 mentions `smoke-check` in the rollback dispatch condition
- `agents/rollback-agent.md` Step 1 mentions `smoke-check` in the proceed-with-rollback list
**Method:** Grep both files for "smoke-check"

### TC-7: NEEDS_DECOMPOSITION Handler in implement-feature
**Check:** Verify the handler exists:
- `skills/implement-feature/SKILL.md` contains "NEEDS_DECOMPOSITION" in Step 6b area
- Handler includes: authoritative revert, decompose_mode check, Block on DISABLED
**Method:** Grep for NEEDS_DECOMPOSITION in the skill file

### TC-8: State Schema ac_source Field
**Check:** Verify the new field exists:
- `state/schema.md` contains `ac_source` field definition
- Field type is string, values include "triage-analyst" and "spec-analyst"
**Method:** Grep state/schema.md for ac_source

### TC-9: Cross-File Consistency
**Check:** Verify that mode signals are consistent:
- implement-feature SKILL.md Step 6b, 6d, 6e all use the same mode string "Mode: feature-implementation"
- Fixer, reviewer, test-engineer all check for the same mode string
**Method:** Grep all files for the exact mode signal string

### TC-10: No Destructive Changes
**Check:** Verify no existing process steps were removed:
- `git diff` shows only additions (+) and modifications, no pure deletions of functional content
- Each modified agent file has same or more lines than before
**Method:** `git diff --stat` on each file

## Execution Order

1. Run TC-1 (baseline) BEFORE any edits
2. Apply all edits
3. Run TC-1 through TC-10
4. If any TC fails, identify the failing edit and fix it before proceeding
