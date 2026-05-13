# Research Questions — Final (Merged)

Phase: Phase 1 — Research Questions
Source agents: agent-1 (WI1 + WI2), agent-2 (WI3), agent-3 (WI4)
Total questions: 26 (no overlaps detected across agents)

---

## Work Item 1: Tracker Subtask Extraction (7 questions)

### Q1.1 — Are the three pseudocode blocks byte-for-byte identical or do they have subtle divergences?

**Files to examine:**
- `skills/fix-ticket/SKILL.md` — section `### 4b-tracker. Create tracker subtasks` (lines 207–388)
- `skills/fix-bugs/SKILL.md` — section `### 3b-tracker. Create tracker subtasks` (lines 224–406)
- `skills/implement-feature/SKILL.md` — section `### 5a. Create tracker subtasks` (lines 266–448)

**What is needed:** Compare the `build_description(subtask)` comment block, the GitHub/Gitea checklist sentinel format, the `git commit -m` message string, and the three DISPLAY strings at the end. Identify any divergences in wording, casing, or punctuation. Also check whether `fix-bugs/SKILL.md` step `3b-tracker` omits the sentence "Follow `core/mcp-body-formatting.md` when constructing multi-line MCP tool parameters." that may appear in `fix-ticket/SKILL.md` line 388 and `implement-feature/SKILL.md` line 448.

---

### Q1.2 — How does the triple gate vary in how it checks `tracker_effective_status`?

**Files to examine:**
- `skills/fix-ticket/SKILL.md` lines 209–213 (triple gate preamble)
- `skills/fix-bugs/SKILL.md` lines 226–230 (triple gate preamble)
- `skills/implement-feature/SKILL.md` lines 268–272 (triple gate preamble)
- `core/mcp-preflight.md` (full file)
- `core/config-reader.md` (full file)

**What is needed:** All three gates refer to `tracker_effective_status != "ready"` as gate condition #3. Determine where `tracker_effective_status` is defined or computed — whether it is produced by `core/mcp-preflight.md` as an output variable, or is an implicit convention not defined in any contract.

---

### Q1.3 — Does `fix-bugs` step `3b-tracker` have a YOLO-mode difference in AC coverage handling compared to `fix-ticket` step `4b`?

**Files to examine:**
- `skills/fix-ticket/SKILL.md` lines 193–203 (AC coverage check, `--yolo` auto-approve behavior)
- `skills/fix-bugs/SKILL.md` lines 213–222 (AC coverage check, "If mode is YOLO" wording)
- `skills/implement-feature/SKILL.md` lines 228–236 (AC coverage check)

**What is needed:** `fix-ticket` step `4b` says "If `--yolo` → Block ('Incomplete decomposition — unmapped AC detected')" at line 201, while `fix-bugs` step `3b` says "If mode is YOLO → Block (...)". Confirm whether the YOLO terminology is consistent and whether `fix-bugs` actually supports `--yolo` as a flag (search `fix-bugs/SKILL.md` for `--yolo`).

---

### Q1.4 — What input parameters are unique to each skill's copy that the new contract must accept as inputs?

**Files to examine:**
- `skills/fix-ticket/SKILL.md` lines 214–220 (Required in-memory values list)
- `skills/fix-bugs/SKILL.md` lines 231–237 (Required in-memory values list)
- `skills/implement-feature/SKILL.md` lines 273–279 (Required in-memory values list)

**What is needed:** All three list the same five items (`ISSUE_ID`, `tracker_type`, Decomposition YAML path, State.json path, Subtask list). Confirm whether they differ. Additionally, check whether `fix-bugs` adds any worktree-specific context (e.g., a worktree path variable) that `fix-ticket` and `implement-feature` do not, given that `fix-bugs` supports parallel worktree execution.

---

### Q1.5 — How do existing core contracts handle delegation — what is the input/output contract pattern?

**Files to examine:**
- `core/block-handler.md` (full file — Input Contract table, Process section, Output Contract, Failure Handling)
- `core/post-publish-hook.md` (full file — Input Contract, Process, Output Contract, Failure Handling)
- `core/fix-verification.md` (full file)
- `core/fixer-reviewer-loop.md` (full file)

