# Requirements: Sprint Planning & Backlog Management

> **Version:** v6.5.0 (MINOR)
> **EARS Pattern Legend:** Ubiquitous (shall), Event-driven (When...shall), State-driven (While...shall), Optional (Where...shall), Unwanted behavior (If...then...shall)

---

## 1. backlog-creator Agent

### REQ-SPB-001 (Ubiquitous)
The backlog-creator agent shall be a read-only sonnet agent that produces structured issue cards from specification or architect decomposition input and shall never create, modify, or delete files or tracker issues.

### REQ-SPB-002 (Ubiquitous)
The backlog-creator agent shall operate in two modes: (a) **Spec mode** accepting specification input in three formats: a single markdown file, a `spec/` folder in scaffold v2 format (containing `spec/epics/*.md`), or multiple markdown file paths; (b) **Task mode** accepting architect decomposition output containing `### Story` or `### Task` sections with `maps_to` fields, producing sub-task cards that preserve traceability.

### REQ-SPB-002a (Event-driven)
When the backlog-creator agent receives architect decomposition output (task mode), it shall extract each story/task section as a sub-issue card, preserving the `maps_to` traceability field, and shall produce sub-task-level cards (not epic-level).

### REQ-SPB-002b (Ubiquitous)
The scaffold skill Step 4e shall dispatch the backlog-creator agent in task mode with architect decomposition output as input. The scaffold skill shall handle tracker-specific operations (issue creation, back-reference comments, parent-child relationships) using the backlog-creator's structured card output.

### REQ-SPB-003 (Event-driven)
When the backlog-creator agent receives a `spec/` folder, it shall iterate `spec/epics/*.md` files sorted by filename prefix and extract one epic per file.

### REQ-SPB-004 (Event-driven)
When the backlog-creator agent receives a single markdown file or multiple files, it shall parse each file for top-level feature sections (H1 or H2 headings) and extract one epic per section.

### REQ-SPB-005 (Ubiquitous)
For each extracted epic, the backlog-creator agent shall produce a structured record containing: title, scope (2-3 sentences), acceptance criteria (2-5 testable items), size estimate (XS/S/M/L mapped to story points: XS=1, S=2, M=3, L=5), dependencies (list of other epic titles or "none"), and a verification section (unit, integration, e2e test hints).

### REQ-SPB-006 (Ubiquitous)
The backlog-creator agent shall produce at most 10 epics from a single specification input. If the specification contains more than 10 identifiable features, the agent shall select the first 10 and annotate the output with: "Specification contains {N} features. Showing first 10. Split the specification or run again on remaining files."

### REQ-SPB-007 (Ubiquitous)
The backlog-creator agent shall render each epic using the Epic Card Template (see design.md section 7) and shall not deviate from the template structure.

### REQ-SPB-008 (Ubiquitous)
The backlog-creator agent shall output a summary table before the individual epic cards:

```
## Backlog Summary

| # | Epic | AC | Size | SP | Dependencies |
|---|------|----|------|----|--------------|
| 1 | {title} | {count} | {XS/S/M/L} | {points} | {deps or "none"} |
```

### REQ-SPB-009 (Unwanted)
If the specification input is empty, unreadable, or contains no identifiable features, the backlog-creator agent shall Block using the Block Comment Template with agent `backlog-creator`, step `Spec Parsing`, and a recommendation to verify the specification format.

---

## 2. sprint-planner Agent

### REQ-SPB-010 (Ubiquitous)
The sprint-planner agent shall be a read-only sonnet agent that receives priority-engine output and Sprint Planning config, produces a capacity-constrained sprint plan, and shall never create, modify, or delete files or tracker issues.

### REQ-SPB-011 (Ubiquitous)
The sprint-planner agent shall be stateless: it shall receive all inputs as context (priority-engine output, Sprint Planning config values, velocity source data) and shall produce a single structured output. It shall not read or write state.json.

### REQ-SPB-012 (Ubiquitous)
The sprint-planner agent shall never re-rank issues. The priority-engine's sort order (P0 > P1 > P2, then by score descending within tier) shall be authoritative and preserved exactly in the sprint plan output.

### REQ-SPB-013 (Ubiquitous)
The sprint-planner agent shall walk the priority-engine ranked list top-to-bottom and include each issue if `accumulated_cost + issue_cost <= effective_capacity + (issue_cost * 0.2)`. The 20% overflow buffer applies per-issue, not globally.

