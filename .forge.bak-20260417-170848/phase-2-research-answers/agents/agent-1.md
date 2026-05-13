# Research Answers — Agent 1
## Work Items: WI1 (Tracker Subtask Extraction) + WI2 (Webhook Format Alignment)

---

## WI1: Tracker Subtask Extraction

### Q1.1: Are the 3 pseudocode blocks identical?

**Short answer: The pseudocode bodies are structurally identical. There are zero functional differences between the three copies. The only difference is that `fix-bugs/3b-tracker` is missing the trailing reference `Follow \`core/mcp-body-formatting.md\`...` sentence that appears in the other two.**

Detailed line-by-line comparison of the `**Process:**` pseudocode block:

| Element | fix-ticket (4b-tracker, L223–360) | fix-bugs (3b-tracker, L240–377) | implement-feature (5a, L282–419) |
|---------|----------------------------------|--------------------------------|----------------------------------|
| Opening READ config line | identical | identical | identical |
| IF disabled skip | identical | identical | identical |
| IF tracker_effective_status skip | identical | identical | identical |
| success_count / failure_count / created_issues init | identical | identical | identical |
| FOR EACH subtask loop header | identical | identical | identical |
| Idempotency check (YAML-first) | identical | identical | identical |
| State.json fallback | identical | identical | identical |
| Build issue content block | identical | identical | identical |
| YouTrack MCP call | identical | identical | identical |
| Jira guard + MCP calls | identical | identical | identical |
| Linear MCP call | identical | identical | identical |
| Redmine MCP call | identical | identical | identical |
| GitHub/Gitea MCP call | identical | identical | identical |
| Dual store write block | identical | identical | identical |
| CATCH block | identical | identical | identical |
| GitHub/Gitea post-loop checklist | identical | identical | identical |
| Commit YAML section | identical | identical | identical |
| Result display messages | identical | identical | identical |
| Trailing pipeline-continues note | identical | identical | identical |

**Per-tracker parameter tables** (after the code block):

All three files have identical 6-row tables (YouTrack, Jira, Linear, Redmine, GitHub, Gitea) with identical content.

**Issue Description Template** (markdown block): identical in all three.

**Trailing prose differences:**

- `fix-ticket` L388: `- Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.`
- `fix-bugs` L406: `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.` (same content, slightly different markdown list syntax — no leading `-`)
- `implement-feature` L448: `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.` (same as fix-bugs)

This is a cosmetic difference (list item vs plain paragraph). Functionally all three are identical.

**Triple gate header** (before the pseudocode):

All three use exactly the same wording:
```
**Triple gate** -- skip this step entirely (no WARN, expected behavior) if ANY of:
1. `decomposition.decision != "DECOMPOSE"` (task was not decomposed)
2. `Create tracker subtasks` config value == `disabled`
3. `tracker_effective_status != "ready"` (MCP tracker not available)
```

**Required in-memory values block**: identical across all three.

**Conclusion: The pseudocode is copy-paste identical. Extraction into a single core contract is safe — there is no divergence to reconcile.**

---

### Q1.2: How does the triple gate check `tracker_effective_status`? Where is it defined?

**`tracker_effective_status` is NOT defined in any of the three skill files or in the core contracts read for this research.** It is referenced but never explained in the pseudocode itself — the condition `tracker_effective_status != "ready"` appears in:

- `fix-ticket` step 4b-tracker, L212: `3. \`tracker_effective_status != "ready"\` (MCP tracker not available)`
- `fix-bugs` step 3b-tracker, L229: same text
- `implement-feature` step 5a, L271: same text

The pseudocode block then uses it as:
```
IF tracker_effective_status != "ready" -> skip step
```
(fix-ticket L226, fix-bugs L243, implement-feature L285 — all identical)

**Where is it set?** Based on cross-reading the pipeline context:

- `core/mcp-preflight.md` outputs `mcp_available: true/false` but does NOT define `tracker_effective_status` as a named variable.
- The mcp-preflight process does not write a `tracker_effective_status` field to state.json (state.json schema was not explicitly read for this task, but nothing in the skill files assigns this variable).

**Gap identified:** `tracker_effective_status` is an implicit in-memory variable that is implicitly set by the MCP pre-flight step (step 0). It is assumed to be `"ready"` when `mcp_available == true`, but this assignment is never explicitly stated in any file read. The variable name does not appear in `core/mcp-preflight.md`.

**Implication for new core contract:** The new core contract must explicitly document that `tracker_effective_status` is set during/after the MCP pre-flight check (step 0), with value `"ready"` when MCP is available and `"unavailable"` otherwise. The contract must own the definition of this variable.

---

### Q1.3: YOLO-mode difference between fix-ticket and fix-bugs

**fix-ticket** (step 4b, L201):
```
- If `--yolo` → auto-approve. Otherwise display plan and wait for confirmation.
```
And in AC coverage check (L202-203):
```
- If `--yolo` → Block ("Incomplete decomposition — unmapped AC detected")
- Otherwise → ask user: "Continue anyway? The unmapped criteria will not be explicitly addressed. [Y/n]"
```

**fix-bugs** (step 3b, L221-222):
```
- If mode is YOLO → Block ("Incomplete decomposition — unmapped AC detected")
- Otherwise → ask user: "Continue anyway? The unmapped criteria will not be explicitly addressed. [Y/n]"
```

**Key difference:**

- `fix-ticket` uses `--yolo` (CLI flag syntax) as the condition.
- `fix-bugs` uses `mode is YOLO` (prose/variable style) as the condition.

Additionally, `fix-ticket` has an explicit `**If \`--yolo\` → auto-approve.**` clause for the decomposition plan display, which is absent from `fix-bugs`. The fix-bugs step 3b has `**Display plan and wait for confirmation.**` without any YOLO auto-approve branch.

**Summary of behavioral differences:**

| Behavior | fix-ticket | fix-bugs |
|----------|-----------|---------|
| Decomposition plan approval | `--yolo` → auto-approve | Always waits for confirmation (no YOLO branch) |
| Unmapped AC → YOLO path | `--yolo` → Block | `mode is YOLO` → Block |
| Unmapped AC → non-YOLO path | ask user | ask user |

Note: `fix-bugs` does NOT support `--yolo` flag at all (not in its argument-hint: `"<N> [--dry-run] [--profile <name>]"` on L6). So the fix-bugs YOLO reference in the AC coverage check is inconsistent — it references a mode that does not exist for that skill. This is a latent bug.

---

### Q1.4: Input parameters unique to each skill's copy

The step header names (`4b-tracker` vs `3b-tracker` vs `5a`) are different, but the **Required in-memory values** block is identical in all three.

However, the **upstream context** that populates those values differs:

| Value | fix-ticket source | fix-bugs source | implement-feature source |
|-------|-------------------|-----------------|--------------------------|
| `ISSUE_ID` | From `$ARGUMENTS` (single issue) | Per-bug in batch loop | From `$ARGUMENTS` or `--description` mode |
| `tracker_type` | Automation Config → Issue Tracker → Type | same | same |
| YAML path | `.claude/decomposition/{ISSUE-ID}.yaml` | same (per-bug) | same |
| `state.json` path | `.ceos-agents/{ISSUE-ID}/state.json` | same (per-bug) | same |
| Subtask list | From step 4b (bug decomposition) | From step 3b (per-bug) | From step 5 (feature decomposition via architect) |

**No unique parameters exist in any single copy.** All three use the same 5 required in-memory values.

**Context difference:** In `fix-bugs`, this step runs inside a per-bug processing loop, so `ISSUE_ID` is the current bug's ID in a batch — not a single fixed value. In `fix-ticket` and `implement-feature`, it is always one specific issue.

---

### Q1.5: How do existing core contracts handle delegation (input/output contract pattern)?

Observed from `core/block-handler.md`:

**Input Contract** table:
```
| Field | Type | Notes |
|-------|------|-------|
| agent_name | string | Name of the blocking agent |
| step_name  | string | Pipeline step label |
| reason     | string | Max 2 sentences |
| detail     | string | Technical output |
| recommendation | string | What the human should do next |
| issue_id   | string | Issue tracker ID |
| config     | object | Automation Config values: Error Handling, State transitions, Notifications |
```

**Output Contract**:
```
Block is recorded. Comment posted to issue tracker. Issue state set to Blocked. Webhook fired if configured.
```

**Process**: numbered steps, each doing exactly one thing.

**Failure Handling**: named scenarios, each mapped to a specific response (log warning + continue).

Observed from `core/post-publish-hook.md`:
- Input Contract: named fields (config, pr_url, issue_id, branch)
- Process: numbered steps
- Output Contract: per-hook result string + overall advisory note
- Failure Handling: per-scenario named responses

Observed from `core/mcp-preflight.md`:
- Input Contract: single field (tracker_type)
- Process: 4 numbered steps, delegates to `core/mcp-detection.md`
- Output Contract: single boolean `mcp_available`
- Failure Handling: two named error scenarios with exact block comment templates

**Pattern conclusion:** All existing core contracts share:
1. `## Purpose` — one sentence
2. `## Input Contract` — table with Field/Type/Notes columns
3. `## Process` — numbered steps
4. `## Output Contract` — what callers get back
5. `## Failure Handling` — per-scenario named responses

The new tracker-subtask extraction contract must follow this exact structure.

---

### Q1.6: Should the new contract own the triple gate or leave it to callers?

**Recommendation: The new contract should own the triple gate.**

Rationale:

1. The triple gate is part of the procedure, not the caller's responsibility. The three callers all have identical gate text — it is repetitive boilerplate that belongs in the contract.
2. `core/block-handler.md` owns its own entry condition (`if blocking agent is fixer/reviewer/test-engineer...`). The pattern is for core contracts to own their own guard conditions.
3. Leaving the gate to callers means all three callers must independently remain in sync. If a new gate condition is added (e.g., a 4th gate for dry-run mode), it must be added in 3 places — the same DRY problem that motivated extraction.
4. The only risk: `tracker_effective_status` must be defined (see Q1.2 gap). The contract should accept `tracker_effective_status` as an Input Contract field (type: string, values: `"ready"` | `"unavailable"`), and callers are responsible for setting it from the MCP pre-flight output.

**New contract Input Contract** should include:
- `tracker_effective_status` (string): `"ready"` | `"unavailable"` — from MCP pre-flight
- `decomposition_decision` (string): `"DECOMPOSE"` | `"SINGLE_PASS"` — from decomposition step
- `create_tracker_subtasks_config` (string): `"enabled"` | `"disabled"` — from Decomposition config section
- `issue_id` (string): parent issue ID
- `tracker_type` (string): from Automation Config
- `subtask_list` (list): from decomposition step (in-memory)
- `state_json_path` (string): `.ceos-agents/{issue_id}/state.json`
- `yaml_path` (string): `.claude/decomposition/{issue_id}.yaml`
- `tracker_project` (string): from Automation Config

---

### Q1.7: Is the Jira nested sub-task guard identical across all 3?

**Yes, completely identical.**

All three files contain the exact same guard block (fix-ticket L271-283, fix-bugs L288-304, implement-feature L329-344):

```
ELSE IF tracker_type == "jira":
    // Jira nested sub-task guard
    parent_issue = MCP get_issue({ISSUE_ID})
    IF parent_issue.issuetype == "Sub-task":
        LOG WARN "Parent issue {ISSUE_ID} is a Sub-task -- creating flat issue without parent link."
        result = MCP create_issue(
            project: {tracker_project},
            summary: issue_title,
            description: issue_description
        )
    ELSE:
        result = MCP create_issue(
            project: {tracker_project},
            summary: issue_title,
            description: issue_description,
            parent: {ISSUE_ID},
            issuetype: "Sub-task"
        )
```