**What is needed:** Determine whether existing core contracts define formal `## Input Contract` and `## Output Contract` sections with tables, what fields they declare, whether the process section uses pseudocode or prose, and what the Output Contract looks like for a contract that produces structured data (e.g., `tracker_issue_id` values written to YAML and state.json).

---

### Q1.6 — Should the new `core/tracker-subtask-creator.md` own the triple gate logic, or should the gate remain in the calling skill?

**Files to examine:**
- `core/block-handler.md` lines 1–10 (Purpose + Input Contract — receives pre-evaluated context)
- `core/post-publish-hook.md` lines 1–15 (Purpose + Input Contract — receives `pr_url`, `issue_id` already resolved)
- `core/fix-verification.md` (check whether it reads config itself or receives config as input)
- `core/mcp-preflight.md` (check whether it performs its own checks or delegates to the caller)

**What is needed:** Determine whether core contracts perform their own config reads (e.g., checking `Create tracker subtasks == "disabled"` internally), or rely on the calling skill to resolve all gates before delegating. This determines whether `core/tracker-subtask-creator.md` should embed the triple gate or document it as a pre-condition.

---

### Q1.7 — Does the Jira nested sub-task guard (pre-creation `get_issue` call) appear identically in all three copies?

**Files to examine:**
- `skills/fix-ticket/SKILL.md` lines 269–283 (Jira branch in pseudocode)
- `skills/fix-bugs/SKILL.md` lines 286–300 (Jira branch in pseudocode)
- `skills/implement-feature/SKILL.md` lines 328–342 (Jira branch in pseudocode)

**What is needed:** Confirm whether the guard comment "// Jira nested sub-task guard" is present in all three, whether the LOG WARN message text matches exactly, and whether the flat-issue fallback (omitting parent param) is identically described in all three or whether any copy omits the `issuetype: "Sub-task"` from the flat case differently.

---

## Work Item 2: Webhook Format Alignment (4 questions)

### Q2.1 — What is the complete inventory of webhook curl calls across all skills and core contracts, and what exact JSON payload keys does each use?

**Files to examine:**

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

**What is needed:** Confirm the exact key names in `implement-feature` step 10a — does it use `"issue"` (not `"issue_id"`) and `"pr"` (not `"pr_url"`)? Confirm the exact key names in `implement-feature` step X block handler — does it use `"issue"` (not `"issue_id"`)? Compare these to the canonical format in `core/block-handler.md` (which uses `"issue_id"`) and `core/post-publish-hook.md` (which uses `"issue_id"` and `"pr_url"`).

---

### Q2.2 — Do any skills that inline their own webhook calls also reference core contracts — and if so, is there a contract split risk?

**Files to examine:**
- `skills/fix-bugs/SKILL.md` steps 8a and 8b (lines 602–618) — has inline `pr-created` webhook at step 8b AND says "Follow `core/post-publish-hook.md`" at step 8a (line 604)
- `skills/fix-bugs/SKILL.md` step X block handler (lines 669–710) — has inline `issue-blocked` webhook AND says "Follow `core/block-handler.md`" (line 669)
- `skills/fix-ticket/SKILL.md` steps 9a and 9b (lines 585–590) — delegates to `core/post-publish-hook.md` only (confirm no inline curl)

**What is needed:** Determine whether `fix-bugs` step 8b is an ADDITIONAL inline webhook call executed AFTER the core contract fires, or a REPLACEMENT. The answer determines whether aligning `fix-bugs` requires removing the inline call, fixing its keys, or both.

---

### Q2.3 — Does the `implement-feature` inline `issue-blocked` webhook also omit `timestamp` compared to the canonical format?

**Files to examine:**
- `skills/implement-feature/SKILL.md` step X block handler, line 663
- `core/block-handler.md` step 5, lines 40–44 (canonical format with `--max-time 5 --retry 0` flags and `"timestamp":"{ISO8601}"`)
- `skills/fix-bugs/SKILL.md` step X block handler, lines 698–701 (inline format with `--max-time 5 --retry 0` and `"timestamp":"{ISO8601}"`)

