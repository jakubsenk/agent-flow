# Phase 2 Research Answers — Agent 3 (CRQ-9 through CRQ-12)

**Researcher:** Agent 3 (CRQ-9–12, P2/MEDIUM)
**Date:** 2026-04-13

---

## CRQ-9: Fixer scope containment — no check against architect's file list

### Finding Summary

There is no automated enforcement that the fixer stays within the `files` list defined for a subtask by the architect. The context passed to fixer (Step 6b) includes "architectural design + subtask scope + acceptance criteria" but the `files` list from the subtask is passed only as information, not as a constraint. The reviewer checklist does not include a file-scope check. Therefore, a fixer working on subtask 2 can freely modify files declared for subtask 3 with no automated detection or warning.

### Evidence Table

| File | Line | Quote | Severity |
|------|------|-------|----------|
| `skills/implement-feature/SKILL.md` | 447–449 | `"Run the fixer agent (Task tool, model: opus): Context: architectural design + subtask scope + acceptance criteria"` | HIGH — no mention of enforcing `files` list |
| `skills/implement-feature/SKILL.md` | 438–439 | `"Build context for fixer: entire decomposition plan + summary of previous subtasks (what changed, why, diff summary) + current subtask (scope, files, acceptance criteria)."` | MEDIUM — `files` passed as informational context only, not as a restriction |
| `skills/implement-feature/SKILL.md` | 529–541 | Step 6i commit (`git add -A`) — all changes committed without scope validation | HIGH — `git add -A` captures any file the fixer touched, regardless of subtask `files` list |
| `agents/reviewer.md` | 29–43 | Reviewer checklist: Root cause, Completeness, Conventions, Regressions, Security, Performance, Over-engineering, AC fulfillment — no file-scope check | HIGH — no checklist item for "did fixer stay within subtask.files?" |
| `agents/architect.md` | 55–66 | Task tree schema defines `files: [path/to/file1.ext, ...]` per subtask | INFO — files are planned but no downstream enforcement |
| `agents/fixer.md` | 33–46 | Fixer ESCAPE HATCH triggers on "≥4 files" but checks scope, not subtask file list | MEDIUM — heuristic is raw count, not cross-subtask collision |

### Specific Recommendation

