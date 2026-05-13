# Acceptance Criteria: Sprint Planning & Backlog Management

> Each criterion is testable via the test harness (`tests/harness/run-tests.sh`) or manual verification.
> Criteria IDs map to requirement groups in requirements.md.

---

## AC-01: backlog-creator Agent Definition

**Given** the file `agents/backlog-creator.md` exists
**When** the test harness validates agent definitions
**Then** the file shall contain YAML frontmatter with `name: backlog-creator`, `model: sonnet`, a `description` field, and a `style` field, followed by sections Goal, Expertise, Process (numbered), and Constraints (with NEVER rules).

**Test:** Extend `tests/scenarios/agent-frontmatter.sh` to include `backlog-creator`. Verify frontmatter keys, section headings, and model value.

---

## AC-02: sprint-planner Agent Definition

**Given** the file `agents/sprint-planner.md` exists
**When** the test harness validates agent definitions
**Then** the file shall contain YAML frontmatter with `name: sprint-planner`, `model: sonnet`, a `description` field, and a `style` field, followed by sections Goal, Expertise, Process (numbered), and Constraints (with NEVER rules). The Constraints section shall include "NEVER re-rank issues" and "NEVER modify code".

**Test:** Extend `tests/scenarios/agent-frontmatter.sh` to include `sprint-planner`. Verify frontmatter keys, section headings, model value, and grep for re-rank constraint.

---

## AC-03: /create-backlog Skill Definition

**Given** the file `skills/create-backlog/SKILL.md` exists
**When** the test harness validates skill definitions
**Then** the file shall contain YAML frontmatter with `name: create-backlog`, `disable-model-invocation: true`, `allowed-tools` including `mcp__*`, `Task`, and `Read`, and an `argument-hint` containing `<spec-path>`. The body shall reference `core/config-reader.md`, `core/mcp-preflight.md`, and `core/agent-override-injector.md`.

**Test:** Create `tests/scenarios/create-backlog-skill.sh`. Verify frontmatter keys, core references, and flag documentation.

---

## AC-04: /sprint-plan Skill Definition

**Given** the file `skills/sprint-plan/SKILL.md` exists
**When** the test harness validates skill definitions
**Then** the file shall contain YAML frontmatter with `name: sprint-plan`, `disable-model-invocation: true`, `allowed-tools` including `mcp__*`, `Task`, and `Read`, and an `argument-hint` containing `--all`, `--apply`, `--dry-run`. The body shall reference `core/config-reader.md`, `core/mcp-preflight.md`, and dispatch both `priority-engine` and `sprint-planner` agents via Task tool.

**Test:** Create `tests/scenarios/sprint-plan-skill.sh`. Verify frontmatter keys, core references, agent dispatches, and gate documentation.

---

## AC-05: Read-Only Agent Compliance

**Given** the agents `backlog-creator` and `sprint-planner` are defined
**When** the read-only agent test suite runs (`tests/scenarios/read-only-agents.sh`)
**Then** both agents shall pass the read-only check: their `allowed-tools` (if specified) shall not include `Write`, `Edit`, or `Bash`, and their Constraints section shall contain "NEVER modify code" or equivalent.

**Test:** Extend `tests/scenarios/read-only-agents.sh` to include both new agents. The test verifies that read-only agents do not have write capabilities.

---

## AC-06: Config Contract -- Sprint Planning Section

**Given** the `core/config-reader.md` file lists optional sections
**When** the `### Sprint Planning` section is present in a project's CLAUDE.md
**Then** the config reader shall parse 8 keys: `Sprint duration`, `Capacity unit`, `Team capacity`, `Velocity target`, `Sprint field`, `Mode`, `Max issues`, `Epic template`, with documented defaults for each.

**Given** the `### Sprint Planning` section is absent from a project's CLAUDE.md
**When** `/sprint-plan` is invoked
**Then** the skill shall Block with the message "Sprint Planning section not found in Automation Config."

**Given** the `### Sprint Planning` section is absent
**When** any other pipeline skill is invoked (`/fix-ticket`, `/fix-bugs`, `/implement-feature`, `/scaffold`)
**Then** the skill shall not be affected -- the absent section shall not cause warnings or errors in other pipelines.

