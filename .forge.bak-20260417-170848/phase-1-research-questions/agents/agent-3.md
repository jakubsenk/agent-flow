# Research Questions — Work Item 4: LOW Documentation Fixes

Agent: agent-3
Phase: Phase 1 — Research Questions

---

## File Inventory

All five target files were read in full before generating these questions.

---

## Q1: fix-verification.md — Where does "Fix verification" appear?

**File:** `core/fix-verification.md`

The phrase "Fix verification" appears in **three distinct locations within the file**, none of which is the document title (H1 = `# fix-verification`):

1. **Line 26 — failure comment template (output text sent to the issue tracker):**
   ```
   [ceos-agents] ❌ Fix verification failed.
   ```
2. **Line 30 — Display message shown to the user:**
   ```
   Display: "Fix verification failed. Issue re-opened."
   ```
3. **Lines 19–23 — success comment template also uses "Fix verified"** (line 22):
   ```
   [ceos-agents] ✅ Fix verified. Verify command: `{command}`. Output: {first 500 chars}.
   ```

The H1 title (`# fix-verification`) uses the slug form (no space, lowercase), which is neutral. The file has no section headers using "Fix verification."

**Research question:** Should "Fix verification failed" in the failure comment (line 26) and the display message (line 30) be changed to "Verification failed"? And should "Fix verified" in the success comment (line 22) become "Verified"? Or is "Fix verification" acceptable in output strings that are written by the contract (not the title), since they are machine-parseable tags?

---

## Q2: fix-verification.md — What other files reference this contract by name?

**Files referencing `fix-verification` or `core/fix-verification.md`:**

- `skills/fix-ticket/SKILL.md` — dispatches this contract
- `skills/fix-bugs/SKILL.md` — dispatches this contract
- `skills/implement-feature/SKILL.md` — dispatches this contract
- `docs/plans/roadmap.md` (line ~608) — records this fix as a roadmap item
- `tests/scenarios/verify-fail.sh` — tests verify step existence

The three pipeline skills all call `fix-verification.md` via `core/fix-verification.md`. The success comment template text `[ceos-agents] ✅ Fix verified.` appears in the issue tracker comment on all three pipelines, including the feature pipeline — where the work was NOT a fix but a feature implementation. Similarly, `[ceos-agents] ❌ Fix verification failed.` is posted even when a feature verification fails, which is confusing framing.

**Research question:** The comment templates in lines 22 and 26 are what users actually see in their issue tracker. Should they use mode-neutral language like `[ceos-agents] ✅ Verified.` / `[ceos-agents] ❌ Verification failed.`? Or should the contract accept a mode parameter to customize the wording per pipeline type?

---

## Q3: state-manager.md — What is the forward reference and what does it actually describe?

**File:** `core/state-manager.md`, **line 42:**
```
- Fall back to heuristic detection (see resume-ticket.md existing logic)
```

This line is in the **Resume Process** section, under the path "If state.json does not exist." It defers the description of the fallback heuristic to `resume-ticket.md` rather than defining it inline.

The actual heuristic is fully defined in `skills/resume-ticket/SKILL.md` under the section **"Heuristic Detection (Fallback)"** (lines 36–58). That section describes a 6-state checkpoint table:

| Checkpoint | Signal |
|-----------|--------|
| `FRESH` | No branch, no `[ceos-agents]` comments |
| `POST_TRIAGE` | Comment `[ceos-agents] Triage completed.` exists |
| `POST_ANALYSIS` | Branch exists + triage comment |
| `POST_FIX` | Branch with commits above base branch |
| `POST_REVIEW` | Branch + reviewer approval comment |
| `PUBLISHED` | Open PR exists for branch |

And a detection logic block:
```
if PR exists → PUBLISHED
else if decomposition YAML exists → DECOMPOSE_PARTIAL
else if branch has commits → POST_FIX (or POST_REVIEW)
else if branch + triage comment → POST_ANALYSIS
else if triage comment → POST_TRIAGE
else → FRESH
```

**Research question:** Should `core/state-manager.md` line 42 replace `(see resume-ticket.md existing logic)` with a compressed inline version of the checkpoint table (5–7 lines), so the state-manager contract is self-contained? Or should it reference `skills/resume-ticket/SKILL.md` explicitly (by full path, not just the file name) to avoid the ambiguous bare reference `resume-ticket.md`?

---

