# Phase 2 Research Answers — Agent 2 (Categories D, E, F)

## Self-score: 0.91

---

### D — NEEDS_CLARIFICATION State

**A-D-1.** How is NEEDS_DECOMPOSITION integrated end-to-end — from agent output signal to state.json?

The `NEEDS_DECOMPOSITION` signal is defined in `agents/fixer.md` lines 36–47 as a fenced markdown block:
```markdown
## NEEDS_DECOMPOSITION
- **Reason:** {why the fix is larger than expected}
- **Estimated scope:** {N files, ~M lines}
- **Suggested split:** {2-3 subtasks that would break this down}
- **Work done so far:** {what was completed, if anything}
```

- Evidence:
  - `agents/fixer.md:39`: `"STOP coding immediately"`
  - `agents/fixer.md:83`: `"MUST use the exact string NEEDS_DECOMPOSITION when signaling decomposition need. No variations"`
  - `skills/fix-ticket/SKILL.md:328-332`: `"If fixer output contains ## NEEDS_DECOMPOSITION: 1. Authoritative revert: git checkout . && git clean -fd (safety net — fixer's self-revert is best-effort and not guaranteed) 2. If decompose_mode = DISABLED → Block ("Fixer needs decomposition but --no-decompose was set") 3. If this ticket has already been decomposed once → Block ("Decomposition limit (1) reached") 4. Run architect agent for decomposition... 5. Continue with subtask execution (step 4c)"`
  - `core/fixer-reviewer-loop.md:3`: `"If fixer output contains ## NEEDS_DECOMPOSITION → return NEEDS_DECOMPOSITION immediately. Only allowed once per ticket; caller enforces the limit."`
  - `core/fixer-reviewer-loop.md:44`: `"Callers: skills/fix-ticket/SKILL.md step 5 (revert + re-decompose, max 1), skills/fix-bugs/SKILL.md step 4 (revert + re-decompose per-bug, max 1), skills/implement-feature/SKILL.md step 6b (block current subtask or block issue in single-pass)."`
  - `state/schema.md:123-128`: `decomposition` object holds `status`, `decision` ("DECOMPOSE" or "SINGLE_PASS"), `subtasks[]`, `strategy`. No dedicated top-level `block` sub-field is used; `decomposition.status` transitions to `"completed"` regardless of the path.
- Inference: NEEDS_CLARIFICATION should follow this same pattern: (1) agent outputs a fenced `## NEEDS_CLARIFICATION` block, (2) skill detects it by exact string match, (3) skill writes a new top-level `clarification` object to state.json, (4) skill sets a new status variant (or stays as `running` with clarification sub-status). The signal is caller-side controlled, not agent-side stored.
- Recommendation: Use `## NEEDS_CLARIFICATION` as the exact match token (parallel to `## NEEDS_DECOMPOSITION`). No variation allowed — same constraint convention.

---

**A-D-2.** What additive JSON shape in state/schema.md would represent NEEDS_CLARIFICATION pause?

The state.json `schema_version` remains `"1.0"` under the additive-field policy documented at `state/schema.md:5-6`: `"The six per-stage usage fields... and the top-level pipeline accumulator are additive additions. schema_version remains '1.0'. Readers from v6.7.x that do not recognize these fields will ignore them — no schema version bump is needed."` The Step Status Enum at `state/schema.md:449-461` currently contains: `pending`, `in_progress`, `completed`, `failed`, `skipped`, `blocked`, `not_applicable`. There is no `awaiting_clarification` value. The top-level `block` field is `object or null` at line 315.

- Evidence:
  - `state/schema.md:5-6`: additive fields permitted, no bump.
  - `state/schema.md:219`: `"status" — One of: running, completed, blocked, failed.` (top-level pipeline status).
  - `state/schema.md:315`: `"block | object or null | Yes | null | If the pipeline was blocked: {agent, step, reason, detail, recommendation}. Null when not blocked."`
