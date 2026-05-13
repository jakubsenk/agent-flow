# Approach C: Skeptical Architect -- "Graceful Degradation Sprint Model"

## Preamble: Why Am I Even Here?

The roadmap explicitly says **NOT PLANNED** for sprint planning/tracking, with the rationale: "ceos-agents is not a PM tool. Sprint tracking is delegated to issue trackers." That rationale is correct. Before we build anything, the burden of proof is on the proposal to demonstrate that what we are building is NOT sprint tracking (a PM tool concern) but rather *sprint-scoped batch selection* (an automation pipeline concern). The distinction matters: if we are just picking which issues to fix next and optionally tagging them in the tracker, that is a natural extension of `/prioritize`. If we are managing sprint lifecycles, velocity charts, and burndown tracking, we have wandered into territory where every tracker already has native tooling that will always be better than ours.

My approach accepts the former and firmly rejects the latter.

## Design Proposal (all 10 dimensions)

### 1. Architecture: New Agent + New Skill, or Extend Existing Components?

**Decision: One new agent (sprint-planner, sonnet), one new skill (sprint-plan). Do NOT extend priority-engine or /prioritize.**

Rationale:
- The sprint-planner agent has a distinct concern: *capacity-constrained selection*. The priority-engine ranks issues by impact/risk/effort. The sprint-planner takes that ranked output and applies a capacity ceiling. These are cleanly separable responsibilities.
- Extending `/prioritize` would violate single-responsibility: `/prioritize` is read-only analysis; `/sprint-plan` writes to trackers (conditionally) and dispatches execution pipelines. Mixing them creates a skill that is sometimes read-only and sometimes destructive.
- The sprint-planner agent is read-only (consistent with priority-engine, acceptance-gate). All tracker writes live in the skill, not the agent. This preserves the architecture's clean separation.

However, I would impose a hard constraint the research does not emphasize enough: **the sprint-planner agent must be stateless**. It receives inputs, produces a structured plan table, and exits. It does NOT hold velocity state, sprint history, or anything persistent. All persistence is the skill's job via state.json.

**What I would NOT build:** A separate `sprint-tracker` agent or any agent that monitors sprint progress. Sprint tracking is the tracker's job. Our state.json records what we dispatched and what completed, but we are NOT building burndown charts or sprint health dashboards. That is scope creep into PM tooling.

### 2. Sprint Model: Unified Abstraction Across Trackers, or Tracker-Specific?

**Decision: Unified vocabulary with a per-tracker semantic mapping layer. The abstraction has exactly three operations: create, assign, query. All three are NON-BLOCKING on failure.**

The unified model:

| Concept | Internal name | YouTrack | Jira | Linear | GitHub | Gitea | Redmine |
|---------|--------------|----------|------|--------|--------|-------|---------|
| Sprint container | `sprint` | Sprint (Agile Board) | Sprint (Scrum board) | Cycle | Milestone | Milestone | Version |
| Sprint field | `sprint_field` | Custom field (default: `Sprint`) | Sprint ID | Cycle UUID | Milestone number | Milestone ID | fixed_version_id |
| Sprint query | `sprint_query` | Query lang | JQL | GraphQL/MCP | List issues filter | List issues filter | List issues filter |

**Critical design constraint: The abstraction MUST degrade gracefully per tracker tier.**

I define three capability tiers for the unified model:

| Tier | Capabilities | Trackers |
|------|-------------|----------|
| Full | Create sprint, assign issues, query sprint, start/end dates | YouTrack, Jira, Linear |
| Partial | Create container, assign issues, query; NO start date, limited metadata | GitHub, Gitea |
| Fallback | Create container, assign issues, query; Version model (not Agile Sprint) | Redmine |

The skill MUST announce the tier at Gate 1:
```
Tracker: github (Milestone mode -- no start dates, no velocity native to tracker)
```

This is non-negotiable. Users must know what "sprint" means for their tracker. A milestone is NOT a sprint. Pretending it is creates false expectations.

**What I explicitly reject:** Any design that requires all 6 trackers to have identical semantics. GitHub milestones do not have start dates. Linear cycles are team-scoped, not project-scoped. Redmine has two competing models. The abstraction must tolerate these differences, not paper over them.

