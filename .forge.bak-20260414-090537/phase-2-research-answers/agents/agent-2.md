# Phase 2 Research Answers — Workflow & Integration (Agent 2)

**Role:** DevOps Automation Architect
**Date:** 2026-04-13
**Scope:** Semi-autonomous workflow design, priority-engine integration, sprint state.json schema, execution decision, cold-start velocity algorithm

---

## 1. Exact Semi-Autonomous Workflow (Numbered Steps with Gate Descriptions)

The workflow has two distinct phases: **Planning Phase** (steps 1–8) and **Execution Phase** (step 9). Every human gate uses the established `[Y/n]` prompt pattern already present in `fix-bugs` and `implement-feature`.

```
1. MCP pre-flight check
2. Config & Sprint Planning section validation
3. Fetch open issues via MCP
4. Run priority-engine → ranked list
5. Run sprint-planner → capacity-fitted plan
   [GATE 1: Capacity confirmation]
6. Scope adjustment opportunity (interactive issue toggle)
   [GATE 5: Scope adjustment — optional]
7. Per-issue decomposition analysis (for issues architect recommends decomposing)
   [GATE 2: Decomposition plan approval — per decomposable issue]
   [GATE 3: Unmapped AC warning — per decomposed issue with gaps]
8. Final sprint plan display
   [GATE 4: "Start sprint? [Y/n]"]
9. Execution: dispatch fix-bugs / implement-feature per issue type
   (OR: write sprint assignments only, if Mode: suggest)
```

### Step-by-Step Detail

**Step 1 — MCP pre-flight check**
Pattern: identical to all pipeline skills (`core/mcp-preflight.md`). Read `Issue Tracker → Type`, verify at least one `mcp__*` tool matching the tracker type is accessible. On failure: STOP with standard MCP error message. No `--yolo` exception here — without tracker access there is nothing to plan.

**Step 2 — Config validation**
Read `## Automation Config`. Check that `### Sprint Planning` section exists. If absent: STOP with "Sprint Planning config not found. Add `### Sprint Planning` section to Automation Config or run `/ceos-agents:check-setup`." (This is a hard stop, not a soft warning — consistent with how `fix-bugs` handles missing required Issue Tracker config, and with the Config Validity Gate pattern in `implement-feature` step 0b.) Also apply Config Validity Gate (implement-feature pattern, step 0b): scan all required Automation Config sections for `<!-- TODO:` or `<...>` placeholders.

**Step 3 — Fetch open issues**
Via MCP server. Apply `Bug query` + `Feature query` (if configured in `Feature Workflow` section). Filter by `Include types` (default: `bug, feature`). Filter out issues with labels in `Exclude labels`. Cap at `Max issues` (default: 20). The hard ceiling from priority-engine is 50 issues (priority-engine.md line 65: "Max 50 issues per analysis"); `Max issues` config default of 20 is intentionally below this ceiling.

**Step 4 — Run priority-engine (opus)**
Pattern: mirrors `skills/prioritize/SKILL.md` step 3 — `run ceos-agents:priority-engine (Task tool, model: opus)`. Pass: issue list enriched with historical data (if `./reports/metrics.md` exists). Output: ranked tables `P0/P1/P2` with per-issue `Impact`, `Risk`, `Effort`, `Score`, `Rationale`, and a `Suggested batch` recommendation. The `Suggested batch` field (priority-engine.md line 58) is the initial sprint selection input to step 5.

**Step 5 — Run sprint-planner (sonnet)**
Pass: priority-engine output (ranked list + scores) + Sprint Planning config keys (`Sprint duration`, `Team capacity`, `Velocity target`, `Capacity unit`, `Max issues`). Sprint-planner applies capacity constraints and produces the sprint plan table. The skill does NOT delegate capacity-fitting to the model via freeform reasoning — the sprint-planner agent does it via structured arithmetic (walk ranked list, accumulate effort sizes, stop at ceiling).

