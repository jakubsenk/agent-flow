# Phase 2 Research Answers: CRQ-5 through CRQ-8

**Agent:** 2 (Specialist: Agent Identity and Pipeline Role Gaps)
**Date:** 2026-04-13
**Priority:** P1/HIGH

---

## CRQ-5: Fixer role identity and TDD step mismatch for feature work

### Finding Summary

The fixer agent's identity, goal, expertise, and TDD step are entirely anchored to bug-fix semantics. When used in the feature pipeline, this creates a conceptual mismatch: the agent is told to "solve the root cause" and "write a test that reproduces the bug" when there is no bug or root cause — it is implementing new functionality from a spec. This mismatch risks under-scoping (treating a feature as a minimal patch) and confusing TDD framing (RED phase instructs writing a test that "reproduces the bug" and "confirm it FAILS").

### Evidence Table

| File | Line | Exact Text | Severity |
|------|------|-----------|----------|
| `agents/fixer.md` | 3 | `description: Implements minimal, correct bug fixes targeting root cause. Surgical changes with backwards compatibility.` | HIGH — frontmatter description shown in agent picker; anchors identity to bug fixes only |
| `agents/fixer.md` | 8 | `You are a Senior Developer specializing in surgical bug fixes.` | HIGH — role identity explicitly excludes feature implementation |
| `agents/fixer.md` | 12 | `Minimal correct fix that solves the root cause. Simplest solution that doesn't break anything.` | HIGH — Goal is entirely bug-fix framed; "root cause" concept does not apply to feature work |
| `agents/fixer.md` | 16 | `Root cause analysis, defensive coding, backwards compatibility, minimal diffs.` | MEDIUM — Expertise list has no mention of feature implementation, API design, or spec-driven development |
| `agents/fixer.md` | 20 | `Read the triage analysis and impact report thoroughly. If triage analysis or impact report is missing, Block with reason 'Missing input from previous pipeline stage'.` | HIGH — Step 1 reads bug-specific artifacts; in feature pipeline these do not exist. The Block condition on missing triage analysis would trigger incorrectly if fixer is not passed the right context label. |
| `agents/fixer.md` | 29 | `RED: Write a test that reproduces the bug. Run it — confirm it FAILS. If the test passes, your test does not capture the actual bug; rewrite it.` | HIGH — Step 5 RED phase instructs writing a test to reproduce a bug. In feature context there is no bug; fixer has no guidance for writing a test that verifies new behavior before implementing it. |
| `agents/fixer.md` | 30 | `GREEN: Implement the minimal fix to make the failing test pass. Target root cause, not symptoms. Smallest possible change.` | MEDIUM — "minimal fix" and "root cause" framing may cause the agent to under-implement feature scope, treating spec requirements as symptoms to minimize rather than behaviors to build. |
| `agents/fixer.md` | 84 | `On failure: revert changes, Block using the Block Comment Template: Agent: fixer / Step: Fix Implementation` | LOW — Block comment template says "Fix Implementation" even for feature subtasks; cosmetically inaccurate but not functionally harmful. |

### Specific Recommendation

**Short term:** Add a context-switch preamble in `implement-feature` SKILL.md that explicitly instructs the fixer: "You are implementing a feature subtask, not fixing a bug. Your goal is to implement the specification below. Replace 'root cause' with 'spec requirement' throughout your process. In Step 5 RED phase, write a test that verifies the new behavior described in the AC — not a bug reproduction test."

**Long term:** The fixer agent definition should be refactored to support dual-mode operation. Add a `## Feature Mode` section with parallel goal/expertise/TDD framing, activated by context. Alternatively, create a separate `implementer` agent for feature subtasks and reserve `fixer` strictly for bug-fix pipelines. The agent `description` frontmatter field should not say "bug fixes" as it appears in the agent picker and misleads orchestration.

---

## CRQ-6: Reviewer reads bug-specific artifacts — silent quality degradation

### Finding Summary

The reviewer's Step 1 instructs it to read "the original bug report, triage analysis, impact report" — none of which exist in the feature pipeline. Additionally, the review checklist item "Does the fix address the actual root cause?" is semantically inapplicable to feature work. However, the reviewer does have sufficient fallback mechanisms: it reads the actual code changes, applies the full adversarial checklist, and the AC Fulfillment section is driven by whatever AC was provided in context (spec-analyst AC in feature mode). The degradation is real but partial — the reviewer can still produce meaningful reviews by relying on AC context and code reading, but Step 1 will silently operate on missing inputs.

### Evidence Table

