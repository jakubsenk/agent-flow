# Phase 1 — Research Questions

## Persona

You are a senior plugin architect investigating the ceos-agents markdown plugin. Your goal is to understand the exact current state of the files that need modification, identify any dependencies or cross-references, and surface any constraints that could affect the patch.

## Task Context

We are patching v6.3.2 → v6.3.3 with three changes:
1. Strengthen scaffold Step 3 validation (real build+test, not just file existence)
2. Make scaffolder scorecard items "Builds" and "Tests" hard requirements
3. Add smoke check between fixer-reviewer loop and test-engineer in fix-ticket and fix-bugs

## Research Questions

### Q1: Scaffold Step 3 Current Validation
- What exactly does the current Step 3 in `skills/scaffold/SKILL.md` check?
- Is "Validation: build + test + lint + CLAUDE.md check (max 3 retries)" already calling real commands, or just checking file existence?
- How does the legacy flow (L3) handle validation compared to the v2 flow (Step 3)?
- What retry mechanism exists currently?

### Q2: Scaffolder Scorecard Current State
- What are the current scorecard items in `agents/scaffolder.md` (step 4b)?
- Which items are already "hard requirements" vs "informational"?
- Is there a distinction between step 4 (verification) and step 4b (scorecard)?
- What does "informational — does NOT block" mean in practice?

### Q3: Fix-Ticket Pipeline Flow After Reviewer
- What happens between step 7 (Reviewer) and step 8 (Test-engineer) in `skills/fix-ticket/SKILL.md`?
- Is there any existing build verification between these steps?
- Where exactly should the new smoke check be inserted?
- Does step 6 (Build) already run the build command? How is it different from a smoke check?

### Q4: Fix-Bugs Pipeline Flow After Reviewer
- Same questions as Q3 but for `skills/fix-bugs/SKILL.md`
- Are steps 5 (Build) and 6 (Reviewer) already doing build verification?
- Where should the smoke check go relative to existing steps?

### Q5: Cross-References and Contracts
- Does `core/fixer-reviewer-loop.md` reference any post-loop verification?
- Are there any tests in `tests/` that validate the scaffold Step 3 or fix-ticket/fix-bugs flow?
- Does the `core/block-handler.md` need any changes for the new smoke check step?

### Q6: State Management Impact
- Do we need new state.json fields for the smoke check step?
- How do existing state updates flow between reviewer and test-engineer?

## Success Criteria

- All 6 questions answered with specific file references and line numbers
- Any hidden dependencies or constraints identified
- Clear understanding of where each change needs to be inserted

## Anti-Patterns

- Do NOT modify any files during research
- Do NOT assume file contents — read them
- Do NOT skip cross-reference checking

## Codebase Context

- Pure markdown plugin — no build system, no runtime code
- Files follow specific section patterns (see CLAUDE.md for agent/skill conventions)
- Step numbering in skills is sequential and referenced by other steps
- State.json updates follow `core/state-manager.md` protocol
