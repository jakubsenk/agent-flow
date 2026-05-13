# Approach B: Innovative Integrator -- "AI-Assisted Sprint Intelligence"

## Design Proposal (all 10 dimensions)

### 1. Architecture: New Agent + New Skill, Purpose-Built for the Sprint Planning Domain

I propose creating **one new agent** (`sprint-planner`, model: sonnet) and **one new skill** (`sprint-plan`), consistent with the research findings. However, my design goes further than a thin dispatch layer by making the sprint-planner agent a genuine analytical component -- not just a capacity accumulator, but an intelligent sprint composition engine that considers dependency chains, risk clustering, and team velocity trends.

**sprint-planner agent** (sonnet, read-only): Receives priority-engine output + Sprint Planning config + velocity data. Performs capacity-constrained selection with dependency awareness and risk distribution. Outputs a structured sprint plan table with overflow candidates, cold-start annotations, and decomposition recommendations. This agent is the analytical brain -- it does NOT write to trackers.

**sprint-plan skill** (orchestration, `disable-model-invocation: true`): The 11-step pipeline that wires everything together. It owns:
- Config parsing and validation (step 0b)
- Velocity source determination (Tier 1/2/3 fallback with manual prompt)
- Issue fetching via MCP
- Agent dispatch (priority-engine via Task, then sprint-planner via Task)
- All 5 human gates (the core of the semi-autonomous experience)
- Tracker-specific sprint assignment dispatch (the per-tracker table from research)
- State persistence (atomic writes to `.ceos-agents/sprint-{timestamp}/state.json`)
- Execution launch (fix-ticket/implement-feature per issue in apply mode)

Why not extend `/prioritize`? Because sprint planning is a fundamentally different workflow. `/prioritize` is read-only analysis with zero tracker writes. Sprint planning involves human gates, tracker mutations (sprint assignment), state persistence, and optionally execution dispatch. Bolting this onto `/prioritize` would violate the single-responsibility principle that makes the current skill architecture clean. The priority-engine agent is reused as-is -- the new sprint-planner agent is its downstream consumer, not its replacement.

Why not extend `fix-bugs`? Because `fix-bugs` takes a number N and immediately starts fixing. Sprint planning is about deciding WHAT to fix before touching any code. It is a planning activity, not an execution activity. The execution only happens after explicit human approval at Gate 4 (or `--apply` flag).

### 2. Sprint Model: Unified Abstraction with Tracker-Specific Dispatch

The sprint model uses a **unified abstraction layer** that maps to tracker-native concepts. The skill speaks in terms of "sprint" universally, and the per-tracker dispatch table handles the vocabulary translation:

| Unified Term | YouTrack | Jira | Linear | GitHub | Gitea | Redmine |
|-------------|----------|------|--------|--------|-------|---------|
| Sprint | Sprint | Sprint | Cycle | Milestone | Milestone | Version |
| Sprint field | `Sprint` | `Sprint` | `cycleId` | `milestone` | `milestone` | `fixed_version_id` |
| Create | REST (agile board) | REST (scrum board) | GraphQL | MCP | MCP | MCP/REST |
| Assign | MCP (field update) | MCP (add to sprint) | MCP (field update) | MCP (field update) | REST | MCP/REST |
| Query | MCP query language | JQL | MCP list | MCP list | MCP list | MCP list |

The key design insight: **sprint assignment is always NON-BLOCKING**. If the tracker operation fails (MCP unavailable, wrong permissions, Kanban board in Jira), the sprint plan still succeeds as a local artifact. The state file records `sprint_assigned: false` for failed assignments, and the user sees a summary of what worked and what did not.

This matters because sprint planning's value is in the analysis and selection, not in the metadata write. A team that uses GitHub milestones gets full value from the capacity-constrained issue selection even if the milestone API call fails. The plan is the product; the tracker assignment is a convenience.

The `Sprint field` config key (default per tracker, overridable) handles the vocabulary mapping. The `Sprint naming pattern` should be a configurable key -- I would add it to the config contract (see dimension 8). Default: `Sprint {YYYY-WW}`. This allows teams using naming conventions like `2026-Q2-Sprint-3` to integrate cleanly.

### 3. Autonomous vs. Semi-Autonomous: The AI Proposes, The Human Disposes