**What is needed:** Confirm whether `implement-feature` step X omits: (a) the `--max-time 5 --retry 0` curl flags, (b) the `"timestamp"` field, (c) uses `"issue"` instead of `"issue_id"`, (d) uses `"agent"` instead of `"agent_name"` (which `core/block-handler.md` uses in its Output Contract). List every deviation.

---

### Q2.4 — Are there any downstream consumers (scripts, tests, CI workflows) that parse webhook payloads by key name and would break if `"issue"` is renamed to `"issue_id"`?

**Files to examine:**
- `tests/` directory — all `.sh` files for assertions on webhook payload keys
- `.github/` or `.gitea/` CI workflow files — for webhook endpoint mocks or payload validators
- `docs/reference/` — for any documented webhook payload format that external consumers may rely on
- `examples/` — for any example webhook handler code or payload samples

**What is needed:** Search for the string `"issue"` (with quotes, as a JSON key) and `issue_id` in `tests/` and `docs/` to find test assertions or documented consumer contracts. If found, the rename from `"issue"` to `"issue_id"` is a breaking change for those consumers.

---

## Work Item 3: Block Handler Inline Removal (6 questions)

### Q3.1 — Does the inline block handler in implement-feature (lines 643–666) differ in substance from `core/block-handler.md`?

**Files to examine:**
- `skills/implement-feature/SKILL.md` lines 643–666 (Step X — Block handler section)
- `core/block-handler.md` lines 1–57 (full file)

**What is needed:** The inline copy in implement-feature spells out all 6 steps verbatim. Compare against `core/block-handler.md` to identify divergences in:
- The rollback condition (implement-feature step 1 names `fixer`, `reviewer`, `test-engineer`, `e2e-test-engineer`, `smoke-check` as rollback triggers — core names the same set but does not mention `smoke-check` explicitly).
- Webhook payload shape: implement-feature uses `"issue":"{issue_id}"` and `"agent":"{agent}"` (step 5); core uses `"issue_id":"{issue_id}"` and `"agent_name":"{agent_name}"`.
- Curl flags: implement-feature omits `--max-time 5 --retry 0` that are present in core step 5.

Confirm whether these three discrepancies are real diffs or transcription artifacts, and whether they constitute behavioral differences or only cosmetic ones.

---

### Q3.2 — What skill-specific logic in implement-feature's Step X must remain after the inline body is replaced with a delegation reference?

**Files to examine:**
- `skills/implement-feature/SKILL.md` lines 643–666 (Step X body)
- `skills/implement-feature/SKILL.md` line 666 (state.json update at end of Step X)

**What is needed:** Implement-feature's Step X contains a 6th numbered item that updates `state.json` (set `status: "blocked"`, write `block` object). Core's step 6 (`core/block-handler.md` line 46) defines the same state.json write. Determine whether this is fully covered by the core contract or whether implement-feature needs an explicit state.json reminder after delegation (as `fix-ticket` does at line 609).

---

### Q3.3 — How do `fix-ticket` and `fix-bugs` structure their Step X, and do they inline or purely delegate?

**Files to examine:**
- `skills/fix-ticket/SKILL.md` lines 605–609 (Step X — Block handler)
- `skills/fix-bugs/SKILL.md` lines 667–710 (Step X — Block handler)

**What is needed:** Confirm the three-way divergence:
- `fix-ticket` delegates cleanly (2 lines + state.json update)
- `implement-feature` inlines 6 steps (~24 lines)
- `fix-bugs` inlines 8 steps (~44 lines with fix-bugs-specific additions like block counter and "continue with next bug")

Identify which additions in `fix-bugs` are legitimately skill-specific vs. duplicating core contract content.

---

### Q3.4 — Where exactly is the inline block handler in implement-feature, and what is the precise line range?

**Files to examine:**
- `skills/implement-feature/SKILL.md` lines 642–667

**What is needed:** The inline block handler starts at line 642 (`### X. Block handler`) and ends at line 667 (end of step 6, state.json update). The header at line 642 is followed by `Follow core/block-handler.md:` at line 644, but then continues to spell out all 6 steps verbatim. Confirm that after a clean refactor, lines 644–666 can be collapsed to a single delegation sentence plus a single state.json reminder (if Q3.2 determines one is needed).

---