### 3. Autonomous vs. Semi-Autonomous: How Do the Two Modes Differ?

**Decision: Semi-autonomous by default, with `--yolo` for CI automation. Five human gates as specified in the research, with one modification.**

The modification: **Gate 5 (scope adjustment interactive toggle) is DEFERRED from MVP.**

Why: Gate 5 introduces a repeating interactive prompt loop -- a pattern that exists nowhere else in ceos-agents. Every other gate is a single Y/n decision. The toggle loop requires cache management (re-running sprint-planner without re-running priority-engine), input parsing (issue IDs), and state mutation during an interactive session. This is a new interaction paradigm with high implementation risk and unclear user value in v1. Users who want to adjust scope can simply re-run with `--capacity` or `--limit` flags.

MVP gates (4 gates, not 5):

| Gate | When | --yolo | Purpose |
|------|------|--------|---------|
| Gate 1 | After capacity fit | Auto-approve | "Is this the right amount of work?" |
| Gate 2 | Per decomposable issue | Auto-approve | "Approve decomposition plan?" |
| Gate 3 | Unmapped AC in decomposition | BLOCK | "Missing coverage -- continue?" |
| Gate 4 | Final sprint plan | Auto-approve | "Commit to this sprint?" |

**`--dry-run` exits after Gate 4 display.** No tracker writes, no execution dispatch, no state file. This is the "show me the plan" mode.

**`--yolo` behavior:** Auto-approves Gates 1, 2, 4. BLOCKS on Gate 3 (unmapped AC). This is consistent with implement-feature's behavior on unmapped AC -- high stakes, never auto-approve.

**Mode: suggest vs. Mode: apply:**
- `suggest` (default): After Gate 4, write sprint assignments to tracker, display summary with suggested commands. No execution dispatch.
- `apply` (config or `--apply` flag): After Gate 4, write sprint assignments AND dispatch fix-ticket/implement-feature per issue.
- `--yolo` does NOT imply `--apply`. You need `--yolo --apply` for fully automated CI execution. This prevents accidental bulk execution from a casual `--yolo` invocation.

### 4. Capacity Planning: How Is Team Capacity Modeled?

**Decision: Simple numeric capacity with unit declaration. No team member modeling, no individual velocity, no role-based allocation.**

Config keys (all optional):
```
| Team capacity | 40 |
| Capacity unit | story-points |
| Velocity target | 35 |
```

`effective_capacity = min(Team capacity, Velocity target)` when both set. Either alone when one set. Null (unconstrained) when neither set.

**What I firmly reject:** Any design that models individual team members, their availability, skill sets, or per-person velocity. That is:
1. Privacy-invasive (who is slow? who is fast?)
2. Impossible to keep accurate (PTO, meetings, context switching)
3. Already solved by every tracker's native sprint planning board
4. Far beyond the scope of "which issues should we fix next"

ceos-agents models *team throughput as a single number*. The number comes from config or from historical metrics. Period.

**Capacity units:** Two supported: `story-points` (default) and `hours`. The effort-to-unit mapping is fixed:

```
EFFORT_TO_POINTS = {1: 1, 2: 2, 3: 3, 4: 5, 5: 8}   (Fibonacci-adjacent)
EFFORT_TO_HOURS  = {1: 0.5, 2: 1.0, 3: 2.0, 4: 4.0, 5: 8.0}
```

When triage-analyst complexity data exists (`[ceos-agents] Triage completed. ... Complexity: {X}`), it takes precedence over priority-engine effort scores because triage complexity is validated against actual code analysis.

### 5. Velocity Tracking: Where Does Velocity Data Live?

**Decision: Velocity is DERIVED, never stored as a first-class entity. There is no velocity database.**

Three-tier fallback:

**Tier 1 -- Historical (metrics report exists):**
Read `./reports/metrics.md` (or Metrics -> Output path). Extract `Avg time to fix` and `Issues fixed` success rate. Calculate `max_issues = floor(capacity_hours / avg_time * success_rate)`. This is a trailing average, not a sprint-by-sprint history.

