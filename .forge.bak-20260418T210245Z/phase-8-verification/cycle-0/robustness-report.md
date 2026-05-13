# Phase 8 Robustness Adversary Report

**Persona:** Robustness Adversary (dimension weight: 0.2)
**Cycle:** 0
**Date:** 2026-04-17
**Scope:** v6.8.0 — Autopilot + Observability Hooks + Real-Time Cost Visibility

---

## Scenario Probe Results

| # | Scenario | Expected | Observed | Severity |
|---|---|---|---|---|
| 1 | Missing `Webhook URL` in Automation Config Notifications | Graceful no-op | PASS — every fire site is gated `if Webhook URL configured AND {event} in On events` (skills/fix-ticket/SKILL.md:91,168,194,306,346,385,417,438,460,485,495,529). Parser at line 62 reads `Webhook URL` as "may be absent". Silent skip path. | INFO |
| 2 | Webhook URL configured but receiver returns 500 | Pipeline continues (advisory) | PASS — every fire site has "On failure: log `[WARN] Webhook delivery failed: {error}`, continue". Backed by core/post-publish-hook.md §4 curl pattern `--max-time 5 --retry 0`. | INFO |
| 3 | Malformed `On events` token (typo e.g. `step_completed` with underscore) | Warning emitted | FAIL — token parsing at fix-ticket:62 says "Parse On events into a token set for event filtering". No validation against the known-token allowlist `{pr-created, issue-blocked, pipeline-started, step-completed, pipeline-completed}`. A typo like `step_completed` silently never fires. Nothing in CLAUDE.md Notifications guidance catches this. No "unknown token" warning. | LOW |
| 4 | Webhook URL with DNS failure — does `curl --max-time 5` return in 5s | Bounded | PASS — `--max-time 5` caps total wall-clock including DNS resolution (standard curl semantics). Documented in core/post-publish-hook.md §4 "Curl Pattern" and Known Limitations §8.3. | INFO |
| 5 | 50 step-completed events in rapid succession from a 10-issue Autopilot batch | No throttle/batching; documented operator concern | PASS — Known Limitations §8.3 "Webhook blast radius" explicitly computes `10 × 15 × 5s = 750s (12.5min)` worst-case and recommends removing `step-completed` from `On events` if stalling is observed. Circuit breaker deferred to v6.9.0. Fully documented. | INFO |
| 6 | `autopilot.lock/` present BUT stale (>120 min) — reclaimed via `find -mmin +121` OR awk mktime | Correct re-acquisition | PASS — Primary path uses `awk mktime`; fallback at SKILL.md:189-204 uses `find "$LOCK_DIR/owner.json" -mmin +121 -print`. +5min NFS buffer at line 128 bumps effective threshold to 125min. Both paths exercised by test `autopilot-lock-stale-awk-missing.sh` (design.md §3.7). | INFO |
| 7 | `autopilot.lock/` present AND fresh (<120 min) — distinct exit code | exit 2 per AUTOPILOT-R3 | PASS — SKILL.md line 222-223 emits `[autopilot][ERROR] Another Autopilot run in progress (pid=..., host=..., since=...)` and `exit 2`. Exit-code matrix (SKILL.md:327-333 + docs/guides/autopilot.md:330-338) documents distinctness from 1 (preflight) and 3 (MCP). | INFO |
| 8 | `autopilot.lock/` present but `owner.json` MISSING | Defensive — treat as stale | PASS — SKILL.md:163-173 explicitly handles `[ ! -f "$LOCK_DIR/owner.json" ]`: `rm -rf` + re-mkdir; recovery-race path falls to exit 2 with clear error. | INFO |
| 8b | `owner.json` CORRUPTED (empty/partial) | Defensive | PASS — SKILL.md:175-187 parses `acquired_at` via grep; empty extract triggers defensive stale-recovery (same pattern as 8). Documented in docs/guides/autopilot.md:364-367 "`owner.json` corruption". | INFO |
| 9 | Empty `Bug query` result + no `Feature query` configured | Log "no work" and exit 0 | PARTIAL — Exit matrix (SKILL.md:329) lists "empty queue" → exit 0 correctly. BUT: no explicit log line like `[autopilot][INFO] No issues match queries — exiting with no work` is specified in Step 5 classification. Step 7 summary will render a table with 0 rows. Operator observability is thin. | LOW |
| 10 | Both queries empty | Exit 0 | PARTIAL — Same as #9: exit 0 documented, but no dedicated "no work" log line. Cron operators parsing logs for "work happened" signal must infer from absence of dispatch lines. | LOW |
| 11 | MCP tracker unreachable | exit 3 per AUTOPILOT-R12 | PASS — Step 0 (SKILL.md:79-83): `[STOP] MCP unreachable — {error}` on stderr, `exit 3`, no lock acquired. Test `autopilot-mcp-unreachable.sh` asserts all three invariants. | INFO |
| 12 | Python 3 not installed, BusyBox < 1.30 awk fallback | works via find -mmin | PASS — Design doc §3.7 and §4.8 explicitly state "no Python 3 dependency". Fallback at SKILL.md:189-204 via `find -mmin +121`. Test `autopilot-lock-stale-awk-missing.sh` stubs awk to simulate BusyBox. docs/guides/autopilot.md:368-378 documents platform support. | INFO |
| 13 | `Log file` path not writable (permission error) | Graceful degradation | FAIL — The `Log file` key (default `.ceos-agents/autopilot.log`) is defined in §4.7 and config table (SKILL.md:53) but the SKILL.md Process section NEVER describes how/when it is written. Step 7 "Final summary" emits markdown to stdout only (SKILL.md:301-316); there is no append step to the log file. Consequently the permission-error scenario has no handler. Either the feature is silently unimplemented, or the implementation is left to the operator's shell redirection (`>> /var/log/autopilot.log 2>&1` in docs/guides/autopilot.md:126). Spec contract says "Append-only run log. Each invocation appends a timestamped summary line" — but no step writes it. | MEDIUM |
| 14 | Task tool returns NO usage metadata (unexpected shape) | Write 0 defensively | PASS — core/state-manager.md:101 "If `result.usage` is null or any individual field is absent (COST-R3): write `0` for each missing count, do not retry, do not block the pipeline." Every fix-ticket post-dispatch block says `(fallback 0 for each missing field)`. Test `cost-usage-null-defensive.sh` asserts. | INFO |
| 15 | v6.7.2 state.json (no usage fields) read by v6.8.0 `/resume-ticket` | Graceful additive read | PASS — COST-R9; state-manager.md:150-161 "Backward-Compatible Read" rules (missing → 0/null). `/resume-ticket` reads a fixed set of field paths and does not reference usage fields. Test `cost-resume-v6.7-state.sh` asserts exit 0. | INFO |
| 16 | Multiple state.json files — does `/metrics` aggregate multiple runs? | Per-pipeline line items, no mixed grand total | PASS — skills/metrics/SKILL.md Step 6a globs `.ceos-agents/*/state.json`, classifies each as MEASURED / ESTIMATED / HYBRID, emits separate line items with provenance footer. Test `metrics-dual-mode.sh` asserts. COST-R7/R8/R11 satisfied. | INFO |
| 17 | Fixer-reviewer crashed mid-iteration — cumulative `tokens_used` valid (not doubled, not lost) | Running total preserved | PARTIAL — fix-ticket:310 "On first fixer invocation of this run, write atomically [zeros]. On subsequent iterations (loop): do not reset the counters — cumulative addition applies." Pattern is correct. BUT: if a mid-iteration crash kills the shell before the post-dispatch accumulator write, the iteration's tokens are lost (not doubled). Acceptable ("state loss is acceptable; pipeline must not block on state write failure" — state-manager.md:31). However there is no test for crash-mid-iteration — `cost-state-fields.sh` only tests happy path. Documented behavior is correct; regression test coverage is thin. | LOW |
| 18 | Clock skew (NTP re-sync mid-run) — `duration_ms = completed_at - started_at` negative? | Handled | FAIL — state-manager.md:96 literally says `{stage}.duration_ms = completed_at epoch ms − started_at epoch ms`. No `max(0, ...)` clamp. No "if negative, treat as 0" defensive guard. An NTP step backwards during a stage will produce a negative `duration_ms`, which then propagates into `pipeline.total_duration_ms` (sum), and into the webhook `duration: {pipeline.total_duration_ms / 1000}`. Consumers receiving `"duration": -12` will be confused. | LOW |
| 19 | summary_table with 21 rows OR 4001 chars — truncation rule actually triggers and adds notice row | Truncation notice emitted | PASS — fix-ticket:491 and state-manager.md:134 describe COST-R10 row-wise truncation and `(truncated, N more stages in pipeline.log)` notice row before Total. Test `cost-summary-truncation.sh` stubs 25 stages and asserts the truncation notice appears. | INFO |
| 20 | Run Autopilot from two different hosts simultaneously — guide warns? | Documented prominently | PASS — docs/guides/autopilot.md has a dedicated `## Single-Host Operation` section (lines 156-213) with a blockquote "Important" callout, concrete disjoint-query examples (per-host assignee filter, per-host component filter, per-host priority filter), AUTOPILOT-R13 INFO-line rationale, and explicit "This line is informational. It does not detect cross-host contention". SKILL.md §Cross-Host Operation and NOT_IN_SCOPE §6.19 reinforce. | INFO |

