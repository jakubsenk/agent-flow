# Pipeline Consistency — Design

**Date:** 2026-03-06
**Status:** APPROVED
**Scope:** Bug fixes + pattern unification in scaffold.md, new consistency test, reference doc

## Problem

The fixer/reviewer/test-engineer execution loop is duplicated across 4 commands (6 instances). While duplication in prompts is acceptable (self-contained commands perform better for LLMs — see Evidence section), the current duplication contains bugs and inconsistencies.

## Evidence: Why Self-Contained Commands

Research confirms self-contained prompts outperform shared/modular prompts for LLM agent orchestration:

- **Anthropic: "Building Effective Agents"** — each agent gets a self-contained prompt; no cross-prompt sharing
- **Anthropic: "Multi-Agent Research System"** — failed with generic instructions, succeeded with detailed per-agent prompts
- **arXiv 2502.02533 (Mass framework)** — per-agent prompt optimization = +6% performance vs shared prompts
- **arXiv 2512.01939** — 42% of developers report excessive abstraction hinders development
- **CrewAI, LangGraph, AutoGen** — all define agents as self-contained units

Consistency is enforced via automated tests, not shared files.

## Decision

Keep commands self-contained. Fix bugs. Add consistency test.

## Changes

### Bug Fixes in `commands/scaffold.md`

| # | Location | Bug | Fix |
|---|----------|-----|-----|
| 1 | Line 334 | Block comment missing emoji — `[ceos-agents] Pipeline Block` | Add emoji: `[ceos-agents] Pipeline Block` (with red circle emoji) |
| 2 | Line 325 | `git add .` inconsistent with other commands | Change to `git add -A` |
| 3 | Line 357 | E2E retry hardcoded `max 3 retries` | Remove — e2e-test-engineer agent handles retries internally (Constraints line 56) |
| 4 | Line 212 | Safety check lacks explicit failure action | Add: "DO NOT run rm -rf — report an error instead" (match line 104) |
| 5 | Lines 330-331 | Rollback-agent "skip issue tracker" is a markdown note, not passed as Context | Move into Context string: `"No issue tracker context — skip issue tracker updates."` |
| 6 | Line 255 | Max subtasks default 5 vs 7 with no explanation | Add: "lower than implement-feature's 7 because scaffold epics are already pre-decomposed by spec-writer" |

### Pattern Unification in `commands/scaffold.md`

| # | Location | Issue | Fix |
|---|----------|-------|-----|
| 7 | Step 7 agent calls | No retry limits passed as Context to agents | Add Context strings: `Max build retries = ...`, `Max fixer iterations = ...`, `Max test attempts = ...` (match fix-ticket/fix-bugs pattern) |
| 8 | Step 7 start | No explanation for hook absence | Add note: hooks are not executed during scaffold because the project is being created from scratch |

### New Files

| File | Purpose |
|------|---------|
| `tests/scenarios/pipeline-consistency.sh` | Automated grep-based test verifying consistent patterns across all 4 pipeline commands |
| `docs/reference/execution-loop.md` | Reference documentation for human editors describing the canonical execution loop |

### Updated Files

| File | Change |
|------|--------|
| `tests/README.md` | Add pipeline-consistency.sh to scenario table, tree, update count 12 to 13 |

## What the Consistency Test Checks

The test `pipeline-consistency.sh` verifies across fix-ticket.md, fix-bugs.md, implement-feature.md, scaffold.md:

1. Block comment format uses emoji consistently
2. Decomposition commits use `git add -A` (not `git add .`)
3. Retry limits are passed as Context strings to fixer/reviewer/test-engineer
4. Safety checks for temp directory cleanup include explicit failure action
5. Rollback-agent context includes issue tracker instruction

## Out of Scope

- Extracting shared execution loop into a separate file (rejected — see Evidence)
- Adding hooks to scaffold (by design — greenfield project)
- Adding publisher to scaffold (by design — no issue tracker context)
- Changing commit strategy defaults (individual vs squash — intentional per-command)