### REQ-SPB-014 (Ubiquitous)
The sprint-planner agent shall resolve effort size for each issue using this precedence: (1) triage complexity from `[ceos-agents] Triage completed` comment if present, mapped via COMPLEXITY_TO_POINTS/HOURS; (2) priority-engine Effort score, mapped via EFFORT_TO_POINTS/HOURS; (3) default effort of 3 (M/3 SP).

### REQ-SPB-015 (Event-driven)
When an issue depends on another issue not yet included in the sprint plan, the sprint-planner agent shall attempt to add the dependency issue to the plan (if capacity permits). If the dependency does not fit, the agent shall annotate the dependent issue as "at-risk: depends on {dependency-ID} (not in sprint)".

### REQ-SPB-016 (Event-driven)
When an issue has effort_score >= 4 OR Risk = 5 in priority-engine output, the sprint-planner agent shall flag it with `decompose_recommended: true` in the output table.

### REQ-SPB-017 (Ubiquitous)
The sprint-planner agent shall produce output in this exact format:

```markdown
## Sprint Plan: {sprint_name}

**Duration:** {duration}
**Capacity:** {effective_capacity} {unit} (source: {velocity_source})
**Tracker tier:** {MCP|Bash|Skip} ({tracker_type})

### Selected Issues ({N} issues, {total_points} {unit})
| # | Issue | Tier | Effort | Cumulative | Flags |
|---|-------|------|--------|------------|-------|
| 1 | {ID}: {title} | P0 | {N} {unit} | {N} {unit} | {flags} |

### Overflow ({M} issues, {overflow_points} {unit})
| # | Issue | Tier | Effort | Reason |
|---|-------|------|--------|--------|
| 1 | {ID}: {title} | P1 | {N} {unit} | capacity exceeded |

### Dependency Warnings
- {issue_A} depends on {issue_B} (not in sprint)

### Cold Start Warnings
{if velocity_source != "historical"}
This plan uses {velocity_source} velocity data. Actual capacity may differ.
{/if}
```

### REQ-SPB-018 (State-driven)
While effective_capacity is null (neither Team capacity nor Velocity target configured, and no metrics file exists), the sprint-planner agent shall operate in unconstrained mode: include all issues up to Max issues limit, sorted by priority-engine rank, with no capacity math applied. The output shall display "Capacity: unconstrained (top {N})" instead of a numeric value.

### REQ-SPB-019 (Optional)
Where `--all` flag is active, the sprint-planner agent shall produce a multi-sprint release plan by filling sprints sequentially until all issues are allocated, with each sprint respecting effective_capacity. Output shall include a release summary table:

```markdown
### Release Summary
| Sprint | Issues | {unit} | Notable |
|--------|--------|--------|---------|
| Sprint 2026-W16 | 3 | 35 SP | includes P0 blocker |
| Sprint 2026-W18 | 2 | 20 SP | — |
```

### REQ-SPB-020 (Unwanted)
If the sprint-planner agent receives an empty issue list (0 issues from priority-engine), it shall output: "No open issues found. Backlog is empty -- nothing to plan." and exit without producing a sprint plan table.

---

## 3. /create-backlog Skill

### REQ-SPB-021 (Ubiquitous)
The /create-backlog skill shall parse `$ARGUMENTS` for: spec path (positional, required), `--decompose` flag, `--update` flag, `--yolo` flag, and `--dry-run` flag.

### REQ-SPB-022 (Ubiquitous)
The /create-backlog skill shall follow `core/config-reader.md` to parse Automation Config. Required sections: Issue Tracker (Type, Instance, Project). Optional sections: Sprint Planning (Epic template), Agent Overrides, Decomposition.

### REQ-SPB-023 (Ubiquitous)
The /create-backlog skill shall follow `core/mcp-preflight.md` to verify tracker MCP availability before any tracker operations. On MCP failure, the skill shall Block with the standard MCP pre-flight error message.

### REQ-SPB-024 (Ubiquitous)
The /create-backlog skill shall dispatch the backlog-creator agent via Task tool (model: sonnet) with the specification content as context.

### REQ-SPB-025 (Event-driven)
When the backlog-creator agent returns epic records, the /create-backlog skill shall display the Backlog Summary table (from REQ-SPB-008) and prompt: "Create {N} epics in {tracker_type} tracker? [Y/n]". In `--yolo` mode, the skill shall auto-approve.

