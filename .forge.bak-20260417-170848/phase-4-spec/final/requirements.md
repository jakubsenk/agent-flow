# Requirements — v6.7.2 Pipeline Consistency & Dedup

## Release Classification

**Version:** 6.7.2 (PATCH)
**Scope:** No behavioral changes, no new features. Extraction of duplicated logic into a shared contract, alignment of webhook formats, removal of inline block handler copies, and documentation corrections.
**Constraint:** Every change must be provably equivalent to the pre-change behavior (except where the pre-change behavior was a documented deviation/bug being corrected).

---

## WI-1: Tracker Subtask Extraction

### REQ-1.1: Core Contract Creation

Create `core/tracker-subtask-creator.md` as the 15th shared pipeline pattern contract. The contract MUST:

1. Follow the established core contract structure: Purpose, Input Contract, Process, Output Contract, Failure Handling.
2. Contain the complete pseudocode block currently duplicated in three skills (fix-ticket step 4b-tracker, fix-bugs step 3b-tracker, implement-feature step 5a).
3. Define a 9-field Input Contract table using 3-column format (Field, Type, Notes) consistent with `core/block-handler.md` and `core/post-publish-hook.md`.
4. Include the Triple Gate logic (3 skip conditions) as the first section of the Process.
5. Include the Per-Tracker Issue Creation Parameters table (6 rows).
6. Include the Issue Description Template block with conditional rules.
7. Reference `core/mcp-body-formatting.md` in paragraph form (not list-item form).
8. Define the Output Contract as a bullet list with `success_count`, `failure_count`, `created_issues`, YAML commit note, and "Pipeline continues regardless" statement.
9. Define Failure Handling for 4 failure scenarios (individual subtask, checklist update, all-creations-failed, YAML commit).

### REQ-1.2: Caller Delegation

Each of the three callers MUST be replaced with a 5-line delegation stub that:

1. References `core/tracker-subtask-creator.md` as the authoritative source.
2. Lists exactly 9 required in-memory values: `ISSUE_ID`, `tracker_type`, `tracker_project`, `tracker_effective_status`, `decomposition_decision`, `create_tracker_subtasks_config`, subtask list, YAML path, state.json path.
3. Contains zero inline pseudocode, zero Per-Tracker table, zero Issue Description Template.

### REQ-1.3: Functional Equivalence

The extracted contract MUST be byte-equivalent in behavior to the current inline copies. Specifically:

- Idempotency logic (YAML-first, state.json fallback) preserved exactly.
- Per-tracker MCP dispatch (YouTrack, Jira, Linear, Redmine, GitHub, Gitea) preserved exactly.
- Jira nested sub-task guard preserved exactly.
- GitHub/Gitea checklist post-loop preserved exactly.
- Dual-store persistence (YAML + state.json) preserved exactly.
- Result display messages preserved exactly.
- All `LOG`, `DISPLAY`, `WARN` messages preserved exactly.

### REQ-1.4: mcp-body-formatting Reference Normalization

The fix-ticket caller currently uses list-item form (`- Follow core/mcp-body-formatting.md...`). The new contract MUST use paragraph form (`Follow core/mcp-body-formatting.md...`), matching the existing fix-bugs and implement-feature form.

---

## WI-2: Webhook Format Alignment

### REQ-2.1: implement-feature Step 10a

Replace the inline curl command and hook summary in implement-feature step 10a with a single delegation line to `core/post-publish-hook.md`, matching the fix-ticket pattern.

**Deviations being corrected:**
1. Missing `--max-time 5 --retry 0` flags (present in canonical `core/post-publish-hook.md`)
2. Missing `timestamp` field in JSON payload
3. Key name `issue` instead of canonical `issue_id`
4. Key name `pr` instead of canonical `pr_url`
5. Missing heredoc body construction (present in canonical)

### REQ-2.2: fix-bugs Step 8b

Replace the duplicate inline webhook in fix-bugs step 8b with a pointer note explaining that the webhook is already handled by `core/post-publish-hook.md` in step 8a. This corrects a confirmed double-fire bug (step 8a delegates to core which fires `pr-created`, then step 8b fires `pr-created` again with deviant keys).

### REQ-2.3: fix-bugs Step X

Replace the 8-step inline block handler in fix-bugs step X with a clean delegation to `core/block-handler.md` plus skill-specific addenda (4 items: worktree-aware rollback context, per-issue state.json path, block counter logic, continue-with-next-bug).

**Deviations being corrected in the inline:**
- Steps 1-6 are duplicates of `core/block-handler.md` Process steps 1-6
- Webhook in step 5 uses deviant key names (`issue` instead of `issue_id`, `agent` instead of `agent_name`)
- Missing `core/status-verification.md` reference after status-set MCP call (present in core)
- Missing `core/mcp-body-formatting.md` reference for block comment (present in core)

