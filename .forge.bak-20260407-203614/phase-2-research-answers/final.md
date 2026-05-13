# Phase 2: Research Answers — Autopilot Skill

## A1: Lock File Mechanism

**Recommendation:** File-based lock at `.ceos-agents/autopilot.lock`

**Format:** Plain text file containing:
```
pid: {process identifier or "claude-session"}
started_at: {ISO 8601 timestamp}
host: {hostname}
```

**Stale lock detection:** Time-based. If the lock file exists and `started_at` is older than `Lock timeout` config value (default: 120 minutes), treat as stale and remove it. PID-based detection is unreliable across platforms and especially for Claude CLI sessions.

**Rationale from codebase:** The state-manager (`core/state-manager.md`) uses atomic tmp-rename writes. The lock file should follow the same pattern: write to `.ceos-agents/autopilot.lock.tmp`, then rename. On Windows, atomic rename is best-effort (state-manager line 29 acknowledges this). For the PoC, a simple check-then-create is sufficient since the primary concurrency scenario is cron-vs-cron, which has second-level granularity.

**Location:** `.ceos-agents/autopilot.lock` — consistent with the `.ceos-agents/` directory pattern used by all pipeline state. This directory already exists in projects using ceos-agents.

## A2: Issue Type Classification

**Recommendation:** Run two separate queries, one for Bug query and one for Feature query.

**Rationale from codebase:**
- `fix-bugs/SKILL.md` line 99: "Use Bug query from Automation Config via the MCP server matching Type."
- `implement-feature/SKILL.md`: works with single ISSUE-ID, no query-based fetch
- `status/SKILL.md` line 22-23: queries both Bug query states and Feature query (if configured)
- The config already has separate queries: `Bug query` in `### Issue Tracker` and `Feature query` in `### Feature Workflow`

**Strategy:**
1. Fetch issues from Bug query -> tag as "bug"
2. Fetch issues from Feature query (if configured) -> tag as "feature"
3. If an issue appears in both queries -> treat as "bug" (bug takes priority, consistent with bug-fix pipeline being the more conservative path)
4. If Feature query is not configured -> process bugs only

## A3: Skill-to-Skill Dispatch

**Recommendation:** Inline orchestration instructions in the SKILL.md.

**Rationale from codebase:**
- Skills are markdown documents that Claude interprets directly. There is no Skill() tool for programmatic dispatch.
- `fix-bugs/SKILL.md` dispatches agents via "Task tool" (e.g., line 105: "run `ceos-agents:triage-analyst` (Task tool, model: sonnet)")
- But fix-bugs/implement-feature are themselves skills, not agents. Skills are invoked by the user or by instruction.
- For autopilot, the correct pattern is: the SKILL.md instructs Claude to "invoke `/ceos-agents:fix-ticket {ISSUE-ID}`" or "invoke `/ceos-agents:implement-feature {ISSUE-ID}`" — Claude can invoke skills via the Skill tool or by following the SKILL.md instructions.
- Actually, checking the Skill tool availability — skills CAN invoke other skills via the `Skill` tool (available in the runtime).

**Dispatch pattern:** The autopilot SKILL.md will instruct: "For each issue, use the Skill tool to invoke the appropriate pipeline skill."

## A4: "Already In Progress" Detection

**Recommendation:** Dual detection — check both issue tracker state AND local state.

**Strategy:**
1. **Tracker state check:** After fetching issues from the query, check each issue's current state. If the state matches "In Progress" (from State transitions config), skip it.
2. **Local state check:** Check if `.ceos-agents/{ISSUE-ID}/state.json` exists with `status: "running"`. If yes, skip.
3. **Lock file check:** The global autopilot lock prevents the entire autopilot from running concurrently, which prevents duplicate processing.

**Rationale from codebase:**
- `status/SKILL.md` line 24: queries issues "in active states: States from Automation Config -> Issue Tracker -> State transitions (In Progress, Blocked, For Review)"
- `state/schema.md`: state.json has `status` field with values including "running"
- The Bug query and Feature query in Automation Config typically already filter for specific states (e.g., "Open" or "To Fix"), so "In Progress" issues should not appear in query results. But the autopilot should be defensive.

## A5: Config Section Design

**Recommendation:** New `### Autopilot` optional config section.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| Max issues per run | integer | `1` | Maximum number of issues to process in a single autopilot invocation |
| Lock timeout | integer | `120` | Minutes before a stale lock file is considered expired and removed |
| Log file | string | `.ceos-agents/autopilot.log` | Path to the autopilot run log |
| Bug limit | integer | `0` | Max bugs to process per run (0 = use Max issues per run) |
| Feature limit | integer | `0` | Max features to process per run (0 = use Max issues per run) |
| On error | string | `skip` | Behavior on issue processing error: `skip` (continue to next) or `stop` (halt run) |
| Dry run | boolean | `false` | If true, fetch and classify issues but do not dispatch pipelines |