**Gate 1 — Capacity confirmation** (after step 5, before step 6):
```
Suggested sprint: {N} issues — {total_estimated_effort} effort points
Team capacity: {configured_value or "unknown"}
Velocity source: {historical | heuristic | manual | unconstrained}
Proceed with this selection? [Y/n]
```
Pattern source: implement-feature step 0c (card preview prompt, `implement-feature/SKILL.md` lines 134-140). `--yolo` auto-approves. If user answers N: prompt for manual capacity override and re-run sprint-planner, or stop.

**Step 6 — Scope adjustment (Gate 5)**
Display the capacity-fitted plan table. Prompt:
```
Add or remove issues? Enter issue ID to toggle, or press Enter to continue.
```
This prompt repeats until the user presses Enter without input. On each toggle: re-run sprint-planner capacity check (not full priority-engine re-run — use cached scores). `--yolo` skips entirely. Note: this is a new interaction pattern not present elsewhere in ceos-agents. Its inclusion in MVP is a design decision (see Section 5 below).

**Step 7 — Per-issue decomposition gates (Gates 2 and 3)**
For each issue in the final selection where sprint-planner flags `decompose_recommended: true` (based on priority-engine `Effort >= 4` or `Risk = HIGH`):

Gate 2 — Display decomposition plan table, wait for `Continue? [Y/n]`. Pattern: `fix-bugs/SKILL.md` step 3b (display plan, wait for confirmation at the equivalent of line 174). `--yolo` auto-approves.

Gate 3 — If decomposition plan has unmapped AC: "Continue anyway? The unmapped criteria will not be explicitly addressed. [Y/n]". Pattern: `fix-bugs/SKILL.md` step 3b AC coverage check (equivalent of line 188). `--yolo` BLOCKS (does not auto-approve) — consistent with the `--yolo` behavior in `implement-feature/SKILL.md` line 215 ("If mode is YOLO → Block").

After Gate 2 approval, re-compute total effort: decomposed issue effort becomes `effort × subtask_count`. Update the sprint plan table. Re-check capacity ceiling. If the post-decomposition total exceeds capacity: warn the user and offer to remove the decomposed issue from the sprint.

**Gate 4 — Final sprint start gate** (after all decomposition gates):
```
## Sprint Plan — {sprint_name}

| # | Issue | Tier | Effort | Decompose? | Subtasks |
|---|-------|------|--------|------------|---------|
| 1 | PROJ-42: Fix login | P0 | 3 | No | — |
| 2 | PROJ-38: Add API auth | P1 | 5 | Yes (3 subtasks) | spec, impl, test |
...

Total effort: ~{N} | Issues: {N} | Est. cost: ~${min}-${max}
Velocity source: {historical | heuristic | manual | unconstrained}

Start sprint? [Y/n]
```
Pattern source: implement-feature step 5 decomposition plan display (`implement-feature/SKILL.md` lines 224-237). `--yolo` auto-approves. If user answers N: stop, no tracker writes, no execution.

**Step 9 — Execution dispatch (or sprint assignment only)**
See Section 4 (Key Design Decision) for the full analysis. The concrete answer: `sprint-plan` dispatches execution. See that section for the routing logic between `fix-bugs` and `implement-feature`.

---

## 2. How Priority-Engine Output Feeds Into Sprint Planning

### Specific Output Fields Used

Priority-engine produces a structured markdown output (priority-engine.md lines 36-60). The sprint-planner agent consumes these specific fields:

**From the P0/P1/P2 tables (one row per issue):**
- `Issue` — the `{ID}: {title}` column → used to populate the sprint plan table
- `Impact` — the `/5` score → used in sprint-planner's capacity-fit rationale
- `Risk` — the `/5` score → if `Risk = 5/5`, sprint-planner flags this issue as `decompose_recommended: true`
- `Effort` — the `/5` score → PRIMARY field for capacity fitting; sprint-planner maps this to hours/points (see cold-start velocity algorithm, Section 5)
- `Score` — the computed priority score → sprint-planner preserves sort order from priority-engine; it does NOT re-rank
- `Rationale` — the 1-sentence explanation → passed through verbatim to the sprint plan table

**From the `### Dependencies` section:**
- `{issue_A} → blocks → {issue_B}` graph → sprint-planner checks: if issue B is in plan and issue A is not, add issue A to plan (or flag B as at-risk if capacity is full)

