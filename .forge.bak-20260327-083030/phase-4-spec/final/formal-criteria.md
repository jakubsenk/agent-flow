# Formal Acceptance Criteria: Machine-Checkable

> **Date:** 2026-03-26
> **Verification method:** Read the specified file and check the stated condition.

---

## Phase 1: Guided Handoff (v5.3.0)

### Scaffold Auto-Finalize

**FC-001:** File `commands/scaffold.md` contains a section headed `### Step 4b: Tracker Configuration` between Step 4 (Git Init) and Step 5 (Architecture & Decomposition).

**FC-002:** `commands/scaffold.md` Step 4b contains logic to scan for `<!-- TODO:` markers in the generated CLAUDE.md and prompt the user for each incomplete value.

**FC-003:** `commands/scaffold.md` Step 4b contains a conditional: "If mode is Full YOLO → skip" for tracker configuration.

**FC-004:** `commands/scaffold.md` Step 4b contains a `git commit` command with message containing "configure Automation Config" after writing values.

**FC-005:** File `commands/scaffold.md` contains a section headed `### Step 4c: MCP Guidance` after Step 4b.

**FC-006:** `commands/scaffold.md` Step 4c displays a message mentioning `/ceos-agents:init` when Issue Tracker Instance was filled.

**FC-007:** `commands/scaffold.md` Step 10 (Final Report) contains conditional logic: if TODOs remain → list them, else → "(none — all configuration values set)".

**FC-008:** `commands/scaffold.md` Step 10 does NOT contain "fill in TODO sections" as an unconditional next step (the old behavior is replaced by conditional TODOs listing).

### Config Validity Gate

**FC-009:** File `commands/implement-feature.md` contains a section headed `### 0b. Config validity gate` between MCP pre-flight (Step 0) and Step 1 (Set issue state).

**FC-010:** `commands/implement-feature.md` Step 0b checks for `<!-- TODO:` markers AND `<...>` placeholders in required config values.

**FC-011:** `commands/implement-feature.md` Step 0b produces a BLOCK with the `[ceos-agents]` prefix when incomplete values are found.

**FC-012:** `commands/implement-feature.md` Step 0b lists incomplete keys in the BLOCK Detail field.

**FC-013:** `commands/implement-feature.md` Step 0b Recommendation mentions `/ceos-agents:onboard --update`.

**FC-014:** File `commands/fix-ticket.md` contains a section headed `### 0b. Config validity gate` with the same validation logic as implement-feature.

**FC-015:** Both `commands/implement-feature.md` and `commands/fix-ticket.md` Step 0b treat optional section TODO markers as WARN, not BLOCK.

### Status Readiness Mode

**FC-016:** File `commands/status.md` contains a section headed `### 6b. Configuration Readiness` or equivalent (between Step 6 totals and Step 7 recommendations).

**FC-017:** `commands/status.md` Step 6b checks for: CLAUDE.md presence, TODO markers in required sections, MCP availability, and build tooling.

**FC-018:** `commands/status.md` Step 6b displays a table with Check/Status/Detail columns.

**FC-019:** `commands/status.md` Step 0 (MCP pre-flight) uses soft mode: sets `mcp_available = false` instead of STOP when MCP is not accessible.

**FC-020:** `commands/status.md` Step 7 (Recommended Next Steps) references readiness failures as the first recommendation when config is incomplete.

### Skill Rename

**FC-021:** Directory `skills/workflow-router/` exists.

**FC-022:** Directory `skills/bug-workflow/` does NOT exist.

**FC-023:** File `skills/workflow-router/SKILL.md` contains frontmatter with `name: workflow-router`.

**FC-024:** File `skills/workflow-router/SKILL.md` `description` field mentions both bugs and features (broader scope than the original "analyze bugs, fix issues").

**FC-025:** The intent mapping table in `skills/workflow-router/SKILL.md` contains the same number of rows (or more) as the original `bug-workflow/SKILL.md`.

**FC-026:** `CLAUDE.md` does NOT contain the string `bug-workflow` (all references updated).

