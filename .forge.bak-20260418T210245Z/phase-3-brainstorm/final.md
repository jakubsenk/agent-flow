# Phase 3 Brainstorm — ceos-agents v6.8.0 (Judge Synthesis)

## Scores

Scoring: 0–5 each criterion. Weights: Roadmap Alignment 1.5, Consumer Utility 1.0, Backward Compatibility 1.5, Scope Discipline 1.5, Implementation Clarity 1.0 (sum = 6.5 max per point ⇒ 32.5 max weighted).

| Agent | Roadmap Alignment | Consumer Utility | Backward Compat | Scope Discipline | Implementation Clarity | Weighted Total |
|---|---|---|---|---|---|---|
| Conservative (1) | 5 | 2 | 5 | 5 | 4 | 7.5+2.0+7.5+7.5+4.0 = **28.5** |
| Innovator (2) | 3 | 5 | 3 | 2 | 4 | 4.5+5.0+4.5+3.0+4.0 = **21.0** |
| Skeptical (3) | 5 | 3 | 5 | 5 | 4 | 7.5+3.0+7.5+7.5+4.0 = **29.5** |

Skeptic wins narrowly over Conservative; Innovator trails on scope but supplies the highest consumer-utility ideas.

## Free-MAD Flaws Identified

### Conservative — Flaws
1. **`disable-model-invocation: true` reasoning is weak for Autopilot.** Classifies Autopilot as a "fix-bugs archetype dispatcher," but fix-bugs is routinely invoked directly by users; the real dispatcher precedent is that ALL pipeline dispatchers carry the flag. The conclusion is right, but the justification conflates precedent with archetype.
2. **Field-name vacillation on `tokens_used` vs `tokens_estimated`.** Proposes "mirror forge byte-for-byte in mechanism but use roadmap's `tokens_used` in naming" — this is the weakest possible synthesis: inherits forge's drift risk AND the roadmap divergence. A single authoritative name would be cleaner.
3. **Silent skip on Feature Workflow absence (option (a)).** When a user sets `Feature limit: 5` but has no Feature Workflow section, silent behavior = cron-invisible misconfiguration. Skeptic's [WARN] is strictly better operationally.

### Innovator — Flaws
1. **Payload field bloat is speculative.** Adds `parent_agent`, `tool_uses_by_type`, `previous_stage_duration_ms`, `iteration_index_of_N`, `flags`, `profile`, `blocked_at`, `stages_completed`, `schema_capabilities` — none named by the roadmap, each a contract surface that must be preserved forever. Violates "start minimal, grow additively" for webhook payloads.
2. **`schema_capabilities` array invents a new evolution model.** Novel capability-flag system not requested by any consumer, not in roadmap, not in D10. Over-engineering that duplicates what `schema_version` already does.
3. **Adds an 8th Autopilot config key (`Summary output`).** Roadmap explicitly lists 7 keys. Adding a key mid-version is a MINOR contract change that dilutes the Autopilot config surface for a feature (custom summary path) no consumer has asked for.
4. **`disable-model-invocation: false` (no flag) contradicts dispatcher precedent.** Autopilot dispatches fix-ticket and implement-feature — that is the dispatcher pattern, and fix-ticket/fix-bugs/implement-feature all carry the flag.

### Skeptical — Flaws
1. **Rejects `/metrics` state.json dual-mode expansion completeness.** Agrees to read state.json but refuses `--format json` / any output evolution. This may under-serve D10's explicit "real-time tracking" goal. The roadmap is silent on `--format json`, so scope-discipline wins, but the consumer gap is real.
2. **`summary_table` as a pre-rendered markdown string inside state.json** couples data with presentation. A dashboard that wants the data must parse markdown out of a JSON string. Ugly pattern; `pipeline.log` or a separate JSON is cleaner.
3. **Rejects `run_id` in webhook payloads.** `issue_id` is insufficient when the same ticket is re-run (debug, retry); without a `run_id`, event correlation breaks for anyone doing time-window analytics. This is a rare case where minimal-now costs more than it saves.

## Decision Matrix (resolved)