**From the `### Recommendations` section:**
- `Suggested batch: {top N issues for next /fix-bugs run}` (priority-engine.md line 58) → used as the initial sprint selection passed to sprint-planner. Sprint-planner may trim this list further based on capacity constraints.
- `Estimated cost for batch: ~${min}-${max}` → passed through to Gate 4 display as `Est. cost`

### What Sprint-Planner Adds on Top of Priority-Engine

Priority-engine is a pure ranker. Sprint-planner adds:
1. Capacity ceiling enforcement (effort accumulation algorithm)
2. Size derivation when no `Estimation field` is configured (complexity → story points mapping)
3. `decompose_recommended` flag per issue
4. Sprint-specific metadata: `sprint_name`, `velocity_source`, `total_effort`
5. Post-decomposition effort re-computation

Priority-engine is NEVER re-run after Gate 1 — its scores are cached in-memory. Only sprint-planner is re-invoked when the user toggles issues during scope adjustment.

---

## 3. Sprint State.json Schema (Complete JSON)

This is a new RUN-ID type. The schema follows the atomic write protocol from `state/schema.md` lines 270-276 (write to `.tmp`, rename atomically).

**New RUN-ID table row** to add to `state/schema.md` RUN-ID Determination table (after line 27):

| Pipeline type | RUN-ID format | Example |
|---|---|---|
| Sprint planning run | `sprint-{timestamp}` | `sprint-20260413-143000` |

**Complete state.json:**

```json
{
  "schema_version": "1.0",
  "run_id": "sprint-20260413-143000",
  "parent_run_id": null,
  "mode": "sprint-planning",
  "pipeline": "sprint-plan",
  "status": "running",
  "started_at": "2026-04-13T14:30:00Z",
  "updated_at": "2026-04-13T14:35:00Z",
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
    "goal": null,
    "duration": "2 weeks",
    "capacity_unit": "story-points",
    "capacity_configured": 40,
    "velocity_target": 35,
    "effective_capacity": 35,
    "velocity_source": "historical",
    "approved_at": null,
    "started_at": null,
    "issues": [
      {
        "issue_id": "PROJ-42",
        "title": "Fix login redirect loop",
        "priority_score": 9.5,
        "tier": "P0",
        "effort_score": 2,
        "effort_hours": 1.0,
        "effort_points": 2,
        "type": "bug",
        "decompose_recommended": false,
        "subtask_count": null,
        "post_decomp_effort": null,
        "sprint_assigned": false,
        "child_run_id": null,
        "status": "pending"
      },
      {
        "issue_id": "PROJ-38",
        "title": "Add OAuth2 authentication",
        "priority_score": 7.2,
        "tier": "P1",
        "effort_score": 4,
        "effort_hours": 4.0,
        "effort_points": 5,
        "type": "feature",
        "decompose_recommended": true,
        "subtask_count": 3,
        "post_decomp_effort": 12,
        "sprint_assigned": false,
        "child_run_id": null,
        "status": "pending"
      }
    ],
    "total_effort_pre_decomp": 7,
    "total_effort_post_decomp": 14,
    "completed_issues": 0,
    "blocked_issues": 0,
    "skipped_issues": 0
  },
  "gates": {
    "capacity_confirmed": false,
    "scope_adjusted": false,
    "sprint_started": false
  },
  "sprint_assignment": {
    "status": "pending",
    "mode": "apply",
    "tracker_sprint_id": null,
    "tracker_sprint_name": null,
    "assigned_count": 0,
    "failed_count": 0
  },
  "block": null
}
```

### Field Definitions

