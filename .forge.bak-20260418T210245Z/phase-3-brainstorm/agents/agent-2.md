# Phase 3 Brainstorm — Persona 2: External-Consumer-First Innovator

## Thesis

Every design decision in v6.8.0 is a **contract with a consumer I have not met yet** — the Grafana dashboard, the Datadog ingester, the on-call runbook, the SRE team's cron monitor, the forge ↔ ceos joint metrics aggregator shipped in v6.9.0. If I emit a minimum-viable payload today and a consumer later asks "can I correlate this ceos pipeline with the forge run that spawned it?" — I have to ship a v6.8.1 payload field addition, which every parser must re-tolerate. That is a silent breaking change for strict consumers.

My rule: **the observability contract is the hardest surface to evolve in a plugin ecosystem**, so future-proof now. The roadmap is a floor, not a ceiling. Forge-parity is a *starting* schema, not a *stopping* schema — ceos-agents has richer runtime signals (AC fulfillment, iteration verdicts, block semantics, model tiers, dispatcher lineage) that consumers will want. We add the fields today, document them, and never pay a migration tax.

I also refuse to make consumers parse markdown tables. If `/metrics` emits a pretty markdown report as its sole output, every ingester writes a brittle regex. A structured `pipeline-summary.json` (or `--format json` on `/metrics`) is the contract a serious consumer expects.

---

## Item 1: `/ceos-agents:autopilot`

### Skill structure

File: `skills/autopilot/SKILL.md`. Frontmatter:

```yaml
---
name: autopilot
description: Headless dispatcher - queries tracker for bugs+features, classifies, runs fix-ticket or implement-feature sequentially with lock-file concurrency guard
allowed-tools: mcp__*, Read, Glob, Grep, Bash, Skill
argument-hint: "[--dry-run] [--max-issues N] [--bug-only] [--feature-only]"
---
```

**Decision on `disable-model-invocation`:** **NO flag.** Autopilot is a user/cron entry point — same class as `/dashboard`, `/metrics`, `/analyze-bug`. The dispatcher-vs-entry-point split in Q12 resolves on the entry axis: a human (or cron wrapper) invokes autopilot; autopilot invokes dispatchers. We do not want autopilot to be auto-invoked by the model itself mid-conversation.

**Steps (high level):**
- Step 0 — MCP pre-flight + config read (Autopilot section optional; absence = feature defaults to 1 bug/run)
- Step 1 — Lock acquisition (skill-owned, see below)
- Step 2 — Fire `autopilot-started` webhook (batch-level event, distinct from per-issue `pipeline-started`)
- Step 3 — Two-query classification + ordering
- Step 4 — Per-issue dispatch loop (Skill tool → fix-ticket or implement-feature)
- Step 5 — Aggregate per-run summary (write `.ceos-agents/autopilot-{timestamp}/summary.json`)
- Step 6 — Fire `autopilot-completed` webhook with aggregate counts
- Step 7 — Release lock (deferred cleanup step so step-N failures still release)

### Lock file mechanism

**Location:** `.ceos-agents/autopilot.lock`. **Ownership: the skill creates it, not the CLI invoker.** Step 1 does three things atomically-as-possible on Windows:

1. Read existing lock (if present). Lock content (JSON, one line): `{"pid": <int>, "hostname": "<str>", "started_at": "<ISO8601>", "run_id": "autopilot-<timestamp>"}`.
2. If lock exists and `(now - started_at) < Lock timeout minutes`: ABORT with exit message `Autopilot already running: run_id={run_id}, started {N}min ago`. Fire `autopilot-aborted` webhook with `reason: "lock_held"`.
3. If absent OR stale: write lock using the state-manager atomic tmp-rename protocol (`autopilot.lock.tmp` → `autopilot.lock`). Same-filesystem rename works on Windows NTFS.

**Stale detection:** `Lock timeout` config key (default 120 minutes) — any lock older than this is presumed crashed. **Windows caveat:** I do not use OS-level file locks; the atomic rename-based write + staleness-window is sufficient for a single-runner cron use case. Document explicitly: concurrent runners on the same filesystem require an external mutex (out of scope).

**Release:** Step 7 deletes the lock. If Steps 2–6 error, a `trap`-style cleanup (documented as Step 7a: "always executes, even on abort") removes the lock. If the process is killed with `kill -9`, the lock stays — the staleness window is the backstop.

