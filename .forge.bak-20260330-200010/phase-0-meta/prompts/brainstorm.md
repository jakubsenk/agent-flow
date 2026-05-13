# Phase 3 — Brainstorm

## Context

You are brainstorming implementation approaches for 4 UX Polish items in the ceos-agents plugin (v5.6.1). All changes are markdown text edits — no runtime code.

## Items to Brainstorm

### Item 1: --infra Flag Format

**Current:** `--infra ready,later` (positional: first = tracker, second = SC)
**Target:** `--infra tracker:ready,sc:later` (self-documenting key:value pairs)

**Design decisions:**
- Should the order matter? (e.g., `--infra sc:later,tracker:ready` should work too)
- Should shorthand be supported? (e.g., `--infra ready` = both ready, `--infra later` = both later)
- What about partial specification? (e.g., `--infra tracker:ready` = tracker ready, SC defaults to "later")
- Error message for invalid format: what should the new validation regex and error text be?

**Recommendation:** Support order-independent `key:value` pairs. Support partial specification (omitted = "later"). No shorthand for single word — always require `key:value` format for clarity. This is the cleanest UX.

### Item 2: Canary-Write Announcement

**Current:** Canary-write happens silently in `core/mcp-detection.md` step 4.
**Target:** Announce before creating, optionally ask in interactive mode.

**Design decisions:**
- Where does the announcement go? In `core/mcp-detection.md` (shared) or in the caller (`scaffold.md`)?
- The core contract does not know about "interactive mode" — that is a scaffold concept. Should the announcement always happen (in core), with the ask-first logic in the caller?
- What text for the announcement? What text for the interactive ask?

**Recommendation:** Add the announcement to `core/mcp-detection.md` step 4 (before canary creation). This is universal — all callers should announce. Add a new input parameter `interactive` (boolean, default false). When `interactive: true`, display a confirmation prompt before proceeding. The caller (`scaffold.md`) passes `interactive: true` when mode is Interactive.

### Item 3: Error Message Rewrite

**Current MCP jargon instances to find and replace:**
- `core/mcp-detection.md` line 57: "No MCP tool matching prefix {tool_prefix} found in current session"
- `core/mcp-detection.md` line 58: "Caller decides whether to block or downgrade"
- `commands/scaffold.md` line 146: "MCP server for {type} not detected in current session"
- `commands/scaffold.md` line 159: 'MCP server for "{tracker_type}" is not available'
- `commands/scaffold.md` line 163: "MCP for {type} not available"
- `commands/scaffold.md` line 748-751: Standard error message block with MCP language

**Recommendation:** Replace all instances with user-friendly language. Map tracker types to display names (youtrack -> "YouTrack", github -> "GitHub Issues", jira -> "Jira", linear -> "Linear", gitea -> "Gitea Issues", redmine -> "Redmine"). Error messages should say "Cannot connect to your {DisplayName} tracker" with actionable next steps.

### Item 4: Resume --infra Override

**Current:** `resume-ticket.md` has no `--infra` flag support. It reads state.json infrastructure values on resume without allowing override.
**Target:** Parse `--infra` flag from $ARGUMENTS, compare with state.json values, override if different.

**Design decisions:**
- Where in the resume flow? Before step 6 (checkpoint determination) since infrastructure state affects the entire pipeline.
- Should this only apply to scaffold pipeline resumes? Yes — infrastructure state is only relevant for scaffold.
- What about partial override? (e.g., only change tracker from later to ready, keep SC as-is)

**Recommendation:** Add `--infra` flag parsing to resume-ticket.md. After state file detection (Priority 0), check if `--infra` was provided AND pipeline is "scaffold". If so, parse the new format, compare with state.json infrastructure values, update state.json, display "Infrastructure changed since last run. Using new values." Only override the values that differ.

## Convergence

All 4 items are straightforward text edits. No architectural decisions needed. The main design choice is item 2 (where to put the announcement) — recommendation is `core/mcp-detection.md` with an `interactive` input parameter.