| Field | Type | Description |
|---|---|---|
| `sprint.name` | string or null | Sprint/milestone/cycle name. Generated from `Sprint naming pattern` config key if present; otherwise `Sprint {YYYY-WW}`. |
| `sprint.goal` | string or null | Sprint goal text (human-authored at Gate 1 or null if not provided). |
| `sprint.effective_capacity` | int or null | `min(capacity_configured, velocity_target)`. Null when both are absent (unconstrained mode). |
| `sprint.velocity_source` | string | One of: `"historical"` (from metrics.md), `"heuristic"` (effort scores), `"manual"` (user input at Gate 3), `"unconstrained"` (no capacity data). |
| `sprint.issues[].effort_score` | int | Raw effort score from priority-engine (1-5). |
| `sprint.issues[].effort_hours` | float | Derived hours: 1→0.5h, 2→1h, 3→2h, 4→4h, 5→8h. |
| `sprint.issues[].effort_points` | int | Derived story points: XS=1, S=2, M=3, L=5 (from triage complexity if available; else from effort_score map: 1→1, 2→2, 3→3, 4→5, 5→8). |
| `sprint.issues[].decompose_recommended` | bool | `true` if sprint-planner flags this issue for decomposition (effort_score >= 4 OR priority-engine Risk = 5). |
| `sprint.issues[].subtask_count` | int or null | Number of subtasks after decomposition approval. Null until Gate 2 approved. |
| `sprint.issues[].post_decomp_effort` | int or null | `effort_points × subtask_count`. Null until Gate 2 approved. |
| `sprint.issues[].sprint_assigned` | bool | Whether tracker sprint field was successfully written (applies only to `Mode: apply`). |
| `sprint.issues[].child_run_id` | string or null | Set to the issue ID (e.g., `"PROJ-42"`) once the fix/feature pipeline is launched. Links to `.ceos-agents/{ISSUE-ID}/state.json`. Mirrors the `parent_run_id` pattern in `state/schema.md` line 36. |
| `sprint.issues[].status` | string | `pending`, `running`, `completed`, `blocked`, `skipped`. Updated as execution progresses. |
| `gates.capacity_confirmed` | bool | Whether Gate 1 was passed. |
| `gates.scope_adjusted` | bool | Whether Gate 5 was used (user toggled issues). |
| `gates.sprint_started` | bool | Whether Gate 4 "Start sprint? [Y/n]" was confirmed. |
| `sprint_assignment.mode` | string | `"suggest"` or `"apply"`. |
| `sprint_assignment.tracker_sprint_id` | string or null | Resolved sprint/milestone/cycle ID in the tracker. |
| `sprint_assignment.assigned_count` | int | Number of issues successfully assigned to sprint in tracker. |
| `sprint_assignment.failed_count` | int | Number of issues where sprint assignment failed (both MCP and REST fallback failed). |

### State Update Points

Following the atomic write protocol (`state/schema.md` lines 270-276: write to `.json.tmp`, rename atomically):

1. After step 2 (config validation): write initial state with `status: "running"`, all `pending`.
2. After Gate 1 confirmed: set `gates.capacity_confirmed: true`, write issue list with effort scores.
3. After each Gate 2 (decomposition): update `sprint.issues[].subtask_count`, `post_decomp_effort`, `sprint.total_effort_post_decomp`.
4. After Gate 4 confirmed: set `gates.sprint_started: true`, `sprint.approved_at`.
5. After each sprint assignment write: update `sprint.issues[].sprint_assigned`, `sprint_assignment.assigned_count/failed_count`.
6. As each child pipeline starts: set `sprint.issues[].child_run_id`, `status: "running"`.
7. As each child pipeline completes/blocks: update `sprint.issues[].status`, increment `sprint.completed_issues/blocked_issues`.
8. On pipeline completion: set top-level `status: "completed"`.

---

## 4. Key Design Decision: Does sprint-plan Launch Execution?

**Decision: YES — sprint-plan dispatches execution after Gate 4 confirmation.**

### Reasoning

The Phase 1 document frames this as an open question (section 9, question N/A — addressed in the workflow matrix). The reasoning for launching execution is:

1. **Existing batch execution model is fix-bugs.** `fix-bugs/SKILL.md` step 1 already accepts `N` as an argument and processes N issues in batch (line 99: `Limit = count from $ARGUMENTS`). Sprint planning is a pre-flight gate that routes to this exact mechanism. Without launching execution, the user must manually construct the command after planning — defeating the purpose of an integrated sprint tool.

