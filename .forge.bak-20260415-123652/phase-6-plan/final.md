# Phase 6: Implementation Plan

## v6.6.0: Status Verification Wiring + MCP Body Formatting Contract + fix-bugs On-Start-Set

Date: 2026-04-15

---

## Summary Table

| Task | File | Action | Group | Deps | Est. Lines |
|------|------|--------|-------|------|------------|
| T-001 | `core/mcp-body-formatting.md` | create | G0 | -- | 30 |
| T-002 | `agents/publisher.md` | edit (2x) | G1 | T-001 | 4 |
| T-003 | `core/block-handler.md` | edit | G1 | T-001 | 2 |
| T-004 | `skills/fix-ticket/SKILL.md` | edit | G1 | T-001 | 2 |
| T-005 | `core/fix-verification.md` | edit | G1 | -- | 2 |
| T-006 | `skills/scaffold/SKILL.md` | edit | G1 | -- | 4 |
| T-007 | `skills/implement-feature/SKILL.md` | edit (SV) | G1 | -- | 3 |
| T-008 | `skills/implement-feature/SKILL.md` | edit (MCP) | G2 | T-001, T-007 | 2 |
| T-009 | `skills/fix-bugs/SKILL.md` | edit (Step 1a) | G1 | -- | 10 |
| T-010 | `skills/fix-bugs/SKILL.md` | edit (MCP R6) | G2 | T-001, T-009 | 2 |
| T-011 | `skills/fix-bugs/SKILL.md` | edit (MCP R7) | G3 | T-010 | 2 |
| T-012 | `skills/fix-bugs/SKILL.md` | edit (SV block) | G4 | T-011 | 3 |
| T-013 | `skills/fix-bugs/SKILL.md` | edit (worktree) | G5 | T-012 | 1 |
| T-014 | `CLAUDE.md` | edit | G1 | -- | 1 |
| T-015 | `tests/scenarios/mcp-newline-handling.sh` | edit | G6 | T-001..T-013 | 46 |
| T-016 | `docs/plans/roadmap.md` | edit | G7 | T-015 | 1 |

**Total: 16 tasks, 8 groups, 1 new file + 15 edits across 10 existing files.**

---

## Dependency Graph

```
G0:  T-001 (create contract)
       |
       v
G1:  T-002  T-003  T-004  T-005  T-006  T-007  T-009  T-014
       |                            |              |
       v                            v              v
G2:  ------                       T-008          T-010
                                                   |
                                                   v
G3:  ----------------------------------------   T-011
                                                   |
                                                   v
G4:  ----------------------------------------   T-012
                                                   |
                                                   v
G5:  ----------------------------------------   T-013
                                                   |
                                                   v
G6:  T-015 (test update — depends on ALL content tasks)
       |
       v
G7:  T-016 (roadmap — final task)
```

### Textual dependency chains

```
T-001 --> T-002, T-003, T-004, T-008, T-010
T-007 --> T-008                              (same file: implement-feature)
T-009 --> T-010 --> T-011 --> T-012 --> T-013 (same file: fix-bugs, sequential)
T-001..T-014 --> T-015                       (test validates all changes)
T-015 --> T-016                              (roadmap marks DONE after test)
```

---

## Task Details

### T-001: Create MCP body formatting contract
- **File:** `core/mcp-body-formatting.md`
- **Action:** create
- **Description:** Create the new core contract file with exactly 5 sections (Purpose, Applies To, Process, Constraints, Failure Mode) as specified in design Part A. The file contains the centralized NEVER rule for MCP parameter formatting. Use double-dash (`--`) not em-dash. Copy verbatim from the design document's Part A content block.
- **Dependencies:** --
- **Parallel group:** G0
- **Lines changed:** 30
- **Requirements:** REQ-MCP-1, REQ-MCP-2

---

### T-002: Publisher MCP replacements (R1 + R2)
- **File:** `agents/publisher.md`
- **Action:** edit (2 replacements)
- **Description:** Apply Replacement 1 (Step 6 sub-bullet: replace inline NEVER instruction with contract reference) and Replacement 2 (Constraints section: replace 3-sentence explanation with condensed NEVER + contract reference). Use exact old_string/new_string from design Part B, Replacements 1 and 2.
- **Dependencies:** T-001
- **Parallel group:** G1
- **Lines changed:** 4
- **Requirements:** REQ-MCP-3, REQ-MCP-4

