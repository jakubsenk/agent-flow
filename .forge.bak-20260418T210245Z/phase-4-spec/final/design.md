# Phase 4 Spec — ceos-agents v6.8.0 — Design & Contracts (Revision 2)

Companion to `requirements.md` and `formal-criteria.md`. Contains Sections 3 (File-level Design) and 4 (Contracts).

**Revision notes (round 1):** addresses review-1-compliance.md (traceability), review-2-quality.md (18 findings, MAJOR 1/2/3/4/5/6/7/8/9/10/11/12), review-3-devilsadvocate.md (12 findings, MAJOR 1/2/3/4/5 and MINOR 6–12). Gate 1 decisions not reopened.

**Revision notes (round 2 — surgical polish):** addresses review-6-devilsadvocate.md round-2 findings (MAJOR round2-1 cross-host-hint sidecar dropped; MINOR round2-3 compact `run_id` format; MINOR round2-2 BusyBox awk-mktime fallback; MINOR round2-4 COST-R12 discovery test must assert known field-name set) + review-5-quality.md round-2 nits (AC-1 anchored grep; AC-36 apostrophe literal). Revision-2 changelog: `.forge/phase-4-spec/revision-2-polish-notes.md`.

---

## Canonical Definitions

- **`run_id`**: `"{issue_id}_{YYYYMMDDTHHMMSSZ}"` where the timestamp is the wall-clock UTC pipeline-start time rendered in compact ISO-8601 basic-format (no colons, no dashes in the time component). Example: `PROJ-42_20260417T143000Z`. This form is URL-safe, filename-safe (NTFS-compatible), and shell-word-safe — no colons, no slashes, no spaces. The same wall-clock instant is later persisted as the first-stage `started_at` in extended ISO-8601 form (for human readability). Two re-runs of the same issue produce distinct `run_id`s because the timestamp differs. Consumers MUST treat `run_id` as opaque. See Known Limitations §8.1 for collision caveat.
- **Stage canonical names**: `triage`, `code_analysis`, `reproduction`, `fixer_reviewer`, `test`, `e2e_test`, `browser_verification`, `acceptance_gate`, `publisher`, `deployment`, `spec_analysis`, `architect`, `spec_writer`, `spec_reviewer`, `scaffolder`. The reproducer AGENT (`agents/reproducer.md`) writes to the `reproduction` STAGE; implementers MUST NOT use `reproducer` as a stage key or webhook `step_name`.
- **Model derivation**: `{stage}.model` is read at dispatch time from the `model:` frontmatter field of the dispatched agent file (`agents/{agent-name}.md`). For fixer_reviewer, the recorded model is `opus` (both fixer and reviewer are opus — hardcoded in the mapping table below).

### Stage → agent file mapping (for `{stage}.model` derivation)

| Stage | Agent file | Frontmatter `model` |
|---|---|---|
| `triage` | `agents/triage-analyst.md` | sonnet |
| `code_analysis` | `agents/code-analyst.md` | sonnet |
| `reproduction` | `agents/reproducer.md` | sonnet |
| `fixer_reviewer` | `agents/fixer.md` + `agents/reviewer.md` | opus (recorded as single value since both agents share `opus`) |
| `test` | `agents/test-engineer.md` | sonnet |
| `e2e_test` | `agents/e2e-test-engineer.md` | sonnet |
| `browser_verification` | `agents/browser-verifier.md` | sonnet |
| `acceptance_gate` | `agents/acceptance-gate.md` | sonnet |
| `publisher` | `agents/publisher.md` | haiku |
| `deployment` | `agents/deployment-verifier.md` | sonnet |
| `spec_analysis` | `agents/spec-analyst.md` | sonnet |
| `architect` | `agents/architect.md` | opus |
| `spec_writer` | `agents/spec-writer.md` | opus |
| `spec_reviewer` | `agents/spec-reviewer.md` | opus |
| `scaffolder` | `agents/scaffolder.md` | sonnet |

---

## Section 3: File-Level Design

Every file below lists: exact path, change type (NEW/MODIFY), what changes, why, and EARS requirement IDs satisfied.

### 3.1 Autopilot skill

| Path | Change | What | Why | Requirements |
|---|---|---|---|---|
| `skills/autopilot/SKILL.md` | NEW | Skill with frontmatter (`name: autopilot`, `description`, `allowed-tools: mcp__*, Bash, Read, Write, Edit, Grep, Glob, Skill, Task`, `disable-model-invocation: true`, `argument-hint: "[--dry-run]"`) and 6 numbered steps: (0) config read + Issue-Tracker validation + MCP ping; (1) lock acquisition via `mkdir` with stale check; trap registration AFTER successful mkdir; (2) two-query classification; (3) dispatch loop via Skill tool; (4) summary append to log file; (5) lock release via trap. Dry-run short-circuit after Step 2 before lock acquisition. | New entry point for headless cron dispatch per roadmap line 625. | AUTOPILOT-R1..R13 |

