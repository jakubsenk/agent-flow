# Requirements Specification: Guided Handoff & Feature from Chat

> **Version:** v5.3.0 (Phase 1) + v5.4.0 (Phase 2)
> **Date:** 2026-03-26
> **Classification:** MINOR bumps (no new required config keys)

---

## Phase 1: Guided Handoff (v5.3.0)

### REQ-P1-001: Scaffold Auto-Finalize — Tracker Configuration

**Priority:** MUST
**Phase:** 1

**Description:**
After scaffold generates the project skeleton and commits it (Step 4), the scaffold command MUST automatically guide the user through configuring issue tracker values in the generated CLAUDE.md. This replaces the current behavior of printing "fill in TODO sections" as a next step. The user must NOT be told to run `/onboard --update` — the scaffold command handles it inline.

**Rationale:** User feedback: "NO tell user to run X. Everything must auto-chain."

**Acceptance Criteria:**
1. After Step 4 (git init), scaffold inserts a new Step 4b that detects TODO markers in the generated CLAUDE.md
2. In Interactive mode: scaffold asks the user for each TODO value (Instance URL, Project, Remote, etc.) using the same question format as `/onboard` Step 2-5
3. In YOLO-checkpoint mode: scaffold asks the user for tracker values at the same checkpoint (cannot be auto-filled)
4. In Full YOLO mode: scaffold skips tracker configuration (TODOs remain — no way to guess tracker URLs)
5. After collecting values, scaffold writes them into the generated CLAUDE.md, replacing TODO markers
6. Scaffold re-validates the CLAUDE.md after writing (Config Contract checklist)
7. If the user declines to fill values (hits Enter on all prompts), TODOs remain and scaffold proceeds as before
8. The existing `/onboard --update` command is NOT removed — it remains available for manual use outside scaffold

---

### REQ-P1-002: Scaffold Auto-Finalize — MCP Guidance

**Priority:** SHOULD
**Phase:** 1

**Description:**
After tracker configuration (Step 4b), if the user provided tracker values, scaffold SHOULD display a one-time guidance message about MCP setup. Since scaffold cannot invoke `/init`, it provides the user with a clear, actionable message.

**Acceptance Criteria:**
1. If Issue Tracker Instance was filled in Step 4b, scaffold displays: "To connect to {type} at {instance}, configure an MCP server. Run `/ceos-agents:init` to set it up automatically."
2. If Issue Tracker Instance was NOT filled (TODOs remain), skip MCP guidance
3. The guidance message is informational only — scaffold does not block on MCP availability

---

### REQ-P1-003: Config Validity Gate in implement-feature

**Priority:** MUST
**Phase:** 1

**Description:**
`/implement-feature` MUST validate the Automation Config before starting the pipeline (Step 0b, between MCP pre-flight and issue state setting). If required config sections contain TODO markers or placeholder values, the command blocks with an actionable error message instead of failing mid-pipeline.

**Acceptance Criteria:**
1. After MCP pre-flight (Step 0) and before Step 1 (set issue state), implement-feature checks all required config sections for TODO markers (`<!-- TODO:`) and placeholder values (`<...>`)
2. If any TODO/placeholder found: BLOCK with a specific error listing the incomplete keys and recommending `/ceos-agents:onboard --update` or `/ceos-agents:check-setup`
3. The check uses the same validation logic as `check-setup.md` Block 1 (structural check)
4. Optional config sections with TODO markers produce WARN, not BLOCK
5. Config validity gate also applies to `/fix-ticket` (same Step 0b insertion point)

---

### REQ-P1-004: `/status` Readiness Mode

**Priority:** MUST
**Phase:** 1

**Description:**
`/status` MUST detect when the project is not yet ready for pipeline execution and display what is missing. This enhances the existing "Recommended Next Steps" section (Step 7) to cover post-scaffold states.

