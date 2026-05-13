# Phase 2 — Research Synthesis

You are a **Senior Technical Analyst** synthesizing research findings into actionable implementation guidance.

## Task Context

We are adding two features to `agents/scaffolder.md` in the ceos-agents plugin (v6.2.0 → v6.3.0):

1. **E2E Test Generation** — New conditional batch generating Playwright e2e test suite for web projects
2. **Application Documentation for Agents** — New batch generating `docs/ARCHITECTURE.md` + populating `Module Docs | Path` in CLAUDE.md

## Input

You have Phase 1 research answers covering:
- Q1: Scaffolder agent structure (batches, scorecard, constraints)
- Q2: Scaffold skill pipeline (invocation, validation, CLAUDE.md auto-fill)
- Q3: Module Docs consumption (which agents, format, zero-change path)
- Q4: E2E Test config section (keys, generation, e2e-test-engineer relation)
- Q5: Existing test patterns (assertion styles, scaffold test locations)
- Q6: File count targets (current ceilings, impact of new files)

## Synthesis Tasks

### S1: Feature Design Decisions
Based on the research, resolve these design questions:
- Should E2E Test Generation be a new Batch 7 or integrated into an existing batch?
- Should Application Documentation be a new Batch 8 or part of Batch 5 (Docs)?
- What is the correct batch ordering? (e2e tests depend on Batch 1 dependencies; docs depend on all batches being generated)

### S2: Scorecard Additions
- What should the "E2E Test Setup" scorecard item check?
- Should "Application Documentation" get its own scorecard item?
- What is the total scorecard count after additions?

### S3: CLAUDE.md Module Docs Integration
- How should scaffolder populate `Module Docs | Path` in the generated CLAUDE.md?
- Should it be in the required or optional section checklist?
- What is the exact format: `docs/ARCHITECTURE.md` or `docs/`?

### S4: File Count Target Update
- Calculate new file count ceiling: current max (23 for web) + e2e files (~3) + docs (~1) = ?
- Propose updated constraint text

### S5: Constraint Additions
- Are any new NEVER rules needed?
- Should there be a conditional skip rule for non-web projects (like Batch 6)?

### S6: Skill Changes Assessment
- Does `skills/scaffold/SKILL.md` need changes?
- If Module Docs is auto-populated by scaffolder in CLAUDE.md, does the skill need to do anything extra?

### S7: Test Plan
- What new test assertions are needed?
- Which existing test file should they go in, or do we need a new test file?

## Output Format

For each synthesis task:
```
### SN: [Title]
**Decision:** [Clear decision with rationale]
**Implementation detail:** [Exact text/structure changes needed]
```

End with a **Summary Table** mapping each change to its target file and section.
