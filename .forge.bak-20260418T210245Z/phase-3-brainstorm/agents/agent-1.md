# Phase 3 Brainstorm — Persona 1: Forge-Parity Consistency Maximalist (Conservative)

## Thesis

v6.8.0 is not a design opportunity — it is a **mirroring exercise**. The roadmap at `docs/plans/roadmap.md:619-716` is ground truth; `core/post-publish-hook.md`, `core/state-manager.md`, and the real forge.json at `.forge.bak-20260417-170848/forge.json` are the reference artifacts. I refuse to invent field names, event granularity rules, or new core/ contracts. Every debate resolves to the same question: what does the reference already do? For Autopilot I copy the MCP pre-flight stanza from `skills/fix-bugs/SKILL.md:80` and the config-reader invocation from `core/config-reader.md`. For Observability Hooks I extend `core/post-publish-hook.md` byte-identically — same `curl --max-time 5 --retry 0`, same heredoc, same advisory-failure clause (`core/post-publish-hook.md:30-33`). For Real-Time Cost Visibility I mirror forge.json 1:1 — field *semantics* and mechanism come from forge, while field *names* defer to the roadmap's explicit `tokens_used` (line 672) because the roadmap is the ceos-agents source of truth. The D10 vs. roadmap payload divergence (Q13) resolves the same way: roadmap wins; D10 delta goes to the roadmap as a follow-up note. Schema_version stays `"1.0"` because `core/state-manager.md` never reads it (Q2/Q11 both HIGH confidence). This persona trades imagination for predictability; the upside is that a future forge↔ceos cross-plugin aggregator ingests both state.json and forge.json with the same parser.

## Item 1: /ceos-agents:autopilot

### Skill structure

File: `skills/autopilot/SKILL.md` (new). Mirrors `skills/fix-bugs/SKILL.md` frontmatter one-for-one. Autopilot IS a user-facing dispatcher, but structurally it dispatches other skills (fix-ticket, implement-feature) and is never invoked by a sub-agent — same pattern as fix-bugs. The roadmap brief (line 628) calls it a "thin dispatcher," which is the fix-bugs archetype. **Therefore `disable-model-invocation: true` matches fix-bugs precedent** (Q12 Part 1 ambiguity resolved via dispatcher-pattern match — Autopilot cannot recurse into itself from an agent).

```
---
name: autopilot
description: Headless batch dispatcher — queries bugs and features, runs fix-ticket or implement-feature per issue, logs results
allowed-tools: mcp__*, Bash, Read, Write, SkillWithClaude, Task
disable-model-invocation: true
argument-hint: "[--dry-run] [--max <N>]"
---

# Autopilot

Headless batch runner. Read Automation Config from CLAUDE.md.

## Configuration

Follow `core/config-reader.md`. Read:
- Type from Issue Tracker (default: youtrack)
- Bug query from Issue Tracker
- Feature query from Feature Workflow section (optional — absent = bug-only mode, silent skip)
- Notifications section (optional)
- Autopilot section (optional — 7 keys, see CLAUDE.md reference)

## Steps

### 0. MCP pre-flight check
(identical to skills/fix-bugs/SKILL.md:80 — copy verbatim, substitute no values)

### 1. Acquire lock
- Path: `.ceos-agents/autopilot.lock` (roadmap line 633 verbatim)
- If file exists:
  - Read `{timestamp}|{hostname}` content
  - If `now - timestamp > Lock timeout` minutes (default 120, roadmap line 634) → stale lock:
    log `[WARN] Stale autopilot lock ({age}min). Removing.`, unlink, continue
  - Else → STOP with "[ceos-agents] Autopilot lock held by {hostname} since {timestamp}. Exit 0."
- Write lock: tmp+rename pattern identical to `core/state-manager.md` Atomic Write Protocol (lines 365–375 of state/schema.md):
  1. Write `{ISO-8601}|{HOSTNAME}` to `.ceos-agents/autopilot.lock.tmp`
  2. Rename to `.ceos-agents/autopilot.lock`
  3. If rename fails: retry once after 100ms; on second failure STOP (not advisory — lock must succeed).

### 2. Query tracker — Bugs first
Use the same MCP query pattern as skills/fix-bugs/SKILL.md Step 1. Apply `Bug limit` (default 0 = no cap).

### 3. Query tracker — Features
If Feature Workflow section present and `Feature query` non-empty: query features. Apply `Feature limit` (default 0 = no cap).
If absent: skip silently (precedent: skills/metrics/SKILL.md:37).

### 4. Classify — Bug-first priority
For every issue ID appearing in BOTH result sets, drop it from the Feature list (roadmap line 633: "bug takes priority on overlap"). Produces two disjoint lists.

### 5. Apply Max issues per run cap
Combine (bugs first, then features), truncate to `Max issues per run` (default 1). Log classification summary to `autopilot.log` (path from config, default `.ceos-agents/autopilot.log`).

### 6. Dispatch loop
For each issue:
- If Dry run = true: append `[DRY] {ID} → {fix-ticket|implement-feature}` to log, continue (NO Skill dispatch, NO lock refresh, NO webhook).
- Else: dispatch via Skill tool:
  - Bug → `ceos-agents:fix-ticket {ID}`
  - Feature → `ceos-agents:implement-feature {ID}`
- Capture result: SUCCESS | BLOCKED | ERROR.
- On ERROR: if `On error = skip` (default) → log, continue. If `stop` → release lock (Step 7), exit.
- On BLOCKED: log, continue (not an Autopilot-level error — the pipeline already commented on the issue).

### 7. Release lock
Delete `.ceos-agents/autopilot.lock`. If deletion fails: log `[WARN] Lock release failed: {err}` and continue (stale-detection in Step 1 will clean it up on next run).

### 8. Emit summary
Append final summary line to log: `{ISO-8601} autopilot run={ID} bugs={N} features={M} success={S} blocked={B} errors={E} duration_s={D}`.
```

