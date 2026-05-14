# Step 08: Final Report

Computes pipeline accumulator, fires pipeline-completed webhook, and displays the final report.

## 08a. Pipeline Accumulator (COST-R6)

Sum across all completed stages (`spec_writer`, `spec_reviewer`, `scaffolder`, `architect`, `fixer_reviewer`, `test`, `e2e_test`, `deployment` — include only stages that ran):
- `pipeline.total_tokens = sum({stage}.tokens_used)`
- `pipeline.total_duration_ms = sum({stage}.duration_ms)`
- `pipeline.total_tool_uses = sum({stage}.tool_uses)`
- `pipeline.summary_table` = markdown table (per `../../../core/state-manager.md` Pipeline Accumulator Write format)

Scaffold pipelines can exceed 20 rows across multi-batch runs — apply COST-R10 truncation: at most 20 data rows; if more, append `| ... | (truncated, N more stages in pipeline.log) | ... |` immediately before the `| **Total** |` row; max 4000 characters.

Write accumulator to state.json atomically. Update top-level `status` to `"completed"`.

## 08b. Pipeline-Completed Webhook

After terminal status write succeeds, fire if `Webhook URL` configured AND `pipeline-completed` in `On events`:
```bash
curl --proto "=http,https" --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  --data-binary @- "${Webhook_URL}" <<EOF
{"event":"pipeline-completed","run_id":"${run_id}","issue_id":"${run_id}","status":"completed",
 "outcome":"${outcome}","duration":${total_duration_seconds},"pr_url":null,"timestamp":"${ISO8601_UTC}"}
EOF
```
`outcome`: `"success"` if all required stages completed; `"blocked"` if any subtask was blocked but pipeline continued.
`pr_url` is `null` (scaffold does not create a PR; subtask commits are made directly).
On failure: log `[WARN] Webhook delivery failed`, continue.

## 08c. Display Summary Table

Echo `pipeline.summary_table` to stdout (COST-R10).

## 08d. Final Report Display

**Required in-memory values:** `tracker_type`, `tracker_instance`, `tracker_project`, `sc_remote`, `tracker_effective_status`, `sc_effective_status`.

```
## Scaffold Complete

**Project:** {name from spec/README.md Vision, or project description}
**Mode:** {default | --yolo | --step-mode}
**Stack:** {from spec/README.md Tech Stack}
**Spec:** {N} iterations, {APPROVED | approved with warnings}

### Infrastructure
{if tracker_effective_status == "ready"}
  Tracker: Connected ({tracker_type} @ {tracker_instance} — {tracker_project}, {N} epics created)
{else if tracker_effective_status == "downgraded"}
  Tracker: Downgraded — MCP unavailable during scaffold. Configure via /agent-flow:setup-mcp
{else}
  Tracker: Not configured — run /agent-flow:setup-mcp + /agent-flow:onboard --update
{/if}

{if sc_effective_status == "ready"}
  SC: Pushed ({sc_remote} — {sc_base_branch})
{else if sc_effective_status == "downgraded"}
  SC: Downgraded — MCP unavailable. Push manually and run /agent-flow:setup-mcp
{else}
  SC: Not configured — set up remote and run /agent-flow:setup-mcp
{/if}

{if .mcp.json.example generated}
  MCP: .mcp.json.example generated (copy to .mcp.json and fill tokens)
{/if}

### Implementation
**Features:** {implemented} / {total} ({blocked} blocked)
**Tests:** {unit count} unit, {integration count} integration, {e2e count} e2e
**Commits:** {count}

### Generated files: {count}
### Spec: spec/

### Blocked features (if any):
- {subtask title} — {block reason}

### Next steps:
{if tracker or SC not ready}
1. Fill tokens in .mcp.json (copy from .mcp.json.example)
2. Run `/agent-flow:setup-mcp` to configure MCP servers
3. Run `/agent-flow:onboard --update` to complete Automation Config
4. Run `/agent-flow:check-setup` to validate configuration
{else}
1. Your project is ready. Try `/agent-flow:implement-feature` with a tracker issue.
2. Run `/agent-flow:check-setup` to validate configuration
3. Run `/agent-flow:scaffold validate` to verify project state
{/if}
```
