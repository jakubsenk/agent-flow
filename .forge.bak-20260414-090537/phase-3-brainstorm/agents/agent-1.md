# Approach A: Conservative Pragmatist --- "Thin Sprint Layer"

## Design Proposal (all 10 dimensions)

### 1. Architecture: New agent + new skill, or extend existing components?

**One new agent (`sprint-planner`, sonnet), one new skill (`sprint-plan`).** No alternatives considered.

The research already validated this is the minimum viable surface. The sprint-planner agent is a pure arithmetic capacity-fitter --- it receives ranked output from the existing priority-engine and applies a knapsack algorithm against configured capacity. It does not re-rank, re-assess, or invent data. It is read-only (consistent with 9 of 19 existing agents). The skill orchestrates the existing MCP pre-flight, priority-engine dispatch, sprint-planner dispatch, human gates, and tracker assignment.

Why not extend `/prioritize`? Because sprint assignment is a write operation (assigning issues to a tracker sprint/milestone/cycle), and the existing `prioritize` skill is explicitly read-only. Bolting write semantics onto it would violate its contract. The sprint-plan skill reuses priority-engine output but owns the write path.

Why not a new "sprint manager" agent that does both prioritization and capacity fitting? Because priority-engine already exists, runs on opus, and produces exactly the ranked list sprint-planner needs. Duplicating that logic in a second agent would be the worst kind of feature creep --- the kind that looks tidy on a diagram but creates two sources of truth for prioritization scores.

**Total new file count:** 2 definition files (agent + skill), up to 7 test scenarios, 10 modified files. This is consistent with previous MINOR releases (browser-verifier v5.1.0: 2 new agents + 1 skill; deployment-verifier v5.3.0: 1 new agent + 1 skill).

### 2. Sprint model: Unified abstraction across trackers, or tracker-specific?

**Unified abstraction with three operations: `sprint_create`, `sprint_assign`, `sprint_query`.** Each tracker maps its native concept to these three verbs:

| Tracker | Native concept | Mapping |
|---------|---------------|---------|
| youtrack | Sprint (custom field) | Direct |
| jira | Sprint (Scrum board) | Direct |
| linear | Cycle (team-scoped) | Rename only |
| github | Milestone | Semantic stretch, but functional |
| gitea | Milestone | Same as GitHub |
| redmine | Version (core) or Agile Sprint (plugin) | Version as default, plugin as upgrade |

The abstraction is THIN. It does not model sprint states (active/closed/future), sprint velocity history, burndown, or retrospective data. Those live in the tracker where they belong.

The key constraint: **sprint assignment is always NON-BLOCKING.** If any of the three operations fail at all tiers (MCP, Bash+REST, skip), the pipeline continues. This means the abstraction does not need to be robust --- it needs to be best-effort and silent-on-failure. This dramatically simplifies implementation because we never need to handle rollback of partial sprint assignments.

I would push back on ANY proposal to normalize sprint states across trackers. Jira has future/active/closed sprints. GitHub milestones have open/closed. Linear cycles auto-close. YouTrack sprints are board-scoped. Trying to unify these is a multi-month project that delivers zero value to the actual goal (selecting issues for the next work batch).

### 3. Autonomous vs. semi-autonomous: How do the two modes differ? Human touchpoints?

**Semi-autonomous by default, with `--yolo` for full automation.**

The research specifies 5 gates. I would trim to 3 for MVP:

| Gate | Purpose | `--yolo` | My rationale |
|------|---------|----------|-------------|
| Gate 1: Capacity confirmation | User sees the proposed sprint and confirms | Auto-approve | Essential --- user must see what the machine chose |
| Gate 3: Unmapped AC warning | High-stakes decomposition gap | BLOCK | Consistent with implement-feature; this is the only gate `--yolo` does NOT skip |
| Gate 4: "Start sprint?" | Final commit before tracker writes | Auto-approve | Essential --- last chance before side effects |

**I would defer Gates 2 and 5 from MVP:**