### Lock file mechanism

**Path:** `.ceos-agents/autopilot.lock` — hardcoded to roadmap line 633. Not configurable.
**Contents:** `{ISO-8601-timestamp}|{HOSTNAME}` — one line, no JSON overhead (matches the mental model of a POSIX pid-file; parseable by a single split).
**Atomicity on Windows:** Use the `tmp+rename` pattern from `core/state-manager.md:29-30` which explicitly notes "atomic on POSIX; best-effort on Windows." Roadmap does not require hard atomicity for the lock; stale-timestamp detection (120min) is the backstop.
**Stale detection:** Read timestamp, compare to `now()`. If `now - ts > Lock timeout` minutes → overwrite. Prevents zombie locks from crashed cron runs.
**Release:** Step 7 unlinks. On crash: next cron invocation sees stale timestamp, recovers.

### Two-query classification

Bug query first → bug set. Feature query second → feature set. **Overlap:** bug-set ID wins; drop from feature set (roadmap line 633 literal). Single-pass, no re-query. If Feature Workflow section absent: feature set = empty, no warning (option (a) from Q7 — matches silent-skip precedent at `skills/metrics/SKILL.md:37`). If `Feature limit` > 0 but Feature Workflow absent: log `[WARN] Feature limit={N} but no Feature Workflow section — running bug-only mode.` Then continue (non-blocking — Q7 edge case resolved pragmatically).

### Error boundaries

| Failure | Response | Source |
|---|---|---|
| MCP not available (Step 0) | STOP, error message identical to fix-bugs | skills/fix-bugs/SKILL.md:80 |
| Lock acquisition fails (Step 1 write retry) | STOP with log | Lock is the only Autopilot-critical write |
| Per-issue dispatch error | Skip or stop per `On error` config | roadmap line 636 |
| Per-issue BLOCK | Continue (pipeline handled the comment) | Existing block-handler pattern |
| Webhook failure | Log `[WARN]`, continue | core/post-publish-hook.md:30-33 |

### Exact `### Autopilot` config section

```markdown
### Autopilot

| Key | Value |
|-----|-------|
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |
```

All 7 keys and defaults mirror roadmap line 634 verbatim. `Bug limit = 0` and `Feature limit = 0` mean "no cap" (consistent with existing `Max blocked per run = unlimited` interpretation of 0/unlimited). `On error` accepts `skip` or `stop`.

