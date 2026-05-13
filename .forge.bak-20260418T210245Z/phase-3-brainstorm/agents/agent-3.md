# Phase 3 Brainstorm — Persona 3: Blast-Radius-Skeptical Pragmatist

## Thesis

Ship v6.8.0 as **three narrow, additive, independently-reversible changes**. Every expansion is a future breaking change waiting to happen, so each interface (config keys, webhook payloads, state.json fields) must match the roadmap **verbatim** — no "while we're at it" fields, no speculative hooks, no schema version bumps. The whole point of "MINOR" is that rolling forward to v6.8.0 is invisible to consumers who haven't opted in, and rolling back to v6.7.2 leaves no residue beyond JSON fields the old reader silently ignores. If Persona 1 proposes mirroring forge byte-for-byte and Persona 2 wants to emit richer payloads for imagined dashboards, I reject both when they exceed roadmap prose: forge can be a structural reference without being a naming authority (because `tokens_estimated` is a forge euphemism that misrepresents ceos-agents, which gets real counts from the Task tool), and monitoring dashboards can parse a v6.8.1 field addition later if they need one — extending a payload is safer than shrinking it. The judge should read this proposal as the floor of what v6.8.0 must do; Personas 1 and 2 define the ceiling.

## Item 1: /ceos-agents:autopilot

### Skill structure (minimum — steps 0..N)

File: `skills/autopilot/SKILL.md` (new). Frontmatter:

```yaml
---
name: autopilot
description: Headless dispatcher — reads Bug + Feature queries, classifies issues, dispatches fix-ticket or implement-feature sequentially with lock-file concurrency control
allowed-tools: mcp__*, Bash, Read, Write, Edit, Grep, Glob, Skill
disable-model-invocation: true
argument-hint: "[--dry-run]"
---
```

**Decision on `disable-model-invocation: true`:** Autopilot is a pipeline dispatcher (invokes fix-ticket, implement-feature), not an exploratory user entry point. The precedent is unambiguous once you classify it as a dispatcher: fix-bugs, fix-ticket, implement-feature all carry the flag. `/onboard`, `/status`, `/metrics` are informational — Autopilot is not. Set the flag true; this also prevents an LLM from mistakenly invoking Autopilot during an unrelated session.

Steps (each is a hard-coded behavioral gate):

1. **Step 0 — Config read.** Read `### Autopilot` section from CLAUDE.md via `core/config-reader.md`. If section missing: print `[INFO] ### Autopilot section absent — using defaults` and continue with defaults. Read `### Issue Tracker` (required). Read `### Feature Workflow` (optional — absence handled at Step 3).
2. **Step 1 — Lock acquisition.** See "Lock file mechanism" below. If lock held and not stale: exit code 2, message `[BLOCK] autopilot already running (lock age {N}min < 120min)`.
3. **Step 2 — MCP precheck.** Call MCP `ping` (issue tracker type from config). On failure: release lock, exit code 3, message `[STOP] MCP unreachable — {error}`. No issue processing.
4. **Step 3 — Classification.** See "Two-query classification" below.
5. **Step 4 — Dispatch loop.** For each classified issue (up to `Max issues per run`): dispatch `fix-ticket` (bug) or `implement-feature` (feature) via Skill tool. On per-issue error: behavior per `On error` config (skip = continue, stop = break). Increment counters, write log line per issue.
6. **Step 5 — Summary.** Write summary line to `{Log file}` (path from config; default `.ceos-agents/autopilot.log`). Release lock. Exit code 0.

No agents invoked directly by Autopilot. No new sub-skills. No retry logic beyond what child skills already implement.

### Lock file mechanism (Windows atomicity addressed)

**Lock location:** `.ceos-agents/autopilot.lock` (per roadmap line 633).

**Mechanism — atomic-create-or-fail file write via PowerShell .NET file handle** (not mkdir):

```
try:
  handle = [System.IO.File]::Open("{lock_path}", Create_New, Write, None)
  write "{pid}|{hostname}|{ISO8601}" to handle
  close handle
  LOCK_ACQUIRED
except IOException (file exists):
  read existing lock → parse timestamp
  if now - timestamp > 120min: delete lock, retry once
  else: LOCK_HELD (exit)
```