| # | Decision Point | Pick | Rationale | Attribution |
|---|---|---|---|---|
| 1 | Token field name | **`tokens_used`** (state.json) | Roadmap line 672/677 uses this exactly; ceos-agents Task tool returns real counts, not estimates. Reject forge's `tokens_estimated` as a misnomer for ceos. | Skeptic (strongest); Conservative+Innovator concur |
| 2 | Schema version | **`"1.0"`** (no bump) | Q2 HIGH: state-manager has no version check; additive; roadmap line 714 says PATCH. | All three (unanimous) |
| 3 | Event granularity | **Top-level stages only** (no opt-in per-iteration) | Roadmap's `iteration_count` field only makes sense at stage granularity. Per-iteration events triple webhook volume and duplicate pipeline.log. Innovator's opt-in token is deferred. | Skeptic + Conservative |
| 4 | core/ refactor | **Extend `core/post-publish-hook.md`** (no new file) | Already carries curl pattern + advisory-failure clause; one file in roadmap line 650; new file = divergence risk + rename blast radius. | Conservative + Skeptic |
| 5 | Payload shape | **Roadmap minimum + `outcome` + `run_id`** on applicable events | Roadmap fields are the floor. Add ONLY (a) `outcome` to `pipeline-completed` (Skeptic agrees — useless without pass/fail) and (b) `run_id` to all three (cheap, enables re-run correlation). Reject all other innovator fields as speculative. | Skeptic (minimum) + Innovator (run_id, outcome) |
| 6 | Dry-run semantics | **Full short-circuit** (no lock, no state.json, no webhooks, no child dispatch) | Unanimous across agents. Cron-safety requirement: concurrent dry-runs must not false-positive; monitoring must not see events for non-runs. | All three (unanimous) |
| 7 | Autopilot `disable-model-invocation` | **`true`** | Autopilot dispatches fix-ticket/implement-feature → dispatcher precedent. Prevents auto-invocation mid-conversation. Conservative+Skeptic agree (2/3 majority); Innovator's minority objection has no consumer evidence. | Skeptic (reasoning) + Conservative |
| 8 | Feature-Workflow absence | **`[WARN]` and continue in bug-only mode** | Silent (a) hides misconfiguration from cron ops; hard-block (c) breaks backward compat for projects currently using fix-bugs-only. [WARN] is the operations-correct middle. Matches `/metrics` idiom (absent-section log line). | Skeptic + Innovator; overrides Conservative's silent-skip |
| 9 | Lock file mechanism | **PowerShell `[System.IO.File]::Open(..., CreateNew, ...)`** on Windows, contents `{pid}\|{hostname}\|{ISO8601}` | NTFS `CreateNew` is atomic (POSIX `O_CREAT\|O_EXCL` equivalent), fails fast on collision, debug-friendly PID/hostname inside. Superior to tmp+rename (race window) and mkdir (no debug info). | Skeptic (uniquely correct); overrides Conservative's tmp+rename |
| 10 | Pipeline summary output | **Inside state.json** (`pipeline.summary_table` as markdown string) + echo to final skill stdout, NOT a separate file, NOT in PR body by default | One read target for `/metrics` (Skeptic); no new artifact to version (Conservative). Innovator's separate `pipeline-summary.json` is deferred to v6.9.0 when a named consumer requests it. | Skeptic (primary); Conservative concurs |
| 11 | `/metrics` mode | **Additive: state.json-read with heuristic fallback**, NO `--format json` flag in v6.8.0 | Reads `pipeline.total_tokens` when present; falls back to existing heuristic constants. Output format stays markdown. Innovator's `--format json` is deferred — it is a MINOR contract change for a future release. | Skeptic (primary); Innovator's format-json is NOT_IN_SCOPE |
| 12 | Batch events (`autopilot-started/completed`) | **NOT added** (deferred to v6.9.0) | Per-issue `pipeline-started`/`pipeline-completed` with a `run_id` carry enough correlation signal for v6.8.0. Batch lifecycle events are a v6.9.0 addition if a dashboard consumer requests them. | Skeptic + Conservative; overrides Innovator |

