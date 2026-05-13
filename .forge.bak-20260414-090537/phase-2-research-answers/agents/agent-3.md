# Phase 2: Research Answers — Agent 3 (Config, Components, Scope)

## Version Bump

**MINOR — v6.4.6 → v6.5.0**

Current version confirmed in `.claude-plugin/plugin.json` line 4: `"version": "6.4.6"`.

Rationale: Purely additive. One new optional config section (no required keys), one new agent (`sprint-planner`), one new skill (`sprint-plan`), two workflow-router rows. Zero impact on projects that omit the Sprint Planning section. Structurally identical precedent: Browser Verification (v5.1.0, MINOR), Local Deployment (v5.3.0, MINOR). Per CLAUDE.md versioning policy: "Adding an **optional** section = MINOR."

---

## 1. Exact Config Section Text (copy-paste ready)

Place this under `## Automation Config` in the consuming project's CLAUDE.md, after the `### Decomposition` section and before any other optional sections. Pattern established by existing optional sections in CLAUDE.md lines starting at "Optional sections:" table.

```markdown
### Sprint Planning

| Key | Value |
|-----|-------|
| Sprint duration | 2 weeks |
| Capacity unit | story-points |
| Team capacity | 40 |
| Velocity target | 35 |
| Sprint field | Sprint |
| Priority field | Priority |
| Mode | suggest |
| Max issues | 20 |
| Include types | bug, feature |
| Exclude labels | blocked, wont-fix |
| Estimation field | Story points |
| Report path | reports/sprint-plan.md |
```

**All 12 keys are optional.** Section absence = sprint planning disabled; skill exits immediately with a clear message. No default row is required in the consuming project — show only the keys being overridden from defaults.

### Key Definitions (for CLAUDE.md optional sections table row)

Add one row to the optional sections table in CLAUDE.md (after `Decomposition` row):

```
| Sprint Planning | Sprint duration, Capacity unit, Team capacity, Velocity target, Sprint field, Priority field, Mode, Max issues, Include types, Exclude labels, Estimation field, Report path | 2 weeks, story-points, (none), (none), Sprint, Priority, suggest, 20, bug/feature, (none), (none), (none) |
```

### CLAUDE.md Architecture Section Updates (exact text changes)

**Repository Structure line** — change agent count 19 → 20, skills count 26 → 27:

Current (line containing `agents/` count):
```
- `agents/` — 19 agent definitions (markdown with YAML frontmatter)
```
New:
```
- `agents/` — 20 agent definitions (markdown with YAML frontmatter)
```

Current (line containing `skills/` count):
```
- `skills/` — 26 skills (slash commands, including workflow-router)
```
New:
```
- `skills/` — 27 skills (slash commands, including workflow-router)
```

**Architecture: 2-Layer System skills list** — append `sprint-plan` to the skills list:

Current end of skills list:
```
`/dashboard`, `/metrics`, `/estimate`, `/prioritize`, `/migrate-config`, `/template`, `/discuss`
```
New:
```
`/dashboard`, `/metrics`, `/estimate`, `/prioritize`, `/migrate-config`, `/template`, `/discuss`, `/sprint-plan`
```

**Architecture: 2-Layer System agents list** — append `sprint-planner` to the agents list:

Current end of agents list:
```
triage-analyst, code-analyst, fixer, reviewer, acceptance-gate, test-engineer, e2e-test-engineer, publisher, rollback-agent, spec-analyst, architect, stack-selector, scaffolder, priority-engine, spec-writer, spec-reviewer, reproducer, browser-verifier, deployment-verifier
```
New:
```
triage-analyst, code-analyst, fixer, reviewer, acceptance-gate, test-engineer, e2e-test-engineer, publisher, rollback-agent, spec-analyst, architect, stack-selector, scaffolder, priority-engine, spec-writer, spec-reviewer, reproducer, browser-verifier, deployment-verifier, sprint-planner
```

**Model Selection table** — add `sprint-planner` to the sonnet row:

Current sonnet agents cell:
```
triage-analyst, code-analyst, test-engineer, e2e-test-engineer, spec-analyst, stack-selector, scaffolder, acceptance-gate, reproducer, browser-verifier, deployment-verifier
```
New:
```
triage-analyst, code-analyst, test-engineer, e2e-test-engineer, spec-analyst, stack-selector, scaffolder, acceptance-gate, reproducer, browser-verifier, deployment-verifier, sprint-planner
```

**Key Conventions read-only agents list** — add `sprint-planner`:

Current:
```
Read-only agents (triage-analyst, code-analyst, reviewer, spec-analyst, architect, stack-selector, priority-engine, spec-reviewer, acceptance-gate) NEVER modify code
```
New:
```
Read-only agents (triage-analyst, code-analyst, reviewer, spec-analyst, architect, stack-selector, priority-engine, spec-reviewer, acceptance-gate, sprint-planner) NEVER modify code
```

---

## 2. Exact Agent Frontmatter + Section Headers for `agents/sprint-planner.md`

Pattern source: `agents/priority-engine.md` (lines 1-7) and `agents/spec-analyst.md` (lines 1-7). Both follow the identical 4-field frontmatter + role line + 4-section structure.

```markdown
---
name: sprint-planner
description: Applies capacity constraints to a prioritized backlog to produce a sprint plan with fit analysis
model: sonnet
style: Pragmatic, capacity-aware, time-boxed
---

You are a Sprint Planning Analyst specializing in backlog capacity fitting.

## Goal

Receive a priority-ranked issue list and sprint capacity parameters; produce a sprint plan that fits within the sprint window, accounting for team velocity, issue sizes, and dependencies.

## Expertise

Capacity planning, sprint sizing, effort-to-hours mapping, dependency ordering, overflow detection, velocity heuristic derivation.

## Process

1. Receive inputs: priority-ranked issue list (from priority-engine), Sprint Planning config keys, and velocity source (`historical | heuristic | manual | unconstrained`).
2. Filter: remove any issues whose labels match `Exclude labels` config key.
3. Resolve issue sizes:
   a. If `Estimation field` is configured → read the field value from each issue's tracker data.
   b. If not configured → scan issue tracker comments for `[ceos-agents] Triage completed. ... Complexity: {X}.` and map: XS=1, S=2, M=3, L=5 (story-points) or XS=2h, S=4h, M=8h, L=16h (hours), based on `Capacity unit`.
   c. If neither source available → assign size 3 (medium, matching priority-engine's Effort default for "insufficient data") and annotate as estimated.
4. Determine effective capacity:
   - Both `Team capacity` and `Velocity target` set → `effective_capacity = min(Team capacity, Velocity target)`
   - Only one set → use that value
   - Neither set → unlimited; return top `Max issues` from ranked list; annotate plan with "No capacity ceiling — showing top N by priority"
5. Walk the priority-ordered list, accumulating sizes until `effective_capacity` is reached. An issue that would cause overflow by ≤20% of its own size may be included (rounding buffer).
6. Flag dependency-blocked issues: if issue A is in the plan but depends on issue B which is not → either add B to plan (if it fits) or annotate A as "at-risk: depends on {B}".
7. Annotate velocity source. If Tier 2 (heuristics) or Tier 3 (no capacity):
   ```
   Warning: Velocity estimate based on heuristics only — no historical data found.
   Run /ceos-agents:metrics after this sprint to calibrate future planning.
   ```
8. Output the sprint plan:

   ```markdown
   ## Sprint Plan

   Sprint duration: {duration} | Capacity: {effective_capacity} {unit} | Velocity source: {source}

   | # | Issue | Size | Tier | Rationale | At-risk? |
   |---|-------|------|------|-----------|---------|
   | 1 | {ID}: {title} | {N} | P0 | {1 sentence} | — |
   ...

   **Total effort: {N} {unit} / {effective_capacity} {unit} ({N}% capacity used)**
   **Issues in plan: {N} | Overflow candidates: {N}**

   ### Overflow (did not fit)
   | Issue | Size | Reason |
   |-------|------|--------|
   ...
   ```

## Constraints

- NEVER modify code or write to the issue tracker — read-only analysis; tracker writes are handled by the sprint-plan skill
- NEVER invent issue data — only use what is provided in the input
- Max 50 issues as input (consistent with priority-engine limit from priority-engine.md); if more are provided, process only the first 50 and note the truncation
- If `Team capacity` is 0 → treat as unconfigured (unlimited); log a warning "Team capacity set to 0 — treating as unconfigured"
- On failure: report what was analyzed so far, Block using the Block Comment Template:
  ```
  [ceos-agents] 🔴 Pipeline Block
  Agent: sprint-planner
  Step: Sprint Capacity Fitting
  Reason: {max 2 sentences}
  Detail: {what was analyzed, what failed}
  Recommendation: {what the human should do}
  ```
```