- **Gate 2 (per-issue decomposition approval):** This requires the full architect agent decomposition flow integrated into sprint planning. That is a significant interaction surface. For MVP, if an issue has effort >= 4, flag it as "consider decomposing before sprint start" in the output table, but do NOT run decomposition inline. The user can run `/implement-feature {ID}` which already handles decomposition with its own gates.

- **Gate 5 (interactive scope adjustment toggle):** The research itself flags this as "a new interaction pattern not present elsewhere" (Open Question 8). A repeating prompt loop with cache management is novel UX machinery. For MVP, if the user rejects Gate 1, they re-run with `--capacity` or `--exclude-labels` flags. Explicit flags over interactive loops.

This reduces the skill from 11 steps to approximately 8, eliminates the most complex interaction patterns, and still delivers the core value: "here is what your next sprint should contain, and here is a button to assign it."

### 4. Capacity planning: How is team capacity modeled?

**Two optional config keys: `Team capacity` and `Velocity target`.** One unit key: `Capacity unit` (story-points or hours, default: story-points).

Effective capacity = `min(Team capacity, Velocity target)` when both set; whichever is present when one set; unconstrained (top N issues) when neither set.

I explicitly reject:
- Per-developer capacity modeling. This is PM tooling territory. The plugin does not know who is on the team, who is on vacation, or who is a senior vs. junior developer. Trying to model this turns ceos-agents into a resource management tool.
- Sprint-over-sprint capacity adjustment. The tracker owns this data. If velocity is consistently lower than capacity, that is a process problem for humans to discuss in retro, not for an LLM to "fix."

The cold-start heuristic from research (Tier 2: effort score maps to hours/points via fixed table) is pragmatic and I accept it. The Tier 3 manual prompt ("estimated hours available?") is acceptable only because it is a single question, not an interactive wizard.

### 5. Velocity tracking: Where does velocity data live?

**In the tracker and in the existing `/metrics` output.** No new velocity storage.

The research proposes reading `./reports/metrics.md` for historical velocity (Tier 1). This is correct --- `/metrics` already tracks "Avg time to fix" and "Issues fixed" counts. Sprint-planner consumes these numbers. It does not write new velocity data.

After a sprint completes, the user runs `/metrics` which reads pipeline state files and produces the report. That report feeds the NEXT sprint's Tier 1 velocity calculation. The feedback loop already exists; we just read from it.

I would NOT add sprint-level velocity aggregation to the state schema. The research proposes `completed_issues`, `blocked_issues`, `skipped_issues` counters in sprint state --- these are fine because they are trivial to maintain (increment on child pipeline completion). But computing "sprint velocity = sum of effort points of completed issues" should be a `/metrics` concern, not a sprint-planner concern. Single responsibility.

### 6. Issue selection algorithm: Pure priority-engine? Capacity-constrained?

**Priority-engine for ranking, sprint-planner for capacity-constrained selection.** Two-phase, two-agent, clear separation.

Phase 1 (priority-engine, opus): Rank all fetched issues by impact, risk, effort, dependencies. Output: P0/P1/P2 tables + suggested batch. This is the existing agent, unchanged.

Phase 2 (sprint-planner, sonnet): Walk the ranked list top-to-bottom, accumulate effort sizes against effective capacity, stop when full. Include an issue if the overflow is within 20% of its own size (rounding buffer). Flag dependency-blocked issues.

The algorithm is deliberately simple: greedy top-down fill. No knapsack optimization, no multi-objective solver, no "what-if" scenario analysis. The priority-engine already did the hard reasoning work. Sprint-planner is a filter, not a strategist.

Why sonnet for sprint-planner? Because the task is arithmetic (accumulate sizes, compare to threshold) with light dependency checking. Opus would be wasted. This is consistent with the model selection table: sonnet for analysis, opus for critical decisions.

### 7. Tracker operations: What operations per tracker?

**Three operations, three-tier fallback per operation.** The research's dispatch table is thorough and I accept it with one simplification:

**For MVP, only `sprint_assign` is required.** Sprint creation and sprint querying are optional enhancements:

- `sprint_create`: Most teams already have their sprints/milestones created in the tracker. The plugin should assign to an EXISTING sprint, not create new ones. If the sprint does not exist, warn and skip (NON-BLOCKING). Creation can be added later if there is demand.
- `sprint_query`: Useful for the `/status` command to show sprint progress. Low priority for MVP.
- `sprint_assign`: The core operation. Set the sprint/milestone/cycle field on each selected issue.

