---
name: metrics
description: Generates pipeline analytics report -- success rate, per-agent effectiveness, failure patterns, optional HTML dashboard
allowed-tools: mcp__*, Read, Glob, Grep, Bash, Write
argument-hint: "[--period <N>] [--output <path>] [--format <md|json|html>]"
---

# Metrics

Input: `$ARGUMENTS` = optional flags (`--period <N>`, `--output <path>`, `--format <md|json|html>`)

## Flag parsing

```bash
FORMAT=""        # empty = no flag supplied = trigger interactive prompt path
PERIOD=30
OUTPUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --period)
      PERIOD="$2"; shift 2
      ;;
    --output)
      OUTPUT="$2"; shift 2
      ;;
    --format)
      FORMAT="$2"; shift 2
      [[ "$FORMAT" =~ ^(md|json|html)$ ]] || { echo "Error: --format must be 'md', 'json', or 'html'"; exit 1; }
      ;;
    *)
      shift
      ;;
  esac
done

# Sentinel for interactive-prompt path (REQ-V902-032)
NO_FORMAT_FLAG=0
if [ -z "$FORMAT" ]; then
  NO_FORMAT_FLAG=1
  FORMAT="md"   # default render is markdown; prompt fires AFTER render
fi
```

- `--period N` → period in days (default: 30)
- `--output path` → output file (default: stdout)
- `--format md|json|html` → output format (default: md with interactive prompt)

## Configuration

Read Automation Config from CLAUDE.md section `## Automation Config`:
- Issue Tracker: Type, Instance, Project, Bug query, State transitions
- Source Control: Remote
- Optionally: Feature Workflow → Feature query
- Optionally: Metrics → Output, Period (overrides defaults)

### 0. MCP pre-flight check

Before any pipeline operation, verify MCP tool availability:
- Read Type from Automation Config (Issue Tracker section)
- Check that at least one `mcp__*` tool matching the tracker type is accessible
- If not accessible → STOP with: "Cannot connect to your {Type} issue tracker. Is the {Type} integration configured? Run `/ceos-agents:check-setup` for diagnostics."

## Orchestration

### 1. Fetch issues

Via MCP server (per Issue Tracker → Type), fetch all issues matching Bug query + Feature query (if it exists). For each issue: ID, title, state, comments, created date.

### 2. Parse [ceos-agents] comments

For each issue, go through comments. Extract:

**Triage checkpoint:**
Regex: `^\[ceos-agents\] Triage completed\. Severity: (.+)\. Area: (.+)\.$`

**Spec checkpoint:**
Regex: `^\[ceos-agents\] Spec analysis completed\. Area: (.+)\. Criteria: (.+)\.$`

**Block comment:**
Regex (multiline): `^\[ceos-agents\] 🔴 Pipeline Block`
Following lines: `Agent: (.+)`, `Step: (.+)`, `Reason: (.+)`, `Detail: (.+)`, `Recommendation: (.+)`

**PR link:**
Regex: `PR: (https?://\S+)` or `#(\d+)`

### 3. Fetch git data

`git log --oneline --since="{period} days ago"` via Bash. Parse commit messages for issue ID references.

### 4. Compute pipeline metrics

- `total_attempted` = issues with a `[ceos-agents]` comment in the given period
- `total_fixed` = issues with PR merged (or in a state from State transitions → For Review/Done)
- `total_blocked` = issues with a `[ceos-agents] 🔴 Pipeline Block` comment and still in Blocked state
- `success_rate` = total_fixed / total_attempted (percentage)
- `avg_time_to_fix` = average time from the first `[ceos-agents]` comment to merged PR (if data available)
- `block_by_stage` = count of blocks per pipeline stage (triage, analysis, fix, review, test, publish)
- `top_block_reasons` = top 5 most frequent "Reason:" values from block comments

### 5. Compute per-agent metrics

For each agent (analyst, fixer, reviewer, test-engineer, browser-agent, publisher, scaffolder, spec-writer, spec-analyst, architect, acceptance-gate, deployment-verifier, backlog-creator, sprint-planner, priority-engine, spec-reviewer, rollback-agent): count blocks, success rate, most frequent failure reason.

- `avg_fixer_iterations` = from reviewer comments (how many REQUEST_CHANGES before APPROVE)
- `failure_pattern_detection` = if an agent blocks > 30% of issues → flag pattern with top reason

### 6. Token cost estimate

Per-issue estimate (heuristic fallback): count stages × model tokens (sonnet ~30k, opus ~50k, haiku ~5k per invocation).
Total estimate for the period.

### 6a. Read state.json per issue (measured data — preferred over heuristics)

For each issue identified in Step 4, glob `.ceos-agents/*/state.json` to locate per-run state files. Classify each pipeline run:

- **MEASURED**: `pipeline.total_tokens` is present in state.json → use `pipeline.total_tokens` directly; do NOT apply heuristic constants.
- **ESTIMATED**: `pipeline.total_tokens` is absent (pre-v6.8.0 run or incomplete pipeline) → apply heuristic constants from Step 6.
- **HYBRID** (partial measurement): state.json has some stages with `tokens_used` but no top-level `pipeline.total_tokens` → classify the pipeline as ESTIMATED at the pipeline level, but note which stages had measured data in the detail section.

For each pipeline run, collect:
- `measured_tokens` = `pipeline.total_tokens` if present, else 0
- `measured_stages` = count of stages where `{stage}.tokens_used` exists and is > 0
- `estimated_tokens` = heuristic sum for stages missing `tokens_used`
- `total_stages` = count of all stages present in state.json

Maintain two global accumulators across all issues:
- `all_measured_issues` = list of issue IDs classified as MEASURED
- `all_estimated_issues` = list of issue IDs classified as ESTIMATED (including HYBRID)

### 7. Generate report

Output format depends on `--format` flag (default: `md`).

**When `--format json`:** emit a single JSON object matching the schema below. Do NOT emit any markdown text. Write to `--output` path if specified, otherwise stdout.

<!-- @snippet:metrics-json-schema -->
**JSON schema** (REQ-029, REQ-031):

```json
{
  "generated_at": "ISO-8601 timestamp",
  "period_days": 30,
  "project": "string (tracker project key, e.g. PROJ — NOT full project name)",
  "pipeline_overview": {
    "issues_attempted": 0,
    "issues_fixed": 0,
    "issues_blocked": 0,
    "success_rate": 0.0,
    "avg_time_to_fix_hours": 0.0
  },
  "token_cost": {
    "measured_issues": ["PROJ-42"],
    "estimated_issues": ["PROJ-37"],
    "measured_tokens": 0,
    "estimated_tokens": 0
  },
  "block_analysis": {
    "by_stage": [
      {"stage": "triage", "blocks": 0, "pct": 0.0}
    ],
    "top_reasons": [
      {"reason": "string (sanitized — block.detail content excluded per state/schema.md hard contract)", "count": 0}
    ]
  },
  "per_agent": [
    {
      "agent": "fixer",
      "invocations": 0,
      "blocks": 0,
      "success_rate": 0.0,
      "top_failure": "string"
    }
  ],
  "recommendations": ["string"]
}
```

**HARD CONTRACT — block.detail exclusion (REQ-030):** `top_reasons[].reason` uses `block.reason` only (the sanitized 2-sentence summary from the block comment). `block.detail` is NEVER serialized into JSON output. This cross-references the comprehensive INCLUDE/EXCLUDE channel table in `state/schema.md` §"Sensitive field exclusion contract".

**When `--format md` (default):** emit markdown report as follows.

```
## Pipeline Metrics Report — {project} ({period} days)

### Pipeline Overview
| Metric | Value |
|--------|-------|
| Issues attempted | {N} |
| Issues fixed | {N} ({rate}%) |
| Issues blocked | {N} |
| Avg time to fix | {N} hours |

### Token Cost — Per Pipeline Breakdown

For each pipeline run in the period, emit separate line items for measured and estimated
tokens. NEVER emit a single combined grand total when any issues fall back to heuristics.

**Example output for a run with both measured and estimated data:**

Pipeline PROJ-42 (2026-04-18):
  Measured: 42,150 tokens (8 stages)
  Estimated: 12,500 tokens (2 stages, heuristic)
  Total: 54,650 tokens

Pipeline PROJ-37 (2026-04-17):  [ESTIMATED — pre-v6.8.0 state]
  Estimated: 85,000 tokens (heuristic: 2×opus + 1×sonnet + 1×haiku)

Pipeline PROJ-55 (2026-04-19):  [MEASURED]
  Measured: 78,300 tokens (5 stages)
  Total: 78,300 tokens

**Hybrid pipeline (some stages measured, some not):**

Pipeline PROJ-60 (2026-04-20):  [ESTIMATED — partial measurement]
  Measured stages: triage (12,500 tok), code_analysis (9,800 tok)
  Estimated stages: fixer_reviewer, test (heuristic)
  Estimated: ~80,000 tokens
  Note: pipeline classified as ESTIMATED because pipeline.total_tokens is absent;
        2 of 4 stages had measured data.

### Token Cost — Period Summary

| Category | Issues | Tokens |
|----------|--------|--------|
| Measured (state.json) | {X} | {sum} |
| Estimated (heuristic) | {Y} | ~{sum} |

> Measured and estimated totals are NOT summed into a single grand total.

### Block Analysis
| Stage | Blocks | % of total |
|-------|--------|------------|
| triage | ... | ... |
| analysis | ... | ... |
| fix | ... | ... |
| review | ... | ... |
| test | ... | ... |
| publish | ... | ... |

Top block reasons:
1. {reason} ({N} occurrences)
...

### Per-Agent Effectiveness
| Agent | Invocations | Blocks | Success Rate | Top Failure |
|-------|-------------|--------|-------------|-------------|
| fixer | ... | ... | ... | ... |
| ... | ... | ... | ... | ... |

### Recommendations
- {threshold-based recommendations}

---
Data source: measured={X} pipelines (state.json.pipeline.total_tokens present), estimated={Y} pipelines (heuristic fallback).
**Provenance:** {X} pipeline(s) used measured token data from state.json (pipeline.total_tokens).
{Y} pipeline(s) fell back to heuristic estimates (sonnet ~30k, opus ~50k, haiku ~5k per stage).
{If Y > 0}: Pipelines run before v6.8.0 upgrade lack per-stage usage fields and are reported as estimated.
Estimated pipelines: {comma-separated list of estimated issue IDs and run dates}.

Generated: {timestamp} | ceos-agents v{version}
```