**Tier 2 -- Heuristic (capacity configured, no metrics):**
Use the `EFFORT_TO_*` mappings. Walk the ranked list, accumulate costs, stop at capacity ceiling with a 20% overflow buffer per issue (to handle rounding in effort estimates).

**Tier 3 -- Manual/Unconstrained (nothing configured):**
Prompt user for hours estimate. If skipped: take top N issues from priority-engine's suggested batch (capped at `Max issues`, default 20). Annotate every gate with:
```
Warning: No capacity data. Velocity estimate based on heuristic. Run /ceos-agents:metrics after this sprint to calibrate.
```

**What I explicitly reject:** A velocity history file, a per-sprint completion log, or any form of sprint retrospective data. That is sprint *tracking*, which the roadmap explicitly excludes and which trackers do natively. If someone wants velocity trends, they look at their Jira/Linear/YouTrack dashboard.

**What I would accept in a future MINOR release:** Reading sprint-state.json files from `.ceos-agents/sprint-*/` to compute a trailing velocity from past sprint-plan runs. But this is NOT MVP. The state files exist for pipeline coordination, not for analytics.

### 6. Issue Selection Algorithm: Pure Priority-Engine? Capacity-Constrained?

**Decision: Priority-engine provides the ranked list. Sprint-planner applies capacity constraints. Two-phase, no re-ranking.**

Algorithm:
1. Priority-engine ranks all fetched issues into P0/P1/P2 tiers with scores.
2. Sprint-planner receives the ranked list and walks it top-to-bottom.
3. For each issue: compute cost from effort score (or triage complexity if available).
4. Include if `accumulated_cost + issue_cost <= effective_capacity + (issue_cost * 0.2)`.
5. If issue has dependency on an issue NOT in the plan: attempt to add the dependency (if fits); if not, annotate the dependent issue as "at-risk: depends on {X}".
6. Issues that exceed capacity go into an "Overflow" section.

**Sprint-planner NEVER re-ranks.** The priority-engine's sort order is authoritative. Sprint-planner only applies a capacity ceiling and dependency resolution. This prevents the sprint-planner from second-guessing the opus-powered priority analysis with sonnet-level reasoning.

**Decomposition interaction:** If an issue has `effort_score >= 4` OR `Risk = 5` in priority-engine output, sprint-planner flags `decompose_recommended: true`. The skill presents Gate 2 for each such issue. Post-decomposition, the sprint-planner is re-invoked with updated effort totals (but priority-engine is NOT re-run -- scores are cached).

### 7. Tracker Operations: What Operations Per Tracker?

**Decision: Three operations (create, assign, query), all with tiered fallback (MCP -> Bash+REST -> skip+warn). Assignment failure is ALWAYS NON-BLOCKING.**

This is the most dangerous dimension for cross-tracker breakage. My constraints:

**Constraint 1: sprint_create is OPTIONAL.** If the sprint/milestone/cycle already exists, we skip creation. The skill should first attempt to find an existing sprint matching the naming pattern before creating one. This handles the common case where a team lead already created the sprint in their tracker's UI.

**Constraint 2: sprint_assign failure NEVER blocks the pipeline.** If we cannot tag an issue with a sprint field, we log a warning and continue. The sprint plan still exists in our state.json and in the output report. The tracker metadata is a convenience, not a dependency.

**Constraint 3: Every Bash fallback requires an environment variable.** If the variable is not set, we skip to Tier 3 (warn) immediately. We do NOT prompt the user for tokens mid-pipeline.

**Constraint 4: Redmine always uses Version, never Agile Plugin.** The Agile Plugin detection heuristic (`GET .../agile_sprints.json` -> 404) is unreliable across Redmine versions and plugin configurations. Version is universally available in Redmine core. If users want Agile Sprint integration, they can use Agent Overrides to customize the sprint-planner. Do NOT build auto-detection for a third-party Redmine plugin.

Per-tracker operation matrix:

| Tracker | Create | Assign | Query | Notes |
|---------|--------|--------|-------|-------|
| youtrack | REST (MCP unverified) | MCP preferred | MCP query | Needs agileID config |
| jira | REST (MCP unconfirmed) | MCP confirmed | JQL via MCP | Scrum boards only |
| linear | GraphQL (MCP unverified) | MCP confirmed | MCP list | Needs team UUID resolution |
| github | MCP confirmed | MCP confirmed | MCP list | Milestones only, no start date |
| gitea | MCP confirmed | REST (MCP unverified) | MCP list | Milestones only, no start date |
| redmine | MCP likely / REST | MCP likely / REST | MCP likely / REST | Version model only |

**Jira Kanban board guard:** Before any sprint operation on Jira, verify `board.type == "scrum"`. Kanban boards have no sprint concept. If Kanban: skip all sprint operations, warn user, continue with suggest-only mode (plan is displayed but not assigned to any tracker construct).

### 8. Config Contract: What Config Section(s)?

**Decision: One optional section (`### Sprint Planning`) with 12 keys, all optional. Section absence = feature disabled.**

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

**Key defaults and validation:**

| Key | Default | Validation |
|-----|---------|-----------|
| Sprint duration | 2 weeks | Must be `1 week`, `2 weeks`, `3 weeks`, or `4 weeks` |
| Capacity unit | story-points | Must be `story-points` or `hours` |
| Team capacity | (none) | Positive integer |
| Velocity target | (none) | Positive integer, must be <= Team capacity if both set |
| Sprint field | (tracker-dependent) | YouTrack: `Sprint`, Jira: `Sprint`, Linear: `Cycle`, GitHub/Gitea: `Milestone`, Redmine: `Version` |
| Priority field | Priority | String -- tracker field name for priority |
| Mode | suggest | Must be `suggest` or `apply` |
| Max issues | 20 | 1-50 (hard ceiling from priority-engine) |
| Include types | bug, feature | Comma-separated list |
| Exclude labels | (none) | Comma-separated list |
| Estimation field | (none) | Tracker field name for story points/estimates |
| Report path | (none) | File path for markdown report output |

**What I reject in config:**
- No `Sprint naming pattern` key in MVP. The default pattern `Sprint {YYYY-WW}` is sufficient. A naming pattern key adds config complexity for marginal value. Defer to a follow-up if users request it.
- No `Sprint goal` key. Sprint goals are per-sprint, not per-project config. If we add goal authoring, it belongs in the interactive flow (Gate 0.5), not in config.
- No `Parallel execution` key. Parallel dispatch for same-tier, dependency-free issues is always enabled. A config toggle adds complexity without clear user benefit.

**Version: v6.5.0 (MINOR).** One optional section, zero new required keys, one new agent, one new skill. Identical precedent to Browser Verification (v5.1.0) and Local Deployment (v5.3.0).

### 9. State Persistence: Sprint State Where?

**Decision: `.ceos-agents/sprint-{timestamp}/state.json` with the schema from the research, minus sprint tracking fields.**

RUN-ID format: `sprint-{YYYYMMDD-HHmmss}` (e.g., `sprint-20260413-143000`).

The state schema tracks:
- Sprint metadata (name, duration, capacity, velocity source)
- Issue list with effort scores, decomposition flags, assignment status
- Gate confirmations
- Child run IDs (links to per-issue `.ceos-agents/{ISSUE-ID}/state.json`)
- Assignment results (how many succeeded/failed at tracker write)

**What the state does NOT track:**
- Sprint completion percentage (that is sprint tracking)
- Velocity actual vs. planned (that is sprint tracking)
- Sprint burndown data (that is sprint tracking)
- Per-member allocation (that is resource management)

The state file serves ONE purpose: pipeline coordination. It tells `/status` what was planned and what was dispatched. It tells `/resume-ticket` (if extended) which issues in a sprint run are pending. It does NOT serve as a sprint analytics database.

**State update points (8 as specified in research):** Initial write after config validation, updates after each gate confirmation, per-issue assignment results, child pipeline linkage, and final completion status. All use the atomic write protocol (write to `.json.tmp`, rename) from `state/schema.md`.

### 10. Failure Modes: What When Tracker Doesn't Support Sprints? Capacity Unknown?

