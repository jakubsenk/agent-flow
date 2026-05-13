# Phase 8 — Verify

You are verifying the implementation of two bug fixes in `skills/scaffold/SKILL.md`.

## Verification Dimensions

### 1. Correctness (weight: 0.3)

**Check 1.1: Step 4e creates story sub-issues**
- Read `skills/scaffold/SKILL.md` Step 4e
- Verify it contains explicit instructions to parse `### Story` headings
- Verify it instructs creating sub-issues for each story (not just epics)
- Verify it writes story-level back-references into spec files
- Verify the sub-issue title format is specified

**Check 1.2: Step 7e transitions issues to Done**
- Read `skills/scaffold/SKILL.md` Step 7e
- Verify it reads tracker issue IDs from spec/epics/ back-references
- Verify it transitions implemented stories to Done
- Verify it only closes epics when ALL stories are Done
- Verify it uses the correct state transition syntax per tracker type

**Check 1.3: Guard clauses present**
- Verify Step 7e has a guard clause for `tracker_effective_status != "ready"`
- Verify Step 7e skips when no tracker issues exist

### 2. Spec Alignment (weight: 0.2)

**Check 2.1: REQ-1 satisfied**
- All 5 acceptance criteria from REQ-1 (story sub-issue creation) are addressed in the code

**Check 2.2: REQ-2 satisfied**
- All 5 acceptance criteria from REQ-2 (tracker state transition) are addressed in the code

**Check 2.3: REQ-3 satisfied (backward compatibility)**
- `--no-implement` legacy flow is unchanged
- `tracker_effective_status = "later"` path is unchanged
- Existing epic creation behavior is preserved

### 3. Robustness (weight: 0.2)

**Check 3.1: Failure handling**
- Step 4e has per-story failure handling (WARN + continue)
- Step 7e has per-issue failure handling (WARN + continue)
- Neither step blocks the pipeline on individual failures

**Check 3.2: Edge cases**
- Epic with zero stories (possible if spec-writer creates an epic without stories)
- Tracker that doesn't support sub-issues (fallback behavior)
- All subtasks blocked (Step 7e should not close any issues)
- Step 4e was skipped (Step 7e guard clause handles this)

### 4. Security (weight: 0.3)

**Check 4.1: No secrets exposed**
- No hardcoded URLs, tokens, or credentials in the changes
- No new environment variable references

**Check 4.2: No destructive operations**
- No `git reset --hard`, `rm -rf`, or other destructive commands added
- State transitions are additive (moving to Done), not destructive

## Test Verification

Run the test harness:
```bash
cd C:/gitea_ceos-agents && ./tests/harness/run-tests.sh
```

Verify:
1. All existing tests pass (no regressions)
2. New test scenarios (if added) pass
3. No warnings about missing sections or malformed steps

## Manual Review Checklist

- [ ] Step numbering is consistent (4e sub-steps use correct lettering, 7e is between 7 and 7b)
- [ ] Markdown formatting is correct (headings, code blocks, lists)
- [ ] No duplicate step numbers
- [ ] In-memory variable references match Step 0-INFRA definitions
- [ ] State transition syntax references `docs/reference/trackers.md` correctly
- [ ] The Final Report (Step 9) is still coherent with the new step

## Verdict Criteria

- **PASS:** All checks pass, tests green, no regressions
- **PASS WITH WARNINGS:** Minor issues (formatting, wording) that don't affect behavior
- **FAIL:** Any correctness check fails, or tests break, or backward compatibility violated