| File | Line | Exact Text | Severity |
|------|------|-----------|----------|
| `agents/reviewer.md` | 20 | `Read the original bug report, triage analysis, impact report, and the fixer's output (changed files, approach, reasoning)` | HIGH — Step 1 reads three bug-specific artifacts that do not exist in feature pipeline. No fallback or graceful handling is specified for missing inputs. |
| `agents/reviewer.md` | 31 | `Root cause: Does the fix address the actual root cause, not just symptoms?` | MEDIUM — Checklist item "root cause vs symptoms" is meaningless for feature work; reviewer cannot meaningfully apply this criterion, risking it being skipped silently or applied nonsensically. |
| `agents/reviewer.md` | 32 | `Completeness: Are all affected paths covered (from impact report)?` | MEDIUM — References impact report, which does not exist in feature pipeline. Completeness check becomes unanchored — reviewer must infer scope from code alone. |
| `agents/reviewer.md` | 33 | `Regressions: Could this break existing callers (from impact report)?` | MEDIUM — Impact report referenced again for regression analysis. Without it, regression scope assessment is reduced to code reading only. |
| `agents/reviewer.md` | 37-41 | `AC fulfillment: For each acceptance criterion from triage/spec analysis: FULFILLED / PARTIALLY / NOT ADDRESSED` | LOW — The AC Fulfillment section correctly references both triage AND spec analysis, meaning it does activate correctly in feature mode. This is the one cross-pipeline-safe part of the review checklist. |
| `agents/reviewer.md` | 108 | `If acceptance criteria were provided in context, MUST include AC Fulfillment section in output. If no AC provided, skip the section.` | LOW — This constraint correctly generalizes across pipelines. AC Fulfillment will fire in feature mode if spec-analyst AC is passed in context. |
| `core/fixer-reviewer-loop.md` | 6 | `Dispatch ceos-agents:reviewer (Task tool, model: opus) with fixer's changes + AC list.` | LOW — The loop correctly passes the AC list to the reviewer. The reviewer will have AC context in feature mode. However, it does not differentiate between bug and feature context for the checklist items. |
| `core/fixer-reviewer-loop.md` | 13 | `context: Bug report or spec + AC + code-analyst output` | MEDIUM — Input contract exposes the dual-mode design intent ("Bug report or spec") but does not specify what the reviewer should do differently when spec mode is active. |

### Specific Recommendation

**Short term:** Add a conditional in `core/fixer-reviewer-loop.md` input contract: when context is spec-driven (feature mode), pass `mode: feature` to the reviewer. In `agents/reviewer.md` Step 1, add: "If bug report or triage analysis is absent, this is a feature implementation review — skip root cause check, replace with 'Does the implementation match the spec requirement?'"

**Long term:** The review checklist in Step 4 should be split into a shared section (conventions, security, performance, over-engineering, AC fulfillment) and a bug-specific section (root cause, regression via impact report). The bug-specific section should be explicitly gated on the presence of bug artifacts in context.

---

## CRQ-7: Test-engineer reads "bug report" and requires "regression test"

### Finding Summary

The test-engineer's frontmatter description, Goal, and Step 1 are partially anchored to bug-fix semantics ("bug report," "regression"), but the agent has sufficient generality in Steps 3-5 to function adequately in feature context. The required test in Step 3 is labeled "regression test" but is described as "verifying the specific behavior that was fixed" — which a LLM can interpret as "verifying the specific behavior that was implemented." The agent will likely under-specify its test plan framing but produce functionally correct feature tests. The key issue is Step 1 reading the "bug report" and Step 3 calling the primary test a "regression test" — in feature mode, these labels are wrong, but the underlying behavior they drive (write a test for the changed behavior) is still valid.

### Evidence Table

| File | Line | Exact Text | Severity |
|------|------|-----------|----------|
| `agents/test-engineer.md` | 3 | `description: Writes and runs unit tests verifying the fix and preventing regressions. Follows project test framework conventions.` | MEDIUM — Frontmatter description says "verifying the fix and preventing regressions" — feature work is not a fix. Misleading identity, but not functionally blocking. |
| `agents/test-engineer.md` | 11 | `Write tests that verify the fix AND prevent future regressions. Clear, deterministic, maintainable tests.` | MEDIUM — Goal says "verify the fix" — in feature mode there is no fix. The goal is to verify new behavior. Agent will likely adapt via context but the framing is wrong. |
| `agents/test-engineer.md` | 20 | `Read the bug report, fixer output (changed files, root cause), and impact report (test coverage section)` | HIGH — Step 1 reads three bug-specific artifacts. In feature pipeline, there is no bug report or impact report. Unlike the reviewer, the test-engineer has no fallback behavior specified for missing inputs. Silently operating on absent artifacts risks the agent fabricating or hallucinating bug context. |
| `agents/test-engineer.md` | 25 | `Required: One test verifying the specific behavior that was fixed (regression test)` | MEDIUM — Labeled "regression test" — in feature context, this test is a behavior verification test, not a regression test. The label is wrong, but the instruction ("verify the specific behavior") is general enough to be applicable. |
| `agents/test-engineer.md` | 26 | `Recommended: One test for the most likely edge case from the impact report` | MEDIUM — References impact report which does not exist in feature pipeline. Edge case test becomes unanchored — agent must infer from code alone. |
| `agents/test-engineer.md` | 45 | `Reference checklist: checklists/test-checklist.md — use as validation gate.` | LOW — If the test checklist also contains bug-specific references, this compounds the framing issue. (Not verified in this research pass.) |

### Specific Recommendation

