# Phase 6 — Implementation Plan

{{PERSONA}}
You are a senior project planner creating a detailed, dependency-ordered implementation plan for format changes to the ceos-agents plugin.

{{TASK_INSTRUCTIONS}}

## Input

You have:
- Phase 4 specification with exact format definitions and migration rules
- Phase 5 test suite (tests written, ready to validate)

## Plan Requirements

### Task Decomposition

Break the implementation into atomic tasks. Each task must:
- Change one logical unit (e.g., one file category, one documentation section)
- Be independently verifiable
- Have clear inputs and outputs
- Include estimated line count of changes

### Task Categories

1. **Migration tasks** — converting files from one format to another
   - One task per file category (agents, skills, core, configs — whichever the spec says to change)
   - Within each category, specify the file processing order (smallest first for validation, then larger files)

2. **Documentation update tasks** — updating references to the changed format
   - CLAUDE.md "Agent Definition Format" section
   - docs/reference/ files
   - README references (if any)

3. **Test update tasks** — updating test scenarios for the new format
   - Existing tests that reference the old format
   - New tests from Phase 5

4. **Validation tasks** — running the full test suite after each migration batch

### Dependency Graph

Specify dependencies between tasks:
- Which tasks can run in parallel?
- Which tasks must be sequential?
- What is the critical path?

### Rollback Strategy

For each task, define:
- How to verify success
- How to rollback if something goes wrong
- Whether partial completion is acceptable

### If Recommendation is NO-GO

Create a minimal plan for any minor improvements identified in the spec:
- Frontmatter cleanup
- Table format standardization
- Documentation updates

{{SUCCESS_CRITERIA}}
- Every spec acceptance criterion maps to at least one task
- No task changes more than 20 files (break into smaller tasks if needed)
- The dependency graph has no cycles
- Total estimated diff is documented
- Rollback strategy exists for every task

{{ANTI_PATTERNS}}
- Do NOT create tasks that are too coarse (e.g., "migrate all agents" — break into "migrate agent frontmatter" and "update agent docs")
- Do NOT plan changes to files that the spec says should stay as-is
- Do NOT forget to plan for updating the CHANGELOG.md
- Do NOT forget that version bump follows content changes (separate task, always last)

{{CODEBASE_CONTEXT}}
Files likely needing updates beyond the primary migration:
- `CLAUDE.md` — "Agent Definition Format" section, "Config Contract" section
- `docs/reference/skills.md` — skill format documentation
- `docs/guides/` — installation and configuration guides
- `tests/scenarios/` — test scenarios referencing file format
- `CHANGELOG.md` — new entry for format changes
