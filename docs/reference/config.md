# Config Reference

This file documents the **Autopilot** section and the updated **Notifications** event tokens. For the full Automation Config contract (all required and optional sections), see [automation-config.md](automation-config.md) and [CLAUDE.md](../../CLAUDE.md).

## Autopilot

Optional section. Enables unattended continuous processing via `/agent-flow:autopilot`. All 7 keys have defaults — the section may be omitted entirely, in which case Autopilot reads `Bug query` from `### Issue Tracker` and `Feature query` from `### Feature Workflow` with all other values at their defaults.

**NOTE on query keys:** `Bug query` and `Feature query` are NOT Autopilot-section keys. They are read from existing sections: `Bug query` from `### Issue Tracker` (required), `Feature query` from `### Feature Workflow` (optional). Autopilot only references them — it does not own them.

**Related:** [`skills/autopilot/SKILL.md`](../../skills/autopilot/SKILL.md) · [`docs/guides/autopilot.md`](../guides/autopilot.md)

### Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| Max issues per run | int | `1` | Total cap on issues dispatched per invocation (bugs + features combined). Default of 1 is a safety cap for first use |
| Lock timeout | int (minutes) | `120` | Age threshold in minutes after which an existing lock directory is considered stale and is auto-recovered |
| Log file | string | `.agent-flow/autopilot.log` | Path to the append-only run log. Each invocation appends a timestamped summary line |
| Bug limit | int | `0` | Per-type cap on bug dispatches. `0` = no per-type cap (total cap from `Max issues per run` applies) |
| Feature limit | int | `0` | Per-type cap on feature dispatches. `0` = no per-type cap (total cap from `Max issues per run` applies) |
| On error | enum | `skip` | Per-issue error policy: `skip` = log [WARN] and continue with next issue; `stop` = abort the whole run on the first per-issue error |
| Dry run | bool | `false` | `true` = full short-circuit: no lock acquired, no state persisted, no webhooks fired, no skill dispatched. Used to preview which issues would be selected |

### Example

```markdown
### Issue Tracker
| Bug query | status:Open assignee:me |

### Feature Workflow
| Feature query | type:Feature status:Open |

### Autopilot
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .agent-flow/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |
```

### Behavior Notes

- `Bug query` lives under `### Issue Tracker` — it is the same query used by the interactive `fix-bugs` pipeline. Autopilot reads it from there.
- `Feature query` lives under `### Feature Workflow` — absent section triggers `[WARN]` and bug-only mode.
- `Bug limit: 0` and `Feature limit: 0` mean no per-type cap; the only cap in effect is `Max issues per run`.
- Lock directory (`.agent-flow/autopilot.lock/`) is separate from the log file (`Log file`). The lock is `mkdir`-based (atomic on POSIX and NTFS); the log file is append-only text.
- Stale lock auto-recovery: if the lock directory's `owner.json` has `acquired_at` older than `Lock timeout` minutes, the next run re-acquires the lock automatically.
- `Dry run` overrides all side effects: the lock directory is not created, `state.json` is not written, webhook events are not fired, and no skill is dispatched to process issues.

## Notifications

Optional section. Configures webhook delivery for pipeline lifecycle events.

**Operator trust required**: The `Webhook URL` value is dispatched via `curl`. SSRF defense (`--proto "=http,https"`) restricts delivery to HTTP/HTTPS schemes only. Cross-run circuit-breaker persistence and URL allowlist are on the roadmap. Operators are responsible for configuring trusted URLs pointing to internal observability endpoints. Per spec design §3.6.

| Key | Default | Description |
|-----|---------|-------------|
| Webhook URL | (none) | HTTP endpoint that receives POST requests for each event |
| On events | (none) | Comma-separated event tokens (see table below) |

### Event Tokens

| Token | When fired |
|-------|-----------|
| `pr-created` | A pull request is created by the publisher agent |
| `issue-blocked` | An agent blocks an issue (pipeline halted for that issue) |
| `pipeline-started` | A pipeline run begins (issue accepted for processing) |
| `step-completed` | Each major pipeline step completes (triage, analyst-impact, fixer, etc.) |
| `pipeline-completed` | A full pipeline run finishes (success or block) |
| `pipeline-paused` | A pipeline run transitions to paused state (NEEDS_CLARIFICATION emitted by fixer or analyst) |
| `pipeline-resumed` | A paused pipeline resumes after the operator provides a clarification answer (by re-invoking the original entry-point skill with `--clarification`; auto-resume is detected inline by `core/resume-detection.md`) |

### Example

```markdown
### Notifications

| Key | Value |
|-----|-------|
| Webhook URL | https://hooks.example.com/agent-flow |
| On events | pipeline-started, step-completed, pipeline-completed, issue-blocked |
```