---

### T-003: block-handler MCP replacement (R3)
- **File:** `core/block-handler.md`
- **Action:** edit
- **Description:** Apply Replacement 3: replace inline NEVER instruction in Step 4 post-template note with `Follow core/mcp-body-formatting.md when constructing the comment string.` Use exact old_string/new_string from design Part B, Replacement 3.
- **Dependencies:** T-001
- **Parallel group:** G1
- **Lines changed:** 2
- **Requirements:** REQ-MCP-5

---

### T-004: fix-ticket MCP replacement (R4)
- **File:** `skills/fix-ticket/SKILL.md`
- **Action:** edit
- **Description:** Apply Replacement 4: replace inline NEVER instruction in Step 4b-tracker with contract reference. Use exact old_string/new_string from design Part B, Replacement 4.
- **Dependencies:** T-001
- **Parallel group:** G1
- **Lines changed:** 2
- **Requirements:** REQ-MCP-6

---

### T-005: fix-verification status verification wiring (SV-2)
- **File:** `core/fix-verification.md`
- **Action:** edit
- **Description:** Apply SV Insertion 2: in Step 6, insert the status verification reference inline within the conditional re-open clause, after "set the issue state back" and before "Display". Use exact old_string/new_string from design Part C, SV Insertion 2.
- **Dependencies:** --
- **Parallel group:** G1
- **Lines changed:** 2
- **Requirements:** REQ-SV-2

---

### T-006: scaffold status verification wiring (SV-4)
- **File:** `skills/scaffold/SKILL.md`
- **Action:** edit
- **Description:** Apply SV Insertion 4: in Step 8b, add the verification reference after epic transition (3a) and after story transitions (3b). Use "After the status-set MCP call" for 3a and "After each status-set MCP call" for 3b. Use exact old_string/new_string from design Part C, SV Insertion 4.
- **Dependencies:** --
- **Parallel group:** G1
- **Lines changed:** 4
- **Requirements:** REQ-SV-4, REQ-SV-5

---

### T-007: implement-feature status verification wiring (SV-1)
- **File:** `skills/implement-feature/SKILL.md`
- **Action:** edit
- **Description:** Apply SV Insertion 1: insert the verification reference as a standalone paragraph in Step 1, after the state-set instruction and before `### 2. Create branch`. Use exact old_string/new_string from design Part C, SV Insertion 1.
- **Dependencies:** --
- **Parallel group:** G1
- **Lines changed:** 3
- **Requirements:** REQ-SV-1

---

### T-008: implement-feature MCP replacement (R5)
- **File:** `skills/implement-feature/SKILL.md`
- **Action:** edit
- **Description:** Apply Replacement 5: replace inline NEVER instruction in Step 5a with contract reference. Use exact old_string/new_string from design Part B, Replacement 5. Must run after T-007 because both edit the same file.
- **Dependencies:** T-001, T-007
- **Parallel group:** G2
- **Lines changed:** 2
- **Requirements:** REQ-MCP-7

---

### T-009: fix-bugs Step 1a insertion
- **File:** `skills/fix-bugs/SKILL.md`
- **Action:** edit
- **Description:** Insert new Step 1a ("Set issue tracker") between Step 1 (Fetch bugs) and Step 2 (Triage). The step includes: (1) state-set instruction, (2) MCP server selection, (3) status verification reference, (4) dry-run annotation. Use exact old_string/new_string from design Part D, Step 1a Insertion. This is the first edit to fix-bugs/SKILL.md in document order.
- **Dependencies:** --
- **Parallel group:** G1
- **Lines changed:** 10
- **Requirements:** REQ-FB-1, REQ-FB-2, REQ-FB-3

---