### REQ-SPB-026 (Ubiquitous)
The /create-backlog skill shall create tracker issues using the per-tracker dispatch table defined in design.md section 5, following the same tracker-specific parameter conventions as implement-feature Step 5a.

### REQ-SPB-027 (Ubiquitous)
The /create-backlog skill shall apply partial failure handling using the accumulator pattern: on individual epic creation failure, log WARN and continue to next epic. After iteration, display: "Created {N}/{M} epic issues."

### REQ-SPB-028 (Optional)
Where `--decompose` flag is present, after creating all epic issues, the /create-backlog skill shall dispatch the architect agent (Task tool, model: opus) for each created epic with the epic's specification as context, then create sub-issues from the architect's task tree using the implement-feature Step 5a tracker dispatch table.

### REQ-SPB-029 (Optional)
Where `--update` flag is present, the /create-backlog skill shall execute the update matching algorithm (see design.md section 12) to identify existing tracker issues that correspond to epics in the specification, then update their descriptions instead of creating new issues.

### REQ-SPB-030 (Optional)
Where `--dry-run` flag is present, the /create-backlog skill shall display the Backlog Summary table and individual epic card previews, then exit without creating any tracker issues or persisting state.

### REQ-SPB-031 (Ubiquitous)
The /create-backlog skill shall initialize state at `.ceos-agents/backlog-{YYYYMMDD-HHmmss}/state.json` with `mode: "backlog-creation"`, `pipeline: "create-backlog"`, and follow the atomic write protocol from `core/state-manager.md`.

### REQ-SPB-032 (Ubiquitous)
The /create-backlog skill shall have YAML frontmatter: `name: create-backlog`, `description: Creates backlog epics in issue tracker from a specification document`, `allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task`, `disable-model-invocation: true`, `argument-hint: "<spec-path> [--decompose] [--update] [--dry-run] [--yolo]"`.

---

## 4. /sprint-plan Skill

### REQ-SPB-033 (Ubiquitous)
The /sprint-plan skill shall parse `$ARGUMENTS` for: `--all` flag, `--apply` flag, `--dry-run` flag, `--yolo` flag, and `--limit <N>` override.

### REQ-SPB-034 (Ubiquitous)
The /sprint-plan skill shall follow `core/config-reader.md` to parse Automation Config. It shall require the `### Sprint Planning` optional section to be present. If absent, the skill shall Block with: "Sprint Planning section not found in Automation Config. Add it to enable sprint planning. See docs/reference/config-reference.md."

### REQ-SPB-035 (Ubiquitous)
The /sprint-plan skill shall follow `core/mcp-preflight.md` to verify tracker MCP availability.

### REQ-SPB-036 (Ubiquitous)
The /sprint-plan skill shall dispatch priority-engine via Task tool (model: opus) with the issue list as context. If priority-engine fails or returns an error, the skill shall Block.

### REQ-SPB-037 (Ubiquitous)
The /sprint-plan skill shall dispatch sprint-planner via Task tool (model: sonnet) with priority-engine output, Sprint Planning config values, and velocity source data as context.

### REQ-SPB-038 (Ubiquitous)
The /sprint-plan skill shall implement Gate 1 (Capacity confirmation): display the sprint-planner's output table and prompt "Accept this sprint plan? [Y/n]". In `--yolo` mode, auto-approve. If rejected, exit cleanly with no tracker writes.

### REQ-SPB-039 (Ubiquitous)
The /sprint-plan skill shall implement Gate 2 (Unmapped AC warning): for each issue in the selected sprint that has fewer than 2 acceptance criteria (from triage checkpoint comments), display a warning. This gate shall Block even in `--yolo` mode. The gate checks that sprint issues have sufficient AC for downstream implement-feature pipeline quality.

### REQ-SPB-040 (Ubiquitous)
The /sprint-plan skill shall implement Gate 3 (Final confirmation): display the final plan with tracker assignment details and prompt "Start sprint? Write assignments to tracker? [Y/n]". In `--yolo` mode, auto-approve. In `--dry-run` mode, display the plan and exit before this gate.