This is where my approach diverges most sharply from a thin-layer design. Semi-autonomous mode is not just "confirm yes/no" -- it is an interactive refinement loop where the human collaborates with the AI to produce a better sprint plan than either could alone.

**Semi-autonomous mode (default, `Mode: suggest`):**

The 9-step flow with 5 human gates:

```
Step 1: MCP pre-flight                    [automatic]
Step 2: Config validation                  [automatic]
Step 3: Fetch issues                       [automatic]
Step 4: Run priority-engine (opus)         [automatic -- heavy analytical lift]
Step 5: Run sprint-planner (sonnet)        [automatic -- capacity fitting]
  GATE 1: "Capacity confirmed?"            [HUMAN -- see the plan, validate assumptions]
Step 6: Scope adjustment                   [HUMAN -- interactive toggle loop]
  GATE 5: "Add/remove issues?"             [HUMAN -- repeating prompt]
Step 7: Per-issue decomposition            [HUMAN per decomposable issue]
  GATE 2: "Approve decomposition?"         [HUMAN]
  GATE 3: "Unmapped AC -- continue?"       [HUMAN -- safety gate, blocks even in --yolo]
Step 8: Final sprint plan table
  GATE 4: "Start sprint?"                  [HUMAN -- point of no return]
Step 9: Sprint assignment + execution      [automatic]
```

The critical UX innovation is Gate 1 + Gate 5 as a conversational refinement loop:

**Gate 1 display:**
```
Suggested sprint: 7 issues -- ~28 effort points
Team capacity: 40 story-points
Velocity source: historical (from reports/metrics.md, last 30 days)
Historical velocity: 32 points/sprint (avg over 3 sprints)
Buffer: 4 points remaining (12% headroom)

| # | Issue       | Tier | Effort | Type    | Depends On | Rationale                    |
|---|-------------|------|--------|---------|------------|------------------------------|
| 1 | PROJ-42     | P0   | 2 pts  | bug     | --         | Login broken, 50+ reports    |
| 2 | PROJ-38     | P0   | 5 pts  | feature | --         | API auth blocks 3 features   |
| 3 | PROJ-55     | P1   | 3 pts  | bug     | PROJ-42    | Follows from PROJ-42 fix     |
| 4 | PROJ-61     | P1   | 5 pts  | feature | --         | High customer demand         |
| 5 | PROJ-73     | P1   | 3 pts  | bug     | --         | Data integrity risk          |
| 6 | PROJ-44     | P1   | 5 pts  | feature | --         | Roadmap commitment           |
| 7 | PROJ-80     | P2   | 5 pts  | bug     | --         | Low impact but easy fix      |

Overflow (not included):
| PROJ-91 | P2 | 8 pts | feature | -- | Complex, exceeds remaining capacity |
| PROJ-92 | P2 | 3 pts | bug     | -- | Cosmetic, low priority              |

Proceed with this selection? [Y/n]
```

If user says N, they enter Gate 5 -- the interactive toggle:

**Gate 5 (scope adjustment):**
```
Add or remove issues? Enter issue ID to toggle, or press Enter to continue.
> PROJ-80
  Removed PROJ-80 (5 pts). Remaining capacity: 9 pts.
  Available to add: PROJ-91 (8 pts), PROJ-92 (3 pts)
> PROJ-92
  Added PROJ-92 (3 pts). Remaining capacity: 6 pts.
> [Enter]
Updated plan: 7 issues, 31 points. Proceeding.
```

This toggle loop is the semi-autonomous killer feature. The AI did the heavy lifting (ranking 20+ issues, computing capacity fit, resolving dependencies), and the human is making surgical adjustments with full context. This is 10x faster than manually building a sprint in Jira's backlog view.

**Autonomous mode (`--yolo` flag):**

Auto-approves Gates 1, 2, 4. Skips Gate 5 entirely. BLOCKS on Gate 3 (unmapped AC -- high stakes). This enables CI-driven sprint planning: a scheduled job runs `/ceos-agents:sprint-plan --yolo --apply` every Monday, creates the sprint, assigns issues, and launches execution. The team reviews the sprint async.

**`--dry-run` mode:**