### State Schema — parent_run_id

**FC-027:** File `state/schema.md` Full Schema Example JSON contains the field `"parent_run_id": null`.

**FC-028:** File `state/schema.md` Top-Level Field Definitions table contains a row for `parent_run_id` with type `string or null`, Required = `No`, Default = `null`.

**FC-029:** `commands/scaffold.md` Step 7 (Feature Implementation Loop) or Step 0 (state init) references setting `parent_run_id` when creating subtask state.

### Documentation

**FC-030:** `CLAUDE.md` Architecture section references `workflow-router` (not `bug-workflow`).

**FC-031:** `docs/plans/roadmap.md` contains a DONE section for v5.3.0 describing the Guided Handoff changes.

**FC-032:** `docs/plans/roadmap.md` contains NEXT or PLANNED items for Phase 2 features (feature from description, local deployment).

**FC-033:** `docs/plans/roadmap.md` contains deferred items for: forge bridge, standalone deployment, scaffold --extend, batch feature implementation.

---

## Phase 2: Feature from Chat + Deploy Optional (v5.4.0)

### Feature from Description

**FC-034:** File `commands/implement-feature.md` Input line includes `--description "..."` in the flag list.

**FC-035:** `commands/implement-feature.md` flag parsing section handles `--description` (or `--desc`) and sets `description_mode = true`.

**FC-036:** `commands/implement-feature.md` flag parsing rejects `--description` combined with an Issue ID with an explicit error message.

**FC-037:** File `commands/implement-feature.md` contains a section headed `### 0c. Feature card creation` (or equivalent) that only runs when `description_mode = true`.

**FC-038:** `commands/implement-feature.md` Step 0c creates an issue via MCP with title extracted from the description.

**FC-039:** `commands/implement-feature.md` Step 0c displays "Created {ISSUE-ID}: {title}" after successful card creation.

**FC-040:** `commands/implement-feature.md` Step 0c contains a BLOCK handler for MCP card creation failure.

**FC-041:** `commands/implement-feature.md` Step 0c shows a card preview for user confirmation when `--yolo` is NOT set.

**FC-042:** `commands/implement-feature.md` Step 0c is positioned AFTER Step 0b (config validity gate) — config must be valid before card creation.

### Workflow Router — Feature Routing

**FC-043:** File `skills/workflow-router/SKILL.md` intent mapping table contains a row for describing a feature to implement (without issue ID) that maps to `ceos-agents:implement-feature` with `--description`.

**FC-044:** `skills/workflow-router/SKILL.md` intent mapping table contains rows for check-deploy (check, start, stop).

**FC-045:** `skills/workflow-router/SKILL.md` Process section contains intent disambiguation logic for implement-feature (issue ID vs. description).

**FC-046:** `skills/workflow-router/SKILL.md` marks feature-from-description as `Destructive? Yes` (requires confirmation).

### Local Deployment Config

**FC-047:** File `core/config-reader.md` contains parsing rules for `### Local Deployment` section with keys: Type, Start command, Stop command, Health check URL, Health check timeout, Ports.

**FC-048:** `core/config-reader.md` Local Deployment defaults: Health check timeout = 60, other keys = none (section is fully optional).

**FC-049:** `CLAUDE.md` Config Contract optional sections table contains a row for `Local Deployment` with keys `Type, Start command, Stop command, Health check URL, Health check timeout, Ports`.

**FC-050:** File `commands/onboard.md` Step 6 multi-select checklist contains an entry for Local Deployment.

**FC-051:** File `commands/check-setup.md` Block 1 Step 5 optional sections list includes Local Deployment with format validation.

### deployment-verifier Agent

**FC-052:** File `agents/deployment-verifier.md` exists.

**FC-053:** `agents/deployment-verifier.md` contains frontmatter with exactly these fields: `name: deployment-verifier`, `description` (non-empty), `model: sonnet`, `style` (non-empty).

**FC-054:** `agents/deployment-verifier.md` contains sections in order: Goal, Expertise, Process, Constraints.