## Merged Proposal (v6.8.0 Recommended Design)

### Item 1: `/ceos-agents:autopilot`

**Skill frontmatter:**

```yaml
---
name: autopilot
description: Headless batch dispatcher — queries bugs and features, classifies, dispatches fix-ticket or implement-feature sequentially with lock-file concurrency guard
allowed-tools: mcp__*, Bash, Read, Write, Edit, Grep, Glob, Skill, Task
disable-model-invocation: true
argument-hint: "[--dry-run]"
---
```

**Steps (0..5, condensed but concrete):**

- **Step 0 — Config read + MCP pre-flight.** Read `### Issue Tracker` (required), `### Feature Workflow` (optional), `### Autopilot` (optional — defaults applied when absent), `### Notifications` (optional). Run MCP ping for the configured tracker type. On MCP failure: exit 3 with `[STOP] MCP unreachable — {error}` — no lock yet, so nothing to clean up. (If `--dry-run`: skip to Step 3 after classification; do NOT acquire lock.)
- **Step 1 — Lock acquisition.** See "Lock file mechanism" below. On stale lock (> `Lock timeout` minutes, default 120): delete + re-acquire. On held non-stale lock: exit 2 with `[BLOCK] autopilot already running (lock age {N}min < {timeout}min)`.
- **Step 2 — Classification (two-query).** Query bugs (`Bug query`) and features (`Feature query` from `Feature Workflow` if present; else `[WARN] Feature Workflow section absent — running in bug-only mode` and `feature_ids = []`). Compute `bug_ids ∩ feature_ids = overlap`; bug wins on overlap. Apply `Bug limit` / `Feature limit` (0 = unlimited from that type), then cap total at `Max issues per run` (default 1). Log classification summary to the log file.
- **Step 3 — Dispatch loop.** For each classified issue in order (bugs first, then features): dispatch `ceos-agents:fix-ticket {ID}` (bug) or `ceos-agents:implement-feature {ID}` (feature) via the Skill tool. Per-issue result captured (SUCCESS / BLOCKED / ERROR). On ERROR: if `On error = stop`, break loop; else (default skip) continue. On BLOCKED: log, continue (child skill already commented). (If `--dry-run`: print classification table to stdout, exit 0; NO lock, NO state.json, NO webhooks, NO child dispatch.)
- **Step 4 — Summary.** Append summary line to `Log file`: `{ISO8601} autopilot bugs={N} features={M} success={S} blocked={B} errors={E} duration_s={D}`.
- **Step 5 — Release lock.** Delete `.ceos-agents/autopilot.lock`. On deletion failure: `[WARN]` and continue (stale detection will recover next run). Finally block ensures release even on Steps 2/3/4 abort.

**Lock file mechanism** (from Skeptic, adopted):

- Path: `.ceos-agents/autopilot.lock` (roadmap line 633 verbatim — project-directory-local; two repos run independently without cross-interference).
- Create: PowerShell invoked via Bash — `[System.IO.File]::Open($path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)`. NTFS atomic create-or-fail. Falls back to POSIX `O_CREAT|O_EXCL` equivalent on Linux/Mac (same semantics for future cross-platform support).
- Contents (one line): `{pid}|{hostname}|{ISO8601-timestamp}`.
- Stale threshold: `Lock timeout` (default 120 min). Read timestamp from existing lock; if `now - ts > timeout`: delete and re-acquire once. No PID liveness probe (cross-platform unreliability).
- Release: try/finally in the skill ensures deletion on clean exit and abort paths. SIGKILL leaves stale lock — recovered on next run via timeout.

**Two-query classification flow:**

```
bug_ids     = mcp_query(bug_query, limit = Bug_limit or Max_issues_per_run)
feature_ids = mcp_query(feature_query, limit = Feature_limit or Max_issues_per_run)   [if Feature Workflow present + query non-empty]
overlap     = bug_ids ∩ feature_ids
feature_only = feature_ids - overlap
classified  = [(id, "bug") for id in bug_ids] + [(id, "feature") for id in feature_only]
cap at Max_issues_per_run
```

