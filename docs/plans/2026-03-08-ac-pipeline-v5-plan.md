# AC-Driven Pipeline v5.0 — Implementation Plan

**Date:** 2026-03-08
**Version:** v5.0.0 (MAJOR — agent output format changes)
**Status:** APPROVED
**Source:** `2026-03-08-ac-pipeline-evaluation.md` (evaluation of 22 proposals from 3 discussion documents)

---

## Table of Contents

1. [Overview](#overview)
2. [Phase 1 (v5.0-alpha): AC Extraction + Complexity + AC-Aware Review](#phase-1-v50-alpha)
3. [Phase 2 (v5.0-beta): AC Writeback + maps_to + Coverage Check](#phase-2-v50-beta)
4. [Phase 3 (v5.0-rc): Scaffolder Infra + Spec Compliance](#phase-3-v50-rc)
5. [Phase 4 (v5.0): Acceptance Gate + Mid-Fix Decomposition](#phase-4-v50)
6. [Phase 5 (v5.0.x): GWT Format + Quality Scorecard](#phase-5-v50x)
7. [CLAUDE.md Changes](#claudemd-changes)
8. [Test Scenarios](#test-scenarios)
9. [Code Review Checklist](#code-review-checklist)

---

## Overview

### Why MAJOR version?

The triage-analyst, reviewer, spec-analyst, and architect agents all get new output format sections (AC extraction, AC fulfillment, AC writeback, maps_to traceability, NEEDS_DECOMPOSITION signal). Any Agent Override or external tooling parsing these outputs must adapt. This constitutes a breaking change in the agent output format contract — justified by an updated Versioning Policy (see CLAUDE.md Changes section) that explicitly classifies agent output format changes as MAJOR.

### Not Included

**Dropped (3 proposals — see evaluation section 4 "Drop" for rationale):**
- F2 (AC quality review step) — self-review bias; existing spec-reviewer covers this
- F8 (AC feedback loop) — high complexity, speculative benefit
- S6 (Batch integration AC) — unreliable to predict emergent integration issues

**Deferred to v5.1+ (3 proposals):**
- B4/F7/S4 (Manual verification mode) — proven CI/CD pattern but high complexity; defer until user demand
- B5 (Fix retrospective history) — validated by ACE paper (+8.6%); implement after core AC pipeline is stable
- S7 (/scaffold-iterate command) — wait for scaffold v2 usage data

### Dependency Graph

```
Phase 1: B1 + B3 + B7/F5           (no dependencies)
Phase 2: F1 + F3 + F4              (F4 depends on F3)
Phase 3: S3 + S1                   (no dependencies)
Phase 4: B2/F6 + B6                (B2/F6 depends on B1 from Phase 1)
Phase 5: S2 + S5                   (no dependencies)
```

Each phase is independently shippable. Phase 4 depends on Phase 1 (the acceptance gate needs AC to verify). All other phases are independent.

---

## Phase 1 (v5.0-alpha)

**AC Extraction + Complexity Estimation + AC-Aware Review**

### B1: AC Extraction in Triage

**File:** `agents/triage-analyst.md`

**Section: Process, Step 5** — After severity assessment, add a new step 5b:

```
5b. Extract or synthesize acceptance criteria:
    - If the bug report contains explicit success criteria → extract verbatim
    - If not → synthesize from the described expected behavior, reproduction steps, and affected area
    - Each AC must be testable (verifiable by running code or inspecting output)
    - Format: numbered list, 2-5 items
    - If the bug is trivial (severity LOW, single-line fix likely) → 1-2 AC is sufficient
```

**Section: Process, Step 6** — Extend the output format. Add after `**Attachments:**`:

```
    - **Acceptance Criteria:**
      1. {testable criterion — what must be true after the fix}
      2. {testable criterion}
    - **Complexity:** {XS|S|M|L} — {brief justification}
```

**Section: Process, Step 7** — Extend checkpoint comment:

Change from:
```
[ceos-agents] Triage completed. Severity: {severity}. Area: {area}.
```
To:
```
[ceos-agents] Triage completed. Severity: {severity}. Area: {area}. Complexity: {complexity}. AC: {count}.
```

**Rationale:** The checkpoint comment format change is part of the MAJOR version justification — tools parsing this comment must adapt.

**Quality safeguard:** If the bug report is too vague to produce meaningful AC (e.g., "it doesn't work" with no reproduction steps or expected behavior), the triage-analyst should Block per existing clarity validation (step 4, confidence < 50%) rather than synthesize speculative AC. Low-quality AC are worse than no AC — downstream agents would optimize against wrong criteria. The existing clarity gate is the first line of defense against poor AC quality.

### B3: Complexity Estimation in Triage

**File:** `agents/triage-analyst.md`

**Section: Process** — Add a new step 5c (after the AC extraction step 5b):

```
5c. Estimate complexity:
    - **XS:** Likely ≤5 lines, 1 file, LOW risk (typo, config value, off-by-one)
    - **S:** Likely ≤20 lines, 1-2 files, LOW/MEDIUM risk
    - **M:** Likely ≤100 lines, 3-5 files, MEDIUM risk
    - **L:** Likely >100 lines or HIGH risk, may need decomposition
    Base the estimate on: affected area breadth, reproduction steps complexity,
    and whether the fix likely crosses module boundaries.
```

The complexity value is included in the output format added by B1 (same `**Complexity:**` line). No separate output change needed.

**Dependencies:** None. Can be implemented together with B1 as a single change to triage-analyst.md.

### B7/F5: AC-Aware Reviewer Checklist

**File:** `agents/reviewer.md`

**Section: Process, Step 4** — Add a new checklist item after `**Over-engineering:**`:

```
   - **AC fulfillment:** For each acceptance criterion from triage/spec analysis:
     - FULFILLED — the fix demonstrably satisfies this criterion
     - PARTIALLY — the fix addresses part of this criterion but not completely
     - NOT ADDRESSED — the fix does not address this criterion
     If any AC is NOT ADDRESSED → this is a HIGH issue.
     If any AC is PARTIALLY fulfilled → this is a MEDIUM issue.
```

**Section: Process, Step 7** — Extend the output format. Add after `**Issues:**` block:

```
   - **AC Fulfillment:**
     1. {AC text} → {FULFILLED|PARTIALLY|NOT ADDRESSED} — {evidence}
     2. {AC text} → {FULFILLED|PARTIALLY|NOT ADDRESSED} — {evidence}
```

**Section: Constraints** — Add:

```
- If acceptance criteria were provided in context, MUST include AC Fulfillment section in output. If no AC provided, skip the section.
```

**Dependencies:** Depends on B1 — without AC in triage output, the reviewer has nothing to check for bug fixes. For features, AC come from spec-analyst (which already produces them). This change works for both pipelines.

### Command Changes for Phase 1

**File: `commands/fix-bugs.md`**

**Section: Orchestration, Step 2 (Triage)** — After running triage-analyst, extract the AC and complexity from the triage output and store them in per-bug context. Add after "OK → continue":

```
Store from triage output: acceptance_criteria (list), complexity (XS/S/M/L).
These are passed to all downstream agents as context.
```

**Section: Orchestration, Step 4 (Fixer)** — Extend the context passed to fixer:

Change from:
```
Context: `Max build retries = {Build retries from config}. Block Comment Template: {template from plugin CLAUDE.md}.`
```
To:
```
Context: `Max build retries = {Build retries from config}. Block Comment Template: {template from plugin CLAUDE.md}. Acceptance criteria: {AC from triage}.`
```

**Section: Orchestration, Step 6 (Reviewer)** — Extend the context:

Add to existing context: `Acceptance criteria: {AC from triage}.`

**Section: Dry-run report** — Add `AC` column to the table:

```
| Bug ID | Summary | Triage | Severity | Affected Files | Risk | Est. Complexity | AC |
|--------|---------|--------|----------|----------------|------|-----------------|----|
| PROJ-1 | ... | OK | HIGH | auth/login.ts | MEDIUM | S (≤20 lines) | 3 |
```

**File: `commands/fix-ticket.md`**

Same changes as fix-bugs.md:
- Step 3 (Triage): store AC and complexity from triage output
- Step 5 (Fixer): pass AC as context
- Step 7 (Reviewer): pass AC as context
- Dry-run report: add AC column

**File: `commands/implement-feature.md`**

**Section: Orchestration, Step 3 (Spec-analyst)** — After running spec-analyst, extract AC:

```
Store from spec-analyst output: acceptance_criteria (list). Pass to all downstream agents.
```

**Section: Orchestration, Step 6d (Reviewer)** — Extend context:

```
Context: diff from fixer + acceptance criteria from spec-analyst
```

Note: implement-feature already passes acceptance criteria to the fixer (via architect's subtask AC). The change here is explicitly passing the top-level feature AC to the reviewer for the AC Fulfillment check.

---

## Phase 2 (v5.0-beta)

**AC Writeback + maps_to Traceability + Coverage Check**

### F1: AC Writeback to Issue Tracker

**File:** `agents/spec-analyst.md`

**Section: Process, Step 6** — Extend the checkpoint comment:

Change from:
```
`[ceos-agents] Spec analysis completed. Area: {area}. Criteria: {count}.`
```
To:
```
`[ceos-agents] Spec analysis completed. Area: {area}. Criteria: {count}.`

Additionally, post the full acceptance criteria as a separate comment:
```
[ceos-agents] Acceptance Criteria:
1. {AC text}
2. {AC text}
...
```
This makes AC visible to human stakeholders in the issue tracker.
```

**Section: Constraints** — Add:

```
- MUST post acceptance criteria to the issue tracker as a separate comment (after the checkpoint comment). This enables human review of AC before implementation proceeds.
```

**Dependencies:** None. Independent of Phase 1 — spec-analyst already produces AC, this just writes them back.

### F3: `maps_to` Traceability in Architect

**File:** `agents/architect.md`

**Section: Process, Step 7** — Extend the task tree YAML format. Add `maps_to` field:

Change from:
```yaml
       - id: "sub-1"
         title: "Short description"
         scope: "What exactly to do"
         files:
           - path/to/file1.ext
           - path/to/file2.ext
         estimated_lines: 25
         depends_on: []
         acceptance_criteria:
           - "Testable criterion 1"
           - "Testable criterion 2"
```
To:
```yaml
       - id: "sub-1"
         title: "Short description"
         scope: "What exactly to do"
         files:
           - path/to/file1.ext
           - path/to/file2.ext
         estimated_lines: 25
         depends_on: []
         maps_to:
           - "AC-1: {text of the parent feature/bug AC this subtask addresses}"
           - "AC-3: {text of another parent AC}"
         acceptance_criteria:
           - "Testable criterion 1"
           - "Testable criterion 2"
```

**Section: Process, Step 7** — Add a validation instruction after the YAML block:

```
   Ensure every parent AC (from spec-analyst or triage-analyst output) is referenced
   by at least one subtask's `maps_to` field. If a parent AC is not covered by any
   subtask, either add it to an existing subtask or create a new subtask for it.
```

**Section: Constraints** — Add:

```
- Every parent acceptance criterion MUST be mapped to at least one subtask via `maps_to`. Unmapped AC indicates incomplete decomposition.
- `maps_to` entries MUST use format `AC-{N}: {verbatim text from parent AC}` where N matches the parent AC numbering exactly. The architect MUST NOT renumber or reorder parent AC.
```

**Dependencies:** None for the architect change itself. The `maps_to` field enables F4 (coverage check).

### F4: Post-Decomposition AC Coverage Check

**File:** `commands/implement-feature.md`

**Section: Orchestration, Step 5 (Decomposition decision)** — Add a validation step after "Validate task tree":

```
**AC coverage check:**
1. Collect all acceptance criteria from spec-analyst output (the parent AC list)
2. Collect all `maps_to` references from all subtasks in the task tree
3. Compute the set difference: parent_AC - mapped_AC
4. If any parent AC is unmapped:
   - Display warning: "The following acceptance criteria are not covered by any subtask:"
   - List the unmapped AC
   - If mode is YOLO → Block ("Incomplete decomposition — unmapped AC detected")
   - Otherwise → ask user: "Continue anyway? The unmapped criteria will not be explicitly addressed. [Y/n]"
```

This is a validation step in the command, NOT a separate agent call.

**AC matching algorithm:**
- Each `maps_to` entry uses format `AC-{N}: {text}` where N is the 1-based index in the parent AC list
- Coverage check: collect all N values from all subtasks' `maps_to` fields, verify that every integer from 1 to {total parent AC count} appears at least once
- Text after `AC-N:` is informational (for human readability) — matching is by index only
- If a `maps_to` entry cannot be parsed (no `AC-{N}:` prefix) → treat as warning, not error

**File: `commands/fix-ticket.md`**

**Section: Orchestration, Step 4b (Decomposition decision)** — Add the same AC coverage check after task tree validation (only when AC are available from triage, i.e., when B1 from Phase 1 is active).

**File: `commands/fix-bugs.md`**

**Section: Orchestration, Step 3b (Decomposition decision)** — Same AC coverage check.

**File: `commands/scaffold.md`**

**Section: Step 5 (Architecture & Decomposition)** — Add after the "Validate architect output" block,
before "### Step 6: Feature Plan Checkpoint":

**AC coverage check (per epic):**
For each epic individually:
1. Collect acceptance criteria from the formatted epic specification (the parent AC list)
2. Collect all `maps_to` references from subtasks belonging to this epic
3. Compute set difference: parent AC indices not covered by any subtask's `maps_to`
4. If any parent AC is unmapped:
   - If mode is Full YOLO → Block ("Incomplete decomposition for epic {name} — unmapped AC")
   - Otherwise → display warning, ask user: "Continue anyway? [Y/n]"

**Dependencies:** Depends on F3 (`maps_to` field must exist in the task tree).

---

## Phase 3 (v5.0-rc)

**Scaffolder Test Infrastructure + Spec Compliance Verification**

### S3: Scaffolder Test Infrastructure Generation

**File:** `agents/scaffolder.md`

**Section: Process, Step 2, Batch 3 — Quality** — Extend to generate test infrastructure:

Change from:
```
   **Batch 3 — Quality:**
   - 1 smoke test (tests/test_smoke.py or equivalent — "app starts and responds")
   - Linter config (ruff.toml / .eslintrc / equivalent)
```
To:
```
   **Batch 3 — Quality:**
   - 1 smoke test (tests/test_smoke.py or equivalent — "app starts and responds")
   - Test infrastructure setup file (`test/setup.{ext}` or `tests/conftest.py` or equivalent):
     - Dynamic port allocation (find free port, avoid hardcoded ports)
     - Database test fixtures (if DB configured — create/teardown test database)
     - Health check helper (wait for service readiness with timeout)
     - Environment isolation (.env.test with test-specific values)
   - Linter config (ruff.toml / .eslintrc / equivalent)
```

**Section: Process, Step 5 (Output)** — Extend the Scaffold Report verification section:

Add after `Linter: {PASS | FAIL}`:
```
     - Test infra: {PASS | FAIL} (setup file exists and imports correctly)
```

**Section: Constraints** — Add:

```
- NEVER use hardcoded ports in test infrastructure — always use dynamic port allocation (e.g., port 0 for OS assignment)
- Test setup file MUST be importable/includable by the smoke test — verify the import works
```

**Dependencies:** None. Independent of other phases.

### S1: Spec Compliance Verification (spec-reviewer --verify mode)

**File:** `agents/spec-reviewer.md`

**Section: Process** — Add a new mode section after Step 7 (output):

```
## Verify Mode (--verify)

When invoked with `--verify` flag, the spec-reviewer operates in implementation verification mode
instead of specification review mode. The input is both the spec/ folder AND the implemented codebase.

### Verify Process

1. Read the specification (all spec/ files) — same as review mode
2. Read the implemented codebase (selectively — do not read everything):
   - For each AC: search for relevant files by keywords from the AC text (Grep/Glob)
   - Read at most 20 source files and 10 test files total
   - Prioritize files referenced in spec/architecture.md and epic descriptions
   - Generated config files (CLAUDE.md, Dockerfile, CI config)
3. For each epic in spec/epics/*.md:
   - For each acceptance criterion in the epic:
     - Search the codebase for evidence of implementation (function names, API endpoints, test assertions)
     - Verdict: IMPLEMENTED | PARTIALLY | MISSING
     - Evidence: file path + line reference (or "no evidence found")
4. For each NFR in spec/architecture.md:
   - Check whether the implementation respects the constraint
   - Verdict: RESPECTED | VIOLATED | UNTESTABLE
5. Output:

   ```markdown
   ## Spec Compliance Report
   - **Verdict:** {PASS | PARTIAL | FAIL}
   - **Coverage:** {N}/{M} acceptance criteria implemented ({percentage}%)
   - **Details:**
     - Epic: {name}
       1. {AC text} → {IMPLEMENTED|PARTIALLY|MISSING} — {evidence}
   - **NFR compliance:**
     - {NFR} → {RESPECTED|VIOLATED|UNTESTABLE} — {evidence}
   - **Summary:** {1-2 sentence overall assessment}
   ```

   Verdict rules:
   - All AC IMPLEMENTED + all NFR RESPECTED → PASS
   - Any AC MISSING → FAIL
   - All AC at least PARTIALLY + no NFR VIOLATED → PARTIAL
```

**Section: Constraints** — Add:

```
- In --verify mode: NEVER modify code — read-only analysis only
- In --verify mode: search evidence systematically — do not assume implementation matches spec without checking
- In --verify mode: for each MISSING AC, suggest which files should contain the implementation
```

Note: Spec-reviewer --verify uses IMPLEMENTED/PARTIALLY/MISSING (implementation existence). Acceptance-gate uses FULFILLED/PARTIALLY/NOT ADDRESSED (fix quality against acceptance criteria). Different scales for different purposes.

**File: `commands/scaffold.md`**

**Section: Orchestration** — Add a new Step 7b after Step 7 (Feature Implementation Loop) and before Step 8 (E2E Tests):

```
### Step 7b: Spec Compliance Check

Run spec-reviewer in verify mode (Task tool, model: opus):
  Context: `--verify mode. Compare spec/ against implemented codebase.`

If verdict is FAIL:
  - Display the compliance report
  - If mode is Full YOLO → Block ("Spec compliance failed — MISSING acceptance criteria detected")
  - If mode is Interactive or YOLO-checkpoint → display report, ask user:
    "Some acceptance criteria are not implemented. Continue to E2E tests anyway? [Y/n]"

If verdict is PASS or PARTIAL → continue to Step 8.
```

**Dependencies:** None. Independent of other phases.

---

## Phase 4 (v5.0)

**Acceptance Gate + Mid-Fix Decomposition**

### B2/F6: Acceptance Gate Step

This is a new agent (`acceptance-gate`) and a new pipeline step. The acceptance-gate agent is a dedicated AC verifier — separate from the reviewer, which remains focused on adversarial code quality review. See `agents/acceptance-gate.md` for the full agent definition.

**File: `commands/fix-bugs.md`**

**Section: Orchestration** — Renumber existing steps:
- 7a (E2E test) stays 7a
- NEW acceptance gate = 7b
- OLD 7b (Pre-publish hook) → 7c
- OLD 7c (Pre-publish custom agent) → 7d

Update all references: "skip to step 7b" → "skip to step 7c" where referring to pre-publish hook.

Add new Step 7b:

```
### 7b. Acceptance gate (conditional)

Condition: Run this step ONLY when:
- Bug has >= 3 acceptance criteria (from triage), OR
- Bug complexity >= M (from triage)

If condition is not met → skip to step 7c.

Run `ceos-agents:acceptance-gate` (Task tool, model: sonnet):
  Context: `Acceptance criteria: {AC from triage}. Changed files: {list of files modified by fixer}.`

If REQUEST_CHANGES → back to fixer (counts toward the same Fixer iterations limit).
If APPROVE → continue to step 7c.
```

**File: `commands/fix-ticket.md`**

Same step structure. Renumber existing steps:
- 8a (E2E test) stays 8a
- NEW acceptance gate = 8b
- OLD 8b (Pre-publish hook) → 8c
- OLD 8c (Pre-publish custom agent) → 8d

Update all references: "skip to step 8b" → "skip to step 8c" where referring to pre-publish hook.

Add new Step 8b with the same condition and context as fix-bugs Step 7b.

**File: `commands/implement-feature.md`**

**Section: Orchestration** — Renumber existing Step 6g (Commit subtask) → 6h. Add new Step 6g (Acceptance gate) after Step 6f (E2E test). Update single-pass reference from '6a–6d' to '6a–6e' if needed.

```
### 6g. Acceptance gate (always for features)

For features, the acceptance gate always runs (no conditional — features always have AC).

Run `ceos-agents:acceptance-gate` (Task tool, model: sonnet):
  Context: `Acceptance criteria: {AC from spec-analyst — full feature AC, not just per-subtask AC}. Changed files: {list of files modified by fixer}.`

If REQUEST_CHANGES → back to fixer for the LAST subtask (or single-pass) with feedback.
If APPROVE → continue to step 6h.
```

**Dependencies:** Depends on B1 (Phase 1) — the gate needs AC from triage. For features, AC come from spec-analyst (already available).

### B6: Mid-Fix Decomposition Escape Hatch

**File:** `agents/fixer.md`

**Section: Process, Step 5** — Add after the REFACTOR phase:

```
   - **ESCAPE HATCH:** If during implementation you realize the fix requires changes across ≥4 files
     or the diff is approaching the 100-line limit and significant work remains:
     - STOP coding immediately
     - Output a NEEDS_DECOMPOSITION signal instead of a Fix Report:
       ```markdown
       ## NEEDS_DECOMPOSITION
       - **Reason:** {why the fix is larger than expected}
       - **Estimated scope:** {N files, ~M lines}
       - **Suggested split:** {2-3 subtasks that would break this down}
       - **Work done so far:** {what was completed, if anything}
       ```
     - Revert any partial changes before outputting this signal (best-effort — the orchestrating command performs its own authoritative revert as a safety net)
     - This signal is consumed by the orchestrating command, not the reviewer
```

**Section: Constraints** — Add:

```
- NEEDS_DECOMPOSITION may be signaled at most ONCE per ticket. If the decomposed subtasks also exceed limits, Block.
- NEVER signal NEEDS_DECOMPOSITION to avoid a hard problem — only when scope genuinely exceeds limits.
```

**File: `commands/fix-ticket.md`**

**Section: Orchestration, Step 5 (Fixer)** — Add handling after running fixer:

```
If fixer output contains `## NEEDS_DECOMPOSITION`:
  1. Authoritative revert: git checkout . && git clean -fd (safety net — fixer's self-revert is best-effort and not guaranteed)
  2. If decompose_mode = DISABLED → Block ("Fixer needs decomposition but --no-decompose was set")
  3. If this ticket has already been decomposed once → Block ("Decomposition limit (1) reached")
  4. Run architect agent for decomposition (same as step 4b with FORCE)
  5. Continue with subtask execution (step 4c)
```

**File: `commands/fix-bugs.md`**

**Section: Orchestration, Step 4 (Fixer)** — Same NEEDS_DECOMPOSITION handling:

```
If fixer output contains `## NEEDS_DECOMPOSITION`:
  1. Authoritative revert: git checkout . && git clean -fd (safety net — fixer's self-revert is best-effort and not guaranteed)
  2. If decompose_mode = DISABLED → Block handler (step X)
  3. If this bug has already been decomposed once → Block handler (step X)
  4. Run architect for decomposition
  5. Continue with subtask execution (step 3c)
```

**Dependencies:** None for the fixer change. The command changes are self-contained.

---

## Phase 5 (v5.0.x)

**GWT Format + Quality Scorecard**

### S2: GWT-Preferred AC Format

**File:** `agents/spec-writer.md`

**Section: Process, Step 5** — Replace the example with a format guideline:

Change from:
```
5. For every user story: write testable acceptance criteria.
   Bad: "Login works correctly"
   Good: "Given valid credentials, POST /auth/login returns 200 with JWT token containing user_id and role claims"
```
To:
```
5. For every user story: write testable acceptance criteria.
   **Preferred format: Given/When/Then (GWT)** for behavioral criteria:
     "Given valid credentials, When POST /auth/login is called, Then it returns 200 with JWT token containing user_id and role claims"
   **Alternative format: Rule-oriented** for NFRs, constraints, and UX requirements:
     "MUST: Response time < 200ms for all API endpoints"
     "MUST: Use PostgreSQL 16+ for data persistence"
   Bad: "Login works correctly" (vague, not testable)
   Bad: "Given the system, When it runs, Then it works properly" (GWT form but vague content)
   Choose GWT for user-facing behavior. Choose rule-oriented for technical constraints.
```

**File:** `agents/spec-reviewer.md`

**Section: Process, Step 3** — Extend the AC quality check:

Add after "Measurable (has a clear pass/fail condition)":
```
   - Formatted correctly:
     - Behavioral criteria use GWT format (Given/When/Then)
     - NFRs and constraints use rule-oriented format (MUST/SHOULD/COULD)
     - Flag criteria that use GWT but have vague content as WARN (not BLOCK)
     - Flag behavioral criteria that don't use GWT as WARN (suggest reformatting)
```

**Dependencies:** None. Can be shipped as a patch after v5.0.

### S5: Quality Scorecard in Scaffolder

**File:** `agents/scaffolder.md`

**Section: Process** — Add a new Step 4b after Step 4 (Verify) and before Step 5 (Output):

```
4b. Generate quality scorecard (informational — does NOT block):
    Run these checks and report results:
    1. **Build:** Does the project build? (already checked in step 4)
    2. **Tests:** At least 1 passing test? (already checked in step 4)
    3. **Lint:** Linter configured and passing? (already checked in step 4)
    4. **CLAUDE.md:** All required sections present? (already checked in step 4)
    5. **Dockerfile:** Multi-stage build? Pinned base image?
    6. **CI config:** All 3 stages present (lint → test → build)?
    7. **Dependencies:** All pinned to exact versions? (check package manager lock file)
    8. **Test infrastructure:** Setup file present with port allocation? (if S3 implemented)
```

**Section: Process, Step 5 (Output)** — Extend the Scaffold Report:

Add after the Verification block:
```
   - **Quality Scorecard:**
     | Check | Status | Notes |
     |-------|--------|-------|
     | Build | PASS | ... |
     | Tests | PASS | 1 smoke test |
     | Lint | PASS | ruff configured |
     | CLAUDE.md | PASS | 5/5 required sections |
     | Dockerfile | PASS | multi-stage, python:3.12-slim |
     | CI config | PASS | lint → test → build |
     | Dependencies | WARN | 2 unpinned dev dependencies |
     | Test infra | PASS | conftest.py with port allocation |
```

**Dependencies:** Check #8 depends on S3 (Phase 3). If S3 is not yet implemented, check #8 is skipped.

---

## CLAUDE.md Changes

After all phases are implemented, update the project's CLAUDE.md:

### Agent Definition Format section

Add to the "Key Conventions Across All Agents" list:

```
- Triage-analyst output includes: acceptance criteria (2-5 items), complexity estimate (XS/S/M/L)
- Reviewer output includes: AC Fulfillment section (per-AC verdict: FULFILLED/PARTIALLY/NOT ADDRESSED) when AC are provided
- Acceptance-gate agent verifies AC fulfillment with code + test evidence (read-only, sonnet)
- Architect task tree includes: `maps_to` field linking subtasks to parent acceptance criteria (format: `AC-{N}: {text}`)
- Spec-analyst posts acceptance criteria as a separate comment to the issue tracker
- Spec-reviewer has a `--verify` mode for checking implementation against spec
- Fixer can signal NEEDS_DECOMPOSITION when scope exceeds limits (max 1 per ticket)
```

### Bug-Fix Pipeline section

Update the pipeline diagram:

```
Issue tracker query → TRIAGE (sonnet, +AC extraction, +complexity)
  → CODE ANALYST (sonnet) → [Pre-fix hook]
  → FIXER ↔ REVIEWER (opus, +AC fulfillment check)
  → [Post-fix hook + custom agent] → TEST ENGINEER (sonnet)
  → [E2E test (optional)] → [Acceptance gate (conditional: AC ≥ 3 or complexity ≥ M)]
  → [Pre-publish hook + custom agent] → PUBLISHER (haiku)
```

### Feature Pipeline section

Update the pipeline diagram:

```
Issue tracker query → SPEC-ANALYST (sonnet, +AC writeback)
  → ARCHITECT (opus, +maps_to traceability)
  → [AC coverage check] → [Decomposition decision]
  → FIXER ↔ REVIEWER (opus, +AC fulfillment check)
  → TEST ENGINEER (sonnet) → [Acceptance gate (always)]
  → PUBLISHER (haiku)
```

### Scaffold Pipeline section

Update the pipeline diagram:

```
User description → [Mode selection] → SPEC-WRITER ↔ SPEC-REVIEWER (opus)
  → [Spec checkpoint] → SCAFFOLDER (sonnet, +test infrastructure, +scorecard)
  → Validate → Git init
  → ARCHITECT (opus, +maps_to) → [Feature plan checkpoint]
  → FIXER ↔ REVIEWER (opus) → TEST ENGINEER (sonnet)
  → [Spec compliance check (spec-reviewer --verify)]
  → E2E-TEST-ENGINEER (sonnet) → Final report
```

### Versioning Policy section

Update the MAJOR row in the versioning table to:

```
| MAJOR (X.0.0) | Breaking change in Automation Config contract — new required key, renamed section — OR breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse) | New required key in Issue Tracker; new output section in triage-analyst |
```

### Repository Structure section

Update `agents/` line: `15 agent definitions` → `16 agent definitions`.

### Architecture: 2-Layer System section

Update **Agents** list to include `acceptance-gate` (after `reviewer`).

### Model Selection table

Add `acceptance-gate` to the `sonnet` row:

```
| sonnet | Analysis, testing, triage, specification, scaffolding, AC verification | triage-analyst, code-analyst, test-engineer, e2e-test-engineer, spec-analyst, stack-selector, scaffolder, acceptance-gate |
```

### Key Conventions Across All Agents

Update the read-only agents list to include `acceptance-gate`:

```
- Read-only agents (triage-analyst, code-analyst, reviewer, spec-analyst, architect, stack-selector, priority-engine, spec-reviewer, acceptance-gate) NEVER modify code
```

---

## Test Scenarios

Add to `tests/` directory:

### Phase 1 Tests

| Scenario | File | What to verify |
|----------|------|----------------|
| Triage AC extraction | `scenarios/triage-ac-extraction.md` | Triage output contains `**Acceptance Criteria:**` section with 2-5 items |
| Triage complexity | `scenarios/triage-complexity.md` | Triage output contains `**Complexity:**` with valid value (XS/S/M/L) |
| Triage checkpoint format | `scenarios/triage-checkpoint-v5.md` | Checkpoint comment includes `Complexity:` and `AC:` fields |
| Reviewer AC fulfillment | `scenarios/reviewer-ac-fulfillment.md` | Reviewer output contains `**AC Fulfillment:**` section when AC provided in context |
| Reviewer no-AC fallback | `scenarios/reviewer-no-ac.md` | Reviewer output does NOT contain AC Fulfillment section when no AC in context |
| Fix-bugs AC passthrough | `scenarios/fix-bugs-ac-context.md` | AC from triage are passed to fixer and reviewer as context |
| Dry-run AC column | `scenarios/dry-run-ac-column.md` | Dry-run report table includes AC count column |

### Phase 2 Tests

| Scenario | File | What to verify |
|----------|------|----------------|
| Spec-analyst AC writeback | `scenarios/spec-analyst-writeback.md` | Spec-analyst posts AC as a separate comment to issue tracker |
| Architect maps_to | `scenarios/architect-maps-to.md` | Task tree YAML contains `maps_to` field in every subtask |
| Architect maps_to coverage | `scenarios/architect-maps-to-coverage.md` | Every parent AC is referenced by at least one subtask's maps_to |
| AC coverage check | `scenarios/ac-coverage-check.md` | Command warns when parent AC is not covered by any subtask |

### Phase 3 Tests

| Scenario | File | What to verify |
|----------|------|----------------|
| Scaffolder test infra | `scenarios/scaffolder-test-infra.md` | Scaffolder generates test setup file with dynamic port allocation |
| Scaffolder no-hardcoded-ports | `scenarios/scaffolder-no-hardcoded-ports.md` | No hardcoded port numbers in test infrastructure files |
| Spec-reviewer verify mode | `scenarios/spec-reviewer-verify.md` | Spec-reviewer in --verify mode outputs compliance report with per-AC verdicts |
| Scaffold spec compliance | `scenarios/scaffold-spec-compliance.md` | Scaffold pipeline runs spec compliance check after feature implementation |

### Phase 4 Tests

| Scenario | File | What to verify |
|----------|------|----------------|
| Acceptance gate conditional | `scenarios/acceptance-gate-conditional.md` | Gate runs when AC >= 3 or complexity >= M; skips otherwise |
| Acceptance gate feature | `scenarios/acceptance-gate-feature.md` | Gate always runs for features |
| Acceptance gate agent | `scenarios/acceptance-gate-agent.md` | acceptance-gate agent produces structured report with per-AC FULFILLED/PARTIALLY/NOT ADDRESSED verdicts |
| Fixer NEEDS_DECOMPOSITION | `scenarios/fixer-needs-decomposition.md` | Fixer outputs NEEDS_DECOMPOSITION signal when scope exceeds limits |
| NEEDS_DECOMPOSITION handling | `scenarios/needs-decomposition-handling.md` | Command reverts changes and triggers architect for decomposition |
| NEEDS_DECOMPOSITION limit | `scenarios/needs-decomposition-limit.md` | Second NEEDS_DECOMPOSITION on same ticket → Block |

### Phase 5 Tests

| Scenario | File | What to verify |
|----------|------|----------------|
| Spec-writer GWT format | `scenarios/spec-writer-gwt.md` | Behavioral AC use GWT format, NFRs use rule-oriented |
| Spec-reviewer GWT check | `scenarios/spec-reviewer-gwt-check.md` | Spec-reviewer flags non-GWT behavioral criteria as WARN |
| Scaffolder scorecard | `scenarios/scaffolder-scorecard.md` | Scaffolder output includes quality scorecard table with 8 checks |

---

## Code Review Checklist

Before merging each phase:

### General (all phases)

- [ ] Agent frontmatter unchanged (name, description, model, style)
- [ ] Goal → Expertise → Process → Constraints section order preserved
- [ ] Process steps renumbered correctly after insertions
- [ ] Constraints start with NEVER or define hard limits
- [ ] Agent count updated from 15 to 16 (new: acceptance-gate)
- [ ] No new required Automation Config keys added (this is a MAJOR version for output format, not config)
- [ ] All command changes pass-through AC as context, not as hardcoded values
- [ ] Tests pass: `./tests/harness/run-tests.sh`

### Phase 1 specific

- [ ] Triage output format change is additive (new fields, not removed fields)
- [ ] Reviewer AC Fulfillment section is conditional (only when AC in context)
- [ ] Checkpoint comment format change documented as breaking
- [ ] Dry-run report table width doesn't break with new column

### Phase 2 specific

- [ ] AC writeback is a separate comment (not merged into checkpoint comment)
- [ ] `maps_to` is a new optional field in YAML (existing task trees without it still work)
- [ ] AC coverage check is in the command, not a new agent invocation
- [ ] Coverage check respects --yolo (Block) vs interactive (ask user)

### Phase 3 specific

- [ ] Test infra uses dynamic ports (no hardcoded port numbers)
- [ ] Spec-reviewer --verify mode is clearly separated from review mode
- [ ] Verify mode is read-only (no code modifications)
- [ ] Scaffold pipeline step ordering is correct (spec compliance before E2E)

### Phase 4 specific

- [ ] New `agents/acceptance-gate.md` follows Goal → Expertise → Process → Constraints structure
- [ ] acceptance-gate agent is read-only (sonnet model)
- [ ] Gate condition is correct: AC >= 3 OR complexity >= M (for bugs)
- [ ] Gate always runs for features (no condition)
- [ ] implement-feature.md steps renumbered correctly (6g→6h, new 6g = acceptance gate)
- [ ] fix-bugs.md steps renumbered correctly (new 7b, old 7b→7c, old 7c→7d)
- [ ] fix-ticket.md steps renumbered correctly (new 8b, old 8b→8c, old 8c→8d)
- [ ] NEEDS_DECOMPOSITION limit is enforced (max 1 per ticket)
- [ ] Partial changes are reverted before NEEDS_DECOMPOSITION signal (fixer best-effort + command authoritative)

### Phase 5 specific

- [ ] GWT is preferred, not mandatory (rule-oriented accepted for NFRs)
- [ ] Spec-reviewer flags non-GWT as WARN, not BLOCK
- [ ] Quality scorecard is informational (does not block scaffold)
- [ ] Scorecard check #8 gracefully handles missing S3 (Phase 3)
