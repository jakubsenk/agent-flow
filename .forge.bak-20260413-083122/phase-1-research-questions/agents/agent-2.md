# Phase 1 Research: Context Flow & AC Mechanism (RQ-2, RQ-4)

**Agent:** agent-2
**Focus:** How implement-feature passes context to each agent; AC format consistency between spec-analyst and triage-analyst; acceptance-gate dual-source handling; mismatches between what skills pass and what agents expect.

---

## Refined Research Questions

### RQ-2: Context Flow — What Artifacts Does implement-feature Pass, and in What Format?

**RQ-2.1** Does implement-feature pass the full spec-analyst output to the architect, or only the extracted `acceptance_criteria` list?

**RQ-2.2** Does implement-feature tell the fixer whether it is operating in a bug-fix context or a feature context? The fixer's Process step 1 reads "triage analysis and impact report" — neither of which exist in the feature pipeline. Does the skill compensate?

**RQ-2.3** Does implement-feature tell the reviewer whether it is in feature vs bug-fix context? The reviewer's checklist explicitly references "triage analysis" and "impact report" in step 1. What happens when those are absent?

**RQ-2.4** The acceptance-gate is told in step 6h: `Context: Acceptance criteria: {AC from spec-analyst — full feature AC, not just per-subtask AC}`. Who resolves this expansion — the skill or the agent? Is the full AC list serialized into the Task context string, or does the agent re-read from state?

**RQ-2.5** In decomposition mode, the fixer context (step 6 preamble) includes "entire decomposition plan + summary of previous subtasks + current subtask". Who generates this summary? There is no summarizer agent — this is implied orchestration by the skill itself. Is this documented?

**RQ-2.6** The test-engineer receives `Context: changed files, acceptance criteria`. Which AC are passed — the subtask-level AC from the YAML, or the full parent AC from spec-analyst? The skill says "acceptance criteria" without specifying source.

---

### RQ-4: AC Mechanism — Are the Two AC Sources Compatible?

**RQ-4.1** AC list numbering: both pipelines place AC in `triage.acceptance_criteria` in state.json. But the field is semantically overloaded — for bugs it comes from triage-analyst, for features from spec-analyst. Is there a `source` tag? Could a resume-ticket or acceptance-gate accidentally read stale bug AC in a feature run?

**RQ-4.2** AC format from triage-analyst (step 9):
```
- **Acceptance Criteria:**
  1. {testable criterion — what must be true after the fix}
```
AC format from spec-analyst (step 5):
```
- **Acceptance Criteria:**
  1. {testable outcome}
```
Both produce numbered markdown lists. Format is visually identical. However, spec-analyst also posts AC to the issue tracker as a separate standalone comment (`[ceos-agents] Acceptance Criteria: ...`). Triage-analyst does NOT post this separate AC comment — it posts only the checkpoint line. Is this asymmetry intentional, and does it affect downstream consumers?

**RQ-4.3** Acceptance-gate step 1 reads: "Read the acceptance criteria from context (from triage-analyst for bugs, spec-analyst for features)." The gate itself is context-source-agnostic — it reads whatever is injected. The question is whether the skill injects the correct source in both pipelines:
- fix-ticket step 8c: `Context: Acceptance criteria: {AC from triage}.` — correct source named explicitly.
- implement-feature step 6h: `Context: Acceptance criteria: {AC from spec-analyst — full feature AC, not just per-subtask AC}.` — correct source named explicitly.
Both are explicit. No mismatch at the gate.

**RQ-4.4** The `maps_to` AC coverage check uses index-based matching: `AC-{N}: {text}`. This algorithm is identical in both pipelines (implement-feature step 5, fix-ticket step 4b). However, in fix-ticket the AC coverage check is conditional: "when AC are available from triage". In implement-feature the check is unconditional and can BLOCK in YOLO mode. Bug AC coverage is softer (user can skip). Feature AC coverage is harder (YOLO = hard block). Is this intentional asymmetry?

**RQ-4.5** Reviewer's AC Fulfillment section: the reviewer produces `AC Fulfillment` per-AC verdicts for BOTH bugs and features. The fixer-reviewer-loop.md input contract shows `acceptance_criteria: list` as a shared field. However, the reviewer's Process step 1 reads "the original bug report, triage analysis, impact report, and the fixer's output". No mention of spec-analyst output. In a feature context, there is no bug report, no triage analysis, no impact report. The reviewer has to infer feature context from whatever is passed. The reviewer is not explicitly told it is in a feature pipeline.

