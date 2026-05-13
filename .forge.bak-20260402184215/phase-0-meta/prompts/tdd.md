# Phase 5 — TDD (Test Definitions)

You are writing test scenarios for the two bug fixes in `skills/scaffold/SKILL.md`. This is a pure markdown codebase — tests are scenario-based assertions checked by the test harness in `tests/`.

## Test Strategy

Read the test harness at `tests/harness/` to understand the testing format. Tests in this codebase validate that skill and agent markdown definitions contain required sections, patterns, and behavioral instructions.

## Test Scenarios

### Test Group: scaffold-step-4e-stories

**Scenario 1: Step 4e contains story sub-issue creation instruction**

- **Assert:** `skills/scaffold/SKILL.md` contains text instructing creation of sub-issues for user stories
- **Pattern to check:** The Step 4e section contains an instruction to parse `### Story` headings from epic files and create a sub-issue for each story
- **Expected:** PASS after fix

**Scenario 2: Step 4e specifies story back-reference format**

- **Assert:** `skills/scaffold/SKILL.md` Step 4e section specifies that each created story sub-issue ID is written back into the spec file
- **Pattern to check:** The section contains guidance for writing a back-reference comment at the story heading level (not just the epic level)
- **Expected:** PASS after fix

**Scenario 3: Step 4e specifies sub-issue title format**

- **Assert:** `skills/scaffold/SKILL.md` Step 4e section specifies the title format for story sub-issues
- **Pattern to check:** Contains text describing story sub-issue title format
- **Expected:** PASS after fix

**Scenario 4: Step 4e specifies story failure handling**

- **Assert:** `skills/scaffold/SKILL.md` Step 4e section has per-story failure handling (accumulator pattern)
- **Pattern to check:** Contains WARN-level failure handling for individual story creation failures
- **Expected:** PASS after fix

### Test Group: scaffold-step-7e-tracker-close

**Scenario 5: Scaffold pipeline has a step to transition tracker issues to Done**

- **Assert:** `skills/scaffold/SKILL.md` contains a step (after implementation loop) that transitions tracker issues to Done
- **Pattern to check:** A step labeled "7e" or similar that references state transitions and "Done"
- **Expected:** PASS after fix

**Scenario 6: Tracker close step has guard clause**

- **Assert:** The tracker close step is conditional on `tracker_effective_status == "ready"`
- **Pattern to check:** Contains guard clause matching Step 4e's guard pattern
- **Expected:** PASS after fix

**Scenario 7: Tracker close step handles partial completion**

- **Assert:** The tracker close step only closes stories that were successfully implemented (not blocked/skipped)
- **Pattern to check:** Contains conditional logic for blocked/skipped stories
- **Expected:** PASS after fix

**Scenario 8: Tracker close step closes epics only when all stories are done**

- **Assert:** The tracker close step transitions epic issues to Done only when all their child stories are Done
- **Pattern to check:** Contains logic for checking all-stories-complete before closing epic
- **Expected:** PASS after fix

### Test Group: scaffold-no-regression

**Scenario 9: Step 4e still creates epic-level issues**

- **Assert:** The existing epic creation logic in Step 4e is preserved
- **Pattern to check:** Step 4e still contains "Create an epic-level issue in the tracker project"
- **Expected:** PASS (regression guard)

**Scenario 10: Step 4e partial failure handling still works**

- **Assert:** The accumulator pattern for epic failures is preserved
- **Pattern to check:** Step 4e still contains "On individual epic failure: log the failure"
- **Expected:** PASS (regression guard)

## Implementation Notes

These test scenarios should be added to the existing test suite at `tests/scenarios/` following the established format. Read existing test files to match the exact assertion format used by the harness.