### File changes (additive + pointer updates)

| File | Change | Direction |
|---|---|---|
| `skills/autopilot/SKILL.md` | CREATE new file | +N lines |
| `CLAUDE.md` (plugin) | Skills list: append `/autopilot` after `/sprint-plan`; agents count stays 21; skills count 28→29 | ~6 line edits |
| `CLAUDE.md` (plugin) — Config Contract table | Add row: `Autopilot \| Max issues per run, Lock timeout, Log file, Bug limit, Feature limit, On error, Dry run \| 1, 120, .ceos-agents/autopilot.log, 0, 0, skip, false` | +1 row |
| `core/config-reader.md` | Add 7 dot-notation keys under a new `### Autopilot` parse block: `autopilot.max_issues_per_run`, `autopilot.lock_timeout`, `autopilot.log_file`, `autopilot.bug_limit`, `autopilot.feature_limit`, `autopilot.on_error`, `autopilot.dry_run` | +~15 lines |
| `docs/reference/skills.md` | Add `/autopilot` row | +1 row |
| `docs/reference/pipelines.md` | Add "Autopilot batch dispatch" subsection | +~25 lines |
| `examples/config-templates/*` | Append `### Autopilot` example to 1-2 templates only (github-nextjs.md, gitea-spring-boot.md) as reference; others document "add section if needed" | +~10 lines each |

## Item 2: Observability Hooks (D10)

### Payload schemas

Copy forge's payload-shape discipline (flat JSON, no nested objects) from `.forge.bak-20260417-170848/forge.json` pattern. **Roadmap wins over D10** (Q13): fields come from `roadmap.md:648` (`step_name`, `duration`, `iteration_count`). D10's `tokens_used` and `outcome` are DEFERRED to v6.9.0 to avoid payload-contract churn mid-version. Rationale: roadmap is the ceos-agents contract; D10 is an external recommendation that has already been reconciled into the roadmap — the roadmap author made an explicit selection when writing line 648, and I respect that selection.

```json
// pipeline-started
{
  "event": "pipeline-started",
  "run_id": "PROJ-42",
  "pipeline": "fix-ticket",
  "issue_id": "PROJ-42",
  "timestamp": "2026-04-17T14:30:00Z"
}

// step-completed
{
  "event": "step-completed",
  "run_id": "PROJ-42",
  "step_name": "fixer_reviewer",
  "duration": 360,
  "iteration_count": 3,
  "timestamp": "2026-04-17T14:40:00Z"
}

// pipeline-completed
{
  "event": "pipeline-completed",
  "run_id": "PROJ-42",
  "status": "completed",
  "duration": 692,
  "pr_url": "https://gitea.example.com/owner/repo/pull/99",
  "timestamp": "2026-04-17T14:42:00Z"
}
```