---

## Detailed Findings

### Finding 1: Fixer Is Written for the Bug-Fix Context

The fixer agent's Process, step 1 reads:
> "Read the triage analysis and impact report thoroughly. If triage analysis or impact report is missing, Block with reason 'Missing input from previous pipeline stage'."

In the feature pipeline, there is no triage-analyst and no code-analyst/impact report. The implement-feature skill passes to fixer (step 6b):
> `Context: architectural design + subtask scope + acceptance criteria`

This means the fixer will receive context that does NOT contain "triage analysis" or "impact report". Whether the fixer blocks depends on whether it interprets the architectural design as a valid substitute. The fixer definition gives no feature-specific handling. This is a **gap**: the fixer's blocking guard ("if missing, Block") could fire falsely in a feature run if the model interprets architectural design as not equivalent to an impact report.

The reviewer has the same problem (step 1 reads "bug report, triage analysis, impact report"). The skill passes "diff from fixer + acceptance criteria from spec-analyst" (step 6d). Neither a bug report nor a triage analysis nor an impact report is present.

### Finding 2: Architect Context Is Asymmetric Between Pipelines

In implement-feature (step 4), architect receives:
> `Context: specification from spec-analyst + access to code + Module Docs path`

In fix-ticket (step 4b), architect receives:
> `Context: code-analyst impact report + issue details + Module Docs path`
> `Instructions: "Decompose this bug into subtasks. Max {max_subtasks} subtasks."`

The architect's Process step 1 reads:
> "Read the specification (from spec-analyst for features, or impact report from code-analyst for bugs). If specification or impact report from previous pipeline stage is missing or incomplete, Block with reason 'Missing input from previous pipeline stage'."

The architect IS aware of both input types and has dual-source handling. This is correctly implemented. However, the explicit instruction "Decompose this bug into subtasks" is only passed in fix-ticket. For features, no equivalent instruction is passed — the architect is expected to infer from the specification that it should produce a task tree. The implement-feature step 4 expected output says "architectural design + task tree (YAML)" but this expectation is not reflected in the context passed to the agent. The architect's decomposition trigger (step 7) is heuristic-based, so this works in practice — but it relies on the architect's internal logic rather than an explicit instruction.

### Finding 3: State.json Field Reuse Creates Semantic Ambiguity

The implement-feature skill stores spec-analyst output in `triage.status` and `triage.acceptance_criteria` (step 3):
> "Update state.json: set `triage.status` to 'completed' (field reused for spec-analyst AC), write spec-analyst AC list to `triage.acceptance_criteria`."

The comment "field reused" is an inline acknowledgment of the semantic mismatch. For features, `triage.acceptance_criteria` holds spec-analyst output. For bugs, it holds triage-analyst output. The state schema does not distinguish between the two. If a tool (like `/status` or `/resume-ticket`) reads `triage.acceptance_criteria` and assumes bug context, it could misinterpret feature AC.

Similarly, `code_analysis.status` is "reused for architect output" in implement-feature (step 4). The semantic overloading is consistent (always reused in the same positions) but undocumented at the schema level.

### Finding 4: Acceptance Gate Is Skip-on-No-AC Safe, But Has a Feature-Specific Logic Bug

The acceptance-gate Constraints section states:
> "If no acceptance criteria are provided in context → output: 'No AC provided. Cannot verify.' and APPROVE"

This means if the skill fails to inject AC, the gate passes silently. This is a safe default.

However, implement-feature step 6h has a feature-specific behavior difference:
> "In single-pass mode (no decomposition), this step is skipped."

So in a feature single-pass run (the most common path for simple features), the acceptance-gate does NOT run at all. The only AC verification in single-pass feature mode comes from the reviewer's AC Fulfillment section (which is part of the fixer-reviewer loop). This is weaker than decomposition mode, which always runs the full acceptance-gate. This asymmetry is undocumented in the acceptance-gate agent itself — the gate does not know whether it's being run in decomposition vs single-pass context.