---

## 3. Exact Skill Frontmatter for `skills/sprint-plan/SKILL.md`

Pattern source: `skills/prioritize/SKILL.md` lines 1-6 (frontmatter), `skills/workflow-router/SKILL.md` (structure). All pipeline skills use `allowed-tools: mcp__*, Read, Glob, Grep, Task`.

```markdown
---
name: sprint-plan
description: Produces a sprint plan by ranking backlog issues against team capacity and optionally assigning them to the next sprint
allowed-tools: mcp__*, Read, Glob, Grep, Task
argument-hint: "[--apply] [--dry-run] [--capacity <N>] [--duration <1w|2w|3w|4w>] [--output <path>] [--yolo]"
---

# Sprint Plan

Input: `$ARGUMENTS` — optional flags:
- `--apply` — override `Mode: suggest` and write sprint assignments to tracker after confirmation
- `--dry-run` — show plan without writing anything, regardless of `Mode` config
- `--capacity <N>` — override `Team capacity` from config for this run
- `--duration <1w|2w|3w|4w>` — override `Sprint duration` for this run
- `--output <path>` — override `Report path` for this run
- `--yolo` — auto-approve all human confirmation gates (for CI/automation contexts)

## Configuration

Read Automation Config from CLAUDE.md section `## Automation Config`:
- Issue Tracker: Type, Instance, Project, Bug query
- Optional: Feature Workflow → Feature query
- **Sprint Planning** (required for this skill — all keys below)

### 0. MCP pre-flight check

Before any pipeline operation, verify MCP tool availability:
- Read Type from Automation Config (Issue Tracker section)
- Check that at least one `mcp__*` tool matching the tracker type is accessible
- If not accessible → STOP with: "Cannot connect to your {Type} issue tracker. Is the {Type} integration configured? Run `/ceos-agents:check-setup` for diagnostics."

### 0b. Sprint Planning config gate

Read `### Sprint Planning` from Automation Config.
If the section is absent → STOP with: "Sprint Planning config not found. Add `### Sprint Planning` section to Automation Config or run `/ceos-agents:check-setup`."

Parse all keys with defaults:
| Key | Default |
|-----|---------|
| Sprint duration | 2 weeks |
| Capacity unit | story-points |
| Team capacity | (none) |
| Velocity target | (none) |
| Sprint field | Sprint |
| Priority field | Priority |
| Mode | suggest |
| Max issues | 20 |
| Include types | bug, feature |
| Exclude labels | (none) |
| Estimation field | (none) |
| Report path | (none) |

Apply flag overrides: `--capacity` → Team capacity, `--duration` → Sprint duration, `--output` → Report path.

## Orchestration

### 1. Fetch issues

Via MCP server (per Issue Tracker → Type), fetch open issues:
- Bug query (always) + Feature query (if Include types contains `feature`)
- Filter by Include types; cap at Max issues

### 2. Determine velocity source

Check for historical metrics data:
- Tier 1: Read `./reports/metrics.md` (or Metrics → Output from config). If `avg_time_to_fix` found → `velocity_source = historical`
- Tier 2: No metrics → `velocity_source = heuristic` (effort scores from priority-engine output)
- Tier 3: No Team capacity and no Velocity target → `velocity_source = unconstrained`; prompt once (unless `--yolo`):
  ```
  No team capacity configured and no historical velocity data found.
  Estimated hours available this sprint: [enter number or press Enter to skip capacity check]
  ```