### Q3.5 — Does implement-feature's inline block handler reference any variables or pipeline state that are specific to implement-feature and not part of `core/block-handler.md`'s input contract?

**Files to examine:**
- `skills/implement-feature/SKILL.md` lines 643–666 (Step X body)
- `core/block-handler.md` lines 7–17 (Input Contract table)

**What is needed:** The core input contract defines six input fields: `agent_name`, `step_name`, `reason`, `detail`, `recommendation`, `issue_id`, `config`. Cross-check whether implement-feature's inline Step X references any pipeline-local variables beyond these (e.g., the `mode` field `"code-feature"` or `pipeline` field `"implement-feature"` that appear in state.json). The inline state.json update at line 666 writes `{agent, step, reason, detail, recommendation}` — confirm whether this matches core's `block` object schema exactly with no extra fields, meaning the delegation can be done with zero field remapping.

---

### Q3.6 — What is the established "delegate to core + add skill-specific state update" pattern, and where is the canonical example?

**Files to examine:**
- `skills/fix-ticket/SKILL.md` lines 605–609 (Step X — the canonical minimal delegation pattern)
- `core/block-handler.md` lines 19–46 (Process steps — what the core covers)

**What is needed:** Fix-ticket's Step X reads:
```
### X. Block handler
Follow `core/block-handler.md` for the block protocol.
Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.
```
Confirm whether the state.json reminder sentence in fix-ticket Step X is redundant (core covers it) or intentional per the "LLM-directed repetition" philosophy documented in fix-bugs line 89 (`<!-- Contributor note: ... -->`). This determines whether implement-feature's refactored Step X should retain the state.json line after removing the 6-step inline body.

---

## Work Item 4: LOW Documentation Fixes (9 questions)

### Q4.1 — fix-verification.md: Should output strings use mode-neutral language instead of "Fix verification"?

**Files to examine:**
- `core/fix-verification.md` lines 22, 26, 30

**What is needed:** "Fix verification" appears in three locations — the failure comment template (line 26: `[ceos-agents] ❌ Fix verification failed.`), the display message (line 30: `Display: "Fix verification failed. Issue re-opened."`), and the success comment (line 22: `[ceos-agents] ✅ Fix verified.`). These strings appear in the issue tracker even when the verify command runs after a feature implementation (not a bug fix). Determine whether "Fix verification failed" / "Fix verified" should be changed to "Verification failed" / "Verified", or whether "Fix verification" is acceptable in machine-parseable output strings.

---

### Q4.2 — fix-verification.md: Do consuming pipelines expose the fix-framing problem in the success/failure comment?

**Files to examine:**
- `skills/fix-ticket/SKILL.md` (dispatches fix-verification.md)
- `skills/fix-bugs/SKILL.md` (dispatches fix-verification.md)
- `skills/implement-feature/SKILL.md` (dispatches fix-verification.md)
- `docs/plans/roadmap.md` (line ~608 — records this fix as a roadmap item)
- `tests/scenarios/verify-fail.sh` (tests verify step existence)

**What is needed:** The success comment `[ceos-agents] ✅ Fix verified.` is posted even when a feature verification completes — where the work was a feature implementation, not a fix. Similarly, `[ceos-agents] ❌ Fix verification failed.` is posted after feature verification failure. Determine whether the contract should use mode-neutral language like `[ceos-agents] ✅ Verified.` / `[ceos-agents] ❌ Verification failed.`, or whether the contract should accept a mode parameter to customize wording per pipeline type.

---

### Q4.3 — state-manager.md: What is the forward reference at line 42 and what does it actually describe?

**Files to examine:**
- `core/state-manager.md` line 42 (forward reference: `(see resume-ticket.md existing logic)`)
- `skills/resume-ticket/SKILL.md` lines 36–58 (Heuristic Detection Fallback section)

**What is needed:** The forward reference defers the fallback heuristic to `resume-ticket.md` rather than defining it inline. The actual heuristic in `resume-ticket/SKILL.md` describes a 6-state checkpoint table (`FRESH`, `POST_TRIAGE`, `POST_ANALYSIS`, `POST_FIX`, `POST_REVIEW`, `PUBLISHED`) and a detection priority ordering. Determine whether `core/state-manager.md` line 42 should replace `(see resume-ticket.md existing logic)` with a compressed inline version of the checkpoint table, or should reference `skills/resume-ticket/SKILL.md` explicitly by full path instead of the ambiguous bare file name.

