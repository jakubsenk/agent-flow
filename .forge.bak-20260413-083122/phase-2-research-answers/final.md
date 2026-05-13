# Phase 2 Research Answers — Final Synthesis

**Produced by:** Synthesis Agent
**Date:** 2026-04-13
**Input agents:** agent-1 (CRQ-1–4), agent-2 (CRQ-5–8), agent-3 (CRQ-9–12)
**Reference:** Phase 1 final.md (risk matrix), Phase 0 analysis.md

---

## 1. Executive Summary

Audit identifikoval celkem **12 problémů** ve sdílených agentech a core kontraktech pipeline `implement-feature`. Ze 12 zkoumaných CRQ jsou **4 potvrzeny jako BLOCKING** (nutno opravit před produkčním spuštěním), **4 jako HIGH** (opravit před GA verzí) a **4 jako MEDIUM** (technický dluh na follow-up). Nejkritičtěji jsou postiženy agenti **fixer** (3 BLOCKING problémy: hard Block na chybějící artefakty, neošetřený `NEEDS_DECOMPOSITION` signál a identity mismatch pro feature práci) a **rollback-agent** (1 BLOCKING: smoke-check není v trigger listu, git zůstává dirty). Sdílení agenti reviewer a test-engineer vykazují HIGH-severity degradaci kvality způsobenou bug-fix jazykem v process krocích, která reálně snižuje kvalitu feature review a testování. **Závěr: `implement-feature` NENÍ bezpečné spustit hromadně v aktuálním stavu** — jsou potřeba minimálně 4 P0 opravy k eliminaci rizika tvrdého Blocku, dirty git stavu a neošetřených signálů při decomposition módu.

---

## 2. Audit Verdicts Table

| CRQ | Severity | Status | Agent/File | One-line verdict |
|-----|----------|--------|-----------|-----------------|
| CRQ-1 | BLOCKING | CONFIRMED | `agents/fixer.md` Step 1 | Fixer hard-blocks on "missing triage analysis" — feature pipeline never produces this artifact |
| CRQ-2 | BLOCKING | CONFIRMED | `skills/implement-feature/SKILL.md` Steps 6b/6d/6e | No mode signal passed; shared agents infer context from absent artifacts only |
| CRQ-3 | BLOCKING | CONFIRMED | `skills/implement-feature/SKILL.md` Step 6b | `NEEDS_DECOMPOSITION` from fixer has no handler in implement-feature; signal falls through |
| CRQ-4 | BLOCKING | CONFIRMED | `agents/rollback-agent.md` + `core/block-handler.md` | smoke-check not in rollback trigger list; git dirty after smoke-check block |
| CRQ-5 | HIGH | CONFIRMED | `agents/fixer.md` (frontmatter, Goal, Step 5) | Fixer identity anchored to bug-fix; TDD RED phase instructs "reproduce the bug" in feature context |
| CRQ-6 | HIGH | PARTIALLY CONFIRMED | `agents/reviewer.md` Steps 1/2 | Reviewer reads bug-only artifacts silently; AC Fulfillment does activate correctly via fallback |
| CRQ-7 | HIGH | CONFIRMED | `agents/test-engineer.md` Steps 1/3 | Test-engineer reads missing bug report; "regression test" label wrong for feature work |
| CRQ-8 | HIGH | CONFIRMED | `skills/implement-feature/SKILL.md` Step 6h | Single-pass features skip acceptance-gate entirely; reviewer AC Fulfillment is lighter-weight gate |
| CRQ-9 | MEDIUM | CONFIRMED | `skills/implement-feature/SKILL.md` Step 6b/6i | No scope containment check; fixer can freely modify future-subtask files; `git add -A` commits all |
| CRQ-10 | MEDIUM | CONFIRMED | `core/fixer-reviewer-loop.md` | Input contract documents "code-analyst output" not available in feature pipeline; no dual-mode shape |
| CRQ-11 | MEDIUM | CONFIRMED | `core/decomposition-heuristics.md` | Feature pipeline bypasses heuristics entirely; contract undocumented as bug-only |
| CRQ-12 | MEDIUM | CONFIRMED | `state/schema.md` | `triage.acceptance_criteria` written by both triage-analyst and spec-analyst; no source tag in schema |