Add a file-scope validation step between 6b (fixer) and 6c (post-fix hook): after each fixer run, diff the changed files (`git diff --name-only HEAD`) and compare against the current subtask's `files` list. If any changed file belongs to a *future* subtask's `files` list (i.e., a file not in the current subtask's list that appears in any later subtask), emit a HIGH reviewer finding or require fixer to revert. This check should be implemented in `skills/implement-feature/SKILL.md` as a new step "6b-scope-check" and documented in `core/fixer-reviewer-loop.md` as an optional scope constraint parameter.

---

## CRQ-10: fixer-reviewer-loop.md context contract documentation gap

### Finding Summary

The `fixer-reviewer-loop.md` Input Contract describes `context` as "Bug report or spec + AC + code-analyst output" (a single definition covering both pipelines). In the feature pipeline, code-analyst never runs and architect provides the structural context instead. The contract does not separately define what "context" means in the feature case, creating an implicit reliance on calling code to assemble the correct context shape without a documented contract.

### Evidence Table

| File | Line | Quote | Severity |
|------|------|-------|----------|
| `core/fixer-reviewer-loop.md` | 9 | `"context \| string \| required \| Bug report or spec + AC + code-analyst output"` | HIGH — describes only bug context shape; "code-analyst output" is not available in feature pipeline |
| `core/fixer-reviewer-loop.md` | 12 | `"acceptance_criteria \| list \| [] \| AC list from triage-analyst output"` | MEDIUM — source attribution is "triage-analyst output", which does not exist in feature pipeline (should be spec-analyst) |
| `skills/implement-feature/SKILL.md` | 463–465 | `"Run the reviewer agent (Task tool, model: opus): Context: diff from fixer + acceptance criteria from spec-analyst"` — follows loop but contradicts loop's documented AC source | MEDIUM — inconsistency between loop contract and actual caller |
| `skills/implement-feature/SKILL.md` | 447–449 | `"Run the fixer agent: Context: architectural design + subtask scope + acceptance criteria"` — no code-analyst output mentioned | INFO — correct practice for feature pipeline but undocumented in the loop contract |
| `core/fixer-reviewer-loop.md` | 3–6 | Purpose: "Iterative fixer↔reviewer loop with configurable limits and acceptance criteria checking" — no mention of pipeline-type variants | LOW — missing pipeline-type distinction at contract level |

### Specific Recommendation

Update `core/fixer-reviewer-loop.md` Input Contract to explicitly define two context shapes as a discriminated union:

```
context_type: "bug" | "feature"  (required — determines how context is assembled)

Bug context:  bug_report + triage_analysis + code_analyst_output + AC (from triage-analyst)
Feature context: specification + architect_design + subtask_scope + AC (from spec-analyst)
```

Also update the `acceptance_criteria` field note from "AC list from triage-analyst output" to "AC list from triage-analyst (bug) or spec-analyst (feature)". This removes the implicit coupling and makes the contract self-documenting for both callers.

---

## CRQ-11: Decomposition-heuristics.md requires code-analyst fields

### Finding Summary

`core/decomposition-heuristics.md` defines an Input Contract that requires `code_analyst_output` with fields `risk`, `affected_files`, `estimated_diff_lines`, and `independent_changes`. The feature pipeline (`implement-feature`) never runs code-analyst — it calls architect instead. Step 5 of `implement-feature/SKILL.md` calls decomposition validation inline without invoking `core/decomposition-heuristics.md` via a Task dispatch, instead implementing its own validation logic. However, the decomposition heuristic contract's Failure Handling clause provides a safe fallback: "Missing or incomplete `code_analyst_output` fields → treat missing numeric fields as 0, missing `risk` as LOW → default to `SINGLE_PASS`." This means the feature pipeline would silently fall back to SINGLE_PASS if the heuristic contract were invoked — but in practice the feature pipeline does not use the heuristic at all for its AUTO mode.

### Evidence Table

| File | Line | Quote | Severity |
|------|------|-------|----------|
| `core/decomposition-heuristics.md` | 8–13 | `"code_analyst_output \| object \| Fields: risk (LOW/MEDIUM/HIGH), affected_files (integer), estimated_diff_lines (integer), independent_changes (integer)"` | HIGH — contract requires code-analyst data; feature pipeline has none |
| `core/decomposition-heuristics.md` | 39 | `"Missing or incomplete code_analyst_output fields → treat missing numeric fields as 0, missing risk as LOW → default to SINGLE_PASS (safe fallback)."` | MEDIUM — fallback exists but is silent; no warning emitted |
| `skills/implement-feature/SKILL.md` | 200–244 | Step 5 "Decomposition decision" — inline validation (cycle check, topological sort, max_subtasks, AC coverage) without referencing `core/decomposition-heuristics.md` for AUTO logic | HIGH — the feature pipeline implements its own decomposition decision logic that contradicts what the heuristics contract documents |
| `skills/implement-feature/SKILL.md` | 198–199 | `"If decompose_mode = FORCE or decompose_mode = AUTO and architect indicates decomposition"` — AUTO decision delegated to the architect's recommendation, not to heuristic thresholds | HIGH — AUTO mode in feature pipeline is architect-driven, not metrics-driven; creates a fork in documented behavior |
| `core/decomposition-heuristics.md` | 34 | Output Contract: `"DECOMPOSE → Run architect agent..."` references `skills/fix-ticket/SKILL.md` steps 4b–4c, not implement-feature | MEDIUM — heuristics document is bug-pipeline-specific; feature pipeline is undocumented in the contract |

### Specific Recommendation

The contract gap is real but the runtime impact is muted because the feature pipeline bypasses `core/decomposition-heuristics.md` entirely. The fix has two options:

1. **Document the split:** Update `core/decomposition-heuristics.md` to explicitly state it applies to the bug pipeline only. Add a note: "Feature pipeline: decomposition decision is architect-driven (see `skills/implement-feature/SKILL.md` Step 5). The heuristic thresholds in this contract do not apply."

2. **Generalize the contract:** Add a `source` field (`"code-analyst"` | `"architect"`) to the Input Contract and add an `AUTO (architect)` branch to the Process section that uses architect's recommendation signal instead of numeric thresholds.

Option 1 is lower risk and aligns with existing implementation. It removes the ambiguity without changing behavior.

---

## CRQ-12: State.json field reuse and AC source ambiguity

### Finding Summary

Both the bug pipeline (via triage-analyst) and the feature pipeline (via spec-analyst) write acceptance criteria to `triage.acceptance_criteria` in state.json. The `mode` field (`"code-bugfix"` vs `"code-feature"`) is present in state.json and could be used by consumers to infer the AC source, but no documentation or schema comment explicitly states that `triage.acceptance_criteria` has dual provenance. Downstream consumers (acceptance-gate, reviewer, resume-ticket) receive AC from state without a source tag, creating potential ambiguity in tooling that reads state files across multiple pipeline runs.

### Evidence Table

| File | Line | Quote | Severity |
|------|------|-------|----------|
| `state/schema.md` | 167–168 | `"triage.acceptance_criteria \| string[] \| No \| [] \| Full AC text items, preserved for resume."` — no mention of dual provenance or source tag | HIGH — schema does not document that this field is also written by spec-analyst in feature mode |
| `state/schema.md` | 59–66 | `triage` object is named after the bug pipeline's triage-analyst phase; no feature-mode alias or note | MEDIUM — naming implies bug-pipeline semantics for all modes |
| `skills/implement-feature/SKILL.md` | 182–183 | `"Update state.json: set triage.status to 'completed' (field reused for spec-analyst AC), write spec-analyst AC list to triage.acceptance_criteria."` | HIGH — explicit acknowledgment of field reuse ("field reused") but only as a code comment, not in the schema |
| `agents/spec-analyst.md` | 51–63 | Spec-analyst Step 5 outputs structured specification including Acceptance Criteria list — these are what get written to `triage.acceptance_criteria` | INFO — correct behavior, wrong field name |
| `agents/triage-analyst.md` | 72–88 | Triage-analyst Step 9 outputs `Acceptance Criteria` for bugs — these are also written to `triage.acceptance_criteria` | INFO — correct field, named for this agent |
| `state/schema.md` | 143–145 | `"mode \| string \| Yes \| — \| One of: code-bugfix, code-feature, code-project, analysis, strategy, content."` | LOW — mode field exists and could disambiguate AC source, but no consumer documentation instructs them to use it |

### Specific Recommendation

Two complementary fixes:

1. **Add `triage.ac_source` field to state.json schema:** A string field (values: `"triage-analyst"` | `"spec-analyst"`) written alongside `triage.acceptance_criteria`. Update `skills/implement-feature/SKILL.md` Step 3 to write `ac_source: "spec-analyst"` and bug pipeline to write `ac_source: "triage-analyst"`. Update `state/schema.md` to document both the field and the dual-provenance pattern.

2. **Add schema annotation to `triage.acceptance_criteria`:** In `state/schema.md`, update the description to: "Full AC text items, preserved for resume. In `code-bugfix` mode: populated by triage-analyst. In `code-feature` mode: populated by spec-analyst (field reused). Use `triage.ac_source` to determine provenance programmatically."

This preserves backward compatibility (same field path) while making the dual-use contract explicit and machine-readable.