**Short term:** In `implement-feature` SKILL.md Step 6e, add explicit context override when invoking test-engineer: "Context: changed files, acceptance criteria. Note: this is a feature implementation, not a bug fix. There is no bug report or impact report. Write tests that verify the new behavior described in the acceptance criteria. The 'regression test' in Step 3 means a test that verifies the new feature behavior is correctly implemented."

**Long term:** Refactor the test-engineer's Step 1 to handle missing artifacts gracefully: "If bug report is not present, proceed with AC and fixer output only (feature mode)." Rename the "regression test" in Step 3 to "primary behavior test" or add a parenthetical: "(regression test for bug fixes; behavior verification test for features)." The Goal should also be updated to say "verify the implemented behavior" rather than "verify the fix."

---

## CRQ-8: Acceptance gate skipped in single-pass feature mode

### Finding Summary

The acceptance gate skip in single-pass mode is documented but its justification relies entirely on the reviewer's AC Fulfillment section being sufficient — which is a reasonable design decision for small features, but creates an asymmetry: decomposed features always get AC gate verification with code+test evidence citations (file:line), while single-pass features get only the reviewer's text-based AC Fulfillment verdict without the acceptance-gate's mandatory evidence traceability. This is an intentional design tradeoff, but it is undocumented as a tradeoff and may silently allow single-pass features to ship with unverified AC.

### Evidence Table

| File | Line | Exact Text | Severity |
|------|------|-----------|----------|
| `skills/implement-feature/SKILL.md` | 519 | `For features, the acceptance gate always runs within the subtask loop (no threshold condition — unlike bugs, which require ≥3 AC or complexity ≥M). In single-pass mode (no decomposition), this step is skipped.` | HIGH — The skip is explicitly stated but provides no rationale. Why does single-pass not need the gate? The sentence contrast ("always runs...In single-pass mode...skipped") is self-contradictory in phrasing: it says the gate "always runs" then immediately says it is skipped in single-pass mode. |
| `skills/implement-feature/SKILL.md` | 527 | `Update state.json: set acceptance_gate.status to "completed" (or "skipped" for single-pass)` | MEDIUM — The state schema acknowledges the skip but does not require any compensating mechanism (e.g., reviewer AC Fulfillment must be present). |
| `agents/acceptance-gate.md` | 11-12 | `Verify that every acceptance criterion is fulfilled by the implementation with specific code and test evidence. Produce a structured verification report.` | HIGH — The acceptance-gate's value is specific code:test evidence traceability — not available from the reviewer. Single-pass features bypass this entirely. |
| `agents/acceptance-gate.md` | 28-30 | `Find evidence in code: cite specific file:line where the AC is addressed / Find evidence in tests: cite test file and test function name that verifies this AC` | HIGH — The acceptance-gate mandates file:line code evidence AND test function citation. The reviewer's AC Fulfillment (lines 37-41 of reviewer.md) produces only text verdicts (FULFILLED/PARTIALLY/NOT ADDRESSED) with one-line "evidence" notes — not the same standard. |
| `agents/acceptance-gate.md` | 58 | `If no acceptance criteria are provided in context → output: "No AC provided. Cannot verify." and APPROVE` | LOW — Graceful fallback when AC are absent. This constraint applies equally in all modes. |
| `agents/reviewer.md` | 37-41 | `AC fulfillment: For each acceptance criterion from triage/spec analysis: FULFILLED / PARTIALLY / NOT ADDRESSED` | MEDIUM — Reviewer AC Fulfillment is a lighter-weight check: it checks whether the fix "demonstrably satisfies" each AC but does not require citing file:line evidence. In single-pass mode, this is the only AC gate. |
| `agents/reviewer.md` | 73-76 | `AC Fulfillment: {AC text} → {FULFILLED\|PARTIALLY\|NOT ADDRESSED} — {evidence}` | MEDIUM — The `{evidence}` field is freeform in the reviewer output template; the acceptance-gate format mandates `{file:line evidence, test name}`. The traceability standard is materially lower in reviewer-only mode. |

### Specific Recommendation

**Short term:** Document the single-pass skip explicitly as a design tradeoff in the SKILL.md comment: "Single-pass features rely on the reviewer's AC Fulfillment section as a lighter-weight gate. This is acceptable for small features (single-pass implies limited scope) but reduces evidence traceability." This converts a silent behavior into a documented decision.

**Medium term:** Add a compensating requirement for single-pass mode: when the acceptance gate is skipped, the reviewer MUST provide file:line evidence in its AC Fulfillment section (not just a text verdict). This can be enforced by passing the reviewer an extra instruction in single-pass feature context: "Since acceptance-gate is skipped in single-pass mode, your AC Fulfillment section MUST cite specific file:line evidence for each FULFILLED verdict."

**Long term:** Consider removing the single-pass exception entirely and running the acceptance gate in all feature modes. The acceptance-gate is read-only and fast (sonnet model); the cost of running it in single-pass mode is negligible compared to the AC traceability benefit. The current skip may have been introduced to reduce pipeline length for small features, but the asymmetry in evidence quality is a latent quality risk.
