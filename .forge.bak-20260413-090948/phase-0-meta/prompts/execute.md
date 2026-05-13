# Phase 7 — Execute

## Context

You are implementing the feature pipeline agent audit. The plan (Phase 6) defines the exact edit sequence. The specification (Phase 4) defines every edit. The TDD criteria (Phase 5) define validation checks.

## Critical Rules

1. **ADDITIVE ONLY:** Every edit MUST be additive. Never remove or replace existing bug-fix pipeline text. Add mode-branches alongside existing text.
2. **PRESERVE STRUCTURE:** Maintain exact agent definition format (frontmatter + Goal + Expertise + Process + Constraints). Maintain exact core contract format (Purpose + Input Contract + Process + Output Contract + Failure Handling).
3. **NO NEW FILES:** Edit only the 10 specified files. Do not create new files.
4. **TEST BEFORE AND AFTER:** Run `tests/harness/run-tests.sh` before starting and after completing all edits.

## Pre-Implementation Baseline

```bash
cd C:/gitea_ceos-agents && ./tests/harness/run-tests.sh
```

Record the baseline result. If any tests fail, document them as pre-existing.

## Execution Sequence

Execute edits in the exact order specified below. After each GROUP, verify the changes are correct by reading the modified files.

### GROUP 1: P0 — BLOCKING Fixes

#### File 1: `core/block-handler.md` (CRQ-4)

**Edit:** In Step 1, add `smoke-check` to the rollback trigger agent list.

Current text (Step 1):
```
1. **Rollback:** If the blocking agent is `fixer`, `reviewer`, or `test-engineer` → dispatch `ceos-agents:rollback-agent`
```

New text:
```
1. **Rollback:** If the blocking agent is `fixer`, `reviewer`, `test-engineer`, or `smoke-check` → dispatch `ceos-agents:rollback-agent`
```

#### File 2: `agents/rollback-agent.md` (CRQ-4)

**Edit:** In Step 1, add `smoke-check` to the proceed-with-rollback list.

Current text:
```
- If the blocking agent is `fixer`, `test-engineer`, `e2e-test-engineer`, or `reviewer` → proceed with rollback.
```

New text:
```
- If the blocking agent is `fixer`, `test-engineer`, `e2e-test-engineer`, `reviewer`, or `smoke-check` → proceed with rollback.
```

Also update the Constraints section:
Current text:
```
- NEVER rollback if called after a read-only agent block (triage-analyst, code-analyst, spec-analyst, architect, stack-selector), publisher block, or scaffolder block — handled in Step 1
```

This remains correct (smoke-check is not in the "never rollback" list, so it will correctly proceed to rollback).

#### File 3: `agents/fixer.md` (CRQ-1, CRQ-2, CRQ-5)

**Edit 3a — Frontmatter description (CRQ-5):**
```
description: Implements minimal, correct bug fixes targeting root cause. Surgical changes with backwards compatibility.
```
Change to:
```
description: Implements minimal, correct fixes — bug fixes targeting root cause or feature subtasks per spec. Surgical changes with backwards compatibility.
```

**Edit 3b — Role statement (CRQ-5):**
```
You are a Senior Developer specializing in surgical bug fixes.
```
Change to:
```
You are a Senior Developer specializing in surgical code changes — bug fixes and feature implementations.
```

**Edit 3c — Goal (CRQ-5):**
```
Minimal correct fix that solves the root cause. Simplest solution that doesn't break anything.
```
Change to:
```
Minimal correct fix that solves the root cause (bug mode) or implements the spec requirement (feature mode). Simplest solution that doesn't break anything.
```

**Edit 3d — Step 1 guard (CRQ-1, CRQ-2):**
```
1. Read the triage analysis and impact report thoroughly. If triage analysis or impact report is missing, Block with reason 'Missing input from previous pipeline stage'.
```
Change to:
```
1. Read the input artifacts for the current pipeline mode:
   - **Bug mode (default):** Read the triage analysis and impact report thoroughly. If triage analysis or impact report is missing, Block with reason 'Missing input from previous pipeline stage'.
   - **Feature mode** (context contains `Mode: feature-implementation`): Read the architectural design, subtask scope, and acceptance criteria. If architectural design or acceptance criteria are missing, Block with reason 'Missing input from previous pipeline stage'. There is no triage analysis or impact report in feature mode — do not require them.
```

