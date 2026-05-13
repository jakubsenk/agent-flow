# Spec Alignment Review

## Findings

### 1. Agent Definition Format — `agents/deployment-verifier.md`

- [PASS] Convention: Frontmatter has all 4 required fields (name, description, model, style) in correct order.
- [PASS] Convention: Section order is Goal -> Expertise -> Process -> Constraints (matches CLAUDE.md spec exactly).
- [PASS] Convention: Process steps are numbered (1-10) and actionable.
- [PASS] Convention: Constraints start with NEVER rules and define hard limits.
- [PASS] Convention: Model is `sonnet`, consistent with Model Selection table for analysis/verification agents.
- [PASS] Convention: Description is concise and descriptive ("Verifies local deployment health -- checks ports, starts app, polls health endpoint, inspects Docker containers").

### 2. Two-Layer Architecture — `commands/check-deploy.md`

- [PASS] Convention: Command dispatches deployment-verifier agent via Task tool (Step 2 and Step 3), preserving the 2-layer command/agent separation.
- [PASS] Convention: Command frontmatter has `description` and `allowed-tools` (includes Task for agent dispatch).
- [PASS] Convention: Command has Input, Configuration, Steps, and Rules sections following established command format.
- [PASS] Convention: Agent Overrides check is present in Step 3 ("If `{Agent Overrides path}/deployment-verifier.md` exists, append its contents...").
- [PASS] Convention: State initialization follows the pattern from other commands (run_id, state.json, atomic write protocol).

### 3. Config Contract — New `Local Deployment` Section

- [PASS] Convention: Listed as optional section in CLAUDE.md Config Contract table with `| Local Deployment | Type, Start command, Stop command, Health check URL, Health check timeout, Ports | (none) |` format.
- [PASS] Convention: Uses table format (`| Key | Value |`) as required by CLAUDE.md ("All sections use table format").
- [PASS] Convention: Keys are consistent with the agent's Process step 1 and the command's Configuration section.

### 4. Version Numbers

- [PASS] Convention: Adding a new optional config section (Local Deployment) + new command + new agent = MINOR version bump. This is correct per Versioning Policy ("New backward-compatible feature -- new optional key, new command/agent" = MINOR).

### 5. Step Numbers in Modified Commands

#### `commands/scaffold.md` — Steps 4b/4c

- [PASS] Convention: Step 4b ("Tracker Configuration") and Step 4c ("MCP Guidance") follow the existing sub-step naming pattern (e.g., Steps 7a, 7b, 7c, 7d in the same file use the same lettered sub-step convention).
- [PASS] Convention: Step numbering from 0 through 10 remains sequential and coherent.
- [PASS] Convention: Both steps have clear skip conditions (Full YOLO skips 4b; skip 4c if tracker not configured).

#### `commands/implement-feature.md` — Step 0c

- [PASS] Convention: Step 0c ("Feature from Description") follows the existing sub-step pattern already established at 0b ("Config Validity Gate") in the same file.
- [PASS] Convention: Step uses Block Comment Template format for error output, consistent with other steps.
- [PASS] Convention: Mutually exclusive flag validation (--description vs Issue ID) is consistent with similar patterns (e.g., scaffold.md Flag Validation).

### 6. Skill Rename — `workflow-router`

- [PASS] Convention: No references to "bug-workflow" found in any active files (agents/, commands/, skills/, CLAUDE.md). The rename to `workflow-router` is complete in all operational files.
- [PASS] Convention: CLAUDE.md Repository Structure section references the skill as `workflow-router` (line 19: "`skills/` -- 1 routing skill (`workflow-router`)").
- [NOTE] Historical references to "bug-workflow" exist in docs/plans/ and CHANGELOG.md, which is expected and correct (historical documentation should not be rewritten).

### 7. Skill Intent Table — `skills/workflow-router/SKILL.md`

- [PASS] Convention: Three new entries (check-deploy, check-deploy --start, check-deploy --stop) follow the existing table format with columns: User Intent, Command, Arguments, Destructive?.
- [PASS] Convention: Destructive classification is correct -- `check-deploy` without flags is "No", `--start` and `--stop` are "Confirm before starting/stopping".
- [PASS] Convention: Process step 3 (non-destructive commands) correctly includes "check-deploy without flags" in the parenthetical list.