### 3.2 Core contracts

| Path | Change | What | Why | Requirements |
|---|---|---|---|---|
| `core/post-publish-hook.md` | MODIFY | Rename Purpose line to `Execute pipeline hooks and fire webhooks at stage boundaries.` Add Section 4 "Pipeline lifecycle events" documenting `pipeline-started`, `step-completed`, `pipeline-completed` payload shapes (reference Section 4 of this design doc), fire sites (cross-reference to 4 pipeline skills), fire order rule (state.json commit MUST precede webhook fire — Section 4 adds "WEBHOOK-R3 fire-order: the skill commits state atomically, then fires; a failed commit suppresses the webhook"), and explicit inheritance clause: "Transport, curl invocation, and failure handling are identical to Section 3." | Single file owns webhook curl pattern + advisory-only clause; no new file. | WEBHOOK-R1, WEBHOOK-R2..R5 |
| `core/state-manager.md` | MODIFY | Add Section "Per-stage usage write pattern" under Process documenting: (1) write `{stage}.started_at` + `{stage}.model` + `{stage}.status: in_progress` before dispatch; (2) after dispatch, defensive read `result.usage.total_tokens|duration_ms|tool_uses` with fallback to 0; (3) write to state.json; (4) accumulate fixer-reviewer cumulatively. Note: Write Process itself is unchanged; only documents additional canonical field paths. | Gives pipeline skills a single authoritative pattern to reference. | COST-R2, COST-R3, COST-R4, COST-R5 |
| `state/schema.md` | MODIFY | (a) In Full Schema Example, append the six usage fields to each of: `triage`, `code_analysis`, `reproduction`, `fixer_reviewer`, `test`, `e2e_test`, `browser_verification`, `acceptance_gate`, `publisher`, `deployment`, `spec_analysis`, `architect`, `spec_writer`, `spec_reviewer`, `scaffolder`. (b) Add a new top-level `pipeline` object with `total_tokens`, `total_duration_ms`, `total_tool_uses`, `summary_table`. (c) Add Top-Level Field Definitions rows for the new fields. (d) Preserve `schema_version: "1.0"` and its existing description line verbatim. (e) Add `run_id` canonical-definition paragraph referencing §4.3 of this doc (format `"{issue_id}_{started_at_ISO8601}"`). (f) Add subsection "summary_table: markdown-in-JSON convenience" stating consumers SHOULD read structured fields (total_tokens/duration_ms/tool_uses) to regenerate tables; markdown may evolve without schema_version change. (g) Add Event Log Format rows for the three new events (pipeline.log emission). | Contract surface documenting the additive fields; no breaking change. | COST-R1, COST-R2, COST-R6 |

### 3.3 Pipeline skills (four dispatchers)

| Path | Change | What | Why | Requirements |
|---|---|---|---|---|
| `skills/fix-ticket/SKILL.md` | MODIFY | (a) After config validation + state.json init: compute `run_id = "{issue_id}_{ISO8601-started-at}"`; fire `pipeline-started` webhook AFTER state.json init commits. (b) Around every top-level agent dispatch (triage, code_analysis, reproduction if run, fixer_reviewer loop, test, e2e_test if run, browser_verification if run, acceptance_gate if run, publisher): read agent model from frontmatter; write pre-dispatch fields; capture `result.usage`; write six usage fields; commit state atomically; ON SUCCESSFUL COMMIT fire `step-completed` webhook. (c) At terminal state write: compute `pipeline.*` accumulator (applying COST-R10 truncation); commit state; fire `pipeline-completed`. (d) Echo `pipeline.summary_table` to stdout at pipeline end. | Core observability integration for the bug-fix pipeline. | WEBHOOK-R2, R3, R4, R5, R6; COST-R2..R6, R10 |
| `skills/fix-bugs/SKILL.md` | MODIFY | Same event + usage-capture pattern, applied per-issue inside the batch loop (each issue gets its own 3 events). Stage enum matches fix-ticket. | Batch mode inherits per-issue events; autopilot inherits these via fix-ticket dispatch. | WEBHOOK-R2..R6; COST-R2..R6, R10 |
| `skills/implement-feature/SKILL.md` | MODIFY | Same pattern. Stage enum includes feature-specific stages (`spec_analysis`, `architect` before fixer_reviewer). | Feature pipeline parity. | WEBHOOK-R2..R6; COST-R2..R6, R10 |
| `skills/scaffold/SKILL.md` | MODIFY | Same pattern. Stage enum includes scaffold-specific stages (`spec_writer`, `spec_reviewer`, `scaffolder`) followed by the feature set when implementation runs. | Scaffold pipeline parity. | WEBHOOK-R2..R6; COST-R2..R6, R10 |

### 3.4 Read-only and reporting skills

