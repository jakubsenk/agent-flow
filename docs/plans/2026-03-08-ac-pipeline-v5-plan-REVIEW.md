# Code Review: AC-Driven Pipeline v5.0 Implementation Plan

**Date:** 2026-03-09
**Reviewer:** Senior Technical Reviewer (adversarial, ultra-deep)
**Target:** `2026-03-08-ac-pipeline-v5-plan.md` + `roadmap.md` + `README.md`
**Source:** `2026-03-08-ac-pipeline-evaluation.md` (28 sources, 22 proposals)
**Files read:** 24 (3 discussion docs, evaluation, plan, roadmap, README, CLAUDE.md, 8 agents, 4 commands)

---

## Review Summary

- **Verdict:** APPROVE (all findings addressed 2026-03-09)
- **Critical issues:** 2
- **Major issues:** 5
- **Minor issues:** 7

---

## Critical Issues (must fix before implementation)

### C1. [CRITICAL] Step 6g numbering collision in implement-feature.md

**File:** `2026-03-08-ac-pipeline-v5-plan.md`, Phase 4, B2/F6

The plan says "Add a new Step 6g after Step 6f (E2E test) and before Step 7 (Integration step)." But Step 6g already exists in `commands/implement-feature.md` (line 190) — it's "Commit subtask." An implementer following the plan literally would overwrite the commit step with the acceptance gate, breaking the pipeline.

**Proposed fix:** In Phase 4 B2/F6, change the implement-feature.md instruction to:

> "Renumber existing Step 6g (Commit subtask) → 6h. Add new Step 6g (Acceptance gate) after Step 6f (E2E test). Update single-pass reference from '6a–6d' to '6a–6e' if needed."

Also update the code review checklist Phase 4 to include:
> - [ ] implement-feature.md steps renumbered correctly (6g→6h, new 6g = acceptance gate)

**Status:** ☑ Done

---

### C2. [CRITICAL] Acceptance gate conflicts with reviewer's hardcoded constraints

**File:** `2026-03-08-ac-pipeline-v5-plan.md`, Phase 4, B2/F6

The acceptance gate invokes the reviewer with instructions "Do NOT raise code quality issues" and expects APPROVE when all AC pass with potentially 0 code issues. But `agents/reviewer.md` has hardcoded constraints:

- Line 49-55: "Issue count gate: You MUST identify at least 3 specific issues per review"
- Line 95: "NEVER approve with zero findings unless you provide an explicit per-checklist-item justification (minimum 7 checklist items addressed)"

These constraints are baked into the agent definition — they cannot be overridden by context instructions. The reviewer will either (a) ignore the gate context and hunt for 3 issues anyway, or (b) attempt to follow conflicting instructions and produce incoherent output.

**Proposed fix:** Create a new agent `agents/acceptance-gate.md` (agent count 15 → 16) instead of reusing the reviewer. This is a deliberate deviation from the evaluation's recommendation ("invoke reviewer with acceptance-gate instructions") for these reasons:

1. **Reviewer and gate have fundamentally different goals:** reviewer = adversarial code quality; gate = evidence-based AC fulfillment. These are different cognitive tasks that require different styles and constraints.
2. **Reviewer is already the most complex agent** — adding a mode with overridden constraints creates behavioral leakage risk (LLM still applies adversarial patterns in gate mode).
3. **Precedent is weak:** spec-reviewer's --verify mode is a natural extension (review spec → verify spec compliance). Reviewer's gate mode would be a role change.
4. **Maintenance cost of a new agent is near-zero** — the plugin is pure markdown, no build system.

Agent design:

```markdown
---
name: acceptance-gate
description: Verifies acceptance criteria are fulfilled by implementation. Maps each AC to code evidence and test coverage. Read-only.
model: sonnet
style: Evidence-driven, requirements-focused, systematic
---

You are a Requirements Fulfillment Analyst specializing in acceptance criteria verification.

## Goal

Verify that every acceptance criterion is fulfilled by the implementation with specific code and test evidence. Produce a structured verification report.

## Expertise

Requirements traceability, acceptance criteria analysis, evidence-based verification,
AC-to-code mapping, test coverage assessment.

## Process

1. Read the acceptance criteria from context (from triage-analyst for bugs, spec-analyst for features).
2. Read all changed files from the fixer's output. Understand what changed and why.
3. For each acceptance criterion:
   a. Identify verification method:
      - Behavioral AC ("When X, Then Y") → look for test that exercises this flow
      - Structural AC ("must use PostgreSQL") → look for configuration/code evidence
      - Performance AC ("response time < 200ms") → look for benchmark or test assertion
   b. Find evidence in code: cite specific file:line where the AC is addressed
   c. Find evidence in tests: cite test file and test function name that verifies this AC
   d. Assign verdict:
      - **FULFILLED** — code change + test evidence both present
      - **PARTIALLY** — code or test present but not both, or AC only partly addressed
      - **NOT ADDRESSED** — no code evidence found for this AC
      For structural/configuration AC (e.g., "must use PostgreSQL"), code/config evidence
      alone is sufficient — test evidence is not required.

4. Output:

   ## Acceptance Gate Report
   - **Verdict:** {APPROVE | REQUEST_CHANGES}
   - **AC:** {fulfilled}/{total} fulfilled, {partial} partial, {not_addressed} not addressed
   - **Details:**
     1. {AC text} → {FULFILLED|PARTIALLY|NOT ADDRESSED} — {file:line evidence, test name}
     2. {AC text} → {FULFILLED|PARTIALLY|NOT ADDRESSED} — {file:line evidence, test name}
   - **Summary:** {1-2 sentence assessment}

   Verdict rules:
   - Any NOT ADDRESSED → REQUEST_CHANGES with explanation of what's missing
   - All FULFILLED → APPROVE
   - Mix of FULFILLED + PARTIALLY → APPROVE (fixer may refine in next iteration)

## Constraints

- NEVER modify code — read-only verification only
- NEVER execute tests — test-engineer already did this; you verify test *existence*, not results
- NEVER raise code quality issues (style, conventions, over-engineering) — that is the reviewer's job
- NEVER produce a verdict without citing specific file:line evidence
- If no acceptance criteria are provided in context → output: "No AC provided. Cannot verify."
  and APPROVE (do not block the pipeline for missing AC)
- On failure: output report with findings so far — do not Block
```

Impact on the plan:
- Phase 4 B2/F6: replace all "invoke reviewer with acceptance-gate context" with "invoke acceptance-gate agent"
- CLAUDE.md changes: agent count 15→16, model selection table, read-only agents list, pipeline diagrams
- Test scenarios: update acceptance gate scenarios to reference the new agent
- Code review checklist: add "new agent file follows Goal→Expertise→Process→Constraints structure"

Full impact analysis will be done after all findings are reviewed and approved.

**Status:** ☑ Done

---

## Major Issues (should fix, risk of downstream problems)

### M1. [MAJOR] MAJOR version (v5.0.0) not justified by the project's own versioning policy

**File:** `2026-03-08-ac-pipeline-v5-plan.md`, Overview

The plan claims MAJOR because of "agent output format changes." But CLAUDE.md (line 182-188) defines:

> MAJOR = Breaking change in Automation Config contract — new required key, renamed section

None of the v5.0 changes add required config keys or rename sections. All agent output changes are additive (new fields/sections). The only arguably breaking change is the triage checkpoint comment format — but that's an internal protocol between commands, not the Automation Config contract.

Analysis of all output changes:
1. Triage-analyst: NEW fields (Acceptance Criteria, Complexity) — **additive**
2. Triage checkpoint comment: MODIFIED format (adding Complexity and AC count) — **internal protocol**
3. Reviewer: NEW optional section (AC Fulfillment) — **additive**, conditional
4. Architect: NEW field in YAML (maps_to) — **additive**
5. Spec-analyst: NEW comment (AC writeback) — **additive**
6. Spec-reviewer: NEW mode (--verify) — **additive**
7. Fixer: NEW output signal (NEEDS_DECOMPOSITION) — **additive**
8. Scaffolder: NEW output section (quality scorecard) — **additive**

