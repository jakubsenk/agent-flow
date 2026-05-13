# Phase 4 Spec — ceos-agents v6.8.0 — Requirements (Revision 2)

**Scope:** Autopilot skill + Observability Hooks (D10) + Real-Time Cost Visibility.
**Version bump:** v6.7.2 → v6.8.0 MINOR via `/ceos-agents:version-bump`.
**Gate 1 decisions:** consumed from `.forge/phase-3-brainstorm/final.md` (approved 2026-04-17).
**Revision:** Round 1 applied 2026-04-17 in response to 3 reviewer reports (compliance / quality / devil's advocate). Round 2 applied 2026-04-17 as surgical polish to address DA-round2 MAJOR (cross-host-hint sidecar dropped) + MINOR findings (compact `run_id`, BusyBox fallback, COST-R12 discovery assertion) and Quality-round2 nits (AC-1 anchored grep, AC-36 apostrophe literal). No Gate 1 decisions reopened.

---

## Section 1: Scope & Goals

### 1.1 Autopilot

A new skill `/ceos-agents:autopilot` that runs headless under cron. It reads `### Issue Tracker`, optionally `### Feature Workflow` and `### Autopilot`, then performs a two-query classification, applies limits, and dispatches `ceos-agents:fix-ticket` (bug) or `ceos-agents:implement-feature` (feature) sequentially via the Skill tool. Concurrency is guarded by a `mkdir`-based portable-bash lock at `.ceos-agents/autopilot.lock/` with stale detection at 120 minutes. Failure boundaries are explicit: MCP unreachable = exit before lock; per-issue errors are skipped by default; lock acquisition failure = exit 2 with no state side-effects; `Dry run: true` is a full short-circuit (no lock, no state.json, no webhooks, no dispatch). The skill carries `disable-model-invocation: true` per dispatcher precedent.

**Done means:**
- `/ceos-agents:autopilot` is invocable via `claude -p "Run /ceos-agents:autopilot" --dangerously-skip-permissions`.
- Lock directory is created/released atomically; stale locks (>120min) are recovered on next run.
- Bug and Feature queries are classified per roadmap rule (bug wins on overlap); `Max issues per run` capped.
- Absent `### Feature Workflow` emits `[WARN]` and continues in bug-only mode.
- `Dry run: true` prints classification and exits with zero side effects.
- Trap-based cleanup guarantees lock release on both success and crash paths, and only when the current process owns the lock.

### 1.2 Observability Hooks (D10)

Three new webhook events — `pipeline-started`, `step-completed`, `pipeline-completed` — are fired by the four pipeline skills (`fix-ticket`, `fix-bugs`, `implement-feature`, `scaffold`) at top-level stage boundaries. Payloads follow the roadmap minimum (`step_name`, `duration`, `iteration_count`) plus `run_id` on all three events and `outcome` on `pipeline-completed`. Transport, curl invocation, and advisory-failure semantics are inherited from `core/post-publish-hook.md` Section 3; the file is extended (not replaced) with a new Section 4 documenting the three new events. Per-iteration resolution stays in `pipeline.log` — no `step-skipped`, no `fixer-iteration-completed`, no batch `autopilot-started/completed`. Webhook fire order is STRICT: state.json is written atomically FIRST; only on successful state write does the webhook fire.

**Done means:**
- The three events fire at the four pipeline skills' stage boundaries when `Webhook URL` is configured and the event name is present in `On events`.
- Payload JSON literals match Section 4 of `design.md` byte-for-byte.
- Existing `pr-created` and `issue-blocked` payloads are unchanged.
- Webhook failure for any new event is advisory: `[WARN]` and continue.
- `core/post-publish-hook.md` Purpose line updated; Section 4 added.
- CLAUDE.md Notifications `On events` enumeration documents the three new tokens and a forward-compat guarantee paragraph.

### 1.3 Real-Time Cost Visibility

Each of the four pipeline skills captures `total_tokens`, `duration_ms`, `tool_uses` from the Task-tool `result.usage` after every agent dispatch and writes six per-stage fields to `state.json`: `tokens_used`, `duration_ms`, `tool_uses`, `model`, `started_at`, `completed_at`. Fixer-reviewer accumulates cumulatively (no per-iteration array). A top-level `pipeline` accumulator is written once at pipeline end with `total_tokens`, `total_duration_ms`, `total_tool_uses`, and a `summary_table` markdown string (truncation bounded; see COST-R10). `schema_version` stays `"1.0"` (additive; state-manager reads permissively; `/resume-ticket` field-path reader tolerates unknown fields). `/metrics` adds a state.json-read step with heuristic fallback and reports measured and estimated values as SEPARATE line items (no mixed grand total). No `--format json` output evolution.

**Done means:**
- Every top-level stage section in state.json carries the six new usage fields on successful completion.
- `pipeline.total_tokens`, `pipeline.total_duration_ms`, `pipeline.total_tool_uses`, `pipeline.summary_table` are written at pipeline end.
- `/resume-ticket` reading a v6.7.x-shape state.json under v6.8.0 does not error.
- `/metrics` reports measured and estimated totals as separate line items per pipeline with a provenance footer; never sums across the boundary.
- Fixer-reviewer `tokens_used` is the cumulative sum across iterations.
- Defensive read: if `result.usage` is null, the field is written as `0` without error.

---

## Section 2: EARS Requirements

### 2.1 Autopilot (AUTOPILOT-R*)

- **AUTOPILOT-R1**: The system shall ship a skill file at `skills/autopilot/SKILL.md` with frontmatter `name: autopilot`, `disable-model-invocation: true`, and `argument-hint: "[--dry-run]"`.
- **AUTOPILOT-R2**: When `/ceos-agents:autopilot` starts and no lock directory exists, the Autopilot skill shall create `.ceos-agents/autopilot.lock/` atomically via `mkdir` and write `{pid, hostname, acquired_at}` JSON to `.ceos-agents/autopilot.lock/owner.json`.
- **AUTOPILOT-R3**: When `/ceos-agents:autopilot` starts and a lock directory exists with `owner.json.acquired_at` ≤ 120 minutes ago (UTC), the Autopilot skill shall print `[autopilot][ERROR] Another Autopilot run in progress` and exit with status 2.
- **AUTOPILOT-R4**: When `/ceos-agents:autopilot` starts and a lock directory exists with `owner.json.acquired_at` > `Lock timeout` minutes ago, the Autopilot skill shall remove the stale lock directory and re-acquire the lock exactly once.
- **AUTOPILOT-R5**: After successful lock acquisition, the Autopilot skill shall register a `trap ... EXIT` handler that verifies `owner.json.pid` matches the current shell PID (`$$`) before removing `.ceos-agents/autopilot.lock/`; on failed acquisition, no trap shall be registered.
- **AUTOPILOT-R6**: The system shall classify issues by querying `Bug query` and, if `### Feature Workflow` is present, `Feature query`, computing bug-priority on overlap, then capping at `Max issues per run`.
- **AUTOPILOT-R7**: When `### Feature Workflow` is absent from Automation Config, the Autopilot skill shall print `[autopilot][WARN] Feature Workflow section absent — running in bug-only mode` and continue.
- **AUTOPILOT-R8**: When `Feature limit` is > 0 but no `Feature query` is configured, the Autopilot skill shall print `[autopilot][WARN] Feature limit={N} configured but no Feature query — treating as bug-only` and continue.
- **AUTOPILOT-R9**: For each classified issue, the Autopilot skill shall dispatch `ceos-agents:fix-ticket {id}` for bugs or `ceos-agents:implement-feature {id}` for features via the Skill tool.
- **AUTOPILOT-R10**: When a dispatched child skill returns ERROR and `On error: skip` (default), the Autopilot skill shall log a WARN line and continue to the next issue; when `On error: stop`, it shall break the dispatch loop.
- **AUTOPILOT-R11**: While `Dry run: true` is configured, the Autopilot skill shall not acquire the lock, shall not write state.json, shall not fire webhooks, shall not dispatch any child skill, and shall print the classification table to stdout before exiting 0.
- **AUTOPILOT-R12**: When MCP ping fails at Step 0, the Autopilot skill shall print `[STOP] MCP unreachable — {error}` to stderr and exit with status 3 without creating a lock.
- **AUTOPILOT-R13**: When Autopilot acquires (or recovers) its lock, the system shall log `[autopilot][INFO] Running on host {hostname}. If another host is also running Autopilot against the same tracker, it MUST use a disjoint bug/feature query. See docs/guides/autopilot.md#single-host-operation.` on every successful lock acquisition. This is an INFORMATIONAL line to aid log correlation; it does NOT detect cross-host contention and does NOT block execution. The authoritative multi-host mitigation is operator-side disjoint-query configuration (see `docs/guides/autopilot.md#single-host-operation`). No sidecar files are written.

### 2.2 Webhooks (WEBHOOK-R*)

- **WEBHOOK-R1**: The `core/post-publish-hook.md` file Purpose line shall read `Execute pipeline hooks and fire webhooks at stage boundaries.`
- **WEBHOOK-R2**: When a pipeline skill validates config and initializes state.json and `Webhook URL` is configured and `pipeline-started` is in `On events`, the skill shall fire a `pipeline-started` webhook with payload `{event, run_id, issue_id, pipeline, timestamp}` AFTER the atomic state.json init has succeeded.
- **WEBHOOK-R3**: When a top-level pipeline stage successfully writes `{stage}.status: completed` to state.json and `Webhook URL` is configured and `step-completed` is in `On events`, the skill shall fire a `step-completed` webhook with payload `{event, run_id, issue_id, step_name, duration, iteration_count, timestamp}`. Fire order is STRICT: if the state.json write fails, the webhook is suppressed (webhook stream is a projection of committed state).
- **WEBHOOK-R4**: When a pipeline skill successfully writes its terminal `status: completed | blocked | failed` and `Webhook URL` is configured and `pipeline-completed` is in `On events`, the skill shall fire a `pipeline-completed` webhook with payload `{event, run_id, issue_id, status, outcome, duration, pr_url, timestamp}`.
- **WEBHOOK-R5**: When any new-event webhook delivery returns non-2xx or times out, the skill shall log `[WARN] Webhook delivery failed: {error}` and continue; the pipeline shall not block.
- **WEBHOOK-R6**: The system shall NOT fire a `step-completed` webhook per fixer-reviewer iteration; fires are one per top-level stage.
- **WEBHOOK-R7**: The system shall NOT emit any `step-skipped` webhook; skipped stages produce no webhook.
- **WEBHOOK-R8**: The `pr-created` and `issue-blocked` webhook payloads shall remain byte-for-byte identical to v6.7.2.

### 2.3 Cost Visibility (COST-R*)

- **COST-R1**: The system shall keep `schema_version` equal to `"1.0"` in `state/schema.md` and in all state.json writes.
- **COST-R2**: After each agent dispatch in a pipeline skill, the skill shall read `result.usage.total_tokens`, `result.usage.duration_ms`, `result.usage.tool_uses` and write them to `{stage}.tokens_used`, `{stage}.duration_ms`, `{stage}.tool_uses` in state.json. The exact Task-tool usage field name is discovered empirically via `tests/scenarios/cost-task-tool-usage-field-discovery.sh` (COST-R12) and the discovered name is used across the implementation.
- **COST-R3**: When `result.usage` is null or missing any usage field, the skill shall write `0` for each missing count, shall not retry, and shall not block.
- **COST-R4**: Before each agent dispatch, the skill shall write `{stage}.started_at`, `{stage}.model`, and `{stage}.status: in_progress`; after dispatch, it shall write `{stage}.completed_at` and `{stage}.status: completed`. `{stage}.model` is derived by reading the `model:` frontmatter field of the dispatched agent file `agents/{agent-name}.md` at dispatch time.
- **COST-R5**: For the fixer-reviewer loop, the skill shall accumulate `tokens_used`, `duration_ms`, `tool_uses` cumulatively across iterations into a single stage object and shall NOT persist a per-iteration breakdown array.
- **COST-R6**: At pipeline end (before terminal state write), the skill shall write `pipeline.total_tokens`, `pipeline.total_duration_ms`, `pipeline.total_tool_uses`, and `pipeline.summary_table` (markdown string, bounded per COST-R10) to state.json.
- **COST-R7**: `/metrics` shall, for each issue in the period, read `.ceos-agents/{ID}/state.json`; when `pipeline.total_tokens` exists, it shall count the issue as MEASURED; when absent, it shall count the issue as ESTIMATED and apply heuristic constants (`sonnet ~30k`, `opus ~50k`, `haiku ~5k`).
- **COST-R8**: `/metrics` shall emit measured and estimated totals as TWO SEPARATE line items per pipeline (never a single combined grand total); the markdown report shall include a provenance footer listing which issues contributed to each category. Example footer line: `Data source: measured={X} issues, estimated={Y} issues (see per-issue breakdown above).`
- **COST-R9**: `/resume-ticket` shall not read `schema_version` nor block on absence of the six new per-stage usage fields; reading a v6.7.x state.json shall produce no error in v6.8.0.
- **COST-R10**: When `pipeline.summary_table` would exceed 20 rows OR 4000 characters, the summary generator shall truncate row-wise (never mid-row) and append the row `| ... | (truncated, N more stages in pipeline.log) | ... |` immediately before the `Total` row.
- **COST-R11**: When `/metrics` aggregates a state.json containing both v6.7.x-era stages (no usage fields) and v6.8.0-era stages (with tokens_used), the metrics skill shall report measured and heuristic-estimated totals as SEPARATE line items per pipeline, with a provenance footer listing which stages contributed estimates (partial-measurement hybrid runs are reported as ESTIMATED at the pipeline level, with a per-stage breakdown in the detail section indicating which stages had measured data).
- **COST-R12**: Phase 5 TDD shall create `tests/scenarios/cost-task-tool-usage-field-discovery.sh` (run BEFORE other Phase 5 cost tests) that dispatches ONE minimal `Task` call and prints `result.usage` verbatim to stdout. The test MUST assert that the discovered token-count field name matches one of the known set `{total_tokens, input_tokens+output_tokens, tokens_estimated}`; on empty, missing, or unknown field name the test shall fail explicitly (exit non-zero) and print `DISCOVERED_FIELD=<UNKNOWN|ABSENT>` to stdout so Phase 7 has a mechanical signal. On success the test shall print a structured line `DISCOVERED_FIELD={name}` to stdout. Phase 7 implementation reads the discovered field name from this structured line and wires COST-R2 writes accordingly.

---

## Section 6: NOT_IN_SCOPE (v6.8.0)

1. **No `step-skipped` webhook event** — skipped stages are visible via `pipeline.log` and absence of a `step-completed` event for that stage. Deferred to v6.9.0 if a consumer requests it.
2. **No `fixer-iteration-completed` webhook event** — per-iteration resolution stays in `pipeline.log`.
3. **No `autopilot-started` / `autopilot-completed` batch events** — per-issue events with `run_id` provide enough correlation signal. Deferred to v6.9.0.
4. **No `--format json` flag on `/metrics`** — output stays markdown; machine consumers read `state.json` directly. Deferred.
5. **No separate `pipeline-summary.json` artifact** — summary table lives in `state.json.pipeline.summary_table`.
6. **No per-iteration token breakdown array** in `fixer_reviewer` — cumulative only.
7. **No new `core/pipeline-events.md` file** — `core/post-publish-hook.md` is extended with Section 4.
8. **No `schema_version` bump** — stays `"1.0"`; additive writes; state-manager reads permissively.
9. **No 8th Autopilot config key** — roadmap lists exactly 7.
10. **No richer webhook payload fields** — no `parent_agent`, `tool_uses_by_type`, `iteration_index_of_N`, `flags`, `profile`, `blocked_at`, `stages_completed`, `schema_capabilities`, `tokens_used` in `step-completed` payload.
11. **No webhook retry logic / dead-letter queue** — advisory-only pattern preserved.
12. **No PR-body injection of summary table by default** — deferred to future opt-in config flag.
13. **No hard cost ceiling / cost budget enforcement** — WONTFIX per roadmap line 918.
14. **No real currency conversion** — informational output only.
15. **No forge.json changes** — ceos-agents state.json is the sole target.
16. **No cross-run cost aggregation beyond `/metrics`** — no new dashboard aggregation feature in v6.8.0.
17. **No learning from outcomes** — roadmap v6.9.0 NEXT item.
18. **No NEEDS_CLARIFICATION agent signal** — roadmap v6.9.0 NEXT item.
19. **Tracker-level distributed lock across hosts** — v6.8.0 lock is process-local; operators running Autopilot from multiple hosts against the same tracker MUST coordinate via disjoint-query configuration or a single deployment. Mitigation is documented in `docs/guides/autopilot.md#single-host-operation`; AUTOPILOT-R13 emits an INFO line with the hostname on every successful lock acquisition (informational only, no automated detection). A distributed-lock primitive (tracker-comment claim or custom-field lease) is deferred to v6.9.0+.
20. **No webhook circuit breaker / rate limiter** — advisory-only pattern preserved; `core/post-publish-hook.md` Section 3 `curl --max-time 5` already bounds per-event wall-clock. A per-run circuit-breaker is deferred to v6.9.0 if operators report webhook-stall backpressure (see Known Limitations §8.3).
21. **No webhook URL scheme validation / SSRF guard** — Webhook URL is operator-trusted input from `### Notifications`. Operators are responsible for restricting URL values to internal observability endpoints. Hardening (scheme allowlist, loopback/link-local block) is deferred to v6.9.0; see Known Limitations §8.4.
22. **No MCP ping retry / backoff** — single-ping fail-fast preserves exit-3 determinism. Operators configure cron retry cadence; see Known Limitations §8.5.

---

## Section 7: Open Design Decisions Resolved (Gate 1 Ledger)

| # | Decision | Resolution | One-line rationale |
|---|---|---|---|
| 1 | Token field name | `tokens_used` | Roadmap lines 672/677 verbatim; ceos Task tool returns measured counts, not estimates — diverges from forge's `tokens_estimated` intentionally. Cross-plugin reconciliation deferred (see §8.6). |
| 2 | Schema version | stays `"1.0"` | State-manager has no version check; additive; roadmap line 714 classifies as PATCH; `/resume-ticket` is a 5-field-path reader. |
| 3 | Event granularity | top-level stages only | `iteration_count` is a per-stage summary field; per-iteration events would triple webhook volume and duplicate pipeline.log. |
| 4 | `core/` refactor | EXTEND `core/post-publish-hook.md` | One file already owns the curl+advisory pattern; new file = rename blast radius. |
| 5 | Webhook payloads | roadmap minimum + `run_id` on all 3 + `outcome` on `pipeline-completed` | Roadmap is floor; `run_id` correlates re-runs at 1 string cost; `outcome` avoids useless completion event without pass/fail. |
| 6 | Dry-run semantics | full short-circuit | Cron-safety: concurrent dry-runs must not false-positive locks; monitoring must not see events for non-runs. |
| 7 | Feature-Workflow absence | `[WARN]` + bug-only | Silent hides misconfiguration from cron ops; hard-block breaks fix-bugs-only projects; `[WARN]` is the operations-correct middle. |
| 8 | Lock mechanism | `mkdir`-based portable bash | Bash already required by test harness; `mkdir` is POSIX+NTFS atomic; no new cross-platform dependency (REVISED from judge's PowerShell CreateNew). |
| 9 | `/metrics` evolution | additive state.json-read + heuristic fallback; NO `--format json` | Reads measured when present, falls back to constants; output format unchanged; measured/estimated reported as separate line items (COST-R8/R11). |
| 10 | Summary output | inside `state.json.pipeline.summary_table` + stdout echo | One read target for `/metrics`; no new artifact to version; deferred separate file to v6.9.0. Truncation bounded (COST-R10). |
| 11 | Autopilot `disable-model-invocation` | `true` | Autopilot dispatches fix-ticket/implement-feature → all 14 existing dispatchers carry the flag. |
| 12 | Batch events | NOT added | Per-issue events with `run_id` carry enough correlation signal; batch lifecycle events deferred to v6.9.0. |

---

## Section 8: Known Limitations (Informational)

These are intentional v6.8.0 constraints surfaced by reviewers that do NOT block ship but must be visible to operators. Each has a forward pointer.

### 8.1 `run_id` uniqueness across re-runs

For v6.8.0, `run_id` is defined as `"{issue_id}_{YYYYMMDDTHHMMSSZ}"` (compact basic-format ISO-8601 — no colons, no dashes in the time component; see design.md §4.3 onwards). Example: `PROJ-42_20260417T143000Z`. This form is designed to be URL-safe, filename-safe (NTFS-compatible), and shell-word-safe. Each re-run of the same issue produces a distinct `run_id` because the timestamp differs. **Caveat:** two re-runs that start within the same whole second would collide; collision probability in practice is negligible (Autopilot is sequential; Task-tool dispatch takes >1s) but consumers writing exactly-once pipelines SHOULD also correlate on `issue_id` + observed event ordering. A monotonic invocation counter was deferred — it would require a counter store and breaks the 1-string-cost rationale.

### 8.2 Lock scope is process-local, not tracker-level

`.ceos-agents/autopilot.lock/` guards concurrent Autopilot runs on ONE host / filesystem. Multi-host deployments against the SAME tracker are NOT coordinated. The authoritative operator-side mitigation is DISJOINT-QUERY configuration: operators MUST either (a) run Autopilot from exactly one host or (b) configure disjoint `Bug query` / `Feature query` filters per host (e.g., per-host assignee or label filters). AUTOPILOT-R13 emits an INFO line with the hostname on every successful lock acquisition to aid log correlation, but this line is purely informational — the plugin provides NO automated detection of cross-host contention (no sidecar hint file; the sidecar-based warning considered in revision 1 was removed in revision 2 as its detection fired after damage had already happened and introduced its own persistent-file race). See `docs/guides/autopilot.md#single-host-operation` for operational guidance. Tracker-level distributed lock is NOT_IN_SCOPE (§6.19).

### 8.3 Webhook blast radius (no circuit breaker)

Each pipeline fires up to 15 webhook events (`pipeline-started` + ≤13 `step-completed` + `pipeline-completed`). `curl --max-time 5` bounds per-event wall-clock. A slow/broken webhook endpoint on a 10-issue Autopilot batch CAN add up to `10 × 15 × 5s = 750s` (12.5min) of wall-clock. No circuit breaker is implemented in v6.8.0. Mitigation: operators configuring `Webhook URL` SHOULD verify endpoint responsiveness and remove `step-completed` from `On events` if stalling is observed. Circuit breaker deferred to v6.9.0 (§6.20).

### 8.4 Webhook URL is operator-trusted (no SSRF guard)

The plugin issues `curl` to the exact string in `### Notifications.Webhook URL` with no scheme validation, loopback block, or link-local block. Operators MUST treat this key as a trusted configuration input. Mitigation is documented in `docs/guides/autopilot.md` and `docs/reference/config.md`. Scheme allowlist / SSRF guard deferred to v6.9.0 (§6.21).

### 8.5 MCP ping has no retry / backoff

A transient MCP outage at the moment Autopilot fires exits 3 and the cron cycle is skipped. No state is recorded (per AUTOPILOT-R12 "no side-effects"). Operators relying on per-cycle observability SHOULD configure their cron harvester to capture exit codes. A retry/backoff primitive deferred to v6.9.0 (§6.22).

### 8.6 `tokens_used` vs forge's `tokens_estimated`

ceos-agents uses `tokens_used` (measured) while sibling plugin `forge` uses `tokens_estimated` (judge-inferred). The field names intentionally differ to signal the underlying data source. No cross-plugin reconciliation is provided in v6.8.0; future cross-plugin dashboards (ASYSTA or equivalent) will need a rename dictionary. This decision is documented in Section 7 row 1 and in `CHANGELOG.md` v6.8.0 Known Issues subsection.

### 8.7 `pipeline.summary_table` is markdown-in-JSON

Acknowledged trade-off (Skeptic flag in brainstorm). The markdown string is a CONVENIENCE PROJECTION; structured data lives in `pipeline.total_tokens / total_duration_ms / total_tool_uses` plus the per-stage fields. Consumers wishing to re-render SHOULD read the structured fields and regenerate their own table; the markdown may evolve (column order, units) in a future MINOR version without violating schema_version. This guidance is documented in `state/schema.md`.

### 8.8 AC-13 grep is indicative, not contract-binding

AC-13 verifies the `pr-created` and `issue-blocked` payload field lists via `grep -A3` which prints lines but does not parse JSON. A future edit that adds a field would still pass. Fixture-based byte-diff verification is deferred; AC-13 is sufficient as a regression guard against accidental format changes but not against malicious or semantic drift.

### 8.9 Stage-name canonical form: `reproduction`

State schema uses `reproduction` (singular, passive-voice object-name). Webhook `step_name` and design narrative also use `reproduction`. The agent file is `agents/reproducer.md` (the actor); the stage (the record) is `reproduction`. Implementers MUST use `reproduction` in `state.json` and webhook `step_name`.