**Edit 3e — Step 5 TDD RED phase (CRQ-5):**
```
   - **RED:** Write a test that reproduces the bug. Run it — confirm it FAILS. If the test passes, your test does not capture the actual bug; rewrite it.
```
Change to:
```
   - **RED:** 
     - **Bug mode (default):** Write a test that reproduces the bug. Run it — confirm it FAILS. If the test passes, your test does not capture the actual bug; rewrite it.
     - **Feature mode** (context contains `Mode: feature-implementation`): Write a test that verifies the new behavior described in the acceptance criteria. Run it — confirm it FAILS (the feature is not yet implemented). If the test passes immediately, verify the feature is not already implemented; if it is not, your test does not capture the expected behavior — rewrite it.
```

#### File 4: `skills/implement-feature/SKILL.md` (CRQ-2, CRQ-3)

**Edit 4a — Step 6b fixer context (CRQ-2):**
```
- Context: architectural design + subtask scope + acceptance criteria
```
Change to:
```
- Context: `Mode: feature-implementation.` + architectural design + subtask scope + acceptance criteria
```

**Edit 4b — Step 6b: Add NEEDS_DECOMPOSITION handler (CRQ-3):**
After "If build still fails -> proceed to step X." add:

```

If fixer-reviewer loop returns `NEEDS_DECOMPOSITION`:
  1. Authoritative revert: `git checkout . && git clean -fd` (safety net — fixer's self-revert is best-effort)
  2. If `decompose_mode = DISABLED` → Block ("Fixer needs decomposition but --no-decompose was set")
  3. If this is already a decomposed subtask → Block ("NEEDS_DECOMPOSITION signaled within a subtask — subtask scope exceeds fixer limits. Split the parent feature into smaller issues.")
  4. If in single-pass mode and the feature has NOT been decomposed yet:
     - Run architect agent for decomposition (same as Step 5 with FORCE)
     - Continue with subtask execution (Step 6 in decomposition mode)
  5. Update `state.json`: record `decomposition.decision` change to `"DECOMPOSE"` (from fixer signal).
```

**Edit 4c — Step 6d reviewer context (CRQ-2):**
```
- Context: diff from fixer + acceptance criteria from spec-analyst
```
Change to:
```
- Context: `Mode: feature-implementation.` + diff from fixer + acceptance criteria from spec-analyst
```

**Edit 4d — Step 6e test-engineer context (CRQ-2):**
```
- Context: changed files, acceptance criteria
```
Change to:
```
- Context: `Mode: feature-implementation.` + changed files + acceptance criteria
```

### CHECKPOINT: Verify P0 Edits

1. Read all 4 modified files to verify edits
2. Verify bug-fix language is preserved in fixer.md (TC-4)
3. Verify mode-branch is present in fixer.md Step 1 (TC-5)
4. Verify smoke-check is in both rollback triggers (TC-6)
5. Verify NEEDS_DECOMPOSITION handler exists in implement-feature (TC-7)

### GROUP 2: P1 — HIGH Quality Fixes

#### File 5: `agents/reviewer.md` (CRQ-6, CRQ-8)

**Edit 5a — Step 1 artifact reading (CRQ-6):**
```
1. Read the original bug report, triage analysis, impact report, and the fixer's output (changed files, approach, reasoning)
```
Change to:
```
1. Read the input artifacts for the current pipeline mode:
   - **Bug mode (default):** Read the original bug report, triage analysis, impact report, and the fixer's output (changed files, approach, reasoning).
   - **Feature mode** (context contains `Mode: feature-implementation`): Read the specification, architectural design, subtask scope, acceptance criteria, and the fixer's output (changed files, approach, reasoning). There is no bug report, triage analysis, or impact report in feature mode.
```

**Edit 5b — Step 4 root cause checklist item (CRQ-6):**
```
   - **Root cause:** Does the fix address the actual root cause, not just symptoms?
```
Change to:
```
   - **Root cause / spec alignment:** In bug mode: Does the fix address the actual root cause, not just symptoms? In feature mode: Does the implementation match the spec requirement completely?
```