**Why file-with-PID not mkdir:** A bare `mkdir` lock gives atomicity but no debug information — an admin investigating a stale lock needs to know *which PID* held it. Writing PID + hostname + timestamp inside the file is worth the tiny complexity. The `FileMode.CreateNew` flag is atomic on Windows NTFS (equivalent to POSIX `O_CREAT | O_EXCL`) and fails fast with `IOException` if the file exists — no race. PowerShell exposes this via `[System.IO.File]::Open`; the skill invokes PowerShell via Bash (Git Bash on Windows wraps this).

**Skill creates the lock, not the user's invocation script.** Reason: the CLI invocation `claude -p "Run /ceos-agents:autopilot" --dangerously-skip-permissions` is the surface a user copies into cron. If the lock is the user's responsibility, a copy-pasted cron entry without lock wrapping will hammer MCP, overwrite each other's state, and produce inconsistent results. Lock inside the skill = lock is a precondition that the feature itself enforces. User cannot forget it.

**Stale detection at 120min:** Single threshold, no grace period. If a previous Autopilot run crashed leaving a lock, 120min is the recovery window. Configurable via `Lock timeout` key. If a genuine run takes > 120min, the next cron invocation will steal the lock — an acceptable edge case that the docs must explicitly call out.

**Cleanup:** `try / finally` — lock deleted on both clean exit and Step 2/3/4 abort paths. If the process is SIGKILLed mid-run, the lock becomes stale and is stolen at the 120min mark. No PID liveness check (cross-platform PID probing is unreliable on Windows; roadmap's time-based staleness is sufficient).

### Two-query classification (overlap resolution)

```
bug_ids    = run_mcp_query(Issue Tracker.Bug query, limit=Bug_limit or Max_issues)
feature_ids = run_mcp_query(Feature Workflow.Feature query, limit=Feature_limit or Max_issues)  [if section present]
overlap    = bug_ids ∩ feature_ids
feature_only = feature_ids - overlap  # bug wins
classified = [(id, "bug") for id in bug_ids] + [(id, "feature") for id in feature_only]
```

Cap total classified length at `Max issues per run`. Bugs populate first so a run with mixed content prioritizes bug fixes (matches the roadmap's "bug takes priority on overlap" clause and extends it to total-limit rationing).

**Edge case — `Bug limit: 0` AND `Feature limit: 0`:** Both defaults are 0, meaning "no per-category cap, use Max issues per run only." Do not interpret 0 as "disabled" for Bug — it defaults to using all available bug slots up to `Max issues per run`. But `Feature limit: 0` + Feature Workflow absent = zero features processed regardless (no query to run). Document this exactly once in CLAUDE.md; no implicit behavior.

### Error boundaries

| Condition | Action | Rationale |
|---|---|---|
| Lock held, not stale | Exit 2, no side effects | Prevent double-run |
| Lock held, stale > 120min | Delete + re-acquire | Recovery |
| MCP ping fails | Exit 3, release lock | No issue tracker = no work |
| Config missing required section | Exit 4, release lock | Same behavior as every other skill |
| Per-issue dispatch fails AND `On error: skip` | Log WARN, continue | Default |
| Per-issue dispatch fails AND `On error: stop` | Break loop, write summary, release lock, exit 1 | Explicit opt-in |
| Webhook delivery fails | `[WARN]` log, continue | Inherit existing advisory pattern |

Never retry at Autopilot level. Child skills (fix-ticket, implement-feature) own their own retry logic. Autopilot is a dispatcher.

### Exact `### Autopilot` config section (roadmap verbatim, no additions)

Seven keys, exactly as roadmap line 634 enumerates. Reject additions even if useful — they belong in v6.8.1 as MINOR feature adds.

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

Added to CLAUDE.md's "Optional sections" table as row: `| Autopilot | Max issues per run, Lock timeout, Log file, Bug limit, Feature limit, On error, Dry run | 1, 120, .ceos-agents/autopilot.log, 0, 0, skip, false |`.

`core/config-reader.md` adds 7 dot-notation entries: `autopilot.max_issues_per_run`, `autopilot.lock_timeout`, `autopilot.log_file`, `autopilot.bug_limit`, `autopilot.feature_limit`, `autopilot.on_error`, `autopilot.dry_run`.

### Dry-run semantics (explicit: lock? state? webhook?)

**Full short-circuit — no side effects, period.**

| Surface | Dry-run behavior | Rationale |
|---|---|---|
| Lock file | NOT created | Concurrent dry-runs from cron testing wouldn't false-positive block each other; dry-run is meant to be safe to invoke repeatedly |
| MCP queries | Executed (read-only) | Classification output is the core deliverable of dry-run |
| State.json | NOT written | No issue is being processed — writing state.json for an unstarted run pollutes `.ceos-agents/` and confuses `/resume-ticket` |
| Pipeline.log | NOT written | Same reason |
| Webhooks | NOT fired | Monitoring systems must not receive events for non-existent pipeline runs — this is a correctness issue for Grafana/observability consumers |
| Output | Classification report (markdown table of would-be-processed issues) | This is all the user wants |
| Child skill dispatch | NOT invoked (no fix-ticket, no implement-feature) | Obvious |

**Justification:** fix-ticket's partial dry-run (writes state.json) is the wrong precedent here — fix-ticket processes ONE issue and the state is the deliverable, but Autopilot is a cron dispatcher whose dry-run exists to answer "would this run be safe?" Creating side effects defeats that. This is stricter than fix-ticket but different context.

### Feature-query absence (bug-only mode, no block)

If `### Feature Workflow` section absent OR `Feature query` key absent within the section:

- Print `[WARN] Feature Workflow section absent — running in bug-only mode` (single line, once per run)
- Treat `feature_ids = []` — run two-query classification with empty feature side
- Do not block, do not exit non-zero, do not alert via webhook

If `Feature Workflow` present AND `Feature limit > 0` AND no `Feature query` inside it: print `[WARN] Feature limit configured but no Feature query — treating as bug-only` and continue. Never block on config omissions in an optional section. Matches `/metrics` precedent per Q7 research.

## Item 2: Observability Hooks (D10)

### Payload schemas (ROADMAP VERBATIM)

Three events, roadmap line 648 wording, nothing more:

```json
// pipeline-started
{"event":"pipeline-started","issue_id":"BUG-123","timestamp":"2026-04-17T10:00:00Z"}

// step-completed
{"event":"step-completed","issue_id":"BUG-123","step_name":"triage","duration":45000,"iteration_count":1,"timestamp":"2026-04-17T10:00:45Z"}

// pipeline-completed
{"event":"pipeline-completed","issue_id":"BUG-123","outcome":"success","duration":692000,"timestamp":"2026-04-17T10:11:32Z"}
```

Four fields for `step-completed`: `event, issue_id, step_name, duration, iteration_count, timestamp` (plus standard event + issue_id + timestamp envelope). `pipeline-completed` needs `outcome` because without it the event is useless to a monitor (pass vs. fail). `pipeline-started` needs only the envelope — its payload answers "did we start?" and nothing more.

**Reject innovator's additions** (`run_id`, `phase`, `previous_stage_duration_ms`, `blocked`): each is a dashboard request disguised as a v6.8.0 requirement. The roadmap lists three fields for `step-completed`; that's the contract. If v6.8.1 or v6.9.0 decides they want more, adding a field is backward-compatible (old parsers ignore it). Shrinking is not. Keep the initial payload minimal; grow it later when there's a named consumer requesting a specific field.

**Reject D10 `tokens_used` in payload**: yes, D10 mentions it, but including per-stage tokens in the webhook duplicates state.json (Item 3) and creates two sources of truth. External consumers who need tokens should read state.json (they already do for post-hoc metrics). Webhooks are for ordering and latency, not data replication.

### Event granularity decision (top-level only; justify)

**One `step-completed` event per top-level named stage.** Not per fixer-reviewer iteration.

Stage enum (closed set — add to spec):
- `triage`, `code_analysis`, `reproducer`, `fixer_reviewer`, `test`, `e2e_test`, `browser_verification`, `acceptance_gate`, `publisher`, `deployment_verification`
- Feature-pipeline additions: `spec_analysis`, `architect`
- Scaffold-pipeline additions: `spec_writer`, `spec_reviewer`, `scaffolder`

**Justification (three layers):**

1. **Roadmap semantics:** `iteration_count` as a payload field only makes sense if a stage aggregates iterations; if events fired per iteration, `iteration_count` would be a monotonic counter redundant with event sequence.
2. **Separation of concerns:** `pipeline.log` already records per-iteration events (`fixer_iteration`). Duplicating them as webhooks creates two parallel internal/external telemetry streams and volume.
3. **Volume math:** Per-stage gives ~10 events per pipeline. Per-iteration with a 5-retry fixer loop gives up to 20. For a 20-issue Autopilot run, that's 200 vs. 400 outbound webhook calls — real cost when the consumer is a rate-limited Grafana endpoint.

**`step-skipped` NOT introduced as a webhook event.** A skip is observable via the gap between the previous `step-completed` and the next one — or more robustly, via reading pipeline.log. Adding `step-skipped` triples the event count in profile-heavy runs. Explicit NOT_IN_SCOPE.

### Fire sites

| Event | Fires at | Skills |
|---|---|---|
| `pipeline-started` | After config validation, before Step 1 | fix-ticket, fix-bugs (once per issue), implement-feature, scaffold |
| `step-completed` | Immediately after each top-level stage write to state.json | same 4 skills |
| `pipeline-completed` | After final state.json write (either success or final block) | same 4 skills |

Autopilot itself does NOT fire `pipeline-started` or `pipeline-completed` for its own lifecycle — those fire per-issue from the child skills. Autopilot only dispatches. (Innovator's `autopilot-started` / `autopilot-completed` events are scope creep; rejected. If v6.8.1 needs dispatcher-level events, add them additively then.)

### Webhook volume / debounce question

**Fire-and-forget, no debounce, no batching.**

Reasoning: existing `pr-created` and `issue-blocked` use `curl --max-time 5 --retry 0` — fire-and-forget with a hard 5-second cap. A slow webhook URL is the user's configuration problem, not ours. If 50 `step-completed` events fire during a 20-issue run and each takes 5 seconds, that's 250 seconds of worst-case webhook time — acceptable for a headless run that might take an hour. Queueing introduces failure modes (what if the queue fills? what if the skill crashes mid-queue?) that a MINOR release should not import.

**Decision against debounce:** debounce is correct for interactive systems where a user expects snappy responses. Autopilot is batch; snappy is irrelevant. Keeping the pattern identical to existing webhooks also means zero new failure paths for v6.7.x users who upgrade.

### core/ refactor decision (extend; justify)

**Extend `core/post-publish-hook.md`, do NOT create `core/pipeline-events.md`.**

Rationale:
- Adding a file is a contract-area change (new reference point for future docs to cite). Extending one file keeps the referential surface area stable.
- `post-publish-hook.md` already carries the webhook pattern with correct failure handling (Step 3 lines 17–23, failure handling lines 29–33). Copy-pasting that pattern into a new file introduces divergence risk — if a future change fixes the pattern in one place, the other goes stale.
- The three new events share the exact same transport contract as `pr-created`. The only difference is the trigger point (middle of pipeline vs. post-publish). That's a Process section addition, not a new module.

Concretely: add Section 4 to `core/post-publish-hook.md` titled "Pipeline lifecycle events" with a reference to the three events, their payloads, and a sentence "Transport, curl invocation, and failure handling are identical to Section 3." No new file. `core/block-handler.md` is untouched — the `issue-blocked` event stays where it is; new events are not blocks.

If v6.9.0 introduces a semantically different event class (e.g., streaming), then split the module. Do not preemptively split.

### Backward compat

- Existing events (`pr-created`, `issue-blocked`) unchanged — same payload, same trigger, same failure path.
- CLAUDE.md `Notifications → On events` key currently accepts a comma-separated list; add 3 new tokens (`pipeline-started`, `step-completed`, `pipeline-completed`) to the valid-token list. Documentation-only change; no parser change (it's a substring check).
- Projects with existing `On events: pr-created` unchanged — they do NOT receive new events until they opt in.
- Projects with no `Webhook URL` configured receive nothing — same as before.

## Item 3: Real-Time Cost Visibility

### State.json field additions (minimum)

Exactly the six fields from roadmap line 705 per stage, plus the top-level `pipeline` accumulator from roadmap line 707. No more.

Per-stage (added to each of: `triage`, `code_analysis`, `reproducer`, `fixer_reviewer`, `test`, `e2e_test`, `browser_verification`, `publisher`, `spec_analysis`, `architect`, `spec_writer`, `spec_reviewer`, `scaffolder`, `deployment`):

```json
{
  "tokens_used": 12500,
  "duration_ms": 45000,
  "tool_uses": 8,
  "model": "sonnet",
  "started_at": "2026-04-17T10:00:00Z",
  "completed_at": "2026-04-17T10:00:45Z"
}
```

Top-level accumulator:

```json
"pipeline": {
  "total_tokens": 250700,
  "total_duration_ms": 692000,
  "total_tool_uses": 183
}
```

**Canonical stored field name: `tokens_used`.** Choose the roadmap's name, not forge's `tokens_estimated`. Rationale (rejecting Persona 1's mirror-forge argument):
- Forge uses `tokens_estimated` because forge's own Task dispatch returns estimates (via approximation formula). Ceos-agents' Task tool returns real usage counts — `estimated` would be misleading.
- The roadmap line 674 wrote `tokens_used` explicitly — roadmap is ground truth for MINOR releases, not a reference repository that happens to have a similar shape.
- `tokens_used` reads correctly in English without needing a footnote. `tokens_estimated` requires the consumer to know which side of ceos/forge they're on.

Name divergence between forge and ceos is NOT a bug — they are separate plugins with separate audiences. `/metrics` can aggregate both by mapping: `reading: field = tokens_estimated ?? tokens_used` (defensive read, works across both).

### Schema version (1.0, justify)

**Stays `"1.0"`.**

- Roadmap classifies this as PATCH (line 714); bumping would contradict the MINOR/PATCH labeling.
- `core/state-manager.md` Read Process (lines 34–35) returns parsed JSON with no version check. A bump is invisible downstream; it's a cosmetic change.
- `/resume-ticket` reads 5 fields (per Q11 research); all survive the addition. Bump provides zero correctness benefit.
- `state/schema.md` line 148 says "Always `\"1.0\"` for this specification" — bumping for additive fields would undermine the intent of that clause.

Write `state/schema.md` updates as additive: expand the Full Schema Example (lines 33–141) with the new fields, add field-definition table rows. Do NOT edit the schema-version clause.

### Task-tool usage capture (per site)

At every Task dispatch site in the four pipeline skills (fix-ticket, fix-bugs, implement-feature, scaffold), wrap the dispatch in capture pseudocode:

```
started_at = now_iso8601()
result = Task(agent=X, ...)
completed_at = now_iso8601()
duration_ms = completed_at - started_at in ms
# Task result provides (per Q1 research — design decision):
#   result.usage.total_tokens   → write as tokens_used
#   result.usage.tool_uses      → write as tool_uses
#   (if Task tool returns duration_ms, use that; else compute from wall clock)

state_write(field_path="{stage}.tokens_used", value=result.usage.total_tokens)
state_write(field_path="{stage}.duration_ms", value=duration_ms)
state_write(field_path="{stage}.tool_uses", value=result.usage.tool_uses)
state_write(field_path="{stage}.model", value=agent_frontmatter.model)
state_write(field_path="{stage}.started_at", value=started_at)
state_write(field_path="{stage}.completed_at", value=completed_at)
```

**Defensive read of Task result:** if `result.usage` is null/absent (older Task tool behavior, unexpected response shape), write `null` for all three count fields. Do not block, do not retry. Preserves forward compatibility and protects against a future Task tool change.

### Fixer-reviewer accumulation (cumulative only)

Per roadmap line 677: `fixer_reviewer.tokens_used` is the **cumulative sum** across iterations. After each fixer→reviewer round:

```
state.fixer_reviewer.tokens_used   += this_iteration_fixer_tokens + this_iteration_reviewer_tokens
state.fixer_reviewer.tool_uses     += ...
state.fixer_reviewer.duration_ms   += ...
state.fixer_reviewer.iterations    += 1  (already existed)
state.fixer_reviewer.model         = "opus"  (constant)
state.fixer_reviewer.started_at    = set on iteration 1 only
state.fixer_reviewer.completed_at  = set on final iteration (success or give-up)
```

**No per-iteration breakdown array.** Explicit NOT_IN_SCOPE exclusion. If a future version wants "which iteration consumed the most tokens" visibility, that's v6.9.0. For v6.8.0, a single cumulative row matches the summary table output (line 685).

**Reviewer and fixer share the `fixer_reviewer` slot.** Don't split them into `fixer` and `reviewer` separate slots — they share a retry loop and state.md already treats them as one stage. Summary table line 685 shows them separately for display purposes; that's a rendering concern, not a state shape concern.

### Pipeline summary table (inside state.json; CI-grep target)

Write the markdown summary table as a single string field `pipeline.summary_table` at the end of each pipeline run. Keep the table inside state.json (not a separate file) so `/metrics` has a single read target and CI greppability is preserved.

```json
"pipeline": {
  "total_tokens": 250700,
  "total_duration_ms": 692000,
  "total_tool_uses": 183,
  "summary_table": "| Stage | Model | Tokens | Duration | Tools |\n|---|---|---|---|---|\n| triage | sonnet | 12,500 | 45s | 8 |\n..."
}
```

PR body inclusion: optional, only if the user wants it via a `Summary in PR body` config flag in Notifications. Do NOT default to PR-body inclusion — PR bodies are a contract surface projects template carefully; adding a table unsolicited is presumptuous. This is a future enhancement.

Do NOT emit summary to pipeline.log — too noisy, breaks line-orientation of JSONL.

### /metrics aggregation (additive only)

`skills/metrics/SKILL.md` gains Step 3b: "Read state.json from each completed run in `.ceos-agents/`. If state carries `pipeline.total_tokens`, use actual values; else fall back to heuristic constants (sonnet ~30k, opus ~50k, haiku ~5k — current Step 6 behavior)."

No new flags, no new output format, no `--format json`. The innovator's proposal for machine-readable output is v6.9.0 territory — it changes /metrics' output contract which downstream CI may scrape. MINOR change, single additive step, keep all existing output stable. (The `--format json` flag is rejected as explicit NOT_IN_SCOPE.)

## Trade-offs

**What this proposal gives up relative to Persona 1 (forge-parity):**
- Name divergence between forge (`tokens_estimated`) and ceos (`tokens_used`). `/metrics` cross-plugin aggregation needs a small name-map. Worth it because `tokens_used` is more accurate for ceos.

**What this proposal gives up relative to Persona 2 (innovator):**
- No `run_id`, `phase`, `blocked`, `previous_stage_duration_ms` in webhook payloads. Dashboards that want them wait for v6.8.1 or read state.json directly.
- No `--format json` in /metrics. Monitoring consumers read state.json, not /metrics stdout.
- No `autopilot-started` / `autopilot-completed` dispatcher lifecycle events. Monitoring consumers infer dispatcher runs from correlated per-issue events.

**What this proposal wins:**
- Backward compat is unbreakable: additive state fields + additive webhook events + additive config section. Rollback = do nothing; old reader ignores.
- Explicit NOT_IN_SCOPE list keeps v6.8.1 scope bounded — future work is pre-named.
- No new core/ files, no new agents, no contract-surface growth beyond what the roadmap prescribes.

## Explicit NOT_IN_SCOPE (at least 3)

1. **No per-iteration token breakdown array.** `fixer_reviewer.tokens_used` is a cumulative sum; no `fixer_reviewer.iterations_usage[]` array. Adding it later is additive.
2. **No `--format json` flag on `/metrics`.** Output format stays stdout markdown. Machine-readable aggregates via state.json direct read.
3. **No `step-skipped` webhook event.** Skips are observable via pipeline.log; adding a dedicated event triples volume in profile-heavy runs.
4. **No `autopilot-started` / `autopilot-completed` dispatcher lifecycle events.** Per-issue events (`pipeline-started`/`pipeline-completed`) already cover the entire batch.
5. **No per-model cost / billing semantics.** `tokens_used` is informational only (roadmap line 714). No `cost_usd`, no `billing_tier`, no model pricing tables.
6. **No real-time streaming of state.json updates.** Writes remain on-close-of-stage. No partial-state event stream.
7. **No PR-body summary table inclusion by default.** Opt-in via future config flag.
8. **No new `core/pipeline-events.md` file.** Extend `core/post-publish-hook.md` only.
9. **No schema version bump.** Stays `"1.0"`.
10. **No `run_id` added to webhook payloads.** `issue_id` is the correlation key; a run_id would be a second correlation surface and its semantics differ across Autopilot vs. single-issue.

## Backward-Compat Risks Identified (at least 2)

**Risk 1 — Mid-upgrade state.json hybrid.** Scenario: a v6.7.2 pipeline crashes, leaving state.json without the new six per-stage fields. User upgrades to v6.8.0 and runs `/resume-ticket`.

*Mitigation:* state-manager.md Read Process already returns parsed JSON with no field-shape validation. `/resume-ticket` reads only 5 known fields (per Q11). Missing new fields = JS-style `undefined` on access, which the existing code does not dereference. **Action required:** Phase 5 TDD adds `regression-resume-v6.7.x-state.sh` — construct a state.json with the v6.7.2 schema, run resume, assert no error.

**Risk 2 — Webhook consumer parses old payload with strict schema.** Scenario: consumer of `pr-created` uses a strict JSON schema validator (e.g., Grafana panel query) that rejects unknown fields. If a future v6.8.1 adds a field to the payload, their panel breaks.

*Mitigation:* Document explicitly in CLAUDE.md Notifications section: "Webhook payloads are forward-compatible — additive fields may be added in future MINOR versions. Consumers should use lenient JSON parsing (ignore unknown fields)." This is a documentation-level guarantee, not a code contract, because we can't enforce the consumer side — but publishing the contract intent reduces support burden when v6.8.1 ships an additional field. **Action required:** add this guarantee to the CLAUDE.md template and to `core/post-publish-hook.md` Section 4.

**Risk 3 (bonus) — Autopilot lock file collision across repos.** Scenario: user runs Autopilot in two different project directories concurrently. Each creates `.ceos-agents/autopilot.lock` in its own working directory.

*Mitigation:* Lock is per-project-directory (the `.ceos-agents/` dir is project-local). Two repos = two locks. Document this explicitly. **Action required:** add a sentence in `skills/autopilot/SKILL.md` Step 1 clarifying lock scope is project-directory-local.

## Synthesis Input

**Best adopt from Persona 1:** per-stage `started_at` + `completed_at` field shape matches forge exactly — this is one place where structural parity is genuine value (enables cross-plugin aggregation by time). The names `started_at`/`completed_at` should be taken as forge names.

**Best adopt from Persona 2:** CLAUDE.md documentation language that explicitly promises "additive fields may be added" (forward-compatibility guarantee) is a good idea — not because we ship extra fields now, but because documenting the guarantee lets us ship them later without breaking anyone.

**Best reject from Persona 1:** `tokens_estimated` as the ceos-agents stored field name. Forge's name is wrong for ceos-agents' context (real counts, not estimates). The roadmap correctly uses `tokens_used`.

**Best reject from Persona 2:** richer webhook payloads now. YAGNI. Growing payloads is additive; shrinking is breaking. Start minimal.

**Where I'm most aggressive about reduction:** drop `--format json` on `/metrics`, drop `step-skipped` event, drop any per-iteration array, drop any core/ new-file split. Every one of those is a contract-surface addition that the roadmap does not require and that v6.8.1 can add painlessly if a real consumer asks.

**Key decision contributions:**
- `disable-model-invocation: true` on autopilot (dispatcher, not entry point)
- Stays `schema_version: "1.0"` (additive, no bump)
- Extend `core/post-publish-hook.md` (no new file)
- Full short-circuit dry-run (no lock, no state, no webhooks)
- `[WARN]` for absent Feature Workflow (not silent, not block)
- Event granularity: one event per top-level named stage
- No `step-skipped` event
- Field name: `tokens_used` (roadmap, not forge)
- Lock: atomic file-create-or-fail with PID/hostname/timestamp inside