Per the project's own policy, this is v4.2.0 (MINOR — new backward-compatible features).

**Proposed fix:** Extend the Versioning Policy. In plan section "CLAUDE.md Changes → Versioning Policy section", replace the current "Add a note" instruction with:

> Update the MAJOR row in the versioning table to:
>
> ```
> | MAJOR (X.0.0) | Breaking change in Automation Config contract — new required key, renamed section — OR breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse) | New required key in Issue Tracker; new output section in triage-analyst |
> ```
>
> This policy update itself justifies the MAJOR version: agent output formats are a contract consumed by Agent Overrides and external tooling.

Also update the "Why MAJOR version?" section in the plan Overview to reference the updated policy rather than claiming it's already covered.

**Status:** ☑ Done

---

### M2. [MAJOR] AC matching algorithm for F4 coverage check is under-specified

**File:** `2026-03-08-ac-pipeline-v5-plan.md`, Phase 2, F4

The plan says "This is a simple set-difference operation on the YAML data." But `maps_to` values are strings like `"AC-1: {text of the parent feature/bug AC}"` while parent AC are numbered list items (`1. {testable outcome}`). The plan never specifies how matching works:

- Exact string match?
- Parse "AC-N:" prefix and match by index?
- Fuzzy match on text content?

An implementer has at least 3 valid interpretations.

**Proposed fix:** Two changes:

1. In Phase 2 F4, replace "This is a simple set-difference operation on the YAML data." with:

> **AC matching algorithm:**
> - Each `maps_to` entry uses format `AC-{N}: {text}` where N is the 1-based index in the parent AC list
> - Coverage check: collect all N values from all subtasks' `maps_to` fields, verify that every integer from 1 to {total parent AC count} appears at least once
> - Text after `AC-N:` is informational (for human readability) — matching is by index only
> - If a `maps_to` entry cannot be parsed (no `AC-{N}:` prefix) → treat as warning, not error

2. In Phase 2 F3 (architect.md), add to the new constraint:

> - `maps_to` entries MUST use format `AC-{N}: {verbatim text from parent AC}` where N matches the parent AC numbering exactly. The architect MUST NOT renumber or reorder parent AC.

**Status:** ☑ Done

---

### M3. [MAJOR] F4 coverage check missing from scaffold pipeline

**File:** `2026-03-08-ac-pipeline-v5-plan.md`, Phase 2, F4

The plan adds AC coverage validation to:
- `implement-feature.md` (Step 5) ✓
- `fix-ticket.md` (Step 4b) ✓
- `fix-bugs.md` (Step 3b) ✓

But `commands/scaffold.md` Step 5 (Architecture & Decomposition) also runs the architect and produces a task tree with `maps_to`. No AC coverage check is added there. If the architect produces subtasks that don't cover all spec/epics AC, the scaffold pipeline won't catch it.

**Proposed fix:** Add a new subsection to Phase 2 F4:

```markdown
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
```

**Status:** ☑ Done

---

### M4. [MAJOR] Double-revert in NEEDS_DECOMPOSITION is unexplained

**File:** `2026-03-08-ac-pipeline-v5-plan.md`, Phase 4, B6

The fixer is instructed to "Revert any partial changes before outputting this signal." Then the command handling says "1. Revert any partial changes (git checkout .)". This means two separate revert operations. The plan doesn't explain why both are needed:

- If the fixer already reverted → command's revert is a no-op (harmless but confusing)
- If the fixer failed to revert (LLM didn't follow instructions) → command's revert is the safety net

The command's revert should be documented as the **primary** mechanism, not secondary.

**Proposed fix:** Two changes:

1. In the fixer agent section (B6), after "Revert any partial changes before outputting this signal", add:

> (best-effort — the orchestrating command performs its own authoritative revert as a safety net)

2. In both command handling sections (fix-ticket.md and fix-bugs.md), change:

> `1. Revert any partial changes (git checkout .)`

to:

> `1. Authoritative revert: git checkout . && git clean -fd (safety net — fixer's self-revert is best-effort and not guaranteed)`

**Status:** ☑ Done

---

### M5. [MAJOR] Reviewer verdicts inconsistent between review loop and acceptance gate

**File:** `2026-03-08-ac-pipeline-v5-plan.md`, Phase 1 vs Phase 4

Two different verdict scales for the same concept:
- Reviewer AC Fulfillment (Phase 1, B7/F5): `FULFILLED | PARTIALLY | NOT ADDRESSED`
- Acceptance gate (Phase 4, B2/F6): `PASS | FAIL | INCONCLUSIVE`

These are semantically overlapping but use different terms. An implementer reading both sections will be confused about which vocabulary to use.

**Proposed fix:** Unify on `FULFILLED | PARTIALLY | NOT ADDRESSED` everywhere in the reviewer (both review loop and acceptance gate). This scale is more precise and already established in Phase 1.

Concrete changes:
1. In Phase 4 B2/F6 acceptance gate context, replace `PASS | FAIL | INCONCLUSIVE` with `FULFILLED | PARTIALLY | NOT ADDRESSED`
2. Replace the gate verdict rules with:
   - Any NOT ADDRESSED → REQUEST_CHANGES
   - All FULFILLED → APPROVE
   - Mix of FULFILLED + PARTIALLY → APPROVE (fixer may refine)
3. Note: Spec-reviewer --verify (Phase 3 S1) intentionally uses a DIFFERENT scale: `IMPLEMENTED | PARTIALLY | MISSING` — this is correct because spec-reviewer checks "does code exist?" while reviewer checks "does fix satisfy the criterion?" Add an explicit note in Phase 3 S1:

> Note: Spec-reviewer --verify uses IMPLEMENTED/PARTIALLY/MISSING (implementation existence). Reviewer uses FULFILLED/PARTIALLY/NOT ADDRESSED (fix quality). Different scales for different purposes.

C2 already incorporates this — the new acceptance-gate agent uses FULFILLED/PARTIALLY/NOT ADDRESSED.

**Status:** ☑ Done

---

## Minor Issues (improve quality, low risk if ignored)

### m1. [MINOR] Step 7aa numbering is awkward

**File:** `2026-03-08-ac-pipeline-v5-plan.md`, Phase 4

Inserting step "7aa" between "7a" and "7b" in fix-bugs.md creates unusual sub-sub-numbering. Consider renumbering: 7a (E2E) → 7b (acceptance gate) → 7c (pre-publish hook), etc. This would require updating all downstream step references in the plan.

**Proposed fix:** Renumber in fix-bugs.md:
- 7a (E2E test) stays 7a
- NEW acceptance gate = 7b
- OLD 7b (Pre-publish hook) → 7c
- OLD 7c (Pre-publish custom agent) → 7d

Same pattern for fix-ticket.md:
- 8a (E2E test) stays 8a
- NEW acceptance gate = 8b
- OLD 8b (Pre-publish hook) → 8c
- OLD 8c (Pre-publish custom agent) → 8d

Update all references in the plan accordingly (the "skip to step 7b" references in fix-bugs, "skip to step 8b" in fix-ticket).

**Status:** ☑ Done

---

### m2. [MINOR] CLAUDE.md proposed Bug-Fix Pipeline diagram omits E2E test

**File:** `2026-03-08-ac-pipeline-v5-plan.md`, CLAUDE.md Changes

The proposed updated bug-fix diagram doesn't show E2E test engineer. The current CLAUDE.md diagram also omits it (consistent), but the v5.0 update is a good opportunity to add it for completeness.

**Proposed fix:** Change the proposed bug-fix diagram in the plan from:

```
  → [Post-fix hook + custom agent] → TEST ENGINEER (sonnet)
  → [Acceptance gate (conditional: AC ≥ 3 or complexity ≥ M)]
  → [Pre-publish hook + custom agent] → PUBLISHER (haiku)
```

to:

```
  → [Post-fix hook + custom agent] → TEST ENGINEER (sonnet)
  → [E2E test (optional)] → [Acceptance gate (conditional: AC ≥ 3 or complexity ≥ M)]
  → [Pre-publish hook + custom agent] → PUBLISHER (haiku)
```

**Status:** ☑ Done

---

### m3. [MINOR] Spec-reviewer --verify mode token cost not addressed

**File:** `2026-03-08-ac-pipeline-v5-plan.md`, Phase 3, S1

The verify mode reads "Source files in src/ (or equivalent)" and "Test files in tests/ (or equivalent)." For large codebases, this could consume significant tokens. The plan should specify a file count limit or instruct the agent to read only files referenced in spec/epics.

**Proposed fix:** In Phase 3 S1, change verify process step 2 from:

> 2. Read the implemented codebase:
>    - Source files in src/ (or equivalent)
>    - Test files in tests/ (or equivalent)
>    - Generated config files (CLAUDE.md, Dockerfile, CI config)

to:

> 2. Read the implemented codebase (selectively — do not read everything):
>    - For each AC: search for relevant files by keywords from the AC text (Grep/Glob)
>    - Read at most 20 source files and 10 test files total
>    - Prioritize files referenced in spec/architecture.md and epic descriptions
>    - Generated config files (CLAUDE.md, Dockerfile, CI config)

**Status:** ☑ Done

---

### m4. [MINOR] Triage AC quality concern from evaluation not addressed in plan

**File:** `2026-03-08-ac-pipeline-v5-plan.md`, Phase 1, B1

The evaluation (section 1.1) notes: "the quality of AI-generated AC is unproven at scale" and "no source describes AI-extracted AC flowing through an automated pipeline." The plan doesn't include a fallback or quality gate for poor triage AC. If triage-analyst (sonnet) produces vague AC, the downstream pipeline optimizes against bad criteria.

**Proposed fix:** In Phase 1 B1, after the new step 5b, add a note:

> **Quality safeguard:** If the bug report is too vague to produce meaningful AC (e.g., "it doesn't work" with no reproduction steps or expected behavior), the triage-analyst should Block per existing clarity validation (step 4, confidence < 50%) rather than synthesize speculative AC. Low-quality AC are worse than no AC — downstream agents would optimize against wrong criteria. The existing clarity gate is the first line of defense against poor AC quality.

**Status:** ☑ Done

---

### m5. [MINOR] Plan doesn't mention dropped proposals

**File:** `2026-03-08-ac-pipeline-v5-plan.md`

The plan covers the 12 implemented proposals but never mentions the 3 dropped proposals (F2, F8, S6) or the 3 deferred proposals (B4/F7/S4, B5, S7). An implementer reviewing the plan against the evaluation would need to cross-reference the evaluation to understand what was intentionally excluded. Adding a "Not included" section would improve clarity.

**Proposed fix:** Add a new section to the plan Overview, after "Dependency Graph":

```markdown
### Not Included

**Dropped (3 proposals — see evaluation section 4 "Drop" for rationale):**
- F2 (AC quality review step) — self-review bias; existing spec-reviewer covers this
- F8 (AC feedback loop) — high complexity, speculative benefit
- S6 (Batch integration AC) — unreliable to predict emergent integration issues

**Deferred to v5.1+ (3 proposals):**
- B4/F7/S4 (Manual verification mode) — proven CI/CD pattern but high complexity; defer until user demand
- B5 (Fix retrospective history) — validated by ACE paper (+8.6%); implement after core AC pipeline is stable
- S7 (/scaffold-iterate command) — wait for scaffold v2 usage data
```

**Status:** ☑ Done

---

### m6. [MINOR] Discussion documents still marked PROPOSED in README

**File:** `docs/plans/README.md`, lines 109-111

The three discussion documents are listed as `PROPOSED` but they've been processed by the evaluation and plan. Consider updating to `ARCHIVE` (supporting documents) to match the pattern of other source documents after consolidation.

**Proposed fix:** In `docs/plans/README.md`, change status of the three discussion docs:

| File | Current status | New status |
|------|---------------|------------|
| `2026-03-08-bugfix-pipeline-discuss.md` | PROPOSED | ARCHIVE |
| `2026-03-08-feature-pipeline-discuss.md` | PROPOSED | ARCHIVE |
| `2026-03-08-scaffold-pipeline-discuss.md` | PROPOSED | ARCHIVE |

**Status:** ☑ Done

---

### m7. [MINOR] Roadmap omits Nice-to-Have count

**File:** `docs/plans/roadmap.md`, line 76

Says "22 proposals → 12 unified + 3 dropped" but doesn't mention the 3 Nice-to-Have proposals deferred to v5.1+. The accounting is incomplete.

**Proposed fix:** In `docs/plans/roadmap.md`, change:

> `(28 sources, 22 proposals → 12 unified + 3 dropped)`

to:

> `(28 sources, 22 proposals → 12 unified + 3 deferred to v5.1+ + 3 dropped)`

**Status:** ☑ Done

---

## Architectural Concerns

### Acceptance gate as a "mode" of an existing agent is fragile

The plan reuses the reviewer agent to avoid increasing the agent count beyond 15. But the reviewer's core identity is adversarial code review with minimum issue requirements — repurposing it as a binary AC pass/fail checker requires suppressing its fundamental behavior via context instructions. LLMs are notoriously bad at "ignore your system prompt when context says X."

A more robust approach: either (a) add a dedicated section to reviewer.md defining acceptance-gate mode with its own process and constraints (making the behavioral switch part of the agent definition, not ephemeral context), or (b) accept a 16th agent as a small, focused AC verifier.

→ Addressed by proposed fix for C2 (option b — new dedicated acceptance-gate agent).

### NEEDS_DECOMPOSITION relies on LLM compliance for git cleanup

The fixer is instructed to "Revert any partial changes before outputting this signal." But LLMs frequently fail to follow multi-step cleanup instructions, especially when they've been coding for a while and their context is loaded with implementation details. The command's safety-net revert is essential, but the plan presents the fixer's revert as the primary mechanism and the command's as secondary. This should be inverted.

→ Addressed by proposed fix for M4 (command revert = authoritative, fixer revert = best-effort).

### The "AC-N:" naming convention in maps_to creates brittle coupling

If spec-analyst outputs 5 AC and later the list is reordered or one is removed during the spec-writer↔spec-reviewer loop, the AC numbers shift. The architect's maps_to references would then point to wrong criteria. The plan should specify whether AC-N refers to the original numbering or current numbering, and what happens if AC are renumbered between spec analysis and architecture design.

→ Partially addressed by M2 (architect MUST NOT renumber). Remaining risk: if spec-writer↔spec-reviewer loop changes AC order between iterations, the architect receives the final version and uses that numbering. This is acceptable because the architect only runs AFTER the spec is finalized. For bugs (triage-analyst), AC are produced once and never revised — no renumbering risk. No additional fix needed.

---

## Positive Observations

1. **Phase independence is well-designed.** Each phase is genuinely independently shippable with clear dependency documentation. Phase 4 correctly identifies its dependency on Phase 1. This enables incremental delivery and validation.

2. **The test scenarios table is comprehensive.** 22 test scenarios covering all 5 phases, with specific file names and verification criteria. This is unusually thorough for a plan document and will significantly reduce implementation ambiguity.

3. **The code review checklist is actionable.** Phase-specific checklist items (e.g., "maps_to is optional field — existing task trees without it still work") catch the exact types of implementation errors that plans like this typically produce. The general checklist items ("Agent frontmatter unchanged", "Process steps renumbered correctly") prevent the most common agent editing mistakes.