The per-tracker table note for Jira is also identical in all three:
```
Guard: if parent is Sub-task, omit parent param and create flat issue without parent link
```

---

## WI2: Webhook Format Alignment

### Q2.1: Complete inventory of ALL webhook curl calls with exact keys, flags, format

#### Source: `core/block-handler.md` (L39–44) — issue-blocked webhook

```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"issue-blocked","issue_id":"{issue_id}","agent":"{agent_name}","reason":"{reason}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```

Flags: `--max-time 5 --retry 0 -X POST -H "Content-Type: application/json" -d '...'`
Keys: `event`, `issue_id`, `agent`, `reason`, `timestamp`
URL quoting: double-quoted
Body quoting: single-quoted inline `-d '...'`

---

#### Source: `core/post-publish-hook.md` (L18–23) — pr-created webhook

```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  --data-binary @- "{Webhook URL}" <<EOF
{"event":"pr-created","issue_id":"${issue_id}","pr_url":"${pr_url}","timestamp":"${ISO8601}"}
EOF
```

Flags: `--max-time 5 --retry 0 -X POST -H "Content-Type: application/json" --data-binary @-`
Keys: `event`, `issue_id`, `pr_url`, `timestamp`
URL quoting: double-quoted
Body: heredoc via `--data-binary @-`
Variable syntax: shell `${var}` (not template `{var}`)

---

#### Source: `skills/fix-bugs/SKILL.md` (L613–618) — inline pr-created webhook (step 8b)

```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"pr-created","issue_id":"{issue}","pr_url":"{url}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```

Flags: `--max-time 5 --retry 0 -X POST -H "Content-Type: application/json" -d '...'`
Keys: `event`, `issue_id`, `pr_url`, `timestamp`
Deviations: key `issue_id` uses placeholder `{issue}` (not `{issue_id}`); `pr_url` uses `{url}` (not `{pr_url}`)
Body quoting: single-quoted inline `-d '...'`

---

#### Source: `skills/fix-bugs/SKILL.md` (L661–665) — pipeline-complete webhook (step 9a)

```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"pipeline-complete","status":"{success|partial}","fixed":{N},"blocked":{M},"timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```

Flags: `--max-time 5 --retry 0 -X POST -H "Content-Type: application/json" -d '...'`
Keys: `event`, `status`, `fixed`, `blocked`, `timestamp`
Note: `fixed` and `blocked` are numeric (no quotes around `{N}` and `{M}`)
Body quoting: single-quoted inline `-d '...'`

---

#### Source: `skills/fix-bugs/SKILL.md` (L697–701) — issue-blocked webhook (block handler inline, step X)

```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"issue-blocked","issue_id":"{issue}","agent":"{agent}","reason":"{reason}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```

Flags: same as block-handler.md
Keys: `event`, `issue_id`, `agent`, `reason`, `timestamp`
Deviation vs core/block-handler.md: placeholder `{issue}` vs `{issue_id}`, placeholder `{agent}` vs `{agent_name}`
Body quoting: single-quoted inline `-d '...'`

---

#### Source: `skills/implement-feature/SKILL.md` (L622–623) — inline pr-created webhook (step 10a)

```bash
curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"pr-created","issue":"{issue_id}","pr":"{pr_url}"}'
```

Flags: `-X POST` only (no `--max-time 5 --retry 0`)
Keys: `event`, `issue` (NOT `issue_id`), `pr` (NOT `pr_url`)
Missing: `timestamp` field entirely
URL quoting: bare `{webhook_url}` — no quotes
Body quoting: single-quoted inline `-d '...'`

---

#### Source: `skills/implement-feature/SKILL.md` (L661–664) — inline issue-blocked webhook (block handler, step X)

```bash
curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"issue-blocked","issue":"{issue_id}","agent":"{agent}","reason":"{reason}"}'
```

