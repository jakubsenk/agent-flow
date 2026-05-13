# Brainstorm: Documentation Systems Engineer — v6.7.2 Implementation

Perspective: Cross-reference integrity, terminology consistency, schema completeness, and documentation consumer reliability. LLMs parse these schemas to decide what state to write — ambiguous or missing field documentation causes incorrect writes. Every delegation reference must use the exact right file path. Every count in CLAUDE.md must reflect reality.

---

## WI1: Tracker Subtask Extraction to `core/tracker-subtask-creator.md`

### Approach

Create a new core contract following the exact Purpose/Input Contract/Process/Output Contract/Failure Handling structure used by all existing contracts (`block-handler.md`, `post-publish-hook.md`, `mcp-preflight.md`). The contract owns the triple gate, the full pseudocode, and the `tracker_effective_status` definition.

### Documentation Design

**Input Contract table** — 9 fields, following the `| Field | Type | Notes |` format from `core/block-handler.md`:

| Field | Type | Notes |
|-------|------|-------|
| `tracker_effective_status` | string | `"ready"` (MCP available) or `"unavailable"` (MCP not available). Set by caller from MCP pre-flight output. |
| `create_tracker_subtasks_config` | string | Value of Decomposition -> Create tracker subtasks (default: `"enabled"`). |
| `decomposition_decision` | string | `"DECOMPOSE"` or `"SINGLE_PASS"`. Only `DECOMPOSE` reaches this contract. |
| `issue_id` | string | Parent issue tracker ID. |
| `tracker_type` | string | One of: `youtrack`, `github`, `jira`, `linear`, `redmine`, `gitea`. |
| `tracker_project` | string | Tracker project key or owner/repo. |
| `subtask_list` | object[] | Subtask objects from decomposition (in-memory). |
| `yaml_path` | string | Path to `.claude/decomposition/{ISSUE-ID}.yaml`. |
| `state_json_path` | string | Path to `.ceos-agents/{ISSUE-ID}/state.json`. |

**Triple gate goes inside Process step 1:**

```
1. Gate check:
   IF create_tracker_subtasks_config == "disabled" -> return SKIPPED("disabled by config")
   IF tracker_effective_status != "ready" -> return SKIPPED("tracker unavailable")
   IF decomposition_decision != "DECOMPOSE" -> return SKIPPED("no decomposition")
```

This is critical: all three callers have identical gate text today. Placing the gate inside the contract prevents three-way drift and ensures the `tracker_effective_status` variable — currently undefined anywhere — gets a formal owner.

**Process steps 2-N:** The full pseudocode block (FOR EACH subtask, idempotency check, per-tracker MCP calls, dual store write, CATCH, commit YAML, GitHub/Gitea checklist, result display) moves verbatim from the callers. The only cosmetic difference across the three copies is a single list-item vs. paragraph sentence for the `core/mcp-body-formatting.md` reference — normalize to paragraph form.

**Output Contract:**

| Result | Payload |
|--------|---------|
| `COMPLETED` | `{success_count, failure_count, created_issues[]}` |
| `SKIPPED` | `{reason}` — config disabled, tracker unavailable, or no decomposition |

**Failure Handling section** (4 named scenarios, following block-handler pattern):
- Per-subtask MCP failure -> log warning, increment failure_count, continue (NEVER block)
- YAML write failure -> log warning, rely on state.json fallback on resume
- GitHub/Gitea checklist update failure -> log warning, continue (sub-issues still exist)
- All creations failed -> display warning, return COMPLETED with success_count=0

### Caller Refactoring

All three callers (`fix-ticket/SKILL.md`, `fix-bugs/SKILL.md`, `implement-feature/SKILL.md`) replace their ~140-line pseudocode blocks with a single delegation line:

```markdown
Follow `core/tracker-subtask-creator.md` to create tracker sub-issues for each subtask.
```

The surrounding context (step header, input preparation listing the 9 fields) stays in each caller because the field sources differ slightly:
- `fix-bugs` runs inside a per-bug batch loop; `state_json_path` is `.ceos-agents/{ISSUE-ID}/state.json` (per-issue)
- `fix-ticket` and `implement-feature` operate on a single issue in CWD

The **Per-Tracker Issue Creation Parameters** table that follows the pseudocode in each file is documentation of the contract's behavior — it should move INTO the new contract file (after the Process section) so there is one source of truth.

### YOLO Bug in fix-bugs

