# Step 12 — Terminal Result + Dispatch-Audit Surfacing

Compute pipeline accumulator, emit the per-issue summary table, surface dispatch-audit anomalies
(REQ-D-1..D-5), and fire the terminal `pipeline-completed` webhook.

This step is NOT a Task() dispatch — it is the orchestrator's terminal infrastructure.

## Step 12.1: Pipeline accumulator

Before writing terminal `status = "completed"` (or `"blocked"`/`"failed"`), compute and write to
`.ceos-agents/{ISSUE-ID}/state.json` atomically per `../../../core/state-manager.md` "Pipeline Accumulator Write":

- `pipeline.total_tokens`     = sum of `{stage}.tokens_used` for all completed stages
- `pipeline.total_duration_ms` = sum of `{stage}.duration_ms` for all completed stages
- `pipeline.total_tool_uses`  = sum of `{stage}.tool_uses` for all completed stages
- `pipeline.summary_table`    = markdown table with one row per completed stage
  (columns: `| Stage | Model | Tokens | Duration | Tools |` plus `Total` footer row).
  Apply COST-R10 truncation: if rows > 20 OR total string length > 4000 chars, truncate row-wise
  (never mid-row) and append `| ... | (truncated, N more stages in pipeline.log) | ... |` immediately
  before the `Total` row.

Set top-level `status` to `"completed"` (success path), `"blocked"` (block path), or `"failed"`
(catastrophic fall-through — see Step Z below). Follow atomic write protocol.

## Step 12.2: Emit summary table to stdout

After state.json commit, echo `pipeline.summary_table` to stdout so the user sees the per-stage
cost breakdown inline.

## Step 12.3: Dispatch-Audit Surfacing (WITNESS_MISSING terminal block — REQ-D-1..D-5)

Read `.ceos-agents/dispatch-audit.log` (top-level path per QB1 resolution, NOT under
`{ISSUE-ID}/`). For this run's stages, classify each entry against the per-skill
`<stage_allowlist>` parsed from this skill's parent SKILL.md (`skills/fix-bugs/SKILL.md`).

The per-skill `stage_allowlist` for fix-bugs is:
- **required:** `triage`, `code_analysis`, `fixer_reviewer`, `smoke_check`, `test`, `publisher`
- **optional:** `reproduce_browser`, `e2e_test`, `browser_verification`, `acceptance_gate`

Parse the allow-list from the parent `skills/fix-bugs/SKILL.md` `<stage_allowlist>` ... `</stage_allowlist>`
block at file-position L11-14 (REQ-D-5). Use awk or grep-block-extract:

```bash
SKILL_DIR="${CLAUDE_SKILL_DIR:-skills/fix-bugs}"
ALLOWLIST_BLOCK=$(awk '/<stage_allowlist>/{f=1;next} /<\/stage_allowlist>/{exit} f' "${SKILL_DIR}/SKILL.md")
# Parse required + optional stages from the YAML-like body of the block.
```

**Parser hardening (REQ-REL-4.2 — prose-discipline contract):** After executing the awk extraction
above, validate that `ALLOWLIST_BLOCK` contains at least one `required:` line. If the extracted
block is empty, contains no `required:` line, or contains no `optional:` line (i.e., the
`<stage_allowlist>` block was malformed or missing its closing tag), emit the following WARN line
to stderr and proceed with **allow-all-stages semantics** (no filter applied — treat all audit
entries as potentially relevant):

```
[WARN] malformed <stage_allowlist> block in <SKILL_PATH>; falling back to allow-all-stages
```

where `<SKILL_PATH>` is the resolved path to the SKILL.md file (e.g., `skills/fix-bugs/SKILL.md`).

> Note: This is a **prose-discipline contract** — it is an instruction to the orchestrator/subagent
> dispatching this step, not a runtime-enforced shell-level contract. The awk command is preserved;
> the validation and fallback behaviour are performed immediately after the awk result is available.

For each WITNESS_MISSING entry in `.ceos-agents/dispatch-audit.log` for this run:

| Stage in allow-list | Classification | Terminal-block treatment |
|---------------------|----------------|--------------------------|
| In `required` list  | **ANOMALY** — orchestrator silently skipped a required step | Render as the anomaly block (default-on, no env-var gate). User-visible warning. |
| In `optional` list AND stage's config-gating evaluated to "off" | EXPECTED_OPTIONAL_NOT_RUN | Render as info block (low-noise — explains why the stage didn't run). |
| In `optional` list AND stage's config-gating evaluated to "on" | **ANOMALY** | Render as anomaly block. |
| NOT in allow-list (hook STAGES superset entries — e.g., implement-feature-only stages bleeding in) | SUPPRESSED | Do NOT render. Not part of this pipeline's expected dispatch set. |

For WITNESS_MISMATCH entries: always render as ANOMALY (witness present but malformed → likely
state.json corruption or orchestrator bug).

For WITNESS_OK entries: never render (no action needed).

If `.ceos-agents/dispatch-audit.log` does not exist: render a small info note "(no dispatch-audit
records — first invocation, or hook is disabled)" and continue. NEVER fail the terminal report on
missing audit log.

### Anomaly block render template

```
+============================================================+
| DISPATCH-AUDIT ANOMALY (run_id: {run_id})                  |
| Issue: {issue_id}                                          |
| Pipeline: fix-bugs                                         |
+============================================================+
| Stage              | Verdict          | Allow-list status   |
|--------------------|------------------|---------------------|
| {stage_name_1}     | WITNESS_MISSING  | required (ANOMALY) |
| {stage_name_2}     | WITNESS_MISMATCH | optional (ANOMALY) |
+------------------------------------------------------------+
| For investigation: cat .ceos-agents/dispatch-audit.log     |
| Recommended: re-run /ceos-agents:fix-bugs {issue_id}       |
|              with --step-mode to verify each dispatch.     |
+============================================================+
```

## Step 12.4: pipeline-completed webhook

After all state writes and terminal output, fire `pipeline-completed` if Notifications → Webhook URL
exists and `pipeline-completed` is in On events:
<!-- @snippet:webhook-curl -->
```bash
curl --proto "=http,https" --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  --data-binary @- "{Webhook URL}" <<EOF
{"event":"pipeline-completed","run_id":"${run_id}","issue_id":"${issue_id}","status":"completed","outcome":"success","duration":${total_duration_seconds},"pr_url":"${pr_url}","timestamp":"${ISO8601}"}
EOF
```
On block: fire with `"outcome":"blocked"` and `"pr_url":null` after terminal block state is committed.
On catastrophic fall-through (Step Z): fire with `"outcome":"failed"` and `"pr_url":null`.
Webhook failure → log `[WARN] Webhook delivery failed: {error}`, continue.

<!-- @snippet:pipeline-completion -->
### Step Z: Catastrophic exit handler (outcome: failed, per-bug)

If the per-bug pipeline reaches the end of all expected steps and the per-issue `state.json`
`status` field is still `"running"` (no terminal `completed`/`blocked`/`paused` transition
committed), the skill MUST attempt to fire `pipeline-completed` with `outcome: "failed"` and
`pr_url: null`, and write `{"status":"failed","outcome":"failed"}` atomically to state.json.

**Limitation:** `outcome: "failed"` covers logical fall-through only — does NOT fire on process
death (OOM, SIGKILL, API timeout). Those leave state.json in `running` indefinitely until external
intervention. A future heartbeat / watchdog would be required for true crash detection.