Flags: `-X POST` only (no `--max-time 5 --retry 0`)
Keys: `event`, `issue` (NOT `issue_id`), `agent`, `reason`
Missing: `timestamp` field entirely
URL quoting: bare `{webhook_url}` — no quotes

---

### Q2.2: Does fix-bugs have duplicate webhook firing (both core reference AND inline)?

**Yes — for the `pr-created` event.**

- Step 8a (L602–608): `Follow \`core/post-publish-hook.md\` for hook execution and webhook firing.` — then immediately also has inline step 8b (L610–618) which fires pr-created directly.
- Step X block handler (L697–704): inline `issue-blocked` webhook — AND `core/block-handler.md` is referenced at L669: `Follow \`core/block-handler.md\` for the block protocol.`

The block handler reference + inline is the same dual-fire pattern for issue-blocked.

**Duplication map for fix-bugs:**

| Event | Core reference | Inline | Net firings |
|-------|---------------|--------|-------------|
| pr-created | step 8a → core/post-publish-hook.md | step 8b inline | **2 firings** |
| issue-blocked | step X → core/block-handler.md | step X inline (L697) | **2 firings** |
| pipeline-complete | step 9a inline only | — | 1 firing |

For `fix-ticket`:
- Step 9b (L588–589): `Follow \`core/post-publish-hook.md\`...` — only the core reference. No inline. **1 firing.**
- Step X (L606): `Follow \`core/block-handler.md\`...` — only the core reference. No inline. **1 firing.**

For `implement-feature`:
- Step 10a (L617–623): `Follow \`core/post-publish-hook.md\`` + immediate inline override. **2 firings** (core + inline, but inline uses different key names so may override or duplicate).
- Step X (L661–664): inline only, no separate core reference line before it. **1 firing from inline** (step X does say `Follow \`core/block-handler.md\`` at L642, so also 2 firings for issue-blocked).

---

### Q2.3: Exact deviations in implement-feature block handler webhook

Source: `skills/implement-feature/SKILL.md` step X block handler (L661–664):

```bash
curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"issue-blocked","issue":"{issue_id}","agent":"{agent}","reason":"{reason}"}'
```

**Deviations from canonical `core/block-handler.md` (L39–44):**

| Attribute | core/block-handler.md (canonical) | implement-feature inline | Deviation |
|-----------|-----------------------------------|--------------------------|-----------|
| `--max-time 5` | present | absent | MISSING |
| `--retry 0` | present | absent | MISSING |
| `-X POST` | present | present | match |
| `-H "Content-Type: application/json"` | present | present | match |
| Body method | `-d '...'` | `-d '...'` | match |
| `issue_id` key | `"issue_id"` | `"issue"` | RENAMED |
| `agent` key | `"agent"` (value: `{agent_name}`) | `"agent"` (value: `{agent}`) | placeholder inconsistency |
| `reason` key | `"reason"` | `"reason"` | match |
| `timestamp` key | `"timestamp":"{ISO8601}"` | absent | MISSING |
| URL quoting | `"{Webhook URL}"` (double-quoted) | `{webhook_url}` (bare) | DIFFERENT |

**Also deviations in implement-feature step 10a pr-created webhook vs canonical:**

Source: `skills/implement-feature/SKILL.md` (L622–623):

```bash
curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"pr-created","issue":"{issue_id}","pr":"{pr_url}"}'
```

| Attribute | core/post-publish-hook.md (canonical) | implement-feature inline | Deviation |
|-----------|---------------------------------------|--------------------------|-----------|
| `--max-time 5` | present | absent | MISSING |
| `--retry 0` | present | absent | MISSING |
| `issue_id` key | `"issue_id"` | `"issue"` | RENAMED |
| `pr_url` key | `"pr_url"` | `"pr"` | RENAMED |
| `timestamp` key | present | absent | MISSING |
| URL quoting | `"{Webhook URL}"` (double-quoted) | `{webhook_url}` (bare) | DIFFERENT |
| Body method | `--data-binary @-` + heredoc | `-d '...'` inline | DIFFERENT |