**Acceptance Criteria:**
1. If CLAUDE.md exists but contains TODO markers in required sections: `/status` lists each incomplete section with the specific keys that need values
2. If `.mcp.json` is missing or does not contain a server matching the configured tracker type: `/status` reports "MCP server not configured for {type}"
3. The readiness check runs BEFORE the MCP pre-flight check (which would BLOCK) — `/status` must work even when MCP is not configured
4. Readiness information appears in a new `### Configuration Readiness` section above `### Recommended Next Steps`
5. If all required config is complete and MCP is available, the `### Configuration Readiness` section shows "All configuration complete. Pipeline ready."
6. If config is incomplete, the first recommendation in "Recommended Next Steps" is always about fixing the config

---

### REQ-P1-005: Skill Rename — bug-workflow to workflow-router

**Priority:** MUST
**Phase:** 1

**Description:**
Rename the skill from `bug-workflow` to `workflow-router` to reflect that it handles both bug and feature workflows. The skill directory, SKILL.md name field, and all references must be updated.

**Rationale:** User feedback: "Rename to workflow-router or project-workflow (covers bugs AND features)."

**Acceptance Criteria:**
1. Directory renamed: `skills/bug-workflow/` becomes `skills/workflow-router/`
2. SKILL.md frontmatter `name` field updated to `workflow-router`
3. SKILL.md `description` updated to reflect broader scope (bugs, features, scaffolding, etc.)
4. All references in documentation updated (docs/reference/, docs/guides/, CLAUDE.md, README if exists)
5. No functional changes to the intent mapping table (same commands, same routing logic)
6. Old skill name `bug-workflow` is documented as deprecated in the changelog

---

### REQ-P1-006: `parent_run_id` in State Schema

**Priority:** SHOULD
**Phase:** 1