**Failure mode 1: Tracker has no sprint concept at all.**
Not possible with our 6 trackers -- all have at least milestones/versions. But if a custom tracker type is configured: skip all tracker operations, run in suggest-only mode, display plan as a report only.

**Failure mode 2: Sprint creation fails.**
NON-BLOCKING. Log warning, continue to assignment (try to assign to an existing sprint with matching name). If no existing sprint found either: skip assignment, display plan report, note that manual tracker setup is needed.

**Failure mode 3: Sprint assignment fails for some issues.**
NON-BLOCKING per-issue. Log per-issue warnings. Continue with remaining issues. Final summary shows `{N} assigned, {M} failed`. State records per-issue `sprint_assigned: true/false`.

**Failure mode 4: Capacity unknown (Tier 3 velocity).**
Prompt user for hours estimate (unless `--yolo`, in which case use unconstrained mode with top N issues). Always annotate with cold-start warning. This is functional but inaccurate -- exactly what you would expect with no data.

**Failure mode 5: Priority-engine fails.**
BLOCKING. Without ranked input, the sprint-planner has nothing to work with. Display error and stop. This is consistent with `/prioritize` behavior.

**Failure mode 6: Sprint-planner fails.**
BLOCKING. Without capacity analysis, there is no plan to present at Gate 1. Display error and stop.

**Failure mode 7: MCP pre-flight fails.**
BLOCKING. Without tracker access, we cannot fetch issues. No fallback -- same as every other pipeline.

**Failure mode 8: Jira project uses Kanban board.**
NON-BLOCKING for planning, BLOCKING for sprint assignment. The plan is still generated (capacity-fit analysis works regardless of board type). Sprint assignment is skipped entirely with a clear message: "Jira project uses Kanban board -- sprint assignment not available. Issues listed in plan report."

**Failure mode 9: GitHub/Gitea milestone has no start date.**
Expected behavior, not a failure. Milestone is created with `due_on` only. The plan report notes: "Milestone mode -- start date not supported by tracker."

**Failure mode 10: `--apply` with no execution infrastructure.**
If `Build & Test` section is missing or incomplete, `fix-ticket`/`implement-feature` will fail at their own config validation. Sprint-plan should NOT pre-validate the entire pipeline config. Let each child pipeline validate its own requirements. Sprint-plan's job is planning; execution config is the execution pipeline's concern.

---

## Critique of Conservative Pragmatist Approach

A "minimum viable" approach that strips sprint planning down to "just run /prioritize with a --sprint flag" fails on several fronts:

**Problem 1: It conflates two distinct concerns.** Prioritization and capacity-constrained selection are different operations. `/prioritize` answers "what matters most?" Sprint planning answers "what fits in the next time window given our throughput?" Bolting capacity logic onto `/prioritize` muddies both the command's API and its mental model.

**Problem 2: No tracker integration means no value over manual work.** If the "conservative" approach skips sprint creation and assignment, users get a ranked list they could already get from `/prioritize`. The delta value of sprint planning is precisely the tracker integration -- writing the sprint/milestone and assigning issues. Without it, you have built a slightly fancier prioritization report.

**Problem 3: No state persistence means no `/status` integration.** If there is no sprint state file, `/status` cannot show "Sprint 2026-W16: 3/7 issues completed." Users have no visibility into sprint progress through ceos-agents. They must switch to their tracker's native UI, which defeats the purpose of the automation.

**Problem 4: No execution dispatch means a broken workflow.** If the plan stops at "here are your issues" without offering to execute them, users must manually invoke `/fix-ticket` for each issue. With 7 issues in a sprint, that is 7 separate command invocations. The conservative approach saves the user zero time compared to just reading the `/prioritize` output and running fix-ticket manually.

**Problem 5: Insufficient abstraction layer.** A thin approach likely hardcodes for one or two trackers and hand-waves the rest. "Works for Jira, TODO for GitHub" is how you ship a feature that is permanently broken for 4 out of 6 trackers.

The conservative approach is seductive because it is low-risk, but it delivers correspondingly low value. A feature that does not meaningfully improve the workflow over existing commands should not be built at all.

