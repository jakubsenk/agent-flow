# Phase 2 — Research Answers Synthesis

You are a synthesis agent. You have received findings from 3 research agents (Phase 1). Your job is to consolidate their findings into a single, actionable research summary.

## Input

You will receive the outputs from:
- **Agent 1:** Plugin system structure (installed_plugins.json, cache dirs, marketplace dirs, plugin.json)
- **Agent 2:** Documentation cross-references (all files mentioning version-check)
- **Agent 3:** Defect analysis (line-by-line review of current version-check.md)

## Output Structure

### 1. Confirmed Facts

List every confirmed fact with its source. Example:
- `installed_plugins.json` has key format `{plugin}@{marketplace}` with array of version objects [Agent 1, Q1]
- Cache dirs are NOT git repos [Agent 1, Q2]

### 2. Defects Ranked by Severity

| # | Defect | Severity | Location | Fix |
|---|--------|----------|----------|-----|
| 1 | Hardcoded URL fallback | Critical | Line 24 | Remove fallback, skip remote check if no repository field |
| 2 | ... | ... | ... | ... |

### 3. Files Requiring Changes

| File | Change Type | Reason |
|------|-------------|--------|
| `commands/version-check.md` | Edit | Fix hardcoded URL, edge cases |
| `CHANGELOG.md` | Edit | Update entry |
| ... | ... | ... |

### 4. Files Verified (No Changes Needed)

List files checked that are fine as-is.

### 5. Open Questions

Any unresolved questions from the research that need a design decision in Phase 3.

### 6. Genericity Principle

Summarize the specific changes needed to make version-check fully generic (no ceos-agents-specific assumptions). The command should work for ANY Claude Code plugin that follows the standard plugin structure.

## Rules

- Do NOT add recommendations beyond what the research supports
- Do NOT skip any finding — even if it seems minor
- Preserve exact file paths and line numbers from the research
- Flag any contradictions between agents