---

## 3. Detailed Findings

### CRQ-1: Fixer hard Block on missing triage/impact artifacts

- **Verdict:** CONFIRMED
- **Severity:** BLOCKING
- **Evidence:**
  - `agents/fixer.md:20` — `"If triage analysis or impact report is missing, Block with reason 'Missing input from previous pipeline stage'."`
  - `skills/implement-feature/SKILL.md:447–448` — Context provided is "architectural design + subtask scope + acceptance criteria" — none labeled "triage analysis" or "impact report"
  - `core/fixer-reviewer-loop.md:13` — Input contract acknowledges "Bug report or spec + AC" as alternatives, but the fixer agent itself does not reflect this flexibility
- **Impact:** Every invocation of fixer from implement-feature risks a hard Block because the specific artifact names the guard checks for are never produced by the feature pipeline. The fixer will not proceed; the pipeline stalls on Step 6b.
- **Recommendation:** Update `agents/fixer.md` Step 1 guard to: "If triage analysis (bug mode) OR architectural design + acceptance criteria (feature mode) are missing, Block." Add a mode-aware preamble in `implement-feature` SKILL.md Step 6b: "Context includes: Mode: feature-implementation. Replace 'triage analysis' with 'architectural design' and 'impact report' with 'subtask scope' throughout your process."

---

### CRQ-2: No pipeline mode signal to shared agents

- **Verdict:** CONFIRMED
- **Severity:** BLOCKING
- **Evidence:**
  - `skills/implement-feature/SKILL.md:447–448` — Fixer context: "architectural design + subtask scope + acceptance criteria" — no `mode` field
  - `agents/reviewer.md:20` — "Read the original bug report, triage analysis, impact report" — no mode branch
  - `agents/test-engineer.md:20` — "Read the bug report, fixer output (changed files, root cause), and impact report" — no mode branch
- **Impact:** All three shared agents (fixer, reviewer, test-engineer) attempt to read bug-pipeline artifacts when invoked from implement-feature. Without an explicit mode signal, agents rely on LLM inference from artifact absence — an unreliable heuristic that degrades output quality and risks incorrect behavior across all three quality gates.
- **Recommendation:** Prepend `Mode: feature-implementation` to the context string passed when dispatching fixer, reviewer, and test-engineer from implement-feature. Add a mode-branch to each agent's Step 1: "If Mode is feature-implementation, substitute 'architectural design' for 'triage analysis', 'subtask scope' for 'impact report', and 'spec requirement' for 'root cause' throughout this process." Long term: refactor shared agents to accept a generic "problem statement + AC" vocabulary that is pipeline-agnostic.

---

### CRQ-3: NEEDS_DECOMPOSITION from feature subtask — no handler

- **Verdict:** CONFIRMED
- **Severity:** BLOCKING
- **Evidence:**
  - `core/fixer-reviewer-loop.md:22–23` — "If fixer output contains ## NEEDS_DECOMPOSITION → return NEEDS_DECOMPOSITION immediately. Only allowed once per ticket; caller enforces the limit."
  - `core/fixer-reviewer-loop.md:43–44` — "NEEDS_DECOMPOSITION → returned to caller; caller handles decomposition logic (see core/decomposition-heuristics.md and skills/fix-ticket/SKILL.md step 5)."
  - `skills/implement-feature/SKILL.md:447–464` — Step 6b/6d handle only: build failure, reviewer APPROVE/REQUEST_CHANGES. No `NEEDS_DECOMPOSITION` branch.
