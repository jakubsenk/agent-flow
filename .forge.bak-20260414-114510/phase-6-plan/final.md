# Implementation Plan: Sprint Planning & Backlog Management (v6.5.0)

> **Feature:** Sprint planning, backlog creation, capacity-constrained sprint plans
> **Requirements:** `.forge/phase-4-spec/final/requirements.md` (68 EARS requirements)
> **Design:** `.forge/phase-4-spec/final/design.md` (agents, skills, dispatch tables, state)
> **Tests:** `.forge/phase-5-tdd/tests/` (18 test files)
> **Post-implementation counts:** 21 agents, 28 skills, 11 read-only agents

---

## Dependency Diagram

```
Layer 1:  [T1] [T2] [T3] [T4]        <-- all parallel (no deps)
              |
Layer 2:  [T5] [T6] [T7]             <-- parallel (T5 dep T1,T3; T6 dep T2,T3; T7 standalone)
              |
Layer 3:  [T8] [T9] [T10]            <-- parallel (T8 dep T5,T6; T9 dep T5,T6; T10 dep T5,T6)
              |
Layer 4:  [T11] [T12]                <-- parallel (T11 dep T8,T9,T10; T12 dep T8,T9,T10)
              |
Layer 5:  [T13]                       <-- sequential (dep on all)
```

---

## Layer 1 -- Foundation (no dependencies, all parallel)

