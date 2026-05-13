# Phase 4 — Specification

## Context

You are writing the precise edit specification for the feature pipeline agent audit. The prior audit report is at `docs/plans/implement-feature-agent-audit-REVIEW.md` (12 CRQs). The brainstorm phase validated the inline mode-branch pattern (Approach A).

## Instructions

For each of the 10 files, produce an exact edit specification. Each edit must specify:
- **File:** absolute path
- **Location:** line numbers or unique string context for the edit
- **Current text:** the exact text to be replaced (or "INSERT AFTER {text}" for additions)
- **New text:** the exact replacement or addition
- **CRQ:** which audit finding this addresses
- **Priority:** P0 (BLOCKING) / P1 (HIGH) / P2 (MEDIUM)

## Files and Required Edits

### 1. `agents/fixer.md` (CRQ-1, CRQ-2, CRQ-5)

**Edit 1a — Frontmatter description (CRQ-5, P1):**
Update the description to be mode-neutral. Currently: "Implements minimal, correct bug fixes targeting root cause. Surgical changes with backwards compatibility."
New: Mention both bug fixes and feature implementations.

**Edit 1b — Role statement (CRQ-5, P1):**
Currently: "You are a Senior Developer specializing in surgical bug fixes."
Add mode-awareness without removing the bug-fix identity.

**Edit 1c — Goal (CRQ-5, P1):**
Currently: "Minimal correct fix that solves the root cause. Simplest solution that doesn't break anything."
Add feature-mode goal variant.

**Edit 1d — Step 1 guard (CRQ-1, P0):**
Currently: "Read the triage analysis and impact report thoroughly. If triage analysis or impact report is missing, Block..."
Add mode-branch: accept architectural design + AC as valid input in feature mode.

**Edit 1e — Step 5 TDD RED phase (CRQ-5, P1):**
Currently: "RED: Write a test that reproduces the bug. Run it — confirm it FAILS. If the test passes, your test does not capture the actual bug; rewrite it."
Add feature-mode TDD variant.

### 2. `agents/reviewer.md` (CRQ-2, CRQ-6, CRQ-8)

**Edit 2a — Step 1 artifact reading (CRQ-6, P1):**
Currently: "Read the original bug report, triage analysis, impact report, and the fixer's output..."
Add mode-branch for feature context.

**Edit 2b — Step 4 root cause checklist item (CRQ-6, P1):**
Currently: "Root cause: Does the fix address the actual root cause, not just symptoms?"
Add feature-mode variant.

**Edit 2c — Step 4 completeness checklist item (CRQ-6, P1):**
Currently: "Completeness: Are all affected paths covered (from impact report)?"
Add feature-mode variant.

**Edit 2d — AC Fulfillment compensating requirement (CRQ-8, P1):**
Add instruction: when acceptance-gate is skipped (single-pass feature mode), reviewer MUST provide file:line evidence in AC Fulfillment verdicts.

### 3. `agents/test-engineer.md` (CRQ-2, CRQ-7)

**Edit 3a — Step 1 artifact reading (CRQ-7, P1):**
Currently: "Read the bug report, fixer output (changed files, root cause), and impact report (test coverage section)"
Add mode-branch for feature context.

**Edit 3b — Step 3 regression test framing (CRQ-7, P1):**
Currently: "Required: One test verifying the specific behavior that was fixed (regression test)"
Add feature-mode variant.

**Edit 3c — Frontmatter description (CRQ-7, P1):**
Currently: "Writes and runs unit tests verifying the fix and preventing regressions."
Make mode-neutral.

### 4. `agents/e2e-test-engineer.md` (CRQ-2)

**Edit 4a — Step 1 artifact reading (CRQ-2, P1):**
Currently: "Read the bug report and fix diff — understand which user flow was affected"
Add mode-branch for feature context.

**Edit 4b — Goal (CRQ-2, P1):**
Currently: "E2E tests verifying the complete user flow affected by the fix. Prevent UI-level regressions."
Make mode-neutral.