- Inference: A separate top-level `clarification` object (parallel to `block`) is cleanest. A `paused` value must be added to the top-level `status` enum (currently `running | completed | blocked | failed`) and a new `awaiting_clarification` added to the Step Status Enum.
- Recommendation: Add top-level `clarification` object as an additive field (not modifying `block`):
  ```json
  "clarification": {
    "question": "string (max 280 chars)",
    "asked_by_agent": "fixer | triage-analyst",
    "asked_at_step": "string (canonical stage name)",
    "asked_at_iteration": "integer or null",
    "context": "string (optional, max 500 chars)",
    "answer": "string or null"
  }
  ```
  Add `"paused"` to top-level `status` enum and `"awaiting_clarification"` to Step Status Enum. Both additions are additive (new values, no renames). `schema_version` stays `"1.0"`.

---

**A-D-3.** How does resume-ticket currently resume, and where does the NEEDS_CLARIFICATION answer injection fit?

`skills/resume-ticket/SKILL.md` State File Detection (Priority 0) at lines 17-31 reads state.json and determines resume point:
- `state/schema.md` Step 1: `"Find the first step with status: 'in_progress' → resume from that step"` 
- `state/schema.md` Step 2: `"If no 'in_progress' step: find the first 'pending' step after all 'completed' steps"`

At line 81-94 (issue_id validation), then lines 96-114 (pipeline type detection). The critical resume-decision code is at `skills/resume-ticket/SKILL.md:20-23`:
- `"Find the first step with status: 'in_progress' → resume from that step"`
- `"If no 'in_progress' step: find the first 'pending' step after all 'completed' steps → resume from that step"`

There is no existing handling for `awaiting_clarification` step status.

- Evidence:
  - `skills/resume-ticket/SKILL.md:20-23`: resume logic reads first `in_progress` then first `pending`.
  - `skills/resume-ticket/SKILL.md:86-94`: issue_id validation block.
  - `skills/resume-ticket/SKILL.md:10`: argument-hint is `<ISSUE-ID>` only — no `--clarification` flag.
- Recommendation: Add detection of `status: "paused"` (top-level) to Priority 0 handling. When detected: (1) read `clarification.question` from state.json, (2) check `$ARGUMENTS` for `--clarification "text"` flag, (3) if flag provided: write `clarification.answer` to state.json, set `clarification.asked_at_step`'s status back to `in_progress`, set top-level `status` back to `running`, then re-dispatch from that step with the clarification answer injected into context. (4) If flag absent: display the question and prompt user interactively. Resume re-enters at the EXACT phase (`asked_at_step`), not from scratch.

---

**A-D-4.** Which skills dispatch fixer or triage-analyst and must handle NEEDS_CLARIFICATION?

Fixer dispatch sites (confirmed by direct file reading):
1. `skills/fix-ticket/SKILL.md:325` — `Run ceos-agents:fixer (Task tool, model: opus)` (Step 5)
2. `skills/fix-bugs/SKILL.md:393` — `For each bug, run ceos-agents:fixer (Task tool, model: opus)` (Step 4)
3. `skills/implement-feature/SKILL.md` — fixer dispatched in Step 6 (feature subtask execution)
4. `skills/scaffold/SKILL.md:777` — `7a. Fixer (Task tool, model: opus)` confirmed at line 777

Triage-analyst dispatch sites (confirmed by direct file reading):
1. `skills/fix-ticket/SKILL.md:161` — `Run ceos-agents:triage-analyst (Task tool, model: sonnet)` (Step 3)
2. `skills/fix-bugs/SKILL.md:180` — `For each bug, run ceos-agents:triage-analyst` (Step 2)
3. `skills/analyze-bug/SKILL.md:24` — `Run ceos-agents:triage-analyst on bug $ARGUMENTS` (Step 3, line 24)

- Evidence:
  - `skills/analyze-bug/SKILL.md:24`: `"Run ceos-agents:triage-analyst on bug $ARGUMENTS"` — confirmed missed site.
  - `skills/scaffold/SKILL.md:777`: `"7a. Fixer (Task tool, model: opus)"` — confirmed missed site.