If `--output` specified: write to file, otherwise stdout.

### 7a. Generate HTML (when --format html)

When `$FORMAT == "html"`, generate a self-contained HTML file with inline CSS and JavaScript.

**HTML escape (XSS defense for user-controlled data paths):**

```bash
html_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\'/&#39;}"
  printf '%s' "$s"
}
```

Order is critical: `&` MUST be substituted first to avoid double-escaping subsequent entity references.

All 5 user-controlled / tracker-sourced fields MUST be passed through `html_escape` BEFORE being interpolated into the HTML output:

- Issue title → `$(html_escape "$issue_title")`
- State label → `$(html_escape "$state_label")`
- Block reason → `$(html_escape "$block_reason")`
- Block recommendation → `$(html_escape "$block_recommendation")`
- Timeline content → `$(html_escape "$timeline_content")`

**HTML structure** (ported from the deleted dashboard skill):
- Header: project, timestamp, plugin version
- Pipeline Overview: 3 cards (Active blue #3B82F6, Blocked red #EF4444, Completed green #22C55E)
- Issue Table: sortable table (ID, Title, State, Stage, Agent, Tokens, Duration, PR) — Tokens and Duration columns show `—` when `pipeline.total_tokens` is absent from state.json
- Blocked Issues Panel: blocked issue details (agent, reason, recommendation)
- Recent Activity Timeline: last 20 events with colored dots (sort all `[ceos-agents]` comments by timestamp desc)
- Statistics: success rate (progress bar), throughput, block distribution
- Recommendations: from Step 6
- Footer: generated timestamp, plugin version

**CSS** (inline `<style>` block):
- Responsive: desktop (1200px+) and mobile (< 768px)
- Colors: blue (#3B82F6), red (#EF4444), green (#22C55E), yellow (#F59E0B), gray (#6B7280)
- Font: system-ui, -apple-system, sans-serif
- Dark mode: prefers-color-scheme media query

**JavaScript** (inline `<script>` block, minimal):
- Table sorting: click on header → sort asc/desc
- Blocked detail expander: click → toggle detail visibility

### 8. Write output file (when --format html OR --output specified)

When `$FORMAT == "html"`:
- If `$OUTPUT` is empty: HTML_PATH="./metrics.html"
- Else: HTML_PATH="$OUTPUT"
- Write the generated HTML to `$HTML_PATH` via Write tool

When `$FORMAT == "md"` or `$FORMAT == "json"` AND `$OUTPUT` is non-empty:
- Write the rendered report to `$OUTPUT` instead of stdout

### 9. Post-render interactive prompt (only when no --format flag was supplied)

When `$NO_FORMAT_FLAG == 1`:

After the markdown report is displayed on stdout, present the following Czech prompt to the user as a question requiring a response:

> Výstup uložit? [1] Ne [2] JSON → stdout [3] HTML → ./metrics.html

Handle the response:
- `1` → exit (no save)
- `2` → re-render the report at `--format json` to stdout (re-execute Step 7's JSON branch)
- `3` → re-render the report at `--format html` to `./metrics.html` (execute Step 7a + Step 8)
- Any other input → treat as `1` (no save)

When `$NO_FORMAT_FLAG == 0`: SKIP this step entirely. The user explicitly chose a format; honor that choice silently.

**Autopilot safety:** Autopilot does NOT invoke /metrics. The interactive prompt is therefore safe from non-TTY automation contexts.

## Rules

- Read-only — no changes to the issue tracker or git
- Data is read via MCP servers
- If MCP unavailable → report error with explanation
- Threshold for recommendations: block_rate > 30% per agent, success_rate < 50%, single agent > 50% of blocks