**Edit 5c — Step 4 completeness checklist item (CRQ-6):**
```
   - **Completeness:** Are all affected paths covered (from impact report)?
```
Change to:
```
   - **Completeness:** In bug mode: Are all affected paths covered (from impact report)? In feature mode: Are all acceptance criteria addressed by the implementation?
```

**Edit 5d — AC Fulfillment: add compensating requirement for single-pass (CRQ-8):**
After the existing AC fulfillment section:
```
     If any AC is NOT ADDRESSED → this is a HIGH issue.
     If any AC is PARTIALLY fulfilled → this is a MEDIUM issue.
```
Add:
```
     If context indicates this is a single-pass feature (no decomposition) and acceptance-gate will be skipped: your AC Fulfillment section acts as the primary AC verification gate. You MUST cite specific `file:line` evidence for each FULFILLED verdict (not just a text-based assessment). This compensates for the skipped acceptance-gate.
```

#### File 6: `agents/test-engineer.md` (CRQ-7)

**Edit 6a — Frontmatter description (CRQ-7):**
```
description: Writes and runs unit tests verifying the fix and preventing regressions. Follows project test framework conventions.
```
Change to:
```
description: Writes and runs unit tests verifying the fix or new feature behavior and preventing regressions. Follows project test framework conventions.
```

**Edit 6b — Step 1 artifact reading (CRQ-7):**
```
1. Read the bug report, fixer output (changed files, root cause), and impact report (test coverage section)
```
Change to:
```
1. Read the input artifacts for the current pipeline mode:
   - **Bug mode (default):** Read the bug report, fixer output (changed files, root cause), and impact report (test coverage section).
   - **Feature mode** (context contains `Mode: feature-implementation`): Read the fixer output (changed files, approach) and acceptance criteria. There is no bug report or impact report in feature mode — derive test scope from the AC and changed files.
```

**Edit 6c — Step 3 regression test framing (CRQ-7):**
```
   - **Required:** One test verifying the specific behavior that was fixed (regression test)
   - **Recommended:** One test for the most likely edge case from the impact report
```
Change to:
```
   - **Required:** One test verifying the specific behavior — in bug mode: the behavior that was fixed (regression test); in feature mode: the primary new behavior from the acceptance criteria (behavior test)
   - **Recommended:** One test for the most likely edge case — in bug mode: from the impact report; in feature mode: from the acceptance criteria boundary conditions
```

#### File 7: `agents/e2e-test-engineer.md` (CRQ-2)

**Edit 7a — Goal (CRQ-2):**
```
E2E tests verifying the complete user flow affected by the fix. Prevent UI-level regressions. Cover both happy path AND critical error paths.
```
Change to:
```
E2E tests verifying the complete user flow affected by the change (bug fix or feature implementation). Prevent UI-level regressions. Cover both happy path AND critical error paths.
```

**Edit 7b — Step 1 (CRQ-2):**
```
1. Read the bug report and fix diff — understand which user flow was affected
```
Change to:
```
1. Read the input artifacts for the current pipeline mode:
   - **Bug mode (default):** Read the bug report and fix diff — understand which user flow was affected.
   - **Feature mode** (context contains `Mode: feature-implementation`): Read the specification, acceptance criteria, and fix diff — understand which user flow is being added or modified.
```

#### File 8: `skills/implement-feature/SKILL.md` (CRQ-8)

**Edit 8a — Step 6h: Add compensating tradeoff documentation (CRQ-8):**
The existing text:
```
For features, the acceptance gate always runs within the subtask loop (no threshold condition — unlike bugs, which require ≥3 AC or complexity ≥M). In single-pass mode (no decomposition), this step is skipped.
```
Change to:
```
For features, the acceptance gate always runs within the subtask loop (no threshold condition — unlike bugs, which require ≥3 AC or complexity ≥M). In single-pass mode (no decomposition), this step is skipped — the reviewer's AC Fulfillment section serves as the compensating verification gate (reviewer is instructed to provide file:line evidence when acceptance-gate is skipped; see CRQ-8 compensating requirement in reviewer agent definition).
```

### CHECKPOINT: Verify P1 Edits