**Interaction with existing config:**
- Bug query is read from `### Issue Tracker` -> Bug query (existing)
- Feature query is read from `### Feature Workflow` -> Feature query (existing, optional)
- State transitions are read from `### Issue Tracker` -> State transitions (existing)

**Rationale:** Follows the convention from other optional sections (e.g., Error Handling has `On block` and `Max blocked per run` with table format). Keys use human-readable names in `| Key | Value |` format per config-reader.md convention.

## A6: Run State Persistence

**Recommendation:** Lightweight run log, no dedicated state directory.

**Format:** Append-only log file at the path specified by `Log file` config key (default: `.ceos-agents/autopilot.log`). Each entry is a single line:

```
[{ISO 8601}] RUN_START max_issues={N}
[{ISO 8601}] ISSUE_FOUND id={ISSUE-ID} type={bug|feature} title="{title}"
[{ISO 8601}] ISSUE_SKIP id={ISSUE-ID} reason={in_progress|already_processed|locked}
[{ISO 8601}] ISSUE_DISPATCH id={ISSUE-ID} pipeline={fix-ticket|implement-feature}
[{ISO 8601}] ISSUE_RESULT id={ISSUE-ID} result={success|blocked|error} detail="{detail}"
[{ISO 8601}] RUN_END total={N} processed={N} skipped={N} errors={N}
```

**Rationale:** No complex state persistence needed for the PoC. The run log provides audit trail. Issue state transitions in the tracker serve as the source of truth for what has been processed. The `.ceos-agents/{ISSUE-ID}/state.json` files from the dispatched pipelines persist per-issue state. The autopilot itself does not need additional state beyond the log and the lock file.

## A7: Logging Format and Location

**Recommendation:** Human-readable timestamped log at `.ceos-agents/autopilot.log`.

**Rationale:** The JSONL format from `pipeline.log` (per state-manager.md) is designed for machine parsing within a single pipeline run. The autopilot log serves a different purpose: cross-run audit trail for the human operator. Human-readable format with structured fields (key=value) is a good middle ground — parseable but readable.

The log is append-only. Each autopilot invocation appends a RUN_START/RUN_END block. Old entries are preserved for history.

## A8: Error Boundaries and Recovery

**Recommendation:**

**Skip and continue (default `On error: skip`):**
- MCP query failure for individual issue -> skip that issue, log error
- Pipeline dispatch failure (skill invocation error) -> skip, log error
- Pipeline block (issue blocked by agent) -> normal pipeline behavior, logged as "blocked"

**Stop the entire run:**
- MCP pre-flight failure (no tracker connectivity at all) -> stop with clear error
- Lock acquisition failure (another run in progress) -> stop immediately
- Config parsing failure -> stop with actionable error

**Partial failure handling:** The run log entry ISSUE_RESULT captures the outcome per issue. RUN_END provides a summary. The next autopilot invocation will re-query the tracker and find issues that were not moved to "In Progress" — they will be picked up again.

## A9: Claude CLI Invocation Pattern

**Recommended command:**
```bash
claude -p "Run /ceos-agents:autopilot" --dangerously-skip-permissions
```

**Notes:**
- `--dangerously-skip-permissions` is required for unattended execution (no human to approve tool calls)
- `-p` flag provides the prompt non-interactively
- The Skill tool is available in CLI mode with `-p`
- MCP tools work normally with `--dangerously-skip-permissions`
- The working directory must be the project root (where CLAUDE.md lives)
- For Windows Task Scheduler: use `cmd /c "cd /d C:\project && claude -p ..."`
- For Unix cron: `cd /path/to/project && claude -p "Run /ceos-agents:autopilot" --dangerously-skip-permissions`

## A10: Max Issues and Sequential Processing

**Recommendation:** Autopilot handles iteration itself; dispatches fix-ticket (not fix-bugs) for individual bugs, and implement-feature for individual features.

**Rationale:**
- fix-bugs processes N bugs from the query and runs the full pipeline for each. But autopilot needs to interleave bugs and features, track results per issue, and enforce its own max issues limit.
- fix-ticket handles a single bug by ISSUE-ID — this is the correct granularity for autopilot dispatch.
- implement-feature handles a single feature by ISSUE-ID — same granularity.
- Sequential processing (one issue at a time) for the PoC. Parallel processing is future scope.
- The autopilot SKILL.md will: (1) fetch bugs and features, (2) merge into a single list ordered by priority/date, (3) process up to max_issues sequentially, (4) log results.
