# Phase 8: Verify

## Objective
Run the full test harness and verify that all changes are backward compatible. Review every changed file for correctness.

## Verification Steps

### Step 1: Run Full Test Suite
```bash
./tests/harness/run-tests.sh
```
Expected: ALL PASS (55+ scenarios)

If any test fails:
1. Read the failing test scenario to understand what it checks
2. Determine if the failure is caused by Phase 7 changes or was pre-existing
3. If caused by changes: fix the issue (either in the changed file or in the test)
4. Re-run the failing test
5. Re-run full suite to confirm no cascading failures

### Step 2: Review Changed Agent Files
For each modified agent file:
1. Read the full file
2. Verify frontmatter is intact
3. Verify section order: Goal -> Expertise -> Process -> Constraints
4. Verify process steps are numbered
5. Verify constraints start with NEVER or define hard limits
6. Verify the description is concise and accurate

### Step 3: Review Changed Core Contracts
For each modified core contract:
1. Read the full file
2. Verify input/output contracts are complete
3. Verify all field references match state schema
4. Verify cross-references to other core contracts are valid

### Step 4: Review Changed State Schema
If state/schema.md was modified:
1. Read the full file
2. Verify JSON example is valid
3. Verify all new fields have defaults
4. Verify new fields are documented in the table

### Step 5: Cross-Pipeline Verification
Verify each pipeline skill still correctly references all its agents:
1. Read `skills/fix-ticket/SKILL.md` — verify all agent dispatch names match `agents/` filenames
2. Read `skills/implement-feature/SKILL.md` — same check
3. Read `skills/scaffold/SKILL.md` — same check
4. Read `skills/fix-bugs/SKILL.md` — same check

### Step 6: Version Impact Assessment
Based on all changes made, determine the version impact:
- Only agent content changes (no contract changes) = PATCH
- New optional fields in state schema = MINOR
- Any changes to Automation Config contract = MAJOR (should not happen per constraints)

## Output
```
## Verification Report

### Test Suite
- Total: {N} scenarios
- Pass: {N}
- Fail: {N}
- Skip: {N}

### Changed Files Review
- {file}: {OK / ISSUE: description}

### Cross-Pipeline Check
- fix-ticket: {OK / ISSUE}
- fix-bugs: {OK / ISSUE}
- implement-feature: {OK / ISSUE}
- scaffold: {OK / ISSUE}

### Version Impact
- Recommended: {PATCH / MINOR}
- Reason: {description}

### Verdict
- {PASS / FAIL}
- {If FAIL: what needs to be fixed}
```