Runs the full analysis pipeline but exits after Gate 4 display. No tracker writes, no execution, no state file. Pure recommendation. This is valuable for sprint planning meetings where the team wants AI input but will make the final call in their own tool.

### 4. Capacity Planning: Multi-Unit Model with Historical Calibration

I advocate for a flexible capacity model that supports three units and automatically calibrates over time:

**Story points** (default when `Capacity unit: story-points`):
- `Team capacity`: total points the team can handle per sprint
- `Velocity target`: target points to commit (always <= capacity)
- `effective_capacity = min(Team capacity, Velocity target)`
- Effort-to-points mapping: `{1: 1, 2: 2, 3: 3, 4: 5, 5: 8}` (Fibonacci-adjacent)

**Hours** (when `Capacity unit: hours`):
- `Team capacity`: total available hours per sprint
- Effort-to-hours mapping: `{1: 0.5, 2: 1.0, 3: 2.0, 4: 4.0, 5: 8.0}`
- Sprint duration converted to hours: `1w=40h, 2w=80h, 3w=120h, 4w=160h`

**Issue count** (when `Capacity unit: issues`):
- `Team capacity`: max number of issues per sprint
- No effort accumulation -- just count. Simplest model for teams without estimation.

The innovative element: **velocity prediction from metrics history**. When `./reports/metrics.md` exists (from running `/ceos-agents:metrics`), the sprint-planner extracts:
- `avg_time_to_fix_hours`: calibrates hour estimates
- `success_rate`: discounts capacity (if 75% success rate, plan for 75% of capacity)
- Per-area failure patterns: flags issues in historically problematic areas

The cold-start formula from the research is sound:
```
Tier 1 (historical): max_issues = floor(effective_capacity / avg_time_to_fix × success_rate)
Tier 2 (heuristic):  capacity-constrained accumulation with 20% overflow buffer per issue
Tier 3 (manual):     prompt user for hours, or unconstrained top-N
```

What I add: **velocity trend awareness**. If the last 3 sprints show declining velocity (30, 28, 25 points), the sprint-planner annotates Gate 1 with: "Warning: Velocity trending downward (30 -> 28 -> 25 over 3 sprints). Consider targeting 23-25 points." This is not a hard constraint -- just intelligence that helps the human make a better decision. The data exists in metrics reports; computing a trend line is trivial.

### 5. Velocity Tracking: Computed at Planning Time from Existing Artifacts

ceos-agents has no runtime. Velocity is NOT tracked -- it is computed at sprint planning time from existing data sources. This is a critical architectural constraint.

**Data sources (in priority order):**

1. **`./reports/metrics.md`** (from `/ceos-agents:metrics`): Contains `avg_time_to_fix`, `success_rate`, per-agent effectiveness. This is the richest source. Velocity source = "historical".

2. **Sprint state files** (`.ceos-agents/sprint-*/state.json`): Previous sprint plans contain `total_effort_post_decomp`, `completed_issues`, `blocked_issues`. By reading past sprint states, the sprint-planner can compute actual velocity (planned vs. completed). This is the sprint-over-sprint calibration feedback loop.

3. **Tracker data**: Some trackers expose velocity charts (Jira, Linear). However, querying these is tracker-specific and unreliable via MCP. I would NOT depend on this for MVP -- the internal data sources are sufficient.

4. **Triage checkpoint comments**: `[ceos-agents] Triage completed. ... Complexity: {X}.` provides per-issue complexity signals already embedded in the tracker. Sprint-planner scans for these and uses the Complexity-to-points mapping when available (takes precedence over raw effort scores because triage complexity is validated against actual code analysis).

**Where velocity lives:** It does NOT have a permanent home. It is computed fresh at each sprint planning invocation by reading metrics + sprint state files. The sprint state file records `velocity_source` and `effective_capacity` so the next sprint can compare actual vs. planned.

The feedback loop: Sprint N state records what was planned. After Sprint N completes, `/ceos-agents:metrics` captures what actually happened. Sprint N+1 planning reads both and adjusts. No new storage mechanism needed -- the existing artifacts close the loop.

### 6. Issue Selection Algorithm: Priority-Engine Seed, Capacity-Constrained, Dependency-Aware

The selection algorithm is a three-stage pipeline:

**Stage 1 -- Priority-engine ranking (existing, unchanged):**
The priority-engine (opus) produces P0/P1/P2 tables with Impact, Risk, Effort, Score, Rationale, and the `Suggested batch` recommendation. This is the raw input. The priority-engine is NEVER re-run after initial invocation -- its scores are cached.

**Stage 2 -- Sprint-planner capacity fitting (new agent, sonnet):**
Walk the ranked list in priority order. For each issue:
1. Resolve effort size (Estimation field > triage complexity > priority-engine effort score > default 3)
2. Check dependency graph: if issue depends on another issue not yet in the plan, attempt to add the dependency first
3. Accumulate effort. Include if `accumulated + issue_cost <= effective_capacity + (issue_cost * 0.2)` (20% overflow buffer per issue -- allows a 5-point issue to be included when 4 points remain)
4. If dependency cannot fit, annotate the dependent issue as "at-risk"
5. Flag `decompose_recommended: true` when effort_score >= 4 OR Risk = 5

**Stage 3 -- Human refinement (Gate 5):**
The human toggles issues in/out. On each toggle, the sprint-planner re-runs capacity fit (NOT full priority-engine re-run) using cached scores. This is fast because it is pure arithmetic, not LLM inference.

The dependency awareness is important. If PROJ-55 depends on PROJ-42, and the human removes PROJ-42 at Gate 5, the system warns: "PROJ-55 depends on PROJ-42 which is no longer in the sprint. Remove PROJ-55 too? [Y/n]". This cascading dependency check prevents broken sprint plans.

Why not pure priority-engine output? Because the priority-engine has no concept of capacity. It ranks ALL issues. The sprint-planner's job is to fit the ranked list into the sprint window. This separation of concerns (ranking vs. fitting) is clean and testable.

### 7. Tracker Operations: Three Operations, Tiered Fallback, Non-Blocking

Three operations per tracker, matching the research dispatch table:

**sprint_create** -- Create the sprint/milestone/cycle/version in the tracker:
- Required before assignment for trackers that need an ID (all except YouTrack)
- Only executed in `Mode: apply` or with `--apply` flag
- If creation fails: log warning, skip assignment, plan still valid

**sprint_assign** -- Assign each issue to the sprint:
- Tiered: MCP (Tier 1) -> Bash+REST (Tier 2) -> skip+warn (Tier 3)
- NON-BLOCKING: failure to assign does not block the pipeline
- State records `sprint_assigned: true/false` per issue

**sprint_query** -- Query issues already in a sprint:
- Used for sprint status checking (future enhancement)
- Not required for MVP planning flow

The tiered fallback logic per tracker is fully specified in the research (Section 1). The key design decision I endorse: **always try MCP first, fall back to Bash+REST, never block on assignment failure**. This makes sprint planning work even with partially configured MCP setups.

Name-to-ID resolution is a hidden complexity. All trackers except YouTrack require resolving a sprint name to a numeric/UUID ID before assignment. The skill handles this resolution before the assignment loop, caching the resolved ID for all issues. If resolution fails (sprint not found), creation is attempted. If creation also fails, assignment is skipped.

### 8. Config Contract: One New Optional Section, 12 Keys, All With Defaults

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

I endorse the 12-key design from the research but advocate adding one more key in a fast-follow:

**Sprint naming pattern** (future, not MVP): Template string like `Sprint {YYYY-WW}` or `{PROJECT}-Sprint-{N}`. Default: `Sprint {YYYY-WW}`. This allows teams to match their existing naming convention.

All 12 keys are optional. Section absence = sprint planning disabled. Projects need only include keys they want to override. This is consistent with every other optional config section (Browser Verification, Local Deployment, Decomposition, etc.).

The section goes in the optional sections table in CLAUDE.md after the Decomposition row:

```
| Sprint Planning | Sprint duration, Capacity unit, Team capacity, Velocity target, Sprint field, Priority field, Mode, Max issues, Include types, Exclude labels, Estimation field, Report path | 2 weeks, story-points, (none), (none), Sprint, Priority, suggest, 20, bug/feature, (none), (none), (none) |
```

Version impact: v6.5.0 (MINOR). One optional section, one new agent, one new skill. Zero impact on projects that do not add the section.