**Test:** Create `tests/scenarios/sprint-config-parsing.sh`. Verify: (a) config-reader.md mentions Sprint Planning, (b) 8 keys are documented, (c) CLAUDE.md optional sections table includes Sprint Planning.

---

## AC-07: Sprint Assignment NON-BLOCKING Behavior

**Given** a sprint plan with 3 issues has been approved at Gate 3
**When** sprint_assign fails for issue #2 (MCP error, REST timeout, or missing environment variable)
**Then** the skill shall log a warning for issue #2 with `sprint_assigned: false`, continue to assign issue #3, and display the final summary "Assigned {N}/{3} issues to {sprint_name}". The pipeline shall not Block or stop.

**Test:** Create `tests/scenarios/sprint-assign-nonblocking.sh`. Verify: (a) skill documentation specifies NON-BLOCKING for every assignment failure, (b) accumulator pattern is documented, (c) all 6 tracker entries in the dispatch table show `skip+warn` as Tier 3.

---

## AC-08: Priority-Engine Output Consumption

**Given** the sprint-planner agent receives priority-engine output
**When** the output contains P0, P1, P2 tier tables with Issue, Impact, Risk, Effort, Score columns
**Then** the sprint-planner shall parse all fields, preserve the priority-engine sort order exactly, and never re-rank or reorder issues.

**Given** the priority-engine output is missing expected columns (e.g., no Effort column)
**When** the sprint-planner processes the output
**Then** the sprint-planner shall use default values (Effort=3) for missing fields and annotate the output with a warning about missing data.

**Test:** Create `tests/scenarios/sprint-planner-priority-consumption.sh`. Verify: (a) sprint-planner Process step references priority-engine output format, (b) Constraints include "NEVER re-rank", (c) default values for missing fields are documented.

---

## AC-09: --decompose-only Early Exit

**Given** `/implement-feature PROJ-42 --decompose-only` is invoked
**When** Steps 0 through 5a (config, MCP, spec-analyst, architect, decomposition, tracker subtask creation) complete successfully
**Then** the skill shall display the decomposition plan table, output the completion message with subtask count, set `state.json` status to `"completed"`, and exit without executing Steps 6 through 10 (fixer, reviewer, test-engineer, publisher).

**Given** `--decompose-only` is combined with `--no-decompose`
**When** flag parsing executes
**Then** the skill shall stop with error "Cannot use --decompose-only with --no-decompose. These flags are mutually exclusive."

**Test:** Create `tests/scenarios/decompose-only-flag.sh`. Verify: (a) flag is documented in implement-feature SKILL.md argument-hint, (b) mutual exclusion with --no-decompose is documented, (c) early exit after Step 5a is documented, (d) Steps 6-10 are explicitly skipped.

---

## AC-10: Cold-Start and Velocity Fallback

**Given** no `./reports/metrics.md` exists and no Team capacity or Velocity target is configured
**When** `/sprint-plan` is invoked
**Then** the skill shall fall through to Tier 3 (manual/unconstrained) and display the cold-start annotation at every gate: "This plan uses {velocity_source} velocity data. Capacity estimates may not reflect actual team throughput."

**Given** `./reports/metrics.md` exists but is corrupt (not parseable markdown)
**When** `/sprint-plan` is invoked
**Then** the skill shall warn "Metrics file unreadable, falling back to heuristic", use Tier 2 if Team capacity/Velocity target is configured, or Tier 3 otherwise.

**Test:** Create `tests/scenarios/sprint-velocity-fallback.sh`. Verify: (a) 3-tier fallback is documented in sprint-plan SKILL.md, (b) cold-start annotation text is specified, (c) corrupt metrics handling is specified.

---

## AC-11: --update Matching Algorithm

**Given** a specification with 3 epics and a tracker project with 2 existing open feature issues whose titles partially match 2 of the epics
**When** `/create-backlog spec/ --update` is invoked
**Then** the skill shall display a match preview table showing MATCHED entries (with similarity score) and NEW entries, prompt for confirmation, then update matched issues and create new ones.