- Inference: `analyze-bug` is analysis-only (no code changes, no state.json, no pipeline pause) — NEEDS_CLARIFICATION from triage-analyst here should simply surface the question to the user interactively without a pause/resume cycle; the pipeline is already display-only.
- Recommendation: For `analyze-bug`: if triage-analyst signals NEEDS_CLARIFICATION, display the question to the user directly (no state.json write, no pause). For `scaffold`: fixer NEEDS_CLARIFICATION should use the same state.json pause mechanism as fix-ticket, but within the per-subtask execution context (step 7a).

---

**A-D-5.** Should `pipeline-completed` webhook fire when pipeline pauses for NEEDS_CLARIFICATION?

`core/post-publish-hook.md:85-96` shows `pipeline-completed` fires with `outcome` of `success`, `blocked`, or `failed`. WEBHOOK-R8 at line 147-149: `"Webhook payloads are forward-compatible — additive fields may be added in future MINOR versions. Consumers should use lenient JSON parsing (ignore unknown fields)."` There is NO provision for a `paused` outcome. The CLAUDE.md states `"Webhook delivery failure is advisory... pipeline continues."` and payloads are `"forward-compatible"`.

- Evidence:
  - `core/post-publish-hook.md:85`: `"outcome is one of: success, blocked, failed"`
  - `core/post-publish-hook.md:147-149`: WEBHOOK-R8 lenient-parsing forward compatibility.
  - `skills/fix-ticket/SKILL.md:508`: `"Fire pipeline-completed webhook (WEBHOOK-R4): After terminal state is committed, fire pipeline-completed with outcome: 'success'"`
  - `skills/fix-ticket/SKILL.md:542`: `"fire pipeline-completed with outcome: 'blocked'"`
- Recommendation: Do NOT fire `pipeline-completed` when pausing for NEEDS_CLARIFICATION. The pause is not a terminal state — it is an interruption awaiting human input. Instead, document that `pipeline-completed` fires only on terminal outcomes (`success`, `blocked`, `failed`). Adding `outcome: "clarification_pending"` as a value in `pipeline-completed` would be semantically misleading (the pipeline has not completed). A new `pipeline-paused` event is the correct additive approach if real-time monitoring is needed — but that is a separate MINOR addition for a future version, not a requirement for v6.9.0.

---

### E — pipeline-history.md Feedback Loop

**A-E-1.** Where should pipeline-history.md live, and what is the correct format?

`docs/plans/roadmap.md` proposes `.claude/pipeline-history.md` but all plugin-managed state uses `.ceos-agents/` (per `state/schema.md:9-18` directory layout). The `.claude/` directory in Claude Code projects contains `settings.local.json` (gitignored per project memory) and `settings.json` (project-committed). `.claude/pipeline-history.md` would be a project-level file in a directory already used by Claude Code for tool settings — this creates a namespace conflict risk if Claude Code reserves `.claude/` for its own file management.

- Evidence:
  - `state/schema.md:9-18`: all plugin state lives under `.ceos-agents/{RUN-ID}/`.
  - Project memory: `"Never commit .claude/settings.local.json"` — confirms `.claude/` has mixed-tracked-and-gitignored files.
  - `agents/fixer.md:21`: Step 1 reads input from previous pipeline stage — no existing history read.
  - `agents/reviewer.md:20`: Step 1 reads the input from previous pipeline stages — no existing history read.
- Inference: `.ceos-agents/pipeline-history.md` is more consistent with plugin conventions and avoids polluting the `.claude/` namespace. However, `.claude/pipeline-history.md` is more likely to be gitignored by project `.gitignore` entries like `.claude/` — which is a privacy advantage.
- Recommendation: Use `.ceos-agents/pipeline-history.md` (not `.claude/`) for consistency with all other plugin state. Advise users to add `.ceos-agents/pipeline-history.md` to `.gitignore` if the project is public. Format: markdown with one H2 per run (append-only), easier for Read tool than JSONL (no parse step). Retain last 50 runs maximum.

---

**A-E-2.** What metadata fields should pipeline-history.md store, and what must be excluded for PII/sensitivity?