**FC-055:** `agents/deployment-verifier.md` Process section contains numbered steps (at least 5 steps covering: read config, port scan, start app, health check, determine verdict).

**FC-056:** `agents/deployment-verifier.md` Process contains port conflict detection logic that runs BEFORE any start attempt.

**FC-057:** `agents/deployment-verifier.md` Constraints section contains at least 5 NEVER rules.

**FC-058:** `agents/deployment-verifier.md` defines verdicts: `HEALTHY`, `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED`, `SKIPPED`.

**FC-059:** `agents/deployment-verifier.md` Output section contains a structured markdown report template.

### check-deploy Command

**FC-060:** File `commands/check-deploy.md` exists.

**FC-061:** `commands/check-deploy.md` contains frontmatter with `description` and `allowed-tools` fields.

**FC-062:** `commands/check-deploy.md` `allowed-tools` includes `Bash, Read` (at minimum).

**FC-063:** `commands/check-deploy.md` handles flags: `--start`, `--stop`, and default (check only).

**FC-064:** `commands/check-deploy.md` contains Steps 1-5 covering: port check, action execution, health check, docker status, report.

**FC-065:** `commands/check-deploy.md` Step 1 (Port Check) contains cross-platform port detection commands (lsof, ss, netstat).

**FC-066:** `commands/check-deploy.md` displays "No Local Deployment section" message and STOPs when config section is absent.

**FC-067:** `commands/check-deploy.md` Rules section contains "NEVER modify source code".

**FC-068:** `commands/check-deploy.md` Step 2 blocks start if port conflicts detected (does not silently overwrite).

### State Schema — Deployment

**FC-069:** File `state/schema.md` Full Schema Example JSON contains a `"deployment"` object with fields: `status`, `verdict`, `ports`, `health_check`.

**FC-070:** File `state/schema.md` Top-Level Field Definitions table contains rows for `deployment.status`, `deployment.verdict`, `deployment.ports`, `deployment.health_check`.

### Documentation — Phase 2

**FC-071:** `CLAUDE.md` Architecture section lists `deployment-verifier` in the agents list.

**FC-072:** `CLAUDE.md` Architecture section lists `check-deploy` in the commands list.

**FC-073:** `CLAUDE.md` Model Selection table contains a row for `deployment-verifier` with model `sonnet`.

**FC-074:** `CLAUDE.md` states 19 agents (updated from 18) and 25 commands (updated from 24).

**FC-075:** `docs/plans/roadmap.md` contains a DONE section for v5.4.0.

---

## Cross-Phase Structural Criteria

**FC-076:** No file in the repository contains the string `bug-workflow` after Phase 1 is complete (full rename).

**FC-077:** `commands/scaffold.md` Step 4b does NOT contain the string `/onboard` (scaffold handles config inline, does not tell user to run onboard).

**FC-078:** `commands/scaffold.md` Step 4b does NOT invoke any other command via Skill tool (commands cannot invoke commands — the inline approach is required).

**FC-079:** All new agent files follow the exact frontmatter format: `name`, `description`, `model`, `style` (in that order, YAML).

**FC-080:** All new command files follow the exact frontmatter format: `description`, `allowed-tools` (in that order, YAML).

**FC-081:** No new required keys are added to the Automation Config contract (all changes are optional sections or optional flags — MINOR version bump).

**FC-082:** `agents/deployment-verifier.md` does NOT contain any code-modification instructions (read-only for source code, can manage processes).

**FC-083:** The `--description` flag in `commands/implement-feature.md` runs the config validity gate (Step 0b) BEFORE creating the tracker card (Step 0c) — early failure on invalid config.

---

## Verification Summary

| Phase | Criteria Count | ID Range |
|-------|---------------|----------|
| Phase 1 | 33 | FC-001 to FC-033 |
| Phase 2 | 42 | FC-034 to FC-075 |
| Cross-Phase | 8 | FC-076 to FC-083 |
| **Total** | **83** | FC-001 to FC-083 |