### 9. State Persistence: Sprint State in `.ceos-agents/sprint-{timestamp}/`

Sprint state lives in `.ceos-agents/sprint-{timestamp}/state.json`, following the existing state schema conventions. The schema from the research (Section 5) is comprehensive and well-designed.

Key state elements:
- `sprint.name`, `sprint.goal`, `sprint.duration`, `sprint.capacity_unit`
- `sprint.effective_capacity`, `sprint.velocity_source`, `sprint.velocity_target`
- `sprint.issues[]` with per-issue: `issue_id`, `priority_score`, `tier`, `effort_score`, `effort_points`, `type`, `decompose_recommended`, `subtask_count`, `sprint_assigned`, `child_run_id`, `status`
- `gates.capacity_confirmed`, `gates.scope_adjusted`, `gates.sprint_started`
- `sprint_assignment.status`, `sprint_assignment.mode`, `sprint_assignment.assigned_count`, `sprint_assignment.failed_count`

**8 state update points** (from research): after config validation, after Gate 1, after each decomposition, after Gate 4, after each assignment, as child pipelines start, as child pipelines complete, on pipeline completion.

The sprint state file serves three purposes:
1. **Resume capability**: If the sprint-plan skill is interrupted, `/ceos-agents:resume-ticket` can read the state and continue (this requires minor extension to resume-ticket, deferred to follow-up).
2. **Dashboard integration**: `/ceos-agents:dashboard` can read sprint state files to show sprint-level aggregation (deferred to follow-up).
3. **Velocity feedback loop**: Next sprint planning invocation reads past sprint states to compute actual-vs-planned velocity.

Atomic writes (write to `.json.tmp`, rename) per existing `state/schema.md` convention.

### 10. Failure Modes: Graceful Degradation at Every Level

**Tracker does not support sprints:**
- Jira Kanban board: Pre-condition check (`board.type == "scrum"`) detects this. Sprint creation and assignment are skipped. The plan is still produced as a local artifact. User sees: "Your Jira project uses a Kanban board. Sprint assignment skipped. The plan is available as a recommendation."
- Tracker with no sprint concept: Impossible in current 6-tracker set -- all have some sprint-like abstraction (milestone, version, cycle). If a 7th tracker is added without sprint support, the pattern is: skip assignment, produce plan as recommendation.

**Capacity unknown (cold start):**
- Tier 3 fallback: Prompt user for estimated hours. If skipped, operate in unconstrained mode (top-N by priority, no capacity ceiling). Gate 1 shows `Velocity source: unconstrained` and annotates: "No capacity data. Run /ceos-agents:metrics after this sprint to calibrate future planning."
- This is NOT a failure -- it is the expected first-sprint experience. The plan is still valuable because the priority ranking is capacity-independent.

**Priority-engine output is stale:**
- The priority-engine is always run fresh at step 4. There is no cache between sprint planning invocations. Staleness is not possible within a single invocation.
- If the user wants to reuse a previous prioritization (e.g., they ran `/ceos-agents:prioritize` 10 minutes ago), they must run `/ceos-agents:sprint-plan` which re-runs the analysis. This is intentional -- backlog state may have changed.

**Priority-engine fails:**
- BLOCKING. Sprint planning cannot proceed without a ranked issue list. The skill displays the error and stops. This is the correct behavior -- unlike sprint assignment (which is convenience), prioritization is the core value.

**Sprint-planner fails:**
- BLOCKING. Without capacity fitting, the plan is just a raw priority list (which `/prioritize` already provides). The skill displays the error and stops.

**Sprint assignment fails (per issue):**
- NON-BLOCKING. Log warning, record `sprint_assigned: false` in state, continue to next issue. Summary after all assignments: "Assigned 5/7 issues. 2 failed (PROJ-80: MCP timeout, PROJ-92: permission denied). These issues are included in the plan but not tagged in the tracker."

**MCP pre-flight fails:**
- BLOCKING. Without tracker access, there are no issues to plan. No `--yolo` exception. The user must fix their MCP configuration.

**Metrics file corrupt or unparseable:**
- Fall back to Tier 2 (heuristic). Log warning: "Could not parse metrics report. Using heuristic velocity estimates."

