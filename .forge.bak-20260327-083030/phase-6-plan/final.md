# Implementation Plan

> **Phases:** v5.3.0 (Phase 1) + v5.4.0 (Phase 2)
> **Date:** 2026-03-26
> **Total tasks:** 12
> **Test files:** 5 visible + 2 hidden = 7

---

## Test File → FC Coverage Map

| Test file | FCs validated |
|-----------|-------------|
| `test-phase1-commands.sh` | FC-001 to FC-020 |
| `test-phase1-skill-rename.sh` | FC-021 to FC-033 |
| `test-phase2-commands.sh` | FC-034 to FC-046 |
| `test-phase2-agent.sh` | FC-052 to FC-059, FC-071, FC-073, FC-074, FC-082 |
| `test-phase2-config.sh` | FC-047 to FC-051, FC-060 to FC-070, FC-072, FC-075 |
| `test-backward-compat.sh` (hidden) | COMPAT-001 to COMPAT-015 |
| `test-edge-cases.sh` (hidden) | FC-076 to FC-083, EDGE cases |

---

## Task Graph

### Batch 1 (parallel — no dependencies)

- **TASK-001:** State schema — add `parent_run_id` field — maps_to: REQ-P1-006
- **TASK-002:** Skill rename — `bug-workflow` to `workflow-router` — maps_to: REQ-P1-005
- **TASK-003:** Config validity gate — implement-feature.md + fix-ticket.md — maps_to: REQ-P1-003
- **TASK-004:** Status readiness mode — status.md — maps_to: REQ-P1-004

### Batch 2 (depends on Batch 1)

- **TASK-005:** Scaffold auto-finalize — scaffold.md Steps 4b, 4c, Step 10 — maps_to: REQ-P1-001, REQ-P1-002
- **TASK-006:** Roadmap + docs — Phase 1 roadmap updates — maps_to: REQ-P1-007

### Batch 3 (parallel — Phase 2 foundation, depends on Batch 2)

- **TASK-007:** deployment-verifier agent — new agent file — maps_to: REQ-P2-004
- **TASK-008:** Local Deployment config — config-reader.md, check-setup.md, onboard.md — maps_to: REQ-P2-003
- **TASK-009:** State schema — add `deployment` object — maps_to: REQ-P2-004 (state)

### Batch 4 (depends on Batch 3)

- **TASK-010:** check-deploy command + implement-feature --description — maps_to: REQ-P2-005, REQ-P2-001
- **TASK-011:** Workflow router Phase 2 — feature routing + deploy intents — maps_to: REQ-P2-002

### Batch 5 (depends on all)

- **TASK-012:** CLAUDE.md + roadmap — Phase 2 documentation updates — maps_to: REQ-P2-006

---

## Task Details

### TASK-001: State schema — add `parent_run_id` field
**Files:** `state/schema.md`
**Action:** MODIFY
**Maps to:** REQ-P1-006, FC-027, FC-028
**Dependencies:** none
**Description:**
1. In the Full Schema Example JSON block (around line 33), add `"parent_run_id": null,` as a new field immediately after `"run_id": "PROJ-42",`.
2. In the Top-Level Field Definitions table (after the `run_id` row at line 119), add a new row:
   `| \`parent_run_id\` | string or null | No | \`null\` | Run ID of the parent pipeline that spawned this run. Set when scaffold creates sub-runs for feature implementation. |`
3. Do NOT change `schema_version` — this is an additive optional field.

**Test validation:**
- `test-phase1-skill-rename.sh` → FC-027, FC-028 (grep for `"parent_run_id"` in JSON and field definitions table)
- `test-backward-compat.sh` → COMPAT-007 (schema_version field still exists)

---

### TASK-002: Skill rename — `bug-workflow` to `workflow-router`
**Files:** `skills/bug-workflow/SKILL.md` → `skills/workflow-router/SKILL.md` (RENAME directory + MODIFY file)
**Action:** RENAME + MODIFY
**Maps to:** REQ-P1-005, FC-021, FC-022, FC-023, FC-024, FC-025, FC-026, FC-030, FC-076
**Dependencies:** none
**Description:**
1. Create directory `skills/workflow-router/`.
2. Copy `skills/bug-workflow/SKILL.md` to `skills/workflow-router/SKILL.md`.
3. In the new SKILL.md:
   - Change frontmatter `name: bug-workflow` → `name: workflow-router`
   - Change frontmatter `description:` to: `Use when the user wants to analyze bugs, fix issues, create PRs, publish changes, scaffold projects, implement features, check deployment, or manage project workflows`
   - Do NOT change the intent mapping table or Process/Constraints sections.