**Error boundaries:**

| Condition | Action | Rationale |
|---|---|---|
| MCP ping fails (Step 0) | Exit 3, no lock held | Pre-work check |
| Lock held + not stale | Exit 2, no side effects | Prevent concurrent runs |
| Lock held + stale (>timeout) | Delete + re-acquire | Recovery |
| Config missing required section | Exit 4, release lock if acquired | Standard skill pattern |
| Feature Workflow absent | `[WARN]`, bug-only mode | Operational visibility |
| Per-issue dispatch ERROR + `On error: skip` (default) | Log WARN, continue | Batch resilience |
| Per-issue dispatch ERROR + `On error: stop` | Break loop, summary, release lock, exit 1 | Explicit opt-in halt |
| Webhook delivery fails | `[WARN]`, continue | Inherit existing advisory |

**Dry-run semantics (full short-circuit):** no lock file, no state.json write, no pipeline.log, no webhooks, no child skill dispatch. Outputs classification table to stdout and exits 0. Safe for repeated cron-test invocations.

**Feature-query absence:** `### Feature Workflow` section missing OR `Feature query` key missing → `[WARN] Feature Workflow section absent — running in bug-only mode`, `feature_ids = []`, continue. If `Feature limit > 0` was set but no Feature query: `[WARN] Feature limit={N} configured but no Feature query — treating as bug-only` and continue. Never block on an optional-section omission.

**`### Autopilot` config section (7 keys, roadmap verbatim):**

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

**File changes:**

| File | Change |
|---|---|
| `skills/autopilot/SKILL.md` | CREATE new file |
| `CLAUDE.md` (plugin) | Skill count 28→29; add `/autopilot` to Skills list; add `Autopilot` row to Optional sections table |
| `core/config-reader.md` | Add 7 dot-notation keys under new `### Autopilot` parse block |
| `docs/reference/skills.md` | Add `/autopilot` row |
| `docs/reference/pipelines.md` | Add "Autopilot batch dispatch" subsection |
| `skills/workflow-router/SKILL.md` | Add intent row: "autopilot" / "headless run" / "cron" |
| `examples/config-templates/*` (2 of 8 templates) | Append `### Autopilot` example |

### Item 2: Observability Hooks (D10)

**Payload schemas (FINAL):**

```json
// pipeline-started
{
  "event": "pipeline-started",
  "run_id": "PROJ-42",
  "issue_id": "PROJ-42",
  "pipeline": "fix-ticket",
  "timestamp": "2026-04-17T14:30:00Z"
}

// step-completed
{
  "event": "step-completed",
  "run_id": "PROJ-42",
  "issue_id": "PROJ-42",
  "step_name": "fixer_reviewer",
  "duration": 360,
  "iteration_count": 3,
  "timestamp": "2026-04-17T14:40:00Z"
}

// pipeline-completed
{
  "event": "pipeline-completed",
  "run_id": "PROJ-42",
  "issue_id": "PROJ-42",
  "status": "completed",
  "outcome": "success",
  "duration": 692,
  "pr_url": "https://gitea.example.com/owner/repo/pulls/99",
  "timestamp": "2026-04-17T14:42:00Z"
}
```

Field set rationale: roadmap minimum (line 648: `step_name`, `duration`, `iteration_count`) + `outcome` on `pipeline-completed` (Skeptic — a completion event without pass/fail is useless) + `run_id` on all three (Innovator — cheap, equals `issue_id` for single-issue runs but enables future re-run correlation). `duration` in whole seconds (payload brevity; state.json stores `duration_ms`). D10's `tokens_used` and `phase` are REJECTED from the payload — state.json is the single source of truth for token data (avoid duplication).

**Event granularity:** one `step-completed` per top-level named stage; NOT per fixer-reviewer iteration. Stage enum (closed set, spec-defined):

- Bug/feature pipelines: `triage`, `code_analysis`, `reproducer`, `fixer_reviewer`, `test`, `e2e_test`, `browser_verification`, `acceptance_gate`, `publisher`, `deployment_verification`, `spec_analysis` (feature), `architect` (feature)
- Scaffold pipeline: `spec_writer`, `spec_reviewer`, `scaffolder`, plus the bug/feature set after implementation starts