| Path | Change | What | Why | Requirements |
|---|---|---|---|---|
| `skills/metrics/SKILL.md` | MODIFY | Insert new Step 3b "Read state.json per issue": glob `.ceos-agents/*/state.json`; classify each issue as MEASURED (if `pipeline.total_tokens` exists) or ESTIMATED (else, apply heuristic constants). Emit per-pipeline output rows in the format: `Pipeline {issue_id}: 42,150 tokens measured (N stages) + 0 tokens estimated (M stages) = 42,150 total`. For hybrid (some stages measured, some not), treat pipeline as ESTIMATED but include a detail line listing which stages had measured data. Append footer: `Data source: measured={X} issues, estimated={Y} issues (see per-issue breakdown above).` Never output a single combined grand total when any issues fall back to heuristics. Output format stays markdown — NO `--format json` changes. | Dual-mode aggregation during v6.7.x→v6.8.0 transition; transparency over neatness. | COST-R7, COST-R8, COST-R11 |
| `skills/dashboard/SKILL.md` | MODIFY | If `pipeline.total_tokens` exists in any state.json glob'd, render one compact row per issue: `{run_id} | {status} | {total_tokens} tok | {duration_ms/1000}s`. Otherwise unchanged. Non-structural — presentation only. | Trivial visualization gain; deferred richer view to v6.9.0. | COST-R6 (display) |

### 3.5 Config contract updates

| Path | Change | What | Why | Requirements |
|---|---|---|---|---|
| `core/config-reader.md` | MODIFY | Add new `### Autopilot` parse block with 7 dot-notation keys: `autopilot.max_issues_per_run` (default 1), `autopilot.lock_timeout` (default 120), `autopilot.log_file` (default `.ceos-agents/autopilot.log`), `autopilot.bug_limit` (default 0), `autopilot.feature_limit` (default 0), `autopilot.on_error` (default `skip`), `autopilot.dry_run` (default `false`). No change to Notifications parser (substring check unchanged). | Enables Autopilot skill to read its 7 keys via the standard contract. | AUTOPILOT-R6, R10, R11; WEBHOOK-R2..R4 (On events) |

### 3.6 Documentation and project contract