### 8. State Schema — `state/schema.md`

- [PASS] Convention: Deployment object is documented with a dedicated sub-section ("Deployment Object Fields") following the same table format as other field definitions.
- [PASS] Convention: The `deployment` field is typed as `object or null` with default `null`, consistent with how optional phase objects work.
- [PASS] Convention: Full Schema Example includes the deployment object, keeping the example comprehensive.
- [ISSUE] Convention: **Deployment status values diverge from Step Status Enum.** The deployment.status uses `pending`, `running`, `verified`, `failed` while all other phase status fields use the standard Step Status Enum: `pending`, `in_progress`, `completed`, `failed`, `skipped`, `blocked`, `not_applicable`. Specifically, `verified` is not in the enum (should be `completed`), and `running` should be `in_progress`. This is a minor inconsistency. **Severity: LOW** — the schema documents it explicitly so consumers can handle it, but it breaks the convention of uniform status values.

### 9. RUN-ID Format

- [ISSUE] Convention: **check-deploy uses `deploy-{timestamp}` format for run_id** (in check-deploy.md Step 0: `deploy-YYYYMMDD-HHmmss`), but the RUN-ID Determination table in state/schema.md only lists three formats: `ISSUE-ID`, `scaffold-{timestamp}`, and `build-{timestamp}`. The `deploy-{timestamp}` format is not documented in the table. **Severity: LOW** — functional but the schema table should enumerate all known RUN-ID patterns.

### 10. CLAUDE.md Consistency

- [PASS] Convention: Agent count updated to 19 (line 17: "19 agent definitions").
- [PASS] Convention: Command count updated to 25 (line 18: "25 commands").
- [PASS] Convention: Commands list includes `/check-deploy` (line 32).
- [PASS] Convention: Agents list includes `deployment-verifier` (line 33).
- [PASS] Convention: Model Selection table includes `deployment-verifier` under sonnet with "deployment" added to the Used For column.
- [PASS] Convention: Key Conventions lists deployment-verifier as an execution agent (line 110).
- [ISSUE] Convention: **deployment-verifier classified as "execution agent" is debatable.** The agent's own Constraints say "NEVER alter project files or app configuration -- deployment verification is strictly read-only." It writes artifacts to `.ceos-agents/deploy/` and manages Docker lifecycle (start/stop), so it does have side effects. However, it does NOT modify source code. Compared to reproducer and browser-verifier (also classified as execution agents that write artifacts but don't modify source), the classification is **consistent**. **Severity: NONE** — the existing convention classifies artifact-writing agents as "execution" even when they don't modify source code.

### 11. Pipeline Profiles Stage Skipping

- [PASS] Convention: CLAUDE.md does not list `deployment-verifier` in the Pipeline Profiles skippable stages, which is correct since check-deploy is a standalone command, not a stage within fix-ticket/fix-bugs/implement-feature pipelines.

### 12. Block Comment Template Usage

- [PASS] Convention: check-deploy.md does not use the Block Comment Template directly (it delegates to the agent). The agent itself does not use it either -- it produces a Deployment Verification Report with a structured verdict, which is appropriate for a standalone diagnostic command (not part of the issue-tracking pipeline).

## Summary of Issues

| # | File | Severity | Description |
|---|------|----------|-------------|
| 1 | `state/schema.md` | LOW | deployment.status values (`verified`, `running`) diverge from the Step Status Enum (`completed`, `in_progress`) used by all other phases |
| 2 | `state/schema.md` | LOW | RUN-ID Determination table does not include the `deploy-{timestamp}` format used by check-deploy |

## Score: 0.95 / 1.0

Two low-severity schema documentation inconsistencies. All structural conventions (agent format, command format, 2-layer architecture, config contract, versioning policy, skill routing, CLAUDE.md updates) are correctly followed. The deployment-verifier agent and check-deploy command are well-integrated into the existing plugin architecture.