---

## Critique of Innovative Integrator Approach

An ambitious AI-assisted approach that adds sprint goal generation, team member modeling, velocity prediction, sprint retrospectives, or burndown tracking fails catastrophically:

**Problem 1: Tracker semantic divergence kills sophisticated models.** An AI-generated sprint goal is useless if the tracker has no field for it (GitHub milestones have `description`, but YouTrack Sprints have `goal` as a separate field, and Linear Cycles have no goal field at all). Every "smart" feature must be implemented 6 different ways or not at all.

**Problem 2: Team member modeling is a privacy and accuracy minefield.** Modeling individual developer velocity requires knowing who works on what, how fast they are, and their availability. This data is sensitive, changes constantly, and is already managed by tracker-native sprint boards. ceos-agents has no business storing developer performance profiles.

**Problem 3: Velocity prediction without data is worse than no prediction.** An AI model that "predicts" velocity from 0-2 past sprints will produce confident-sounding numbers that are statistically meaningless. Users will trust the prediction, overcommit, and blame the tool. The cold-start heuristic (Tier 2/3) is honest about its limitations by annotating every gate with a warning. An AI prediction hides uncertainty behind a veneer of sophistication.

**Problem 4: Sprint retrospectives duplicate tracker functionality.** Every tracker with native sprints (YouTrack, Jira, Linear) has built-in retrospective/velocity reporting. Building our own is not just redundant -- it will always be worse because we have less data (we only see issues processed through ceos-agents, not the full sprint).

**Problem 5: Scope explosion makes cross-tracker testing impossible.** With 6 trackers times N sophisticated features, the test matrix grows combinatorially. The current test suite has ~39 scenarios. Adding sprint goal generation, velocity prediction, and retrospectives for 6 trackers could easily triple that. With no CI runner configured (per project memory), all tests run locally. This is unsustainable.

**Problem 6: The roadmap said NOT PLANNED for a reason.** The original decision was sound: "ceos-agents is not a PM tool." An innovative approach that adds PM features (retrospectives, burndown, team modeling) directly contradicts the project's architectural boundary. Accepting sprint as "batch selection with tracker tagging" is defensible. Accepting sprint as "full sprint lifecycle management" is scope creep into a domain where we cannot compete with native tracker tooling.

---

## What I Would Accept as Compromise

I would accept these specific elements if proposed by the other approaches:

**From the Conservative Pragmatist:**
- **Deferring Gate 5 (scope adjustment)** -- I already include this in my approach. The interactive toggle loop is novel complexity with unclear MVP value.
- **Starting with `Mode: suggest` only** -- I could accept shipping v6.5.0 with only suggest mode and adding `--apply` execution dispatch in v6.5.1. This reduces the blast radius of the initial release. However, I consider this overcautious -- `--apply` is gated behind explicit config or flag, and fix-ticket/implement-feature are already battle-tested.

**From the Innovative Integrator:**
- **Sprint naming pattern as a config key** -- but only if it uses simple `{YYYY}`, `{MM}`, `{WW}` tokens, not a template language. Default: `Sprint {YYYY}-W{WW}`. This is low-cost and genuinely useful for teams with naming conventions.
- **Sprint goal as a Gate 0.5 prompt** -- but only in non-`--yolo` mode, and only if the user types something. Default: null. AI-generated goals are rejected; user-authored goals are fine.
- **Reading past sprint state files for Tier 1 velocity** -- but only in a follow-up release (v6.6.0), and only as a supplement to metrics.md data, never as a replacement. The state files record what we planned and dispatched; deriving velocity from them is a natural extension that does not require new schema.

**Hard rejections (non-negotiable):**
- Team member modeling -- will not accept in any form
- AI velocity prediction -- heuristic with honest uncertainty warnings is better than a black-box prediction
- Sprint retrospectives / burndown -- tracker's job, not ours
- Redmine Agile Plugin auto-detection -- unreliable, Version is always available
- Gate 5 interactive toggle in MVP -- new interaction pattern, defer
- `--yolo` implying `--apply` -- too dangerous for an implicit default