No `step-skipped` event — skipped stages produce no webhook (consumer reconciles from `pipeline-completed` final summary). NO opt-in per-iteration event.

**Fire sites:**

| Event | File | Location |
|---|---|---|
| `pipeline-started` | `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md` | After config validation + state.json init, before first agent dispatch |
| `step-completed` | same 4 skills | After each top-level stage completes (writes `{stage}.status: completed` to state.json) |
| `pipeline-completed` | same 4 skills | After final state.json write (success or terminal block) |
| `pr-created` (existing) | `core/post-publish-hook.md` | Unchanged |
| `issue-blocked` (existing) | `core/block-handler.md` | Unchanged |

Autopilot itself does NOT emit its own lifecycle events — per-issue events from child skills provide enough signal.

**core/ refactor decision: EXTEND `core/post-publish-hook.md`** (do NOT create `core/pipeline-events.md`). Add Section 4 titled "Pipeline lifecycle events": documents the three new events, their payloads, their fire sites (cross-reference to the four pipeline skills), and explicitly states "Transport, curl invocation, and failure handling are identical to Section 3." Rename the file's top-line Purpose from "Execute post-publish hooks and fire webhooks after PR creation" to "Execute pipeline hooks and fire webhooks at stage boundaries." One file, one curl pattern, one advisory-failure clause.

**CLAUDE.md Notifications update:**

```markdown
### Notifications
| Key | Value |
|-----|-------|
| Webhook URL | https://... |
| On events | pr-created, issue-blocked, pipeline-started, step-completed, pipeline-completed |
```

Valid `On events` tokens (documentation-only; parser is a substring check): existing `pr-created`, `issue-blocked`, `reproduce`, `verify` + new `pipeline-started`, `step-completed`, `pipeline-completed`. Default when `On events` omitted: preserve v6.7.x behavior (currently the parser behavior — no change).