2. **Gate 4 is an explicit "Start sprint?" confirmation.** This gate is not ambiguous. It is the last human gate before any code changes happen. Its purpose is precisely to separate the planning ceremony from the execution commitment. Once confirmed, there is no reason to stop short of launching.

3. **`--dry-run` provides the plan-without-execution path.** Users who want only a recommendation without launching execution pass `--dry-run`. This stops after Gate 4 display (no tracker writes, no pipeline launch). The `--dry-run` pattern already exists in both `fix-bugs/SKILL.md` (step 0, line 93) and `implement-feature/SKILL.md` (step 0 dry-run check, line 90-95). Sprint planning inherits this pattern.

4. **`--yolo` auto-approves the start gate.** CI pipelines that want fully automated sprint execution can use `--yolo`. This matches the `--yolo` behavior documented in `implement-feature/SKILL.md` line 13: "auto-approve decomposition plan, auto-approve result display, auto-publish after successful pipeline."

### Execution Routing Logic

After Gate 4 is confirmed:

```
FOR EACH issue IN sprint.issues (in tier order: P0 first, then P1, then P2):

  IF issue.type == "bug":
    // Route to fix-bugs — but one issue at a time (not batch),
    // to preserve per-issue state tracking and child_run_id linkage
    INVOKE ceos-agents:fix-ticket {issue_id}
      [with --profile if sprint config specifies a profile]
      [with --decompose if issue.decompose_recommended == true AND Gate 2 was approved]
    SET sprint.issues[].child_run_id = issue_id
    SET sprint.issues[].status = "running"
    UPDATE state.json (atomic write)
    AWAIT completion
    READ .ceos-agents/{issue_id}/state.json → check top-level status
    IF status == "completed": increment sprint.completed_issues
    IF status == "blocked": increment sprint.blocked_issues
    UPDATE sprint.issues[].status accordingly
    UPDATE state.json (atomic write)

  IF issue.type == "feature":
    INVOKE ceos-agents:implement-feature {issue_id}
      [with --decompose if issue.decompose_recommended == true AND Gate 2 was approved]
    // Same state tracking as above
```

Note: `fix-ticket` (single-issue pipeline) is used per issue rather than `fix-bugs N` (batch), because:
- Sprint state needs `child_run_id` linkage to individual `.ceos-agents/{ISSUE-ID}/state.json` files
- Per-issue status tracking (`sprint.issues[].status`) requires knowing when each issue completes/blocks
- `fix-bugs` batch processing is parallelized at triage (line 101: "parallel — triage is read-only") but sequential at fix. Sprint planning can exploit the same parallelism by dispatching multiple `fix-ticket` calls in parallel via the Task tool for P0 issues.

**Parallelism rule:** Bug issues in the same tier (P0 or P1) with no dependency relationship (per priority-engine `### Dependencies` section) may be dispatched in parallel via simultaneous Task calls. Issues with dependencies must be serialized (dependency first). This matches the pattern in `fix-bugs/SKILL.md` step 2 (parallel triage) and step 4+ (sequential fix).

### Mode: suggest (no execution launch)

When `Mode: suggest` AND `--apply` is NOT passed:
- After Gate 4: write sprint assignments to tracker only (no pipeline launch)
- Display: "Sprint plan created. Run `/ceos-agents:fix-bugs {N}` or `/ceos-agents:implement-feature {ISSUE-ID}` to begin implementation."
- Write sprint state with `gates.sprint_started: true` but `sprint.issues[].status` all remaining `"pending"`.

This is the safe default. Users who want execution must either configure `Mode: apply` or pass `--apply` explicitly.

---

## 5. Cold-Start Velocity Algorithm with Formulas

### Tier Determination

The algorithm first determines which tier applies:

```
IF ./reports/metrics.md exists (or Metrics → Output path from config):
    READ avg_time_to_fix (hours) from metrics report
    READ success_rate (decimal, e.g. 0.75) from metrics report
    SET velocity_source = "historical"
    GOTO Tier 1

ELSE IF Team capacity is configured in Sprint Planning section:
    SET velocity_source = "heuristic"
    GOTO Tier 2

ELSE:
    SET velocity_source = "manual" (if user answers) OR "unconstrained" (if user skips)
    GOTO Tier 3
```

