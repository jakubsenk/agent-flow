# Phase 3 — Brainstorm Synthesis

## Consensus Decisions

### 1. Mode Awareness: Inline Conditionals (Approach B)
Both personas agree: add mode-specific inline paragraphs within existing Process steps. Follows the proven acceptance-gate pattern (line 21). Three explicit modes: `bug-fix`, `feature`, `scaffold`.

### 2. Mode Signal: Skills inject `Mode:` prefix
Skills (fix-ticket, fix-bugs, implement-feature, scaffold) inject `Mode: bug-fix | feature | scaffold` into the context string at dispatch time. Agents detect this in Step 1 and branch.

### 3. Fixer Step 1: Replace hard Block with mode-aware input mapping
Bug mode: triage analysis + impact report (existing behavior)
Feature mode: specification + architectural design + subtask scope
Scaffold mode: specification + architectural design + subtask scope (same as feature)

### 4. Fixer Step 5 TDD: Mode-specific instructions
Bug mode: "Write a test that reproduces the bug" (existing)
Feature/scaffold: "Write a test that verifies the requirement is implemented correctly"

### 5. Reviewer: Mode-aware checklist
Bug mode: "Root cause addressed?" (existing)
Feature/scaffold: "Specification requirement fulfilled?"

### 6. Publisher: Skill passes commit prefix
Skills pass commit type (fix/feat/init) rather than making publisher mode-aware internally.

### 7. State Schema: Add ac_source discriminator field
Conservative approach: add `triage.ac_source` field. Parallel field groups (spec_analysis.*, etc.) are a larger schema change deferred to a future version.

### 8. Core Contracts: Generalize fixer-reviewer-loop and block-handler; narrow decomposition-heuristics
- fixer-reviewer-loop: document dual input shape (bug vs feature)
- block-handler: add smoke-check to rollback triggers
- decomposition-heuristics: mark as bug-pipeline-only, fix misleading reference in implement-feature

### 9. NEEDS_DECOMPOSITION: Always-Block handler in implement-feature
Simplest and safest approach. Architect already decomposed; if fixer says NEEDS_DECOMPOSITION, it means the subtask is still too large — Block and let human handle.

## Deferred Items (out of scope for this implementation)
- Spec-reviewer split into spec-reviewer + spec-compliance-checker (Area 6.1)
- Tracker subtask extraction to core contract (~540 lines dedup) (Area 6.3)
- Code-analyst before architect in implement-feature (Area 6.2)
- Parallel state schema sections (Area 4 Approach A)
- Config Validity Gate in fix-bugs (P2-G1)

## Implementation Scope

**In scope (Batch 1 + 2 = 16 items):**
Files to modify:
1. `agents/fixer.md` — Step 1 guard, frontmatter, Goal, Step 5 TDD, Constraints
2. `agents/reviewer.md` — Step 1 input, Step 2 checklist
3. `agents/test-engineer.md` — Step 1 input, Step 3 test framing, description
4. `agents/e2e-test-engineer.md` — Step 1 input, Goal
5. `agents/publisher.md` — Step 6 PR title, Step 6 PR template
6. `agents/rollback-agent.md` — Step 1 trigger allowlist
7. `skills/implement-feature/SKILL.md` — Mode prefix (Steps 6b/6d/6e), NEEDS_DECOMPOSITION handler, webhook format, single-pass AC gate
8. `core/fixer-reviewer-loop.md` — Input Contract, NEEDS_DECOMPOSITION references
9. `core/block-handler.md` — Rollback trigger list
10. `core/decomposition-heuristics.md` — Scope annotation, implement-feature reference fix
11. `state/schema.md` — ac_source field

**Out of scope deferred (Batch 3-4):**
- config-reader.md key fix
- state schema retry limit fields
- fix-verification language
- duplication reduction
