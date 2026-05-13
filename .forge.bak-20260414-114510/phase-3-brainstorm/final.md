# Phase 3: Brainstorm Synthesis --- Sprint Planning Design

## Judge's Verdict

### Scoring

Each dimension scored 1-5 on Feasibility, Value, Robustness, Simplicity, Consistency. Winner takes the design for that dimension.

| Dimension | Conservative (A) | Innovative (B) | Skeptical (C) | Winner | Rationale |
|-----------|:-:|:-:|:-:|--------|-----------|
| 1. Architecture | 4 | 4 | 5 | **C (Skeptical)** | All three agree on 1 agent + 1 skill. C adds the critical constraint that sprint-planner must be stateless (persistence is the skill's job). This is the cleanest separation and prevents the agent from accumulating hidden complexity. A and B describe the same architecture but C makes the contract explicit. |
| 2. Sprint Model | 5 | 4 | 4 | **A (Conservative)** | A's three-verb model (create, assign, query) with NON-BLOCKING assignment and explicit rejection of sprint state normalization is the simplest design that works. B and C agree on the same vocabulary mapping table. A wins by explicitly refusing to model sprint states across trackers --- that decision alone prevents months of maintenance debt. |
| 3. Autonomous vs. Semi-Autonomous | 5 | 2 | 4 | **A (Conservative)** | A's 3-gate MVP is correct. B's 5-gate model with Gate 5 interactive toggle is the single most contentious proposal across all three approaches, and both A and C independently reject it. Gate 5 introduces a repeating prompt loop with no precedent in ceos-agents. A and C converge on the same trimmed gate set. A wins by additionally deferring Gate 2 (per-issue decomposition) from MVP, which is the right call --- decomposition already has its own gates in implement-feature. |
| 4. Capacity Planning | 4 | 3 | 5 | **C (Skeptical)** | C's model is the most disciplined: two units (story-points, hours), no team member modeling, no velocity prediction, no trend analysis. B's "issue count" third unit and velocity trend awareness are scope creep --- issue count is just "top N" which the unconstrained mode already handles, and trend analysis requires multi-sprint history that will not exist at launch. C's explicit rejections (privacy, accuracy, scope) are well-reasoned. |
| 5. Velocity Tracking | 5 | 3 | 5 | **A/C (Tie, adopt C)** | A and C both conclude velocity is derived, never stored. They agree on the 3-tier fallback. B proposes reading past sprint state files for velocity calibration --- a good idea that both A and C acknowledge but correctly defer to a follow-up release. C's explicit rejection of a velocity history file and retrospective data is the right architectural boundary. |
| 6. Issue Selection Algorithm | 4 | 4 | 5 | **C (Skeptical)** | All three describe the same two-phase algorithm (priority-engine ranks, sprint-planner fits). C wins by adding the strongest constraint: sprint-planner NEVER re-ranks. This prevents sonnet from second-guessing opus, which is an important model hierarchy principle. B's Stage 3 (human refinement via Gate 5) is rejected per Dimension 3. |
| 7. Tracker Operations | 5 | 3 | 4 | **A (Conservative)** | A's decision to implement only sprint_assign for MVP cuts the tracker integration surface by two-thirds (6 paths instead of 18). Sprint creation and querying are genuinely optional --- most teams pre-create sprints in their tracker. C's Constraint 4 (Redmine always uses Version, never Agile Plugin) is adopted as an additional simplification. B proposes all three operations in MVP, which is unnecessary scope. |
| 8. Config Contract | 5 | 3 | 4 | **A (Conservative)** | A's 7-key MVP is the right scope. The 5 deferred keys (Priority field, Include types, Exclude labels, Estimation field, Report path) all have sensible defaults or can be handled through existing config (Bug query, Feature query already filter by type). B and C propose 12 keys, which front-loads config documentation and testing for keys most users will not override. |
| 9. State Persistence | 5 | 3 | 4 | **A (Conservative)** | A's simplified schema removes redundant fields (goal, capacity_configured, velocity_target, effort_hours, title, decompose fields, skipped_issues, gates object, sprint_assignment sub-object) and reduces state update points from 8 to 5. B wants the full research schema. C wants the full schema minus tracking fields. A correctly identifies that most removed fields are either derivable from config, not consumed by any reader in MVP, or deferrable with decomposition gates. |
| 10. Failure Modes | 4 | 4 | 5 | **C (Skeptical)** | C catalogues 10 distinct failure modes vs. A's 6 and B's 8. The additional coverage (corrupt metrics file, all gates declined, --apply with no execution infrastructure) represents real edge cases that the spec must address. C's "let each child pipeline validate its own requirements" for failure mode 10 is architecturally sound --- sprint-plan should not pre-validate fix-ticket's config. |

### Overall Assessment

**Overall winner: Conservative Pragmatist (A), with targeted adoptions from Skeptical Architect (C).**

The Conservative approach wins 5 of 10 dimensions outright and shares the win on a 6th. The Skeptical approach wins 4 dimensions. The Innovative approach wins zero dimensions outright.

This is decisive: the Conservative approach delivers the highest value-to-complexity ratio. Its core insight --- that sprint planning's value is the capacity-constrained selection, not the tracker integration sophistication --- is correct. Every dimension where the Skeptical approach wins is one where it adds a constraint or rejection that further narrows scope, which aligns with the Conservative philosophy.

The Innovative approach's proposals (Gate 5 interactive toggle, velocity trend analysis, issue count capacity unit, sprint goal authoring, full 12-key config, full state schema) are all individually reasonable ideas that collectively represent 2-3x the implementation scope for perhaps 20% more value. The killer feature B advocates for (Gate 5 scope adjustment) is independently rejected by both A and C --- that is a strong signal.

**Adopted from each approach:**

- **From A (Conservative):** Architecture, sprint model, 3-gate MVP, 7-key config, simplified state schema, sprint_assign-only tracker operations, `--yolo` does NOT imply `--apply`
- **From B (Innovative):** Sprint naming pattern as a future config key (accepted by all three), `--dry-run` mode in MVP (also proposed by C), dependency awareness in selection algorithm
- **From C (Skeptical):** Stateless agent constraint, Redmine always Version, 10 failure modes, no velocity history file, child pipeline validates its own config, tracker tier announcement at Gate 1

---

## Synthesized Design (The Recommended Approach)

### 1. Architecture

One new agent (`sprint-planner`, sonnet, read-only) and one new skill (`sprint-plan`, `disable-model-invocation: true`).

The sprint-planner agent is **stateless**: it receives inputs (priority-engine output, Sprint Planning config, velocity source), produces a structured sprint plan table, and exits. All persistence is the skill's responsibility via state.json. All tracker writes are the skill's responsibility. The agent performs pure analytical work: capacity-constrained selection with dependency awareness.

The sprint-plan skill is the orchestrator. It owns: config parsing, velocity source determination, MCP pre-flight, agent dispatch (priority-engine via Task, then sprint-planner via Task), human gates, tracker assignment dispatch, state persistence, and execution launch.

Neither `/prioritize` nor `fix-bugs` are extended. `/prioritize` remains read-only analysis. `fix-bugs` remains immediate execution. Sprint planning bridges the gap between them as a distinct workflow.

**New file count:** 2 definition files + up to 7 test scenarios. **Modified file count:** 10 (per research inventory). **Version: v6.5.0 (MINOR).**

### 2. Sprint Model

Unified vocabulary with three abstract operations: `sprint_create`, `sprint_assign`, `sprint_query`. Per-tracker semantic mapping:

| Tracker | Native concept | Default field |
|---------|---------------|---------------|
| youtrack | Sprint | `Sprint` |
| jira | Sprint (Scrum boards only) | `Sprint` |
| linear | Cycle | `Cycle` |
| github | Milestone | `Milestone` |
| gitea | Milestone | `Milestone` |
| redmine | Version (always, never Agile Plugin) | `Version` |

**MVP implements only `sprint_assign`.** Sprint creation and querying are deferred. Most teams create sprints in their tracker UI. If the target sprint does not exist, warn and skip (NON-BLOCKING).

Sprint assignment is ALWAYS NON-BLOCKING. If all tiers fail for an issue, log a warning and continue. The sprint plan is valid and useful even without tracker assignment.

No sprint state normalization across trackers. No start/end date abstraction. No active/closed/future state mapping. The skill announces the tracker tier at Gate 1 so users know what "sprint" means for their tracker.

### 3. Autonomous vs. Semi-Autonomous

Semi-autonomous by default. Three human gates for MVP:

| Gate | When | `--yolo` | Purpose |
|------|------|----------|---------|
| Gate 1 | After sprint-planner output | Auto-approve | User reviews the proposed sprint and capacity assumptions |
| Gate 3 | Unmapped AC in any issue | **BLOCK** | Safety gate --- never auto-approved, even in `--yolo` |
| Gate 4 | Final "Start sprint?" | Auto-approve | Last chance before tracker writes and/or execution dispatch |

**Deferred from MVP:**
- Gate 2 (per-issue decomposition approval): Decomposition is already handled by implement-feature with its own gates. Sprint planning flags `decompose_recommended` in its output table but does not run inline decomposition. Users decompose via `/implement-feature {ID}` after the sprint is planned.
- Gate 5 (interactive scope adjustment toggle): No precedent in ceos-agents. Both A and C reject it. If the user rejects Gate 1, they re-run with `--capacity` or `--limit` flags.

**Mode: suggest** (default): After Gate 4, write sprint assignments to tracker (metadata only). Display suggested execution commands.

**Mode: apply** (config or `--apply` flag): After Gate 4, write sprint assignments AND dispatch fix-ticket/implement-feature per issue.

**`--yolo` does NOT imply `--apply`.** Explicit `--yolo --apply` required for fully automated CI execution. This prevents accidental bulk execution.

**`--dry-run`:** Runs full analysis, displays Gate 4 plan, then exits. No tracker writes, no state file, no execution. Trust-building mode for first-time users and sprint planning meetings.

### 4. Capacity Planning

Simple numeric capacity with unit declaration. No team member modeling. No individual velocity. No role-based allocation.

Two capacity units: `story-points` (default) and `hours`.

```
effective_capacity = min(Team capacity, Velocity target)  -- when both set
effective_capacity = Team capacity OR Velocity target     -- when one set
effective_capacity = null (unconstrained, top N)          -- when neither set
```

Effort-to-unit mappings (fixed):
```
EFFORT_TO_POINTS = {1: 1, 2: 2, 3: 3, 4: 5, 5: 8}     (Fibonacci-adjacent)
EFFORT_TO_HOURS  = {1: 0.5, 2: 1.0, 3: 2.0, 4: 4.0, 5: 8.0}
```

Triage complexity takes precedence over priority-engine effort scores when available:
```
COMPLEXITY_TO_POINTS = {"XS": 1, "S": 2, "M": 3, "L": 5}
COMPLEXITY_TO_HOURS  = {"XS": 2.0, "S": 4.0, "M": 8.0, "L": 16.0}
```

Three-tier velocity fallback:
- **Tier 1 (historical):** Read `./reports/metrics.md` for avg_time_to_fix and success_rate.
- **Tier 2 (heuristic):** Use effort mappings with configured capacity. 20% overflow buffer per issue.
- **Tier 3 (manual/unconstrained):** Prompt user for hours estimate. If skipped, use unconstrained top-N.

Cold-start annotation shown at every gate for Tiers 2 and 3.

### 5. Velocity Tracking

Velocity is DERIVED, never stored as a first-class entity. There is no velocity database, no velocity history file, no per-sprint completion log.

Data sources in priority order:
1. `./reports/metrics.md` (from `/ceos-agents:metrics`) --- trailing averages
2. Sprint Planning config keys (Team capacity, Velocity target)
3. User manual input (Tier 3 prompt)

The feedback loop: Sprint N is planned and executed. `/ceos-agents:metrics` captures what happened. Sprint N+1 planning reads the metrics report. No new storage mechanism.

Reading past sprint state files for velocity calibration is deferred to a follow-up MINOR release (v6.6.0 or later). The state files will exist and support this, but the sprint-planner does not read them in v6.5.0.

### 6. Issue Selection Algorithm

Two-phase, two-agent, no re-ranking.

**Phase 1 --- Priority-engine (opus, existing, unchanged):** Rank all fetched issues into P0/P1/P2 tiers with Impact, Risk, Effort, Score, Rationale. Output: ranked tables + Suggested batch + Dependencies graph.

**Phase 2 --- Sprint-planner (sonnet, new):** Walk the ranked list top-to-bottom. For each issue:
1. Resolve effort size (triage complexity > priority-engine effort score > default 3).
2. Check dependencies: if issue depends on another not in plan, attempt to add the dependency (if fits). If dependency does not fit, annotate the dependent as "at-risk: depends on {X}".
3. Include if `accumulated_cost + issue_cost <= effective_capacity + (issue_cost * 0.2)`.
4. Flag `decompose_recommended: true` when effort_score >= 4 OR Risk = 5.
5. Remaining issues go into Overflow section.

Sprint-planner NEVER re-ranks. Priority-engine's sort order is authoritative. Sprint-planner is a capacity filter, not a strategist.

Priority-engine is invoked once and its scores are cached. It is never re-run within a single sprint-plan invocation.

### 7. Tracker Operations

MVP scope: **sprint_assign only**, with three-tier fallback per tracker.

| Tracker | Tier 1 (MCP) | Tier 2 (Bash+REST) | Tier 3 |
|---------|-------------|-------------------|--------|
| youtrack | `update_issue(Sprint: name)` | curl REST | skip+warn |
| jira | `add_issues_to_sprint(sprintId, issues)` | curl REST | skip+warn |
| linear | `update_issue(cycleId: uuid)` | GraphQL mutation | skip+warn |
| github | `update_issue(milestone: number)` | curl REST | skip+warn |
| gitea | Unverified --- skip to Tier 2 | curl REST | skip+warn |
| redmine | `update_issue(fixed_version_id: id)` | curl REST | skip+warn |

Name-to-ID resolution required for all trackers except YouTrack. Resolution is done once before the assignment loop and the ID is cached.

Pre-conditions:
- **Jira:** Check `board.type == "scrum"`. If Kanban, skip all sprint operations, warn user, continue with plan-only output.
- **Redmine:** Always use Version. No Agile Plugin auto-detection.

Environment variables for Bash fallbacks: per the research dispatch table. If missing when needed, skip to Tier 3 immediately. Never prompt for tokens mid-pipeline.

**sprint_create deferred.** The skill assigns to existing sprints/milestones. If the target does not exist, warn and skip.

**sprint_query deferred.** Useful for future `/status` integration but not needed for MVP planning flow.

### 8. Config Contract

One optional section (`### Sprint Planning`) with 7 keys for MVP. Section absence = sprint planning disabled.

```markdown
### Sprint Planning

| Key | Value |
|-----|-------|
| Sprint duration | 2 weeks |
| Capacity unit | story-points |
| Team capacity | 40 |
| Velocity target | 35 |
| Sprint field | Sprint |
| Mode | suggest |
| Max issues | 20 |
```

| Key | Default | Validation |
|-----|---------|------------|
| Sprint duration | 2 weeks | `1 week`, `2 weeks`, `3 weeks`, `4 weeks` |
| Capacity unit | story-points | `story-points` or `hours` |
| Team capacity | (none) | Positive integer; 0 treated as unconfigured |
| Velocity target | (none) | Positive integer; must be <= Team capacity if both set |
| Sprint field | (tracker-dependent) | String --- tracker field name |
| Mode | suggest | `suggest` or `apply` |
| Max issues | 20 | 1--50 (hard ceiling from priority-engine) |

**Deferred keys (addable as PATCH releases since all optional):**
- Priority field (default: Priority --- rarely overridden)
- Include types (use existing Bug query + Feature query)
- Exclude labels (use tracker query filters)
- Estimation field (use triage complexity as proxy)
- Report path (stdout for MVP)
- Sprint naming pattern (default: `Sprint {YYYY-WW}`)

### 9. State Persistence

Path: `.ceos-agents/sprint-{timestamp}/state.json` using existing atomic write protocol.

RUN-ID format: `sprint-{YYYYMMDD-HHmmss}`.

Simplified schema (removes fields not consumed by any MVP reader):

```json
{
  "schema_version": "1.0",
  "run_id": "sprint-20260413-143000",
  "parent_run_id": null,
  "mode": "sprint-planning",
  "pipeline": "sprint-plan",
  "status": "running",
  "started_at": "ISO-8601",
  "updated_at": "ISO-8601",
  "config": {
    "profile": null,
    "flags": ["--apply"],
    "retry_limits": {
      "fixer_iterations": 5,
      "test_attempts": 3,
      "build_retries": 3
    }
  },
  "sprint": {
    "name": "Sprint 2026-W16",
    "duration": "2 weeks",
    "effective_capacity": 35,
    "velocity_source": "historical",
    "issues": [
      {
        "issue_id": "PROJ-42",
        "tier": "P0",
        "effort_points": 2,
        "type": "bug",
        "sprint_assigned": false,
        "child_run_id": null,
        "status": "pending"
      }
    ],
    "completed_issues": 0,
    "blocked_issues": 0
  }
}
```

Removed from research schema: `sprint.goal` (always null in MVP), `sprint.capacity_configured` and `sprint.velocity_target` (redundant with config), `sprint.capacity_unit` (redundant with config), `sprint.approved_at` and `sprint.started_at` (not consumed), `sprint.issues[].title` (fetch from tracker on demand), `sprint.issues[].priority_score` (sort order is implicit in array position), `sprint.issues[].effort_score` and `sprint.issues[].effort_hours` (derivable from effort_points + config unit), `sprint.issues[].decompose_recommended` and `sprint.issues[].subtask_count` and `sprint.issues[].post_decomp_effort` (deferred with Gate 2), `sprint.skipped_issues` (either completed or blocked), `sprint.total_effort_pre_decomp` and `sprint.total_effort_post_decomp` (derivable from issues array), `gates` object (skill tracks gate state in-memory), `sprint_assignment` sub-object (flattened to per-issue `sprint_assigned` boolean), `block` (use top-level status).

**5 state update points:**
1. After config validation --- write initial state with `status: "running"`, all issues `pending`
2. After Gate 1 confirmed --- write issue list with effort scores
3. After Gate 4 confirmed --- mark status as `approved`
4. Per child pipeline start/complete/block --- update `child_run_id`, `status`, counters
5. On pipeline completion --- set top-level `status: "completed"`

### 10. Failure Modes

| # | Failure | Behavior | Rationale |
|---|---------|----------|-----------|
| 1 | MCP pre-flight fails | **BLOCK** | No tracker access = no issues to plan |
| 2 | Sprint Planning config absent | **BLOCK** | Feature disabled by design |
| 3 | Priority-engine fails | **BLOCK** | No ranked input = nothing to plan |
| 4 | Sprint-planner fails | **BLOCK** | No capacity analysis = no plan |
| 5 | Capacity unknown (Tier 3) | Prompt user or unconstrained top-N | Plan still valuable without capacity math |
| 6 | Metrics file corrupt | Fall back to Tier 2 heuristic | Warn and continue |
| 7 | Sprint assignment fails (per issue) | **NON-BLOCKING** | Log warning, record `sprint_assigned: false`, continue |
| 8 | Target sprint does not exist in tracker | **NON-BLOCKING** | Warn and skip assignment (no creation in MVP) |
| 9 | Jira project uses Kanban board | Skip sprint operations, plan still generated | Board type pre-check; plan is the product |
| 10 | GitHub/Gitea milestone has no start date | Expected, not a failure | Create with `due_on` only; note in plan output |
| 11 | `--apply` with incomplete Build & Test config | Let child pipeline validate | Sprint-plan's job is planning; execution config is execution's concern |
| 12 | User rejects Gate 4 | Clean exit | No tracker writes, no execution, no state persisted |
| 13 | `--yolo` with `Mode: suggest` | Suggest-only with auto-approved gates | `--yolo` does NOT imply `--apply`; need `--yolo --apply` for full automation |

---

## Scope Boundary (Explicit NOT-IN-SCOPE)

The following are explicitly excluded from sprint planning. Any future proposal adding these MUST be rejected or treated as a separate feature:

1. **Sprint tracking** --- burndown charts, sprint health, completion percentages. The tracker owns sprint lifecycle.
2. **Sprint retrospectives** --- velocity trends, improvement suggestions, team performance analysis. PM tool territory.
3. **Team member modeling** --- individual capacity, skill allocation, availability tracking. Privacy-invasive and impossible to keep accurate.
4. **AI velocity prediction** --- confident-sounding numbers from insufficient data are worse than honest heuristics with uncertainty warnings.
5. **AI sprint goal generation** --- strategic alignment statements require organizational context an LLM cannot access from issue titles.
6. **Sprint state normalization** --- mapping active/closed/future states across trackers. Each tracker's model is different and we do not need to unify them.
7. **Burndown data storage** --- no per-day progress tracking, no remaining-work calculations.
8. **Interactive scope adjustment** (Gate 5) --- deferred, not rejected. May appear in a follow-up if there is user demand.
9. **Inline decomposition** (Gate 2) --- deferred. Use `/implement-feature` which already handles this.
10. **Redmine Agile Plugin detection** --- unreliable heuristic. Version is universally available.

---

## Areas of Universal Agreement

All three approaches independently converged on these points. These represent the highest-confidence design decisions:

1. **One new agent (sprint-planner, sonnet, read-only) + one new skill (sprint-plan).** No alternatives considered by any approach.
2. **Sprint assignment is ALWAYS NON-BLOCKING.** Unanimous. The plan is the product; tracker metadata is a convenience.
3. **Priority-engine is reused unchanged.** Sprint-planner consumes its output; no modifications to the existing agent.
4. **Sprint-planner NEVER re-ranks.** Priority-engine's opus-powered ranking is authoritative.
5. **Two-phase algorithm:** priority-engine ranks, sprint-planner capacity-fits. Clean separation.
6. **`--yolo` does NOT imply `--apply`.** Explicit `--yolo --apply` required for fully automated execution.
7. **Gate 3 (unmapped AC) blocks even in `--yolo` mode.** Consistent with implement-feature behavior.
8. **Version: v6.5.0 (MINOR).** Optional section, no required keys, one agent, one skill.
9. **Velocity is derived, not stored.** No velocity database, no new persistent storage for velocity.
10. **`--dry-run` mode in MVP.** Trust-building path for first-time users.
11. **Jira Kanban board detection.** Pre-check board type; skip sprint operations for Kanban.
12. **Cold-start is a first-class concern**, not an afterthought. Three-tier fallback with honest annotations.

---

## Deferred to Future Versions

| Feature | Proposed By | Earliest Version | Rationale for Deferral |
|---------|------------|-----------------|----------------------|
| Gate 5: Interactive scope adjustment | B | v6.5.1 or v6.6.0 | New interaction pattern; re-run with flags is sufficient for MVP |
| Gate 2: Inline decomposition | B, C | v6.5.1 or v6.6.0 | implement-feature already handles decomposition with its own gates |
| sprint_create tracker operation | A, B, C | v6.5.1 | Most teams pre-create sprints; adds 6 more tracker code paths |
| sprint_query tracker operation | A, B, C | v6.6.0 | Useful for `/status` integration but not needed for planning |
| Sprint naming pattern config key | A, B, C | v6.5.1 | Default `Sprint {YYYY-WW}` is sufficient; low-cost addition |
| Sprint goal (Gate 0.5) | B | v6.6.0+ | Per-sprint, not per-project; AI-generated goals rejected |
| Sprint-level dashboard/metrics | B | v6.6.0 | Architecture supports it; dashboard/metrics code does not change in MVP |
| Velocity from past sprint state files | B, C | v6.6.0 | Good idea once there are past sprint runs to read from |
| Velocity trend analysis | B | Indefinite | Requires multi-sprint history; trackers already do this natively |
| Parallel execution config key | B | Not needed | Always on (consistent with fix-bugs); config toggle adds no value |
| 5 additional config keys (Priority field, Include types, Exclude labels, Estimation field, Report path) | B, C | v6.5.x patches | All optional with sensible defaults; addable as PATCH releases |
| Resume capability for sprint runs | B | v6.6.0 | Requires extending /resume-ticket; state files support it |

---

## Key Implementation Risks

### Risk 1: Name-to-ID resolution fragility across trackers
Every tracker except YouTrack requires resolving a sprint/milestone/cycle name to a numeric or UUID identifier before assignment. This resolution depends on MCP list operations or REST queries that may fail, return paginated results, or have rate limits. The spec must define: (a) exact resolution call per tracker, (b) behavior when multiple sprints match the name, (c) behavior when no sprint matches (skip, since creation is deferred).

### Risk 2: Priority-engine output format coupling
Sprint-planner consumes 6 specific fields from priority-engine's markdown output (Impact, Risk, Effort, Score, Rationale, Dependencies). Any change to priority-engine's output format breaks sprint-planner silently. The spec must define: (a) the exact parsing contract between the two agents, (b) a validation step in sprint-planner that detects missing fields before proceeding.

### Risk 3: Effort-to-points mapping mismatch with real project data
The fixed `EFFORT_TO_POINTS` mapping (1,2,3,5,8) and `COMPLEXITY_TO_POINTS` mapping (XS=1, S=2, M=3, L=5) are assumptions. Real projects may use different scales. If a project's "Story points" field uses values like 0.5, 13, or 20, the mapping will produce incorrect capacity calculations. The deferred `Estimation field` config key is the proper fix, but MVP users with non-standard scales will get inaccurate capacity fits. The spec must document this limitation and recommend the Estimation field key for projects with custom point scales.

### Risk 4: MCP tool name instability
Several tracker MCP packages have unverified tool names (Jira creation, Linear creation, Gitea assignment). The research uses "likely" and "unverified" qualifiers for multiple operations. Since MVP only implements sprint_assign, the blast radius is contained, but even for assignment, Jira has two possible tool name prefixes (`mcp__jira__*` vs `mcp__atlassian__*`). The spec must define: attempt both prefixes before Bash fallback, per the research recommendation.

### Risk 5: `--apply` execution ordering with dependencies
When `Mode: apply` dispatches fix-ticket/implement-feature per issue, dependent issues must be serialized (A completes before B starts). The spec must define: (a) how the skill detects dependency completion (poll child state file? block on Task tool return?), (b) what happens when a dependency-predecessor pipeline blocks (does the dependent issue also block, or is it dispatched anyway?), (c) maximum wall-clock time before the sprint-plan skill gives up on a child pipeline.