4. Delete directory `skills/bug-workflow/` (the old directory must not exist — FC-022).
5. CLAUDE.md already has no "bug-workflow" references, but verify no active files in `agents/`, `commands/`, `skills/`, `core/`, `state/`, `docs/reference/`, `docs/guides/`, `checklists/`, `examples/`, `.claude-plugin/` contain the string "bug-workflow". The only allowed locations are `CHANGELOG.md` (historical), `docs/plans/` (archival), and `.forge*` (internal).

**Test validation:**
- `test-phase1-skill-rename.sh` → FC-021 (dir exists), FC-022 (old dir gone), FC-023 (name field), FC-024 (description mentions bugs + features), FC-025 (>= 20 table rows), FC-026 (CLAUDE.md no bug-workflow), FC-030 (CLAUDE.md has workflow-router)
- `test-edge-cases.sh` → FC-076 (no active file contains "bug-workflow")

**IMPORTANT:** CLAUDE.md line 32 already lists commands without "bug-workflow" — no CLAUDE.md change needed for this task. FC-030 checks that "workflow-router" appears in CLAUDE.md; it does NOT currently. This will be handled by TASK-012 (CLAUDE.md updates). However, to pass FC-030 independently, this task should add "workflow-router" to CLAUDE.md in the skills line (line 19): change `1 routing skill for natural language access` to `1 routing skill (`workflow-router`) for natural language access`.

---

### TASK-003: Config validity gate — implement-feature.md + fix-ticket.md
**Files:** `commands/implement-feature.md`, `commands/fix-ticket.md`
**Action:** MODIFY (both)
**Maps to:** REQ-P1-003, FC-009 to FC-015, FC-042, FC-083, COMPAT-009, COMPAT-010, COMPAT-015
**Dependencies:** none
**Description:**

**implement-feature.md:**
1. Insert `### 0b. Config validity gate` section between the existing MCP pre-flight / dry-run check sections and Step 1. Current structure: MCP pre-flight (line 58), Dry-run check (line 69). Insert the new section after the dry-run check and before Step 1.
2. The section must:
   - Check required config values for `<!-- TODO:` markers, `<...>` placeholders, and empty strings
   - List incomplete keys in the Detail field: `Detail: Incomplete keys: {comma-separated list}`
   - Use `[ceos-agents]` prefix in the BLOCK output
   - Recommend `/ceos-agents:onboard --update` or `/ceos-agents:check-setup`
   - For optional sections with TODO markers: log `WARN`, not BLOCK (use text like "optional sections with TODO markers produce WARN, not BLOCK")
3. Exact text content per the design document Section 1.2.

**fix-ticket.md:**
1. Insert `### 0b. Config validity gate` section between the existing MCP pre-flight check (line 71) and Step 1. The content is identical to implement-feature.md's Step 0b, adapted with a reference like "Same specification as implement-feature.md Step 0b" or duplicated in full.
2. Must contain: `<!-- TODO:` reference, placeholder check, `[ceos-agents]` block output, `onboard --update` recommendation, and optional-section WARN language.

**CRITICAL:** Do NOT add `Local Deployment` as a required section. It must remain optional. Do NOT remove the existing MCP pre-flight step. Do NOT change the Issue ID handling.

**Test validation:**
- `test-phase1-commands.sh` → FC-009 to FC-015
- `test-edge-cases.sh` → FC-083 (Step 0b before Step 0c positional order)
- `test-backward-compat.sh` → COMPAT-009 (MCP pre-flight preserved), COMPAT-010 (Issue ID path preserved), COMPAT-015 (Local Deployment not required)

---