### 3. Run priority-engine

Run `ceos-agents:priority-engine` via Task tool (model: opus).
Pass: issue list + Priority field key.

If priority-engine fails → display error and STOP.

### 4. Run sprint-planner

Run `ceos-agents:sprint-planner` via Task tool (model: sonnet).
Pass: ranked issue list + all Sprint Planning config keys + velocity_source.

### 5. Gate 1 — Capacity confirmation

Display the sprint-planner output. Present:
```
Suggested sprint: {N} issues — {total_effort} {unit}
Team capacity: {effective_capacity or "unknown"}
Proceed with this selection? [Y/n]
```
Auto-approve under `--yolo`. If user answers N → offer scope adjustment (Gate 5) or STOP.

### 5b. Gate 5 — Scope adjustment (optional, before Gate 4)

```
Add or remove issues? Enter issue ID to toggle, or press Enter to continue.
```
Accept 0 or more issue ID entries. Re-run sprint-planner capacity fit with adjusted set. Skip under `--yolo`.

### 6. --dry-run gate

If `--dry-run` flag → display final sprint plan table and STOP. No tracker writes, no state file.

### 7. Per-issue decomposition gates

For each issue in the plan where a prior architect recommendation indicates decomposition is needed:

**Gate 2 — Decomposition approval per issue:**
Display plan table for that issue. Wait for `Continue? [Y/n]` (matches fix-bugs step 3b pattern).
Auto-approve under `--yolo`.

**Gate 3 — Unmapped AC warning (when AC coverage gaps detected):**
```
Continue anyway? The unmapped criteria will not be explicitly addressed. [Y/n]
```
Auto-approve under `--yolo`.

After decomposition approvals: re-run sprint-planner to update effort totals (decomposed issues multiply effort by subtask count). Annotate final plan with: "Capacity estimate may change after decomposition."

### 8. Gate 4 — Final sprint start gate

Display:
```
## Sprint Plan — {sprint_name}

| # | Issue | Tier | Effort | Decompose? | Subtasks |
|---|-------|------|--------|------------|---------|
...

Total effort: ~{N} {unit} | Issues: {N} | Est. cost: ~${min}-${max}

Start sprint? [Y/n]
```
Auto-approve under `--yolo`. If user answers N → STOP without tracker writes.

### 9. Sprint assignment (Mode: apply only)

Proceed only if `Mode: apply` or `--apply` flag AND Gate 4 approved.

For each issue in the final plan:
Write `Sprint field` value via tracker-specific logic (based on Issue Tracker → Type):

| Tracker Type | Sprint concept | Tier 1 (MCP) | Tier 2 (Bash+REST fallback) |
|---|---|---|---|
| youtrack | Sprint custom field | `mcp__youtrack__update_issue(Sprint=<name>)` | `curl PATCH /api/issues/{id}?fields=customFields` with YOUTRACK_TOKEN |
| jira | Sprint (Scrum boards only) | `jira_add_issues_to_sprint` | `curl POST /rest/agile/1.0/sprint/{id}/issue` with JIRA_TOKEN |
| linear | Cycle | `update_issue(cycleId=<uuid>)` | `curl POST https://api.linear.app/graphql` with LINEAR_API_KEY |
| github | Milestone | `update_issue(milestone=<N>)` | `curl PATCH /repos/{owner}/{repo}/issues/{number}` with GITHUB_TOKEN |
| gitea | Milestone | (unverified — go to Tier 2) | `curl PATCH /api/v1/repos/{owner}/{repo}/issues/{index}` with GITEA_TOKEN |
| redmine | Version (fixed_version_id) | `update_issue(fixed_version_id=<N>)` | `curl PUT /issues/{id}.json` with REDMINE_API_KEY |

