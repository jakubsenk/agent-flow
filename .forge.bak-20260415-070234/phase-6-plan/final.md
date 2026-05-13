# Phase 6 — Implementation Plan

## Task Dependency Graph

```
task-001 ──┐
task-002 ──┤
task-003 ──┼──→ task-006 (install tests + run suite)
task-004 ──┤
task-005 ──┘
```

All implementation tasks (001–005) are fully independent and can run in parallel. Task 006 must run after all five complete.

## Tasks

### task-001: Fix scaffolder step numbering

- **File:** `agents/scaffolder.md`
- **AC:** AC-1
- **Changes:**
  - Line 149: rename `4b. Generate quality scorecard:` to `5. Generate quality scorecard:`
  - Line 150: change leading indent from 4-space (`    Items`) to 3-space (`   Items`) to match numbered-step convention
  - Line 165: rename `5. Output:` to `6. Output:`
- **Lines to change:** 149, 150, 165
- **Dependencies:** none
- **Parallelizable:** yes

### task-002: Add contributor note in fix-bugs

- **File:** `skills/fix-bugs/SKILL.md`
- **AC:** AC-2
- **Changes:** Insert one HTML comment line immediately before line 89 (before "For each issue fetched in step 1:"). The comment explains that the 16 occurrences of "Follow atomic write protocol from core/state-manager.md" are intentional LLM-directed repetition and must not be consolidated.
- **Exact insertion (before current line 89):**
  ```
  <!-- Contributor note: "Follow atomic write protocol from core/state-manager.md" appears at each state.json write step intentionally. This is LLM-directed repetition for reliable per-step compliance — not accidental duplication. Do not consolidate. -->
  ```
- **Lines to change:** insert before line 89
- **Dependencies:** none
- **Parallelizable:** yes

### task-003: Add token constraints to triage-analyst

- **File:** `agents/triage-analyst.md`
- **AC:** AC-3
- **Changes:** Insert two MUST constraint lines in the `## Constraints` section after line 111 ("MUST store downloaded attachments...") and before line 112 ("If issue tracker MCP server is unreachable...").
- **Lines to insert (after current line 111):**
  ```
  - MUST use exactly `PASS` or `UNCLEAR` as the Quality gate value. No variations (not "incomplete", "insufficient", "fail", or other synonyms).
  - MUST output Reproduction steps as a JSON array literal (e.g., `[{action: "navigate", target: "/"}]`), not as prose or numbered list. Omit the field entirely if not UI-related.
  ```
- **Lines to change:** insert after line 111
- **Dependencies:** none
- **Parallelizable:** yes

### task-004: Add token constraints to code-analyst

- **File:** `agents/code-analyst.md`
- **AC:** AC-4
- **Changes:** Insert two MUST constraint lines in the `## Constraints` section after line 106 ("Risk level criteria: LOW = ...") and before line 107 ("If codebase is too large to fully explore...").
- **Lines to insert (after current line 106):**
  ```
  - MUST use exactly `YES` or `NO` as the `root cause confirmed` value. No variations (not "confirmed", "unconfirmed", "partial", or other synonyms).
  - MUST use exactly one of `LOW`, `MEDIUM`, `HIGH` as the Risk level value. No variations.
  ```
- **Lines to change:** insert after line 106
- **Dependencies:** none
- **Parallelizable:** yes

### task-005: Add token constraints to fixer and reviewer

- **Files:** `agents/fixer.md`, `agents/reviewer.md`
- **AC:** AC-5
- **Changes (fixer):** Insert one MUST constraint line after line 82 ("NEVER signal NEEDS_DECOMPOSITION to avoid a hard problem...") and before line 83 ("NEVER change more than necessary...").
  ```
  - MUST use the exact string `NEEDS_DECOMPOSITION` when signaling decomposition need. No variations (not "NEEDS DECOMPOSITION", "needs_decomposition", "decomposition needed", or other forms).
  ```
- **Changes (reviewer):** Insert two MUST constraint lines after line 110 ("Verdict = BLOCK only for...") and before line 111 ("If acceptance criteria were provided in context...").
  ```
  - MUST use exactly one of: `APPROVE`, `REQUEST_CHANGES`, `BLOCK` as the Verdict value. No variations, no additional qualifiers (not "APPROVED", "CHANGES_REQUESTED", "BLOCKED", or other forms).
  - MUST use exactly one of: `FULFILLED`, `PARTIALLY`, `NOT ADDRESSED` for each AC fulfillment verdict. No variations.
  ```
- **Lines to change:** fixer: insert after line 82; reviewer: insert after line 110
- **Dependencies:** none
- **Parallelizable:** yes

### task-006: Install and run tests

- **Action:**
  1. Copy test files from `.forge/phase-5-tdd/tests/` to `tests/scenarios/`:
     - `ac1-scaffolder-step-numbering.sh`
     - `ac2-fixbugs-contributor-note.sh`
     - `ac3-triage-token-constraints.sh`
     - `ac4-codeanalyst-token-constraints.sh`
     - `ac5-fixer-reviewer-token-constraints.sh`
  2. Make all copied files executable (`chmod +x`)
  3. Run full test suite: `./tests/harness/run-tests.sh`
  4. Verify all tests pass (0 failures), including both existing and new tests
- **AC:** AC-6, AC-7
- **Dependencies:** task-001, task-002, task-003, task-004, task-005
- **Parallelizable:** no (must run after all implementation tasks complete)

## Execution Strategy

All implementation tasks (001–005) can run in parallel since they touch different files (task-005 touches two files, but neither overlaps with any other task). Task 006 (test installation and verification) runs sequentially after all five implementation tasks complete.

**Recommended execution:**
1. **Baseline:** Run existing test suite before any changes to establish green baseline.
2. **Parallel batch:** Execute tasks 001–005 simultaneously.
3. **Verification:** Execute task 006 — install new tests, run full suite, confirm all pass.

## Risk Mitigation

- Run existing test suite BEFORE making changes (baseline — confirms no pre-existing failures).
- Each task modifies only lines explicitly identified in the design spec; no surrounding content is altered.
- All agent frontmatter (name, description, model, style) and section structure (Goal, Expertise, Process, Constraints) must remain untouched — only the Constraints section body gets additions (AC-7).
- All 16 occurrences of "Follow atomic write protocol from core/state-manager.md" in fix-bugs/SKILL.md must remain intact after task-002 (AC-2 negative check).
- Run full test suite AFTER all changes (regression check — AC-6).
