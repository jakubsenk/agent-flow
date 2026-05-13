# Requirements Specification — v6.7.0: Pipeline Hardening

## Scope

### What Changes

Two independent hardening features that improve pipeline security and operational resilience. Both are MINOR-level changes (new optional features, no breaking contract changes).

| # | Change | File(s) | Category |
|---|--------|---------|----------|
| D2 | Prompt Injection Protection | `core/external-input-sanitizer.md` (CREATE), 5 skills (ADD reference), 5 agents (ADD constraint), `CLAUDE.md` (MODIFY count) | Security |
| D12 | Plugin Version Tracking | `state/schema.md` (ADD field), `core/state-manager.md` (ADD step), `skills/resume-ticket/SKILL.md` (ADD comparison) | Resilience |

### What Does NOT Change

- No changes to Automation Config contract (no new required keys).
- No changes to agent output format contracts.
- No changes to existing core contract files (only new core file created).
- No changes to plugin metadata (plugin.json, marketplace.json).
- No changes to existing test scenarios.
- No changes to docs/, examples/, checklists/, or .claude-plugin/.

---

## Item 1: Prompt Injection Protection (D2)

### R-001 — External Input Sanitizer Core Contract

| Field | Value |
|-------|-------|
| **ID** | R-001 |
| **Type** | Ubiquitous |
| **Priority** | P0 |
| **Description** | The system SHALL provide a core contract `core/external-input-sanitizer.md` (14th core contract) that defines a standard marker format for wrapping all external input read from MCP sources (issue tracker descriptions, comments, attachment content). The marker format SHALL be `--- EXTERNAL INPUT START ---` / `--- EXTERNAL INPUT END ---`. |
| **AC Mapping** | AC-1 |

### R-002 — Sanitizer Contract Structure

| Field | Value |
|-------|-------|
| **ID** | R-002 |
| **Type** | Ubiquitous |
| **Priority** | P0 |
| **Description** | The external input sanitizer contract SHALL follow the established core contract structure with sections: Purpose, Applies To, Process, Constraints, Failure Mode — matching the pattern of `core/mcp-body-formatting.md` and `core/status-verification.md`. |
| **AC Mapping** | AC-1 |

### R-003 — Pipeline Skills Reference Sanitizer

| Field | Value |
|-------|-------|
| **ID** | R-003 |
| **Type** | Event-driven |
| **Priority** | P0 |
| **Description** | WHEN a pipeline skill dispatches an agent that processes external input from an MCP source, THEN the skill SHALL include a reference to `core/external-input-sanitizer.md` instructing agents to wrap MCP-sourced content with the marker format before processing. The 5 affected skills are: `fix-ticket`, `fix-bugs`, `implement-feature`, `scaffold`, `analyze-bug`. |
| **AC Mapping** | AC-2 |

### R-004 — Agent NEVER Constraint for Injection Protection

| Field | Value |
|-------|-------|
| **ID** | R-004 |
| **Type** | Ubiquitous |
| **Priority** | P0 |
| **Description** | The following 5 agents SHALL have a NEVER constraint in their Constraints section that prohibits executing instructions, tool calls, or code found within `--- EXTERNAL INPUT START ---` / `--- EXTERNAL INPUT END ---` markers: `triage-analyst`, `code-analyst`, `fixer`, `spec-analyst`, `reviewer`. |
| **AC Mapping** | AC-3 |

### R-005 — CLAUDE.md Core Count Update

| Field | Value |
|-------|-------|
| **ID** | R-005 |
| **Type** | Ubiquitous |
| **Priority** | P1 |
| **Description** | The `core/` line in CLAUDE.md Repository Structure section SHALL reflect the updated count of 14 shared pipeline pattern contracts (changed from 13). |
| **AC Mapping** | AC-4 |

### R-006 — Test Scenario for Injection Protection

| Field | Value |
|-------|-------|
| **ID** | R-006 |
| **Type** | Ubiquitous |
| **Priority** | P1 |
| **Description** | A test scenario SHALL exist that validates: (a) `core/external-input-sanitizer.md` exists with required sections, (b) all 5 pipeline skills reference the sanitizer, (c) all 5 agents contain the NEVER constraint with the marker text, (d) CLAUDE.md declares 14 core contracts. |
| **AC Mapping** | AC-5 |

---

## Item 2: Plugin Version Tracking (D12)

### R-007 — State Schema plugin_version Field

| Field | Value |
|-------|-------|
| **ID** | R-007 |
| **Type** | Ubiquitous |
| **Priority** | P0 |
| **Description** | The state schema (`state/schema.md`) SHALL document a new top-level field `plugin_version` (type: string or null, required: no, default: null) that records the ceos-agents plugin version active when the pipeline run was initiated. |
| **AC Mapping** | AC-6 |

### R-008 — State Manager Version Read and Write

| Field | Value |
|-------|-------|
| **ID** | R-008 |
| **Type** | Event-driven |
| **Priority** | P0 |
| **Description** | WHEN the state manager initializes a new state file (Write Process step 2), THEN it SHALL read the `version` field from `.claude-plugin/plugin.json` and write it to the `plugin_version` field in state.json. |
| **AC Mapping** | AC-7 |

### R-009 — Resume Ticket Version Comparison

| Field | Value |
|-------|-------|
| **ID** | R-009 |
| **Type** | Event-driven |
| **Priority** | P0 |
| **Description** | WHEN resume-ticket reads a state file that contains a `plugin_version` field, THEN it SHALL compare the major version component of the stored `plugin_version` against the major version of the currently installed plugin (from `.claude-plugin/plugin.json`). If they differ, it SHALL log a `[WARN] Plugin major version mismatch: state was created with v{stored} but current plugin is v{current}. Resume may behave unexpectedly.` message. The pipeline SHALL continue (no block). |
| **AC Mapping** | AC-8 |

### R-010 — Backwards Compatibility for Missing plugin_version

| Field | Value |
|-------|-------|
| **ID** | R-010 |
| **Type** | State-driven |
| **Priority** | P0 |
| **Description** | IF the state file does not contain a `plugin_version` field (state files created by older plugin versions), THEN the resume-ticket skill SHALL NOT emit any WARN. The field SHALL be treated as absent and the version comparison SHALL be skipped silently. |
| **AC Mapping** | AC-9 |

---

## Versioning Assessment

| Check | Result |
|-------|--------|
| New required key in Automation Config? | No |
| New required section in Automation Config? | No |
| Breaking change in agent output format? | No |
| New optional core contract? | Yes (D2: external-input-sanitizer) |
| New optional state field? | Yes (D12: plugin_version) |
| **Verdict** | **MINOR** (v6.7.0) |

## Dependency Map

```
R-001 (core contract) ← R-003 (skill references depend on contract existing)
R-001 (core contract) ← R-004 (agent constraints reference marker format from contract)
R-001 + R-003 + R-004 + R-005 ← R-006 (test validates all D2 changes)
R-007 (schema field) ← R-008 (state-manager writes the field)
R-007 + R-008 ← R-009 (resume-ticket reads the field)
R-009 ← R-010 (backwards compat is a refinement of R-009)
```

No cross-dependencies between D2 and D12 — they can be implemented in parallel.