- **Impact:** When fixer emits NEEDS_DECOMPOSITION during a feature subtask, the signal propagates back to implement-feature Step 6b which has no handler. Most likely: fixer's NEEDS_DECOMPOSITION output is passed to the reviewer as a Fix Report, causing confused reviewer output, or the pipeline reaches an undefined state. In decomposition mode (multiple subtasks), partial git commits from prior subtasks exist with no rollback path for the failing subtask.
- **Recommendation:** Add a `NEEDS_DECOMPOSITION` branch in `implement-feature` Step 6b after the fixer-reviewer loop returns. In single-pass mode: Block with "Feature scope exceeds fixer limits — re-run with `--decompose` flag or split the feature into smaller issues." In decomposition mode per-subtask: Block that subtask and proceed (if `fail-strategy: continue`) or halt the pipeline (if `fail-strategy: fail-fast`). Mirror the handler from `fix-ticket/SKILL.md` Step 5 as the reference implementation.

---

### CRQ-4: Smoke-check Block leaves git dirty

- **Verdict:** CONFIRMED
- **Severity:** BLOCKING
- **Evidence:**
  - `skills/implement-feature/SKILL.md:472–477` — "Run Build command via Bash. If it fails → Block handler (step X) with agent = smoke-check"
  - `core/block-handler.md:21` — "If the blocking agent is fixer, reviewer, or test-engineer → dispatch ceos-agents:rollback-agent" — smoke-check absent
  - `agents/rollback-agent.md:25–28` — "If the blocking agent is fixer, test-engineer, e2e-test-engineer, or reviewer → proceed with rollback" — smoke-check absent from both lists
- **Impact:** When smoke check fails post-fixer+reviewer approval, the block handler fires but rollback is skipped. In single-pass mode: uncommitted fixer changes remain in working tree. In decomposition mode: prior subtask commits are clean but current subtask's uncommitted changes remain. On resume, the pipeline starts with a dirty git state, causing unpredictable behavior.
- **Recommendation:** Two complementary fixes: (1) Add `smoke-check` to the rollback trigger condition in `core/block-handler.md` Step 1. (2) Add `smoke-check` to the proceed-with-rollback allowlist in `agents/rollback-agent.md` Step 1. Better long-term: switch rollback-agent from allowlist to denylist — specify agents that should NOT trigger rollback (triage-analyst, code-analyst, spec-analyst, architect, stack-selector, publisher, scaffolder); all others (including smoke-check and any future agents) default to rollback.

---

### CRQ-5: Fixer role identity and TDD step mismatch for feature work

- **Verdict:** CONFIRMED
- **Severity:** HIGH
- **Evidence:**
  - `agents/fixer.md:3` — Frontmatter description: "Implements minimal, correct bug fixes targeting root cause. Surgical changes with backwards compatibility." — shown in agent picker
  - `agents/fixer.md:8` — "You are a Senior Developer specializing in surgical bug fixes."
  - `agents/fixer.md:29` — "RED: Write a test that reproduces the bug. Run it — confirm it FAILS. If the test passes, your test does not capture the actual bug; rewrite it."
- **Impact:** In feature context, fixer's TDD RED phase instructs it to write a test for a bug that does not exist. The guard "if the test passes, your test does not capture the actual bug; rewrite it" can cause the fixer to discard valid feature tests that correctly pass on first write. The "minimal fix" and "root cause" identity anchors risk under-scoping feature implementations, treating spec requirements as symptoms to minimize rather than behaviors to build.
- **Recommendation:** Short term: Add context-switch preamble in `implement-feature` SKILL.md Step 6b: "You are implementing a feature subtask, not a bug fix. Replace 'root cause' with 'spec requirement' throughout. In Step 5 RED: write a test verifying the new behavior described in the AC — if this test passes immediately, it means your test correctly captures the expected behavior; do not rewrite it." Long term: Refactor `agents/fixer.md` to support dual-mode with a `## Feature Mode` section, or create a separate `implementer` agent for feature subtasks.

---

### CRQ-6: Reviewer reads bug-specific artifacts — silent quality degradation

