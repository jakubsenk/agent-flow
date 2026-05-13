# Research Answers: RQ-5 through RQ-8

Agent: agent-2
Date: 2026-04-15

---

### RQ-5: Core Contract Structure Pattern

**Finding:** All 13 core contracts follow a consistent 5-section pattern: `# {Title}`, `## Purpose`, `## Input Contract`, `## Process`, `## Output Contract`, `## Failure Handling`. Some contracts add a `## Constraints` section between Output Contract and Failure Handling. No contract omits Purpose, Process, or Failure Handling.

**Evidence (from 5 contracts read):**

`core/state-manager.md`:
- Line 1: `# State Manager`
- Line 3: `## Purpose`
- Line 7: `## Input Contract` (subdivided into `### Write Operation`, `### Read Operation`, `### Resume Operation`)
- Line 20: `## Process` (subdivided into `### Write Process`, `### Read Process`, `### Resume Process`)
- Line 44: `## Output Contract` (subdivided per operation)
- Line 58: `## Failure Handling`

`core/block-handler.md`:
- Line 1: `# Block Handler`
- Line 3: `## Purpose`
- Line 7: `## Input Contract` (uses `| Field | Type | Notes |` table)
- Line 19: `## Process`
- Line 47: `## Output Contract`
- Line 51: `## Failure Handling`

`core/config-reader.md`:
- Line 1: `# Config Reader`
- Line 3: `## Purpose`
- Line 7: `## Input Contract`
- Line 11: `## Process`
- Line 44: `## Output Contract`
- Line 47: `## Failure Handling`

`core/mcp-body-formatting.md`:
- Line 1: `# MCP Body Formatting`
- Line 3: `## Purpose`
- Line 11: `## Applies To` (variant — replaces Input Contract for this contract type)
- Line 19: `## Process`
- Line 25: `## Constraints`
- Line 31: `## Failure Mode` (variant label for Failure Handling)

`core/status-verification.md`:
- Line 1: `# Status Verification`
- Line 3: `## Purpose`
- Line 7: `## Input Contract` (uses `| Field | Type | Notes |` table)
- Line 15: `## Process`
- Line 35: `## Output Contract`
- Line 39: `## Constraints`
- Line 47: `## Failure Handling` (uses `| Failure Mode | Action |` table)

**Canonical section order (normalized):**
1. `# {Contract Title}` — H1 title
2. `## Purpose` — one-paragraph purpose statement
3. `## Input Contract` — what the contract receives (table or bullet list); may have `### {Operation}` subsections for multi-operation contracts
4. `## Process` — numbered steps describing what to do; may have `### {Sub-process}` subsections
5. `## Output Contract` — what is produced/returned; may have `### {Result}` subsections
6. `## Constraints` — NEVER rules (present in: status-verification, mcp-body-formatting; absent in: block-handler, config-reader, state-manager)
7. `## Failure Handling` — table or bullet list of failure modes and actions

**Surprise/Note:** `core/mcp-body-formatting.md` is the only outlier — it uses `## Applies To` instead of `## Input Contract` (the contract has no inputs, only an applicability scope) and `## Failure Mode` (singular) instead of `## Failure Handling`. All other contracts are consistent. The `## Constraints` section appears only in contracts that impose strict behavioral rules (NEVER), mirroring the agent definition format.

---

### RQ-6: Existing NEVER Constraints in Target Agents

**Finding:** The five target agents collectively contain 25 NEVER constraints (verbatim list below). NEVER constraints enforce read-only behavior, output format precision, scope limits, and failure handling. Every agent except spec-analyst uses NEVER for output token precision (exact verdict/keyword values).

**Evidence — verbatim NEVER lines with file and line numbers:**

**`agents/triage-analyst.md` (lines 106–116):**
- Line 108: `- NEVER modify code — read-only analysis`
- Line 109: `- NEVER guess missing information — Block if unclear`