| Path | Change | What | Why | Requirements |
|---|---|---|---|---|
| `CLAUDE.md` | MODIFY | (a) Skill count table: 28 → 29. (b) Architecture skills list: add `/autopilot`. (c) Optional sections table: 17 → 18; add row `Autopilot | Max issues per run, Lock timeout, Log file, Bug limit, Feature limit, On error, Dry run | 1, 120, .ceos-agents/autopilot.log, 0, 0, skip, false`. (d) Notifications section: update `On events` enumeration to include `pipeline-started, step-completed, pipeline-completed`. (e) Add forward-compat paragraph under Notifications: "Webhook payloads are forward-compatible — additive fields may be added in future MINOR versions. Consumers should use lenient JSON parsing (ignore unknown fields)." (f) Add operator-trust note under Notifications: "The `Webhook URL` value is dispatched via `curl` without scheme/host validation. Operators are responsible for restricting this value to trusted internal observability endpoints." | Document the new optional section and the three new event tokens. | AUTOPILOT-R1, WEBHOOK-R2..R5 |
| `skills/workflow-router/SKILL.md` | MODIFY | Add Autopilot to intent-matching table: map user phrasings "run all bugs", "headless mode", "batch fix", "nightly run", "cron dispatch", "automate tracker" → `/ceos-agents:autopilot`. Bump intent row count if tracked. | workflow-router is the natural-language dispatcher; Autopilot must be discoverable. | AUTOPILOT-R1 |
| `docs/reference/skills.md` | MODIFY | Add row for `/autopilot` (description, model N/A dispatcher, arg hint `[--dry-run]`). Bump skill count 28 → 29 in summary table. | Reference catalog. | AUTOPILOT-R1 |
| `docs/reference/config.md` | MODIFY | Document `### Autopilot` section with the 7 keys table + defaults + types. Document updated Notifications enumeration. Add operator-trust note for Webhook URL (mirrors CLAUDE.md note in f). | Reference catalog for config consumers. | AUTOPILOT-R6, R10, R11 |
| `docs/reference/pipelines.md` | MODIFY | Add new subsection "Autopilot pipeline dispatcher" describing the batch-dispatch pattern: query → classify → per-issue dispatch of fix-ticket / implement-feature, cite the lock mechanism, link to `docs/guides/autopilot.md`. | Pipeline reference catalog must reflect the new dispatcher. | AUTOPILOT-R1, R2 |
| `docs/guides/autopilot.md` | NEW | Short (≤160 lines) operations guide: cron invocation line; lock-file location + stale recovery; `## Single-Host Operation` subsection (AUTHORITATIVE mitigation is operator-side DISJOINT-QUERY coordination — no file-based hint. WARNING block: "Autopilot's lock is process-local. Running Autopilot from multiple hosts against the SAME tracker will double-process issues. Operational requirement: run Autopilot from ONE cron host. If multi-host is unavoidable, configure DISJOINT `Bug query` / `Feature query` filters per host — e.g., `assignee = {hostname-specific-user}`. Autopilot emits an INFO line with the hostname on every run (AUTOPILOT-R13) to aid log correlation; the plugin provides NO automated detection of cross-host contention."); `## Platform Support` subsection (declares BusyBox ≥ 1.30 / bash ≥ 4.0 / modern gawk-or-macOS-awk for full staleness arithmetic; older BusyBox falls back to a 121-minute mtime-based staleness check); log file format; dry-run example; troubleshooting matrix (exit codes 2/3/4); operator-responsibility note for Webhook URL; advisory note for concurrent `/fix-ticket` + autopilot on same issue (state-manager last-write-wins; operators should not manually run fix-ticket on an issue currently in an autopilot batch). | Operator onboarding for headless deployment + disjoint-query coordination as the authoritative multi-host mitigation. | AUTOPILOT-R2, R3, R4, R11, R12, R13 |
| `CHANGELOG.md` | MODIFY | Add v6.8.0 entry dated `2026-04-17` with four subsections: `### Added` (Autopilot skill + 7-key config; Observability hooks × 3 events; Real-Time Cost Visibility state fields + /metrics dual-mode), `### Changed` (skill count 28→29; optional sections 17→18; schema schema_version unchanged; Notifications `On events` enumeration extended), `### Known Issues` (tokens_used vs forge's tokens_estimated divergence; summary_table is markdown-in-JSON convenience; webhook URL operator-trusted; multi-host lock limitation), `### Migration notes` (in-flight v6.7.2 pipelines resume cleanly but lack cost data for stages completed before upgrade; `/metrics` treats any state.json missing `pipeline.total_tokens` as ESTIMATED even if some stages have partial measured data). Classify as MINOR. | Release record + operator-facing deltas. | all |
| `.claude-plugin/plugin.json` | MODIFY | Bump `version` from `6.7.2` to `6.8.0`. | Version release. | all |
| `.claude-plugin/marketplace.json` | MODIFY | Bump version to `6.8.0` (matches plugin.json). | Version release. | all |
| `examples/config-templates/*.md` | DEFERRED (scoped) | **DECISION:** adding `### Autopilot` to each of 8 templates is deferred to v6.8.1. Rationale: Autopilot is an OPTIONAL section (defaults are sensible), adding it to templates requires per-template testing of 8 stack combinations, and the skill is fully usable by hand-writing the section from `CLAUDE.md` Optional-sections table. If no operator reports friction within 30 days of v6.8.0 release, templates will be left as-is indefinitely. Documented in CHANGELOG.md Known Issues. | Respect "don't let templates block the feature" pattern; preserve v6.8.0 surface area. | AUTOPILOT-R9 (documented deferral — not breaking) |

### 3.7 Tests

| Path | Change | What | Why | Requirements |
|---|---|---|---|---|
| `tests/scenarios/cost-task-tool-usage-field-discovery.sh` | NEW | FIRST test to run in Phase 5 (ordered before other cost tests). Dispatches ONE minimal `Task` call (e.g., a trivial sonnet agent that returns "ok") and prints the raw `result.usage` block to stdout. Asserts that the discovered token-count field name matches the known allowlist `{total_tokens, input_tokens+output_tokens, tokens_estimated}`. On a recognised field, prints structured summary line `DISCOVERED_FIELD={name}` to stdout and exits 0. On empty/absent/unknown field (dispatch failure or shape drift), prints `DISCOVERED_FIELD=<UNKNOWN|ABSENT>` and exits 1 (explicit failure — mechanical signal for Phase 7). | Resolves Phase 2 Q1 MEDIUM-confidence uncertainty about Task-tool usage shape with an allowlist assertion (DA round2-4). | COST-R2, COST-R12 |
| `tests/scenarios/autopilot-dry-run.sh` | NEW | Asserts: `/autopilot --dry-run` exits 0; no `.ceos-agents/autopilot.lock/` directory is created; stdout contains `[DRY RUN]`; no new state.json files written under `.ceos-agents/`. | Covers AUTOPILOT-R11. | AUTOPILOT-R11 |
| `tests/scenarios/autopilot-lock-acquire.sh` | NEW | Positive lock-acquire path: runs autopilot with a trivial empty-queue stub (no issues to dispatch); asserts that during execution `.ceos-agents/autopilot.lock/owner.json` exists with valid JSON containing `pid`, `hostname`, `acquired_at` keys; asserts exit 0 and lock is released afterward. | Covers AUTOPILOT-R2 directly (referenced by AC-2). | AUTOPILOT-R2 |
| `tests/scenarios/autopilot-lock-held.sh` | NEW | Pre-creates `.ceos-agents/autopilot.lock/` with fresh `owner.json`; runs autopilot; asserts exit 2; asserts `[autopilot][ERROR] Another Autopilot run in progress` appears on stderr or stdout; asserts the pre-existing lock directory is STILL present after the failed run (trap-race regression guard). | Covers AUTOPILOT-R3 and trap-race fix. | AUTOPILOT-R3 |
| `tests/scenarios/autopilot-lock-stale.sh` | NEW | Pre-creates lock with `acquired_at` = 121 minutes ago; runs autopilot with MCP stub; asserts re-acquire succeeds and dispatch proceeds. | Covers AUTOPILOT-R4. | AUTOPILOT-R4 |
| `tests/scenarios/autopilot-lock-stale-awk-missing.sh` | NEW | Stubs `awk` with a wrapper that returns "function mktime not defined" (simulates BusyBox < 1.30); pre-creates `.ceos-agents/autopilot.lock/owner.json` with `acquired_at` 130 minutes ago AND sets the file mtime ≥ 122 minutes old via `touch -d`; runs autopilot; asserts the BusyBox-fallback branch takes effect and the lock is re-acquired (exit 0). Also validates a matching negative case (mtime < 121min → exit 2 with the `awk mktime unavailable; mtime age < 121min` error). | Covers BusyBox fallback path for stale-lock arithmetic. | AUTOPILOT-R4 |
| `tests/scenarios/autopilot-trap-cleanup.sh` | NEW | Runs autopilot against a stub that returns non-zero after acquiring the lock; asserts exit code is non-zero AND `.ceos-agents/autopilot.lock/` is absent after exit (trap fires). Covers runtime behavior of R5 (complements the grep-based AC-5). | Covers AUTOPILOT-R5 runtime. | AUTOPILOT-R5 |
| `tests/scenarios/autopilot-feature-workflow-absent.sh` | NEW | Runs autopilot against a CLAUDE.md missing `### Feature Workflow`; asserts `[autopilot][WARN] Feature Workflow section absent` on stdout; asserts exit 0 after dispatching (or empty-queue no-op). | Covers AUTOPILOT-R7. | AUTOPILOT-R7 |
| `tests/scenarios/autopilot-feature-limit-no-query.sh` | NEW | Runs autopilot with `Feature limit: 5` in Autopilot section but no `Feature query` in Feature Workflow; asserts `[autopilot][WARN] Feature limit=5 configured but no Feature query` on stdout; asserts exit 0. | Covers AUTOPILOT-R8. | AUTOPILOT-R8 |
| `tests/scenarios/autopilot-on-error-stop.sh` | NEW | Configures `On error: stop`; stubs two issues where the first dispatch returns error; asserts loop breaks after issue 1 (second issue not dispatched); asserts dispatch count == 1. | Covers AUTOPILOT-R10 stop branch. | AUTOPILOT-R10 |
| `tests/scenarios/autopilot-mcp-unreachable.sh` | NEW | Stubs MCP ping to fail; runs autopilot; asserts exit 3; asserts `[STOP] MCP unreachable` appears on stderr (not stdout); asserts `.ceos-agents/autopilot.lock/` does NOT exist post-exit. | Covers AUTOPILOT-R12. | AUTOPILOT-R12 |
| `tests/scenarios/webhook-pipeline-events.sh` | NEW | Starts a local HTTP listener via pure-bash `nc -l` wrapped in a Python-fallback check (SKIP with exit 77 if neither `nc` nor `python3` is available); runs `fix-ticket` against a stub; asserts three payload files are captured containing `"event":"pipeline-started"`, `"event":"step-completed"`, `"event":"pipeline-completed"` with a non-null `run_id` field matching `^[A-Z]+-[0-9]+_[0-9]{8}T[0-9]{6}Z$` regex (compact basic-format ISO-8601, no colons — URL/filesystem/shell safe). | Covers WEBHOOK-R2, R3, R4 + run_id format. | WEBHOOK-R2, R3, R4 |
| `tests/scenarios/webhook-advisory-failure.sh` | NEW | Configures `Webhook URL` to an unreachable host (`http://127.0.0.1:1/`); asserts pipeline continues; asserts `[WARN] Webhook delivery failed` appears; asserts state.json reaches terminal state. | Covers WEBHOOK-R5. | WEBHOOK-R5 |
| `tests/scenarios/webhook-no-step-skipped.sh` | NEW | `grep -nE "step-skipped" skills/fix-ticket/SKILL.md skills/fix-bugs/SKILL.md skills/implement-feature/SKILL.md skills/scaffold/SKILL.md core/post-publish-hook.md` — asserts ZERO matches. | Covers WEBHOOK-R7 (referenced by AC-33). | WEBHOOK-R7 |
| `tests/scenarios/cost-state-fields.sh` | NEW | Runs a minimal pipeline dispatch with Task-tool stub returning `{usage: {total_tokens: 100, duration_ms: 1000, tool_uses: 2}}`; asserts `state.json` contains `triage.tokens_used == 100`, `triage.duration_ms == 1000`, `triage.tool_uses == 2`, `triage.model == "sonnet"`, `triage.started_at`, `triage.completed_at`. | Covers COST-R2, R4. | COST-R2, R4 |
| `tests/scenarios/cost-usage-null-defensive.sh` | NEW | Runs with Task-tool stub returning `{}` (no usage); asserts `tokens_used == 0`, `duration_ms == 0`, `tool_uses == 0`; pipeline proceeds without error. | Covers COST-R3. | COST-R3 |
| `tests/scenarios/cost-pipeline-accumulator.sh` | NEW | After full pipeline run, asserts `pipeline.total_tokens == sum({stage}.tokens_used)`, `pipeline.total_duration_ms == sum(duration_ms)`, `pipeline.total_tool_uses == sum(tool_uses)`, and `pipeline.summary_table` is a non-empty string starting with `"| Stage"`. | Covers COST-R6. | COST-R6 |
| `tests/scenarios/cost-summary-truncation.sh` | NEW | Stubs a pipeline that generates 25 stages; asserts `pipeline.summary_table` contains at most 20 rows (excluding header and Total), and that a truncation notice row `(truncated, N more stages in pipeline.log)` is present. | Covers COST-R10. | COST-R10 |
| `tests/scenarios/cost-resume-v6.7-state.sh` | NEW | Constructs a v6.7.2-shape state.json (no usage fields, no `pipeline` accumulator); runs `/resume-ticket`; asserts exit 0; asserts no unhandled key-missing error in output. | Covers COST-R9. | COST-R9 |
| `tests/scenarios/metrics-dual-mode.sh` | NEW | Glob includes two issue state.json files — one with `pipeline.total_tokens: 50000`, one legacy without; runs `/metrics`; asserts output contains measured line and estimated line as SEPARATE entries; asserts footer `Data source: measured=1 issues, estimated=1 issues`; asserts NO single-line grand total summing across the boundary. | Covers COST-R7, R8, R11. | COST-R7, R8, R11 |

`tests/harness/run-tests.sh` reads these scenarios automatically; no harness change. All scenarios declare precondition checks at top and exit 77 (SKIP) if unable to run on the current platform (Windows Git Bash vs Linux vs macOS).

---

## Section 4: Contracts (Concrete JSON Literals)

### 4.1 state.json per-stage usage block

Applied to each canonical stage (see Canonical Definitions above). Existing fields (status, iterations, etc.) remain unchanged. The stage key is `reproduction` (not `reproducer`).

```json
{
  "triage": {
    "status": "completed",
    "severity": "MEDIUM",
    "area": "auth",
    "complexity": "S",
    "acceptance_criteria": ["AC-1: ...", "AC-2: ..."],
    "reproduction_steps": null,
    "ac_source": "triage-analyst",
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

### 4.2 state.json top-level `pipeline` accumulator

Written once at pipeline end (before terminal state write). `summary_table` is a MARKDOWN CONVENIENCE STRING (see Known Limitations §8.7) bounded by COST-R10 (≤20 rows, ≤4000 characters).

```json
{
  "pipeline": {
    "total_tokens": 250700,
    "total_duration_ms": 692000,
    "total_tool_uses": 183,
    "summary_table": "| Stage | Model | Tokens | Duration | Tools |\n|---|---|---|---|---|\n| triage | sonnet | 12,500 | 45s | 8 |\n| code_analysis | sonnet | 18,200 | 62s | 12 |\n| fixer_reviewer | opus | 201,000 | 525s | 147 |\n| test | sonnet | 15,800 | 48s | 11 |\n| publisher | haiku | 3,200 | 12s | 5 |\n| **Total** |  | 250,700 | 692s | 183 |"
  }
}
```

Truncated example (>20 stages):

```
| Stage | Model | Tokens | Duration | Tools |
|---|---|---|---|---|
| triage | sonnet | ... | ... | ... |
| ...(rows 2–20)... |
| ... | (truncated, 5 more stages in pipeline.log) | ... | ... | ... |
| **Total** |  | 410,000 | 1,830s | 302 |
```

### 4.3 Webhook payload — `pipeline-started`

`run_id` format is `"{issue_id}_{YYYYMMDDTHHMMSSZ}"` (compact basic-format ISO-8601, no colons).

```json
{
  "event": "pipeline-started",
  "run_id": "PROJ-42_20260417T143000Z",
  "issue_id": "PROJ-42",
  "pipeline": "fix-ticket",
  "timestamp": "2026-04-17T14:30:00Z"
}
```

### 4.4 Webhook payload — `step-completed`

```json
{
  "event": "step-completed",
  "run_id": "PROJ-42_20260417T143000Z",
  "issue_id": "PROJ-42",
  "step_name": "fixer_reviewer",
  "duration": 525,
  "iteration_count": 3,
  "timestamp": "2026-04-17T14:40:00Z"
}
```

`duration` is in whole seconds (payload brevity). `iteration_count` is 1 for non-loop stages. `step_name` MUST use canonical stage names (Canonical Definitions above).

### 4.5 Webhook payload — `pipeline-completed`

```json
{
  "event": "pipeline-completed",
  "run_id": "PROJ-42_20260417T143000Z",
  "issue_id": "PROJ-42",
  "status": "completed",
  "outcome": "success",
  "duration": 692,
  "pr_url": "https://gitea.example.com/owner/repo/pulls/99",
  "timestamp": "2026-04-17T14:42:00Z"
}
```

`outcome` is one of: `success`, `blocked`, `failed`. `pr_url` is `null` when no PR was created.

### 4.6 Autopilot lock file — `.ceos-agents/autopilot.lock/owner.json`

Lock is a DIRECTORY `.ceos-agents/autopilot.lock/` created atomically by `mkdir`. Owner metadata lives in `owner.json` inside. Note: path is resolved to ABSOLUTE at lock acquisition (see §4.8) to avoid CWD-dependent trap deletion.

```json
{
  "pid": 12345,
  "hostname": "ceos-builder-01",
  "acquired_at": "2026-04-17T14:30:00Z"
}
```

`acquired_at` is ISO 8601 UTC. Stale threshold = 120 minutes by default (`Lock timeout`).

### 4.7 `### Autopilot` config section (verbatim for CLAUDE.md)

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

Types & semantics:

| Key | Type | Default | Semantics |
|---|---|---|---|
| `Max issues per run` | integer ≥ 1 | `1` | Hard cap on dispatched issues per invocation; applied after limits. |
| `Lock timeout` | integer (minutes) | `120` | Stale threshold for `.ceos-agents/autopilot.lock/`. |
| `Log file` | path | `.ceos-agents/autopilot.log` | Append-only ISO-8601 summary line per run. |
| `Bug limit` | integer ≥ 0 | `0` | `0` = unlimited from bug query; otherwise caps bug results. |
| `Feature limit` | integer ≥ 0 | `0` | `0` = unlimited from feature query; otherwise caps feature results. |
| `On error` | enum `skip` or `stop` | `skip` | Per-issue error handling in dispatch loop. |
| `Dry run` | boolean | `false` | Full short-circuit when `true` — no lock, no state, no webhook, no dispatch. |

### 4.8 Autopilot lock acquisition snippet (portable bash, revised)

Key invariants addressed (f-devilsadvocate-10, f-devilsadvocate-11, f-quality-6, f-quality-7, f-quality-11, f-quality-12, round2-1):

1. `LOCK_DIR` is resolved to an ABSOLUTE path before the trap is installed (CWD-change-safe).
2. The `trap ... EXIT` is installed ONLY AFTER a successful `mkdir` (or successful stale re-acquire).
3. The trap verifies `owner.json.pid` matches the current shell PID (`$$`) before `rm -rf` — refuses to nuke another process's lock.
4. ISO-8601 `acquired_at` parsing uses pure bash/awk arithmetic (no GNU-date `-d`, no BSD-date `-j -f`, no Python 3 dependency) — portable to Linux, Windows Git Bash, macOS.
5. Empty or malformed `owner.json` triggers defensive retry (rather than treating as fresh).
6. Stale threshold includes a +5 minute buffer to absorb NFS/CIFS clock skew.
7. No sidecar files outside `$LOCK_DIR` — cross-host awareness is purely an always-on INFO log line (AUTOPILOT-R13), not a persistent hint file.

**Stale-lock arithmetic / BusyBox fallback:** If `awk mktime` is unavailable (e.g. minimal BusyBox < 1.30 images in Alpine 3.9 and earlier), `iso_to_epoch` returns empty. In that case the Autopilot shall treat the existing lock as stale after 121 minutes (conservative fallback: the `LOCK_TIMEOUT + 5` buffer, rounded up) using a wall-clock mtime check on `$LOCK_DIR/owner.json` via `find "$LOCK_DIR/owner.json" -mmin +121 -print`. Test `tests/scenarios/autopilot-lock-stale-awk-missing.sh` validates this fallback path.

```bash
# --- Portable ISO-8601 → epoch (pure bash/awk, no -d / -j -f) ---
iso_to_epoch() {
  # Input: 2026-04-17T14:30:00Z → epoch seconds
  local ts="$1"
  [ -z "$ts" ] && { echo ""; return 1; }
  # Strip non-digits: YYYYMMDDHHMMSS
  local Y=${ts:0:4} M=${ts:5:2} D=${ts:8:2} h=${ts:11:2} m=${ts:14:2} s=${ts:17:2}
  # Validate all numeric
  case "$Y$M$D$h$m$s" in
    *[!0-9]*|"") echo ""; return 1 ;;
  esac
  # Use awk's mktime (available in gawk + BusyBox >=1.30 + macOS awk)
  awk -v Y="$Y" -v M="$M" -v D="$D" -v h="$h" -v m="$m" -v s="$s" \
    'BEGIN { print mktime(Y" "M" "D" "h" "m" "s" UTC") }'
}

# --- Lock acquisition ---
LOCK_DIR="$(pwd)/.ceos-agents/autopilot.lock"
OWNER_PID=$$
OWNER_HOST=$(hostname)
OWNER_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOCK_TIMEOUT=${LOCK_TIMEOUT:-120}
LOCK_TIMEOUT_WITH_BUFFER=$((LOCK_TIMEOUT + 5))

write_owner_json() {
  printf '{"pid":%s,"hostname":"%s","acquired_at":"%s"}\n' \
    "$OWNER_PID" "$OWNER_HOST" "$OWNER_TIME" \
    > "$LOCK_DIR/owner.json"
}

install_trap() {
  # Trap body: verify ownership BEFORE rm -rf. Uses absolute LOCK_DIR.
  trap '
    if [ -f "'"$LOCK_DIR"'/owner.json" ]; then
      own_pid=$(grep -o "\"pid\"[[:space:]]*:[[:space:]]*[0-9]*" "'"$LOCK_DIR"'/owner.json" 2>/dev/null | grep -o "[0-9]*$")
      if [ "$own_pid" = "'"$OWNER_PID"'" ]; then
        rm -rf "'"$LOCK_DIR"'"
      fi
    fi
  ' EXIT
}

log_single_host_info() {
  # AUTOPILOT-R13: always emit INFO on lock acquire — informational, no race, no sidecar.
  echo "[autopilot][INFO] Running on host ${OWNER_HOST}. If another host is also running Autopilot against the same tracker, it MUST use a disjoint bug/feature query. See docs/guides/autopilot.md#single-host-operation." >&2
}

# Step 1: try to acquire
if mkdir "$LOCK_DIR" 2>/dev/null; then
  write_owner_json
  install_trap                # ← trap registered AFTER successful acquisition
  log_single_host_info
else
  # Lock exists — check staleness
  if [ ! -f "$LOCK_DIR/owner.json" ]; then
    # Empty/malformed lock — treat as stale and recover
    rm -rf "$LOCK_DIR"
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      write_owner_json
      install_trap
    else
      echo "[autopilot][ERROR] Another Autopilot run in progress (malformed lock recovery failed)" >&2
      exit 2
    fi
  else
    acquired_at=$(grep -o '"acquired_at":"[^"]*"' "$LOCK_DIR/owner.json" | cut -d'"' -f4)
    if [ -z "$acquired_at" ]; then
      # Defensive: empty or partial write → treat as stale
      rm -rf "$LOCK_DIR"
      if mkdir "$LOCK_DIR" 2>/dev/null; then
        write_owner_json
        install_trap
        log_single_host_info
      else
        echo "[autopilot][ERROR] Another Autopilot run in progress (defensive-parse recovery failed)" >&2
        exit 2
      fi
    else
      acquired_epoch=$(iso_to_epoch "$acquired_at")
      # BusyBox fallback: if awk mktime unavailable, iso_to_epoch returns empty.
      # Fall back to filesystem mtime check at 121-minute boundary.
      if [ -z "$acquired_epoch" ]; then
        if find "$LOCK_DIR/owner.json" -mmin +121 -print 2>/dev/null | grep -q .; then
          rm -rf "$LOCK_DIR"
          if mkdir "$LOCK_DIR" 2>/dev/null; then
            write_owner_json
            install_trap
            log_single_host_info
          else
            echo "[autopilot][ERROR] Another Autopilot run in progress (BusyBox-fallback recovery race)" >&2
            exit 2
          fi
        else
          echo "[autopilot][ERROR] Another Autopilot run in progress (awk mktime unavailable; mtime age < 121min)" >&2
          exit 2
        fi
      else
        now_epoch=$(date -u +%s)
        age_min=$(( (now_epoch - acquired_epoch) / 60 ))
        if [ "$age_min" -gt "$LOCK_TIMEOUT_WITH_BUFFER" ]; then
          rm -rf "$LOCK_DIR"
          if mkdir "$LOCK_DIR" 2>/dev/null; then
            write_owner_json
            install_trap
            log_single_host_info
          else
            echo "[autopilot][ERROR] Another Autopilot run in progress (stale recovery race)" >&2
            exit 2
          fi
        else
          echo "[autopilot][ERROR] Another Autopilot run in progress (age ${age_min}min < ${LOCK_TIMEOUT_WITH_BUFFER}min)" >&2
          exit 2
        fi
      fi
    fi
  fi
fi
```

Windows Git Bash: `mkdir`, `awk`, `grep`, `hostname`, `date -u +%s`, `date -u +%Y-%m-%dT%H:%M:%SZ` all resolve via MSYS coreutils and work identically. macOS: `awk mktime` is supported; `date +%s` is POSIX. Linux: all POSIX. No GNU-date `-d` or BSD-date `-j -f` used.