---

## WI-3: Block Handler Inline Removal (implement-feature)

### REQ-3.1: implement-feature Step X

Replace the 25-line inline block handler (L642-666) with the 4-line fix-ticket-style delegation pattern. The replacement MUST:

1. Reference `core/block-handler.md` as the authoritative source.
2. Include the state.json update reminder (intentional LLM-directed redundancy, matching fix-ticket L609).
3. Contain zero inline rollback, zero status-set, zero comment posting, zero webhook firing logic.

**Bugs being automatically corrected:**
- Unconditional rollback (core has the correct guard: only rollback for fixer/reviewer/test-engineer/e2e-test-engineer/smoke-check)
- Missing `core/status-verification.md` reference
- Missing `core/mcp-body-formatting.md` reference
- Deviant webhook format (missing `--max-time`, missing `timestamp`, deviant key names)
- Missing failure handling for each sub-step

---

## WI-4: Documentation Fixes

### REQ-4.1: Fix 1 — Mode-Neutral Purpose in fix-verification.md

Change the word "fix" to "changes" in the Purpose line (L5) to make the contract mode-neutral (used by both bug-fix and feature pipelines).

### REQ-4.2: Fix 2 — Mode-Neutral Success Comment in fix-verification.md

Change "Fix verified" to "Verified" in the success comment template (L21) to make the comment mode-neutral.

### REQ-4.3: Fix 3 — Mode-Neutral Failure Comment in fix-verification.md

Change "Fix verification failed" to "Verification failed" in the failure comment template (L26) to make the comment mode-neutral.

### REQ-4.4: Fix 4 — Inline Heuristic in state-manager.md

Replace the forward reference to `resume-ticket.md` at L42-43 with a self-contained inline heuristic detection table (6 checkpoints). Add `(no AC list, no iteration counts)` qualifier to the "reduced context" mention.

### REQ-4.5: Fix 5 — e2e_test Schema Parity in state/schema.md

Add `verdict`, `result_path`, and `attempts` fields to the `e2e_test` section in both the JSON example and the field definition table. These fields are written by the e2e-test-engineer phase but are currently undocumented in the schema.

### REQ-4.6: Fix 6 — Complete Caller Reference in fixer-reviewer-loop.md

Replace the single `skills/fix-ticket/SKILL.md` reference at L44 with all three callers (fix-ticket, fix-bugs, implement-feature) and their distinct enforcement strategies.

---

## WI-Cross: CLAUDE.md Count Update

### REQ-C.1: Core Contract Count

Update CLAUDE.md line 27 from "14 shared pipeline pattern contracts" to "15 shared pipeline pattern contracts" to reflect the new `core/tracker-subtask-creator.md`.

---

## WI-Cross: Roadmap Entry

### REQ-R.1: YOLO Latent Bug

Add a one-line entry to `docs/plans/roadmap.md` documenting the latent YOLO bug in fix-bugs (fix-bugs does not support `--yolo` flag but contains YOLO references inherited from fix-ticket). This follows the project convention (feedback_roadmap_items.md).

---

## Implementation Order

1. WI-4 (6 documentation fixes -- independent, zero risk)
2. WI-1 (new core contract + 3 caller refactors)
3. WI-3 (implement-feature block handler replacement)
4. WI-2 (fix-bugs step 8b pointer + fix-bugs step X cleanup + implement-feature step 10a)
5. CLAUDE.md count update (14 -> 15)

---

## File Change Manifest

| # | File | WI | Action |
|---|------|----|--------|
| 1 | `core/tracker-subtask-creator.md` | WI-1 | NEW (15th core contract) |
| 2 | `skills/fix-ticket/SKILL.md` | WI-1 | Replace step 4b-tracker (~155 lines) with 5-line stub |
| 3 | `skills/fix-bugs/SKILL.md` | WI-1, WI-2 | Replace step 3b-tracker with stub; replace step 8b with pointer; replace step X with delegation + addenda |
| 4 | `skills/implement-feature/SKILL.md` | WI-1, WI-2, WI-3 | Replace step 5a with stub; replace step 10a with one-liner; replace step X with 4-line delegation |
| 5 | `core/fix-verification.md` | WI-4 | 3 lines modified (L5, L21, L26) |
| 6 | `core/state-manager.md` | WI-4 | L41-43 replaced with inline heuristic table |
| 7 | `state/schema.md` | WI-4 | JSON example update + 3 table rows inserted |
| 8 | `core/fixer-reviewer-loop.md` | WI-4 | L44 expanded with all-caller reference |
| 9 | `CLAUDE.md` | cross | L27: 14 -> 15 |
| 10 | `docs/plans/roadmap.md` | cross | 1-line entry added |

**Totals:** 1 new file, 9 modified files. Net line reduction: ~310 lines.
