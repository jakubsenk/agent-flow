# Phase 6 — Implementation Plan

## Persona

You are a senior developer creating a step-by-step implementation plan for the v6.3.3 patch. The plan must be executable by a single agent in sequence (no parallelization needed for this small patch).

## Task Instructions

Create an ordered task list with dependencies. Each task specifies the exact file, the exact location within the file, and the exact change.

### Task 1: Strengthen scaffold Step 3 validation
**File:** `skills/scaffold/SKILL.md`
**Location:** Step 3 (around line 440-464)
**Change:** Expand the one-line "Validation: build + test + lint + CLAUDE.md check (max 3 retries)" into an explicit procedure:
1. After scaffolder agent completes, read Build command and Test command from generated CLAUDE.md (in $SCAFFOLD_TEMP)
2. Run Build command. If fails → pass error to scaffolder, scaffolder fixes, retry.
3. Run Test command. If fails → pass error to scaffolder, scaffolder fixes, retry.
4. Run lint check (if configured).
5. Run CLAUDE.md structure check.
6. Max 3 total retries. If exhausted → delete temp, report, STOP.

**Pattern reference:** The legacy flow L3 (lines 279-298) has a similar structure. Match its style but add explicit command execution.

### Task 2: Make scaffolder scorecard items hard requirements
**File:** `agents/scaffolder.md`
**Location:** Step 4b header (around line 149) and Constraints section (around line 193+)
**Changes:**
- Step 4b: Change "informational — does NOT block" to indicate Build and Tests are hard gates
- Constraints: Existing constraint "Generated skeleton MUST build, MUST pass tests, MUST pass linter" (line ~200) already exists. Strengthen by making the scorecard's Build and Tests items explicitly blocking: if FAIL, the scaffolder MUST fix before reporting.

### Task 3: Add smoke check to fix-ticket
**File:** `skills/fix-ticket/SKILL.md`
**Location:** Between step 7 (Reviewer) and step 8 (Test-engineer)
**Change:** Insert new step "7a. Smoke check" (or renumber appropriately):
- Run Build command from Automation Config
- Run Test command from Automation Config
- If either fails → proceed to Block handler (step X) with agent "smoke-check", step "post-review smoke check"
- Update state.json: no new fields needed (failure goes through block handler)

**Step renumbering:** Current step 8 (Test-engineer) stays at 8. Insert 7a between 7 and 8. No renumbering of existing steps needed since 7a uses letter suffix.

### Task 4: Add smoke check to fix-bugs
**File:** `skills/fix-bugs/SKILL.md`
**Location:** Between step 6 (Reviewer) and step 7 (Test-engineer)
**Change:** Insert new step "6a. Smoke check" with identical logic to fix-ticket's 7a.

**Step renumbering:** Current step 7 (Test-engineer) stays at 7. Insert 6a between 6 and 7.

### Task 5: Version bump + changelog
**Files:** `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `CHANGELOG.md`
**Changes:**
- plugin.json: "version": "6.3.2" → "6.3.3"
- marketplace.json: version "6.3.2" → "6.3.3"
- CHANGELOG.md: Add v6.3.3 entry at the top (after header, before v6.3.2)

### Task 6: Roadmap update
**File:** `docs/plans/roadmap.md`
**Change:** Add v6.3.3 items (scaffold validation, scaffolder hard requirements, smoke check)

### Task 7: Run tests
**Command:** `./tests/harness/run-tests.sh`
**Gate:** All existing tests must pass

## Dependency Graph

```
Task 1 ──┐
Task 2 ──┤
Task 3 ──┼── Task 5 (version bump) ── Task 6 (roadmap) ── Task 7 (tests)
Task 4 ──┘
```

Tasks 1-4 are independent. Task 5 depends on 1-4 (changelog references all changes). Task 7 depends on all.

## Success Criteria

- All 7 tasks completed
- No step renumbering conflicts
- CHANGELOG entry accurately describes all three changes
- All existing tests pass after changes

## Anti-Patterns

- Do NOT change step numbers of existing steps (use letter suffixes)
- Do NOT add new config keys
- Do NOT modify core/*.md contracts
- Do NOT add new state.json fields

## Codebase Context

- fix-ticket step numbering: 0, 0b, 1-9 with sub-steps using letters (4a, 4b, 6a, 8a-deploy, etc.)
- fix-bugs step numbering: 0, 1-9 with sub-steps (3a, 3b, 5a, 7a-deploy, etc.)
- Scaffold step numbering: 0-INFRA, 0-MCP, 0-9 with sub-steps
- CHANGELOG format: Keep a Changelog style with [version] — date header