- **Verdict:** PARTIALLY CONFIRMED
- **Severity:** HIGH
- **Evidence:**
  - `agents/reviewer.md:20` — "Read the original bug report, triage analysis, impact report, and the fixer's output" — three absent artifacts in feature mode
  - `agents/reviewer.md:31` — "Root cause: Does the fix address the actual root cause, not just symptoms?" — semantically inapplicable to feature work
  - `agents/reviewer.md:37–41` — AC Fulfillment section correctly references "triage/spec analysis" — this part activates correctly in feature mode
- **Impact:** The reviewer can still produce meaningful feature reviews because the AC Fulfillment section does fire from spec-analyst context, and the code-reading checklist items (conventions, security, performance, over-engineering) are pipeline-neutral. However, the root-cause and impact-report checklist items silently degrade: "Does the fix address root cause?" has no meaningful answer for feature code, and "completeness from impact report" is unanchored. Quality degradation is real but partial — not a total failure.
- **Recommendation:** Short term: Add mode-aware instruction in `core/fixer-reviewer-loop.md`: when context contains spec/feature artifacts, pass `Mode: feature` to reviewer. In `agents/reviewer.md` Step 1: "If bug report or triage analysis is absent, this is a feature review — skip root cause check; replace with 'Does the implementation match the spec requirement?'" Long term: Split Step 2 checklist into a shared section (conventions, security, performance, over-engineering, AC fulfillment) and a bug-specific section (root cause, impact report-based completeness), explicitly gated on artifact presence.

---

### CRQ-7: Test-engineer reads "bug report" and requires "regression test"

- **Verdict:** CONFIRMED
- **Severity:** HIGH
- **Evidence:**
  - `agents/test-engineer.md:20` — "Read the bug report, fixer output (changed files, root cause), and impact report (test coverage section)" — all three absent in feature mode
  - `agents/test-engineer.md:25` — "Required: One test verifying the specific behavior that was fixed (regression test)"
  - `agents/test-engineer.md:3` — Frontmatter: "Writes and runs unit tests verifying the fix and preventing regressions"
- **Impact:** Test-engineer in feature mode operates without its primary inputs (bug report, impact report). Step 3's required "regression test" label is wrong for feature work; the agent may hallucinate bug context or produce tests with incorrect framing. Unlike the reviewer, the test-engineer has no fallback behavior specified for missing inputs. The scope constraint ("1-3 focused tests") may under-test feature implementations that require integration or workflow tests.
- **Recommendation:** Short term: In `implement-feature` SKILL.md Step 6e, add: "Note: this is a feature implementation. There is no bug report or impact report. Write tests verifying the new behavior in the AC. The 'regression test' in Step 3 means a test verifying the new feature behavior is correctly implemented." Long term: Update `agents/test-engineer.md` Step 1 to handle missing artifacts gracefully ("If bug report not present, proceed with AC and fixer output only — feature mode") and rename "regression test" to "primary behavior test" with a parenthetical for mode context.

---

### CRQ-8: Acceptance gate skipped in single-pass feature mode

- **Verdict:** CONFIRMED
- **Severity:** HIGH
- **Evidence:**
  - `skills/implement-feature/SKILL.md:519` — "In single-pass mode (no decomposition), this step is skipped." — contrasts with the opening "always runs within the subtask loop"
  - `skills/implement-feature/SKILL.md:527` — State: `acceptance_gate.status = "skipped"` for single-pass with no compensating mechanism
  - `agents/acceptance-gate.md:28–30` — Gate mandates specific `file:line` code evidence AND test function citation; reviewer AC Fulfillment produces only text verdicts
- **Impact:** Single-pass features (the most common path for simple features) have no dedicated acceptance-gate run. The reviewer's AC Fulfillment section provides only text-based verdicts without file:line evidence traceability. This creates an asymmetric quality standard: decomposed features get rigorous evidence-backed AC verification; single-pass features get lighter-weight text-only verification. Features that "just fit" in single-pass may ship with unverified AC and no audit trail.
- **Recommendation:** Short term: Document the single-pass skip explicitly in SKILL.md as a tradeoff comment. Add a compensating requirement: when acceptance-gate is skipped, the reviewer MUST provide file:line evidence in its AC Fulfillment (pass extra instruction: "Since acceptance-gate is skipped, your AC Fulfillment MUST cite specific file:line evidence for each FULFILLED verdict"). Medium term: Consider removing the single-pass exception — the acceptance-gate is read-only and fast (sonnet); cost is negligible versus AC traceability benefit.