### TASK-004: Status readiness mode — status.md
**Files:** `commands/status.md`
**Action:** MODIFY
**Maps to:** REQ-P1-004, FC-016 to FC-020
**Dependencies:** none
**Description:**
1. **Modify Step 0 (MCP pre-flight)** at line 10: Change the current hard-stop behavior to soft mode. When MCP is not accessible, set `mcp_available = false` and continue (do NOT STOP). Add text: `set mcp_available = false, continue` or equivalent. The key test assertion (FC-019) is that the string `mcp_available = false` appears in the file.
2. **Insert `### 6b. Configuration Readiness`** section. It must appear BEFORE `### Recommended Next Steps` (currently line 63). Insert around line 60-62. The section must check 4 items:
   - CLAUDE.md presence
   - Automation Config completeness: `<!-- TODO:` markers and placeholders in required sections
   - MCP availability (uses `mcp_available` from Step 0)
   - Build tooling availability
3. The section must display a table with columns `| Check | Status | Detail |`.
4. Display a verdict: "Pipeline ready" or "N items need attention".
5. **Modify Step 7 (Recommended Next Steps)**: If config is incomplete, inject readiness-related recommendation as first item. Add text referencing "config incomplete" or "readiness" so FC-020 grep for `config.*incomplete|incomplete.*config|fix.*config|readiness` succeeds.
6. Ensure the `### 6b. Configuration Readiness` section line number is LOWER than the `### Recommended Next Steps` line number (FC-020 positional check).

**Test validation:**
- `test-phase1-commands.sh` → FC-016 to FC-020

---

### TASK-005: Scaffold auto-finalize — scaffold.md Steps 4b, 4c, Step 10
**Files:** `commands/scaffold.md`
**Action:** MODIFY
**Maps to:** REQ-P1-001, REQ-P1-002, REQ-P1-006 (parent_run_id in scaffold), FC-001 to FC-008, FC-029, FC-077, FC-078, EDGE (Full YOLO)
**Dependencies:** TASK-001 (parent_run_id must exist in schema before scaffold references it)
**Description:**

1. **Insert `### Step 4b: Tracker Configuration (Auto-Finalize)`** between Step 4 (Git Init, line 251) and Step 5 (Architecture, line 263). Content per design Section 1.1:
   - Scan `<!-- TODO:` markers in Automation Config table rows
   - Full YOLO skip: include text like "Full YOLO → skip" within the Step 4b section (within 80 lines of the header — FC-003, EDGE test)
   - Prompt user for values (same format as `/onboard` but inline — do NOT reference `/onboard` or invoke it via Skill tool — FC-077, FC-078)
   - After collecting: write values into CLAUDE.md, replacing TODOs
   - Git commit with message containing "configure Automation Config" (FC-004)
   - If user declines: TODOs remain, display message mentioning `/ceos-agents:onboard --update`

2. **Insert `### Step 4c: MCP Guidance`** immediately after Step 4b. Content:
   - If Instance was filled: display guidance mentioning `/ceos-agents:init` (FC-006)
   - If Instance still TODO: skip

3. **Modify `### Step 7: Feature Implementation Loop`** (line 338): When creating state for subtask execution, set `parent_run_id` to the scaffold's `run_id`. Add a line like: `Set \`parent_run_id\` to the scaffold's \`run_id\` in the subtask state.json.` (FC-029)

4. **Modify `### Step 10: Final Report`** (line 457) and the `### Remaining TODOs in CLAUDE.md:` section (line 478):
   - Make TODO listing conditional: if TODOs remain → list them; else → `(none — all configuration values set)` (FC-007)
   - Remove unconditional "fill in TODO sections" text (line 141 legacy and line 483 — FC-008). Replace with conditional text.
   - Update remaining legacy flow L6 to reference `/onboard --update`.

5. **Preserve all existing steps** (Step 1, Step 4, Step 5, Step 10 headers must still exist — COMPAT-011).

**Test validation:**
- `test-phase1-commands.sh` → FC-001 to FC-008
- `test-phase1-skill-rename.sh` → FC-029 (parent_run_id in scaffold)
- `test-edge-cases.sh` → FC-077 (no /onboard in Step 4b), FC-078 (no Skill tool in Step 4b), EDGE (Full YOLO proximity)
- `test-backward-compat.sh` → COMPAT-011 (Steps 1, 4, 5, 10 preserved)

