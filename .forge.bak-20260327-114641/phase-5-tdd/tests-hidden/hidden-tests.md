# Hidden Test Cases — Scaffold Infrastructure Integration (v5.5.0)

**Visibility:** Phase 8 (verification) only. These tests are NOT shown to the implementer.

**Purpose:** Catch subtle stale references, in-memory variable contract gaps, diagram edge cases,
and test-file omissions that are easy to miss when focused on the primary additions.

**Total hidden test cases:** 8 (H01–H08)

---

### H01: No "jump to Step 10" survives anywhere in scaffold.md
- **Priority:** P0
- **Category:** Internal cross-reference (req 1.11, 1.12)
- **Assertion:** `grep -cn "jump to Step 10" commands/scaffold.md` → expected output: `0`
- **Full command:** `grep -c "jump to Step 10" commands/scaffold.md`
- **Expected:** 0
- **Why hidden:** Implementers reliably update the heading but often leave inline "jump to" references unchanged. Requirements 1.11 and 1.12 call out two specific lines in Step 7 (L443 and L449). Both must be updated. This is the most common partial-implementation defect.

---

### H02: MCP Pre-flight section does NOT reference Step 9 in any form
- **Priority:** P0
- **Category:** Stale cross-reference (req 1.13)
- **Assertion:** `grep -A20 "MCP Pre-flight Check" commands/scaffold.md | grep -c "Step 9"` → expected output: `0`
- **Full command:** `grep -A20 "MCP Pre-flight Check" commands/scaffold.md | grep "Step 9"`
- **Expected:** NO_MATCH (zero lines)
- **Why hidden:** The MCP Pre-flight section (req 1.13) must be completely rewritten to reference Step 0-MCP instead of old Step 9. An implementer who only adds content without removing the old Step 9 reference will pass the visible addition checks but fail here. Formal criterion 6.3 directly specifies this check.

---

### H03: In-memory values block present in Step 0-MCP
- **Priority:** P1
- **Category:** In-memory variable contract (req formal criterion 6.4)
- **Assertion:** `grep -A40 "Step 0-MCP: MCP Verification" commands/scaffold.md | grep -q "Required in-memory values from Step 0-INFRA"` → MATCH
- **Why hidden:** Formal criterion 6.4 requires each consuming step to re-declare its in-memory variable dependencies. Step 0-MCP is the first consumer of 0-INFRA state. Omitting the declaration block means downstream agents have no contract to verify against. Implementers focused on the step content routinely skip the boilerplate declaration.

---

### H04: In-memory values block present in Step 4e
- **Priority:** P1
- **Category:** In-memory variable contract (req formal criterion 6.4)
- **Assertion:** `grep -A40 "Step 4e: Create Tracker Issues" commands/scaffold.md | grep -q "Required in-memory values from Step 0-INFRA"` → MATCH
- **Why hidden:** Companion to H03. Step 4e consumes tracker-type and tracker-ready flags set in 0-INFRA. Without the declaration, the conditional logic ("if TC=ready") has no documented source variable. H04 specifically targets 4e because 4d (Push) is simpler and more likely to get the declaration; 4e involves the more complex tracker branch.

---

### H05: Step 4e has conditional language ("if TC=ready")
- **Priority:** P1
- **Category:** Edge case — Step 4e conditional (req 1.8, formal criterion 5 note)
- **Assertion:** `grep -A30 "Step 4e: Create Tracker Issues" commands/scaffold.md | grep -iq "TC=ready\|if.*tracker.*ready\|tracker.*configured"` → MATCH
- **Why hidden:** Step 4e must be conditional — it only runs when the tracker infrastructure was confirmed ready in Step 0-INFRA. An unconditional implementation would always attempt to create issues even when no tracker is configured, causing pipeline failures in fresh projects. The visible test T11 only checks the heading; this test checks the conditional guard.

---

### H06: No-implement test file has L5b assertion
- **Priority:** P1
- **Category:** Test file assertion gap (req 9.1)
- **Assertion:** `grep -q "L5b" tests/scenarios/scaffold-v2-no-implement.sh` → MATCH
- **Why hidden:** Requirement 9.1 specifies an explicit L5b assertion in the no-implement test scenario. The visible tests check for 0-INFRA presence (T29 in visible set maps to req 9.1 step heading). But L5b is the Push sub-step inside the --no-implement flow, and its assertion is a separate, specific check in formal criterion 7.5. Implementers often add the 0-INFRA assertion and stop, missing the L5b guard.

---

### H07: Happy path test has ordering assertion using INFRA_LINE variable
- **Priority:** P1
- **Category:** Test file ordering assertion (req 8.3, formal criterion 7.3)
- **Assertion:** `grep -q "INFRA_LINE" tests/scenarios/scaffold-v2-happy-path.sh` → MATCH
- **Why hidden:** Formal criterion 7.3 requires the happy-path test to verify that 0-INFRA appears before Mode Selection by extracting line numbers (`INFRA_LINE`, `MODE_LINE`) and asserting `INFRA_LINE < MODE_LINE`. The pattern-based visible tests (T08, T12) check presence and logical ordering in scaffold.md but do NOT check whether the test script itself enforces this order — which is what Phase 8 verification must confirm. This is a test-of-tests check.

---

### H08: pipelines.md scaffold stages table has exactly 14 body rows
- **Priority:** P1
- **Category:** Stage table completeness (formal criterion 4.3)
- **Assertion:**
  ```bash
  awk '/^\| Step \| Stage/,/^$/' docs/reference/pipelines.md \
    | grep "^\|" | grep -v "Step \| Stage" | grep -v "\-\-\-" | wc -l
  ```
  → expected output: `14`
- **Why hidden:** Formal criterion 4.3 explicitly specifies the row count: 14 rows for 0-INFRA, 0-MCP, 0, 1, 2, 3, 4, 4d, 4e, 5, 6, 7, 8, 9. Implementers commonly add the new rows (0-INFRA, 0-MCP, 4d, 4e = +4) but forget to remove the old Step 9: Issue Tracker row (-1) and renumber Step 10 to Step 9 (-0, already covered by a heading update). The net result should be 14, not 15 or 16. An exact count assertion catches this arithmetic error.

---

## Hidden Test Summary

| ID | Defect Class | Formal Criterion Ref |
|----|--------------|----------------------|
| H01 | Stale "jump to Step 10" inline refs | 1.4 (No Step 10 refs), req 1.11/1.12 |
| H02 | Stale Step 9 ref in MCP Pre-flight | 6.3 |
| H03 | Missing in-memory declaration in Step 0-MCP | 6.4 |
| H04 | Missing in-memory declaration in Step 4e | 6.4 |
| H05 | Unconditional Step 4e (no TC=ready guard) | Req 1.8 semantics |
| H06 | Missing L5b assertion in no-implement test | 7.5 |
| H07 | Missing INFRA_LINE ordering assertion in happy-path test | 7.3 |
| H08 | Wrong row count in pipelines.md stages table | 4.3 |