`duration` is in whole seconds (matches forge.json's per-phase `duration_ms` semantic but seconds-scale for payload brevity; the stored state.json keeps `duration_ms` for forge-parity — see Item 3). Consumer computes ms from seconds if needed; we follow the roadmap's word (`duration` unit-unspecified ⇒ seconds, mirroring `phase_complete` event in state/schema.md:386 which uses `duration_s`).

### Event granularity decision

**Top-level stages only** — one `step-completed` per named pipeline stage, NOT per fixer-reviewer iteration. Justification (Q6 synthesis):
1. Roadmap line 648 includes `iteration_count` as a field — only meaningful as a summary if one event = one stage.
2. Roadmap line 677 prose: "accumulate across iterations (fix.iterations: 3, fix.tokens_used: 135000)" — single cumulative row.
3. `pipeline.log` already carries `fixer_iteration` events (state/schema.md:389) for per-iteration internal resolution. Webhook layer = external consumers, coarser grain.

`step-skipped` is **NOT a new event** in v6.8.0. When a stage is skipped (profile or config), no webhook fires. Rationale: v6.7.x `pr-created` and `issue-blocked` never fired "skipped" events; consistency wins. Consumers reconcile skip state from the missing event + `pipeline-completed` final summary (DEFERRED to v6.9.0 if D10 consumers demand it).

Stage enum for `step_name` (canonical — derived from state/schema.md top-level field names):
- `triage`, `code_analysis`, `reproduction`, `fixer_reviewer`, `decomposition`, `test`, `e2e_test`, `browser_verification`, `acceptance_gate`, `publisher`

### Fire sites per skill

| Skill | Fire site |
|---|---|
| `skills/fix-ticket/SKILL.md` | `pipeline-started` right after Step 0 MCP pre-flight succeeds; `step-completed` at the end of each of Steps 3/4/5/6/7/8/9 (when stage reaches `completed`); `pipeline-completed` after Step 11 publisher success |
| `skills/fix-bugs/SKILL.md` | Same as fix-ticket, PER ISSUE in the dispatch loop. Batch-level summary is the existing fix-bugs log output, no new event. |
| `skills/implement-feature/SKILL.md` | Same pattern — spec-analyst, architect, fixer_reviewer, test, publisher stages |
| `skills/scaffold/SKILL.md` | `pipeline-started` after Step 0-INFRA/0-MCP; `step-completed` for spec-writer, scaffolder, validate, architect, fixer_reviewer, test, e2e; `pipeline-completed` after final report |
| `skills/autopilot/SKILL.md` | **Autopilot does NOT emit pipeline-started or pipeline-completed** for itself. The dispatched child skills emit those per-issue. Autopilot-level batch events are DEFERRED to v6.9.0. |

### core/ refactor decision: **EXTEND `core/post-publish-hook.md`; do NOT create `core/pipeline-events.md`**

Justification:
1. The curl invocation at `core/post-publish-hook.md:17-22` is 4 lines and already contains the canonical `--max-time 5 --retry 0` heredoc pattern. Copying the same pattern to a new file creates drift risk (two curl snippets to keep in sync).
2. `core/post-publish-hook.md:30-33` already documents advisory-failure semantics. New events inherit this; documenting it twice is a maintenance liability.
3. The roadmap (line 650) explicitly lists `core/post-publish-hook.md` as the file to touch, not a new file.
4. Rename risk: renaming `core/post-publish-hook.md` to `core/pipeline-events.md` is a MAJOR change (any consumer grep of core/ contracts breaks).

Concrete edit: rename the "Purpose" in `core/post-publish-hook.md` from "Execute post-publish hooks and fire webhooks after PR creation" to "Execute pipeline hooks and fire webhooks at stage boundaries." Add a new Step 4 that generalizes the Step 3 curl pattern: "If `{event_name}` is in On events: fire webhook with payload `{event_name, ...}` using the same curl pattern as Step 3." The contract is now general.

### CLAUDE.md Notifications update

New accepted `On events` tokens (append to existing `pr-created`, `issue-blocked`, `reproduce`, `verify`):
- `pipeline-started`
- `step-completed`
- `pipeline-completed`

Example config:
```
### Notifications
| Key | Value |
|-----|-------|
| Webhook URL | https://grafana.example.com/ceos-hook |
| On events | pr-created, pipeline-started, step-completed, pipeline-completed |
```

### Backward compat

Fully preserved. Existing `pr-created` fires exactly as before (post-publish-hook.md:16 is unchanged). `issue-blocked` (core/block-handler.md:39-43) is unchanged. Users with v6.7.2 Notifications config see no behavioral change. Users who add the 3 new events get them. Zero breaking change — MINOR bump correct (roadmap line 651).

## Item 3: Real-Time Cost Visibility

### State.json field additions

Per-stage usage object (applied additively to triage, code_analysis, fixer_reviewer, reproduction, test, e2e_test, browser_verification, acceptance_gate, publisher):

```json
"triage": {
  "status": "completed",
  "severity": "MEDIUM",
  "area": "auth",
  "complexity": "M",
  "acceptance_criteria": [...],
  "reproduction_steps": null,
  "ac_source": "triage-analyst",
  "model": "sonnet",
  "tokens_used": 12500,
  "duration_ms": 45000,
  "tool_uses": 8,
  "started_at": "2026-04-17T14:30:05Z",
  "completed_at": "2026-04-17T14:30:50Z"
}
```

Rationale for field NAMES: roadmap line 672 uses `tokens_used`; I adopt that as canonical for state.json writes. The MECHANISM is byte-identical to forge (`total_tokens` captured from Task tool → stored), but the stored name matches the roadmap prose. This does create a rename between forge.json (`tokens_estimated`) and state.json (`tokens_used`) — acceptable cost because the roadmap's `tokens_used` better reflects ceos-agents reality (Task tool returns real token counts, not estimates) and the cross-plugin consumer can map via a small dictionary.

Top-level `pipeline` accumulator (new):

```json
"pipeline": {
  "total_tokens": 250700,
  "total_duration_ms": 692000,
  "total_tool_uses": 183
}
```

Names mirror roadmap line 678: `total_tokens`, `total_duration_ms`, `total_tool_uses`. (Forge uses `total_tokens_estimated` + `total_duration_ms` — 2 of 2 fields match exactly; only the `_estimated` suffix diverges, same rationale.)

### state/schema.md update

Add these rows to the field definition tables:

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `triage.model` | string or null | No | `null` | Agent model used (`sonnet`, `opus`, `haiku`). |
| `triage.tokens_used` | integer or null | No | `null` | Tokens consumed by this stage (cumulative across iterations where applicable). |
| `triage.duration_ms` | integer or null | No | `null` | Wall-clock duration in milliseconds. |
| `triage.tool_uses` | integer or null | No | `null` | Count of tool invocations during this stage. |
| `triage.started_at` | ISO 8601 string or null | No | `null` | Stage start timestamp. |
| `triage.completed_at` | ISO 8601 string or null | No | `null` | Stage completion timestamp. |
| `pipeline` | object or null | No | `null` | Top-level usage accumulator. Written at pipeline end. |
| `pipeline.total_tokens` | integer | No | `0` | Sum of per-stage `tokens_used`. |
| `pipeline.total_duration_ms` | integer | No | `0` | Sum of per-stage `duration_ms`. |
| `pipeline.total_tool_uses` | integer | No | `0` | Sum of per-stage `tool_uses`. |

Repeat the six per-stage rows for: `code_analysis`, `reproduction`, `fixer_reviewer`, `test`, `e2e_test`, `browser_verification`, `acceptance_gate`, `publisher`. Update the Full Schema Example (state/schema.md:33-141) to include the new fields on each stage; null values in the example for clarity.

### Schema version — **stay at "1.0"**

Justification (Q2 HIGH confidence): 
1. `state/schema.md:148` declares `schema_version` as "Always `\"1.0\"` for this specification" — the spec itself says do not advance for this schema.
2. `core/state-manager.md` has no version negotiation (Read Process lines 34-35 returns raw parsed JSON; Write Process uses merge-update).
3. `skills/resume-ticket/SKILL.md:19` uses `plugin_version` as "advisory only, never block" — no schema_version check anywhere.
4. Additions are 100% additive. v6.7.x readers receive `null`/absent; v6.8.0 readers receive values. No backward-compat logic needed.
5. Roadmap line 714 explicitly classifies as "PATCH (informational output, no contract change)" — advancing schema_version would be a contract change signal.

### Task-tool usage capture pseudocode

Every agent dispatch in every pipeline skill:

```
# Before dispatch:
state_write("{stage}.status", "in_progress")
state_write("{stage}.started_at", ISO8601_NOW)
state_write("{stage}.model", "{agent.model_from_frontmatter}")

# Dispatch:
result = Task(subagent_type="{agent-name}", prompt="...")

# After dispatch — capture usage from result:
state_write("{stage}.tokens_used", result.usage.total_tokens)
state_write("{stage}.duration_ms", result.usage.duration_ms)
state_write("{stage}.tool_uses", result.usage.tool_uses)
state_write("{stage}.completed_at", ISO8601_NOW)
state_write("{stage}.status", "completed")
```

Field names on the Task tool result (`result.usage.total_tokens`, etc.) follow the roadmap's Q1 statement (line 656) — if the Task tool at runtime actually returns `tokens_estimated` (as forge writes it), the skill transcribes to `tokens_used` on write. One capture pattern, one rename at the boundary. If runtime inspection later reveals the Task tool returns neither name, Phase 4 spec will add a `getattr(result.usage, 'total_tokens', None) ?? getattr(result.usage, 'tokens_estimated', None)` normalization line — non-breaking.

### Fixer-reviewer loop accumulation

Cumulative mechanism (roadmap line 677 verbatim):

```
# Initialize once at loop entry:
fixer_tokens_accumulator = 0
fixer_duration_accumulator = 0
fixer_tool_uses_accumulator = 0

# In each iteration:
fixer_result = Task("fixer", ...)
fixer_tokens_accumulator += fixer_result.usage.total_tokens
fixer_duration_accumulator += fixer_result.usage.duration_ms
fixer_tool_uses_accumulator += fixer_result.usage.tool_uses

reviewer_result = Task("reviewer", ...)
fixer_tokens_accumulator += reviewer_result.usage.total_tokens
...

# After loop exits (APPROVED or max iterations):
state_write("fixer_reviewer.tokens_used", fixer_tokens_accumulator)
state_write("fixer_reviewer.duration_ms", fixer_duration_accumulator)
state_write("fixer_reviewer.tool_uses", fixer_tool_uses_accumulator)
state_write("fixer_reviewer.iterations", iteration_count)
```

Fixer and reviewer costs combined into single `fixer_reviewer.*` sum (matches existing schema — there is no separate `reviewer` stage object). Pipeline summary table (below) DECOMPOSES the sum into `fixer (×N)` and `reviewer (×N)` rows for display, but storage is combined.

### Pipeline summary table

**When:** at pipeline end, right after `pipeline.total_tokens` is written (after publisher success or at block point).
**Where:** appended to (1) `.ceos-agents/{RUN-ID}/pipeline.log` as a multi-line comment-style entry; (2) the final skill output text to the user; NOT in the PR body (keeps PR body clean; monitoring ingestors read state.json).
**Format:** roadmap lines 680-690 verbatim (markdown table with columns `Stage | Model | Tokens | Duration | Tools`). Decompose `fixer_reviewer` into `fixer (×N)` and `reviewer (×N)` rows assuming 50/50 split is WRONG — instead report combined as single row `fixer_reviewer (×N) | opus | {sum} | {sum} | {sum}`. Roadmap's 50/50 display is illustrative; we report actual stored data only.

### /metrics aggregation update — dual-mode strategy

`skills/metrics/SKILL.md` Step 6 currently uses hardcoded constants (`sonnet ~30k`, `opus ~50k`, `haiku ~5k` — line 79). New dual-mode read (Q12 Part 2):

```
# For each issue in the period:
state_path = ".ceos-agents/{ISSUE_ID}/state.json"
if exists(state_path):
  state = read_json(state_path)
  if state.get("pipeline", {}).get("total_tokens"):
    issue_tokens = state["pipeline"]["total_tokens"]
    issue_duration = state["pipeline"]["total_duration_ms"] / 1000
    source = "measured"
  else:
    # v6.7.x state file or mid-pipeline — fall back to heuristic
    issue_tokens = heuristic_estimate(state)
    source = "estimated"
else:
  # No state.json at all (older runs) — fall back to heuristic
  issue_tokens = count_stages * model_constants
  source = "estimated"

# Report aggregates with a "source breakdown" footer:
# "Data sources: measured = {X} issues, estimated = {Y} issues"
```

New output columns in the report: `Avg tokens (measured) | Avg tokens (estimated)` side-by-side during transition period. DEFERRED: a pure-measured report once all archived runs age out (likely v6.9.0 cleanup).

## Trade-offs

**What my conservatism costs:**
1. **Field-name friction with forge.** state.json stores `tokens_used`; forge.json stores `tokens_estimated`. A future forge↔ceos cross-plugin aggregator needs a 3-row rename dictionary. An Innovator persona might unify on one name; I refuse because the roadmap's explicit `tokens_used` wording (line 672) wins.
2. **No richer payload = less consumer value.** External dashboards that want `tokens_used` per step-completed event (D10 original ask) will have to read state.json separately via a side channel. This pushes complexity to the consumer. My answer: consumers of real-time events want low-latency signals, not full accounting — full accounting is post-hoc from state.json. Roadmap agrees at line 648.
3. **No step-skipped event = ambiguous stage transitions.** A consumer counting `step-completed` events cannot tell whether a stage was skipped or still running. My answer: `pipeline-completed` carries final status; consumers reconcile. Adding `step-skipped` in v6.8.1 is a non-breaking MINOR addition.
4. **No Autopilot-level batch events.** Dashboards cannot distinguish a scheduled batch run from a single-issue human run. My answer: per-issue `pipeline-started` events with distinct `run_id`s provide enough signal; a batch-correlation ID (like forge's top-level `id`) is a v6.9.0 feature.
5. **`disable-model-invocation: true` on Autopilot may surprise users** who type `/autopilot` interactively and expect it to also be dispatchable from a `/discuss` conversation. Fix-bugs has the same pattern; precedent consistency wins.

## Explicit Deferrals (NOT IN SCOPE for v6.8.0)

1. **`step-skipped` webhook event** — not mentioned by the roadmap; add in v6.8.1 if dashboard consumers need it.
2. **D10 enriched payload** (`tokens_used`, `outcome` on `step-completed`) — roadmap explicitly chose the simpler payload at line 648; revisit in v6.9.0 after real consumer feedback.
3. **Autopilot-level batch events** (`autopilot-started`, `autopilot-completed`, batch `run_id` correlation) — not in roadmap line 628-644; defer.
4. **Per-iteration token breakdown array** in `fixer_reviewer` — Q9 confirmed HIGH that cumulative is canonical; per-iteration breakdown is NOT planned.
5. **Renaming state.json stage fields to match forge.json** (`tokens_used`→`tokens_estimated`) — would be a backward-compat concern even though roadmap classifies as PATCH; respect the roadmap's word.
6. **`--format json` on /metrics** — Innovator's idea; not in v6.8.0 roadmap scope; add in v6.9.0.
7. **Schema version bump** — see Item 3 justification; stays `"1.0"`.
8. **`core/pipeline-events.md`** new file — see Item 2 decision; extend `core/post-publish-hook.md` instead.

## Synthesis Input

**The single most valuable element the judge should take from this proposal:** the **core/ refactor decision — EXTEND post-publish-hook.md, do NOT create a new pipeline-events.md**. This is the decision that locks in low blast radius: the roadmap's own file list (line 650) names `core/post-publish-hook.md`, the advisory-failure contract is already documented once (lines 30-33), and the curl pattern exists as a canonical 4-line snippet (lines 17-22). An Innovator persona will want to create a dedicated events contract for aesthetic/architectural reasons; a Skeptic will wrestle with rename risk. My persona says: the contract is already general-purpose, just rename the Purpose line and add a Step 4 — one edit, zero new files, zero rename concerns. This also locks down that the three new events inherit the advisory-only failure clause WITHOUT a separate discussion — the clause is right there in the existing file they're reading.

Second-most valuable: **keep schema_version at "1.0"** — Q2 and Q11 are both HIGH confidence, roadmap line 714 explicitly says PATCH, state-manager never reads the field. Any proposal to bump is a solution in search of a problem.

---

# 150-Word Summary

Conservative persona proposes byte-identical mirroring of existing references: Autopilot copies the fix-bugs dispatcher pattern (including `disable-model-invocation: true`), lock file lives at `.ceos-agents/autopilot.lock` with 120min stale detection per roadmap line 633. Observability Hooks EXTEND `core/post-publish-hook.md` (do NOT create `core/pipeline-events.md`) — one curl pattern, one advisory-failure clause, roadmap payload (`step_name, duration, iteration_count`) wins over D10 enriched payload; top-level stage granularity only. Cost Visibility mirrors forge.json 1:1 in mechanism but uses `tokens_used` (roadmap word) not `tokens_estimated` (forge word) for state.json names; schema_version stays `"1.0"`. Biggest trade-off: Autopilot-level batch events and D10 enriched payload are deferred, so dashboards have a coarser view. Most confident element: EXTEND `core/post-publish-hook.md` — the file is 33 lines, the contract is already general-purpose, renaming or duplicating it creates drift risk with zero upside.