---

### Q4.4 — state-manager.md: What heuristic detail should be inlined if the forward reference is fixed?

**Files to examine:**
- `core/state-manager.md` (Resume Process section, line 42 and surrounding context)
- `skills/resume-ticket/SKILL.md` lines 36–58 (full Heuristic Detection section)

**What is needed:** The heuristic has two distinct parts: (1) the checkpoint signal table (how to detect resume state from git + tracker signals) and (2) the detection priority ordering (the `if/else` decision tree). The state-manager's Resume Output contract already promises to return `resume_point` and `detection_method: "heuristic_fallback"`. Determine which part of the heuristic needs to be inlined for an implementer to understand what logic produces those values without reading a separate file. Assess whether a condensed sentence plus the 6-point checkpoint enum would be sufficient.

---

### Q4.5 — state/schema.md: What fields currently exist in `e2e_test`, and what is missing?

**Files to examine:**
- `state/schema.md` lines 104–106 (e2e_test in Full Schema Example)
- `state/schema.md` lines 225–226 (e2e_test field definition table)
- `agents/e2e-test-engineer.md` lines 55–72 (E2E Test Report output and retry behavior)
- `state/schema.md` lines 79–84 and 184–188 (reproduction section for comparison)
- `state/schema.md` lines 107–110 and 228–230 (browser_verification section for comparison)

**What is needed:** The `e2e_test` section currently contains only `{"status": "pending"}` with only `e2e_test.status` in the field definition table. Parallel sections (`reproduction`, `browser_verification`) define additional fields: `verdict`, `result_path`, `attempts`. The e2e-test-engineer agent produces an E2E Test Report with existing test count, new test file paths, and auth handling method, and runs up to 3 attempts before blocking. Determine whether `e2e_test` should gain `verdict`, `result_path`, and `attempts` fields. Also assess whether additional agent output fields (e.g., `new_tests_count`, `framework`) should be persisted, or whether the minimal trio is sufficient for resume and metrics.

---

### Q4.6 — state/schema.md: Which `triage.*` and `code_analysis.*` fields are reused across pipeline modes?

**Files to examine:**
- `state/schema.md` lines 171–183 (triage field definitions)
- `skills/implement-feature/SKILL.md` lines 189, 212 (field reuse in feature mode)
- `skills/scaffold/SKILL.md` lines 435, 484 (field reuse in scaffold mode)

**What is needed:** The schema documents `triage.*` and `code_analysis.*` with only bug-fix mode semantics, but the skills explicitly reuse these fields differently across modes:
- `triage.status`: triage-analyst (bug-fix) / spec-analyst (feature) / spec-writer (scaffold)
- `triage.acceptance_criteria`: triage-analyst AC / spec-analyst AC list / AC count
- `code_analysis.status`: code-analyst (bug-fix) / architect output (feature) / scaffolder (scaffold)

Determine whether `triage` and `code_analysis` field definitions should each receive a mode-reuse note, and where it should appear (in the Description column only, or also via a new "Mode Notes" subsection).

---

### Q4.7 — state/schema.md: Where exactly should the mode-reuse note be placed?

**Files to examine:**
- `state/schema.md` lines 171–183 (triage and code_analysis field definitions)
- `state/schema.md` line 178 (`triage.ac_source` field — existing multi-mode precedent)

**What is needed:** The `triage.ac_source` field at line 178 already contains a multi-mode description as a precedent for inline mode documentation within the Description column. Determine whether `triage.status` and `code_analysis.status` descriptions should be expanded inline (e.g., "In bug-fix mode: triage-analyst phase. In feature mode: spec-analyst phase. In scaffold mode: spec-writer phase.") or whether a separate "Field Reuse Across Modes" table section between the triage and code_analysis definitions would be cleaner.

---

### Q4.8 — fixer-reviewer-loop.md: Where does NEEDS_DECOMPOSITION appear and what does it currently reference?