This cuts the tracker integration surface by roughly two-thirds. Instead of implementing and testing 18 code paths (6 trackers x 3 operations), we implement 6 (one assign path per tracker, each with MCP-first + Bash fallback + skip).

The `Sprint field` config key tells the skill which tracker field to target (default: "Sprint" for youtrack/jira, "Milestone" for github/gitea, "Cycle" for linear, "Version" for redmine).

### 8. Config contract: What config section(s)?

**One optional section: `### Sprint Planning`.** Research specifies 12 keys; I would ship with 7 for MVP:

| Key | Default | MVP? | Rationale |
|-----|---------|------|-----------|
| Sprint duration | 2 weeks | Yes | Needed for capacity calculation |
| Capacity unit | story-points | Yes | Hours vs. points |
| Team capacity | (none) | Yes | Primary capacity constraint |
| Velocity target | (none) | Yes | Secondary constraint |
| Sprint field | (per tracker default) | Yes | Which tracker field to write |
| Mode | suggest | Yes | suggest vs. apply |
| Max issues | 20 | Yes | Fetch ceiling |
| Priority field | Priority | Defer | Rarely overridden |
| Include types | bug, feature | Defer | Use existing Bug query + Feature query |
| Exclude labels | (none) | Defer | Can be done with tracker query filters |
| Estimation field | (none) | Defer | Use triage complexity as proxy |
| Report path | (none) | Defer | stdout is fine for MVP |

The deferred keys can be added in patch releases since they are all optional with sensible defaults. Section absence = sprint planning disabled. This is consistent with every other optional section in the plugin.

**Version: v6.5.0 (MINOR).** One optional config section, one new agent, one new skill. Identical precedent to v5.1.0 and v5.3.0.

### 9. State persistence: Sprint state where?

**`.ceos-agents/sprint-{timestamp}/state.json`** using the existing atomic write protocol and the existing schema version. New RUN-ID format row: `sprint-{timestamp}`.