### REQ-SPB-041 (Ubiquitous)
The /sprint-plan skill shall execute sprint_assign for each selected issue using the 3-tier fallback per tracker (MCP > Bash+REST > skip+warn). Every assignment failure shall be NON-BLOCKING: log warning, record `sprint_assigned: false`, continue to next issue.

### REQ-SPB-042 (Optional)
Where Mode is `apply` or `--apply` flag is present, after sprint assignment, the /sprint-plan skill shall dispatch `/ceos-agents:implement-feature {issue-id}` (or `/ceos-agents:fix-ticket {issue-id}` for bug-type issues) for each selected issue. Issues with unmet dependencies shall wait until their dependency completes. If a dependency pipeline blocks, dependent issues shall also be marked as blocked.

### REQ-SPB-043 (Ubiquitous)
The /sprint-plan skill shall determine effective_capacity as: `min(Team capacity, Velocity target)` when both are set; whichever is set when only one is configured; null when neither is configured (unconstrained mode).

### REQ-SPB-044 (Ubiquitous)
The /sprint-plan skill shall determine velocity_source using the 3-tier fallback: Tier 1 (historical) reads `./reports/metrics.md`; Tier 2 (heuristic) uses effort mappings with configured capacity; Tier 3 (manual/unconstrained) prompts user or uses top-N. If metrics file exists but is corrupt or unparseable, fall back to Tier 2 with a warning.

### REQ-SPB-045 (Ubiquitous)
The /sprint-plan skill shall generate sprint_name using the pattern `Sprint {YYYY}-W{WW}` where YYYY is the current year and WW is the current ISO week number.

### REQ-SPB-046 (Ubiquitous)
The /sprint-plan skill shall initialize state at `.ceos-agents/sprint-{YYYYMMDD-HHmmss}/state.json` and follow the atomic write protocol from `core/state-manager.md`.

### REQ-SPB-047 (Ubiquitous)
The /sprint-plan skill shall have YAML frontmatter: `name: sprint-plan`, `description: Plans a sprint from backlog issues using capacity constraints and priority ranking`, `allowed-tools: mcp__*, Bash, Read, Glob, Grep, Task`, `disable-model-invocation: true`, `argument-hint: "[--all] [--apply] [--dry-run] [--limit <N>] [--yolo]"`.

---

## 5. --decompose-only Flag (implement-feature)

### REQ-SPB-048 (Optional)
Where `--decompose-only` flag is present on /implement-feature, the skill shall execute Steps 0 through 5a (config validation, MCP pre-flight, spec-analyst, architect, decomposition decision, tracker subtask creation) and then exit with the decomposition result displayed. Steps 6 through 10 (fixer, reviewer, test, publisher) shall not execute.

### REQ-SPB-049 (Event-driven)
When `--decompose-only` is combined with `--no-decompose`, the skill shall reject the combination with: "Cannot use --decompose-only with --no-decompose. These flags are mutually exclusive."

### REQ-SPB-050 (Event-driven)
When `--decompose-only` completes successfully, the skill shall display the decomposition plan table (same format as Step 5) and output: "Decomposition complete. {N} subtasks created in tracker. Run `/ceos-agents:implement-feature {ISSUE-ID}` to begin implementation."

---

## 6. Config Contract

### REQ-SPB-051 (Ubiquitous)
The `### Sprint Planning` section shall be an OPTIONAL section in Automation Config using `| Key | Value |` table format, consistent with all other optional config sections.

### REQ-SPB-052 (Ubiquitous)
The `### Sprint Planning` section shall support exactly 7 keys with these defaults:

| Key | Default | Validation |
|-----|---------|------------|
| Sprint duration | 2 weeks | One of: `1 week`, `2 weeks`, `3 weeks`, `4 weeks` |
| Capacity unit | story-points | One of: `story-points`, `hours` |
| Team capacity | (none) | Positive integer; 0 treated as unconfigured |
| Velocity target | (none) | Positive integer; shall be <= Team capacity when both set |
| Sprint field | (tracker-dependent) | String: tracker field name for sprint assignment |
| Mode | suggest | One of: `suggest`, `apply` |
| Max issues | 20 | Integer 1-50 |

### REQ-SPB-053 (Unwanted)
If Velocity target exceeds Team capacity when both are configured, the /sprint-plan skill shall display a warning: "Velocity target ({V}) exceeds Team capacity ({C}). Using Team capacity as effective capacity." and use Team capacity.

