# Research Questions — Agent 1
## Work Items 1 & 2: Tracker Subtask Extraction + Webhook Format Alignment

---

## Work Item 1: Tracker Subtask Extraction

### Q1. Are the three pseudocode blocks byte-for-byte identical or do they have subtle divergences?

Files to examine:
- `skills/fix-ticket/SKILL.md` — section `### 4b-tracker. Create tracker subtasks` (lines 207–388)
- `skills/fix-bugs/SKILL.md` — section `### 3b-tracker. Create tracker subtasks` (lines 224–406)
- `skills/implement-feature/SKILL.md` — section `### 5a. Create tracker subtasks` (lines 266–448)

Specific check: Compare the `build_description(subtask)` comment block, the GitHub/Gitea checklist sentinel format, the `git commit -m` message string, and the three DISPLAY strings at the end. Are they identical across all three files, or do any of them diverge in wording, casing, or punctuation?

Also check: `fix-bugs/SKILL.md` step `3b-tracker` does NOT contain the sentence "Follow `core/mcp-body-formatting.md` when constructing multi-line MCP tool parameters." — does `fix-ticket/SKILL.md` step `4b-tracker` include it (line 388)? Does `implement-feature/SKILL.md` step `5a` include it (line 448)? Is this line absent from `fix-bugs`?

### Q2. How does the triple gate vary in how it checks `tracker_effective_status`?

Files to examine:
- `skills/fix-ticket/SKILL.md` lines 209–213 (triple gate preamble)
- `skills/fix-bugs/SKILL.md` lines 226–230 (triple gate preamble)
- `skills/implement-feature/SKILL.md` lines 268–272 (triple gate preamble)

Specific check: All three gates refer to `tracker_effective_status != "ready"` as gate condition #3. Where is `tracker_effective_status` defined or computed? Search `core/mcp-preflight.md` and `core/config-reader.md` for the term. Is it produced by `core/mcp-preflight.md` as an output variable, or is it an implicit convention not defined in any contract?

Files to also examine: `core/mcp-preflight.md`, `core/config-reader.md`.

### Q3. Does `fix-bugs` step `3b-tracker` have a YOLO-mode difference in AC coverage handling compared to `fix-ticket` step `4b`?

Files to examine:
- `skills/fix-ticket/SKILL.md` lines 193–203 (AC coverage check) — note the `--yolo` auto-approve behavior
- `skills/fix-bugs/SKILL.md` lines 213–222 (AC coverage check) — note it says "If mode is YOLO" instead of "If `--yolo`"
- `skills/implement-feature/SKILL.md` lines 228–236 (AC coverage check)

Specific check: `fix-ticket` step `4b` says "If `--yolo` → Block ('Incomplete decomposition — unmapped AC detected')" at line 201, while `fix-bugs` step `3b` says "If mode is YOLO → Block (...)". Is the YOLO terminology consistent? Does `fix-bugs` actually support `--yolo` as a flag? (Search `fix-bugs/SKILL.md` for `--yolo` to confirm presence or absence of that flag.)

### Q4. What input parameters are unique to each skill's copy that the new contract must accept as inputs?

Files to examine:
- `skills/fix-ticket/SKILL.md` lines 214–220 (Required in-memory values list)
- `skills/fix-bugs/SKILL.md` lines 231–237 (Required in-memory values list)
- `skills/implement-feature/SKILL.md` lines 273–279 (Required in-memory values list)

Specific check: All three list the same five items (`ISSUE_ID`, `tracker_type`, Decomposition YAML path, State.json path, Subtask list). Do any differ? Additionally, does `fix-bugs` add any worktree-specific context (e.g., a worktree path variable) that `fix-ticket` and `implement-feature` do not, given that `fix-bugs` supports parallel worktree execution?

### Q5. How do existing core contracts handle delegation — what is the input/output contract pattern?

Files to examine:
- `core/block-handler.md` — full file (Input Contract table, Process section, Output Contract, Failure Handling)
- `core/post-publish-hook.md` — full file (Input Contract, Process, Output Contract, Failure Handling)
- `core/fix-verification.md` — full file
- `core/fixer-reviewer-loop.md` — full file

Specific check: Do the existing core contracts define formal `## Input Contract` and `## Output Contract` sections with tables? What fields do they declare? Does the process section use pseudocode similar to the tracker subtask block, or is it written in prose? What does the "Output Contract" look like for a contract that produces structured data (e.g., `tracker_issue_id` values written to YAML and state.json)?

### Q6. Should the new `core/tracker-subtask-creator.md` own the triple gate logic, or should the gate remain in the calling skill?

Files to examine:
- `core/block-handler.md` lines 1–10 (Purpose + Input Contract) — note it receives pre-evaluated context
- `core/post-publish-hook.md` lines 1–15 (Purpose + Input Contract) — note it receives `pr_url`, `issue_id` already resolved
- `core/fix-verification.md` — check whether it reads config itself or receives config as input
- `core/mcp-preflight.md` — check whether it performs its own checks or delegates to the caller

Specific check: Do core contracts perform their own config reads (e.g., checking `Create tracker subtasks == "disabled"` internally), or do they rely on the calling skill to resolve all gates before delegating? This determines whether `core/tracker-subtask-creator.md` should embed the triple gate or document it as a pre-condition.

### Q7. Does the Jira nested sub-task guard (pre-creation `get_issue` call) appear identically in all three copies?