The research's full schema is reasonable. I would simplify the sprint state to track only what is needed for `/status` and `/metrics`:

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
  "config": { "...existing pattern..." },
  "sprint": {
    "name": "Sprint 2026-W16",
    "duration": "2 weeks",
    "velocity_source": "historical",
    "effective_capacity": 35,
    "issues": [
      {
        "issue_id": "PROJ-42",
        "tier": "P0",
        "effort_points": 2,
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

I removed: `goal` (null for MVP), `capacity_configured` and `velocity_target` (redundant with config), `effort_hours` (derivable from effort_points), `title` (fetch from tracker on demand), `decompose_recommended` and `subtask_count` and `post_decomp_effort` (deferred with Gate 2), `skipped_issues` (either completed or blocked), `gates` object (skill tracks gate state in-memory during execution; persisting it adds complexity for no consumer), `sprint_assignment` sub-object (flatten to per-issue `sprint_assigned` boolean).

State update points reduced from 8 to 5:
1. After config validation --- write initial state
2. After Gate 1 confirmed --- write issue list with effort scores
3. After Gate 4 confirmed --- mark sprint as approved
4. Per child pipeline start/complete/block --- update status and counters
5. On pipeline completion --- set top-level status

### 10. Failure modes: What when tracker doesn't support sprints? Capacity unknown?

**Tracker does not support sprints (or sprint operations fail):**
- Sprint assignment is NON-BLOCKING. If all three tiers fail for an issue, log a warning and continue. The sprint PLAN (the ranked, capacity-fitted list of issues) is still valid and useful even if the tracker assignment did not happen.
- If the tracker type has no sprint concept at all (hypothetical --- all 6 supported trackers have at least milestones), the skill outputs the plan and skips assignment entirely.
- Jira Kanban boards: detect via board type check, skip sprint assignment, warn.

**Capacity unknown (no config, no metrics):**
- Tier 3 fallback: ask the user once ("estimated hours available?"). If they skip, use unconstrained mode (top N issues by priority, no capacity fit). Display a cold-start warning at every gate.
- This is acceptable because the VALUE of sprint planning is the prioritized selection, not the capacity math. Even an unconstrained plan ("here are your top 20 issues ranked by priority with effort estimates") is useful.

**Priority-engine fails:**
- BLOCKING. Without ranked input, sprint-planner has nothing to work with. Display error and stop. This is consistent with existing pipeline behavior where upstream agent failure blocks downstream agents.

**Sprint-planner fails:**
- BLOCKING. The skill cannot produce a sprint plan without the capacity-fitting agent. Block and report.

**MCP pre-flight fails:**
- STOP. No tracker access means no issue list, which means nothing to plan. Consistent with every other skill.

**`--yolo` with `Mode: suggest`:**
- I resolve Open Question 5 simply: `--yolo` does NOT imply `--apply`. If you configured `Mode: suggest`, you meant it. `--yolo --apply` is required for fully automated execution. This avoids surprising the user with tracker writes they did not configure.

**Gate 3 (unmapped AC) in `--yolo` mode:**
- BLOCK, consistent with implement-feature. This is the one gate that `--yolo` cannot bypass. Rationale: unmapped acceptance criteria mean the plan has gaps that automation cannot evaluate --- human judgment required.

---

## Critique of Innovative Integrator Approach

An Innovative Integrator would likely propose:

1. **AI-assisted interactive planning with velocity prediction.** The problem: velocity prediction from LLM reasoning is not grounded in data. LLMs are confident estimators but poor actuaries. The existing Tier 1 historical approach (read actual metrics) is strictly better than any LLM-generated velocity prediction. Adding a "predicted velocity" feature creates a false sense of precision that degrades trust when predictions are wrong --- and they will be wrong, because sprint velocity depends on factors invisible to the plugin (meetings, sick days, context switching, morale).

2. **Interactive scope adjustment (Gate 5) with real-time capacity recalculation.** This is the most dangerous proposal from a maintenance perspective. A repeating prompt loop with cached priority scores is a new interaction pattern that has NO precedent in the plugin. Every other gate is a single yes/no question. Introducing an interactive toggle loop means: new test scenarios for empty input, invalid input, toggling the same issue twice, toggling an issue that causes a dependency violation, toggling an issue that pushes capacity over/under the threshold. Each of these is a distinct edge case. The simpler alternative: reject at Gate 1, re-run with different flags.

3. **Sprint goal drafting by AI.** The research notes this as Open Question 2. An AI-drafted sprint goal is the epitome of "looks impressive in a demo, useless in practice." Sprint goals are strategic alignment statements that reflect organizational priorities. An LLM looking at a list of bug titles cannot produce a meaningful goal. It will generate something like "Improve stability and add requested features" --- which tells the team nothing they did not already know. Defer indefinitely.

4. **Sprint-over-sprint learning / prediction curves.** Storing velocity history across sprints, building trend lines, predicting future capacity. This is what Jira, Linear, and every dedicated PM tool already does, better than we ever could with a flat JSON file. This is the fastest path to turning ceos-agents into a bad imitation of tools the team already pays for.

5. **Parallel execution with automatic dependency resolution.** The research suggests same-tier, dependency-free issues can be dispatched in parallel. An Integrator would want to extend this to automatic dependency graph execution (A completes, then B and C in parallel, then D). This adds a job scheduler to a markdown plugin. The complexity-to-value ratio is terrible. For MVP, sequential execution per-tier is fine. If users need parallelism, they can run multiple `/fix-ticket` calls themselves.

The core critique: the Innovative Integrator confuses "technically possible" with "valuable." Every AI-assisted feature they would add is a feature that needs to be maintained, tested, documented, and explained when it produces unexpected results. The plugin's strength is its simplicity --- 19 agents, each with a clear single responsibility, orchestrated by thin skills. Adding interactive planning, velocity prediction, and sprint-level learning turns it into something fundamentally different.

---

## Critique of Skeptical Architect Approach

A Skeptical Architect would argue:

1. **"Sprint planning does not belong in a code automation plugin."** This is a reasonable position but misses the practical gap. The plugin already has `/prioritize` which ranks the backlog, and `/fix-bugs N` which processes the top N issues. The gap between "here is a ranked list" and "process these issues as a sprint" is exactly one capacity-constrained selection step + tracker assignment. Refusing to bridge this gap means users must manually translate priority-engine output into tracker sprint assignments --- a tedious, error-prone task that is exactly what automation should handle.

2. **"Just use the tracker's built-in sprint planning."** This ignores why users want ceos-agents in the first place: because they want AI-assisted automation of development workflows. Telling them to use Jira's sprint planning UI and then come back to ceos-agents for execution creates a context-switching tax and breaks the pipeline's end-to-end value proposition. The Skeptic is right that we should not REPLICATE the tracker's sprint management, but wrong that we should not INTEGRATE with it.

3. **"The 6-tracker abstraction is too complex and will be maintenance burden."** This is the strongest Skeptic argument. Supporting sprint operations across 6 trackers with 3 tiers of fallback IS significant surface area. But the research's NON-BLOCKING constraint neutralizes most of the risk: if a tracker operation fails, we warn and continue. We do not need perfect reliability across all 6 trackers. We need best-effort assignment that works well for the 2-3 most common trackers (GitHub, Jira, Gitea) and degrades gracefully for the rest.

4. **"The config contract is getting too large."** Fair --- the Automation Config already has 16 optional sections. Adding a 17th increases cognitive load for new users. But the section is optional and self-contained. Users who do not need sprint planning never see it. The `/onboard` wizard and `/template` generator handle discoverability. This is the same argument that was made against Local Deployment (v5.3.0) and Browser Verification (v5.1.0), and both turned out fine.

5. **"Wait for real user demand."** The Skeptic's ultimate position: do not build it until someone asks. The counter: the roadmap already lists "Sprint planning / tracking" as a recognized gap, and the feature fills a clear workflow gap between prioritization and execution. Building the thin version now (one agent, one skill, 7 config keys) is low-cost enough that the risk of building something nobody uses is bounded by the small implementation scope.

The core critique: the Skeptical Architect is right about the risks but wrong about the magnitude. Every concern they raise is valid at the scale of "building a sprint management system." None of them is fatal at the scale of "one read-only agent that filters a ranked list by capacity, plus tracker field assignment."

---

## What I Would Accept as Compromise

From the Innovative Integrator, I would accept:

1. **Sprint naming pattern as a config key.** A simple `Sprint naming pattern` key (default: `Sprint {YYYY-WW}`) that generates the sprint/milestone name. This is pure string templating, zero complexity, and avoids hardcoding the name format. This is Open Question 1 and should be resolved in MVP.

2. **`--output` flag for the sprint plan report.** Writing the sprint plan table to a markdown file is useful for team review before Gate 4. This is a trivial addition (write formatted output to path) that adds real value for async teams.

3. **Parallel execution as a follow-up.** NOT in MVP, but I would accept it as a v6.5.1 patch if the implementation uses the existing Task tool parallelism pattern (same-tier, no-dependency issues dispatched simultaneously). No new config key --- always on, matching existing `fix-bugs` parallel triage behavior.

From the Skeptical Architect, I would accept:

1. **Deferring `sprint_create` to a follow-up.** MVP assigns to EXISTING sprints/milestones only. This cuts tracker integration scope significantly and aligns with the reality that most teams create sprints in their tracker UI.

2. **Starting with 3 trackers instead of 6.** If implementation budget is tight, ship GitHub + Jira + Gitea (the most common in the user base) with full MCP+Bash support, and add youtrack + linear + redmine in a follow-up patch. The fallback architecture (Tier 3 skip+warn) means partially-supported trackers do not break anything.

3. **No sprint-level metrics aggregation in MVP.** The existing `/metrics` command reads pipeline state files. Let it continue doing that. Sprint-level aggregation ("what was the velocity of sprint X?") is a follow-up that can read sprint state files when it lands.

4. **Hard scope boundary: NO retrospective, NO burndown, NO team management.** These are PM tool features. If any future proposal adds them, that proposal should be rejected. ceos-agents selects issues, assigns them, and executes pipelines. The tracker owns everything else.