1. Read all modified files
2. Verify bug-fix language preserved in reviewer.md, test-engineer.md, e2e-test-engineer.md (TC-4)
3. Verify mode-branches present in all four agent files (TC-5)

### GROUP 3: P2 — MEDIUM Technical Debt

#### File 9: `core/fixer-reviewer-loop.md` (CRQ-10)

**Edit 9a — Input Contract (CRQ-10):**
```
| context | string | required | Bug report or spec + AC + code-analyst output |
```
Change to:
```
| context | string | required | Discriminated by mode. **Bug mode:** bug report + triage analysis + code-analyst output + AC (from triage-analyst). **Feature mode:** specification + architectural design + subtask scope + AC (from spec-analyst). Prefixed with `Mode: feature-implementation.` in feature mode. |
```

**Edit 9b — acceptance_criteria field note (CRQ-10):**
```
| acceptance_criteria | list | [] | AC list from triage-analyst output |
```
Change to:
```
| acceptance_criteria | list | [] | AC list from triage-analyst (bug mode) or spec-analyst (feature mode) |
```

**Edit 9c — Failure Handling (CRQ-10):**
```
- `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `skills/fix-ticket/SKILL.md` step 5).
```
Change to:
```
- `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `skills/fix-ticket/SKILL.md` step 5 for bug pipeline, `skills/implement-feature/SKILL.md` step 6b for feature pipeline).
```

#### File 10: `core/decomposition-heuristics.md` (CRQ-11)

**Edit 10a — Purpose (CRQ-11):**
```
Determine whether a ticket should be decomposed into subtasks before the fixer-reviewer loop begins.
```
Change to:
```
Determine whether a bug-fix ticket should be decomposed into subtasks before the fixer-reviewer loop begins.

**Scope:** This contract applies to the **bug pipeline** (`fix-ticket`, `fix-bugs`) only. The feature pipeline (`implement-feature`) uses architect-driven decomposition — see `skills/implement-feature/SKILL.md` Step 5 for the feature decomposition decision logic, which uses the architect's task tree and AC coverage checks instead of code-analyst heuristics.
```

**Edit 10b — Output Contract (CRQ-11):**
```
| `DECOMPOSE` | Run architect agent, build task tree, execute per-subtask (see `skills/fix-ticket/SKILL.md` steps 4b–4c) |
```
Change to:
```
| `DECOMPOSE` | Run architect agent, build task tree, execute per-subtask (see `skills/fix-ticket/SKILL.md` steps 4b–4c). Note: feature pipeline does not use this heuristic — it evaluates architect recommendation directly. |
```

#### File 11: `state/schema.md` (CRQ-12)

**Edit 11a — Add ac_source field to triage object (CRQ-12):**
After the `triage.acceptance_criteria` row in the field definitions table, add:
```
| `triage.ac_source` | string or null | No | `null` | Source agent for acceptance criteria: `"triage-analyst"` (bug pipeline) or `"spec-analyst"` (feature pipeline). Use this field to determine AC provenance programmatically. |
```

**Edit 11b — Update triage.acceptance_criteria description (CRQ-12):**
```
| `triage.acceptance_criteria` | string[] | No | `[]` | Full AC text items, preserved for resume. |
```
Change to:
```
| `triage.acceptance_criteria` | string[] | No | `[]` | Full AC text items, preserved for resume. In `code-bugfix` mode: populated by triage-analyst. In `code-feature` mode: populated by spec-analyst (field reused for cross-pipeline compatibility). See `triage.ac_source` for provenance. |
```

**Edit 11c — Add ac_source to the JSON example (CRQ-12):**
In the Full Schema Example JSON, after `"acceptance_criteria": [],` add:
```
    "ac_source": null,
```

### CHECKPOINT: Verify P2 Edits

1. Read all modified files
2. Verify contract structure preserved (Purpose + Input + Process + Output + Failure Handling)

## Post-Implementation

1. Run test harness: `cd C:/gitea_ceos-agents && ./tests/harness/run-tests.sh`
2. Verify all TDD criteria (TC-1 through TC-10)
3. Run `git diff --stat` to verify edit scope matches expectations (~160 lines added)
4. Verify no files were accidentally created