---

### Q2.4: Are there any downstream consumers that parse webhook payload keys?

No downstream consumers were found within the repository files read. The webhook is a fire-and-forget notification to an external HTTP endpoint configured by the consuming project. Within the plugin itself:

- No skill or agent reads webhook responses.
- No core contract parses webhook payload keys.
- The keys `event`, `issue_id`, `pr_url`, `agent`, `reason`, `timestamp` are only written in curl `-d` parameters.

**However, consuming projects may have built webhook receivers based on the key names documented in the existing inline blocks.** Since `implement-feature` uses `"issue"` and `"pr"` while `fix-bugs` step 8b uses `"issue_id"` and `"url"`, external consumers that handle both pipeline types would receive inconsistent key names for the same logical fields.

**Risk:** Any downstream webhook consumer written for `implement-feature` events that reads `payload.issue` will break if `fix-ticket`/`fix-bugs` sends `payload.issue_id`. Key normalization is needed.

---

## Complete Deviation Matrix — Webhooks

### Matrix 1: pr-created event

| Source | `--max-time` | `--retry` | issue key | pr_url key | timestamp | URL quoting | Body method |
|--------|-------------|---------|-----------|-----------|-----------|-------------|-------------|
| `core/post-publish-hook.md` (canonical) | `5` | `0` | `issue_id` | `pr_url` | present | `"..."` | `--data-binary @-` heredoc |
| `fix-bugs` step 8a → core | delegates | delegates | delegates | delegates | delegates | delegates | delegates |
| `fix-bugs` step 8b inline | `5` | `0` | `issue_id` | `url` ❌ | present | `"..."` | `-d '...'` |
| `implement-feature` step 10a inline | absent ❌ | absent ❌ | `issue` ❌ | `pr` ❌ | absent ❌ | bare ❌ | `-d '...'` |

### Matrix 2: issue-blocked event

| Source | `--max-time` | `--retry` | issue key | agent key placeholder | timestamp | URL quoting |
|--------|-------------|---------|-----------|----------------------|-----------|-------------|
| `core/block-handler.md` (canonical) | `5` | `0` | `issue_id` | `{agent_name}` | present | `"..."` |
| `fix-bugs` step X → core | delegates | delegates | delegates | delegates | delegates | delegates |
| `fix-bugs` step X inline | `5` | `0` | `issue` ❌ | `{agent}` | present | `"..."` |
| `implement-feature` step X → core | delegates | delegates | delegates | delegates | delegates | delegates |
| `implement-feature` step X inline | absent ❌ | absent ❌ | `issue` ❌ | `{agent}` | absent ❌ | bare ❌ |

### Matrix 3: pipeline-complete event (fix-bugs only)

| Source | `--max-time` | `--retry` | Keys | URL quoting |
|--------|-------------|---------|------|-------------|
| `fix-bugs` step 9a inline | `5` | `0` | `event`, `status`, `fixed`, `blocked`, `timestamp` | `"..."` |

This event has no canonical core contract — it exists only in fix-bugs.

---

## Summary of Findings

**WI1:** The three pseudocode blocks are functionally identical — safe to extract. The only real inconsistency is the YOLO-mode handling in fix-bugs (references "YOLO mode" but fix-bugs has no `--yolo` flag). `tracker_effective_status` is an undocumented implicit variable that the new core contract must formally define.

**WI2:** Significant webhook inconsistencies exist. `implement-feature` inline webhooks are the most divergent: missing `--max-time`/`--retry`, different key names (`issue` vs `issue_id`, `pr` vs `pr_url`), missing `timestamp`, unquoted URL. `fix-bugs` step 8b inline has `url` instead of `pr_url`. The canonical forms in `core/block-handler.md` and `core/post-publish-hook.md` are the correct reference. All inline copies in skills should be removed in favor of delegating to those core contracts.