### T-010: fix-bugs MCP replacement (R6) -- Step 3b-tracker
- **File:** `skills/fix-bugs/SKILL.md`
- **Action:** edit
- **Description:** Apply Replacement 6: replace inline NEVER instruction in Step 3b-tracker with contract reference. Use exact old_string/new_string from design Part B, Replacement 6. Must run after T-009 (same file, sequential).
- **Dependencies:** T-001, T-009
- **Parallel group:** G2
- **Lines changed:** 2
- **Requirements:** REQ-MCP-8 (part 1)

---

### T-011: fix-bugs MCP replacement (R7) -- block handler Step 4
- **File:** `skills/fix-bugs/SKILL.md`
- **Action:** edit
- **Description:** Apply Replacement 7: replace inline NEVER instruction in the block handler's Step 4 post-template note with contract reference. Use exact old_string/new_string from design Part B, Replacement 7. Must run after T-010 (same file, sequential).
- **Dependencies:** T-010
- **Parallel group:** G3
- **Lines changed:** 2
- **Requirements:** REQ-MCP-8 (part 2)

---

### T-012: fix-bugs status verification wiring (SV-3) -- block handler Step 2
- **File:** `skills/fix-bugs/SKILL.md`
- **Action:** edit
- **Description:** Apply SV Insertion 3: add the verification reference as an indented continuation line after the Step 2 heading ("Set issue state to Blocked") and before Step 3. Use exact old_string/new_string from design Part C, SV Insertion 3. Must run after T-011 (same file, sequential).
- **Dependencies:** T-011
- **Parallel group:** G4
- **Lines changed:** 3
- **Requirements:** REQ-SV-3

---

### T-013: fix-bugs worktree range update
- **File:** `skills/fix-bugs/SKILL.md`
- **Action:** edit
- **Description:** Update the worktree parallel dispatch step range from "steps 2-8" to "steps 1a-8". Use exact old_string/new_string from design Part D, Worktree Range Update. Must run after T-012 (same file, sequential, last edit to this file).
- **Dependencies:** T-012
- **Parallel group:** G5
- **Lines changed:** 1
- **Requirements:** REQ-FB-4

---

### T-014: CLAUDE.md core count update
- **File:** `CLAUDE.md`
- **Action:** edit
- **Description:** Update the core/ description from "12 shared pipeline pattern contracts" to "13 shared pipeline pattern contracts". Use exact old_string/new_string from design Part E.
- **Dependencies:** --
- **Parallel group:** G1
- **Lines changed:** 1
- **Requirements:** REQ-POST-1

---

### T-015: Deploy updated test scenario
- **File:** `tests/scenarios/mcp-newline-handling.sh`
- **Action:** edit (full rewrite)
- **Description:** Overwrite `tests/scenarios/mcp-newline-handling.sh` with the content from `.forge/phase-5-tdd/tests/mcp-newline-handling.sh`. The new test has two checks: (A) contract file exists and contains "NEVER use" marker, (B) all 5 previously-vulnerable files reference `core/mcp-body-formatting.md`. Preserves T-013 tag. Must run after ALL content tasks (T-001 through T-014) because it validates them.
- **Dependencies:** T-001, T-002, T-003, T-004, T-005, T-006, T-007, T-008, T-009, T-010, T-011, T-012, T-013, T-014
- **Parallel group:** G6
- **Lines changed:** 46
- **Requirements:** REQ-MCP-10

---

### T-016: Roadmap update -- mark v6.6.0 DONE
- **File:** `docs/plans/roadmap.md`
- **Action:** edit
- **Description:** Change `## PLANNED -- v6.6.0` heading to `## DONE -- v6.6.0` (per roadmap conventions). This is the final task, executed only after all changes are applied and validated.
- **Dependencies:** T-015
- **Parallel group:** G7
- **Lines changed:** 1
- **Requirements:** REQ-POST-2

---

## Execution Groups

### G0 -- Foundation (1 task)
Create the new core contract file. Everything downstream depends on this.
- T-001: `core/mcp-body-formatting.md` (create)