The `block` object in state.json (`state/schema.md:315`) contains `{agent, step, reason, detail, recommendation}`. The `detail` field "can include source code excerpts" (per Phase 1 question context) and raw error output — this is both sensitive and potentially large.

- Evidence:
  - `state/schema.md:315`: `"block | object or null | ... | {agent, step, reason, detail, recommendation}"`
  - `state/schema.md:219`: `"status — One of: running, completed, blocked, failed"`
  - `state/schema.md:37-50`: top-level `run_id`, `mode`, `pipeline`, `status`, `started_at`, `updated_at`.
  - `state/schema.md:71-85`: `triage.severity`, `triage.area`, `triage.complexity`, `triage.acceptance_criteria`.
- Recommendation: Store ONLY these metadata fields per run entry — NO `block.detail`, NO issue title, NO code excerpts:
  ```markdown
  ## {run_id}
  - date: {started_at}
  - pipeline: {mode}
  - outcome: {status at terminal}
  - agents_touched: {comma-separated list of completed stages}
  - block_agent: {block.agent or null}
  - block_step: {block.step or null}
  - block_reason: {block.reason (max 2 sentences) or null}
  - complexity: {triage.complexity or null}
  - duration_s: {pipeline.total_duration_ms / 1000 or null}
  ```
  Explicitly do NOT store: `block.detail` (source code, stack traces), issue title (PII in some orgs), acceptance criteria text. The fixer reads last 5 entries; reviewer reads last 10 entries.

---

**A-E-3.** At what pipeline step should pipeline-history.md append fire?

`core/post-publish-hook.md` currently has 4 numbered sections ending at Section 4 (pipeline lifecycle events, lines 35-149). The file has no Section 5.

The fix-bugs per-bug loop: each bug fires its own `pipeline-completed` event (per `skills/fix-bugs/SKILL.md:680-685`). A per-bug history entry is more useful than a loop-summary entry because each bug is an independent pipeline run with its own `run_id` and `state.json`.

`core/state-manager.md` atomic write protocol (tmp+rename) supports file writes but is documented for JSON files. Append-only markdown requires a different write pattern (file read + append + write), not the tmp+rename protocol. However, `core/state-manager.md` line 8: the protocol is designed for state.json; for pipeline-history.md a simpler bash append (`echo >> .ceos-agents/pipeline-history.md`) is correct.

- Evidence:
  - `core/post-publish-hook.md:1-34`: Sections 1-3 (hooks + pr-created webhook), Section 4 ends at line 149.
  - `skills/fix-bugs/SKILL.md:687-689`: `"### 8a. Post-publish hook — Follow core/post-publish-hook.md for hook execution and webhook firing."` — post-publish-hook.md is invoked here.
  - `skills/fix-ticket/SKILL.md:510-514`: `"### 9a. Post-publish hook"` and `"### 9b. Webhook — PR created — Follow core/post-publish-hook.md"`.
  - `core/state-manager.md:5-8`: atomic write is tmp+rename for JSON — not applicable to markdown append.
- Recommendation: Add a new **Section 5** to `core/post-publish-hook.md` titled `## Section 5: pipeline-history.md append (v6.9.0+)`. This section fires AFTER Section 4 (pipeline-completed webhook), inheriting advisory failure semantics. Each call appends one H2 run entry to `.ceos-agents/pipeline-history.md` using bash append. For fix-bugs: fire per-bug (each bug has its own run_id and state.json). Append then truncate: after append, count H2 headers; if count > 50, remove the oldest entries (head trim). All failures are advisory (`[WARN]`), never blocking.

---

### F — ARCHITECTURE.md Freshness

**A-F-1.** Does docs/ARCHITECTURE.md exist? What does it show, and is it stale?

The file exists at `docs/architecture.md` (lowercase — Windows filesystem is case-insensitive, so `docs/ARCHITECTURE.md` and `docs/architecture.md` resolve to the same file). It is tracked in git under the lowercase path `docs/architecture.md`.

The Mermaid diagram at `docs/architecture.md:27` shows:
```
SKL[28 Skills]
```
This is already stale as of v6.8.0 (which added the 29th skill `/ceos-agents:autopilot`).