**Files to examine:**
- `core/fixer-reviewer-loop.md` lines 21, 36, 44
- `skills/fix-ticket/SKILL.md` line 452
- `skills/fix-bugs/SKILL.md` line 470
- `skills/implement-feature/SKILL.md` line 482

**What is needed:** Line 44 of `core/fixer-reviewer-loop.md` references only `skills/fix-ticket/SKILL.md` as the caller for NEEDS_DECOMPOSITION handling, but all three pipeline skills (`fix-ticket`, `fix-bugs`, `implement-feature`) handle NEEDS_DECOMPOSITION with nearly identical blocks. The current partial reference misleads readers into thinking NEEDS_DECOMPOSITION is only relevant to the bug-fix ticket pipeline. Determine whether line 44 should list all three callers explicitly, and whether line 21's "caller enforces the limit" language should also be updated to name all three callers.

---

### Q4.9 — fixer-reviewer-loop.md: Does the "once per ticket" NEEDS_DECOMPOSITION limit apply uniformly across all three callers?

**Files to examine:**
- `core/fixer-reviewer-loop.md` line 21
- `skills/fix-ticket/SKILL.md` line 452
- `skills/fix-bugs/SKILL.md` line 470
- `skills/implement-feature/SKILL.md` line 482

**What is needed:** The contract states: "Only allowed once per ticket; caller enforces the limit." `fix-bugs` processes multiple tickets in a batch. Determine whether `fix-bugs` enforces "once per run" or "once per individual ticket" for NEEDS_DECOMPOSITION. This distinction matters because the current contract language says "per ticket" but `fix-bugs` batch mode could encounter NEEDS_DECOMPOSITION on multiple tickets in the same run. The answer determines whether the updated NEEDS_DECOMPOSITION documentation should qualify the limit differently for batch vs. single-ticket callers.

---

## Summary

| Work Item | Questions | Theme |
|-----------|-----------|-------|
| WI1 — Tracker Subtask Extraction | 7 (Q1.1–Q1.7) | Divergences across three duplicate pseudocode blocks; new `core/tracker-subtask-creator.md` design |
| WI2 — Webhook Format Alignment | 4 (Q2.1–Q2.4) | Inconsistent JSON key names (`issue` vs `issue_id`, `pr` vs `pr_url`, `agent` vs `agent_name`) across inline webhook calls |
| WI3 — Block Handler Inline Removal | 6 (Q3.1–Q3.6) | Implement-feature inlines 6 steps that should delegate to `core/block-handler.md`; identify skill-specific residue |
| WI4 — LOW Documentation Fixes | 9 (Q4.1–Q4.9) | Stale language in fix-verification.md, ambiguous forward reference in state-manager.md, missing e2e_test schema fields, undocumented field reuse, incomplete NEEDS_DECOMPOSITION caller list |
| **Total** | **26** | |

### Key Discovery Themes

1. **Duplication across three pipeline skills** (WI1, WI3): The tracker subtask pseudocode block and the block handler inline procedure each appear in `fix-ticket`, `fix-bugs`, and `implement-feature` with subtle but consequential divergences. Extraction into core contracts requires confirming which divergences are intentional skill-specific variations vs. copy-paste drift.

2. **Webhook payload inconsistency** (WI2): `implement-feature` uses non-canonical key names (`"issue"`, `"pr"`, `"agent"`) in inline webhook calls while `fix-bugs` and core contracts use `"issue_id"`, `"pr_url"`, `"agent_name"`. The rename has potential breaking-change risk if any downstream consumers parse these keys.

3. **Core contract delegation patterns** (WI3): The three pipeline skills show three different delegation styles for Step X — clean delegation (`fix-ticket`), 6-step inline (`implement-feature`), 8-step inline with skill-specific additions (`fix-bugs`). The target pattern is `fix-ticket`'s minimal delegation, but the state.json reminder line's intentionality must be confirmed before replicating it.

4. **Schema and contract completeness** (WI4): Multiple contracts contain partial or outdated information — `fix-verification.md` uses fix-framing in feature-pipeline output, `state-manager.md` has an ambiguous bare-filename forward reference, `state/schema.md` is missing `e2e_test` fields and mode-reuse documentation, and `fixer-reviewer-loop.md` lists only one of three NEEDS_DECOMPOSITION callers.
