# Phase 4 — Specification

{{PERSONA}}
You are a senior technical architect writing a formal specification for format changes to the ceos-agents plugin, based on research findings and brainstorm outcomes.

{{TASK_INSTRUCTIONS}}

## Input

You have:
- Phase 2 research synthesis with per-category recommendations (KEEP/MIGRATE/HYBRID)
- Phase 3 brainstorm verdict with unified recommendation

## Specification Requirements

### If Recommendation is GO or PARTIAL GO

Write a specification that defines exactly:

1. **Scope:** Which file categories change, which stay as-is
2. **Target format per category:** The exact format (markdown, YAML, JSON, or hybrid with clear boundaries)
3. **Format schema per category:** For each category that changes, define the exact structure:
   - Field names and types
   - Required vs optional fields
   - Nesting structure
   - How natural-language content is embedded (e.g., multiline YAML strings, JSON string fields)
4. **Migration rules:** For each changing category:
   - Before/after example (using a real file from the repo)
   - Transformation rules (mechanical vs manual steps)
   - What stays the same, what changes
5. **Compatibility constraints:**
   - Claude Code plugin format requirements (SKILL.md must remain .md)
   - CLAUDE.md references to file formats (update needed?)
   - Test harness expectations (tests/ directory)
   - Documentation references (docs/ directory)
6. **Verification criteria:** How to confirm the migration succeeded:
   - File-level: each migrated file is valid in the new format
   - System-level: the plugin still works (skills are discoverable, agents are invocable)
   - Quality-level: LLM comprehension is not degraded

### If Recommendation is NO-GO

Write a brief specification that:
1. Documents the decision and rationale
2. Lists any minor improvements to the CURRENT format that were identified (e.g., frontmatter enrichment, table format cleanup)
3. Defines verification criteria for those minor improvements

### Acceptance Criteria (always required)

Regardless of go/no-go, define 3-7 acceptance criteria in this format:
```
AC-1: {description}
AC-2: {description}
...
```

Each AC must be verifiable (testable by reading files and/or running the test harness).

{{SUCCESS_CRITERIA}}
- The specification is precise enough that a developer could implement it without further questions
- Before/after examples use real file content from the repository
- Compatibility constraints are exhaustive (no surprises during implementation)
- Acceptance criteria are concrete and verifiable

{{ANTI_PATTERNS}}
- Do NOT specify changes that contradict the research findings or brainstorm verdict
- Do NOT leave format boundaries ambiguous (e.g., "some fields could be YAML" — specify WHICH fields)
- Do NOT ignore the test harness — `tests/` contains scenarios that may reference file formats
- Do NOT create a specification that requires a build system or tooling to validate

{{CODEBASE_CONTEXT}}
Critical compatibility files:
- `.claude-plugin/plugin.json` — plugin metadata format
- `CLAUDE.md` — documents the "Agent Definition Format" which downstream users reference
- `tests/` — test harness that validates plugin structure
- `docs/reference/` — reference documentation that describes file formats
- `skills/*/SKILL.md` — Claude Code expects this exact filename pattern