**All gates declined (user says N to Gate 4):**
- Clean exit. No tracker writes, no execution, no state file persisted. The analysis is lost (by design -- if the user rejects the plan, they do not want it recorded).

---

## Critique of Conservative Pragmatist Approach

A "thin wrapper" that simply maps priority-engine output to tracker sprint APIs would have these specific problems:

### 1. Capacity fitting becomes the user's problem

If the conservative approach skips the sprint-planner agent and just feeds priority-engine's `Suggested batch` directly to the tracker, there is no capacity awareness. The `Suggested batch` is the priority-engine's best guess at "what to fix next" but it has NO concept of team capacity, sprint duration, or velocity. A team with 20 story-points of capacity would get the same suggestion as a team with 80. The user would have to mentally do the capacity math and manually remove issues -- exactly the workflow sprint planning is supposed to eliminate.

### 2. No interactive refinement means the tool is either all-or-nothing

Without Gate 5 (scope adjustment), the user's choices are: accept the AI's plan wholesale, or reject it entirely and plan manually. There is no middle ground. The semi-autonomous mode's value comes precisely from the ability to surgically adjust the AI's proposal. Removing this makes the tool useful only for fully automated (CI) scenarios, which is a small fraction of the audience.

### 3. Cold-start is handled poorly or not at all

A thin layer would likely punt on the cold-start problem: "No velocity data? Use the priority-engine suggestion as-is." This means first-time users get an uncalibrated plan with no capacity constraints, no warnings about confidence levels, and no path to calibration. The three-tier velocity fallback with explicit cold-start annotations is essential for trust.

### 4. Dependency awareness is lost

The priority-engine outputs a dependency graph (`{issue_A} -> blocks -> {issue_B}`), but a thin wrapper would not use it for sprint composition. Without the sprint-planner's dependency-aware fitting, a sprint could include PROJ-55 (which depends on PROJ-42) without including PROJ-42 -- and the user would not know until they start implementation.

### 5. Velocity feedback loop never forms

Without sprint state files that record planned-vs-actual, there is no mechanism for the system to learn from past sprints. Each sprint planning session starts from zero. The feedback loop (sprint state -> metrics -> next sprint calibration) is what turns sprint planning from a one-shot tool into an improving system.

The conservative approach is seductive because it is cheap to build. But it produces a tool that is marginally better than running `/ceos-agents:prioritize` and manually creating a sprint in the tracker. That is not worth a new agent, a new skill, and a new config section.

---

## Critique of Skeptical Architect Approach

The skeptical position -- "sprint planning does not belong in ceos-agents because the roadmap said NOT PLANNED" -- has these specific weaknesses:

### 1. The NOT PLANNED status was a prioritization call, not an architectural verdict

The roadmap says NOT PLANNED for sprint planning/tracking. But it also says "backlog selection" is PROPOSED. Sprint planning IS backlog selection with capacity constraints and tracker integration. The roadmap was not declaring sprint planning architecturally incompatible -- it was saying "we have higher-priority work." That work is now done (v6.4.x). The architectural foundation (priority-engine, MCP tracker abstraction, state schema, metrics) is mature enough to support sprint planning cleanly.

### 2. The 6-tracker problem is already solved

The skeptic's strongest argument -- "if you cannot make it work for all 6 trackers, do not build it" -- is valid in principle but already addressed by the research. The per-tracker dispatch table covers all 6 trackers with concrete MCP calls, REST fallbacks, and skip-with-warning degradation. Sprint assignment is NON-BLOCKING precisely because tracker support varies. The unified abstraction works because the abstraction is simple: "assign issue to a named sprint-like container." Every tracker has this concept (Sprint, Cycle, Milestone, Version).

### 3. "Pure markdown plugin" is not violated

The skeptic may argue that sprint state files and velocity computation make ceos-agents a runtime system. But ceos-agents ALREADY has state files (`.ceos-agents/{RUN-ID}/state.json`), metrics reports (`./reports/metrics.md`), and multi-step pipelines with human gates. Sprint planning adds one more state file type and one more gate pattern -- no architectural novelty. The velocity computation happens at planning time, not as a background process. There is no daemon, no database, no persistent service. It remains a pure markdown plugin that an LLM interprets at invocation time.