### 5. `skills/implement-feature/SKILL.md` (CRQ-2, CRQ-3, CRQ-8)

**Edit 5a — Step 6b fixer dispatch: add Mode prefix (CRQ-2, P0):**
Currently: "Context: architectural design + subtask scope + acceptance criteria"
Prepend `Mode: feature-implementation.` to the context string.

**Edit 5b — Step 6b: add NEEDS_DECOMPOSITION handler (CRQ-3, P0):**
After the fixer-reviewer loop in Step 6b, add handler for NEEDS_DECOMPOSITION signal. Mirror fix-ticket/SKILL.md step 5 pattern.

**Edit 5c — Step 6d reviewer dispatch: add Mode prefix (CRQ-2, P0):**
Currently: "Context: diff from fixer + acceptance criteria from spec-analyst"
Prepend `Mode: feature-implementation.` to the context string.

**Edit 5d — Step 6e test-engineer dispatch: add Mode prefix (CRQ-2, P0):**
Currently: "Context: changed files, acceptance criteria"
Prepend `Mode: feature-implementation.` to the context string.

**Edit 5e — Step 6h single-pass skip: add compensating requirement (CRQ-8, P1):**
Document the skip as explicit tradeoff. Add instruction for reviewer to provide file:line evidence in single-pass mode.

### 6. `core/fixer-reviewer-loop.md` (CRQ-10)

**Edit 6a — Input Contract: discriminated union (CRQ-10, P2):**
Currently: "context | string | required | Bug report or spec + AC + code-analyst output"
Expand to document bug-mode and feature-mode context shapes.

**Edit 6b — Failure Handling: add implement-feature reference (CRQ-10, P2):**
Currently: "NEEDS_DECOMPOSITION -> returned to caller; caller handles decomposition logic (see core/decomposition-heuristics.md and skills/fix-ticket/SKILL.md step 5)."
Add implement-feature reference.

### 7. `core/block-handler.md` (CRQ-4)

**Edit 7a — Step 1 rollback trigger list: add smoke-check (CRQ-4, P0):**
Currently: "If the blocking agent is fixer, reviewer, or test-engineer -> dispatch rollback-agent"
Add smoke-check to the list.

### 8. `agents/rollback-agent.md` (CRQ-4)

**Edit 8a — Step 1 proceed-with-rollback allowlist: add smoke-check (CRQ-4, P0):**
Currently: "If the blocking agent is fixer, test-engineer, e2e-test-engineer, or reviewer -> proceed with rollback."
Add smoke-check to the list.

### 9. `core/decomposition-heuristics.md` (CRQ-11)

**Edit 9a — Purpose: add scope annotation (CRQ-11, P2):**
Add note that this contract applies to the bug pipeline. Feature pipeline uses architect-driven decomposition.

**Edit 9b — Output Contract: add feature pipeline reference (CRQ-11, P2):**
Add note about feature pipeline's alternative decomposition path.

### 10. `state/schema.md` (CRQ-12)

**Edit 10a — Add triage.ac_source field (CRQ-12, P2):**
Add new field to the triage object: `ac_source` with values "triage-analyst" or "spec-analyst".

**Edit 10b — Update triage.acceptance_criteria description (CRQ-12, P2):**
Add dual-provenance note to the existing field description.

## Validation Rules

After all edits:
1. Every agent file must preserve: frontmatter (name, description, model, style) + Goal + Expertise + Process + Constraints section order
2. Every core contract must preserve: Purpose + Input Contract + Process + Output Contract + Failure Handling
3. No bug-fix pipeline text may be removed — only additive mode-branches
4. Run `tests/harness/run-tests.sh` — all tests must pass
5. The word "root cause" must still appear in bug-mode contexts of fixer and reviewer
6. The word "triage analysis" must still appear in bug-mode contexts of fixer
