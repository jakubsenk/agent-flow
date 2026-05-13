# Phase 6: Implementation Plan

## Task: v6.3.2 Verification Follow-ups (Single Task)

### task-001: Implement all three patch fixes

**Type:** bugfix
**Parallelizable:** false (single task)
**Files to modify:**
1. `agents/triage-analyst.md` — Add explicit UNCLEAR token to quality gate output
2. `agents/scaffolder.md` — Add Java/.NET/Go Playwright detection to Batch 7
3. `skills/analyze-bug/SKILL.md` — Verify UNCLEAR handling references correct token
4. `skills/fix-bugs/SKILL.md` — Align UNCLEAR block comment to Block Comment Template
5. `skills/fix-ticket/SKILL.md` — Align UNCLEAR block comment to Block Comment Template
6. `tests/scenarios/scaffolder-e2e-batch.sh` — Replace grep -A5 with sed, add Java/.NET/Go assertions

**Implementation Order:**

#### Step 1: UNCLEAR Signal Contract (Fix 1)

1a. **agents/triage-analyst.md** — In Process step 4 (Issue Quality Gate), change "Quality gate: incomplete" to "Quality gate: UNCLEAR" in the quality gate output section. This establishes the machine-readable token contract.

1b. **skills/analyze-bug/SKILL.md** — Step 3a already handles UNCLEAR correctly. Verify the trigger condition explicitly references "Quality gate: UNCLEAR" from triage-analyst output. Ensure block comment format fields match Block Comment Template.

1c. **skills/fix-bugs/SKILL.md** — In the triage step (~line 108), expand the "Unclear" bullet to include full Block Comment Template with Agent/Step/Reason/Detail/Recommendation fields, matching analyze-bug exactly.

1d. **skills/fix-ticket/SKILL.md** — In step 3 triage (~line 132), expand the "Unclear" bullet to include full Block Comment Template, identical to fix-bugs.

#### Step 2: Playwright Java/.NET/Go (Fix 2)

2a. **agents/scaffolder.md** — In the "Cross-stack Playwright detection" section, add after "If none match → skip this batch":
- **Java:** `pom.xml` or `build.gradle` contains `com.microsoft.playwright`
- **.NET:** `*.csproj` contains `Microsoft.Playwright`
- **Go:** `go.mod` contains `playwright-go`

2b. **agents/scaffolder.md** — After the "For Ruby stacks" section, add three new generation sections following the same structure:
- "For Java stacks (detected via `com.microsoft.playwright`)" with SmokeTest.java
- "For .NET stacks (detected via `Microsoft.Playwright`)" with SmokeTest.cs
- "For Go stacks (detected via `playwright-go`)" with smoke_test.go

2c. **tests/scenarios/scaffolder-e2e-batch.sh** — Add assertions for the three new detections and test file references.

#### Step 3: Test grep Tolerance (Fix 3)

3a. **tests/scenarios/scaffolder-e2e-batch.sh** — Replace `grep -A5 "Batch 7" "$SCAFFOLDER" | grep -q "Skip this batch entirely"` with `sed -n '/Batch 7/,/Batch 8/p' "$SCAFFOLDER" | grep -q "Skip this batch entirely"`.

3b. **tests/scenarios/scaffolder-e2e-batch.sh** — Replace the global `grep -q "smoke" "$SCAFFOLDER"` with Batch-7-specific `sed -n '/Batch 7/,/Batch 8/p' "$SCAFFOLDER" | grep -q "smoke"`.

#### Step 4: Validation

4a. Run `./tests/harness/run-tests.sh` to verify all tests pass.

### Success Criteria
1. `Quality gate: UNCLEAR` token in triage-analyst.md output
2. Identical Block Comment Template in all three consuming skills
3. Java/Go/.NET Playwright detection in scaffolder.md
4. Java/Go/.NET test file generation in scaffolder.md
5. sed range extraction in test script (no grep -A5)
6. Batch-7-scoped smoke assertion in test script
7. All tests pass

### Dependencies
- None (single task, no dependencies)