---

### CRQ-9: Fixer scope containment — no check against architect's file list

- **Verdict:** CONFIRMED
- **Severity:** MEDIUM
- **Evidence:**
  - `skills/implement-feature/SKILL.md:438–439` — `files` list from subtask passed as informational context only, not as a constraint
  - `skills/implement-feature/SKILL.md:529–541` — `git add -A` commits all changed files without scope validation
  - `agents/reviewer.md:29–43` — Reviewer checklist has no item for "did fixer stay within subtask.files?"
- **Impact:** A fixer implementing subtask 2 can freely modify files declared for subtask 3. In decomposition mode, this causes cross-subtask interference: subtask 3's files are already partially modified when subtask 3's fixer runs, creating merge conflicts or inconsistent state. No automated detection or warning exists.
- **Recommendation:** Add a "6b-scope-check" step between Step 6b (fixer) and Step 6c (post-fix hook): run `git diff --name-only HEAD` and compare against current subtask's `files` list. If any changed file belongs to a future subtask's `files` list, emit a HIGH finding to the reviewer or require fixer to revert the out-of-scope changes. Document this as an optional `scope_constraint` parameter in `core/fixer-reviewer-loop.md`.

---

### CRQ-10: fixer-reviewer-loop.md context contract documentation gap

- **Verdict:** CONFIRMED
- **Severity:** MEDIUM
- **Evidence:**
  - `core/fixer-reviewer-loop.md:9` — `context | string | required | Bug report or spec + AC + code-analyst output` — code-analyst output not available in feature pipeline
  - `core/fixer-reviewer-loop.md:12` — AC source documented as "triage-analyst output" only; spec-analyst not mentioned
  - `skills/implement-feature/SKILL.md:463–465` — Reviewer receives "diff from fixer + acceptance criteria from spec-analyst" — contradicts loop contract's documented AC source
- **Impact:** Maintainers reading `core/fixer-reviewer-loop.md` cannot determine the correct context shape for feature pipeline invocations. The implicit coupling creates risk that future changes to the loop contract (bug-mode) inadvertently break feature-mode callers without detection.
- **Recommendation:** Update `core/fixer-reviewer-loop.md` Input Contract to define a discriminated union: `context_type: "bug" | "feature"`. Bug context: `bug_report + triage_analysis + code_analyst_output + AC (from triage-analyst)`. Feature context: `specification + architect_design + subtask_scope + AC (from spec-analyst)`. Update the `acceptance_criteria` field note from "triage-analyst output" to "triage-analyst (bug) or spec-analyst (feature)".

---

### CRQ-11: Decomposition-heuristics.md requires code-analyst fields not available in feature pipeline

- **Verdict:** CONFIRMED
- **Severity:** MEDIUM
- **Evidence:**
  - `core/decomposition-heuristics.md:8–13` — Requires `code_analyst_output` fields: `risk`, `affected_files`, `estimated_diff_lines`, `independent_changes`
  - `skills/implement-feature/SKILL.md:200–244` — Step 5 implements its own inline decomposition decision logic (cycle check, topological sort, max_subtasks, AC coverage) without invoking `core/decomposition-heuristics.md`
  - `core/decomposition-heuristics.md:39` — Fallback: "Missing fields → treat as 0/LOW → default to SINGLE_PASS" — silent, no warning