### Tier 1 — Historical Data (from /metrics output)

```
// Source: metrics/SKILL.md step 4 output fields
avg_time_to_fix_hours = extracted from metrics report "Avg time to fix" row
success_rate = extracted from "Issues fixed" percentage row
// e.g.: avg_time_to_fix_hours = 6.5, success_rate = 0.75

// Capacity unit: hours
sprint_duration_hours = parse_duration(Sprint duration config)
  // "2 weeks" → 80 work hours (5 days × 8h × 2 weeks)
  // "1 week" → 40h, "3 weeks" → 120h, "4 weeks" → 160h

team_capacity_hours = Team capacity config (if Capacity unit = hours)
                    OR Team capacity × 8 (if Capacity unit = story-points, assuming 8h/point)
                    // fallback if Team capacity is absent: team_capacity_hours = sprint_duration_hours

effective_capacity_hours = min(team_capacity_hours, sprint_duration_hours)

// Issues that fit in the sprint:
max_issues = floor(effective_capacity_hours / avg_time_to_fix_hours × success_rate)
// Example: floor(80 / 6.5 × 0.75) = floor(9.2) = 9 issues

// Capacity points for effort-score accumulation:
avg_points_per_issue = floor(effective_capacity_hours / avg_time_to_fix_hours)
// Used as denominator for capacity ceiling in sprint-planner
```

**Story-points mode:**
```
// When Capacity unit = story-points:
team_capacity_points = Team capacity config (e.g., 40)
velocity_target_points = Velocity target config (e.g., 35)
effective_capacity = min(team_capacity_points, velocity_target_points)
// Use effort_score → story_points mapping below to accumulate
```

### Tier 2 — Heuristic (Cold Start, no metrics)

Effort score from priority-engine (1–5) maps to both hours and story-points:

```
EFFORT_TO_HOURS = {1: 0.5, 2: 1.0, 3: 2.0, 4: 4.0, 5: 8.0}
EFFORT_TO_POINTS = {1: 1, 2: 2, 3: 3, 4: 5, 5: 8}
// Note: points use Fibonacci-adjacent progression (1,2,3,5,8) consistent with
// triage complexity map in Phase 1 doc: "XS=1, S=2, M=3, L=5"
// (Effort 5 extends to 8 because no complexity L+ exists in triage output)

// If Estimation field is configured in Sprint Planning: read actual story points from tracker
// If Estimation field is absent AND triage complexity is available from [ceos-agents] comment:
//   XS → 1 point, S → 2 points, M → 3 points, L → 5 points (exact Phase 1 doc mapping)
//   priority-engine Effort score is NOT used when triage complexity is available
// If neither: use EFFORT_TO_POINTS mapping above

// Capacity ceiling:
IF Capacity unit == "hours":
    capacity = Team capacity (hours config)
    for each issue in ranked list:
        issue_cost = EFFORT_TO_HOURS[issue.effort_score]
        IF accumulated_cost + issue_cost <= capacity × 1.1:  // 10% rounding buffer (≤ Phase 1's "20% own-size" buffer simplified)
            include issue
            accumulated_cost += issue_cost
        ELSE:
            overflow_issues.append(issue)

IF Capacity unit == "story-points":
    capacity = min(Team capacity, Velocity target) if both set; else whichever is present
    for each issue in ranked list:
        issue_cost = EFFORT_TO_POINTS[issue.effort_score]
        // Overflow buffer: issue included if it would overflow by <= 20% of its own size
        // (Phase 1 doc, sprint-planner Process step 5: "≤20% of their own size may be included")
        overflow_threshold = issue_cost × 0.2
        IF accumulated_cost + issue_cost <= capacity + overflow_threshold:
            include issue
            accumulated_cost += issue_cost
        ELSE:
            overflow_issues.append(issue)
```

### Tier 3 — Manual Prompt (No capacity configured, no metrics)