The research found that `fix-bugs` references "mode is YOLO" in its AC coverage check but does not expose a `--yolo` flag (its argument-hint is `"<N> [--dry-run] [--profile <name>]"`). The new contract should NOT include YOLO logic — the YOLO path is a caller-level concern. The `fix-bugs` YOLO reference should be flagged as a known latent bug in the implementation notes but is out of scope for this PATCH version (fixing it would add a new flag, which is MINOR-level).

### Cross-Reference Integrity

After extraction, the following cross-references must exist:
1. `core/tracker-subtask-creator.md` references `core/state-manager.md` (atomic write protocol)
2. `core/tracker-subtask-creator.md` references `core/mcp-body-formatting.md` (comment formatting)
3. `skills/fix-ticket/SKILL.md` references `core/tracker-subtask-creator.md`
4. `skills/fix-bugs/SKILL.md` references `core/tracker-subtask-creator.md`
5. `skills/implement-feature/SKILL.md` references `core/tracker-subtask-creator.md`

And the following cross-references must be REMOVED (they currently point to nowhere since `tracker_effective_status` is implicit):
- None to remove; the implicit references become explicit through the contract's Input Contract.

### CLAUDE.md Impact

`core/` will contain 15 files after this extraction. CLAUDE.md line 27 currently reads:
```
- `core/` — 14 shared pipeline pattern contracts
```
Must change to:
```
- `core/` — 15 shared pipeline pattern contracts
```

MEMORY.md currently says "14 core contracts" in the conventions section. Must update to 15.

---

## WI2: Webhook Format Alignment

### Approach

The canonical format is defined by two core contracts:
- `core/post-publish-hook.md` (canonical `pr-created` webhook)
- `core/block-handler.md` (canonical `issue-blocked` webhook)

The fix is to remove all inline webhook curl invocations from skills and ensure skills delegate exclusively to core contracts. Where a skill already delegates to core AND fires inline, the inline copy is the duplicate — remove it.

### Precise Changes

**File: `skills/fix-bugs/SKILL.md`**

1. **Step 8b (pr-created, L610-618):** Remove entire step 8b. Step 8a already delegates to `core/post-publish-hook.md`, which fires the webhook. The inline at step 8b is a duplicate firing. Replace with:
   ```markdown
   ### 8b. Webhook — PR created

   Handled by `core/post-publish-hook.md` (invoked in step 8a above). No additional action needed.
   ```
   Alternative (simpler): delete step 8b entirely and renumber. But keeping it as a no-op pointer preserves the step numbering for existing documentation references.

   I recommend keeping it as a pointer. Deleting and renumbering would break any external references to "step 8c" (fix verification).

2. **Step X block handler webhook (L697-701):** The inline curl uses `"issue":"{issue}"` and `"agent":"{agent}"` — wrong keys. But this is mooted by WI3: the fix-bugs block handler already delegates to `core/block-handler.md` at L669, which fires the webhook canonically. The inline webhook at L697-701 is a duplicate. The fix-bugs block handler has legitimate skill-specific addenda (worktree context, block counter) that must remain, but the webhook step (item 5 in the inline) should be removed and replaced with a note:
   ```
   5. **Webhook — issue-blocked:** Handled by `core/block-handler.md` (step 5). No additional webhook firing here.
   ```

**File: `skills/implement-feature/SKILL.md`**

3. **Step 10a (pr-created, L620-623):** Step 10a delegates to `core/post-publish-hook.md` on line 619, then fires an inline curl on L622-623 with 5 deviations (missing --max-time, --retry, wrong keys `issue`/`pr`, missing timestamp, bare URL). Remove the inline curl. Replace step 10a with:
   ```markdown
   #### 10a. Post-publish hook + webhook

   Follow `core/post-publish-hook.md`. If Hooks -> Post-publish exists: run the command via Bash.
   ```
   The webhook firing is already handled inside `core/post-publish-hook.md` step 3. No inline needed.

4. **Step X block handler webhook (L661-664):** Fully addressed by WI3 (the entire inline block handler is being replaced with delegation). The deviant webhook disappears automatically.

**File: `skills/fix-ticket/SKILL.md`**

No changes needed. fix-ticket is already clean — pure delegation, no inline webhooks.

### Terminology Normalization

After these changes, the canonical JSON payload keys are:
- `issue_id` (never `issue`)
- `pr_url` (never `pr` or `url`)
- `agent_name` placeholder (never `agent`)
- `timestamp` always present
- URL always double-quoted
- `--max-time 5 --retry 0` always present