### Two-query classification

Ordering rule (roadmap line 633 — bug takes priority on overlap):

1. Run Bug query via MCP. Collect set `B`.
2. Run Feature query via MCP (if `Feature Workflow → Feature query` configured). Collect set `F`.
3. **Overlap resolution:** for any issue in `B ∩ F`, it dispatches as a bug. (Bug wins — consistent with roadmap.)
4. Ordering: `B` first (all bugs), then `F \ B` (features not already processed as bugs).
5. Trim: per-type limits (`Bug limit`, `Feature limit` — 0 = unlimited from that type) then global limit (`Max issues per run`).

**Feature Workflow absence decision (Q7):** emit `[WARN] Feature query not configured; running bug-only mode` when `Feature Workflow` section is absent AND `Feature limit > 0` was set, otherwise silent. This is the "consumer-first" answer: if the operator explicitly asked for 5 features and there is no query, they deserve a log line — not a silent misunderstanding.

### Error boundaries

| Failure | Behavior | Webhook fired |
|---------|----------|---------------|
| MCP unavailable (Step 0) | STOP. Exit with check-setup hint. | None (pre-observability). |
| Lock held (Step 1) | ABORT. Exit with message. | `autopilot-aborted` (reason: `lock_held`). |
| Lock write fails (Step 1) | STOP. | `autopilot-aborted` (reason: `lock_write_failure`). |
| Bug query fails (Step 3) | STOP (can't classify safely). | `autopilot-aborted` (reason: `classification_failure`). |
| Per-issue fix-ticket fails | Per `On error` config: `skip` (default) → log + continue; `stop` → halt remaining; `block` → stop + post batch-block comment. | Per-issue `pipeline-completed` event with `outcome: "failed"`; batch continues or halts. |
| Lock release fails (Step 7) | Log `[WARN]`, continue. | Advisory. |

### Exact `### Autopilot` config section — 8 keys

I propose **one additional key beyond the roadmap's 7**: `Summary output` (path override for the machine-readable aggregate). Consumer need: a dashboard pulling the summary from a shared NFS path needs to know where autopilot writes; cron wrappers need the path to publish to S3.

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
| Summary output | .ceos-agents/autopilot-{timestamp}/summary.json |
```

**Dry run semantics (Q8):** FULL SHORT-CIRCUIT. Dry-run emits a classification list to stdout and exits. No lock file. No state.json. No webhooks. Rationale: cron safety — if dry-run created a lock, a parallel production cron invocation would false-positive. Webhooks for non-existent pipeline runs confuse dashboards. This is the only semantically safe choice for a headless dispatcher.

### File changes

- `skills/autopilot/SKILL.md` — NEW
- `CLAUDE.md` lines 138–156 — add Autopilot row to optional-sections table: `| Autopilot | Max issues per run, Lock timeout, Log file, Bug limit, Feature limit, On error, Dry run, Summary output | 1, 120, .ceos-agents/autopilot.log, 0, 0, skip, false, auto-path |`
- `core/config-reader.md` — add 8 keys under `### Autopilot`: `autopilot.max_issues_per_run`, `autopilot.lock_timeout`, `autopilot.log_file`, `autopilot.bug_limit`, `autopilot.feature_limit`, `autopilot.on_error`, `autopilot.dry_run`, `autopilot.summary_output`
- `docs/reference/skills.md` — add autopilot entry (skill count 28 → 29)
- `docs/reference/config.md` — add section doc
- `skills/workflow-router/SKILL.md` — add intent row for "autopilot" / "headless run" / "cron"

### `/metrics` `--format json` flag

Already present in `skills/metrics/SKILL.md:5` frontmatter (`--format <md|json>`) per Step 7 line 125. **Ensure the JSON output includes**: `success_rate`, `avg_time_to_fix`, `block_by_stage` (as object), `top_block_reasons` (as array of `{reason, count}`), `per_agent` (as object keyed by agent name with nested `{invocations, blocks, success_rate, top_failure}`), `token_cost_total`, `token_cost_by_model`, `period_days`, `generated_at`. This JSON is the contract for external ingesters — markdown is for humans only.

---

## Item 2: Observability Hooks (D10)

### Event granularity decision

**Per-top-level-stage, NOT per-fixer-iteration** for `step-completed`. Rationale (Q6): the roadmap includes `iteration_count` as a stage-level summary field, which is redundant if events fire per iteration. Per-iteration granularity would fire 3–5 events for a typical fix, overwhelming webhook consumers without adding signal.

BUT — **add a `fixer-iteration-completed` event as a separate, OPT-IN token in the `On events` list**. Consumers who want per-iteration resolution (a fixer-health dashboard, a fixer-churn alert) can opt in. Default `On events` does NOT include it — preserves cost for the majority of consumers.

**Skipped stages:** DO fire `step-skipped` event. Consumer need: a dashboard showing which profiles skipped which stages needs a skip signal, not absence-of-event. Also opt-in token in `On events` (default OFF).

### Payload schemas — RICHER than the roadmap minimum

All payloads share a **common envelope** (6 fields) + event-specific fields. Common envelope:

```json
{
  "event": "<event-name>",
  "schema_version": "1.0",
  "ceos_agents_version": "6.8.0",
  "timestamp": "2026-04-17T14:30:00Z",
  "run_id": "PROJ-42",
  "issue_id": "PROJ-42"
}
```

**Why `schema_version` on the payload** (separate from state.json's `schema_version`): consumers need to branch on payload shape evolution without reading state.json. This is the single most important future-proofing field; consumers upgrade at different speeds than producers.

**`pipeline-started`:**
```json
{
  "...envelope": "...",
  "event": "pipeline-started",
  "pipeline": "fix-ticket",
  "mode": "code-bugfix",
  "parent_run_id": null,
  "profile": "default",
  "flags": []
}
```

Non-roadmap fields with consumer rationale:
- `parent_run_id` — **correlation** to scaffold-spawned or autopilot-spawned runs. Dashboard panel: "Pipelines triggered by this autopilot run."
- `profile` — **filter/facet** by pipeline profile (hotfix vs. full). Alert: "Hotfix profile error rate > X".
- `flags` — **debug tag** for --yolo or --dry-run style runs. Correlation: distinguish test runs from production runs.

**`step-completed`:**
```json
{
  "...envelope": "...",
  "event": "step-completed",
  "step_name": "fixer_reviewer",
  "phase": "fix",
  "duration_ms": 360000,
  "iteration_count": 3,
  "iteration_index_of_N": "3/5",
  "tokens_used": 135000,
  "tool_uses": 102,
  "model_used": "opus",
  "tool_uses_by_type": {"Read": 42, "Edit": 28, "Bash": 18, "Grep": 14},
  "outcome": "completed",
  "blocked": false,
  "previous_stage_duration_ms": 62000,
  "parent_agent": null
}
```

Non-roadmap fields with consumer rationale:
- `phase` (from D10) — coarser category than `step_name` for dashboards that group `fix` + `review` under a single panel. D10 explicitly requires this.
- `iteration_index_of_N` — **progress indicator** ("3/5 on this ticket") for a live dashboard. `iteration_count` alone is cumulative; index_of_N signals how close to the retry ceiling we are.
- `tokens_used` (from D10) — **cost panel**. D10 explicit requirement.
- `tool_uses_by_type` — **tool-churn detection**. Alert: "Fixer invoked Bash 50+ times" = runaway pipeline.
- `model_used` — **cost-per-model aggregation**. Answer "what % of spend is opus?" without cross-referencing agent definitions.
- `outcome` (from D10) — `completed|blocked|skipped|failed`. D10 explicit requirement.
- `blocked: bool` — **triage urgency**. On-call needs a boolean faster than parsing outcome string.
- `previous_stage_duration_ms` — **stage-to-stage handoff latency** panel. Detect queue delays if agents are rate-limited.
- `parent_agent` — correlation to the dispatcher (e.g., autopilot → fix-ticket → fixer chain). Null if top-level.

**`pipeline-completed`:**
```json
{
  "...envelope": "...",
  "event": "pipeline-completed",
  "pipeline": "fix-ticket",
  "status": "completed",
  "outcome": "completed",
  "total_duration_ms": 692000,
  "total_tokens": 250700,
  "total_tool_uses": 183,
  "tokens_by_model": {"opus": 201000, "sonnet": 46500, "haiku": 3200},
  "iteration_counts": {"fixer_reviewer": 3, "test": 1},
  "pr_url": "https://gitea/owner/repo/pulls/99",
  "blocked_at": null,
  "stages_completed": ["triage", "code_analysis", "fixer_reviewer", "test", "publisher"],
  "stages_skipped": []
}
```

Non-roadmap rationale:
- `tokens_by_model` — **spend panel**. Directly feeds `/metrics` cost estimation.
- `iteration_counts` — **retry-churn aggregation**. Alert on fixer loops hitting retry ceiling.
- `blocked_at` — if status=blocked, which stage? Panel: "Block rate by stage."
- `stages_completed` / `stages_skipped` — **coverage audit**. Who profiles away quality stages?

**`autopilot-started`** (NEW, batch-level):
```json
{
  "...envelope": "...",
  "event": "autopilot-started",
  "run_id": "autopilot-20260417-143000",
  "bugs_queued": 3,
  "features_queued": 2,
  "max_issues": 1,
  "dry_run": false
}
```

**`autopilot-completed`** (NEW, batch-level):
```json
{
  "...envelope": "...",
  "event": "autopilot-completed",
  "run_id": "autopilot-20260417-143000",
  "issues_processed": 3,
  "issues_succeeded": 2,
  "issues_failed": 1,
  "issues_blocked": 0,
  "total_duration_ms": 1850000,
  "total_tokens": 620000,
  "summary_path": ".ceos-agents/autopilot-20260417-143000/summary.json"
}
```

Consumer rationale: dashboards need batch context — a dashboard that cannot distinguish "one autopilot run processed 5 issues" from "5 independent one-off runs" is blind to autopilot health.

### Fire sites

| Event | File | Location |
|-------|------|----------|
| `pipeline-started` | `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md` | Step 0 (after state.json init, before first agent dispatch). Invoke `core/pipeline-events.md` fire helper. |
| `step-completed` | same | After each phase_complete (post state.json update). |
| `step-skipped` | same | After each phase_skip. |
| `fixer-iteration-completed` | `core/fixer-reviewer-loop.md` | After each reviewer verdict (inside the loop). |
| `pipeline-completed` | same | Final step, before skill exit. |
| `autopilot-started` | `skills/autopilot/SKILL.md` | Step 2. |
| `autopilot-completed` | `skills/autopilot/SKILL.md` | Step 6. |
| `pr-created` (existing) | `core/post-publish-hook.md` | Unchanged. |
| `issue-blocked` (existing) | `core/block-handler.md` | Unchanged. |

### core/ refactor decision: REFACTOR into new `core/pipeline-events.md`

**Why refactor, not extend:** the existing `core/post-publish-hook.md` is domain-scoped (post-publish lifecycle) and mixes hooks + custom agents + webhooks. Adding pipeline-wide events would overload the contract. Cleaner: extract a dedicated event-fire helper.

New file `core/pipeline-events.md`:
- Input: `event_name`, `payload_fields` (object), `config.notifications`
- Process: check `On events` list contains `event_name`; if yes, construct envelope + merge fields, fire curl (copy pattern: `--max-time 5 --retry 0`, heredoc for JSON-safe quoting, advisory on failure), log `[WARN]` on non-2xx.
- Output: no return value; advisory.

`core/post-publish-hook.md` and `core/block-handler.md` DELEGATE to `core/pipeline-events.md` for webhook-firing, keeping their domain logic (hook execution, state transition) intact. Backward compat: existing events (`pr-created`, `issue-blocked`) fire through the same helper — payload shape unchanged from v6.7.x.

### CLAUDE.md Notifications update

Update `CLAUDE.md` Notifications row + the detailed section:

Old: `Notifications | Webhook URL, On events`
New: `Notifications | Webhook URL, On events, Payload schema version | (none), (none), 1.0`

New `On events` tokens: `pipeline-started`, `step-completed`, `step-skipped`, `pipeline-completed`, `fixer-iteration-completed`, `autopilot-started`, `autopilot-completed`, `autopilot-aborted`. Existing: `pr-created`, `issue-blocked`. Default if omitted: `[pr-created, issue-blocked]` — no behavior change for existing users.

### Backward compat

- `pr-created` payload: unchanged (existing consumers continue to work).
- `issue-blocked` payload: unchanged.
- `core/post-publish-hook.md` and `core/block-handler.md` line-level contracts: preserved (only the curl block is refactored to delegate).
- If `Notifications.On events` is absent: default to `[pr-created, issue-blocked]` (v6.7.x behavior) — new events only fire when explicitly listed.
- **Payload `schema_version: "1.0"`** signals future evolution without breaking parsers. Consumers match on `schema_version` first, field-level second.

---

## Item 3: Real-Time Cost Visibility

### State.json field additions — richer than roadmap

**Canonical stored field name: `tokens_used`** (not `tokens_estimated`). Rationale: ceos-agents captures the Task tool's actual usage return, not a pre-run estimate. Calling it "estimated" when it is actually measured would mislead consumers. Forge uses "estimated" for its own historical reasons; we do not inherit that naming mistake. This is consumer-facing terminology — honesty matters. (If the Task tool returns `total_tokens`, the skill writes `tokens_used: <that value>`; field-name mapping lives in the skill layer, not exposed to consumers.)

**Per-stage additions (applied to: `triage`, `code_analysis`, `reproduction`, `fixer_reviewer`, `test`, `e2e_test`, `browser_verification`, `acceptance_gate`, `publisher`, `deployment`):**

```json
{
  "triage": {
    "status": "completed",
    "severity": "HIGH",
    ...existing fields,
    "tokens_used": 12500,
    "duration_ms": 45000,
    "tool_uses": 8,
    "tool_uses_by_type": {"Read": 5, "Grep": 3},
    "model": "sonnet",
    "started_at": "2026-04-17T14:30:00Z",
    "completed_at": "2026-04-17T14:30:45Z",
    "retry_count": 0,
    "parent_agent": null
  }
}
```

Non-roadmap fields (richer than roadmap lines 704–708):
- `tool_uses_by_type` — per-tool breakdown (Read: N, Edit: M, Bash: K). Consumer need: `/metrics` tool-churn analysis; detecting fixer instability via Bash-heavy iterations.
- `retry_count` — for `fixer_reviewer`, tracks reviewer REQUEST_CHANGES count (distinct from `iterations` which is per-cycle). For `test`, tracks test-engineer retries. Observability into retry churn by stage.
- `parent_agent` — which dispatcher invoked this stage (e.g., fixer's parent_agent is the skill; architect's parent_agent within decomposition is the architect coordinator). Enables invocation-chain analysis.

**Top-level `pipeline` accumulator:**

```json
{
  "pipeline": {
    "total_tokens": 250700,
    "total_duration_ms": 692000,
    "total_tool_uses": 183,
    "tokens_by_model": {"opus": 201000, "sonnet": 46500, "haiku": 3200},
    "stages_executed": ["triage", "code_analysis", "fixer_reviewer", "test", "publisher"],
    "stages_skipped": [],
    "first_stage_at": "2026-04-17T14:30:00Z",
    "last_stage_at": "2026-04-17T14:41:32Z"
  }
}
```

Non-roadmap rationale: `tokens_by_model` is the single most-requested `/metrics` aggregation (cost-per-model). Computing it at write time beats forcing every consumer to parse per-stage and regroup.

### state/schema.md update

Add ~15 field-definition rows (per-stage fields × 10 stages, plus pipeline accumulator × 8 fields). Add a dedicated subsection `### Per-Stage Usage Fields` that defines the common shape once and references it from each stage section. Add `### Pipeline Accumulator Object` with the full table. Update the Full Schema Example (lines 33–141) to include usage fields in each stage object and a new `pipeline` top-level block.

### Schema version — stay at `"1.0"`

**Decision: stay at `"1.0"`** per Q2 HIGH confidence. Additive writes with null-tolerance read paths do not change the contract — `/resume-ticket` ignores unknown fields; absent fields return null. Bumping to 1.1 or 2.0 would signal a breakage that does not exist and force every consumer to recompute version matching.

BUT — **add a top-level `schema_capabilities` array** (NEW idea): `["cost_tracking", "pipeline_accumulator", "per_stage_timing", "tool_uses_by_type", "autopilot_runs"]`. Consumers that want to know "is this state.json rich enough to feed my dashboard?" query this array instead of parsing `schema_version`. Capabilities are additive and composable — a cleaner evolution model than integer-versioned schemas. This is the innovator's answer to schema evolution: capability flags over version numbers.

### Task-tool usage capture pseudocode

In each pipeline skill at Task dispatch sites:

```
before_dispatch:
  stage_started_at = ISO8601(now)
  write_state(field_path="<stage>.started_at", value=stage_started_at)
  write_state(field_path="<stage>.status", value="in_progress")
  emit_event("step-started", {...})  # optional, behind flag

result = Task(agent=..., context=...)

after_dispatch:
  stage_completed_at = ISO8601(now)
  tokens = result.usage.total_tokens or 0
  duration_ms = result.usage.duration_ms or (now - stage_started_at).ms
  tool_uses = result.usage.tool_uses or 0
  tool_uses_by_type = result.usage.tool_uses_by_type or {}

  write_state_batch({
    "<stage>.tokens_used": tokens,
    "<stage>.duration_ms": duration_ms,
    "<stage>.tool_uses": tool_uses,
    "<stage>.tool_uses_by_type": tool_uses_by_type,
    "<stage>.model": <agent.model>,
    "<stage>.completed_at": stage_completed_at,
    "<stage>.parent_agent": <caller.name>,
    "<stage>.status": "completed"
  })

  update_pipeline_accumulator(tokens, duration_ms, tool_uses, agent.model, stage_name)

  emit_event("step-completed", {...all fields...})
```

**If the Task tool does NOT return usage metadata** (Q1 unresolved): write zeros, add a top-level `pipeline.usage_source: "task_tool" | "estimated" | "unavailable"` flag. Consumers branch on this. Another capability flag, essentially.

### Fixer-reviewer accumulation

Cumulative per roadmap line 677 — `fixer_reviewer.tokens_used` is the sum across all iterations. Plus (innovator addition): `fixer_reviewer.iteration_breakdown` — an OPTIONAL array of per-iteration `{tokens, duration_ms, verdict}` records, behind a config flag `Cost Visibility → Per-iteration breakdown: true|false` (default false).

Consumer need: forensic analysis of a fixer loop that burned 200k tokens — which iteration was the culprit? Default OFF to avoid bloating state.json for normal runs. Power users and debug dashboards opt in.

### Pipeline summary — propose `pipeline-summary.json`

**YES — ship a structured summary artifact alongside `pipeline.log`.** Path: `.ceos-agents/{RUN-ID}/pipeline-summary.json`. Written at pipeline end by each pipeline skill. Contents: a flattened consumable-for-dashboards view of the state.json usage fields:

```json
{
  "run_id": "PROJ-42",
  "pipeline": "fix-ticket",
  "status": "completed",
  "started_at": "...",
  "completed_at": "...",
  "total_duration_ms": 692000,
  "total_tokens": 250700,
  "total_tool_uses": 183,
  "tokens_by_model": {"opus": 201000, "sonnet": 46500, "haiku": 3200},
  "stages": [
    {"name": "triage", "model": "sonnet", "tokens": 12500, "duration_ms": 45000, "tool_uses": 8, "iterations": 1, "outcome": "completed"},
    {"name": "fixer_reviewer", "model": "opus", "tokens": 135000, "duration_ms": 360000, "tool_uses": 102, "iterations": 3, "outcome": "completed"},
    ...
  ],
  "pr_url": "...",
  "blocked_at": null
}
```

This is the contract for dashboards, CI reporting, and PR comment enrichment. **Consumers should never parse markdown tables or state.json directly** — `pipeline-summary.json` is the public API. The markdown table still goes into `pipeline.log` for human tailing and into the PR body template.

### /metrics aggregation — true state.json-reading mode

Today `/metrics` uses hardcoded heuristics (line 79: `sonnet ~30k, opus ~50k, haiku ~5k`). Consumer-first: aggregate ACTUAL tokens from `pipeline-summary.json` files across the `.ceos-agents/` directory for the period window. Dual-mode:

- **Step 5.5 (NEW): State-json aggregation mode.** Glob `.ceos-agents/*/pipeline-summary.json` for files created in the period. Sum `total_tokens`, group by `model`, compute per-agent averages from the `stages` array.
- **Step 6: Fall-back heuristic** only for runs without `pipeline-summary.json` (legacy v6.7.x or in-flight runs). Report dual counts: `estimated_tokens_legacy` vs. `actual_tokens_measured`.

Add output fields (`--format json`): `tokens_by_run`, `tokens_by_model`, `tokens_by_agent`, `duration_by_stage_avg_ms`, `tool_uses_by_agent_avg`, `data_source: "measured" | "estimated" | "mixed"`. Dashboard consumers branch on `data_source` to warn "partial data" when mixed.

---

## Trade-offs

| Trade-off | Acceptance |
|-----------|------------|
| Payload size grows ~3–5× (from ~60 bytes to ~300–500 bytes per event) | Accept — webhook is advisory; still sub-ms latency at 5s timeout. Modern ingesters expect richer envelopes. |
| More fields to document | Accept — documentation is one-time; payload instability is perpetual. |
| State.json grows ~30% per run (richer per-stage) | Accept — state.json is ephemeral per-run; total size stays under 100 KB for typical pipelines. |
| `pipeline-summary.json` is a new public artifact (extra contract) | Accept — it is the single best mitigation for markdown-regex brittleness. Formal contract beats implicit format. |
| `fixer-iteration-completed` as opt-in adds one more On-events token | Accept — opt-in means zero cost for consumers who do not want it. |
| `schema_capabilities` is a new idea (not in roadmap) | Accept — it is strictly additive and optional; dashboards that do not read it are unaffected. |
| Consumer cost: slightly more parsing logic | Small; the payload is self-describing with `schema_version` + `ceos_agents_version`. |

**Biggest trade-off:** complexity. I am adding ~10 non-roadmap fields, one new config key, one new core file, one new artifact. Each is defensible individually. The risk is that the Phase 4 spec reviewer will prune aggressively — I document every field's consumer need so the pruning decisions are evidence-based.

---

## Explicit Deferrals

1. **Cross-run correlation via `parent_run_id` beyond autopilot → fix-ticket.** Only autopilot-spawned runs set `parent_run_id` in v6.8.0. Scaffold's existing parent_run_id usage continues. A full invocation graph (e.g., for asysta orchestration) is OUT OF SCOPE.
2. **Payload signing / HMAC.** Webhook auth is the consumer's problem (URL can carry a token); v6.8.0 does not add signing headers. Deferred to v6.9.0 if demand emerges.
3. **Retry logic for webhook failures.** Current advisory-only contract preserved (Q10 HIGH confidence). No retries, no dead-letter queue. If a webhook endpoint is down for 5 minutes, events are lost — this is acceptable for observability. Deferred.
4. **`pipeline-summary.json` schema evolution.** v6.8.0 ships "1.0" of the summary; breaking changes would need a new field or version bump. Deferred — we will accumulate consumer feedback before iterating.
5. **State.json size compaction.** No compaction/truncation logic in v6.8.0 despite richer fields. If size becomes an issue, deferred to v6.8.1.

---

## Synthesis Input

**What I am most confident about** (highest signal-to-risk):
- `pipeline-summary.json` as the consumer contract — separating machine-readable summary from markdown/state.json is objectively correct for external integration. Almost zero risk of regret.
- `parent_run_id` in `pipeline-started` payload — cheap, enables autopilot correlation, already a first-class state.json concept.
- `tokens_by_model` in pipeline accumulator — directly feeds the #1 /metrics consumer need (cost-per-model).
- Refactoring to `core/pipeline-events.md` — domain-clean separation; preserves backward compat trivially.
- Common payload envelope with `schema_version` — the single most future-proofing field.

**What I am least confident about** (highest debate value):
- `schema_capabilities` array — novel, could be seen as over-engineering. If Persona 1 prefers strict `schema_version: "1.1"`, that is a defensible simpler alternative.
- `fixer-iteration-completed` as opt-in event — adds complexity to the event taxonomy; could be deferred if fixer-health dashboards are not an immediate consumer.
- `parent_agent` per stage — invocation chains are nice but could be inferred from the skill name + state.json structure. Borderline.

**Best elements for judge synthesis** (what I would port into a blended recommendation):
- Keep schema_version at "1.0" (align with Persona 1/3 conservative position — I agree).
- Ship `pipeline-summary.json` (my core innovator contribution).
- Adopt the richer payload: at minimum `run_id`, `parent_run_id`, `phase`, `tokens_used`, `outcome`, `blocked`, `model_used` on `step-completed` (reconciles D10 vs. roadmap — these are the non-controversial additions).
- `autopilot-started`/`autopilot-completed` distinct from `pipeline-started`/`pipeline-completed` — batch vs. per-issue distinction is critical.
- `core/pipeline-events.md` refactor — clean architecture.
- `/metrics` state.json-reading mode with heuristic fallback — directly unblocks cost truth.
- Dry-run = full short-circuit — non-negotiable for cron safety.