```
// Prompt once at start of step 5:
DISPLAY:
  "No team capacity configured and no historical velocity data found."
  "Estimated hours available this sprint: [enter number or press Enter to skip capacity check]"

IF user enters a number N:
    SET team_capacity_hours = N
    SET velocity_source = "manual"
    APPLY Tier 2 formula with EFFORT_TO_HOURS mapping and N as capacity

IF user presses Enter (skips):
    SET velocity_source = "unconstrained"
    SET effective_capacity = null
    SELECT top min(Max issues, 20) from ranked list
    // No accumulation — just take top-N by priority score
```

### Cold-Start Annotation (Tiers 2 and 3)

Applied to the sprint plan output at every gate where the plan is displayed:

```
Warning: Velocity estimate based on {heuristic estimates | manual input} — no historical data found.
  Run /ceos-agents:metrics after this sprint to calibrate future planning.
```

Pattern source: Phase 1 doc section 2 "Cold-start annotation" — matches `estimate` skill's "Based on heuristics only" warning pattern (referenced in Phase 1 final.md line 152).

### Complexity → Effort Mapping (from triage comments)

When `[ceos-agents] Triage completed. ... Complexity: {X}.` comments exist in the tracker:

```
// Read from tracker comment regex (dashboard/SKILL.md line 47):
// ^\[ceos-agents\] Triage completed\. Severity: (.+)\. Area: (.+)\.$
// NOTE: Complexity field added in same comment format per state/schema.md triage.complexity

COMPLEXITY_TO_HOURS = {"XS": 2.0, "S": 4.0, "M": 8.0, "L": 16.0}
COMPLEXITY_TO_POINTS = {"XS": 1, "S": 2, "M": 3, "L": 5}
// Exact mapping from Phase 1 doc sprint-planner Process step 3
```

This takes precedence over priority-engine effort scores when available, because triage-analyst complexity has been validated against actual code (code-analyst runs before triage output, giving more signal than priority-engine's effort estimation from issue description alone).

---

## 6. Integration with dashboard and metrics

### Dashboard (skills/dashboard/SKILL.md)

No changes required for MVP. Sprint-originated issues produce identical `[ceos-agents]` block comment format — they appear correctly in existing stage inference logic (`dashboard/SKILL.md` lines 60-68). The `child_run_id` link in sprint state enables drill-down but does not require dashboard changes.

Sprint-level aggregation (sprint goal, issues completed/blocked/pending per sprint) requires reading `.ceos-agents/sprint-*/state.json`. This is out of scope for the MVP sprint and should be tracked as a follow-up MINOR release item. The architecture supports it without schema changes.

### Metrics (skills/metrics/SKILL.md)

Per-issue metrics work unchanged — same `[ceos-agents]` comments, same git log parsing (metrics/SKILL.md steps 2-3). No metrics.md changes needed for MVP.

New sprint-level metrics (`sprint_completion_rate`, `sprint_velocity_actual`) require reading sprint state files. The guard condition: check whether any `.ceos-agents/sprint-*/state.json` files exist before attempting sprint-level computation. This is backward-compatible (existing installations without sprint state get identical metrics output). Defer to follow-up MINOR release.

---

## 7. Source File References

| File | Relevant Lines | Used For |
|---|---|---|
| `skills/implement-feature/SKILL.md` | 13, 90-95, 134-140, 215, 224-237 | `--yolo` behavior, dry-run gate, Gate 1 pattern, YOLO-blocks-on-unmapped-AC, decomposition plan display |
| `skills/fix-bugs/SKILL.md` | 93-95, 99, 101, 174, 188 | dry-run gate, batch limit arg, parallel triage, decomposition confirmation gate, unmapped AC warning gate |
| `agents/priority-engine.md` | 26-29, 36-60, 65 | Score formula, output format with all fields, 50-issue hard limit |
| `state/schema.md` | 22-27, 36, 270-276 | RUN-ID format table, parent_run_id pattern, atomic write protocol |
| `skills/dashboard/SKILL.md` | 60-68 | Stage inference — sprint issues appear without dashboard changes |
| `skills/metrics/SKILL.md` | 64-68 | Metric computation — per-issue metrics work unchanged |
| `skills/prioritize/SKILL.md` | 38-41 | Exact Task tool invocation pattern for priority-engine |