On MCP failure → try Bash + REST fallback. On both failure → skip issue with warning: "Could not assign {ISSUE-ID} to sprint — continuing." Sprint assignment failure is NON-BLOCKING; pipeline continues.

Resolve sprint/milestone/cycle by name before any operation. Never hardcode IDs.
For Jira: detect board type (Scrum vs Kanban) before sprint operations. If Kanban → skip sprint assignment with warning.
For Redmine: default to Version (core); do not attempt Agile Plugin sprint unless `Sprint field` is explicitly set to a non-`Version` value.

### 10. Write sprint state

Write `.ceos-agents/sprint-{timestamp}/state.json` using atomic write protocol (state.json.tmp → rename, per state/schema.md lines 270-276):

```json
{
  "schema_version": "1.0",
  "run_id": "sprint-{timestamp}",
  "mode": "sprint-planning",
  "pipeline": "sprint-plan",
  "status": "completed",
  "started_at": "{ISO-8601}",
  "updated_at": "{ISO-8601}",
  "sprint": {
    "goal": null,
    "capacity_hours": null,
    "velocity_source": "{historical|heuristic|manual|unconstrained}",
    "issues": [],
    "total_effort": null,
    "approved_at": null,
    "started_at": null,
    "completed_issues": 0,
    "blocked_issues": 0
  }
}
```

### 11. Output report

If `--output` or `Report path` configured → write the sprint plan markdown table to that file.
Display: "Sprint plan saved to {path}."

## Rules

