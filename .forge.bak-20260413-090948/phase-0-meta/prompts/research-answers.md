# Phase 2 — Research Answers

## Context

You are researching residual unknowns for the feature pipeline agent audit. The prior audit report is at `docs/plans/implement-feature-agent-audit-REVIEW.md` (12 CRQs, all CONFIRMED).

## Instructions

Answer each research question from `research-questions.md` by reading the relevant files. For each question:

1. Read the files specified in the search strategy
2. Provide a direct answer with file:line evidence
3. State the impact on the edit plan

## Research Questions to Answer

### RQ-1: Scaffold pipeline agent dispatch overlap
Read `skills/scaffold/SKILL.md`. Find all dispatch points for fixer, reviewer, test-engineer. Document what context each receives. Determine if the mode-branch pattern needs a third mode (scaffold) or if the existing feature-mode branch covers scaffold too.

### RQ-2: Test harness coverage of agent definitions
Read `tests/harness/run-tests.sh` and all files in `tests/`. Identify which tests validate:
- Agent file frontmatter structure
- Agent file section order (Goal, Expertise, Process, Constraints)
- Agent file content patterns (e.g., must contain "Block Comment Template")
- Skill file structure
- Core contract structure
Document any structural rules that would be violated by adding mode-branch paragraphs.

### RQ-3: Existing mode-branch patterns in agents
Grep `agents/*.md` for patterns like "bug", "feature", "mode", "pipeline". Document any existing dual-mode handling. The known example is `agents/acceptance-gate.md` line 21: "from triage-analyst for bugs, spec-analyst for features".

### RQ-4: fix-bugs skill NEEDS_DECOMPOSITION handling
Read `skills/fix-bugs/SKILL.md`. Determine if it has its own NEEDS_DECOMPOSITION handler or delegates to fix-ticket. If it has its own handler, document it — we may need to verify it's consistent with what we add to implement-feature.

### RQ-5: State schema consumers
Grep across the entire codebase for `acceptance_criteria`, `ac_source`, and `triage.` to find all consumers of these state fields. Document each consumer and whether adding `triage.ac_source` would affect it.

### RQ-6: Block-handler smoke-check invocation path
Read `skills/implement-feature/SKILL.md` Step 6d-smoke to confirm the exact `agent` string passed to the block handler. Also check `skills/fix-ticket/SKILL.md` for any similar smoke-check block handler invocation. Confirm the string is `smoke-check` (not `smoke_check` or `smokeCheck`).

## Output Format

For each RQ:
```
### RQ-N: {title}
**Answer:** {direct answer}
**Evidence:** {file:line references}
**Impact on plan:** {no change / adjust approach / new file needed — with explanation}
```

## Final Synthesis

After all RQs are answered, provide a summary table:

| RQ | Impact | Action |
|----|--------|--------|
| RQ-1 | ... | ... |
| ... | ... | ... |
