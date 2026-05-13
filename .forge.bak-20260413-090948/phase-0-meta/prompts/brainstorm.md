# Phase 3 — Brainstorm

## Context

You are designing the mode-aware branching pattern for shared agents in the ceos-agents plugin. The prior audit (`docs/plans/implement-feature-agent-audit-REVIEW.md`) identified 12 issues. Research from Phase 2 has answered residual unknowns.

## Constraint

This is a LIGHTWEIGHT brainstorm. The approach is well-defined by the audit recommendations. The goal is to validate the pattern choice and identify any risks, not to explore radically different approaches.

## Topic: Mode-Branch Pattern for Shared Agents

### Approach A: Inline Mode-Branch (Recommended by Audit)

Add a conditional paragraph in each agent's Step 1:
```
If the context includes `Mode: feature-implementation`:
- Read "architectural design" instead of "triage analysis"
- Read "subtask scope" instead of "impact report"  
- Read "spec requirement" instead of "root cause"
Otherwise (default — bug-fix mode): proceed as currently written.
```

**Pros:** Minimal change, additive, preserves all existing bug-fix behavior
**Cons:** Duplicates the vocabulary mapping in each agent; if a third mode is added later, each agent needs another branch

### Approach B: Generic Vocabulary (Long-term ideal)

Replace bug-specific terms with generic ones everywhere:
- "problem statement" instead of "bug report" / "specification"
- "analysis report" instead of "triage analysis" / "architectural design"
- "affected scope" instead of "impact report" / "subtask scope"

**Pros:** One vocabulary works for all modes; no branching needed
**Cons:** BREAKS the existing bug-fix pipeline vocabulary (destructive change); violates the "additive only" constraint

### Approach C: External Mode Translator

Add a new core contract `core/mode-translator.md` that maps mode-specific terms to generic ones. Skills call the translator before dispatching agents.

**Pros:** Clean separation of concerns; agents stay mode-unaware
**Cons:** Adds a new file (violates "no new files" preference); increases complexity; translator becomes a single point of failure

## Decision Criteria

1. Must not break bug-fix pipeline (eliminates Approach B)
2. Must not require new files (eliminates Approach C unless strictly necessary)
3. Must be implementable in ~70 targeted edits across 10 files
4. Must be maintainable — a future third mode should be addable without redesign

## Your Task

1. Validate that Approach A is correct given the constraints
2. Identify any risks or edge cases with Approach A that the audit missed
3. If Approach A has a fatal flaw, propose a hybrid approach
4. Recommend the final pattern with a 1-paragraph rationale

## Additional Considerations

- The `implement-feature` skill already passes `Mode: feature-implementation` as a prefix in the context string for Steps 6b/6d/6e (this is part of the CRQ-2 fix)
- The fixer-reviewer-loop core contract needs a discriminated union input (CRQ-10) — should the mode signal live in the loop contract or in each agent?
- Scaffold pipeline may dispatch these agents too (RQ-1 from Phase 2) — does the pattern need to handle scaffold mode?

## Output Format

1. Pattern validation verdict (APPROVED / MODIFIED / REJECTED)
2. Risk assessment (0-3 risks with mitigations)
3. Final pattern recommendation (1 paragraph)
4. Per-agent pattern template (show the exact markdown that will be added to each agent's Step 1)
