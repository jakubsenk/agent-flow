# Research Agent 2: Workflow Design & Integration

## Semi-Autonomous Workflow Design

### Decision Matrix

| Decision Point | Autonomous Mode | Semi-Autonomous Mode | Rationale |
|----------------|-----------------|----------------------|-----------|
| Issue selection from backlog | AI selects top-N by priority score | AI presents ranked list, human confirms selection | Priority-engine score is auditable but business context (team capacity, strategic goals) cannot be inferred |
| Capacity ceiling (hours/points) | Use static config value | AI suggests based on velocity, human confirms or adjusts | Velocity on cold start is unknown; human must set the first sprint budget |
| Sprint goal statement | Auto-generate from top-3 P0 titles | AI drafts, human approves before pipeline starts | Sprint goal is a communication artifact — it needs human ownership |
| Scope negotiation (add/remove issue) | Not applicable (no negotiation) | Interactive: show plan, accept add/drop per issue | Adding issues mid-sprint without confirmation could silently overflow capacity |
| Decomposition approval per issue | Auto-approved (mirrors `--yolo` in implement-feature step 5) | Wait for confirmation per issue (matches implement-feature step 5 default pattern) | Decomposition changes branch strategy and subtask count — high-stakes decision |
| Unmapped AC in decomposition | Block (matches YOLO behavior in fix-bugs line 188) | Ask: "Continue anyway? [Y/n]" (matches non-YOLO behavior in fix-bugs line 188) | Consistent with existing AC coverage check pattern |
| Start pipeline after plan approval | Auto-start immediately | Show final plan table, require explicit "Start sprint? [Y/n]" | Prevents accidental launch of multi-issue batch |

### Human Interaction Points

The following are concrete interaction moments modeled after existing patterns in the codebase:

1. **Capacity confirmation** — After priority-engine output (step 2), display:
   ```
   Suggested sprint: {N} issues — {total_estimated_effort} effort points
   Team capacity: {configured_value or "unknown"}
   Proceed with this selection? [Y/n]
   ```
   Pattern source: implement-feature step 0c (card preview prompt at line 134-140 in implement-feature SKILL.md).

2. **Decomposition approval per issue** — For each issue where architect recommends decomposition, display the plan table and wait. Pattern source: fix-bugs step 3b (display plan + `Continue? [Y/n]` at line 174). This already halts the pipeline and is non-YOLO safe.

3. **Unmapped AC warning** — For decomposed issues, same as fix-bugs line 188:
   ```
   Continue anyway? The unmapped criteria will not be explicitly addressed. [Y/n]
   ```

4. **Final sprint start gate** — After all per-issue confirmations, display:
   ```
   ## Sprint Plan — {sprint_name}

   | # | Issue | Tier | Effort | Decompose? | Subtasks |
   |---|-------|------|--------|------------|---------|
   ...

   Total effort: ~{N} | Issues: {N} | Est. cost: ~${min}-${max}

   Start sprint? [Y/n]
   ```
   This is the last human gate. Pattern source: implement-feature step 5 decomposition plan display (lines 224-237).

5. **Scope adjustment** — Before the final gate, optionally prompt:
   ```
   Add or remove issues? Enter issue ID to toggle, or press Enter to continue.
   ```
   This is a new interaction not currently present in the codebase; it should follow the same conversational style as the `discuss` skill step 5 (follow-up prompt: `Follow up on any perspective? [agent name / done]`).

### Velocity Cold Start Strategy

**Problem:** No `pipeline.log` events, no `[ceos-agents]` comments, no `/metrics` report → cannot compute `avg_time_to_fix` or historical throughput.

**Proposed approach (three-tier fallback):**

1. **Tier 1 — Historical data available:** Read `./reports/metrics.md` (or Metrics → Output config path). Extract `avg_time_to_fix` and `success_rate`. Derive estimated velocity = `(team_capacity_hours / avg_time_to_fix) × success_rate`.

2. **Tier 2 — Cold start (metrics unavailable):** Fall back to priority-engine effort scores. Each issue effort score 1-5 maps to: 1=0.5h, 2=1h, 3=2h, 4=4h, 5=8h (heuristic, same order-of-magnitude as estimate skill token cost table). Suggest initial sprint = issues whose summed effort ≤ configurable capacity ceiling.

3. **Tier 3 — No capacity configured:** Ask user once at sprint planning start:
   ```
   No team capacity configured and no historical velocity data found.
   Estimated hours available this sprint: [enter number or press Enter to skip capacity check]
   ```
   If skipped, operate without capacity ceiling and show a warning banner in the sprint plan.