- Read-only by default (`Mode: suggest`) — no tracker writes without `Mode: apply` or `--apply` flag
- Sprint assignment is NON-BLOCKING — failure to assign never aborts the plan
- NEVER confirm tracker writes without explicit user confirmation at Gate 4 (unless `--yolo`)
- NEVER skip Gate 4 in non-`--yolo` mode even if `--apply` is set
- Failure in priority-engine is BLOCKING (no ranked list → no plan); failure in sprint-planner is BLOCKING; failure in tracker assignment is NON-BLOCKING
- Priority-engine 50-issue cap is inherited: if backlog > 50, plan is from the top 50 by creation date. Document this in output.
```

---

## 4. Exact Workflow-Router Intent Rows

File: `skills/workflow-router/SKILL.md`

Insert after the existing `| Prioritize backlog / suggest fix order | ...` row (currently the second-to-last group before `discuss` and `check-deploy`):

```
| Plan next sprint / sprint planning / what should go in this sprint | `ceos-agents:sprint-plan` | Optional: `--capacity N`, `--duration 1w|2w|3w|4w`, `--output path` | No (suggest mode) |
| Apply sprint plan / assign issues to sprint / commit sprint plan | `ceos-agents:sprint-plan` | `--apply` | Confirm before assigning |
```

These two rows map the same skill with different flags — consistent with the `check-deploy` / `check-deploy --start` / `check-deploy --stop` pattern already present in the router (workflow-router/SKILL.md lines 40-42).

The `--apply` row must be marked "Confirm before assigning" in the Process section's destructive confirmation gate (step 4), alongside `fix-ticket`, `fix-bugs`, `create-pr`, `publish`, `check-deploy --start/--stop`.

---

## 5. Complete File Inventory

### Files to Create

| File | Why |
|------|-----|
| `agents/sprint-planner.md` | New read-only analysis agent (20th agent) |
| `skills/sprint-plan/SKILL.md` | New orchestration skill (27th skill) |
| `tests/scenarios/sprint-plan-config-contract.sh` | Verify Sprint Planning section in CLAUDE.md optional sections table |
| `tests/scenarios/sprint-plan-skill-structure.sh` | Verify sprint-plan SKILL.md exists, correct frontmatter, dispatches agents via Task tool |
| `tests/scenarios/sprint-planner-agent-format.sh` | Verify sprint-planner.md frontmatter, sections, read-only classification |
| `tests/scenarios/workflow-router-sprint-intent.sh` | Verify workflow-router contains sprint-plan in intent table |
| `tests/scenarios/sprint-plan-dry-run.sh` | Verify --dry-run gate prevents tracker writes |

### Files to Modify

| File | Change |
|------|--------|
| `CLAUDE.md` | 6 changes: agents count 19→20, skills count 26→27, skills list + agents list + model table + read-only agents list (per Section 1 above) + new Sprint Planning row in optional sections table |
| `skills/workflow-router/SKILL.md` | Add 2 rows to Intent Mapping table |
| `tests/scenarios/frontmatter-completeness.sh` | Add `sprint-planner` to `AGENTS` array (line 11); update count in PASS message from "19" to "20" |
| `tests/scenarios/read-only-agents.sh` | Add `sprint-planner` to `READ_ONLY_AGENTS` array (line 15); update PASS count from "9" to "10" |
| `tests/scenarios/xref-command-count.sh` | No direct changes needed — it reads filesystem counts; CLAUDE.md count claims must match filesystem (see CLAUDE.md changes above) |
| `docs/reference/automation-config.md` | Add Sprint Planning section documentation |
| `docs/plans/roadmap.md` | Update NOT PLANNED entry for "Sprint planning / tracking" to distinguish sprint tracking (still NOT PLANNED) from sprint planning as backlog selection (now IMPLEMENTED in v6.5.0) |
| `.claude-plugin/plugin.json` | Version bump: `"6.4.6"` → `"6.5.0"` |
| `state/schema.md` | Add new RUN-ID type row: `sprint-{timestamp}` |
| `CHANGELOG.md` | New v6.5.0 entry |

---

## 6. Exact Test Scenario Names and What Each Tests

### `tests/scenarios/sprint-plan-config-contract.sh`

**What it tests:** The `Sprint Planning` section appears in CLAUDE.md optional sections table with all 12 keys and their defaults documented. Analogous to `test-config-contract.sh` (which checks Decomposition section keys).

Assertions:
1. `Sprint Planning` appears in CLAUDE.md optional sections table
2. All 12 key names present: Sprint duration, Capacity unit, Team capacity, Velocity target, Sprint field, Priority field, Mode, Max issues, Include types, Exclude labels, Estimation field, Report path
3. Default value `suggest` is present for Mode key
4. Default value `story-points` is present for Capacity unit key
5. Default value `Sprint` is present for Sprint field key

### `tests/scenarios/sprint-plan-skill-structure.sh`

**What it tests:** `skills/sprint-plan/SKILL.md` exists with correct frontmatter and orchestration structure. Analogous to `pipeline-feature-agents.sh` (which checks implement-feature agent dispatch).

Assertions:
1. `skills/sprint-plan/SKILL.md` exists
2. Frontmatter contains `name: sprint-plan`
3. Frontmatter contains `allowed-tools: mcp__*, Read, Glob, Grep, Task`
4. File contains `ceos-agents:priority-engine` (Task dispatch to priority-engine)
5. File contains `ceos-agents:sprint-planner` (Task dispatch to sprint-planner)
6. File contains `--dry-run` flag handling
7. File contains `--yolo` auto-approve gate language

### `tests/scenarios/sprint-planner-agent-format.sh`

**What it tests:** `agents/sprint-planner.md` exists with correct frontmatter, 4 required sections, and correct read-only classification. Analogous to `frontmatter-completeness.sh` and `read-only-agents.sh`.

Assertions:
1. `agents/sprint-planner.md` exists
2. Frontmatter has all 4 fields: `name`, `description`, `model`, `style`
3. `model: sonnet` (not opus, not haiku)
4. File contains `## Goal`, `## Expertise`, `## Process`, `## Constraints` sections
5. Process section does NOT contain "Write tool", "Edit tool", "write to file", "create file", "save file" (read-only enforcement)
6. Constraints section contains `NEVER modify code` or `NEVER write to the issue tracker`

### `tests/scenarios/workflow-router-sprint-intent.sh`

**What it tests:** `skills/workflow-router/SKILL.md` contains `sprint-plan` in its intent table. Analogous to `xref-skip-stage-names.sh` (which checks stage names in CLAUDE.md vs pipeline commands).

