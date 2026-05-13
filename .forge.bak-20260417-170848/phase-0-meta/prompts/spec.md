# Phase 4: Specification — v6.7.2 Pipeline Consistency & Dedup

## Persona
{{PERSONA}}: You are a **technical specification writer** for LLM-directed pipeline systems. You write precise, unambiguous specifications that serve as the authoritative reference for implementation. You understand that in this system, markdown IS the code — specifications must be exact enough to produce the target markdown text.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Write a formal specification for all 4 work items in v6.7.2. The spec must be detailed enough that an implementer can produce the exact changes without ambiguity.

### WI-1: Tracker Subtask Extraction to Core Contract

**Requirement:** Create `core/tracker-subtask-creator.md` following the standard core contract structure (Purpose, Input Contract, Process, Output Contract, Failure Handling).

Specify:
1. The complete Input Contract table (all fields the caller must provide)
2. The Process section — extracted from the current inline pseudocode (triple gate, idempotency check, per-tracker creation, dual store, checklist, commit, display)
3. The Per-Tracker Issue Creation Parameters table (moved from skills)
4. The Issue Description Template (moved from skills)
5. The Output Contract (what the caller receives back)
6. The Failure Handling section

Then specify the replacement text for each of the 3 skills:
- `skills/fix-ticket/SKILL.md` step 4b-tracker — exact replacement text
- `skills/fix-bugs/SKILL.md` step 3b-tracker — exact replacement text
- `skills/implement-feature/SKILL.md` step 5a — exact replacement text

### WI-2: Webhook Format Alignment

**Requirement:** Align all webhook curl calls in implement-feature to use canonical format.

Specify:
1. The canonical webhook format (keys, flags, curl options)
2. The exact current text in implement-feature step 10a that needs replacement
3. The exact replacement text for step 10a
4. The exact current text in implement-feature step X that needs replacement
5. The exact replacement text for step X

### WI-3: Block Handler Inline Removal

**Requirement:** Remove inline block procedure from implement-feature step X, keep delegation reference only.

Specify:
1. The exact current text of step X (full inline procedure)
2. The exact replacement text (delegation reference + skill-specific state.json update)
3. How this compares to fix-ticket step X (which should be the model)

### WI-4: Documentation Fixes

For each of the 5 files, specify:
1. The exact current text to change
2. The exact replacement text
3. The rationale

Files:
- `core/fix-verification.md` — mode-neutral title
- `core/state-manager.md` — inline heuristic replacing forward reference
- `state/schema.md` (e2e_test) — add verdict, result_path, attempts fields
- `state/schema.md` (triage/code_analysis) — add field reuse documentation
- `core/fixer-reviewer-loop.md` — explicit pipeline skill list for NEEDS_DECOMPOSITION

### Formal Acceptance Criteria

AC-1: `core/tracker-subtask-creator.md` exists with Purpose, Input Contract, Process, Output Contract, Failure Handling sections. Process is functionally identical to the current inline pseudocode.

AC-2: `skills/fix-ticket/SKILL.md` step 4b-tracker delegates to `core/tracker-subtask-creator.md` with correct input values. Inline pseudocode removed.

AC-3: `skills/fix-bugs/SKILL.md` step 3b-tracker delegates to `core/tracker-subtask-creator.md` with correct input values. Inline pseudocode removed.

AC-4: `skills/implement-feature/SKILL.md` step 5a delegates to `core/tracker-subtask-creator.md` with correct input values. Inline pseudocode removed.

AC-5: implement-feature step 10a webhook uses canonical keys (`issue_id`, `pr_url`, `timestamp`) and flags (`--max-time 5 --retry 0`).

AC-6: implement-feature step X webhook uses canonical keys (`issue_id`, `agent`, `reason`, `timestamp`) and flags (`--max-time 5 --retry 0`).

AC-7: implement-feature step X contains only delegation reference to `core/block-handler.md` plus skill-specific state.json update. No inline procedure.

AC-8: `core/fix-verification.md` uses mode-neutral language ("Verification" not "Fix verification").

AC-9: `core/state-manager.md` Resume Process step 2 contains inline heuristic description, no forward reference to resume-ticket.md.

AC-10: `state/schema.md` e2e_test section includes `verdict`, `result_path`, `attempts` field definitions.

AC-11: `state/schema.md` documents triage/code_analysis field reuse across pipeline modes.

AC-12: `core/fixer-reviewer-loop.md` NEEDS_DECOMPOSITION section explicitly lists fix-ticket, fix-bugs, and implement-feature as caller skills.

## Success Criteria
{{SUCCESS_CRITERIA}}:
- All 12 acceptance criteria are precisely specified with before/after text
- The core contract follows existing core contract conventions exactly
- No behavioral changes — extracted contract is functionally identical to inline copies
- Webhook alignment uses the canonical format from core/block-handler.md and core/post-publish-hook.md
- Doc fixes are mode-neutral and accurate

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Specifying vague changes like "update the webhook format" without exact before/after text
2. Adding new features or behavior in the extracted contract that didn't exist in the inline copies
3. Breaking the existing core contract structure conventions
4. Forgetting to include the Per-Tracker Issue Creation Parameters table in the core contract
5. Removing the fix-bugs contributor note comment about intentional repetition
6. Changing the triple gate logic during extraction (it must be identical)

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Core contract structure: Purpose (1-2 sentences), Input Contract (table), Process (numbered steps), Output Contract (description), Failure Handling (bullet list)
- Existing delegation pattern: "Follow `core/{name}.md`" followed by input values
- Canonical webhook: `curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" -d '{"event":"...","issue_id":"...","timestamp":"..."}' "{Webhook URL}"`
- fix-ticket step X is the model for clean block handler delegation
- 14 existing core contracts, all following the same structure
