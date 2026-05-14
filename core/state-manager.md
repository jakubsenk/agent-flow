# State Manager

## Purpose

Read, write, and resume contract for `.agent-flow/{RUN-ID}/state.json`. Provides atomic state persistence for all pipeline commands, enabling deterministic resume and metrics collection.

## Input Contract

### Write Operation
- **run_id** (string, required): Issue ID or generated ID
- **field_path** (string, required): Dot-notation path (e.g., "triage.status", "fixer_reviewer.iterations")
- **value** (any, required): Value to set at the field path

### Read Operation
- **run_id** (string, required): Issue ID or generated ID

### Resume Operation
- **run_id** (string, required): Issue ID or generated ID

## Process

### Write Process
1. Read current state from `.agent-flow/{RUN-ID}/state.json`
2. If file does not exist, initialize from schema template (see `state/schema.md`)
2a. On initialization (first write only): read the `version` field from `.claude-plugin/plugin.json` and write it to the `plugin_version` field in state.json. If the file is unreadable, contains malformed JSON, or lacks a `version` field: set `plugin_version` to `null` — no error, no warning.
3. Set the value at the specified field_path (supports all top-level sections from `state/schema.md` including the optional `infrastructure` object — typically only written by the scaffold pipeline at Step 0-INFRA)
4. Update `updated_at` to current ISO-8601 timestamp
5. Append event to `.agent-flow/{RUN-ID}/pipeline.log` (JSONL format)
6. Write to `.agent-flow/{RUN-ID}/state.json.tmp`
7. Rename `.tmp` to `.json` (atomic on POSIX; best-effort on Windows)
8. If write fails: retry once. If second attempt fails: log warning, continue pipeline (state loss is acceptable; pipeline must not block on state write failure)

### Read Process
1. If `.agent-flow/{RUN-ID}/state.json` exists: read and return parsed JSON
2. If not: return null (caller must handle missing state)

### Resume Process
1. Read state.json. If exists:
   - Find the first step with status "in_progress" or "pending" after all "completed" steps
   - Return resume_point (step name) and resume_context (triage AC, complexity, iteration counts)
2. If state.json does not exist:
   - Fall back to heuristic detection using these checkpoints (priority order):

     | Checkpoint | Signal | Skips |
     |-----------|--------|---------|
     | `PUBLISHED` | Open PR exists for branch | Entire pipeline |
     | `DECOMPOSE_PARTIAL` | `.claude/decomposition/{ISSUE-ID}.yaml` exists | Triage + analysis + completed subtasks |
     | `POST_REVIEW` | Branch + reviewer approval comment | Triage + analyst + fixer + reviewer |
     | `POST_FIX` | Branch with commits above base | Triage + analyst + fixer |
     | `POST_ANALYSIS` | Branch exists + triage comment | Triage + analyst |
     | `POST_TRIAGE` | Triage comment exists | Triage |

   - Return resume_point from heuristic with reduced context (no AC list, no iteration counts)

## Output Contract

### Write Output
- Updated state.json file (atomic)
- Appended event in pipeline.log

### Read Output
- Full state object (JSON) or null

### Resume Output
- resume_point: string (step name to resume from)
- resume_context: object (triage data, iteration counts, relevant prior results)
- detection_method: "state_file" | "heuristic_fallback"

## Usage Field Capture

Documents the canonical pattern for pipeline skills to record per-stage observability fields. All writes use the existing atomic tmp+rename mechanism — no new write path is introduced.

### Stage Lifecycle Writes

**Before agent dispatch** (COST-R4): write three fields atomically as a single state update:

```
{stage}.started_at   = current ISO-8601 UTC timestamp
{stage}.model        = value of "model:" frontmatter field in agents/{agent-name}.md (read at dispatch time)
{stage}.status       = "in_progress"
```

Also initialize the usage counters so a partial failure leaves known-good defaults:

```
{stage}.tokens_used  = 0
{stage}.duration_ms  = 0
{stage}.tool_uses    = 0
```

**After agent dispatch** (COST-R2, COST-R4): defensive-read `result.usage` from the Task tool response and write:

```
{stage}.completed_at = current ISO-8601 UTC timestamp
{stage}.tokens_used  = result.usage.total_tokens  (allowlist: total_tokens | input_tokens+output_tokens | tokens_estimated — field name discovered per COST-R12)
{stage}.duration_ms  = completed_at epoch ms − started_at epoch ms
{stage}.tool_uses    = result.usage.tool_uses
{stage}.status       = "completed"
```

If `result.usage` is null or any individual field is absent (COST-R3): write `0` for each missing count, do not retry, do not block the pipeline.

**Field name discovery (COST-R12):** The exact Task-tool field name for token counts is determined by running `tests/scenarios/cost-task-tool-usage-field-discovery.sh` before implementation. The test asserts the discovered name matches the known allowlist `{total_tokens, input_tokens+output_tokens, tokens_estimated}` and emits `DISCOVERED_FIELD={name}` to stdout. The implementation wires this discovered name into every COST-R2 read.

**Concrete per-stage JSON shape** (design.md §4.1):

```json
{
  "triage": {
    "status": "completed",
    "tokens_used": 12500,
    "duration_ms": 45000,
    "tool_uses": 8,
    "model": "sonnet",
    "started_at": "2026-04-17T14:30:00Z",
    "completed_at": "2026-04-17T14:30:45Z"
  }
}
```

Field defaults when absent or null usage: `tokens_used: 0`, `duration_ms: 0`, `tool_uses: 0`, `model: null`, `started_at: null`, `completed_at: null`.

### Pipeline Accumulator Write

Written ONCE at pipeline end (success or block), BEFORE the terminal `status` write (COST-R6). Sums across all completed stages:

```
pipeline.total_tokens      = sum({stage}.tokens_used   for all completed stages)
pipeline.total_duration_ms = sum({stage}.duration_ms   for all completed stages)
pipeline.total_tool_uses   = sum({stage}.tool_uses      for all completed stages)
pipeline.summary_table     = markdown string (see below)
```

`summary_table` is a markdown-in-JSON convenience string (design.md §4.2). It is bounded by COST-R10: at most 20 rows (excluding header and Total); if truncated, a truncation-notice row `| ... | (truncated, N more stages in pipeline.log) | ... |` is appended immediately before the `Total` row. Maximum 4000 characters. Consumers SHOULD prefer reading the structured numeric fields; `summary_table` may evolve without a `schema_version` change.

The accumulator write uses the existing atomic tmp+rename write path — no new mechanism.

### Fixer-Reviewer Cumulative Write

The `fixer_reviewer` stage accumulates token counts cumulatively across iterations (COST-R5). After each fixer or reviewer invocation within the loop:

```
fixer_reviewer.tokens_used  += iteration_tokens_used   (running total)
fixer_reviewer.duration_ms  += iteration_duration_ms
fixer_reviewer.tool_uses    += iteration_tool_uses
```

No per-iteration breakdown array is persisted. The final `fixer_reviewer.tokens_used` equals the cumulative sum across all iterations. This single-stage object is consistent with all other stage objects written by the accumulator pass.

<!-- v6.7.x backward-compat read removed in v9.5.0 (lenient-read promise of schema_version 1.0 still honored for unknown fields; missing-field defaults removed because all v9 writers populate these fields) -->

## Failure Handling

- **Atomic write failure:** Retry once with 1-second delay. If retry fails: log `STATE_WRITE_FAILED` event to stderr, continue pipeline execution. State persistence is advisory — pipeline MUST NOT block on state write failures.
- **Corrupted state file:** If JSON parse fails on read: rename corrupted file to `state.json.corrupt.{timestamp}`, log warning, return null (triggers heuristic fallback on resume).
- **Missing directory:** Create `.agent-flow/{RUN-ID}/` on first write. If directory creation fails: log warning, skip state writes for this run.
- **Concurrent access (fix-bugs parallel mode):** Each issue has its own directory (`.agent-flow/{ISSUE-ID}/`). No file-level locking needed — parallel tickets never share state files. If two sessions process the same ticket: last-write-wins (acceptable — human should not run the same ticket twice).

