# Phase 6 — Implementation Plan

## Context

You are planning the implementation of v5.6.1 (UX Polish) for the ceos-agents plugin. All changes are markdown text edits across 3 files. This is a fast-tracked task — low complexity, low risk.

## Execution Order

Changes should be applied in dependency order:

### Step 1: Update `core/mcp-detection.md` (Items 2, 3)

**Why first:** This is a shared contract referenced by `commands/scaffold.md`. Changes here affect the contract that scaffold.md consumes.

**Edits:**
1. Add `interactive` parameter to Input Contract section
2. Add canary-write announcement to Process step 4 (before canary creation)
3. Add interactive confirmation prompt to Process step 4
4. Rewrite Failure Handling error messages (remove MCP jargon)

**Estimated diff:** ~15 lines added/changed

### Step 2: Update `commands/scaffold.md` (Items 1, 3)

**Why second:** Depends on updated core/mcp-detection.md contract (interactive parameter). Also contains the --infra flag format which item 4 depends on.

**Edits:**
1. Update Flag Parsing (line 22): new --infra format description
2. Update Flag Validation (lines 36-40): new format regex and error message
3. Update Step 0-INFRA preset (lines 60-66): new parsing description
4. Pass `interactive` parameter in Step 0-MCP (around line 144)
5. Rewrite all MCP jargon messages (lines 146, 159, 163, 748-751)

**Estimated diff:** ~30 lines changed

### Step 3: Update `commands/resume-ticket.md` (Item 4)

**Why third:** Depends on the --infra format defined in Step 2 (must use same format).

**Edits:**
1. Add --infra flag to input description (after line 8)
2. Add infrastructure override logic after State File Detection section
3. Add non-scaffold pipeline warning

**Estimated diff:** ~25 lines added

### Step 4: Run Tests

Run `tests/harness/run-tests.sh` to verify no structural regressions.

### Step 5: Verify (Manual)

Apply the test cases from Phase 5 (TDD) as a manual checklist.

## Parallelization

Steps 1 and 3 could theoretically run in parallel (no shared edits), but Step 3 depends on the --infra format defined in Step 2, which depends on Step 1. Execute sequentially for safety.

## Risk Mitigation

- **Low risk overall.** All changes are text edits in markdown files.
- **Cross-reference check:** After all edits, search for any remaining "MCP server for" occurrences across the entire codebase to ensure completeness.
- **Format consistency check:** After all edits, verify `--infra` format description matches between `scaffold.md` and `resume-ticket.md`.

## Dependencies

```
Step 1 (core/mcp-detection.md)
  |
  v
Step 2 (commands/scaffold.md) -- depends on Step 1 (interactive parameter)
  |
  v
Step 3 (commands/resume-ticket.md) -- depends on Step 2 (--infra format)
  |
  v
Step 4 (tests) -- depends on Steps 1-3
  |
  v
Step 5 (verify) -- depends on Step 4
```

## Estimated Total Effort

~70 lines of markdown edits across 3 files. No new files. No compilation. No runtime changes.