All inline copies that used deviant keys are removed, so normalization is automatic.

### Documentation Consumer Impact

External webhook receivers that were built against `implement-feature` events would have received `payload.issue` and `payload.pr`. After this fix, they will receive `payload.issue_id` and `payload.pr_url`. This is a breaking change for those consumers, but the old format was a bug — it never matched the documented canonical format in `core/post-publish-hook.md`. The fix aligns actual behavior to documented behavior. No documentation change is needed; the core contracts already document the correct format.

---

## WI3: Block Handler Inline Removal from `implement-feature`

### Approach

Replace lines 642-666 of `skills/implement-feature/SKILL.md` (25 lines of inline block handler) with the fix-ticket-style delegation pattern (3 lines).

### Exact Before/After

**Before (implement-feature L642-666):**
```markdown
### X. Block handler

Follow `core/block-handler.md`:

1. Run `ceos-agents:rollback-agent` (Task tool, model: haiku) — revert git changes
2. Set issue state to Blocked (State transitions -> Blocked)
3. **On block action** (per Error Handling -> On block):
   - `comment` (default): Add a Block comment to the issue tracker (see below)
   - `close`: Add a Block comment + close the issue
   - Other value: interpret as a custom action (always add a comment)
4. Add Block comment to the issue tracker:
   ```
   [ceos-agents] 🔴 Pipeline Block
   Agent: {agent name}
   Step: {pipeline step}
   Reason: {max 2 sentences}
   Detail: {error output}
   Recommendation: {what human should do}
   ```
5. If Notifications -> Webhook URL exists and On events contains `issue-blocked`:
   ```bash
   curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"issue-blocked","issue":"{issue_id}","agent":"{agent}","reason":"{reason}"}'
   ```

6. Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.
```

**After (matching fix-ticket L605-609):**
```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.
```

### What This Fixes

1. **Behavioral bug: unconditional rollback.** The inline calls rollback-agent for ALL blocking agents, including read-only agents like `spec-analyst` and `architect`. The core contract (`core/block-handler.md` L21) has the correct conditional guard: only rollback for `fixer`, `reviewer`, `test-engineer`, `e2e-test-engineer`, or `smoke-check`. Delegating to core automatically fixes this bug.

2. **Missing rollback Task context string.** The inline does not pass the execution context string to rollback-agent. The core contract does.

3. **Missing status-verification follow-up.** The inline does not verify the state transition succeeded. The core contract calls `core/status-verification.md` after the status-set MCP call.

4. **Missing `core/mcp-body-formatting.md` reference.** The inline constructs the block comment without referencing the formatting contract. The core contract includes this reference.

5. **Deviant webhook format.** Missing `--max-time 5`, `--retry 0`, wrong keys (`issue` vs `issue_id`, `{agent}` vs `{agent_name}`), missing `timestamp`, bare URL. Addressed automatically by delegation.

6. **Missing Failure Handling.** The inline has no instructions for comment failure, webhook failure, state failure, or rollback failure. The core contract has all four.

### Why the state.json line remains

The state.json update line is kept because fix-ticket also keeps it (L609). It serves as a per-skill reminder that is intentionally duplicated (per the contributor note pattern used elsewhere in the codebase). The core contract also mandates it (step 6), so this is belt-and-suspenders — acceptable for LLM-directed compliance.

### fix-bugs Block Handler — No Change in This WI

The fix-bugs inline block handler (L667-710) has three genuinely skill-specific additions that must remain: worktree-aware rollback context string (L674), per-issue state.json path (L704), and block counter logic (L706-710). Only the duplicate webhook (WI2, item 2 above) is removed from fix-bugs. The structural inline in fix-bugs is NOT replaced because the addenda are necessary.

---

## WI4: Documentation Fixes (5 files)

### Fix 1 — Mode-Neutral Language in `core/fix-verification.md` L21

**Problem:** The success comment says "Fix verified" but this contract is also invoked by `implement-feature` (feature pipeline). The word "Fix" is bug-fix-centric and misleading for feature work.

**Callers that reference this file:**
- `skills/fix-ticket/SKILL.md` L603 (bug-fix — "Fix" is correct)
- `skills/fix-bugs/SKILL.md` L622 (bug-fix — "Fix" is correct)
- `skills/implement-feature/SKILL.md` L627 (feature — "Fix" is misleading)