- **Impact:** The feature pipeline bypasses `core/decomposition-heuristics.md` entirely — so no runtime failure occurs. However, the contract is misleading: it appears to be a general-purpose decomposition contract but is bug-pipeline-specific. Maintainers adding feature-pipeline logic could incorrectly call the heuristic and get silent SINGLE_PASS fallbacks instead of architect-driven decisions.
- **Recommendation:** Option 1 (lower risk): Update `core/decomposition-heuristics.md` to explicitly state it applies to the bug pipeline only. Add: "Feature pipeline: decomposition decision is architect-driven (see `skills/implement-feature/SKILL.md` Step 5). The heuristic thresholds in this contract do not apply." Option 2 (generalize): Add `source: "code-analyst" | "architect"` field to Input Contract with an `AUTO (architect)` branch using architect's recommendation signal.

---

### CRQ-12: State.json field reuse and AC source ambiguity

- **Verdict:** CONFIRMED
- **Severity:** MEDIUM
- **Evidence:**
  - `state/schema.md:167–168` — `triage.acceptance_criteria` documented without mention of dual provenance
  - `skills/implement-feature/SKILL.md:182–183` — Explicitly writes spec-analyst AC to `triage.acceptance_criteria` with comment "field reused" — acknowledged only as a code comment
  - `state/schema.md:59–66` — `triage` object named after bug pipeline's triage-analyst phase; no feature-mode alias or note
- **Impact:** Downstream consumers of state.json (`/status`, `/resume-ticket`, acceptance-gate) receive AC without a source tag. In most cases this is harmless (AC content is functionally equivalent). However, tooling that parses state across multiple pipeline runs or uses the `triage` namespace for logic gating could misinterpret feature AC as bug AC. The `mode` field in state.json exists and could disambiguate, but no consumer documentation instructs them to use it.
- **Recommendation:** (1) Add `triage.ac_source` field to `state/schema.md`: string, values `"triage-analyst"` | `"spec-analyst"`. Update `skills/implement-feature/SKILL.md` Step 3 to write `ac_source: "spec-analyst"` and bug pipeline to write `ac_source: "triage-analyst"`. (2) Update `state/schema.md` `triage.acceptance_criteria` description to: "Full AC text items. In `code-bugfix` mode: populated by triage-analyst. In `code-feature` mode: populated by spec-analyst (field reused). Use `triage.ac_source` to determine provenance programmatically."

---

## 4. Agents NOT Dispatched by implement-feature but Worth Noting

The following agents are dispatched by **all three main pipelines** (scaffold, fix-ticket/fix-bugs, implement-feature) and the findings from this audit have cross-pipeline implications:

### fixer, reviewer, test-engineer (shared across all bug + feature pipelines)
The identity and process-step vocabulary fixes recommended for CRQ-1/2/5/6/7 affect **both** `fix-ticket/fix-bugs` and `implement-feature`. Any refactoring of these agents must preserve bug-pipeline semantics. A mode-branch approach (as recommended) is safer than a vocabulary replacement — it adds feature-mode handling without altering bug-mode behavior.

### rollback-agent (shared, dispatched by block-handler across all pipelines)
The CRQ-4 smoke-check gap affects any pipeline that invokes the Block handler with `agent = smoke-check`. The scaffold pipeline also runs build validation steps — if it uses a similar block-handler invocation, it may share this vulnerability. **Recommendation: adopt the denylist approach for rollback-agent** so all future pipelines automatically get correct rollback behavior without explicit allowlist maintenance.

### acceptance-gate (also used in fix-ticket conditionally)
CRQ-8's finding (single-pass skip) is specific to implement-feature. In fix-ticket, the gate runs conditionally (AC ≥ 3 or complexity ≥ M). The asymmetry between feature single-pass (always skip) and bug conditional (threshold-based) is an existing architectural decision — but the compensating requirement for reviewer file:line evidence in single-pass mode would be a net quality improvement with no cross-pipeline risk.

### spec-analyst (feature-only) vs triage-analyst (bug-only)
These agents post AC to different places: spec-analyst posts a separate `[ceos-agents] Acceptance Criteria:` comment to the tracker; triage-analyst does not. This asymmetry is intentional per Phase 1 findings (F10) and requires no fix — but `/resume-ticket` should be verified to handle both formats when resuming feature vs. bug tickets.