### G1 -- Parallel edits to independent files + first fix-bugs edit (8 tasks)
All tasks in this group edit different files (or are the first edit to a shared file). Can execute in full parallel.
- T-002: `agents/publisher.md` (MCP R1 + R2)
- T-003: `core/block-handler.md` (MCP R3)
- T-004: `skills/fix-ticket/SKILL.md` (MCP R4)
- T-005: `core/fix-verification.md` (SV-2)
- T-006: `skills/scaffold/SKILL.md` (SV-4)
- T-007: `skills/implement-feature/SKILL.md` (SV-1)
- T-009: `skills/fix-bugs/SKILL.md` (Step 1a insertion)
- T-014: `CLAUDE.md` (core count)

### G2 -- Second edits to shared files (2 tasks)
Second edit to `implement-feature` and `fix-bugs` -- both depend on their G1 predecessor for the same file.
- T-008: `skills/implement-feature/SKILL.md` (MCP R5) -- after T-007
- T-010: `skills/fix-bugs/SKILL.md` (MCP R6) -- after T-009

### G3 -- Third fix-bugs edit (1 task)
- T-011: `skills/fix-bugs/SKILL.md` (MCP R7) -- after T-010

### G4 -- Fourth fix-bugs edit (1 task)
- T-012: `skills/fix-bugs/SKILL.md` (SV block handler) -- after T-011

### G5 -- Fifth fix-bugs edit (1 task)
- T-013: `skills/fix-bugs/SKILL.md` (worktree range) -- after T-012

### G6 -- Test deployment (1 task)
Overwrite the test scenario. Validates all preceding changes.
- T-015: `tests/scenarios/mcp-newline-handling.sh`

### G7 -- Roadmap finalization (1 task)
Mark v6.6.0 as DONE. Final task in the pipeline.
- T-016: `docs/plans/roadmap.md`

---

## Critical Path

```
T-001 -> T-009 -> T-010 -> T-011 -> T-012 -> T-013 -> T-015 -> T-016
```

The critical path runs through `skills/fix-bugs/SKILL.md` due to its 5 sequential edits. All other file edits complete within G1-G2 and do not extend the critical path.

---

## Validation Checklist (post-execution)

After all tasks complete, run these verification commands:

| Check | Command | Expected |
|-------|---------|----------|
| Contract exists | `test -f core/mcp-body-formatting.md` | exit 0 |
| Contract NEVER rule | `grep -q "NEVER use" core/mcp-body-formatting.md` | exit 0 |
| SV in implement-feature | `grep -q "status-verification.md" skills/implement-feature/SKILL.md` | exit 0 |
| SV in fix-verification | `grep -q "status-verification.md" core/fix-verification.md` | exit 0 |
| SV in fix-bugs | `grep -q "status-verification.md" skills/fix-bugs/SKILL.md` | exit 0 |
| SV in scaffold (2x) | `grep -c "status-verification.md" skills/scaffold/SKILL.md` | >= 2 |
| MCP ref in publisher | `grep -q "core/mcp-body-formatting.md" agents/publisher.md` | exit 0 |
| MCP ref in block-handler | `grep -q "core/mcp-body-formatting.md" core/block-handler.md` | exit 0 |
| MCP ref in fix-ticket | `grep -q "core/mcp-body-formatting.md" skills/fix-ticket/SKILL.md` | exit 0 |
| MCP ref in implement-feature | `grep -q "core/mcp-body-formatting.md" skills/implement-feature/SKILL.md` | exit 0 |
| MCP ref in fix-bugs | `grep -q "core/mcp-body-formatting.md" skills/fix-bugs/SKILL.md` | exit 0 |
| No old inline NEVER | `grep -r "NEVER use the literal characters" agents/ core/ skills/` | no matches |
| Step 1a exists | `grep -q "### 1a. Set issue tracker" skills/fix-bugs/SKILL.md` | exit 0 |
| Worktree range updated | `grep -q "steps 1a" skills/fix-bugs/SKILL.md` | exit 0 |
| Core count = 13 | `grep -q "13 shared pipeline pattern contracts" CLAUDE.md` | exit 0 |
| Roadmap DONE | `grep -q "DONE.*v6.6.0" docs/plans/roadmap.md` | exit 0 |
| Full test suite | `./tests/harness/run-tests.sh` | exit 0 |