Note that `implement-feature` already uses mode-specific language in its OWN verification step (10b): "Feature verified" at L635 and "Feature verification failed" at L638. But the core contract itself should be mode-neutral since it serves both pipelines.

**Before (line 21):**
```
[ceos-agents] ✅ Fix verified. Verify command: `{command}`. Output: {first 500 chars}.
```

**After (line 21):**
```
[ceos-agents] ✅ Verified. Verify command: `{command}`. Output: {first 500 chars}.
```

**Impact on comment parsing:** The `[ceos-agents]` prefix is the machine-parseable marker (used by `/resume-ticket` for heuristic detection). The word "Fix" is not part of any detection regex. Removing it is safe.

### Fix 2 — Mode-Neutral Language in `core/fix-verification.md` L26

**Before (line 26):**
```
[ceos-agents] ❌ Fix verification failed.
```

**After (line 26):**
```
[ceos-agents] ❌ Verification failed.
```

**Same rationale as Fix 1.** Both changes make the contract mode-neutral.

**Additional consideration:** The file's Purpose section (L5) says "confirm the fix works on the target branch." This should also be made mode-neutral:

**Before (line 5):**
```
Run the verify command after PR merge to confirm the fix works on the target branch.
```

**After (line 5):**
```
Run the verify command after PR merge to confirm the changes work on the target branch.
```

### Fix 3 — Forward Reference in `core/state-manager.md` L41-43

**Problem:** The Resume Process says "Fall back to heuristic detection (see resume-ticket.md existing logic)." This creates a forward-reference loop — a core contract borrowing its fallback definition from one of its callers (`resume-ticket` is a skill above the core layer). The contract cannot be understood in isolation. An LLM reading `core/state-manager.md` to understand the resume process would need to look up a skill file — violating the core layer's self-containment principle.

**Before (lines 41-43):**
```markdown
2. If state.json does not exist:
   - Fall back to heuristic detection (see resume-ticket.md existing logic)
   - Return resume_point from heuristic with reduced context
```

**After (lines 41-43, expanded):**
```markdown
2. If state.json does not exist:
   - Fall back to heuristic detection by reading issue tracker comments, branch state, and git log:
     - PR open for branch -> `PUBLISHED`
     - `.claude/decomposition/{ISSUE-ID}.yaml` exists -> `DECOMPOSE_PARTIAL`
     - Branch with commits above base -> `POST_FIX` (or `POST_REVIEW` if reviewer approval comment present)
     - Branch exists + `[ceos-agents] Triage completed.` comment -> `POST_ANALYSIS`
     - `[ceos-agents] Triage completed.` comment only -> `POST_TRIAGE`
     - Otherwise -> `FRESH`
   - Return resume_point from heuristic with reduced context (no AC list, no iteration counts)
```

**Cross-reference impact:** The `skills/resume-ticket/SKILL.md` heuristic table (L36-70) remains unchanged — it is the implementation. The core contract now documents the same checkpoints as a summary table, giving the contract self-contained documentation while `resume-ticket` retains the full implementation detail. This is the same pattern as `core/block-handler.md` documenting the block comment format while skills implement the dispatch.