**Description:**
Add an optional `parent_run_id` field to the state schema. This enables tracking when one pipeline spawns or is triggered by another (e.g., scaffold's feature implementation loop creating per-subtask state).

**Acceptance Criteria:**
1. `state/schema.md` includes `parent_run_id` as an optional top-level field (string or null, default: null)
2. When scaffold's Step 7 (feature implementation loop) creates state for subtask execution, it sets `parent_run_id` to the scaffold's `run_id`
3. `/status` can display parent-child relationship if `parent_run_id` is present
4. Backward-compatible: existing state files without `parent_run_id` are valid (field defaults to null)
5. No schema_version bump required (additive change within schema_version 1.0)

---

### REQ-P1-007: Documentation Updates for Phase 1

**Priority:** MUST
**Phase:** 1

**Description:**
All documentation must be updated to reflect Phase 1 changes. This includes reference docs, guides, CLAUDE.md, and the changelog.

**Acceptance Criteria:**
1. `CLAUDE.md` Architecture section reflects the skill rename (workflow-router)
2. `docs/reference/` files updated: command reference (implement-feature changes), agent reference (no changes), config reference (no new required keys), skill reference (workflow-router)
3. Changelog entry for v5.3.0 describes all Phase 1 changes
4. `docs/plans/roadmap.md` updated: Phase 1 items marked DONE, Phase 2 items listed as NEXT
5. Installation/configuration guides reference workflow-router instead of bug-workflow

---

## Phase 2: Feature from Chat + Deploy Optional (v5.4.0)

### REQ-P2-001: Feature from Description — implement-feature --description

**Priority:** MUST
**Phase:** 2

**Description:**
`/implement-feature` MUST accept a `--description "..."` flag that creates a tracker card from the description and then runs the standard implement-feature pipeline on the created card. This enables the "describe a feature, get it implemented" flow without manually creating tracker issues.

**Rationale:** User feedback: "User wants to describe a feature in natural language -> system auto-creates tracker card -> auto-runs implement-feature."

**Acceptance Criteria:**
1. New flag: `--description "..."` (or `--desc "..."` shorthand) accepted by implement-feature
2. When `--description` is provided, Issue ID becomes optional (must not be provided alongside `--description`)
3. implement-feature creates a new issue in the tracker via MCP with: title (extracted from first sentence or summarized), description (full text), type/label set to feature
4. The created issue ID is displayed to the user: "Created {ISSUE-ID}: {title}"
5. The pipeline then proceeds exactly as if the user had run `/implement-feature {ISSUE-ID}`
6. If `--yolo` is combined with `--description`: card is created without confirmation
7. Without `--yolo`: user is shown the card preview and asked to confirm before proceeding
8. If card creation fails (MCP error, auth, etc.): BLOCK with actionable error
9. Config validity gate (REQ-P1-003) runs before card creation — incomplete config blocks early

---

### REQ-P2-002: Workflow Router — Feature from Natural Language

**Priority:** MUST
**Phase:** 2

**Description:**
The workflow-router skill (renamed in Phase 1) MUST recognize natural language feature descriptions and route them to `/implement-feature --description "..."`. This enables the conversational path: user describes what they want, system creates the card and implements it.

**Acceptance Criteria:**
1. New intent row in the workflow-router intent mapping table: "Describe a feature to implement" maps to `ceos-agents:implement-feature` with `--description "{extracted description}"`
2. The router distinguishes between: (a) "implement feature PROJ-42" (existing issue ID) and (b) "I want a dark mode toggle in the settings page" (description, no issue ID)
3. When routing a description: the router extracts the full feature description from the user's message and passes it as `--description`
4. Destructive operation: confirmation required before proceeding (consistent with existing routing rules)
5. If the user's message contains both an issue ID and descriptive text, prefer the issue ID path

---

### REQ-P2-003: Optional Local Deployment Config Section

**Priority:** SHOULD
**Phase:** 2

**Description:**
Add a new optional `### Local Deployment` section to the Automation Config contract. This section configures how the project runs locally for verification purposes. Docker is optional — the section supports both Docker-based and native deployments.

**Rationale:** User feedback: "Docker is optional. But when used, check for occupied ports before starting."

**Acceptance Criteria:**
1. New optional section: `### Local Deployment` with keys:
   - `Type` — `docker` or `native` (required within section)
   - `Start command` — command to start the app (e.g., `docker compose up -d` or `npm start`)
   - `Stop command` — command to stop the app (e.g., `docker compose down` or kill process)
   - `Health check URL` — URL to poll for readiness (e.g., `http://localhost:3000/health`)
   - `Health check timeout` — max seconds to wait for health check (default: 60)
   - `Ports` — comma-separated list of ports the app uses (e.g., `3000, 5432`)
2. Section is optional — if absent, deployment-related features are skipped
3. Adding this section is a MINOR version bump (new optional key)
4. `core/config-reader.md` updated to parse the new section with defaults
5. `check-setup.md` validates the section format if present
6. `onboard.md` offers to configure the section in the optional sections bundle

---

### REQ-P2-004: deployment-verifier Agent

**Priority:** SHOULD
**Phase:** 2

**Description:**
New agent `deployment-verifier` that verifies a local deployment is running and healthy. Uses port checking, health endpoint polling, and Docker container status inspection.

**Acceptance Criteria:**
1. Agent file: `agents/deployment-verifier.md` with frontmatter (name, description, model: sonnet, style)
2. Agent follows Goal / Expertise / Process / Constraints structure
3. Process: (a) Read Local Deployment config, (b) Check ports are free before starting, (c) Start the app, (d) Poll health check URL with timeout, (e) If Docker: check container status, (f) Report verdict
4. Port conflict detection: before starting, check if configured ports are occupied. If occupied, report which port and which process holds it
5. Verdict: `HEALTHY`, `UNHEALTHY` (started but health check fails), `PORT_CONFLICT`, `START_FAILED`, `SKIPPED` (no Local Deployment section)
6. The agent is read-only in terms of code (does not modify source files) but starts/stops processes
7. Model: sonnet (operational verification, not code review)

---

### REQ-P2-005: `/check-deploy` Command

**Priority:** SHOULD
**Phase:** 2

**Description:**
New command `/check-deploy` that invokes the deployment-verifier agent to check if the local deployment is running and healthy. Standalone command for manual use.

**Acceptance Criteria:**
1. Command file: `commands/check-deploy.md` with frontmatter (description, allowed-tools)
2. Reads Local Deployment section from Automation Config
3. If section is absent: "No Local Deployment section in Automation Config. Add one via `/ceos-agents:onboard --update` or manually."
4. If section exists: runs deployment-verifier agent
5. Displays the verdict and details (port status, health check result, container status)
6. `--start` flag: start the app if not running (default: check only)
7. `--stop` flag: stop the app if running
8. The command does not modify code — only manages app lifecycle

---

### REQ-P2-006: Documentation Updates for Phase 2

**Priority:** MUST
**Phase:** 2

**Description:**
All documentation must be updated to reflect Phase 2 changes.

**Acceptance Criteria:**
1. `CLAUDE.md` updated: Architecture section lists deployment-verifier agent, check-deploy command; Config Contract includes Local Deployment in optional sections table; Model Selection table includes deployment-verifier
2. `docs/reference/` files updated: command reference (implement-feature --description, check-deploy), agent reference (deployment-verifier), config reference (Local Deployment section), skill reference (workflow-router feature routing)
3. Changelog entry for v5.4.0
4. `docs/plans/roadmap.md` updated: Phase 2 items marked DONE, deferred items listed
5. Agent count updates: 18 becomes 19 (deployment-verifier added)
6. Command count updates: 24 becomes 25 (check-deploy added)

---

## Deferred Requirements (Roadmap Items)

### REQ-DEF-001: Forge Bridge — Cross-Plugin Integration

**Priority:** MAY (deferred)
**Roadmap Placement:** EXPLORING

**Description:**
Cross-plugin integration between ceos-agents and filip-superpowers. `--expert` flag on scaffold/implement-feature delegates to forge-spec/forge-tdd for deeper specification and TDD workflows.

**Rationale for deferral:** User feedback: "Forge bridge deferred. Cross-plugin integration postponed pending validation." Depends on confirming cross-plugin Skill tool calls work reliably. Implement after BIFITO E2E validation.

**Acceptance Criteria (future):**
1. `--expert` flag on `/scaffold` and `/implement-feature` delegates specification phase to filip-superpowers
2. Routing skill handles cross-plugin intent disambiguation
3. Output format translation between forge spec and ceos-agents spec/ convention

---

### REQ-DEF-002: Standalone Machine Deployment

**Priority:** MAY (deferred)
**Roadmap Placement:** LONG-TERM (under "Standalone CLI Tool")

**Description:**
Run ceos-agents pipelines without Claude Code installed. A standalone CLI or runtime that reads agent .md files and calls Claude API directly.

**Rationale for deferral:** User feedback: "Deferred items MUST go to roadmap. User needs standalone deployment eventually." This is the largest potential evolution item.

**Acceptance Criteria (future):**
1. `npx ceos-agents fix-ticket ISSUE-123` works without Claude Code
2. Agent .md files remain the source of truth (no code duplication)
3. State management uses SQLite instead of JSON files

---

### REQ-DEF-003: `scaffold --extend` for Existing Projects

**Priority:** MAY (deferred)
**Roadmap Placement:** PLANNED

**Description:**
Add epics to an existing scaffolded project. `/scaffold --extend` reads the existing spec/ folder, adds new epics, and runs the implementation loop for just the new epics.

**Acceptance Criteria (future):**
1. `--extend` flag on scaffold detects existing spec/ folder
2. User provides new epic descriptions
3. spec-writer generates only the new epics, preserving existing ones
4. architect decomposes only new epics (existing code is context, not target)
5. Implementation loop runs only for new subtasks

---

### REQ-DEF-004: Batch Feature Implementation

**Priority:** MAY (deferred)
**Roadmap Placement:** PLANNED

**Description:**
Similar to `/fix-bugs` but for features. Process multiple feature issues in sequence or parallel.

**Acceptance Criteria (future):**
1. New command or flag: `/implement-features` or `/implement-feature --batch N`
2. Reads Feature query from config
3. Processes N features sequentially (parallel with worktrees if configured)
4. Per-feature state tracking with parent run coordination