**Summary:** 14 PASS (INFO), 4 PARTIAL (LOW), 1 FAIL (LOW — #3), 1 FAIL (MEDIUM — #13). No HIGH-severity findings.

---

## Findings

### [ROBUSTNESS-FINDING-1] severity=MEDIUM

**Scenario:** #13 — `Log file` key defined in config but never written by the Process section.

**Location:** `skills/autopilot/SKILL.md` §Configuration table (line 53) vs §Process Step 7 (lines 301-316).

**Expected:** The `Log file` key is documented as "Append-only run log. Each invocation appends a timestamped summary line" — so the Process section should describe (a) when the log line is appended, (b) what happens when the path is not writable (graceful degradation expected, per state-manager.md precedent).

**Observed:** No step in the Process section (Steps 0–7) appends anything to the `Log file` path. Step 7 emits a markdown summary table to stdout only. The only reference to the log path in the guide (docs/guides/autopilot.md:126) relies on operator-side `>> /var/log/autopilot.log 2>&1` shell redirection — not on the `Log file` config key. Result: the `Log file` key is currently dead configuration; operators who configure a path will see no effect, and the permission-error path cannot be exercised because no write is attempted.

**Remediation:** Either (a) add Step 7.3 "Append summary line to `Log file`; on write failure log `[autopilot][WARN] Log file not writable: {error}. Summary available on stdout.` and continue" OR (b) drop the `Log file` key from the §Autopilot config table (breaking-compat risk — better to implement). Option (a) preferred; aligns with state-manager.md's advisory-write precedent and does not require a MAJOR bump.

---

### [ROBUSTNESS-FINDING-2] severity=LOW

**Scenario:** #3 — `On events` typo (e.g. `step_completed` instead of `step-completed`) silently never fires.

**Location:** `skills/fix-ticket/SKILL.md:62` "Parse `On events` into a token set for event filtering throughout the pipeline." (and identical parsing in the other 3 pipeline skills).

**Expected:** An unknown token (one not in the known allowlist `{pr-created, issue-blocked, pipeline-started, step-completed, pipeline-completed}`) should produce a one-time `[WARN] Unknown event token in On events: {token}. Known tokens: ...` at pipeline start. Operators typo-ing `step_completed` with an underscore would otherwise debug a silent webhook-never-fires condition for hours.

**Observed:** No validation step anywhere in fix-ticket, fix-bugs, implement-feature, scaffold, or core/post-publish-hook.md §4 "On events Filter" section. The filter says "If a token is present in the `On events` list, the webhook fires. If omitted, the event is skipped silently." — which is correct semantics for OMITTED but wrong for UNKNOWN (both are treated as omitted).

**Remediation:** Add to core/post-publish-hook.md §4.On-events-filter a "Validation" subsection: "At pipeline start, after parsing `On events` into a token set, emit `[autopilot][WARN] Unknown event token(s) in On events: {csv-unknowns}. Known tokens: pr-created, issue-blocked, pipeline-started, step-completed, pipeline-completed.` if any non-allowlisted tokens are present. Do not block." Single-line change per pipeline skill.

---

### [ROBUSTNESS-FINDING-3] severity=LOW

**Scenario:** #9 / #10 — Empty `Bug query` result (+ empty `Feature query`) produces no log line signalling "no work".

**Location:** `skills/autopilot/SKILL.md` Step 5 classification loop (lines 267-275) + Step 7 summary (lines 301-316).

**Expected:** A dedicated `[autopilot][INFO] No issues matched queries (bug={N} feature={M}). Exiting with no work.` line so cron log harvesters can distinguish "ran and had nothing to do" from "crashed before fetch".

**Observed:** The Step 5 classification produces an empty dispatch list silently. Step 7 renders an empty markdown summary table ("0 success, 0 blocked, 0 errored"). Exit code 0 per the exit matrix. Distinguishable from a crash only by inspecting the Step 3 INFO line. Acceptable but thin for operator observability.

**Remediation:** Between Step 5.4 and Step 6, add: "If dispatch list is empty, emit `[autopilot][INFO] No issues matched queries (bug_count={N}, feature_count={M}). Exiting with no work.` and skip Step 6." Exit 0 through the normal trap path. Pure UX polish.

---

### [ROBUSTNESS-FINDING-4] severity=LOW

**Scenario:** #18 — NTP re-sync during a stage produces a negative `duration_ms` which then propagates into webhook `duration` and into `pipeline.total_duration_ms`.

**Location:** `core/state-manager.md:96`: `{stage}.duration_ms = completed_at epoch ms − started_at epoch ms`. No clamp.

**Expected:** `duration_ms = max(0, completed_at − started_at)` with a one-time WARN log when the clamp triggers: `[autopilot][WARN] Negative duration detected for stage {name} ({raw_ms} ms). Clamping to 0. Likely NTP re-sync during dispatch.`

**Observed:** No clamp, no warning. A negative `duration` propagates into the `step-completed` webhook payload (webhook consumers could receive `"duration": -12`) and into `pipeline.total_duration_ms` (subtractive — could produce an artificially low total).

**Remediation:** Update state-manager.md §"Stage Lifecycle Writes" after-dispatch block: `{stage}.duration_ms = max(0, completed_at epoch ms − started_at epoch ms)`. Add a sentence: "If the subtraction is negative (clock skew / NTP re-sync during dispatch), clamp to 0 and log `[WARN] Negative stage duration clamped`." One-line fix per pipeline skill plus state-manager contract update.

---

### [ROBUSTNESS-FINDING-5] severity=LOW

**Scenario:** #17 — Fixer-reviewer mid-iteration crash has no regression test.

**Location:** Test catalog (design.md §3.7). Tests cover happy path (`cost-state-fields.sh`) and null-usage (`cost-usage-null-defensive.sh`) but no scenario where fixer-reviewer accumulates 2 iterations, crashes in the 3rd, then is resumed.

**Expected:** A test `cost-fixer-reviewer-crash-recovery.sh` that (a) runs 2 iterations, each adding 10k tokens → 20k total written; (b) kills the shell mid-3rd-iteration before state.json write; (c) re-runs `/resume-ticket`; (d) asserts `fixer_reviewer.tokens_used == 20000` (no doubling, no loss of the committed 20k).

**Observed:** No such test. Documented behavior is correct ("state loss is acceptable" per state-manager.md:31); empirical regression coverage is thin.

**Remediation:** Add the scenario to tests/scenarios/ in v6.8.1 (not ship-blocking for v6.8.0). Current tests verify the accumulator formula; this gap is about crash-recovery surface area, not about broken behavior.

---

## Dimension Score

**robustness_score:** 0.83

**Rationale:**
- 14 of 20 scenarios are fully PASS with explicit spec/impl/test coverage.
- 4 are PARTIAL (LOW severity — UX polish or test-coverage gaps, no behavioral break).
- 1 LOW-severity functional bug (unknown On events token silently ignored — #3).
- 1 MEDIUM-severity feature-completeness bug (`Log file` key is dead config — #13).
- Zero HIGH-severity findings.

Weighted per-severity deduction:
- MEDIUM × 1 = −0.10
- LOW × 4 = −0.04 each for finding-grade LOWs, −0.02 each for polish-grade = −0.08
- Starting score 1.0 − 0.10 − 0.08 + 0.01 (extensive documentation of blast-radius §8.3 and cross-host §8.2) = 0.83.

Composite threshold per verify.md: dimension weight 0.2 → contribution to commander composite = 0.83 × 0.2 = 0.166.

---

## Top 3 Risks (regardless of composite score)

1. **[MEDIUM] `Log file` is dead config** (Finding 1) — operators will configure it expecting behavior that does not exist. Either implement the append or drop the key. Shipping with the key advertised but unwired is the worst option.
2. **[LOW] Unknown `On events` tokens silently drop** (Finding 2) — typos in CSV event lists produce silent observability gaps. One-time validation warning at pipeline start fixes it. Cheap.
3. **[LOW] Negative `duration_ms` on NTP re-sync** (Finding 4) — visible to webhook consumers as `"duration": -12`. `max(0, …)` clamp. Trivial.