## Q4: state-manager.md — What heuristic detail should be inlined?

Building on Q3, the forward reference is to a heuristic that has two distinct parts:

1. **Checkpoint signal table** — how to detect the resume state from git + tracker signals
2. **Detection priority ordering** — the `if/else` decision tree

**Research question:** For the purpose of the state-manager contract, which part of the heuristic needs to be inlined? The state-manager's Resume Output contract already promises to return `resume_point` and `detection_method: "heuristic_fallback"`. The inlined text should be enough for an implementer to understand what logic produces those values without reading a separate file. Would a condensed sentence ("scan issue tracker comments and git branch state to infer the completed pipeline step") plus the 6-point checkpoint enum be sufficient?

---

## Q5: state/schema.md — What fields currently exist in e2e_test, and what is missing?

**File:** `state/schema.md`

The `e2e_test` section in the Full Schema Example (line 104–106) currently contains:
```json
"e2e_test": {
  "status": "pending"
}
```

The field definition table (lines 225–226) defines only:
- `e2e_test.status` — Phase status. See Step Status Enum.

**Missing fields compared to parallel sections:**

The `reproduction` section (lines 79–84 / definitions 184–188) defines: `status`, `script_path`, `result_path`, `verdict`.
The `browser_verification` section (lines 107–110 / definitions 228–230) defines: `status`, `result_path`, `verdict`.

The e2e-test-engineer agent (`agents/e2e-test-engineer.md`) produces an **E2E Test Report** (lines 59–64) with:
- Existing test count / pass count
- New test file paths and descriptions
- Auth handling method

The agent runs up to **3 attempts** before blocking (line 55, line 72). This means an `attempts` counter analogous to `test.attempts` / `test.max_attempts` is appropriate.

**Research question:** Should `e2e_test` gain the following three fields?
- `verdict`: string or null — `"PASSED"` or `"FAILED"` (parallel to `browser_verification.verdict` and `test.last_result`)
- `result_path`: string or null — path to the E2E test report JSON (parallel to `reproduction.result_path` and `browser_verification.result_path`)
- `attempts`: integer — number of completed E2E test attempts (parallel to `test.attempts`)

Are there additional fields from the agent output (e.g., `new_tests_count`, `framework`) that should also be persisted, or is the minimal trio (`verdict`, `result_path`, `attempts`) sufficient for resume and metrics?

---

## Q6: state/schema.md — Which triage.* and code_analysis.* fields are reused across pipeline modes?

**File:** `state/schema.md`; cross-references in `skills/*/SKILL.md`

The schema currently documents `triage.*` and `code_analysis.*` with only bug-fix mode semantics in their descriptions. However, the skills explicitly reuse these fields for different agent outputs in different modes:

| Field | Bug-fix mode | Feature mode | Scaffold mode |
|-------|-------------|--------------|---------------|
| `triage.status` | triage-analyst phase | spec-analyst phase | spec-writer phase |
| `triage.acceptance_criteria` | triage-analyst AC | spec-analyst AC list | AC count (integer written as list length) |
| `code_analysis.status` | code-analyst phase | architect output phase | scaffolder phase |

Evidence from skills:
- `skills/implement-feature/SKILL.md` line 189: `set triage.status to "completed" (field reused for spec-analyst AC)`
- `skills/implement-feature/SKILL.md` line 212: `set code_analysis.status to "completed" (field reused for architect output)`
- `skills/scaffold/SKILL.md` line 435: `set triage.status to "completed" (field reused for spec-writer phase)`
- `skills/scaffold/SKILL.md` line 484: `set code_analysis.status to "completed" (field reused for scaffolder phase)`

The schema definitions at lines 171–183 (triage) and 179–183 (code_analysis) do not mention this reuse. A reader consulting the schema alone would not know that `triage.status = "completed"` in a feature pipeline means the spec-analyst completed, not a triage-analyst.

**Research question:** Should the `triage` and `code_analysis` field definitions in `state/schema.md` each receive a note (similar to the `triage.ac_source` field description at line 178) explaining the mode-dependent semantics? Specifically, where in each field row should this note appear — in the `Description` column only, or also via a new "Mode Notes" subsection below the field table?

---

## Q7: state/schema.md — Where exactly should the mode-reuse note be placed?

**File:** `state/schema.md`, lines 171–183