---

## 5. Prioritized Action Plan

### P0 — Before production use (must fix before running implement-feature in bulk)

These four issues cause pipeline stalls, dirty git state, or undefined behavior:

1. **CRQ-1 — Fixer hard Block guard** (`agents/fixer.md` Step 1)
   - Add mode-aware guard: accept "architectural design + AC" as valid input in feature mode
   - Add `Mode: feature-implementation` preamble in `implement-feature` SKILL.md Step 6b

2. **CRQ-2 — No pipeline mode signal** (`skills/implement-feature/SKILL.md` Steps 6b/6d/6e)
   - Prepend `Mode: feature-implementation` to context for all shared agent dispatches
   - Add mode-branch to Step 1 of fixer, reviewer, test-engineer

3. **CRQ-3 — NEEDS_DECOMPOSITION unhandled** (`skills/implement-feature/SKILL.md` Step 6b)
   - Add NEEDS_DECOMPOSITION branch after fixer-reviewer loop returns
   - Single-pass: Block with re-run guidance; decomposition: per-subtask Block + continue/fail-fast

4. **CRQ-4 — Smoke-check rollback gap** (`core/block-handler.md` + `agents/rollback-agent.md`)
   - Add `smoke-check` to trigger conditions in both files
   - Preferred: switch rollback-agent to denylist approach

### P1 — Before GA (significant quality degradation, fix for quality release)

5. **CRQ-5 — Fixer TDD mismatch** (`agents/fixer.md` Step 5, frontmatter)
   - Add feature-mode preamble in `implement-feature` SKILL.md Step 6b overriding RED-phase instructions
   - Long term: dual-mode fixer agent or separate implementer agent

6. **CRQ-6 — Reviewer bug-artifact reads** (`agents/reviewer.md` Steps 1/2)
   - Add mode signal to `core/fixer-reviewer-loop.md`; mode-branch in reviewer Step 1
   - Gate bug-specific checklist items on artifact presence

7. **CRQ-7 — Test-engineer bug-artifact reads** (`agents/test-engineer.md` Steps 1/3)
   - Add feature-mode note in `implement-feature` SKILL.md Step 6e
   - Update test-engineer Step 1 to handle missing artifacts gracefully

8. **CRQ-8 — Single-pass acceptance-gate skip** (`skills/implement-feature/SKILL.md` Step 6h)
   - Document skip as an explicit tradeoff
   - Add compensating instruction: reviewer MUST provide file:line evidence in single-pass feature AC Fulfillment

### P2 — Follow-up (technical debt, maintainability)

9. **CRQ-9 — Fixer scope containment** (`skills/implement-feature/SKILL.md`)
   - Add 6b-scope-check step comparing `git diff --name-only` against subtask `files` list
   - Document as optional `scope_constraint` in `core/fixer-reviewer-loop.md`

10. **CRQ-10 — Loop contract documentation gap** (`core/fixer-reviewer-loop.md`)
    - Add discriminated union context shapes for bug vs. feature mode
    - Update AC source attribution to include spec-analyst

11. **CRQ-11 — Decomposition-heuristics bug-only scope** (`core/decomposition-heuristics.md`)
    - Add explicit note: "This contract applies to the bug pipeline only"
    - Document architect-driven decision path for feature pipeline

12. **CRQ-12 — State.json AC source ambiguity** (`state/schema.md`)
    - Add `triage.ac_source` field with values `"triage-analyst"` | `"spec-analyst"`
    - Update schema annotation for `triage.acceptance_criteria`

---

## 6. Updated Risk Matrix

Cells: **CRITICAL** (confirmed blocking) / **HIGH** (confirmed quality degradation) / **MEDIUM** (confirmed tech debt) / **LOW** (cosmetic) / `—` (no issue)