### 4. Not building it has a real cost

The gap between `/ceos-agents:prioritize` (ranking) and `/ceos-agents:fix-bugs` (execution) is where sprint planning lives. Without it, the user must:
1. Run `/prioritize` to rank the backlog
2. Manually read the output and decide which issues to fix
3. Manually create a sprint in their tracker
4. Manually assign issues to the sprint
5. Run `/fix-ticket` or `/fix-bugs` for each issue

Steps 2-4 are exactly what sprint planning automates. The priority-engine output is stranded without a consumer that bridges it to execution. This is not feature creep -- it is closing a gap in the existing pipeline.

### 5. Abstraction fragility is manageable

The skeptic worries that tracker differences will make the abstraction leak. But the design handles this by making every tracker operation tiered and non-blocking. If GitHub milestones cannot represent sprint start dates (they cannot), the system still works -- it just records the sprint plan as a local artifact. If Redmine's Agile Plugin is not installed, Version is used instead. The abstraction does not claim that all trackers are identical -- it claims that all trackers have "a container you put issues in for a time period," which is true.

---

## What I Would Accept as Compromise

My approach is deliberately ambitious. Here are the specific elements where I would accept trimming, and the elements from the other approaches that could improve mine:

### From the Conservative Pragmatist -- I accept:

1. **Defer sprint naming pattern config key to a fast-follow.** The default `Sprint {YYYY-WW}` is sufficient for MVP. Adding a 13th config key for customization can wait.

2. **Defer sprint goal authoring (Gate 0.5).** The research noted this as an open question. I accept that `sprint.goal` is always null in MVP. Sprint goal is a nice-to-have, not a planning necessity.

3. **Defer sprint-level dashboard and metrics aggregation.** The state files enable this, but the dashboard/metrics code does not need to change in v6.5.0. Sprint-level views can come in v6.6.0.

4. **Defer velocity trend analysis to a fast-follow.** The raw velocity computation (Tier 1/2/3) is sufficient for MVP. Trend lines and decline warnings can come after the first sprint cycle proves the data flow works.

5. **Defer parallel execution config key.** The research asks whether `Parallel execution: true/false` should be configurable. I accept: always parallel for MVP (consistent with fix-bugs behavior), config key deferred.

### From the Skeptical Architect -- I accept:

1. **Sprint assignment MUST be non-blocking, without exception.** The skeptic is right that tracker diversity makes any "required" tracker write fragile. I already design for this, but I elevate it to a first-class principle: sprint planning produces value even with zero tracker writes.

2. **Explicit degradation messages per tracker.** When a tracker operation fails or is skipped, the message must be tracker-specific (not generic). "Your Jira project uses a Kanban board -- sprint assignment skipped" is better than "Sprint assignment failed." The skeptic's demand for honest failure reporting is correct.

3. **No new required config sections.** Sprint Planning is optional. Period. If a project does not want sprint planning, adding the section should never be required by any existing skill. The skeptic is right that a required section would be a MAJOR version bump and would burden all existing users.

4. **The 50-issue ceiling from priority-engine is inherited, not raised.** I accept the hard ceiling rather than trying to paginate or batch beyond it. 50 issues is enough for any reasonable sprint planning scenario.

### Elements I would NOT compromise on:

1. **The sprint-planner agent must exist.** Capacity fitting is analytical work that belongs in an agent, not inline in a skill. The separation of ranking (priority-engine) from fitting (sprint-planner) is architecturally clean and testable.

2. **Gate 5 (scope adjustment) must be in MVP.** This is the semi-autonomous killer feature. Without it, sprint planning is a take-it-or-leave-it tool. The interaction pattern (repeating prompt with toggle) is new but not complex -- it is a while loop with user input.

3. **Sprint state files must exist.** Without state, there is no feedback loop, no resume capability, and no sprint-level visibility. The state schema from the research is the minimal viable structure.

4. **Cold-start velocity handling (Tier 1/2/3) must be in MVP.** First-time users are the most important users. If sprint planning does not work without historical data, it will never get historical data because no one will use it.

5. **`--dry-run` must be in MVP.** This is the trust-building mode. Users who are uncertain about sprint planning can run `--dry-run` to see what it would do before committing. Removing it makes adoption harder.