### Task 1: Create backlog-creator Agent Definition
- **Layer:** 1
- **Depends on:** none
- **Parallel group:** A
- **Files:** create `agents/backlog-creator.md`
- **Estimated lines:** 130 (new)
- **Acceptance criteria:**
  1. File exists at `agents/backlog-creator.md`
  2. YAML frontmatter has `name: backlog-creator`, `model: sonnet`, `description:`, `style:` fields
  3. Body has sections in order: `## Goal`, `## Expertise`, `## Process`, `## Constraints`
  4. Process section documents spec mode (spec/ folder, single file, multiple files) and task mode (architect decomposition with `maps_to` preservation)
  5. Constraints section includes at least one NEVER rule (NEVER modify code, files, or tracker issues)
  6. Process section does NOT contain write-tool phrases (Write tool, Edit tool, write to file, create file, save file)
  7. Constraints include: max 10 epics, 2-5 AC per epic, size mapping XS=1 S=2 M=3 L=5
  8. Block Comment Template used for empty/unparseable spec input (agent: backlog-creator, step: Spec Parsing)
  9. Backlog Summary table format matches REQ-SPB-008 (# | Epic | AC | Size | SP | Dependencies)
  10. Epic Card Template output matches design.md section 7 format
- **Implementation notes:**
  - Source: design.md section 2 has the full agent definition as a code block -- use it verbatim, cleaning up only the markdown code fence wrapping
  - Pattern: follow `agents/priority-engine.md` structure (~78 lines) and `agents/spec-analyst.md` (~97 lines) for length/style reference
  - REQ coverage: REQ-SPB-001 through REQ-SPB-009, REQ-SPB-065
  - Tests: `backlog-creator-agent.sh`, `backlog-creator-read-only.sh`

### Task 2: Create sprint-planner Agent Definition
- **Layer:** 1
- **Depends on:** none
- **Parallel group:** A
- **Files:** create `agents/sprint-planner.md`
- **Estimated lines:** 120 (new)
- **Acceptance criteria:**
  1. File exists at `agents/sprint-planner.md`
  2. YAML frontmatter has `name: sprint-planner`, `model: sonnet`, `description:`, `style:` fields
  3. Body has sections in order: `## Goal`, `## Expertise`, `## Process`, `## Constraints`
  4. Section order verified: Goal line < Expertise line < Process line < Constraints line
  5. Constraints section includes "NEVER re-rank" rule
  6. Constraints section includes at least one NEVER rule
  7. Process section does NOT contain write-tool phrases
  8. Process documents: effort resolution precedence (triage > priority-engine > default), capacity inclusion formula with 20% overflow buffer, `decompose_recommended` flag logic, unconstrained mode
  9. Output format matches REQ-SPB-017 exactly (Sprint Plan header, Selected Issues table, Overflow table, Dependency Warnings, Cold Start Warnings)
  10. `--all` mode multi-sprint release plan with Release Summary table documented
  11. Block Comment Template for unparseable priority-engine output
- **Implementation notes:**
  - Source: design.md section 3 has the full agent definition -- use it verbatim
  - REQ coverage: REQ-SPB-010 through REQ-SPB-020, REQ-SPB-065
  - Tests: `sprint-planner-agent.sh`, `sprint-planner-read-only.sh`

### Task 3: Extend Config Reader with Sprint Planning Section
- **Layer:** 1
- **Depends on:** none
- **Parallel group:** A
- **Files:** modify `core/config-reader.md`
- **Estimated lines:** 15 (diff)
- **Acceptance criteria:**
  1. `core/config-reader.md` contains `### Sprint Planning` in the optional sections list
  2. File mentions `Sprint duration` key (default: `2 weeks`)
  3. File mentions `Capacity unit` key (default: `story-points`)
  4. File mentions `Team capacity` key (default: none)
  5. File mentions `Velocity target` key (default: none)
  6. File mentions `Sprint field` key (default: tracker-dependent)
  7. File mentions `Mode` key (default: `suggest`)
  8. File mentions `Max issues` key (default: 20)
  9. File mentions `Epic template` key (default: none)
  10. Parsed into `sprint_planning.*` namespace (e.g., `sprint_planning.sprint_duration`)
- **Implementation notes:**
  - Add a new bullet to the existing optional sections list (step 3), following the exact format of neighboring entries
  - Example pattern from existing: `- \`### Local Deployment\` -> keys: \`Type\` (mapped to ..., default: ...), ...`
  - REQ coverage: REQ-SPB-051 through REQ-SPB-055
  - Test: `sprint-config-section.sh`

### Task 4: Extend State Schema with Sprint and Backlog Formats
- **Layer:** 1
- **Depends on:** none
- **Parallel group:** A
- **Files:** modify `state/schema.md`
- **Estimated lines:** 55 (diff)
- **Acceptance criteria:**
  1. RUN-ID Determination table includes `sprint-{YYYYMMDD-HHmmss}` format for sprint planning
  2. RUN-ID Determination table includes `backlog-{YYYYMMDD-HHmmss}` format for backlog creation
  3. New mode values `sprint-planning` and `backlog-creation` are documented
  4. Sprint state object schema is included (JSON example with `sprint` top-level field containing `name`, `duration`, `effective_capacity`, `velocity_source`, `issues` array, `completed_issues`, `blocked_issues`)
  5. Sprint issue object fields documented: `issue_id`, `tier`, `effort_points`, `type`, `sprint_assigned`, `child_run_id`, `status`
  6. Backlog state object schema included (JSON example with `backlog` top-level field containing `spec_path`, `epics_total`, `epics_created`, `epics_failed`, `subtasks_created`, `created_issues`)
  7. `schema_version` field remains `"1.0"`
- **Implementation notes:**
  - Add two new rows to the RUN-ID Determination table (after existing rows)
  - Add new sections after the Deployment Object Fields section: "Sprint State Object" and "Backlog State Object" with JSON examples from design.md section 11
  - REQ coverage: REQ-SPB-056 through REQ-SPB-059
  - Test: `sprint-state-schema.sh`

---

## Layer 2 -- Core Skills (depends on Layer 1)

### Task 5: Create /create-backlog Skill
- **Layer:** 2
- **Depends on:** T1, T3
- **Parallel group:** B
- **Files:** create `skills/create-backlog/SKILL.md`
- **Estimated lines:** 310 (new)
- **Acceptance criteria:**
  1. File exists at `skills/create-backlog/SKILL.md`
  2. YAML frontmatter: `name: create-backlog`, `description: Creates backlog epics in issue tracker from a specification document`, `allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task`, `disable-model-invocation: true`, `argument-hint: "<spec-path> [--decompose] [--update] [--dry-run] [--yolo]"`
  3. Documents `--decompose`, `--update`, `--dry-run`, `--yolo` flags
  4. References `core/mcp-preflight.md` for MCP pre-flight check
  5. References `core/config-reader.md` for configuration parsing
  6. References `core/agent-override-injector.md` for agent overrides
  7. Dispatches `backlog-creator` agent via Task tool (model: sonnet)
  8. Human gate: display Backlog Summary table, prompt "Create {N} epics?" (auto-approve in --yolo)
  9. Per-tracker dispatch table covers all 6 tracker types (youtrack, jira, linear, redmine, github, gitea) with correct MCP tool prefixes and parameters
  10. Accumulator pattern for partial failure handling
  11. State initialization at `.ceos-agents/backlog-{YYYYMMDD-HHmmss}/state.json`
  12. `--update` matching algorithm documented (design.md section 12)
  13. `--decompose` dispatches architect agent (opus) for subtask creation
  14. `--dry-run` displays preview and stops without tracker writes
- **Implementation notes:**
  - Source: design.md section 4 has the complete skill skeleton -- use it verbatim
  - Section 5 has the per-tracker dispatch table -- include inline
  - Section 7 has the Epic Card Template -- reference it
  - Section 12 has the --update matching algorithm -- include inline
  - Pattern: follow `skills/prioritize/SKILL.md` for lightweight skill structure, but this skill is closer to `skills/implement-feature/SKILL.md` in complexity
  - REQ coverage: REQ-SPB-021 through REQ-SPB-032, REQ-SPB-066, REQ-SPB-067
  - Tests: `create-backlog-skill.sh`, `create-backlog-flags.sh`, `create-backlog-tracker-dispatch.sh`

### Task 6: Create /sprint-plan Skill
- **Layer:** 2
- **Depends on:** T2, T3
- **Parallel group:** B
- **Files:** create `skills/sprint-plan/SKILL.md`
- **Estimated lines:** 350 (new)
- **Acceptance criteria:**
  1. File exists at `skills/sprint-plan/SKILL.md`
  2. YAML frontmatter: `name: sprint-plan`, `description: Plans a sprint from backlog issues using capacity constraints and priority ranking`, `allowed-tools: mcp__*, Bash, Read, Glob, Grep, Task`, `disable-model-invocation: true`, `argument-hint: "[--all] [--apply] [--dry-run] [--limit <N>] [--yolo]"`
  3. Documents `--all`, `--apply`, `--dry-run`, `--limit <N>`, `--yolo` flags
  4. References config-reader.md and requires `### Sprint Planning` section
  5. References MCP pre-flight check
  6. Dispatches `priority-engine` agent via Task tool (model: opus)
  7. Dispatches `sprint-planner` agent via Task tool (model: sonnet)
  8. Implements Gate 1 (Capacity confirmation) with --yolo auto-approve
  9. Implements Gate 2 (Unmapped AC warning) that blocks even in --yolo mode
  10. Implements Gate 3 (Final confirmation) with --dry-run exit point
  11. At least 3 distinct human gate indicators in the file
  12. References capacity (team capacity for sprint planning)
  13. Per-tracker sprint assignment dispatch table covers all 6 tracker types with 3-tier fallback (MCP > Bash+REST > Skip+Warn)
  14. Sprint name generation: `Sprint {YYYY}-W{WW}`
  15. State initialization at `.ceos-agents/sprint-{YYYYMMDD-HHmmss}/state.json`
  16. Velocity source 3-tier fallback documented (historical > heuristic > manual/unconstrained)
  17. `--apply` dispatches implement-feature/fix-ticket per issue
  18. `--yolo` does NOT imply `--apply`
- **Implementation notes:**
  - Source: design.md section 6 has the complete skill skeleton -- use it verbatim
  - Section 8 has the per-tracker sprint assignment dispatch table -- include inline
  - Section 9 has the Gate UX specifications -- follow exactly
  - Section 13 has the capacity model detail (effort mappings, effective capacity computation, velocity fallback)
  - REQ coverage: REQ-SPB-033 through REQ-SPB-047, REQ-SPB-066, REQ-SPB-067
  - Tests: `sprint-plan-skill.sh`, `sprint-plan-flags.sh`, `sprint-plan-gates.sh`, `sprint-plan-priority-engine.sh`, `sprint-plan-tracker-dispatch.sh`

### Task 7: Add --decompose-only Flag to /implement-feature
- **Layer:** 2
- **Depends on:** none (existing file modification)
- **Parallel group:** B
- **Files:** modify `skills/implement-feature/SKILL.md`
- **Estimated lines:** 45 (diff)
- **Acceptance criteria:**
  1. `--decompose-only` flag documented in the Flag Parsing section
  2. `--decompose-only` appears in the `argument-hint` frontmatter field
  3. Mutual exclusion with `--no-decompose` documented (error message: "Cannot use --decompose-only with --no-decompose. These flags are mutually exclusive.")
  4. After decomposition completes (Steps 0-5a), pipeline exits with decomposition result displayed
  5. Steps 6-10 do not execute when `--decompose-only` is active
  6. Success output: "Decomposition complete. {N} subtasks created in tracker. Run `/ceos-agents:implement-feature {ISSUE-ID}` to begin implementation."
  7. References `backlog-creator` or `create-backlog` integration for the decomposition-to-backlog path
- **Implementation notes:**
  - Add `--decompose-only` to the Flag Parsing section (parse as boolean flag)
  - Add new `decompose_only_mode` variable
  - Add mutual exclusion check: if both `--decompose-only` and `--no-decompose` → STOP with error
  - Add early exit after Step 5a: if `decompose_only_mode = true` → display result and STOP
  - Add a brief note after Step 5a about the connection to /create-backlog for spec-to-backlog workflows
  - Keep the diff under 100 lines by being surgical: touch only Flag Parsing, argument-hint, and the Step 5a exit point
  - REQ coverage: REQ-SPB-048 through REQ-SPB-050
  - Test: `implement-feature-decompose-only.sh`

---

## Layer 3 -- Integration (depends on Layer 2)

### Task 8: Update Workflow Router with New Intent Rows
- **Layer:** 3
- **Depends on:** T5, T6
- **Parallel group:** C
- **Files:** modify `skills/workflow-router/SKILL.md`
- **Estimated lines:** 10 (diff)
- **Acceptance criteria:**
  1. Intent mapping table includes a row for "Create backlog from spec" mapping to `ceos-agents:create-backlog`
  2. Intent mapping table includes a row for "Plan a sprint / sprint planning" mapping to `ceos-agents:sprint-plan`
  3. Intent mapping table includes a row for "Decompose a feature into subtasks only" mapping to `ceos-agents:implement-feature` with `--decompose-only`
  4. All three rows follow the existing table format: `| User Intent | Command | Arguments | Destructive? |`
  5. `create-backlog` and `sprint-plan` rows marked as `Yes` destructive
- **Implementation notes:**
  - Add 3 new rows to the Intent Mapping table in `skills/workflow-router/SKILL.md`
  - Place the new rows logically near "Implement a feature" and "Prioritize backlog" rows
  - REQ coverage: REQ-SPB-060
  - Test: `sprint-workflow-router.sh`

### Task 9: Update CLAUDE.md -- Counts, Model Table, Read-Only Agents, Config Contract
- **Layer:** 3
- **Depends on:** T5, T6
- **Parallel group:** C
- **Files:** modify `CLAUDE.md`
- **Estimated lines:** 20 (diff, across 6 touch points)
- **Acceptance criteria:**
  1. `agents/` line says "21 agent definitions" (was 19)
  2. `skills/` line says "28 skills" (was 26)
  3. Model Selection table sonnet row includes `backlog-creator, sprint-planner` in the Agents column (append after `deployment-verifier`)
  4. Model Selection table sonnet row "Used For" column includes `backlog creation, sprint planning` (append after `deployment`)
  5. Read-only agents list includes `backlog-creator, sprint-planner` (append after `acceptance-gate`)
  6. Read-only agents count changes from 9 to 11 in the "11 read-only agents" note (if present as a count)
  7. Optional sections table includes new row: `| Sprint Planning | Sprint duration, Capacity unit, Team capacity, Velocity target, Sprint field, Mode, Max issues, Epic template | 2 weeks, story-points, (none), (none), (tracker-dependent), suggest, 20, (none) |`
  8. `backlog-creator` and `sprint-planner` appear in the file (for test assertions)
  9. Skills list in Architecture section includes `/create-backlog` and `/sprint-plan`
- **Implementation notes:**
  - Touch 6 specific locations in CLAUDE.md:
    1. Repository Structure: `agents/` line -- change 19 to 21
    2. Repository Structure: `skills/` line -- change 26 to 28
    3. Model Selection table: sonnet row -- append agents and "Used For" text
    4. Key Conventions: Read-only agents list -- append 2 new agents
    5. Optional sections table -- add 1 new row after `Local Deployment`
    6. Architecture 2-Layer System: Skills list -- add `/create-backlog`, `/sprint-plan`
  - Each touch point is a small surgical edit (1-3 line change)
  - Total diff well under 100 lines
  - REQ coverage: REQ-SPB-061 through REQ-SPB-063
  - Tests: `sprint-counts.sh`, `backlog-creator-read-only.sh` (CLAUDE.md assertions), `sprint-planner-read-only.sh` (CLAUDE.md assertions), `sprint-config-section.sh` (CLAUDE.md assertion)

### Task 10: Update Scaffold Step 4e to Reference backlog-creator
- **Layer:** 3
- **Depends on:** T1
- **Parallel group:** C
- **Files:** modify `skills/scaffold/SKILL.md`
- **Estimated lines:** 10 (diff)
- **Acceptance criteria:**
  1. Step 4e section exists in `skills/scaffold/SKILL.md`
  2. Step 4e mentions `backlog-creator` or `create-backlog` within 15 lines of the step heading
  3. The word `backlog-creator` or `create-backlog` appears at least once in the entire scaffold skill file
  4. Existing Step 4e logic is NOT replaced (per REQ-SPB-064: scaffold Step 4e is NOT refactored)
  5. Only a documentation note is added clarifying the relationship: scaffold Step 4e creates story-level sub-issues from pre-decomposed spec, while backlog-creator creates epic-level issues from raw specifications
- **Implementation notes:**
  - REQ-SPB-064 explicitly states: "Scaffold Step 4e shall NOT be refactored to use backlog-creator." Instead, add a brief note/comment at the top of Step 4e explaining the distinction
  - Add ~3-5 lines of documentation: "Note: This step handles story-level sub-issue creation from scaffold v2 pre-decomposed epics. For creating epic-level issues from a raw specification (without scaffold), use `/ceos-agents:create-backlog` which dispatches the `backlog-creator` agent."
  - Do NOT change the existing Step 4e logic, guard clauses, or tracker dispatch
  - Test: `scaffold-4e-backlog-creator.sh`

---

## Layer 4 -- Documentation (depends on Layer 3)

### Task 11: Update docs/reference/skills.md with New Skills
- **Layer:** 4
- **Depends on:** T8, T9, T10
- **Parallel group:** D
- **Files:** modify `docs/reference/skills.md`
- **Estimated lines:** 80 (diff)
- **Acceptance criteria:**
  1. Skill Index table includes `| Planning | [/create-backlog](#create-backlog) | Creates backlog epics from specification |`
  2. Skill Index table includes `| Planning | [/sprint-plan](#sprint-plan) | Plans a sprint with capacity constraints |`
  3. Total skill count in the file header updated from 26 to 28
  4. Full `/create-backlog` skill documentation section added (Syntax, Arguments, Flags, What it does, Example, Related skills)
  5. Full `/sprint-plan` skill documentation section added (Syntax, Arguments, Flags, What it does, Example, Related skills)
  6. Both sections placed under the `## Planning Skills` heading (after /prioritize)
  7. Documentation follows the exact format of existing skill entries (e.g., /prioritize, /estimate)
- **Implementation notes:**
  - Follow the exact documentation pattern from existing entries:
    ```
    ### /skill-name
    > One-line description
    **Syntax:** ...
    **Arguments:** ...
    **Flags:** ...
    **What it does:** ...
    **Example:** ...
    **Related skills:** ...
    ```
  - Add /create-backlog and /sprint-plan entries after /prioritize in the Planning Skills section
  - Update the Skill Index table with two new rows
  - Update the header count: "All 28 ceos-agents skills"
  - REQ coverage: documentation requirements (no specific REQ, but implied by REQ-SPB-032, REQ-SPB-047)

### Task 12: Update docs/plans/roadmap.md -- Move Sprint Planning Entry
- **Layer:** 4
- **Depends on:** T8, T9, T10
- **Parallel group:** D
- **Files:** modify `docs/plans/roadmap.md`
- **Estimated lines:** 20 (diff)
- **Acceptance criteria:**
  1. The "Sprint planning / tracking" entry is removed from the NOT PLANNED section
  2. A new entry is added under either "PLANNED -- v6.5.0" or "DONE -- v6.5.0" (depending on state at time of implementation) with title "Sprint Planning & Backlog Management"
  3. Entry includes: source reference, brief description (2 new agents, 2 new skills, 1 new flag, config extension), file list
  4. Version number in the header is updated to current if needed
- **Implementation notes:**
  - Remove the row: `| **Sprint planning / tracking** | ceos-agents is not a PM tool. Sprint tracking is delegated to issue trackers. |`
  - Add a new "PLANNED -- v6.5.0" section (or append to "DONE -- v6.5.0" if implementation is complete by then):
    ```
    ### Sprint Planning & Backlog Management
    **Source:** Feature specification (`.forge/phase-4-spec/final/requirements.md`)
    2 new agents (backlog-creator, sprint-planner), 2 new skills (/create-backlog, /sprint-plan),
    --decompose-only flag on /implement-feature, Sprint Planning config section, state schema extensions.
    **Files:** `agents/backlog-creator.md`, `agents/sprint-planner.md`, `skills/create-backlog/SKILL.md`, `skills/sprint-plan/SKILL.md`, `skills/implement-feature/SKILL.md`, `core/config-reader.md`, `state/schema.md`, `CLAUDE.md`, `skills/workflow-router/SKILL.md`, `docs/reference/skills.md`
    ```

---

## Layer 5 -- Tests (depends on all)

### Task 13: Copy Test Scenarios and Validate
- **Layer:** 5
- **Depends on:** T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12
- **Parallel group:** E
- **Files:** create 18 files in `tests/scenarios/` (copy from `.forge/phase-5-tdd/tests/`)
- **Estimated lines:** 18 files, ~850 lines total (copy)
- **Acceptance criteria:**
  1. All 18 test files from `.forge/phase-5-tdd/tests/` are copied to `tests/scenarios/`
  2. All 18 tests pass when run with `./tests/harness/run-tests.sh`
  3. No existing tests regress (all 54 existing scenarios still pass)
  4. File permissions are executable (chmod +x)
- **Implementation notes:**
  - Copy each file from `.forge/phase-5-tdd/tests/` to `tests/scenarios/`:
    - `backlog-creator-agent.sh`
    - `sprint-planner-agent.sh`
    - `backlog-creator-read-only.sh`
    - `sprint-planner-read-only.sh`
    - `create-backlog-skill.sh`
    - `create-backlog-flags.sh`
    - `create-backlog-tracker-dispatch.sh`
    - `sprint-plan-skill.sh`
    - `sprint-plan-flags.sh`
    - `sprint-plan-tracker-dispatch.sh`
    - `sprint-plan-priority-engine.sh`
    - `sprint-plan-gates.sh`
    - `implement-feature-decompose-only.sh`
    - `sprint-config-section.sh`
    - `sprint-workflow-router.sh`
    - `sprint-state-schema.sh`
    - `sprint-counts.sh`
    - `scaffold-4e-backlog-creator.sh`
  - The test files use `REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"` which resolves correctly from `tests/scenarios/` (3 levels up to repo root)
  - Run full test suite to verify no regressions
  - Total after copy: 72 test scenarios (54 existing + 18 new)

---

## Summary

| Metric | Value |
|--------|-------|
| Total tasks | 13 |
| New files | 4 (2 agents, 2 skills) |
| Modified files | 6 (CLAUDE.md, config-reader, state schema, implement-feature, workflow-router, scaffold) |
| Documentation files modified | 2 (skills.md, roadmap.md) |
| Test files copied | 18 |
| Estimated new lines | ~910 (agents + skills) |
| Estimated diff lines | ~180 (modifications) |
| Max parallelism | 4 tasks (Layer 1) |

### REQ Coverage Matrix

| Task | Requirements Covered |
|------|---------------------|
| T1 | REQ-SPB-001 to 009, 065 |
| T2 | REQ-SPB-010 to 020, 065 |
| T3 | REQ-SPB-051 to 055 |
| T4 | REQ-SPB-056 to 059 |
| T5 | REQ-SPB-021 to 032, 066, 067 |
| T6 | REQ-SPB-033 to 047, 066, 067 |
| T7 | REQ-SPB-048 to 050 |
| T8 | REQ-SPB-060 |
| T9 | REQ-SPB-061 to 063 |
| T10 | REQ-SPB-064 |
| T11 | (documentation, no specific REQ) |
| T12 | (documentation, no specific REQ) |
| T13 | (validation of all REQs via tests) |

All 68 requirements (REQ-SPB-001 through REQ-SPB-068) are covered. REQ-SPB-068 (version bump MINOR) is handled separately outside this plan.

### Test Coverage Matrix

| Test File | Tasks That Must Pass It |
|-----------|------------------------|
| `backlog-creator-agent.sh` | T1 |
| `backlog-creator-read-only.sh` | T1, T9 |
| `sprint-planner-agent.sh` | T2 |
| `sprint-planner-read-only.sh` | T2, T9 |
| `create-backlog-skill.sh` | T5 |
| `create-backlog-flags.sh` | T5 |
| `create-backlog-tracker-dispatch.sh` | T5 |
| `sprint-plan-skill.sh` | T6 |
| `sprint-plan-flags.sh` | T6 |
| `sprint-plan-tracker-dispatch.sh` | T6 |
| `sprint-plan-priority-engine.sh` | T6 |
| `sprint-plan-gates.sh` | T6 |
| `implement-feature-decompose-only.sh` | T7 |
| `sprint-config-section.sh` | T3, T9 |
| `sprint-workflow-router.sh` | T8 |
| `sprint-state-schema.sh` | T4 |
| `sprint-counts.sh` | T9 |
| `scaffold-4e-backlog-creator.sh` | T10 |