**Given** a tracker project with 0 open issues
**When** `/create-backlog spec/ --update` is invoked
**Then** the skill shall behave identically to create mode (all epics are unmatched), creating all issues as new.

**Test:** Create `tests/scenarios/create-backlog-update.sh`. Verify: (a) matching algorithm is documented in SKILL.md or design.md, (b) Jaccard similarity threshold (0.7) is specified, (c) prefix match (40 chars) is specified, (d) multiple-match disambiguation is specified, (e) empty-tracker edge case is specified.

---

## AC-12: Workflow Router Integration

**Given** the workflow-router intent mapping table in `skills/workflow-router/SKILL.md`
**When** a user says "create backlog from my spec", "plan a sprint", or "just decompose this feature"
**Then** the router shall match these intents to `ceos-agents:create-backlog`, `ceos-agents:sprint-plan`, and `ceos-agents:implement-feature --decompose-only` respectively.

**Test:** Extend `tests/scenarios/workflow-router-intents.sh`. Verify: (a) 4 new rows exist in the intent table, (b) each row has correct Command, Arguments, and Destructive? values.

---

## AC-13: State Schema Compliance

**Given** the state schema documentation in `state/schema.md`
**When** v6.5.0 is released
**Then** the schema shall include:
- RUN-ID format `sprint-{YYYYMMDD-HHmmss}` in the RUN-ID Determination table
- RUN-ID format `backlog-{YYYYMMDD-HHmmss}` in the RUN-ID Determination table
- Mode values `sprint-planning` and `backlog-creation` documented
- Sprint state object fields: `name`, `duration`, `effective_capacity`, `velocity_source`, `issues[]`, `completed_issues`, `blocked_issues`
- Backlog state object fields: `spec_path`, `epics_total`, `epics_created`, `epics_failed`, `subtasks_created`, `created_issues[]`

**Test:** Create `tests/scenarios/state-schema-sprint.sh`. Grep `state/schema.md` for the new RUN-ID formats, mode values, and field definitions.

---

## AC-14: Version and Count Updates

**Given** the CLAUDE.md file at the repository root
**When** v6.5.0 is released
**Then**:
- The agent count shall read "21 agents" (up from 19)
- The skill count shall read "28 skills" (up from 26)
- The model table sonnet row shall include `backlog-creator` and `sprint-planner`
- The optional config sections table shall include `Sprint Planning` with its keys
- The version bump shall be MINOR (v6.4.6 to v6.5.0) per the versioning policy

**Test:** Extend existing `tests/scenarios/plugin-metadata.sh`. Verify counts in CLAUDE.md, model table entries, and config section table.

---

## AC-15: Scaffold Step 4e Refactored to Use backlog-creator

**Given** the scaffold skill at `skills/scaffold/SKILL.md`
**When** v6.5.0 is released
**Then** Step 4e (Create Tracker Issues) shall dispatch the backlog-creator agent in task mode with architect decomposition output. The skill shall:
- Pass architect output to backlog-creator via Task tool
- Receive structured sub-task cards back
- Create tracker issues using the existing per-tracker dispatch table
- Write back-reference comments (`<!-- {TrackerType}: {ID} -->`) into spec files (scaffold's responsibility, not the agent's)
- Maintain parent-child issue relationships (scaffold's responsibility)

**Test:** Create `tests/scenarios/scaffold-4e-backlog-creator.sh`. Verify: (a) Step 4e references `backlog-creator` agent dispatch, (b) back-reference comment protocol is preserved in the skill, (c) task mode input is passed to the agent.

## AC-16: backlog-creator Task Mode

**Given** the backlog-creator agent at `agents/backlog-creator.md`
**When** the agent receives architect decomposition output with `### Story` or `### Task` sections
**Then** the agent shall produce sub-task-level cards (not epic-level), preserve `maps_to` traceability fields, and produce the same structured card format usable by both create-backlog and scaffold skills.

**Test:** Extend `tests/scenarios/create-backlog-skill.sh` to verify backlog-creator Process section mentions task mode with story/task detection.