Git history for `docs/architecture.md`:
- Last commit touching the file: `0542505` — `"docs: update architecture diagrams to use skills terminology"` dated 2026-04-14.
- Commits since that commit to HEAD: **25 commits** (confirmed via `git rev-list HEAD ^0542505 --count`).
- The default N threshold recommended in Phase 1 (F) is 25 — the file is exactly at the warning threshold right now.

- Evidence:
  - `docs/architecture.md:27`: `"SKL[28 Skills]"` — stale, current count is 29.
  - `git log --format="%H %ai %s" -- docs/architecture.md | head -1`: `0542505 2026-04-14 19:46:05 docs: update architecture diagrams to use skills terminology`
  - `git rev-list HEAD ^0542505 --count`: `25`
- Inference: The staleness warning feature (if implemented with N=25) would trigger immediately on the current codebase even before v6.9.0 is released. This confirms the feature is useful and needed. The Mermaid "28 Skills" error should be fixed as a doc-drift correction in Phase 9 regardless.
- Recommendation: The staleness check should trigger a soft warning when commits-since-last-edit >= N (default 25). The current file at exactly 25 commits validates the threshold choice.

---

**A-F-2.** What git command detects staleness, what N threshold, and where to insert the check?

Correct git command (agent-3 proposal is correct):
```bash
last_commit=$(git log -1 --format="%H" -- docs/ARCHITECTURE.md 2>/dev/null)
if [ -n "$last_commit" ]; then
  commits_since=$(git rev-list HEAD ^${last_commit} --count 2>/dev/null)
  if [ "${commits_since}" -ge 25 ]; then
    echo "[WARN] docs/ARCHITECTURE.md has not been updated in ${commits_since} commits."
  fi
fi
```
Note: case-insensitive on Windows; use `docs/ARCHITECTURE.md` or `docs/architecture.md` consistently — choose lowercase `docs/architecture.md` to match the tracked git path.

`git rev-list HEAD ^${last_commit} --count` counts commits reachable from HEAD but NOT from the last-edit commit — this is "commits since last file edit" which is the correct semantic. Alternative `git log --oneline docs/ARCHITECTURE.md | wc -l` counts total commits TO the file (different meaning — resets when file is touched, does not reflect how stale it is relative to recent changes). The `rev-list` approach is more accurate.

**Insertion points:**

`skills/fix-ticket/SKILL.md`: The check should be inserted after Step 0b (Config Validity Gate, line ~130) and before Step 1 (Set issue tracker, line 139). This places the advisory warning after configuration is validated but before any pipeline work begins. It is NOT Step 1 itself — it precedes the tracker state-set call.

`skills/implement-feature/SKILL.md`: The check should be inserted after Step 0b (Config Validity Gate, lines 124-145) and before Step 0c (Feature from Description, lines 147-185), or between Step 0c and Step 1 if description mode is active. The cleanest position is immediately after Step 0b validation passes.

- Evidence:
  - `skills/fix-ticket/SKILL.md:112-132`: Step 0b ends at line 131. Step 1 begins at line 139.
  - `skills/implement-feature/SKILL.md:124-145`: Step 0b. Step 0c starts at line 147.
  - `git rev-list HEAD ^0542505 --count`: 25 — confirms N=25 as the right default (already triggered).
- Recommendation: Default N = 25. The warning is purely advisory — `echo "[WARN] docs/ARCHITECTURE.md has not been updated in ${commits_since} commits (threshold: ${N}). Consider reviewing it for accuracy before this pipeline run."` — pipeline continues unconditionally. No optional config key needed; the threshold can be hardcoded at N=25.

**Pipeline-completed webhook integration:** Do NOT add the staleness warning to `pipeline-completed` payload. Webhook payloads must be actionable signals tied to pipeline outcomes. An architecture doc staleness warning is a developer experience hint at pipeline start, not a pipeline outcome signal. Adding it to the payload adds noise for all webhook consumers. Defer to a future `/ceos-agents:check-setup` diagnostic if needed.

---

DONE
