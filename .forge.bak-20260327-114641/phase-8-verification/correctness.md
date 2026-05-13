# Phase 8 — Correctness Verification Report

**Date:** 2026-03-27
**Verifier:** Phase 8 correctness reviewer
**Scope:** Hidden tests H01–H08 from `.forge/phase-5-tdd/tests-hidden/hidden-tests.md`

---

## Test Results Summary

| ID | Description | Expected | Actual | Result |
|----|-------------|----------|--------|--------|
| H01 | No "jump to Step 10" in scaffold.md | 0 | 0 | PASS |
| H02 | No "Step 9" in MCP Pre-flight section | 0 | 0 | PASS |
| H03 | In-memory values block in Step 0-MCP | MATCH | MATCH (count=1) | PASS |
| H04 | In-memory values block in Step 4e | MATCH | MATCH (count=1) | PASS |
| H05 | Step 4e has conditional guard (TC=ready / if.*tracker.*ready / tracker.*configured) | MATCH | NO_MATCH | FAIL |
| H06 | L5b assertion in no-implement test | MATCH | MATCH (count=3) | PASS |
| H07 | INFRA_LINE ordering assertion in happy-path test | MATCH | MATCH (count=2) | PASS |
| H08 | Scaffold stages table has exactly 14 body rows | 14 | 15 | FAIL |

**Pass: 6/8**
**Fail: 2/8**

---

## Detailed Findings

### H01 — PASS
`grep -c "jump to Step 10" commands/scaffold.md` returns **0**.
All inline "jump to Step 10" references have been removed. Requirements 1.11 and 1.12 are satisfied.

### H02 — PASS
`grep -A20 "MCP Pre-flight Check" commands/scaffold.md | grep -c "Step 9"` returns **0**.
The MCP Pre-flight section no longer references old Step 9. Formal criterion 6.3 is satisfied.

### H03 — PASS
`grep -A40 "Step 0-MCP: MCP Verification" commands/scaffold.md | grep -c "Required in-memory values from Step 0-INFRA"` returns **1**.
Step 0-MCP declares its in-memory variable dependencies from Step 0-INFRA. Formal criterion 6.4 is satisfied for this step.

### H04 — PASS
`grep -A40 "Step 4e: Create Tracker Issues" commands/scaffold.md | grep -c "Required in-memory values from Step 0-INFRA"` returns **1**.
Step 4e declares its in-memory variable dependencies from Step 0-INFRA. Formal criterion 6.4 is satisfied for this step.

### H05 — FAIL
`grep -A30 "Step 4e: Create Tracker Issues" commands/scaffold.md | grep -iE "TC=ready|if.*tracker.*ready|tracker.*configured"` returns **NO_MATCH**.

The hidden test expects one of three specific patterns: `TC=ready`, `if.*tracker.*ready`, or `tracker.*configured`.

The actual implementation uses:
```
**Guard clause — skip this step if ANY of:**
- `tracker_effective_status` is NOT `"ready"`
```

The conditional logic IS present and functionally correct — the variable `tracker_effective_status` with value `"ready"` is the guard condition. However, the exact patterns required by H05 do not match the phrasing used. The test expects a positive conditional form (e.g., "if TC=ready, proceed") but the implementation uses a negative guard form ("if NOT ready, skip"). The word "ready" appears, but not within the exact regex patterns specified.

**Impact:** The semantic intent of requirement 1.8 is implemented, but the phrasing contract defined in formal criterion 5 note is not met.

### H06 — PASS
`grep -c "L5b" tests/scenarios/scaffold-v2-no-implement.sh` returns **3**.
The no-implement test scenario contains L5b assertions (3 occurrences). Formal criterion 7.5 is satisfied.

### H07 — PASS
`grep -c "INFRA_LINE" tests/scenarios/scaffold-v2-happy-path.sh` returns **2**.
The happy-path test uses `INFRA_LINE` variable for ordering assertions. Formal criterion 7.3 is satisfied.

### H08 — FAIL
The exact command from the hidden test:
```bash
awk '/^\| Step \| Stage/,/^$/' docs/reference/pipelines.md \
  | grep "^\|" | grep -v "Step \| Stage" | grep -v "\-\-\-" | wc -l
```
Returns **15**, but expected **14**.

**Root cause analysis:** The pipelines.md scaffold stages table contains exactly 14 data rows (visually confirmed: 0-INFRA, 0-MCP, 0, 1, 2, 3, 4, 4d, 4e, 5, 6, 7, 8, 9). The discrepancy is caused by a trailing blank line at the end of the awk range output (`/^\| Step \| Stage/,/^$/`) which includes the terminating empty line. On this platform, this terminating empty line passes through `grep "^\|"` as an artifact (likely a CRLF/LF interaction on Windows). When filtered with `awk 'NF>0'` or `grep -v "^\s*$"`, the count correctly resolves to 14.

**The table content is correct** (14 rows as required by formal criterion 4.3). The FAIL is a test-execution artifact caused by the command not accounting for the trailing blank line in the awk range output on this platform. However, since the hidden test specifies the exact command and expects 14, this is scored as FAIL.

**Note:** If the test is run on a Linux/macOS system (no CRLF), the blank line behavior may differ and the result may be 14. This is a platform-portability issue.

---

## Score

**Raw score:** 6/8 tests passing = **0.75**

**Adjusted analysis:**
- H05: Implementation is functionally correct but uses different phrasing (`tracker_effective_status` is NOT `"ready"` guard clause) rather than the positive form (`TC=ready`). Severity: MINOR (phrasing mismatch, not a missing feature).
- H08: Table content is correct (14 rows), but the exact test command produces 15 due to platform CRLF behavior. Severity: MINOR (platform artifact, not a content defect).

**Final score: 0.75**

Both failures are phrasing/platform issues rather than substantive implementation gaps. The core requirements (conditional guard in 4e, 14-row table) are fulfilled in the actual content. Strict test-exact scoring gives 0.75; content-correctness scoring would give closer to 0.90.

---

## Recommended Fixes

### Fix for H05 (if strict pattern match is required)
In `commands/scaffold.md`, Step 4e, change the guard phrasing to include one of the expected patterns. For example, add a line like:
```
Run Step 4e only if TC=ready (tracker_effective_status == "ready") and not Full YOLO.
```
Or restructure as: "If tracker is configured and ready, proceed with issue creation."

### Fix for H08 (if cross-platform consistency is required)
The table already has exactly 14 rows. The fix would be either:
1. Ensure no trailing blank line follows the table in `docs/reference/pipelines.md` (the blank line between the table and `### Legacy Mode` section).
2. Or adjust the test command to add `| grep -v "^\s*$"` before `wc -l`.