**Cold start annotation:** When tier 2 or tier 3 is used, annotate the sprint plan with:
```
⚠ Velocity estimate based on heuristics only — no historical data found.
  Run /ceos-agents:metrics after this sprint to calibrate future planning.
```

This matches the estimate skill step 7 pattern (line 103: "Based on heuristics only").

### Interaction Model

The correct interaction model is **AskUserQuestion / interactive prompts** at specific gates — not continuous supervision. This matches how implement-feature handles decomposition (step 5, lines 224-237): the pipeline pauses, displays a formatted table, and waits for `[Y/n]`. Between gates, execution is fully autonomous.

The `--yolo` flag (introduced in implement-feature) should be supported for CI/automation contexts: when `--yolo` is passed, all human gates are auto-approved and sprint starts immediately. This is consistent with the existing `--yolo` behavior in implement-feature (line 13).

---

## Integration Mapping

### Priority-Engine Integration

**Pattern found:** `skills/prioritize/SKILL.md` runs `ceos-agents:priority-engine` as a Task tool (step 3, line 38) and displays the result. Sprint planning should reuse this exact invocation.

**Two integration options:**

Option A — **Run internally:** Sprint planning skill directly invokes `ceos-agents:priority-engine` via Task tool, same as `/ceos-agents:prioritize` does. Advantage: self-contained, no prerequisite. Disadvantage: duplicates fetch + enrichment logic from `skills/prioritize/SKILL.md` steps 1-2.

Option B — **Require as prerequisite:** Sprint planning reads a cached prioritize output file (from `--output` flag of `/ceos-agents:prioritize`). User must run `/ceos-agents:prioritize --output .ceos-agents/priority.md` first.

**Recommendation: Option A with deduplication.** The sprint planning skill should call `ceos-agents:priority-engine` with the same context-building pattern as `skills/prioritize/SKILL.md` (fetch → enrich → run agent). This avoids a prerequisite step that users will forget. The code in `skills/prioritize/SKILL.md` is only ~50 lines (steps 1-4), so inlining the pattern is not a significant duplication.

**Constraint from priority-engine.md line 65:** Max 50 issues per analysis. Sprint planning inherits this limit. If the backlog exceeds 50, the sprint must be chosen from the top 50 by creation date.

**Priority-engine output reuse:** The `Recommendations` section of priority-engine output (line 58) already contains:
```
- Suggested batch: {top N issues for next /fix-bugs run}
```
Sprint planning should read this field as the initial issue selection and present it as the suggested sprint set.

### Fix-Bugs Relationship

**Fix-bugs is NOT replaced by sprint planning.** Sprint planning is a planning layer that outputs a list of issues and then delegates execution to the existing pipeline. The relationship is:

```
/sprint-plan → issue selection + capacity check → human approval
  → FOR EACH issue: route to /fix-bugs or /implement-feature (per issue type)
```

**Batch processing reuse:** `skills/fix-bugs/SKILL.md` already supports processing N issues in a batch (line 99: `Limit = count from $ARGUMENTS`). Sprint planning does not need to re-implement batch loops; it needs to invoke `fix-bugs` with the approved list.

**Parallelism:** fix-bugs triage is parallel (line 101: "parallel — triage is read-only"). Sprint planning can pass all approved issues to a single `fix-bugs N` call and inherit the parallel triage + sequential fix behavior.

**Key difference from plain `fix-bugs`:** Sprint planning adds a planning gate before execution — capacity check, goal statement, scope negotiation. Plain `fix-bugs` has no such gate.

**Flag compatibility:** Sprint planning should support `--dry-run` (inherited from fix-bugs step 0, line 93-95) to preview the sprint plan without executing the pipeline.

### State Persistence

**Current schema** (`state/schema.md`) is per-issue (`state.json` in `.ceos-agents/{ISSUE-ID}/`). Sprint planning requires cross-issue state.

**Required new fields (not currently in schema):**

A new top-level state file: `.ceos-agents/sprint-{timestamp}/state.json`

Suggested additions to the schema (new RUN-ID type in the table at schema.md lines 22-27):

| Pipeline type | RUN-ID format | Example |
|---------------|--------------|---------|
| Sprint planning run | `sprint-{timestamp}` | `sprint-20260413-143000` |

New schema object for sprint state:

```json
{
  "schema_version": "1.0",
  "run_id": "sprint-20260413-143000",
  "mode": "sprint-planning",
  "pipeline": "sprint-plan",
  "status": "running",
  "started_at": "ISO-8601",
  "updated_at": "ISO-8601",
  "sprint": {
    "goal": "string or null",
    "capacity_hours": null,
    "velocity_source": "historical | heuristic | manual | unconstrained",
    "issues": [
      {
        "issue_id": "PROJ-42",
        "priority_score": 8.5,
        "tier": "P0",
        "effort": 3,
        "type": "bug | feature",
        "child_run_id": "PROJ-42",
        "status": "pending | running | completed | blocked | skipped"
      }
    ],
    "total_effort": null,
    "approved_at": null,
    "started_at": null,
    "completed_issues": 0,
    "blocked_issues": 0
  }
}
```

**`child_run_id`** links to individual `.ceos-agents/{ISSUE-ID}/state.json` for drill-down — analogous to how `parent_run_id` works in schema.md line 36 (scaffold spawning sub-runs).

**No new config section is strictly required** for the first version. The optional `Sprint Planning` config section can be added later (MINOR version bump per versioning policy) with keys: `Capacity hours`, `Sprint duration days`, `Sprint naming pattern`.

### Dashboard/Metrics Visibility

**Dashboard** (`skills/dashboard/SKILL.md`): The pipeline stage inference logic (lines 60-68) derives stage from `[ceos-agents]` comment parsing. Sprint-originated issues produce the same `[ceos-agents]` comment format, so they will appear correctly in the dashboard with no changes.

**Sprint-level aggregation** is NOT currently supported by the dashboard. To add it, a new section "Sprint Progress" would be needed:
- Read `.ceos-agents/sprint-*/state.json` files via Glob
- For each sprint: display goal, issues completed/blocked/pending, capacity used
- This is a MINOR feature addition (new optional section in HTML output)

**Metrics** (`skills/metrics/SKILL.md`): Metrics are computed from `[ceos-agents]` comments and git log (steps 2-3). Sprint issues produce the same artifacts, so per-issue metrics work without changes.

**New sprint-level metric suggestions:**
- `sprint_completion_rate` = completed issues / planned issues
- `sprint_velocity_actual` = sum of effort of completed issues / sprint duration
- These would require reading `.ceos-agents/sprint-*/state.json` — not currently done by metrics skill (it reads only issue tracker comments + git log)

**Recommended approach:** Add sprint metrics as an optional section in the metrics report, guarded by checking whether any `sprint-*` state files exist. This is backward-compatible and follows the existing threshold-based recommendation pattern (metrics skill lines 130-133).

---

## Key Findings & Risks

1. **Reuse existing confirmation patterns directly.** The decomposition plan display + `[Y/n]` prompt (implement-feature step 5, lines 224-237 and fix-bugs line 174) is the right model for every human gate in sprint planning. No new interaction primitives are needed.

2. **`--yolo` flag is essential for CI.** Without it, the sprint plan gate will block all automated runs. Implement it from day one with the same semantics as implement-feature (line 13).

3. **Priority-engine 50-issue cap is a hard limit** (priority-engine.md line 65). Sprint planning cannot plan across more than 50 issues in a single pass. If a team has 200+ open issues, only the oldest 50 are scored. This is a known constraint that should be documented in the sprint planning skill.

4. **No velocity data risk on first sprint.** The effort-heuristic fallback (tier 2) maps effort 1-5 to hours using the same order-of-magnitude as the estimate skill. But these are rough approximations. The sprint planning skill must prominently warn the user (the `⚠` annotation) that the first sprint's capacity estimate is unreliable.

5. **State schema is issue-scoped today.** The cross-issue sprint state file is a new pattern. Care must be taken to follow the same atomic write protocol (`state.json.tmp` → rename, defined in schema.md lines 270-276). The sprint `run_id` format `sprint-{timestamp}` must be added to the RUN-ID table in `state/schema.md`.

6. **Dashboard and metrics work without changes** for individual issue tracking within a sprint. Sprint-level aggregation requires new reading of sprint state files — this is additive and backward-compatible, suitable for a follow-up MINOR version.

7. **Fix-bugs is extended, not replaced.** Sprint planning is a pre-flight orchestrator that calls `fix-bugs` and `implement-feature`. The pipeline execution contracts (batch loop, parallel triage, fixer-reviewer, publisher) remain unchanged.

8. **Architect decomposition affects capacity significantly.** When an issue is decomposed, its effort multiplies by the number of subtasks (up to `decomposition.max_subtasks = 7`). Sprint planning must re-estimate capacity after decomposition approval gates (step 4 in the interaction model), or warn the user that decomposed issues may exceed the capacity ceiling.
