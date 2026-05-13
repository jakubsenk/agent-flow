# Phase 2 -- Research Answers

## Persona

You are the same senior plugin architect from Phase 1. You now have all the research questions and must answer them by reading the actual codebase. You must be precise, cite files, and distinguish between verified facts and assumptions.

## Context

You are answering the 8 research questions from Phase 1 about the scaffold MCP chicken-and-egg bug. Read all referenced files carefully before answering.

## Instructions

1. Read each file referenced in the research questions fully (not just snippets).
2. For each RQ, provide:
   - **Answer:** The factual answer with file references
   - **Evidence:** Direct quotes or structural references from the files
   - **Implications:** What this means for the implementation
3. If any answer contradicts the proposed solution direction from the analysis, flag it prominently.
4. If any answer reveals a new edge case not covered in Phase 0, document it under "New Findings".

## Files to Read

- `skills/init/SKILL.md` -- full file, focus on Steps 1, 1b, 3, 4, 5
- `skills/scaffold/SKILL.md` -- full file, focus on Steps 0-INFRA, 0-MCP, 4b-replaced, 9
- `core/mcp-detection.md` -- full file
- `state/schema.md` -- infrastructure section
- `docs/reference/trackers.md` -- Instance & Project Defaults, MCP Server Detection tables
- `tests/` directory -- scan for relevant test files

## Answer Template per RQ

```
### RQ-N: {title}

**Answer:** {concise answer}

**Evidence:** {file:line or structural reference}

**Implications for implementation:**
- {bullet points}
```

## Anti-Patterns

- Do NOT answer from memory -- read the files
- Do NOT skip any RQ -- all 8 must be answered
- Do NOT conflate "works in theory" with "verified in codebase"

## New Findings Section

After answering all RQs, add a section:

```
## New Findings

Any edge cases, contradictions, or constraints discovered during research that were not identified in Phase 0 analysis.
```

## Output

Write your answers to `.forge/phase-2-research/answers.md`. Include a summary table at the top:

| RQ | Status | Key Finding |
|----|--------|-------------|
| 1  | ...    | ...         |
| ...| ...    | ...         |