### REQ-SPB-054 (Ubiquitous)
The `### Sprint Planning` section shall also support an optional `Epic template` key with a file path value. If absent, the built-in Epic Card Template shall be used.

### REQ-SPB-055 (Ubiquitous)
The absence of the `### Sprint Planning` section shall not affect any existing pipeline (/fix-ticket, /fix-bugs, /implement-feature, /scaffold). Only /sprint-plan shall require it.

---

## 7. State Schema Extensions

### REQ-SPB-056 (Ubiquitous)
Sprint planning runs shall use RUN-ID format `sprint-{YYYYMMDD-HHmmss}` and mode `sprint-planning`.

### REQ-SPB-057 (Ubiquitous)
Backlog creation runs shall use RUN-ID format `backlog-{YYYYMMDD-HHmmss}` and mode `backlog-creation`.

### REQ-SPB-058 (Ubiquitous)
The sprint state object shall contain: `name` (string), `duration` (string), `effective_capacity` (integer or null), `velocity_source` (string: "historical", "heuristic", or "manual"), `issues` (array of issue objects), `completed_issues` (integer), `blocked_issues` (integer).

### REQ-SPB-059 (Ubiquitous)
Each sprint issue object shall contain: `issue_id` (string), `tier` (string: P0/P1/P2), `effort_points` (integer), `type` (string: "bug" or "feature"), `sprint_assigned` (boolean), `child_run_id` (string or null), `status` (string: "pending", "running", "completed", "blocked").

---

## 8. Integration Updates

### REQ-SPB-060 (Ubiquitous)
The workflow-router intent mapping table shall include the following new rows:

| User Intent | Command | Arguments | Destructive? |
|-------------|---------|-----------|-------------|
| Create backlog from spec | `ceos-agents:create-backlog` | Spec path + optional flags | Yes |
| Plan a sprint / sprint planning | `ceos-agents:sprint-plan` | Optional flags | Yes |
| Decompose a feature into subtasks only | `ceos-agents:implement-feature` | Issue ID + `--decompose-only` | Yes |

### REQ-SPB-061 (Ubiquitous)
The CLAUDE.md config contract table for optional sections shall include `Sprint Planning` with keys: `Sprint duration, Capacity unit, Team capacity, Velocity target, Sprint field, Mode, Max issues, Epic template`.

### REQ-SPB-062 (Ubiquitous)
The CLAUDE.md agent count shall be updated from 19 to 21 and skill count from 26 to 28.

### REQ-SPB-063 (Ubiquitous)
The CLAUDE.md model table shall include backlog-creator and sprint-planner under the sonnet row (Analysis, testing, triage, specification, scaffolding, AC verification, deployment, backlog creation, sprint planning).

### REQ-SPB-064 (Ubiquitous)
Scaffold Step 4e shall NOT be refactored to use backlog-creator. The scaffold Step 4e creates story-level sub-issues from an already-decomposed spec (epics with `### Story N.M` sections), while backlog-creator creates epic-level issues from a raw specification. These operate at different granularity levels, and forcing a shared agent would require backlog-creator to handle two incompatible input/output contracts. The recommendation is: leave scaffold Step 4e unchanged; document the distinction in design.md.

---

## 9. Cross-Cutting Concerns

### REQ-SPB-065 (Ubiquitous)
Both backlog-creator and sprint-planner agents shall follow the established agent definition format: YAML frontmatter (name, description, model, style) followed by Goal, Expertise, Process (numbered steps), Constraints (NEVER rules and hard limits).

### REQ-SPB-066 (Ubiquitous)
Both /create-backlog and /sprint-plan skills shall follow `core/agent-override-injector.md`: before dispatching any agent via Task tool, check if `{Agent Overrides path}/{agent-name}.md` exists and append its content as `## Project-Specific Instructions`.

### REQ-SPB-067 (Ubiquitous)
All tracker operations in /create-backlog and /sprint-plan skills shall use the tracker-type-specific MCP tool prefixes defined in `core/mcp-detection.md`, including alternative prefixes for Jira (`mcp__jira__*` or `mcp__atlassian__*`) and Gitea (`mcp__gitea__*` or `mcp__forgejo__*`).

### REQ-SPB-068 (Ubiquitous)
The version bump from v6.4.6 to v6.5.0 shall be MINOR per the versioning policy: new optional config section, new agents, new skills, no breaking changes to existing config contract or agent output formats.