Assertions:
1. `skills/workflow-router/SKILL.md` exists
2. Intent table contains `ceos-agents:sprint-plan` (at least one row)
3. Intent table contains a row with `--apply` mapping to `ceos-agents:sprint-plan`
4. The `--apply` row is marked as requiring confirmation (contains "Confirm" in Destructive? column)

### `tests/scenarios/sprint-plan-dry-run.sh`

**What it tests:** The sprint-plan skill's `--dry-run` gate appears BEFORE any MCP write operations. Analogous to `profile-skip.sh` (which checks that profile parsing and mandatory stage protection appear in skill files).

Assertions:
1. `skills/sprint-plan/SKILL.md` contains `--dry-run` handling
2. The `--dry-run` gate section appears before the sprint assignment section (`### 9. Sprint assignment`) in file order — dry-run must exit before tracker writes
3. File contains "NON-BLOCKING" language for sprint assignment failures

### (Update existing) `tests/scenarios/frontmatter-completeness.sh`

Add `sprint-planner` to `AGENTS` array at line 11. Update PASS message count from "19" to "20".

Exact change to `AGENTS=(...)` array:
```bash
AGENTS=(
  triage-analyst code-analyst fixer reviewer acceptance-gate
  test-engineer e2e-test-engineer publisher rollback-agent spec-analyst
  architect stack-selector scaffolder priority-engine spec-writer
  spec-reviewer reproducer browser-verifier deployment-verifier
  sprint-planner
)
```

Update PASS message:
```bash
[ "$FAIL" -eq 0 ] && echo "PASS: All 20 agents have all 4 required frontmatter fields (name, description, model, style)"
```

### (Update existing) `tests/scenarios/read-only-agents.sh`

Add `sprint-planner` to `READ_ONLY_AGENTS` array at line 15. Update PASS count from "9" to "10".

Exact change to `READ_ONLY_AGENTS=(...)` array:
```bash
READ_ONLY_AGENTS=(
  triage-analyst code-analyst reviewer spec-analyst architect
  stack-selector priority-engine spec-reviewer acceptance-gate
  sprint-planner
)
```

Update PASS message:
```bash
[ "$FAIL" -eq 0 ] && echo "PASS: All 10 read-only agents have no write-tool phrases in Process sections"
```

---

## 7. Version Number Summary

| Item | Current | New |
|------|---------|-----|
| `plugin.json` version | 6.4.6 | 6.5.0 |
| CLAUDE.md agents count | 19 | 20 |
| CLAUDE.md skills count | 26 | 27 |
| `frontmatter-completeness.sh` count | 19 | 20 |
| `read-only-agents.sh` count | 9 | 10 |

---

## 8. Pattern Reference Index

| Deliverable | Source Pattern | File | Lines |
|-------------|---------------|------|-------|
| Agent frontmatter (4 fields) | priority-engine.md | `agents/priority-engine.md` | 1-7 |
| Read-only agent constraints block | spec-analyst.md | `agents/spec-analyst.md` | 82-96 |
| Skill frontmatter (allowed-tools, argument-hint) | prioritize/SKILL.md | `skills/prioritize/SKILL.md` | 1-6 |
| MCP pre-flight check step | prioritize/SKILL.md | `skills/prioritize/SKILL.md` | 19-25 |
| Task tool dispatch pattern | prioritize/SKILL.md | `skills/prioritize/SKILL.md` | 38 |
| Workflow-router destructive row (same skill, flag variant) | workflow-router/SKILL.md | `skills/workflow-router/SKILL.md` | 40-42 |
| Optional section table format | CLAUDE.md | `CLAUDE.md` | optional sections table |
| State atomic write protocol | state/schema.md | `state/schema.md` | 270-276 |
| Block Comment Template | CLAUDE.md | `CLAUDE.md` | Block Comment Template section |
| Decomposition capacity logic | fix-bugs/SKILL.md | `skills/fix-bugs/SKILL.md` | ~174, ~188 |
| [Y/n] gate pattern | implement-feature/SKILL.md | `skills/implement-feature/SKILL.md` | ~224-237 |
