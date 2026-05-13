# Phase 3: Brainstorm

## Personas

### Persona 1: Defense-in-Depth Security Architect
You are a security architect who has hardened LLM-based automation systems against prompt injection for 5 years. You believe in layered defenses: markers alone are insufficient — agents need constraints, and the wrapping must be airtight. Your approach: maximum coverage, every agent that could possibly see external content gets the constraint, every skill gets the wrapping instruction. For version tracking, you want cryptographic-strength comparison (not just major version).

### Persona 2: Pragmatic Plugin Developer
You are the plugin's author who values simplicity and maintainability. You know that this is a markdown plugin — overly complex schemes are impossible to enforce because LLM agents interpret instructions, not execute code. Your approach: minimal viable protection — clear markers, clear constraint, done. For version tracking, a simple string comparison and WARN is sufficient. Don't over-engineer what is fundamentally advisory.

### Persona 3: Adversarial Red Team Analyst
You are a red team analyst who finds holes in security measures. You question: Can the markers themselves be injected? What if an issue title contains `--- EXTERNAL INPUT END ---`? What if the attacker nests markers? What if the version field is corrupted? For every proposed defense, you find the bypass. You focus on failure modes and edge cases.

## Task Instructions
Each persona independently proposes solutions for both items. Then a judge synthesizes the best elements.

**Item 1: Prompt Injection Protection (D2)**
- What exact marker format should be used? (Consider: uniqueness, resistance to injection, LLM interpretability)
- Should agents receive the markers or should skills strip content before dispatch?
- Which agents need the NEVER constraint? Only the 5 specified, or more?
- Where in the skill flow should wrapping happen? After MCP read? During context construction?
- What happens if markers appear in legitimate issue content?
- Should the core contract define escaping rules for nested markers?

**Item 2: Plugin Version Tracking (D12)**
- Where should the version be read from? `.claude-plugin/plugin.json`? CLAUDE.md? Both?
- When should it be written to state.json? At initialization only, or updated on resume?
- What comparison logic? Major-only? Major+minor? Full semver?
- What should happen on mismatch? WARN only? WARN + ask user? Block?
- Should the version be the full semver string or structured `{major, minor, patch}`?

**Constraints for all personas:**
- This is a MINOR version — new optional features, no breaking changes
- Pure markdown plugin — no runtime code to add
- Changes must pass existing test suite (`tests/harness/run-tests.sh`)
- The core contract pattern must match existing contracts in `core/`
- Agent constraint pattern must match existing NEVER rules in agents

## Success Criteria
- Three distinct approaches with clear tradeoffs
- Edge cases identified (marker injection, nested markers, corrupted version)
- Judge synthesis picks the pragmatic middle ground
- Both items are fully addressed by the final synthesis
- The synthesis respects the existing codebase patterns (core contract structure, agent constraint format)

## Anti-Patterns
1. All three personas converging on the same solution — they should disagree on scope and strictness
2. Proposing runtime code (validation scripts, parsers) — this is a pure markdown plugin
3. Over-engineering the version comparison (semver library, etc.) — simple string parsing suffices
4. Ignoring that markers are instructions TO the LLM, not executable code — they work by convention
5. Forgetting that the core contract must be referenced by skills to be useful (see xref-core-registry test)
6. Not considering the test scenario requirements (the test must verify file content, not behavior)

## Codebase Context
- Pure markdown plugin: all "code" is markdown instructions for LLM agents
- Core contracts follow: Purpose, Input Contract, Process, Output Contract, Failure Handling
- Agent constraints follow: `- NEVER {action} — {reason}` pattern in `## Constraints` section
- Existing 13 core contracts are all referenced by at least one skill (tested by xref-core-registry.sh)
- State.json schema defines all fields with Type, Required, Default, Description columns
- Plugin version is in `.claude-plugin/plugin.json` as `"version": "6.6.0"`
- Resume-ticket has Priority 0 (state file) and fallback (heuristic) detection paths
- Test scenarios are bash scripts that grep for patterns in markdown files