The `triage.ac_source` field (line 178) already contains a multi-mode description:
> Origin of acceptance criteria: `"triage-analyst"` (bug-fix pipeline), `"spec-analyst"` (feature pipeline), `"spec-writer"` (scaffold pipeline), or `null`.

This sets a precedent for inline mode documentation within the Description column.

**Research question:** For `triage.status` and `code_analysis.status`, the Description column currently says only "Phase status. See Step Status Enum." Should this be expanded to:
> Phase status. See Step Status Enum. In bug-fix mode: triage-analyst phase. In feature mode: spec-analyst phase. In scaffold mode: spec-writer phase.

And similarly for `code_analysis.status`:
> Phase status. See Step Status Enum. In bug-fix mode: code-analyst phase. In feature mode: architect phase. In scaffold mode: scaffolder phase.

Is inline description the right approach, or would a separate "Field Reuse Across Modes" table section between the triage and code_analysis definitions be cleaner?

---

## Q8: fixer-reviewer-loop.md — Where does NEEDS_DECOMPOSITION appear and what does it currently reference?

**File:** `core/fixer-reviewer-loop.md`

`NEEDS_DECOMPOSITION` appears in three locations:

1. **Line 21 (Process step 3):**
   > If fixer output contains `## NEEDS_DECOMPOSITION` → return `NEEDS_DECOMPOSITION` immediately. Only allowed once per ticket; caller enforces the limit.

2. **Line 36 (Output Contract table):**
   > `NEEDS_DECOMPOSITION` | Fixer's decomposition rationale (passed through)

3. **Line 44 (Failure Handling):**
   > `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `skills/fix-ticket/SKILL.md` step 5).

**The problem:** Line 44 references only `skills/fix-ticket/SKILL.md` as the "caller." However, `NEEDS_DECOMPOSITION` is handled by three pipeline skills:
- `skills/fix-ticket/SKILL.md` (line 452)
- `skills/fix-bugs/SKILL.md` (line 470)
- `skills/implement-feature/SKILL.md` (line 482)

All three have nearly identical NEEDS_DECOMPOSITION handling blocks. The current reference to only `fix-ticket` is a partial enumeration that misleads readers into thinking NEEDS_DECOMPOSITION is only relevant to the bug-fix ticket pipeline.

**Research question:** Should line 44 be updated to list all three callers explicitly:
> `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and callers: `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`).

Or should line 21's `caller enforces the limit` language also be updated to name the three callers? Is there a reason that "Once per ticket" limit is enforced differently across the three skills?

---

## Q9: fixer-reviewer-loop.md — Does "Once per ticket" apply uniformly across all three callers?

**File:** `core/fixer-reviewer-loop.md` line 21; cross-references `skills/fix-ticket/SKILL.md` line 452, `skills/fix-bugs/SKILL.md` line 470, `skills/implement-feature/SKILL.md` line 482

The contract states: `Only allowed once per ticket; caller enforces the limit.`

**Research question:** All three pipeline skills handle NEEDS_DECOMPOSITION. Is the "once per ticket" enforcement consistent across all three? Specifically: does `fix-bugs` (which processes multiple tickets in a batch) enforce "once per run" or "once per individual ticket"? This distinction matters because the current contract language says "per ticket" but `fix-bugs` batch mode could theoretically encounter NEEDS_DECOMPOSITION on multiple tickets in the same run. The answer determines whether the updated NEEDS_DECOMPOSITION documentation should qualify the limit differently for batch vs. single-ticket callers.

---

## Summary of Target Changes Implied by Research

| # | File | Location | Current Text | Question Resolved By |
|---|------|----------|-------------|---------------------|
| Q1–Q2 | `core/fix-verification.md` | Lines 22, 26, 30 | "Fix verification"/"Fix verified" in output strings | Q1–Q2 |
| Q3–Q4 | `core/state-manager.md` | Line 42 | `(see resume-ticket.md existing logic)` forward ref | Q3–Q4 |
| Q5 | `state/schema.md` | Lines 104–106, 225–226 | `e2e_test` has only `status` | Q5 |
| Q6–Q7 | `state/schema.md` | Lines 171–183 triage, 179–183 code_analysis | No mode-reuse documentation | Q6–Q7 |
| Q8–Q9 | `core/fixer-reviewer-loop.md` | Lines 21, 44 | Only `fix-ticket` listed for NEEDS_DECOMPOSITION | Q8–Q9 |