**Order of checkpoints:** The list is ordered by detection priority (same as resume-ticket's detection logic at L52-58): PUBLISHED first (highest priority, most definitive signal), FRESH last (fallback). This ordering matches what the heuristic actually does.

### Fix 4 — Schema Parity for `e2e_test` in `state/schema.md`

**Problem:** The `e2e_test` section in the schema has only `status`, while the analogous `test` section has `status`, `attempts`, `max_attempts`, and `last_result`. LLMs reading the schema to decide what state to write after an E2E test run will NOT write attempt tracking — because the fields are not documented. This means:
- Resume after E2E failure cannot know how many attempts were used
- Metrics collection cannot report E2E retry rates
- The state file silently diverges between `test` (fully tracked) and `e2e_test` (minimally tracked)

**Part A — JSON example block (around L104-106):**

**Before:**
```json
"e2e_test": {
  "status": "pending"
},
```

**After:**
```json
"e2e_test": {
  "status": "pending",
  "attempts": 0,
  "max_attempts": 3,
  "last_result": null
},
```

**Part B — Field definitions table (after L226):**

**Before (L225-226):**
```
| `e2e_test` | object | Yes | — | E2E-test-engineer phase state. |
| `e2e_test.status` | string | Yes | `"pending"` | Phase status. See Step Status Enum. |
```

**After (L225-229):**
```
| `e2e_test` | object | Yes | — | E2E-test-engineer phase state. |
| `e2e_test.status` | string | Yes | `"pending"` | Phase status. See Step Status Enum. |
| `e2e_test.attempts` | integer | Yes | `0` | Number of completed E2E test attempts. |
| `e2e_test.max_attempts` | integer | Yes | `3` | Maximum allowed attempts (from retry limits). |
| `e2e_test.last_result` | string or null | No | `null` | Most recent E2E test outcome: `PASSED` or `FAILED`. |
```

**Why `max_attempts` defaults to 3:** The Retry Limits table in CLAUDE.md defines `Test attempts: 3` as the default. E2E tests share the same retry limit (there is no separate `e2e_test_attempts` retry limit key). If a project needs different limits for E2E, that would be a future MINOR feature.

**Schema version:** Remains `"1.0"`. Adding optional fields with defaults to the schema does not constitute a schema version bump — existing state files without these fields will be read as having the defaults (0, 3, null) by any compliant reader. This follows the same pattern used when `deployment` fields were added (no schema version bump).

### Fix 5 — Incomplete Caller Reference in `core/fixer-reviewer-loop.md` L44

**Problem:** The Failure Handling section only references `skills/fix-ticket/SKILL.md step 5` for NEEDS_DECOMPOSITION handling, omitting `fix-bugs` and `implement-feature`. An LLM reading this contract would conclude only fix-ticket handles decomposition — and would not know that the three callers enforce the limit differently.

**Before (line 44):**
```
- `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `skills/fix-ticket/SKILL.md` step 5).
```

**After (line 44):**
```
- `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md`). Enforcement varies by caller: `fix-ticket` and `fix-bugs` each enforce a one-decomposition-per-ticket limit (Block if already decomposed); `implement-feature` always Blocks (decomposition mode Blocks the subtask; single-pass mode Blocks the issue).
```

**Why remove the step reference:** The `skills/fix-ticket/SKILL.md step 5` reference is fragile — step numbers can change. The replacement describes behavior rather than pointing to a specific step, which is more resilient. All three callers are named so an LLM can look up any of them.

**Line 21 note:** Line 21 says "Only allowed once per ticket; caller enforces the limit." This remains correct as a high-level statement. The detailed per-caller enforcement documentation now lives in line 44 (Failure Handling), which is the right place — Failure Handling is where callers learn what to do with each result.

---

## Cross-Cutting Concerns

### 1. CLAUDE.md Core Contract Count

**Location:** `CLAUDE.md` line 27
**Before:** `- `core/` — 14 shared pipeline pattern contracts`
**After:** `- `core/` — 15 shared pipeline pattern contracts`

This is a required change due to WI1 creating `core/tracker-subtask-creator.md`. The count must match reality. Failing to update this line means LLMs reading CLAUDE.md will have an incorrect mental model of the repository.

### 2. MEMORY.md Convention Count

**Location:** MEMORY.md conventions line (currently says "14 core contracts")
**Before:** `- Total: 21 agents, 28 skills, 14 core contracts, 17 optional config sections`
**After:** `- Total: 21 agents, 28 skills, 15 core contracts, 17 optional config sections`

### 3. CHANGELOG Entry

The changelog entry for v6.7.2 should list:
- `core/tracker-subtask-creator.md` — new core contract (15th)
- Webhook format alignment across fix-bugs and implement-feature
- Block handler inline removed from implement-feature (fixes unconditional rollback bug)
- 5 documentation fixes (fix-verification mode-neutral, state-manager self-contained heuristic, schema.md e2e_test parity, fixer-reviewer-loop complete caller reference)
- Artifact counts: 21 agents (unchanged), 28 skills (unchanged), 15 core contracts (was 14), 17 optional config sections (unchanged)

### 4. Test Impact

The test harness (`tests/`) should be checked for any tests that:
- Count files in `core/` (must expect 15, not 14)
- Match the exact text of webhook curl commands (tests would break if they grep for the old inline format)
- Match the exact text of block handler steps in implement-feature
- Match "Fix verified" or "Fix verification failed" strings

### 5. Roadmap Cleanup

`docs/plans/roadmap.md` L608 contains an existing entry for the fix-verification language fix. After implementation, this entry should be marked as completed/removed.

### 6. implement-feature Step 10b Verification Language

After Fix 1 and Fix 2 make the core contract mode-neutral, there is a question about `implement-feature` step 10b (L625-640), which has its OWN verification text: "Feature verified" and "Feature verification failed." Step 10b says "Follow `core/fix-verification.md`" but then re-specifies the behavior inline with feature-specific language. This is the SAME pattern as the block handler duplication (WI3): delegate then duplicate.

For this version, I recommend leaving step 10b as-is. It is correctly using feature-specific language ("Feature verified"), and the core contract will now say "Verified" (mode-neutral). The inline in step 10b is not a conflict — it is a specialization. But this should be flagged for future cleanup (consolidate verification steps across skills into core contracts).

---

## Implementation Order

1. **WI4 first** — documentation fixes are independent and low-risk. They also fix issues that would affect the quality of the WI1 contract if left unfixed (e.g., the state-manager forward reference would be inherited by the new contract if it references state-manager).

2. **WI1 second** — creates the new core contract and refactors the three callers. This is the largest change and benefits from WI4 being done (schema.md e2e_test parity means the new contract is written against a complete schema).

3. **WI3 third** — removes the implement-feature inline block handler. This is simple but depends on WI2 being sequenced afterward (the block handler webhook is part of both WI2 and WI3).

4. **WI2 last** — removes all remaining inline webhooks from fix-bugs and implement-feature. WI3 already removes the implement-feature block handler webhook, so WI2 only needs to handle fix-bugs step 8b, fix-bugs step X item 5, and implement-feature step 10a.

Actually, WI3 and WI2 have overlap in implement-feature's Step X webhook. Doing WI3 first (replacing the entire inline) automatically removes the deviant webhook. Then WI2 handles the remaining inline webhooks in fix-bugs and implement-feature step 10a.

**Recommended task dependency graph:**

```
WI4 (5 doc fixes, independent)
  |
  v