### Finding 5: Context Verbosity is Unspecified for Key Handoffs

The skill says agents receive "acceptance criteria" but never specifies the serialization format for the Task tool context string. For example:
- Does `{AC from spec-analyst}` inject the raw numbered markdown list from the agent output?
- Or does the skill extract only the items (strip the markdown header)?
- Is the full `## Feature Specification` block passed, or just the AC sub-list?

For the fixer-reviewer-loop.md, the input contract says `acceptance_criteria: list` — this suggests a structured list, not a raw markdown string. But the loop contract is a documentation contract, not a technical one (there is no runtime enforcement). The actual Task context is free-form prose. This means the fixer-reviewer loop's "AC list" is whatever the skill serializes into the context string.

### Finding 6: No Pipeline Mode Signal to Agents

No agent definition contains the phrase "feature pipeline" or "bug-fix pipeline" or any equivalent mode discriminator. Agents are expected to infer context from what is passed to them. The only place where an agent explicitly names both sources is:
- architect step 1: "(from spec-analyst for features, or impact report from code-analyst for bugs)"
- acceptance-gate step 1: "(from triage-analyst for bugs, spec-analyst for features)"

These two agents correctly handle dual-source inputs. All other agents (fixer, reviewer, test-engineer, publisher) have no feature/bug discrimination — they receive whatever context the skill passes and must work with it.

---

## AC Mechanism Comparison Table

| Property | triage-analyst (bugs) | spec-analyst (features) |
|---|---|---|
| AC count | 2-5 items (1-2 for trivial bugs) | 3-7 items |
| AC format | numbered markdown list | numbered markdown list |
| AC source | extracted or synthesized from bug report | extracted from ticket or inferred |
| AC writeback to tracker | NOT posted separately; only in checkpoint line | Posted as separate comment `[ceos-agents] Acceptance Criteria:` |
| AC stored in state.json | `triage.acceptance_criteria` | `triage.acceptance_criteria` (field reused) |
| AC passed to fixer | Yes, via skill context string | Yes, via skill context string |
| AC passed to reviewer | Yes, via fixer-reviewer-loop `acceptance_criteria` | Yes, via fixer-reviewer-loop `acceptance_criteria` |
| AC coverage check | Conditional (when decomposed AND AC available) | Unconditional (when decomposed); YOLO = hard block |
| Acceptance gate condition | Conditional (AC >= 3 OR complexity >= M) | Always (in decomposition); skipped in single-pass |
| Quality gate token | `Quality gate: PASS` / `Quality gate: UNCLEAR` | `Quality gate: PASS` / `Quality gate: incomplete` |

Note: The quality gate tokens differ: triage-analyst uses `UNCLEAR` (machine-readable, consumed by downstream skills); spec-analyst uses `incomplete` (no evidence it is machine-consumed). This may be intentional (triage UNCLEAR is explicitly described as a machine-readable signal; spec incomplete triggers a manual block and is not re-parsed downstream).

---

## Summary of Gaps and Risks

| # | Gap | Risk | Affected Agents |
|---|-----|------|-----------------|
| G1 | Fixer guard "if triage analysis or impact report is missing, Block" can fire in feature runs | Medium — fixer may false-block on missing triage/impact report | fixer |
| G2 | Reviewer reads "bug report, triage analysis, impact report" in step 1; none present in feature pipeline | Low-Medium — reviewer may lack context for adversarial review in feature mode | reviewer |
| G3 | `triage.acceptance_criteria` in state.json is semantically overloaded; no source tag | Low — tools reading state may misattribute AC source | state consumers, resume-ticket |
| G4 | Acceptance gate skipped in single-pass feature mode; only reviewer AC Fulfillment runs | Medium — feature single-pass has no dedicated AC gate | acceptance-gate |
| G5 | AC context serialization format unspecified for Task tool calls | Low — works in practice but not formally specified | all agents receiving AC |
| G6 | No explicit pipeline mode signal to fixer/reviewer/test-engineer | Low — agents infer from context; architect and acceptance-gate handle correctly | fixer, reviewer, test-engineer |
| G7 | spec-analyst quality gate token `incomplete` differs from triage `UNCLEAR` | Low — both trigger manual block; no known downstream consumer of `incomplete` token | spec-analyst callers |