| Agent / Contract | Bug-Fix Language | Missing Artifact Guard | NEEDS_DECOMP Handling | AC Mechanism | Scope Containment | Rollback Safety |
|---|---|---|---|---|---|---|
| **fixer** | **CRITICAL** ✓ | **CRITICAL** ✓ (hard Block confirmed) | HIGH ✓ | MEDIUM | — | — |
| **reviewer** | HIGH ✓ | HIGH ✓ (silent, partial fallback) | — | MEDIUM (single-pass: LOW quality) | — | — |
| **test-engineer** | HIGH ✓ | HIGH ✓ (no fallback specified) | — | MEDIUM | — | — |
| **e2e-test-engineer** | LOW | LOW | — | — | — | — |
| **acceptance-gate** | — | — | — | HIGH ✓ (single-pass skip confirmed) | — | — |
| **rollback-agent** | — | — | — | — | — | **CRITICAL** ✓ (smoke-check absent) |
| **implement-feature (skill)** | — | **CRITICAL** ✓ (no mode signal) | **CRITICAL** ✓ (no handler) | MEDIUM | MEDIUM ✓ | HIGH ✓ |
| **fixer-reviewer-loop (core)** | — | — | HIGH ✓ (refs fix-ticket only) | — | — | — |
| **block-handler (core)** | — | — | — | — | — | HIGH ✓ (smoke-check absent) |
| **decomposition-heuristics (core)** | — | MEDIUM ✓ (bypassed, not called) | — | — | — | — |
| **state.json schema** | — | — | — | MEDIUM ✓ (no ac_source field) | — | — |
| **architect** | — | — | — | — | — | — |
| **spec-analyst** | — | — | — | LOW (token asymmetry, acceptable) | — | — |

**Changes from Phase 1 Risk Matrix:**
- CRQ-6 (reviewer) downgraded from CRITICAL to HIGH — AC Fulfillment does activate correctly via fallback; degradation is partial, not total
- CRQ-11 (decomposition-heuristics) confirmed MEDIUM but muted — feature pipeline bypasses the contract entirely, so no runtime failure occurs
- All CRITICAL items (CRQ-1 through CRQ-4) fully confirmed; no false positives in Phase 1 assessment

---

## 7. Overall Verdict

**Is `implement-feature` safe to run in bulk right now?**

**No.** There are four BLOCKING issues that cause predictable pipeline failures:

1. **Fixer will hard-Block** on missing "triage analysis" — preventing Step 6b from completing in most feature invocations (CRQ-1).
2. **NEEDS_DECOMPOSITION has no handler** — if fixer emits this signal during a subtask, implement-feature reaches undefined behavior (CRQ-3).
3. **Smoke-check Block leaves git dirty** — after smoke-check failure, the branch is in an inconsistent state that cannot be resumed cleanly (CRQ-4).
4. **No mode signal means fragile inference** — all three shared quality agents (fixer, reviewer, test-engineer) must guess their context from absent artifacts (CRQ-2).

**Minimum fix required to unblock bulk use:**
Fix CRQ-1 and CRQ-2 together (mode signal + guard update) — this is a single coordinated change across `agents/fixer.md`, `agents/reviewer.md`, `agents/test-engineer.md`, and `skills/implement-feature/SKILL.md`. Then fix CRQ-3 (add NEEDS_DECOMPOSITION handler in Step 6b) and CRQ-4 (add smoke-check to rollback trigger lists). These four P0 fixes can be made in one focused PR without architectural redesign.

**After P0 fixes:** The pipeline becomes functionally safe for bulk use, but will produce lower-quality output than the bug pipeline due to P1 gaps (fixer TDD mismatch, reviewer/test-engineer silent degradation, single-pass AC gate bypass). P1 fixes improve quality and should be completed before a GA release. P2 items are technical debt and maintainability improvements with no immediate runtime impact.

**Estimated fix scope:** P0 = ~4 files, ~20 targeted edits. P1 = ~6 files, ~30 targeted edits. P2 = ~4 files, ~20 targeted edits (mostly documentation). Total: roughly 10 files across all three priority levels.
