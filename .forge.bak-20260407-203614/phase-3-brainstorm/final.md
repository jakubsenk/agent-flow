# Phase 3: Brainstorm Synthesis — Autopilot Skill

## Approach A: Conservative — Thin Dispatcher (Agent A)

**Philosophy:** Autopilot does the absolute minimum: lock, fetch, classify, dispatch, log, unlock. All pipeline logic stays in fix-ticket and implement-feature.

**Design:**
- SKILL.md is ~150 lines. Reads config, acquires lock, queries tracker twice (Bug query + Feature query), merges results, dispatches fix-ticket or implement-feature per issue via Skill tool, logs outcomes, releases lock.
- No new agents needed.
- Config section: 3 keys only (Max issues per run, Lock timeout, On error).
- Lock: simple `.ceos-agents/autopilot.lock` with timestamp.
- Log: append to `.ceos-agents/autopilot.log` in human-readable format.
- No state directory, no run history database.

**Strengths:** Minimal surface area. Reuses all existing pipeline logic. Easy to understand, test, and maintain. Follows the "best code is no code" principle.

**Weaknesses:** Limited configurability. No separate bug/feature limits. No dry-run support from config (only via --dry-run flag). No programmatic run history.

## Approach B: Innovative — Extensible Runner (Agent B)

**Philosophy:** Autopilot is a foundation for future server deployment. Build extensible from day one.

**Design:**
- SKILL.md is ~300 lines. Full-featured runner with mode selection (poll-once vs continuous), priority sorting, issue deduplication, webhook notifications on completion.
- Config section: 8 keys (Max issues, Lock timeout, Bug limit, Feature limit, Log file, On error, Dry run, Priority sort).
- Separate run state directory: `.ceos-agents/autopilot/runs/{timestamp}/` with summary.json per run.
- Integration with Notifications config for completion webhooks.
- Extensibility point: `### Autopilot Hooks` for pre-run and post-run custom actions.

**Strengths:** Future-proof. Rich reporting. Notification integration. Priority-based processing.

**Weaknesses:** Over-engineered for PoC. Many config keys to document and test. Run state directory adds complexity. Hooks pattern duplicates existing Hooks section. Continuous polling mode is irrelevant for cron-based invocation.

## Approach C: Skeptical — Defensive Runner (Agent C)

**Philosophy:** Focus on what goes wrong. Every failure mode must be handled explicitly.

**Design:**
- SKILL.md is ~200 lines. Emphasizes defensive checks at every step.
- Pre-flight: MCP check, config validation, lock check, disk space check.
- Per-issue: check tracker state, check local state, check branch conflicts, timeout per issue.
- Post-run: cleanup lock, cleanup orphan state, summary report.
- Config section: 5 keys (Max issues, Lock timeout, Log file, On error, Issue timeout).
- Mandatory cool-down: after processing max_issues, write a cool-down marker that prevents the next cron invocation from running for N minutes (prevents rapid re-processing of the same backlog).

**Strengths:** Robust failure handling. Cool-down prevents thrashing. Comprehensive pre-flight catches problems early.

**Weaknesses:** Issue timeout is hard to enforce (Claude CLI sessions do not have reliable timeout mechanisms). Cool-down marker adds state complexity. Disk space check is overkill for markdown plugin. Some defensive checks duplicate what the dispatched pipelines already do.

## Cross-Critique

**A critiques B:** The run state directory and hooks are YAGNI. No user has asked for autopilot webhooks or continuous polling. Build the minimum, extend when there is a real need.

**A critiques C:** Issue timeout and disk space checks add complexity that provides no real value. The dispatched pipelines already handle their own errors. Cool-down is interesting but should be a future feature, not PoC scope.

**B critiques A:** Too minimal. No dry-run from config means testing requires flag knowledge. No separate bug/feature limits means you cannot say "process 3 bugs but only 1 feature per run". Log file path being hardcoded limits deployment flexibility.

**B critiques C:** Cool-down marker is state that can go stale. Better to use the lock timeout for this purpose. Issue timeout is unimplementable in the current architecture.

**C critiques A:** Lock file with only timestamp is insufficient. What if the clock skews? At least add hostname for multi-machine scenarios (future-proofing).

**C critiques B:** Continuous polling mode in a markdown skill is architecturally wrong. Claude CLI runs a prompt and exits. Continuous mode would require a shell loop around Claude, which is outside the plugin's scope.

## Synthesis: Recommended Approach

**Selected: Approach A (Conservative) with targeted additions from B and C.**

### Final Design Decisions

1. **Skill architecture:** Thin dispatcher SKILL.md (~180 lines). No new agents. No sub-skills.

2. **Dispatch mechanism:** Use the Skill tool to invoke `/ceos-agents:fix-ticket {ISSUE-ID}` for bugs and `/ceos-agents:implement-feature {ISSUE-ID}` for features. Sequential processing, one issue at a time.

3. **Lock file design:** File at `.ceos-agents/autopilot.lock` with content: `started_at` timestamp + `host` hostname. Stale detection: time-based with configurable timeout (default 120 minutes). Acquisition via write-then-check pattern (write .tmp, rename). Release on completion or error (finally pattern in SKILL.md instructions).

4. **Config section:** 7 keys from Approach B's richer set (adopted from critique):
   - Max issues per run (default: 1)
   - Lock timeout (default: 120 minutes)
   - Log file (default: `.ceos-agents/autopilot.log`)
   - Bug limit (default: 0, meaning "use Max issues per run")
   - Feature limit (default: 0, meaning "use Max issues per run")
   - On error (default: `skip`)
   - Dry run (default: `false`)

5. **Logging:** Append-only human-readable log at configurable path. Format from A6 research answer (timestamped key=value entries).

6. **Issue classification:** Two separate queries (Bug query + Feature query). Bug-first priority. Deduplication if same issue appears in both.

7. **Run state:** No separate state directory. Log file is the run history. Lock file is the concurrency guard. Per-issue state is managed by the dispatched pipelines.

8. **Error boundaries:** MCP pre-flight failure or lock failure = stop run. Per-issue errors = skip (configurable via On error). From Approach C: add explicit pre-flight validation (MCP + config) before any dispatch.

### Failure Mode Analysis

| Failure | Behavior | Recovery |
|---------|----------|----------|
| Lock file exists, not stale | Log, exit immediately | Wait for previous run to finish |
| Lock file exists, stale | Remove stale lock, acquire new one, log warning | Automatic |
| MCP server unavailable | Log error, exit with non-zero | Check MCP config, restart server |
| Bug query returns empty | Log "no bugs found", continue to features | Normal |
| Feature query not configured | Log "no feature query", skip features | Normal |
| Pipeline dispatch fails | Log error, skip issue (or stop if On error = stop) | Issue remains in tracker, picked up next run |
| Pipeline blocks issue | Normal block behavior (comment on issue) | Human reviews blocked issue |
| Claude CLI crash mid-run | Lock file remains, goes stale after timeout | Next invocation cleans up |

### Scope Boundaries

**In PoC:**
- Single skill SKILL.md
- 7-key config section
- Lock file with stale detection
- Append-only log
- Two-query issue classification
- Sequential processing
- Windows Task Scheduler + cron documentation

**Future (NOT in PoC):**
- Continuous polling mode
- Webhook notifications on completion
- Priority-based issue ordering
- Parallel issue processing
- Cool-down mechanism
- Run history UI/dashboard integration
- Server deployment support