WI1 (new core contract + 3 skill refactors)
  |
  v
WI3 (implement-feature block handler replacement)
  |
  v
WI2 (remaining webhook dedup in fix-bugs + implement-feature 10a)
  |
  v
CLAUDE.md + MEMORY.md count update (14 -> 15)
  |
  v
CHANGELOG entry
```

WI4 and WI1 could run in parallel since they touch different files. But WI1 is the only one that creates a new file — which triggers the count update — so it must complete before the CLAUDE.md update.

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| New `core/tracker-subtask-creator.md` breaks 3 skills if delegation reference is wrong | Exact file path in each delegation line; test that the file exists |
| Removing inline webhooks from fix-bugs causes silent loss of notifications | Core contracts already fire the webhooks; the inline was a DUPLICATE, not the primary |
| e2e_test schema fields are added but no agent writes them | This is acceptable — the fields have safe defaults (0, 3, null) and will be populated when the e2e-test-engineer is updated in a future version |
| `tracker_effective_status` is formally defined but callers may not set it | The Input Contract makes it required; callers already reference the variable name in identical gate checks |
| YOLO bug in fix-bugs is documented but not fixed | Correct — fixing it would add a new CLI flag (`--yolo`), which is MINOR-level, not PATCH |

---

## Summary of File Touches

| File | Action | Lines Changed (est.) |
|------|--------|---------------------|
| `core/tracker-subtask-creator.md` | NEW | ~180 |
| `skills/fix-ticket/SKILL.md` | EDIT (replace ~140 lines with delegation) | -135 |
| `skills/fix-bugs/SKILL.md` | EDIT (replace ~140 lines with delegation + remove step 8b inline + remove step X item 5 inline) | -145 |
| `skills/implement-feature/SKILL.md` | EDIT (replace ~140 lines with delegation + replace step X inline + fix step 10a inline) | -160 |
| `core/fix-verification.md` | EDIT (3 lines: L5, L21, L26) | 3 |
| `core/state-manager.md` | EDIT (L41-43: 3 lines become 8 lines) | +5 |
| `state/schema.md` | EDIT (JSON example + 3 table rows) | +6 |
| `core/fixer-reviewer-loop.md` | EDIT (L44: 1 line) | 1 |
| `CLAUDE.md` | EDIT (L27: 14 -> 15) | 1 |
| `CHANGELOG.md` | EDIT (add v6.7.2 entry) | ~15 |

**Net effect:** ~180 new lines (core contract), ~440 lines removed (3 inline copies), ~30 lines of doc fixes. Net: ~250 lines removed from the repository.
