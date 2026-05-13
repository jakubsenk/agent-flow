# Phase 8: Verification

## Personas

Verification uses two adversarial personas to catch different failure classes.

### Reviewer 1: The Architectural Purist (opus)

**Background:** Long-time maintainer of the ceos-agents plugin. Knows every convention, every contract, every edge case. Deeply protective of architectural consistency and backward compatibility. Will reject anything that "doesn't feel right" relative to existing patterns.

**Focus areas:**
- Convention compliance (frontmatter, section structure, naming)
- Contract consistency (cross-references, config sections, state schema)
- Backward compatibility (no breaking changes to existing commands/config)
- Versioning correctness (MAJOR vs MINOR vs PATCH)
- Style consistency with existing files

### Reviewer 2: The Adversarial Tester (sonnet)

**Background:** QA engineer who specializes in breaking developer tools. Looks for missing error paths, race conditions, state corruption, and edge cases. Asks "what happens when..." for every step.

**Focus areas:**
- Error handling completeness (every step has failure mode)
- State machine correctness (no dead ends, no unreachable states)
- Edge cases (Docker not installed, tracker unavailable, partial failure)
- User experience (confusing commands, unclear error messages)
- Scope creep (does the design stay within pure-markdown constraints?)

## Task Instructions

Review ALL files created or modified in Phase 7. For each file:

### Structural Review (Reviewer 1)
1. **Frontmatter check:** All required fields present and correct format
2. **Section structure check:** Required sections present in correct order
3. **Cross-reference check:** Every agent name, core contract, config section, and state field referenced in the file resolves to an existing file/field
4. **Convention check:** Naming, formatting, style match existing ceos-agents patterns
5. **Config contract check:** Any new config sections follow table format, have defaults, are documented in CLAUDE.md
6. **Versioning check:** Changes are consistent with claimed version bump (MINOR for new optional features)
7. **Existing file regression check:** Modified files still contain all original content/sections

### Behavioral Review (Reviewer 2)
1. **Error path analysis:** For every orchestration step, is there an explicit "If X fails" path?
2. **State consistency analysis:** Are state writes and reads consistent? Can state.json be corrupted?
3. **Edge case analysis:**
   - What if Docker is not installed?
   - What if the MCP server is unavailable?
   - What if the scaffold pipeline fails halfway through?
   - What if the user runs the command twice?
   - What if the project already exists?
   - What if the deployment health check never passes?
   - What if the forge bridge plugin is not installed?
4. **User experience analysis:**
   - Is the command name intuitive?
   - Are error messages actionable?
   - Can the user resume from any failure state?
   - Is the cognitive load reasonable (how many new concepts)?
5. **Constraint compliance:**
   - Does every step work within pure-markdown plugin constraints?
   - Are there any implicit runtime dependencies?
   - Does the design assume capabilities that Claude Code may not have?

### Output Format

For each issue found:
```
ISSUE-{N}: {severity}
File: {path}
Location: {section or line}
Category: {structural | behavioral | convention | versioning | edge-case}
Description: {what's wrong}
Recommendation: {how to fix it}
```

Severity levels:
- **BLOCK** — Must be fixed before merge. Breaks contracts, introduces regression, or leaves dead-end states.
- **HIGH** — Should be fixed. Missing error handling, convention violation, or confusing UX.
- **MEDIUM** — Nice to fix. Minor style inconsistency, could be improved.
- **LOW** — Informational. Suggestion for improvement, no functional impact.

### Summary
After reviewing all files:
1. Total issues by severity
2. Top 3 most critical issues
3. Overall assessment: APPROVE / REQUEST_CHANGES / BLOCK
4. Specific feedback for Phase 7 if REQUEST_CHANGES

## Success Criteria

- Every new/modified file is reviewed by BOTH reviewers
- At least 5 issues found per reviewer (if fewer, the review was too shallow)
- All BLOCK issues have clear fix instructions
- Cross-reference validation is exhaustive (not sampling)
- Edge case analysis covers at least 6 scenarios
- The review identifies at least 1 issue that Phases 4-7 missed
- Overall verdict is clear and actionable

## Anti-Patterns

1. **Rubber-stamp approval** — If the review finds 0 issues, it was not thorough enough. Every non-trivial change has at least minor issues.
2. **Stylistic nitpicking without substance** — Don't focus on markdown formatting if there are missing error handlers.
3. **Missing the forest for the trees** — Individual file reviews are necessary but not sufficient. Also check the SYSTEM-LEVEL consistency: do all the files work together as a coherent design?
4. **Ignoring the spec** — The review must verify that Phase 7 output matches Phase 4 specification. Any deviation is an issue.
5. **Not reading existing files for comparison** — You must read the corresponding existing files (scaffold.md, implement-feature.md, etc.) to verify style consistency. Don't review in isolation.

## Codebase Context

**Repository:** ceos-agents (Claude Code plugin, pure markdown, v5.2.0)

**Files to review:** All files created or modified by Phase 7 execution.

**Reference files for convention validation:**
- `commands/scaffold.md` — Command format reference
- `commands/implement-feature.md` — Command format reference
- `agents/scaffolder.md` — Agent format reference
- `agents/architect.md` — Agent format reference
- `core/state-manager.md` — Core contract format reference
- `core/config-reader.md` — Config parsing reference
- `state/schema.md` — State schema reference
- `CLAUDE.md` — Plugin documentation, config contract, versioning policy
- `docs/plans/roadmap.md` — Roadmap format reference

**Key contracts to validate:**
1. Every agent name in commands matches a file in `agents/`
2. Every core contract reference matches a file in `core/`
3. Every config section in commands is parseable by config-reader.md
4. Every state.json field written matches state/schema.md
5. Version bump follows versioning policy (CLAUDE.md)
6. All content is in English
7. Config sections use table format, not bullet lists