Add forward-compat guarantee paragraph to CLAUDE.md Notifications section (Skeptic's Risk 2 mitigation): "Webhook payloads are forward-compatible — additive fields may be added in future MINOR versions. Consumers should use lenient JSON parsing (ignore unknown fields)."

**Backward compat note:** fully preserved. `pr-created` and `issue-blocked` payloads unchanged. Projects without `Webhook URL` configured receive nothing (unchanged). Projects with `On events: pr-created` only receive `pr-created` (unchanged — new events require opt-in). Zero breaking change; MINOR bump correct.

### Item 3: Real-Time Cost Visibility

**state.json per-stage additions** (applied to each of: `triage`, `code_analysis`, `reproducer`, `fixer_reviewer`, `test`, `e2e_test`, `browser_verification`, `acceptance_gate`, `publisher`, `deployment`, `spec_analysis`, `architect`, `spec_writer`, `spec_reviewer`, `scaffolder`):

```json
{
  "tokens_used": 12500,
  "duration_ms": 45000,
  "tool_uses": 8,
  "model": "sonnet",
  "started_at": "2026-04-17T14:30:00Z",
  "completed_at": "2026-04-17T14:30:45Z"
}
```

Six fields, roadmap verbatim (line 705). No `tool_uses_by_type`, no `retry_count`, no `parent_agent` — all innovator speculation.

**state.json top-level `pipeline` accumulator:**

```json
"pipeline": {
  "total_tokens": 250700,
  "total_duration_ms": 692000,
  "total_tool_uses": 183,
  "summary_table": "| Stage | Model | Tokens | Duration | Tools |\n|---|---|---|---|---|\n| triage | sonnet | 12,500 | 45s | 8 |\n..."
}
```

Roadmap lines 707–708 verbatim for the three totals. `summary_table` as a markdown string field (Skeptic): single read target for `/metrics`; no separate artifact to version. Written once at pipeline end.

**schema_version: stays `"1.0"`.** Unanimous across agents. Q2 HIGH. No state-manager version check; additive fields; roadmap line 714 says PATCH. state/schema.md line 148 clause left intact.

**Task-tool usage capture pseudocode** (per-site):

```
# Before dispatch:
stage_started_at = ISO8601_NOW
state_write("{stage}.started_at", stage_started_at)
state_write("{stage}.status", "in_progress")
state_write("{stage}.model", "{agent.model_from_frontmatter}")

# Dispatch:
result = Task(subagent_type="{agent-name}", prompt="...")

# After dispatch — defensive read:
tokens      = result.usage.total_tokens or 0
duration_ms = result.usage.duration_ms or (now - stage_started_at).ms
tool_uses   = result.usage.tool_uses or 0

# Write (field-name rename at the boundary — Task tool returns `total_tokens`, state.json stores `tokens_used`):
state_write("{stage}.tokens_used", tokens)
state_write("{stage}.duration_ms", duration_ms)
state_write("{stage}.tool_uses", tool_uses)
state_write("{stage}.completed_at", ISO8601_NOW)
state_write("{stage}.status", "completed")

# Update pipeline accumulator (in-memory running total, written once at pipeline end):
pipeline_totals.tokens      += tokens
pipeline_totals.duration_ms += duration_ms
pipeline_totals.tool_uses   += tool_uses
```

Defensive read (Skeptic): if `result.usage` is absent/null, write 0 for each count. Do not block, do not retry. Forward-compat protection if Task tool API changes.

**Fixer-reviewer accumulation (cumulative only):**

```
# Initialize at loop entry:
fixer_reviewer.tokens_used = 0
fixer_reviewer.duration_ms = 0
fixer_reviewer.tool_uses   = 0
fixer_reviewer.started_at  = ISO8601_NOW  (first iteration only)
fixer_reviewer.model       = "opus"

# In each iteration (fixer call + reviewer call):
fixer_reviewer.tokens_used += fixer_result.usage.total_tokens + reviewer_result.usage.total_tokens
fixer_reviewer.duration_ms += ...
fixer_reviewer.tool_uses   += ...
fixer_reviewer.iterations  += 1   (already exists)

# After loop:
fixer_reviewer.completed_at = ISO8601_NOW
fixer_reviewer.status = "completed"
```

No per-iteration breakdown array (roadmap line 677 is explicit). Fixer and reviewer share the `fixer_reviewer` slot; summary table's per-row split (e.g., `fixer (×3) | opus | 135,000`) reports the combined value.

**Pipeline summary output:** inside state.json as `pipeline.summary_table` (markdown string). Echo to final skill stdout. NOT written to a separate file (no `pipeline-summary.json` in v6.8.0). NOT injected into PR body by default (PR body template is a stable contract surface). Format: roadmap lines 680–690 verbatim.

**`/metrics` aggregation update** (additive):

Add Step 3b to `skills/metrics/SKILL.md`: "For each issue in the period, glob `.ceos-agents/{ID}/state.json`. If state carries `pipeline.total_tokens`, sum measured values. For runs without `pipeline.total_tokens` (v6.7.x legacy or in-flight), fall back to Step 6 heuristic constants (`sonnet ~30k`, `opus ~50k`, `haiku ~5k`)." Report a one-line footer: `Data source: measured={X} issues, estimated={Y} issues` to warn on mixed data. Output format stays markdown (no `--format json` in v6.8.0).

## Explicit NOT_IN_SCOPE (v6.8.0)

1. **No `step-skipped` webhook event.** Skips observable via pipeline.log and absent events.
2. **No `fixer-iteration-completed` webhook event.** Per-iteration resolution stays in pipeline.log.
3. **No `autopilot-started` / `autopilot-completed` batch events.** Per-issue events with `run_id` suffice.
4. **No `--format json` flag on `/metrics`.** Output stays markdown; machine consumers read state.json directly.
5. **No separate `pipeline-summary.json` artifact.** Summary table lives in `state.json.pipeline.summary_table`.
6. **No per-iteration token breakdown array** in `fixer_reviewer`. Cumulative only.
7. **No `core/pipeline-events.md` new file.** Extend `core/post-publish-hook.md` only.
8. **No schema version bump.** Stays `"1.0"`.
9. **No 8th Autopilot config key** (`Summary output` — roadmap lists 7).
10. **No richer webhook payload fields** (`parent_agent`, `tool_uses_by_type`, `previous_stage_duration_ms`, `iteration_index_of_N`, `flags`, `profile`, `blocked_at`, `stages_completed`, `schema_capabilities`, `tokens_by_model` in payload, `tokens_used` in `step-completed` payload).
11. **No webhook retry logic / dead-letter queue.** Advisory-only pattern preserved.
12. **No PR-body injection of summary table by default.** Future opt-in config flag only.

## Backward Compat Risks + Mitigations

1. **Mid-upgrade hybrid state.json** (v6.7.2 state read by v6.8.0 resume, or vice versa). *Mitigation:* Q11 HIGH — `/resume-ticket` reads 5 fields only; missing new fields silently `null`; `core/state-manager.md` merge-update preserves old fields. Phase 5 TDD: `regression-resume-v6.7.x-state.sh` — construct v6.7.2-shape state.json, run resume, assert no error.

2. **Strict webhook consumers on `pr-created` payload.** A consumer using a strict JSON schema validator may reject future payload additions. *Mitigation:* document forward-compat guarantee in CLAUDE.md Notifications ("additive fields may be added; consumers should use lenient parsing"). Preserves v6.7.x `pr-created` and `issue-blocked` byte-for-byte in v6.8.0.

3. **Autopilot lock file cross-repo collision** (same user, two projects). *Mitigation:* lock is project-directory-local (`.ceos-agents/` is per-project). Document explicitly in `skills/autopilot/SKILL.md` Step 1.

## Gate 1 Discussion Points (for user)

Two genuinely controversial decisions to surface:

- **`run_id` in webhook payloads.** Skeptic would reject (YAGNI, adds a field); Innovator strongly supports (enables re-run correlation). Judge picked include-it because the cost is one string field and the benefit is real when a ticket is re-run (otherwise consumers cannot distinguish two runs of the same ID). If the user prefers strict roadmap-minimum, remove `run_id` from payloads — consumers correlate on `issue_id` + `timestamp`.

- **`[WARN]` vs silent on absent Feature Workflow.** Skeptic (and Innovator for the Feature-limit>0 case) prefer `[WARN]`; Conservative prefers silent-skip matching `/metrics`. Judge chose `[WARN]` for operational visibility, but if the user values strict precedent-mirroring with `/metrics`, flip to silent-skip (Q7 is OPEN with MEDIUM confidence).

- **`tokens_used` vs `tokens_estimated` naming.** All three agents converged on `tokens_used`, but this creates a name divergence with forge.json's `tokens_estimated`. Confirm the user accepts the name divergence (future cross-plugin metrics aggregator needs a 3-row rename dictionary). Alternative: align to forge's `tokens_estimated` and update roadmap prose in a follow-up.

## Synthesis Attribution

| Element | Source | Modification |
|---|---|---|
| `disable-model-invocation: true` | Conservative + Skeptic | Adopted Skeptic's cleaner dispatcher-vs-entry-point reasoning |
| Lock file via PowerShell `CreateNew` + PID contents | Skeptic | Adopted as-is; Conservative's tmp+rename rejected (race window) |
| Dry-run full short-circuit | All three (unanimous) | Adopted as-is |
| `[WARN]` on absent Feature Workflow | Skeptic + Innovator | Overrode Conservative's silent-skip |
| 7 Autopilot config keys (roadmap verbatim) | Conservative + Skeptic | Innovator's 8th key (`Summary output`) rejected |
| Top-level event granularity only | Skeptic + Conservative | Innovator's opt-in `fixer-iteration-completed` rejected |
| Extend `core/post-publish-hook.md` | Conservative + Skeptic | Innovator's new `core/pipeline-events.md` rejected |
| Roadmap-minimum payload + `outcome` + `run_id` | Skeptic base + Innovator additions | Innovator's 8+ other fields rejected; kept only cheapest-with-evidence |
| No `step-skipped` event | Skeptic + Conservative | Innovator's opt-in token rejected |
| `tokens_used` naming | All three (unanimous) | Adopted |
| schema_version `"1.0"` | All three (unanimous) | Adopted |
| 6-field per-stage additions (roadmap verbatim) | Conservative + Skeptic | Innovator's `tool_uses_by_type`, `retry_count`, `parent_agent` rejected |
| Fixer-reviewer cumulative (no per-iteration array) | Conservative + Skeptic | Innovator's opt-in `iteration_breakdown` rejected |
| `pipeline.summary_table` inside state.json (no separate file) | Skeptic | Innovator's `pipeline-summary.json` deferred to v6.9.0 |
| `/metrics` dual-mode, no `--format json` | Skeptic | Innovator's format-json deferred to v6.9.0 |
| Forward-compat guarantee doc paragraph | Skeptic | Adopted |
| No batch events | Skeptic + Conservative | Innovator's `autopilot-started/completed` deferred to v6.9.0 |
| state.json backward-compat via merge-write | Conservative | Adopted; Phase 5 regression test added |
| Extend rename of `core/post-publish-hook.md` Purpose line | Conservative | Adopted |

---

## Gate 1 Decisions (User-Approved 2026-04-17)

The Judge's synthesis was approved with **one revision**:

| # | Decision Point | Judge Recommendation | Final Decision |
|---|---|---|---|
| 1 | `run_id` in webhook payloads | Include | **Approved — include** |
| 2 | Feature Workflow absent behavior | `[WARN]` + bug-only mode | **Approved — `[WARN]`** |
| 3 | Token field name | `tokens_used` | **Approved — `tokens_used`** |
| 4 | Lock mechanism | PowerShell `[System.IO.File]::Open(..., CreateNew, ...)` | **REVISED — `mkdir`-based portable bash** |

### Lock Mechanism Revision Rationale

The Judge selected PowerShell `CreateNew` for Windows atomicity. At Gate 1, this was revised to **`mkdir`-based bash lock** because:

1. **No new cross-platform dependency**: Bash is already a hard dependency via `./tests/harness/run-tests.sh`. PowerShell 7+ is cross-platform but is NOT installed by default on Linux/macOS (requires `apt install powershell` or `brew install powershell`).
2. **`mkdir` is atomic on all filesystems**: POSIX and Windows NTFS both guarantee that `mkdir` either creates the directory (success) or fails atomically if it exists. This is the canonical portable exclusive-create primitive.
3. **Language consistency**: Existing test harness, `core/state-manager.md` atomic-write pattern, and all webhook invocations are bash. Adding pwsh would create a two-interpreter plugin.

### Final Lock File Design

- **Path**: `.ceos-agents/autopilot.lock/` (DIRECTORY, not a file)
- **Acquisition (portable bash):**
  ```bash
  if mkdir ".ceos-agents/autopilot.lock" 2>/dev/null; then
    echo "{\"pid\":$$,\"hostname\":\"$(hostname)\",\"acquired_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" \
      > ".ceos-agents/autopilot.lock/owner.json"
  else
    # Read existing owner, check if stale (acquired_at > 120min ago)
    # If stale: remove and retry once
    # If fresh: print "[autopilot][ERROR] Another Autopilot run in progress" and exit
  fi
  ```
- **Release**: `rm -rf ".ceos-agents/autopilot.lock"` in trap EXIT
- **Stale detection**: 120 minutes per roadmap line 633 — parse `owner.json.acquired_at`, compare to current time in UTC
- **Owner metadata**: `{pid, hostname, acquired_at}` as JSON inside the lock directory (file `owner.json`)

### Remaining Implementation Notes for Phase 4

- Spec must mandate `trap "rm -rf .ceos-agents/autopilot.lock" EXIT` in the Autopilot skill's Step 0 so crashes release the lock
- Windows Git Bash: `mkdir` resolves via MSYS and works identically; no special casing needed
- Native Windows PowerShell (not bash): out of scope — Autopilot runs via Claude Code's Bash tool