---

### TASK-006: Roadmap + Phase 1 docs
**Files:** `docs/plans/roadmap.md`
**Action:** MODIFY
**Maps to:** REQ-P1-007, FC-031, FC-032, FC-033
**Dependencies:** TASK-001 through TASK-005 (must know what was implemented to document it)
**Description:**

1. **Add `## DONE — v5.3.0 (Guided Handoff)` section** after the v5.2.0 DONE section (around line 134). Include:
   - Scaffold Auto-Finalize (Steps 4b, 4c)
   - Config Validity Gate (implement-feature, fix-ticket)
   - Status Readiness Mode
   - Skill rename (bug-workflow → workflow-router)
   - parent_run_id in state schema
   - Files affected

2. **Add Phase 2 items as NEXT/PLANNED** in the "PLANNED — Next" section:
   - "Feature from description (`--description` flag)" — mention `feature from description` or `local deployment` or `check-deploy` (FC-032)
   - "Local Deployment config + check-deploy command"
   - "deployment-verifier agent"

3. **Add deferred items** (FC-033 requires all 4):
   - Forge bridge / cross-plugin integration (already exists at line 136 as EXPLORING — verify it's still there)
   - Standalone deployment / standalone CLI (already exists at line 287 — verify)
   - `scaffold --extend` — add if not present
   - Batch feature implementation — add if not present

4. **Update version header** from v5.2.0 to v5.3.0.

**Test validation:**
- `test-phase1-skill-rename.sh` → FC-031 (v5.3.0 in roadmap), FC-032 (Phase 2 feature items), FC-033 (4 deferred items)

---

### TASK-007: deployment-verifier agent
**Files:** `agents/deployment-verifier.md`
**Action:** CREATE
**Maps to:** REQ-P2-004, FC-052 to FC-059, FC-079, FC-082
**Dependencies:** none (can start with Batch 3)
**Description:**

Create `agents/deployment-verifier.md` with exact content from design Section 3.1. Requirements:

1. **Frontmatter** in exact order (FC-079): `name`, `description`, `model`, `style`:
   ```
   ---
   name: deployment-verifier
   description: Verifies local deployment health — checks ports, starts app, polls health endpoint, inspects Docker containers
   model: sonnet
   style: Diagnostic, port-aware, non-destructive
   ---
   ```

2. **Section order** (FC-054): `## Goal` → `## Expertise` → `## Process` → `## Constraints`

3. **Process section** (FC-055): At least 5 numbered steps covering:
   - Read config / Local Deployment (step 1)
   - Port scan / port check (step 2) — MUST appear BEFORE start app step (FC-056)
   - Start app (step 4)
   - Health check polling (step 5)
   - Determine verdict (step 8)

4. **Constraints section** (FC-057): At least 5 lines starting with `- NEVER`

5. **All 5 verdict states** (FC-058): HEALTHY, UNHEALTHY, PORT_CONFLICT, START_FAILED, SKIPPED

6. **Output section** or report template (FC-059): Include a section with "## Output" or "Output template" heading showing the structured report format.

7. **No code-modification instructions** (FC-082): Do NOT include text like "edit source", "modify source", "Write tool", "Edit tool".

**Test validation:**
- `test-phase2-agent.sh` → FC-052 to FC-059, FC-082, FC-079
- `test-backward-compat.sh` → COMPAT-001 (original 18 agents still exist)

---

### TASK-008: Local Deployment config — config-reader, check-setup, onboard
**Files:** `core/config-reader.md`, `commands/check-setup.md`, `commands/onboard.md`
**Action:** MODIFY (all three)
**Maps to:** REQ-P2-003, FC-047, FC-048, FC-050, FC-051
**Dependencies:** none (can start with Batch 3)
**Description:**

**core/config-reader.md:**
1. Add a new entry to the optional sections list (after the `### Notifications` entry, around line 36):
   ```
   - `### Local Deployment` → `deployment.type` (required within section: `docker` or `native`), `deployment.start_command`, `deployment.stop_command`, `deployment.health_check_url`, `deployment.health_check_timeout` (default: 60), `deployment.ports` (comma-separated string → parsed to list of integers)
   ```
2. Include text marking the section as optional: "If `### Local Deployment` is absent, skip" or use existing pattern "missing section → use defaults".
3. Mention "Health check timeout" default of `60` explicitly (FC-048).
4. All 6 keys must appear: Type, Start command, Stop command, Health check URL, Health check timeout, Ports (FC-047).

**commands/check-setup.md:**
1. Add `Local Deployment` to the optional sections validation list in Block 1 Step 5. Add a line like:
   ```
   - Local Deployment (if exists: check Type is docker|native, Start command non-empty, Health check URL is a valid URL pattern)
   ```

**commands/onboard.md:**
1. Add `Local Deployment` to the optional sections multi-select checklist. Add an entry like:
   ```
   [13] Local Deployment — local app startup, health check, port configuration
   ```
2. Add Local Deployment processing with keys: Type (docker/native), Start command, Stop command, Health check URL, Health check timeout (default: 60), Ports.

**Test validation:**
- `test-phase2-config.sh` → FC-047 (config-reader has Local Deployment + all 6 keys), FC-048 (default 60 + optional documentation), FC-050 (onboard has Local Deployment), FC-051 (check-setup has Local Deployment)

---

### TASK-009: State schema — add `deployment` object
**Files:** `state/schema.md`
**Action:** MODIFY
**Maps to:** REQ-P2-004 (state), FC-069, FC-070
**Dependencies:** TASK-001 (parent_run_id already added; this task adds deployment object)
**Description:**

1. In the Full Schema Example JSON block, add a `"deployment"` object before the closing `}`. Insert after the `"block": null` field (around line 110):
   ```json
   "deployment": {
     "status": "pending",
     "verdict": null,
     "ports": [],
     "health_check": null
   }
   ```

2. In the Top-Level Field Definitions table, add rows for:
   - `deployment` — object, Yes, —, Deployment-verifier phase state.
   - `deployment.status` — string, Yes, `"pending"`, Phase status. See Step Status Enum.
   - `deployment.verdict` — string or null, No, `null`, Deployment verdict: HEALTHY, UNHEALTHY, PORT_CONFLICT, START_FAILED, or SKIPPED.
   - `deployment.ports` — object[], No, `[]`, Port scan results: [{port, status, process}].
   - `deployment.health_check` — string or null, No, `null`, Health check result: HEALTHY, UNHEALTHY, UNREACHABLE, or skipped.

3. Do NOT remove any existing fields. Preserve `schema_version`, all existing phase objects.

**Test validation:**
- `test-phase2-config.sh` → FC-069 ("deployment" in JSON + status/verdict/ports/health_check fields), FC-070 (deployment.status, deployment.verdict, deployment.ports, deployment.health_check in field definitions)
- `test-backward-compat.sh` → COMPAT-007 (schema_version preserved)

---

### TASK-010: check-deploy command + implement-feature --description
**Files:** `commands/check-deploy.md` (CREATE), `commands/implement-feature.md` (MODIFY)
**Action:** CREATE + MODIFY
**Maps to:** REQ-P2-005, REQ-P2-001, FC-034 to FC-042, FC-060 to FC-068, FC-080, FC-083, EDGE
**Dependencies:** TASK-003 (Step 0b must exist before Step 0c is added), TASK-008 (Local Deployment config must exist)
**Description:**

**commands/check-deploy.md (CREATE):**
1. Create with content from design Section 2.1. Frontmatter in order (FC-080): `description` before `allowed-tools`:
   ```
   ---
   description: Check local deployment health — start, stop, or verify app status
   allowed-tools: Bash, Read, Glob, Grep, Task
   ---
   ```
2. Must include `--start` and `--stop` flag handling (FC-063).
3. Must have at least 4 steps or numbered step sections covering port check and health check (FC-064).
4. Port check must include `lsof` and `ss` or `netstat` (FC-065).
5. Must show "No Local Deployment section" message when config is absent (FC-066).
6. Must include "NEVER modify source code" in Rules section (FC-067).
7. Must block start on port conflict with explicit stop/block language (FC-068).

**commands/implement-feature.md (MODIFY):**
1. **Update Input line** (line 8): Change `Issue ID (required)` to `Issue ID (required unless --description)`. Add `--description "..."` (or `--desc "..."`) to the optional flags list.
2. **Update flag parsing section** (line 32): Add handling for `--description "..."` and `--desc "..."`. Set `description_mode = true`. Add mutual exclusion: "Cannot use --description with an Issue ID" or equivalent (FC-036 — grep for "mutually exclusive|cannot.*combined|not.*provided.*alongside").
3. **Insert `### 0c. Feature card creation (--description mode only)`** AFTER Step 0b (config validity gate) — FC-042 positional check. The section must:
   - Be conditional on `description_mode` — include text like "If `description_mode = false` → skip" within 5 lines of the header (FC-083, EDGE tests)
   - Create issue via MCP (FC-038)
   - Display "Created {ISSUE-ID}: {title}" (FC-039)
   - BLOCK on MCP failure with "card creation fails" language (FC-040)
   - Show card preview/confirmation when --yolo is NOT set (FC-041)

**Test validation:**
- `test-phase2-commands.sh` → FC-034 to FC-042
- `test-phase2-config.sh` → FC-060 to FC-068
- `test-edge-cases.sh` → FC-080, FC-083, EDGE cases
- `test-backward-compat.sh` → COMPAT-010 (Issue ID path still works), COMPAT-015 (Local Deployment not required)

---

### TASK-011: Workflow router Phase 2 — feature routing + deploy intents
**Files:** `skills/workflow-router/SKILL.md`
**Action:** MODIFY
**Maps to:** REQ-P2-002, FC-043 to FC-046
**Dependencies:** TASK-002 (skill must be renamed first), TASK-010 (check-deploy and --description must exist)
**Description:**

1. **Add new intent rows** to the Intent Mapping table (after the existing `discuss` row):
   ```
   | Describe a feature to implement (no issue ID) | `ceos-agents:implement-feature` | --description "{extracted description}" + optional: --yolo | Yes |
   | Check if deployment is running | `ceos-agents:check-deploy` | None | No |
   | Start local deployment | `ceos-agents:check-deploy` | --start | Yes |
   | Stop local deployment | `ceos-agents:check-deploy` | --stop | Yes |
   ```

2. **Update Process section** to add intent disambiguation logic. After "Extract arguments (issue ID or count) from the user's message", add a new step:
   ```
   3. **Intent disambiguation for implement-feature:**
      - If the message contains a recognizable Issue ID pattern (e.g., PROJ-42, #123) → use Issue ID path
      - If the message describes a feature in natural language without an Issue ID → use --description path
      - If ambiguous → ask: "Did you mean to implement an existing issue, or create a new feature from your description?"
   ```

3. The feature-from-description row must:
   - Contain `--description` text (FC-043)
   - Be marked `Yes` in Destructive column (FC-046)
4. check-deploy rows must include `--start` and `--stop` (FC-044).
5. Process must contain disambiguation language like "distinguish" or "Issue ID vs description" (FC-045).

**Test validation:**
- `test-phase2-commands.sh` → FC-043 to FC-046

---

### TASK-012: CLAUDE.md + roadmap — Phase 2 documentation updates
**Files:** `CLAUDE.md`, `docs/plans/roadmap.md`
**Action:** MODIFY (both)
**Maps to:** REQ-P2-006, FC-049, FC-071, FC-072, FC-073, FC-074, FC-075, FC-081
**Dependencies:** All previous tasks (must reflect final state of all changes)
**Description:**

**CLAUDE.md:**
1. **Repository Structure** (line 17-18):
   - Change `18 agent definitions` → `19 agent definitions` (FC-074)
   - Change `24 orchestration commands` → `25 orchestration commands` (FC-074)

2. **Architecture: 2-Layer System** (line 32-33):
   - Add `/check-deploy` to the Commands list (FC-072)
   - Add `deployment-verifier` to the Agents list (FC-071)

3. **Model Selection table** (line 101-105):
   - Add `deployment-verifier` to the sonnet row agents list (FC-073). Change the sonnet line to include `deployment-verifier` after `browser-verifier`.

4. **Key Conventions** (line 109-110):
   - Add `deployment-verifier` to the appropriate list. It is read-only for source code but starts/stops processes — classify it in the read-only list or add a note.

5. **Optional sections table** (after line 153):
   - Add row: `| Local Deployment | Type, Start command, Stop command, Health check URL, Health check timeout, Ports | (none) |` (FC-049)
   - This MUST be in the optional table, NOT the required table (FC-081).

6. Ensure `workflow-router` appears somewhere in CLAUDE.md (FC-030 — likely already added by TASK-002 in the skills line).

**docs/plans/roadmap.md:**
1. Add `## DONE — v5.4.0 (Feature from Chat + Deployment)` section (FC-075). Include:
   - implement-feature --description
   - workflow-router feature routing
   - Local Deployment config
   - deployment-verifier agent
   - check-deploy command
   - State schema deployment fields
2. Move Phase 2 items from NEXT/PLANNED to the DONE section.
3. Update version header.

**Test validation:**
- `test-phase2-agent.sh` → FC-071 (CLAUDE.md lists deployment-verifier), FC-073 (sonnet model table), FC-074 (19 agents, 25 commands)
- `test-phase2-config.sh` → FC-049 (CLAUDE.md Local Deployment row with keys), FC-072 (check-deploy in CLAUDE.md), FC-075 (v5.4.0 in roadmap)
- `test-edge-cases.sh` → FC-081 (Local Deployment in optional table, not required)

---

## Execution Summary

| Batch | Tasks | Parallelism | Files touched | Key FCs |
|-------|-------|-------------|---------------|---------|
| 1 | TASK-001, TASK-002, TASK-003, TASK-004 | 4 parallel | 5 files | FC-001–FC-020, FC-021–FC-030 |
| 2 | TASK-005, TASK-006 | 2 parallel | 2 files | FC-001–FC-008, FC-029, FC-031–FC-033 |
| 3 | TASK-007, TASK-008, TASK-009 | 3 parallel | 5 files | FC-047–FC-059, FC-069–FC-070 |
| 4 | TASK-010, TASK-011 | 2 parallel | 3 files | FC-034–FC-046, FC-060–FC-068 |
| 5 | TASK-012 | 1 serial | 2 files | FC-049, FC-071–FC-075, FC-081 |

**Total:** 12 tasks, 5 batches, touches 14 unique files (6 modified, 2 created, 1 renamed).

### File Change Matrix

| File | Tasks | Action |
|------|-------|--------|
| `state/schema.md` | TASK-001, TASK-009 | MODIFY (2x) |
| `skills/bug-workflow/SKILL.md` | TASK-002 | DELETE (rename) |
| `skills/workflow-router/SKILL.md` | TASK-002, TASK-011 | CREATE, then MODIFY |
| `commands/implement-feature.md` | TASK-003, TASK-010 | MODIFY (2x) |
| `commands/fix-ticket.md` | TASK-003 | MODIFY |
| `commands/status.md` | TASK-004 | MODIFY |
| `commands/scaffold.md` | TASK-005 | MODIFY |
| `docs/plans/roadmap.md` | TASK-006, TASK-012 | MODIFY (2x) |
| `agents/deployment-verifier.md` | TASK-007 | CREATE |
| `core/config-reader.md` | TASK-008 | MODIFY |
| `commands/check-setup.md` | TASK-008 | MODIFY |
| `commands/onboard.md` | TASK-008 | MODIFY |
| `commands/check-deploy.md` | TASK-010 | CREATE |
| `CLAUDE.md` | TASK-002, TASK-012 | MODIFY (2x) |

### Risk Notes

1. **TASK-005 is the largest task** (scaffold.md is 490+ lines). The Step 4b section is ~60 lines of new content. Monitor for context window issues.
2. **TASK-010 modifies implement-feature.md for the second time** (after TASK-003). The agent must read the post-TASK-003 state of the file.
3. **TASK-002 (skill rename) requires directory deletion** — the `skills/bug-workflow/` directory must be fully removed, not just emptied.
4. **FC-076 (hidden edge case)** checks that NO active file contains "bug-workflow" — the CHANGELOG.md reference is allowed (it's historical), but any newly written file must not contain the old name.
5. **FC-081 (hidden edge case)** checks that "Local Deployment" does NOT appear in the first ~10 rows after the required sections table header. The CLAUDE.md edit in TASK-012 must place it in the optional table only.