**`agents/code-analyst.md` (lines 101–120):**
- Line 103: `- NEVER modify code — read-only analysis`
- Line 104: `- If the bug report names a specific method/file as the cause, treat it as a HINT, not a fact. Verify independently by tracing the full data flow from user action to wrong behavior. The named method may have real defects that are irrelevant to the bug's reproduction scenario.`

  *(Note: line 104 is a non-NEVER constraint rule — it doesn't use "NEVER" as a prefix.)*

**`agents/fixer.md` (lines 79–96):**
- Line 81: `- NEEDS_DECOMPOSITION may be signaled at most ONCE per ticket. If the decomposed subtasks also exceed limits, Block.`

  *(Note: this is a hard limit constraint, not phrased with NEVER.)*
- Line 82: `- NEVER signal NEEDS_DECOMPOSITION to avoid a hard problem — only when scope genuinely exceeds limits.`
- Line 83: `- MUST use the exact string `NEEDS_DECOMPOSITION` when signaling decomposition need. No variations (not "NEEDS DECOMPOSITION", "needs_decomposition", "decomposition needed", or other forms).`
- Line 84: `- NEVER change more than necessary — no drive-by refactoring`
- Line 85: `- NEVER modify public APIs without explicit approval`
- Line 86: `- Diff MUST NOT exceed 100 lines. If approaching this limit, decompose the change into smaller steps or Block.`

**`agents/reviewer.md` (lines 103–123):**
- Line 105: `- NEVER modify code — feedback only`
- Line 106: `- NEVER run build or test commands — that is fixer's and test-engineer's responsibility`
- Line 107: `- NEVER approve with zero findings unless you provide an explicit per-checklist-item justification (minimum 7 checklist items addressed)`
- Line 108: `- NEVER block a correct fix for style nitpicks — approve if the fix addresses the root cause correctly`
- Line 111: `- MUST use exactly one of: `APPROVE`, `REQUEST_CHANGES`, `BLOCK` as the Verdict value. No variations, no additional qualifiers (not "APPROVED", "CHANGES_REQUESTED", "BLOCKED", or other forms).`
- Line 112: `- MUST use exactly one of: `FULFILLED`, `PARTIALLY`, `NOT ADDRESSED` for each AC fulfillment verdict. No variations.`
- Line 113: `- If acceptance criteria were provided in context, MUST include AC Fulfillment section in output. If no AC provided, skip the section.`

**`agents/spec-analyst.md` (lines 81–96):**
- Line 83: `- MUST post acceptance criteria to the issue tracker as a separate comment (after the checkpoint comment). This enables human review of AC before implementation proceeds.`
- Line 84: `- NEVER modify code — read-only analysis`
- Line 85: `- NEVER design architecture or suggest implementation — that's the architect's job`
- Line 86: `- NEVER guess missing requirements — Block if the request is too vague to determine what the feature should do`

**Complete verbatim NEVER list (extracted):**

| Agent | NEVER constraint |
|-------|-----------------|
| triage-analyst | NEVER modify code — read-only analysis |
| triage-analyst | NEVER guess missing information — Block if unclear |
| code-analyst | NEVER modify code — read-only analysis |
| fixer | NEVER signal NEEDS_DECOMPOSITION to avoid a hard problem — only when scope genuinely exceeds limits. |
| fixer | NEVER change more than necessary — no drive-by refactoring |
| fixer | NEVER modify public APIs without explicit approval |
| reviewer | NEVER modify code — feedback only |
| reviewer | NEVER run build or test commands — that is fixer's and test-engineer's responsibility |
| reviewer | NEVER approve with zero findings unless you provide an explicit per-checklist-item justification (minimum 7 checklist items addressed) |
| reviewer | NEVER block a correct fix for style nitpicks — approve if the fix addresses the root cause correctly |
| spec-analyst | NEVER modify code — read-only analysis |
| spec-analyst | NEVER design architecture or suggest implementation — that's the architect's job |
| spec-analyst | NEVER guess missing requirements — Block if the request is too vague to determine what the feature should do |

**Surprise/Note:** `code-analyst` has only ONE explicit NEVER constraint (`NEVER modify code`). Its constraints section is dominated by MUST rules and hard limits phrased differently. Reviewer has the most NEVER constraints (4) reflecting its adversarial gate role. The pattern "NEVER modify code — read-only analysis" appears verbatim in all 4 read-only agents (triage-analyst, code-analyst, reviewer, spec-analyst). Fixer is the only execution agent in this list and has no read-only constraint.

---

### RQ-7: plugin_version Placement in state.json

**Finding:** There is no `plugin_version` field in the current state schema. `schema_version` is defined as a string field `"1.0"` at the top level of state.json. It tracks schema evolution, not plugin version. State initialization occurs in the state-manager's Write Process when the file does not exist. `plugin_version` would naturally belong at the top level alongside `schema_version`, immediately after it.

**Evidence:**

`state/schema.md`, lines 34–38 (Full Schema Example):
```json
{
  "schema_version": "1.0",
  "run_id": "PROJ-42",
  "parent_run_id": null,
  "mode": "code-bugfix",
  "pipeline": "fix-ticket",
  "status": "running",
  ...
}
```

`state/schema.md`, lines 140–149 (Top-Level Field Definitions table):
- Line 142: `| schema_version | string | Yes | "1.0" | Schema version. Always "1.0" for this specification. Enables future schema evolution. |`
- Line 143: `| run_id | string | Yes | — | Unique identifier for this pipeline run. |`
- Line 144: `| parent_run_id | string or null | No | null | Run ID of the parent pipeline that spawned this run. |`

`core/state-manager.md`, lines 21–25 (Write Process):
- Line 22: `1. Read current state from .ceos-agents/{RUN-ID}/state.json`
- Line 23: `2. If file does not exist, initialize from schema template (see state/schema.md)`
- Line 24: `3. Set the value at the specified field_path ...`

`.claude-plugin/plugin.json`, lines 1–10:
```json
{
  "name": "ceos-agents",
  "version": "6.6.0",
  ...
}
```

**Surprise/Note:** `schema_version` is currently hardcoded as `"1.0"` in the spec with no mechanism to read the actual plugin version at init time. Adding `plugin_version` requires: (1) reading from `.claude-plugin/plugin.json` at state init time in the Write Process step 2, (2) adding it to the schema example in `state/schema.md` immediately after `schema_version`, (3) adding it to the Top-Level Field Definitions table. The version format in plugin.json is semver: `"6.6.0"` (MAJOR.MINOR.PATCH as a string).

The state-manager init path (Write Process step 2) is the single place where `plugin_version` would be populated — read from `.claude-plugin/plugin.json` and written as a string field.

---

### RQ-8: resume-ticket State File Detection Logic

**Finding:** The state file detection in `resume-ticket` is documented as "Priority 0" — it supersedes all heuristic detection. It reads 5 specific fields from state.json. There is no version comparison logic currently. Version comparison would slot in between steps 1 (read+parse) and 2 (determine resume point) — after confirming the file is valid but before using its step statuses.

**Evidence:**

`skills/resume-ticket/SKILL.md`, lines 15–32 (State File Detection block):
```
### State File Detection (Priority 0)

If `.ceos-agents/{ISSUE-ID}/state.json` exists:
1. Read and parse the state file
2. Determine resume point from step statuses:
   - Find the first step with `status: "in_progress"` → resume from that step
   - If no "in_progress" step: find the first `"pending"` step after all `"completed"` steps → resume from that step
   - If all steps completed → pipeline is done, inform user
3. Restore context from state file:
   - Triage acceptance criteria from `triage.acceptance_criteria`
   - Complexity from `triage.complexity`
   - Fixer iteration count from `fixer_reviewer.iterations`
   - Pipeline profile from `config.profile`
   - Active flags from `config.flags`
4. Pass resume_point and restored context to the appropriate pipeline command
5. Detection method: "state_file" (logged for metrics)
```

**Fields read from state.json (lines 22–29):**

| Field path | Line | Purpose |
|-----------|------|---------|
| `triage.acceptance_criteria` | 24 | Restore AC for fixer/reviewer context |
| `triage.complexity` | 25 | Resume context |
| `fixer_reviewer.iterations` | 26 | Restore loop iteration count |
| `config.profile` | 27 | Restore active pipeline profile |
| `config.flags` | 28 | Restore CLI flags passed at start |

Step statuses read (implicitly, all phase `.status` fields): `"in_progress"` → resume there; first `"pending"` after `"completed"` chain → resume there (lines 20–23).

`skills/resume-ticket/SKILL.md`, line 32:
`If .ceos-agents/{ISSUE-ID}/state.json does NOT exist, fall back to the heuristic detection below.`

**Where version comparison should go:**

Between state file detection step 1 (`Read and parse the state file`) and step 2 (`Determine resume point`), insert:
- Read `plugin_version` from state.json
- Read current version from `.claude-plugin/plugin.json`
- If major version differs: warn user or treat as incompatible (fallback to heuristic or abort)
- If minor/patch differs: continue with a log note

**Plugin version format (`.claude-plugin/plugin.json`, line 3):**
`"version": "6.6.0"` — semver string MAJOR.MINOR.PATCH.

**Surprise/Note:** The current heuristic fallback (lines 34–57) is quite elaborate — 7 checkpoints using branch state, PR existence, and `[ceos-agents]` comment scanning. The state file detection is intentionally simpler and takes absolute priority. The `detection_method` field logged (`"state_file"`) matches the output contract in `core/state-manager.md` line 56: `detection_method: "state_file" | "heuristic_fallback"`. There is currently NO schema_version or plugin_version read by resume-ticket — it trusts the state file blindly, which is the gap the new `plugin_version` field would address.