Files to examine:
- `skills/fix-ticket/SKILL.md` lines 269–283 (Jira branch in pseudocode)
- `skills/fix-bugs/SKILL.md` lines 286–300 (Jira branch in pseudocode)
- `skills/implement-feature/SKILL.md` lines 328–342 (Jira branch in pseudocode)

Specific check: Is the guard comment "// Jira nested sub-task guard" present in all three? Does the LOG WARN message text match exactly? Is the flat-issue fallback (omitting parent param) identically described in all three, or does any copy omit the `issuetype: "Sub-task"` from the flat case differently?

---

## Work Item 2: Webhook Format Alignment

### Q8. What is the complete inventory of webhook curl calls across all skills and core contracts, and what exact JSON payload keys does each use?

Files to examine (all webhook curl invocations found in the codebase):

| File | Section | Event | Keys used |
|------|---------|-------|-----------|
| `skills/implement-feature/SKILL.md` | Step 10a (line 622) | `pr-created` | `event`, `issue`, `pr` |
| `skills/implement-feature/SKILL.md` | Step X block handler (line 663) | `issue-blocked` | `event`, `issue`, `agent`, `reason` |
| `skills/fix-bugs/SKILL.md` | Step 8b (lines 612–617) | `pr-created` | `event`, `issue_id`, `pr_url`, `timestamp` |
| `skills/fix-bugs/SKILL.md` | Step 9a (lines 660–664) | `pipeline-complete` | `event`, `status`, `fixed`, `blocked`, `timestamp` |
| `skills/fix-bugs/SKILL.md` | Step X block handler (lines 697–701) | `issue-blocked` | `event`, `issue_id`, `agent`, `reason`, `timestamp` |
| `skills/publish/SKILL.md` | Step 8 (lines 29–34) | `pr-created` | `event`, `issue_id`, `pr_url`, `timestamp` |
| `core/block-handler.md` | Step 5 (lines 39–44) | `issue-blocked` | `event`, `issue_id`, `agent_name`, `reason`, `timestamp` |
| `core/post-publish-hook.md` | Step 3 (lines 16–22) | `pr-created` | `event`, `issue_id`, `pr_url`, `timestamp` |

Specific check: Confirm the exact key names in `implement-feature` step 10a — does it use `"issue"` (not `"issue_id"`) and `"pr"` (not `"pr_url"`)? Confirm the exact key names in `implement-feature` step X block handler — does it use `"issue"` (not `"issue_id"`)? Compare these to the canonical format in `core/block-handler.md` (which uses `"issue_id"`) and `core/post-publish-hook.md` (which uses `"issue_id"` and `"pr_url"`).

### Q9. Do any skills that inline their own webhook calls also reference core contracts — and if so, is there a contract split risk?

Files to examine:
- `skills/fix-bugs/SKILL.md` step 8a and 8b (lines 602–618) — `fix-bugs` has an inline `pr-created` webhook at step 8b AND also says "Follow `core/post-publish-hook.md`" at step 8a (line 604). Are these the same event or two separate firings?
- `skills/fix-bugs/SKILL.md` step X block handler (lines 669–710) — has an inline `issue-blocked` webhook AND says "Follow `core/block-handler.md`" (line 669). Are these duplicate/redundant, or is the inline block the actual implementation that overrides the core contract?
- `skills/fix-ticket/SKILL.md` steps 9a and 9b (lines 585–590) — delegates to `core/post-publish-hook.md` only (no inline webhook). Confirm there is no inline curl in `fix-ticket`.

Specific check: Is `fix-bugs` step 8b an ADDITIONAL inline webhook call executed AFTER the core contract fires, or is it a REPLACEMENT? The answer determines whether aligning `fix-bugs` requires removing the inline call, fixing its keys, or both.

### Q10. Does the `implement-feature` inline `issue-blocked` webhook also omit `timestamp` compared to the canonical format?

Files to examine:
- `skills/implement-feature/SKILL.md` step X block handler, line 663: `curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"issue-blocked","issue":"{issue_id}","agent":"{agent}","reason":"{reason}"}'`
- `core/block-handler.md` step 5, lines 40–44: canonical format with `--max-time 5 --retry 0` flags and `"timestamp":"{ISO8601}"` field
- `skills/fix-bugs/SKILL.md` step X block handler, lines 698–701: inline format with `--max-time 5 --retry 0` and `"timestamp":"{ISO8601}"`

Specific check: Confirm whether `implement-feature` step X omits: (a) the `--max-time 5 --retry 0` curl flags, (b) the `"timestamp"` field, (c) uses `"issue"` instead of `"issue_id"`, (d) uses `"agent"` instead of `"agent_name"` (which `core/block-handler.md` uses in its Output Contract). List every deviation.

### Q11. Are there any downstream consumers (scripts, tests, CI workflows) that parse webhook payloads by key name and would break if `"issue"` is renamed to `"issue_id"`?

Files to examine:
- `tests/` directory — all `.sh` files for any assertions on webhook payload keys
- `.github/` or `.gitea/` CI workflow files — for any webhook endpoint mocks or payload validators
- `docs/reference/` — for any documented webhook payload format that external consumers may rely on
- `examples/` — for any example webhook handler code or payload samples

Specific check: Run a search for the string `"issue"` (with quotes, as a JSON key) and `issue_id` in `tests/` and `docs/` to find any test assertions or documented consumer contracts. If found, the rename from `"issue"` to `"issue_id"` is a breaking change for those consumers.
