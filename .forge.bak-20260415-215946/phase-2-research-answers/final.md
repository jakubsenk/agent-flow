# Phase 2: Research Answers — Synthesis

## Item 1: Prompt Injection Protection (D2)

### External Content Flow Map

| Skill | Fetch Step | Data Extracted | Agent Dispatch | Sanitization Today |
|-------|-----------|----------------|----------------|--------------------|
| fix-ticket | Step 1 (MCP read) | title, description, comments, custom fields | Step 3: triage-analyst, Step 4: code-analyst, Step 5: fixer, Step 7: reviewer | NONE |
| fix-bugs | Step 1 (MCP query) | same per-issue | Step 2: triage-analyst (per bug), then delegates to fix-ticket flow | NONE |
| implement-feature | Step 1 (MCP read) + Step 0c (--description) | title, description, comments, attachments | Step 3: spec-analyst | NONE |
| resume-ticket | Step 3 (MCP read comments) | comments with `[ceos-agents]` prefix | Control-flow decisions + state restoration | NONE |
| scaffold | --issue flag | issue description | spec-writer, spec-reviewer | NONE |

### Agent Context Injection Points

| Agent | How It Receives External Content | Context Format |
|-------|----------------------------------|----------------|
| triage-analyst | Reads directly from tracker via MCP (Process step 1) | Raw: `summary, description, comments, custom fields` |
| code-analyst | Receives triage output containing synthesized issue data | `Context: {triage analysis}` |
| fixer | Receives AC from triage interpolated literally | `Acceptance criteria: {AC from triage}` |
| reviewer | Receives AC from triage interpolated literally | `Acceptance criteria: {AC from triage}` |
| spec-analyst | Reads directly from tracker via MCP (Process step 1) | `Context: issue details from the issue tracker` |

### Key Finding: Zero Sanitization
No existing constraint, wrapper, or trust-boundary annotation exists anywhere in the pipeline for external content. Content flows from MCP → skill context string → Task dispatch → agent processing with no markers.

### Existing NEVER Constraint Patterns (verbatim)
- `triage-analyst`: "NEVER modify code", "NEVER guess missing info"
- `code-analyst`: "NEVER modify code"
- `fixer`: "NEVER signal NEEDS_DECOMPOSITION to avoid hard problems", "NEVER change more than necessary", "NEVER modify public APIs"
- `reviewer`: "NEVER modify code", "NEVER run build/test", "NEVER approve with zero findings", "NEVER block for style nitpicks"
- `spec-analyst`: "NEVER modify code", "NEVER design architecture", "NEVER guess missing requirements"

Pattern: `- NEVER {verb phrase} — {reason or clarification}`

## Item 2: Plugin Version Tracking (D12)

### State Schema
- `schema_version` exists at top level (line 35 of state/schema.md), value "1.0", hardcoded
- No field currently reads from plugin.json
- `plugin_version` should go at top level immediately after `schema_version`
- Plugin.json version format: `"6.6.0"` (semver string)

### State Initialization
- `core/state-manager.md` Write Process step 2: "If file does not exist, initialize from schema template"
- Must add explicit instruction to read `.claude-plugin/plugin.json` and stamp `plugin_version` at init

### Resume-Ticket Detection
- State File Detection (Priority 0) reads 5 specific fields + all phase statuses
- Version comparison insertion point: between step 1 (read+parse) and step 2 (determine resume point)
- Heuristic fallback (no state.json) naturally skips version check — backwards compatible

### Core Contract Structure
Canonical 6-section structure (from reading 3+ contracts):
1. `# Title`
2. `## Purpose`
3. `## Input Contract`
4. `## Process` (numbered steps)
5. `## Output Contract`
6. `## Failure Handling`

Optional: `## Constraints` between Output and Failure (seen in status-verification, mcp-body-formatting).
Outlier: mcp-body-formatting uses `## Applies To` and `## Failure Mode`.

## Testing

### xref-core-registry.sh
- Dynamic: auto-discovers core files from disk
- Cross-checks count in CLAUDE.md via grep pattern
- Updating CLAUDE.md 13→14 will satisfy this test automatically

### core-include-refs.sh
- **Hardcoded array of 11 names** (stale — should be 13)
- Checks 4 standard sections per core file
- Minimum reference counts per skill: fix-ticket=7, fix-bugs=7, implement-feature=6, scaffold=3
- **resume-ticket is NOT in this test's check list**

### Constraints Content Testing
- No existing test validates Constraints content broadly
- AC tests (ac3, ac4, ac5) validate specific token constraints in 4 agents using awk+grep pattern
- New test must fill the gap for prompt injection NEVER constraint

### state-schema.sh
- Validates infrastructure presence (schema_version exists, state-manager has atomic write patterns)
- test-state-schema.sh validates field-level details
- Adding plugin_version requires updating schema JSON example + field definitions table
