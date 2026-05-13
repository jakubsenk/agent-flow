# Brainstorm Agent 2 — Refactoring Pragmatist

Perspective: Minimal diff size, zero behavioral change, LLM comprehension preserved. Extraction only where the dedup payoff clearly exceeds the comprehension cost of indirection. Intentional repetition is not a defect.

---

## WI1: Tracker Subtask Extraction to `core/tracker-subtask-creator.md`

### Design Decision: Extract, but keep the Per-Tracker table and Issue Description Template in callers

The ~140-line pseudocode block is byte-identical across all 3 skills. That is genuine waste -- three sync points for one procedure. Extraction is justified.

However, extracting EVERYTHING (pseudocode + table + template) into core forces the LLM to cross-reference a second file for information it currently sees inline. The pseudocode is procedural logic that benefits from single-source-of-truth. The Per-Tracker Issue Creation Parameters table and Issue Description Template are reference material that agents consult while executing the procedure -- they are MORE useful near the procedure call than behind a file reference.

**Pragmatic split:**
- **Extract to core:** Triple gate, pseudocode block (lines 223-360 in fix-ticket), and the `core/mcp-body-formatting.md` reference. These are the parts that must stay in sync.
- **Keep in callers:** The Per-Tracker table and Issue Description Template. These are stable reference data (changed once in v5.3.0, not since). If they drift, the delta is cosmetic, not behavioral.

**Counter-argument considered and rejected:** "Extract everything for single source of truth." The table is 8 rows of static data. The cost of drift is a wrong MCP parameter name, which the MCP server would reject immediately. The cost of extraction is that the LLM executing the subtask creation must look up a separate file for parameter mappings while inside a FOR loop. LLMs handle inline context better than cross-file lookups during procedural execution.

**Final answer: Extract everything.** On reflection, the counter-argument wins for a different reason: the research confirms the tables are byte-identical, and three copies of an 8-row table is still three sync points. The table belongs in the core contract. The callers become pure delegation stubs. This is simpler to maintain and simpler to verify.

### New file: `core/tracker-subtask-creator.md`

Structure follows the established core contract pattern (`block-handler.md`, `post-publish-hook.md`):

```
# Tracker Subtask Creator

## Purpose
Create tracker sub-issues from a decomposition plan, with idempotency, per-tracker MCP dispatch, and dual-store (YAML + state.json) persistence.

## Input Contract
| Field | Type | Notes |
|-------|------|-------|
| issue_id | string | Parent issue tracker ID |
| tracker_type | string | From Automation Config -> Issue Tracker -> Type |
| tracker_project | string | From Automation Config -> Issue Tracker -> Project |
| tracker_effective_status | string | `"ready"` or `"unavailable"` (from MCP pre-flight) |
| decomposition_decision | string | `"DECOMPOSE"` or `"SINGLE_PASS"` |
| create_tracker_subtasks_config | string | From Decomposition -> Create tracker subtasks (default: `"enabled"`) |
| subtask_list | array | Decomposition subtasks (in-memory from previous step) |
| yaml_path | string | `.claude/decomposition/{ISSUE-ID}.yaml` |
| state_json_path | string | Path to state.json for this issue |

## Process
[Triple gate -- 3 conditions, skip if any true]
[Full pseudocode block -- verbatim from current inline copies]

## Per-Tracker Issue Creation Parameters
[6-row table -- verbatim from current inline copies]

## Issue Description Template
[Template block + 4 bullet rules + mcp-body-formatting reference]

## Output Contract
- `success_count`, `failure_count`, `created_issues` list
- YAML committed if success_count > 0
- Pipeline NEVER blocks here (failures are warnings)

## Failure Handling
- Individual subtask creation failure -> WARN, continue to next subtask
- All subtasks failed -> WARN with connectivity guidance, continue pipeline
- GitHub/Gitea checklist update failure -> WARN, standalone sub-issues still exist
```

### What the triple gate includes

The gate checks three conditions. Research confirms all three callers have identical gate text. The contract owns the gate:

```
Skip this step entirely (no WARN, expected behavior) if ANY of:
1. decomposition_decision != "DECOMPOSE"
2. create_tracker_subtasks_config == "disabled"
3. tracker_effective_status != "ready"
```

### What callers become

Each caller shrinks from ~170 lines (triple gate + required values + pseudocode + table + template) to ~5 lines:

**fix-ticket** (step 4b-tracker):
```markdown
### 4b-tracker. Create tracker subtasks

Follow `core/tracker-subtask-creator.md`.

Required in-memory values: `ISSUE_ID`, `tracker_type`, `tracker_project`, `tracker_effective_status`, `decomposition_decision`, `create_tracker_subtasks_config`, subtask list, YAML path (`.claude/decomposition/{ISSUE-ID}.yaml`), state.json path (`.ceos-agents/{ISSUE-ID}/state.json`).
```

**fix-bugs** (step 3b-tracker): identical structure, same values.

**implement-feature** (step 5a): identical structure, same values.

### Handling the cosmetic difference

Research found one cosmetic difference: fix-ticket uses `- Follow core/mcp-body-formatting.md...` (list-item) while fix-bugs and implement-feature use `Follow core/mcp-body-formatting.md...` (plain paragraph). This reference moves into the core contract, so the difference disappears.

### Handling the YOLO latent bug

Research found fix-bugs references "mode is YOLO" for AC coverage check but does not expose `--yolo`. This is NOT in the tracker subtask code -- it is in the AC coverage step (step 3b, before 3b-tracker). It is out of scope for this extraction. The research correctly identifies it, but fixing it would expand scope beyond WI1. Document in a TODO comment or roadmap entry, do not fix in v6.7.2.

### `tracker_effective_status` formal definition

The new contract's Input Contract table formally defines `tracker_effective_status` as: `string | "ready" or "unavailable" — set by caller from MCP pre-flight output`. This closes the implicit-variable gap identified in the research.

### Diff estimate

- **New file:** `core/tracker-subtask-creator.md` (~200 lines)
- **fix-ticket/SKILL.md:** -165 lines, +5 lines (step 4b-tracker replacement)
- **fix-bugs/SKILL.md:** -165 lines, +5 lines (step 3b-tracker replacement)
- **implement-feature/SKILL.md:** -165 lines, +5 lines (step 5a replacement, keeping step 5a-exit intact)
- **Net:** +200 new, -495 removed, +15 added = ~280 net reduction

### Risk assessment

**LOW.** The pseudocode is byte-identical. The new contract produces identical behavior. Callers delegate with the same parameters they already populate in-memory. No behavioral change.

---

## WI2: Webhook Format Alignment

### Design Decision: Remove inline duplicates, do NOT touch fix-bugs step 9a

The research identifies three problems:
1. **implement-feature step 10a** has wrong keys, missing flags, missing timestamp
2. **implement-feature step X** has wrong keys, missing flags, missing timestamp
3. **fix-bugs step 8b** duplicates what `core/post-publish-hook.md` already fires (called in step 8a), and has one wrong key (`url` instead of `pr_url`)
4. **fix-bugs step X** duplicates what `core/block-handler.md` already fires (called at L669)

Problem 3 and 4 are DOUBLE-FIRING bugs: the core contract fires the webhook, then the inline copy fires it again.

**Approach:**

#### implement-feature step 10a (pr-created)

The step currently says "Follow `core/post-publish-hook.md`" and then ALSO fires an inline curl. This is the same double-fire pattern as fix-bugs.

**Fix:** Remove the inline curl block entirely. The delegation to `core/post-publish-hook.md` already handles webhook firing. The step becomes:

```markdown
#### 10a. Post-publish hook + webhook

Follow `core/post-publish-hook.md` for hook execution and webhook firing.

If Hooks -> Post-publish exists: run the command via Bash.
```

Wait -- this still has a problem. The "If Hooks -> Post-publish exists" line is ALSO handled by `core/post-publish-hook.md` (its Process step 1). So this is another duplication. However, removing it changes how the LLM reads the step -- it would see only a bare delegation line with no context about what happens.

**Pragmatic choice:** Keep the "If Hooks -> Post-publish exists" line as a human-readable summary. It does not cause double-firing (the core contract handles it). It helps the LLM understand what the delegation step does without opening the core file. This matches fix-bugs step 8a which has the same pattern.

Actually, looking more carefully at fix-bugs step 8a vs fix-ticket step 9a/9b:

- **fix-ticket** (steps 9a + 9b): bare delegation -- `Follow core/post-publish-hook.md for hook execution and webhook firing.` No inline details. Clean.
- **fix-bugs** (step 8a): delegation + summary -- `Follow core/post-publish-hook.md for hook execution and webhook firing.` + `If Hooks -> Post-publish exists:` block. Adds context but doesn't duplicate webhook logic.

The fix-ticket pattern is the cleanest. For implement-feature, I will match fix-ticket:

**Before (implement-feature step 10a):**
```markdown
#### 10a. Post-publish hook + webhook

Follow `core/post-publish-hook.md`. If Hooks -> Post-publish exists: run the command via Bash.
If Notifications -> Webhook URL exists and On events contains `pr-created`:
\`\`\`bash
curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"pr-created","issue":"{issue_id}","pr":"{pr_url}"}'
\`\`\`
```

**After:**
```markdown
#### 10a. Post-publish hook + webhook

Follow `core/post-publish-hook.md` for hook execution and webhook firing.
```

This removes the inline curl AND the redundant hook summary. The delegation covers everything.

#### implement-feature step X (issue-blocked)

WI3 handles this. The entire inline block handler goes away and is replaced with a delegation line. The webhook fix is subsumed by WI3.

#### fix-bugs step 8b (pr-created -- double firing)

Step 8a already delegates to `core/post-publish-hook.md`, which fires the pr-created webhook. Step 8b then fires it AGAIN with wrong keys (`issue` instead of `issue_id`, `url` instead of `pr_url`).

**Fix:** Remove step 8b entirely. Rename step 8c to 8b (Fix Verification). The webhook is already fired by the core contract in step 8a.

**Before:**
```markdown
### 8a. Post-publish hook

Follow `core/post-publish-hook.md` for hook execution and webhook firing.

If Hooks -> Post-publish exists:
- Run the command via Bash
- Failure -> warning only (PR already exists, cannot rollback)

### 8b. Webhook -- PR created

If Notifications -> Webhook URL exists and `pr-created` is in On events:
\`\`\`bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"pr-created","issue_id":"{issue}","pr_url":"{url}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
\`\`\`
Failure -> warning, must not stop the pipeline.

### 8c. Fix Verification (optional, per-bug)
```

**After:**
```markdown
### 8a. Post-publish hook + webhook

Follow `core/post-publish-hook.md` for hook execution and webhook firing.

If Hooks -> Post-publish exists:
- Run the command via Bash
- Failure -> warning only (PR already exists, cannot rollback)

### 8b. Fix Verification (optional, per-bug)
```

Step header renamed from "8a. Post-publish hook" to "8a. Post-publish hook + webhook" (to match implement-feature and signal that webhook is included). Step 8b (old 8c) renumbered.

**Impact on fix-bugs step 9a (pipeline-complete webhook):** This webhook is unique to fix-bugs and has no canonical core contract. It uses correct flags (`--max-time 5 --retry 0`) and correct format. Leave it untouched. It is not a duplicate -- it fires a different event type.

#### fix-bugs step X (issue-blocked -- double firing)

The fix-bugs step X (L667-710) already delegates to `core/block-handler.md` at L669, then re-lists the entire procedure including an inline curl at L697-701 with wrong keys (`issue` instead of `issue_id`).

**Decision: Do NOT touch fix-bugs step X in v6.7.2.** The research (WI3) explicitly states: "fix-bugs inline cannot be fully removed -- three items are genuinely skill-specific: worktree-aware rollback context string, per-issue state.json path, and block counter logic." The fix-bugs block handler has legitimate skill-specific addenda. Fixing its webhook keys requires careful surgery to keep the addenda while removing the duplicated core steps. This is a separate work item (scope control).

The webhook key deviation (`issue` instead of `issue_id`, `{agent}` instead of `{agent_name}`) in fix-bugs step X IS a real bug, but fixing it is entangled with the larger fix-bugs block handler cleanup. Fix the two easy targets (implement-feature step 10a and fix-bugs step 8b) and leave fix-bugs step X for a future version.

**EXCEPTION:** We CAN fix just the webhook keys in fix-bugs step X without restructuring the block handler. The inline curl at L697-701 uses `"issue":"{issue}"` and `"agent":"{agent}"`. Change to `"issue_id":"{issue_id}"` and `"agent":"{agent_name}"` and add `"timestamp":"{ISO8601}"`. This is a 1-line diff that does not change the block handler structure. Do it.

### Diff estimate

- **implement-feature/SKILL.md step 10a:** -4 lines (remove inline curl block), +1 line (clean delegation)
- **fix-bugs/SKILL.md step 8b:** -9 lines (remove entire step), rename 8c->8b, rename header 8a
- **fix-bugs/SKILL.md step X webhook:** 1 line modified (key names + timestamp)
- **Net:** ~14 lines removed, ~2 lines modified

### Risk assessment

**LOW.** Removing inline duplicates that already delegate to core contracts. The only behavioral change is eliminating double webhook firing, which is a bug fix. Key name alignment matches the documented canonical format.

---

## WI3: Block Handler Inline Removal (implement-feature)

### Design Decision: Replace with fix-ticket-style delegation, zero addenda

Research confirms:
- implement-feature's inline block handler (L642-666) has zero skill-specific logic
- It has a behavioral bug (calls rollback-agent unconditionally, including for read-only agents)
- fix-ticket's pattern (L605-609) is the canonical reference: pure delegation + state.json reminder

**Before (implement-feature, 25 lines):**
```markdown
### X. Block handler

Follow `core/block-handler.md`:

1. Run `ceos-agents:rollback-agent` (Task tool, model: haiku) -- revert git changes
2. Set issue state to Blocked (State transitions -> Blocked)
3. **On block action** (per Error Handling -> On block):
   - `comment` (default): Add a Block comment to the issue tracker (see below)
   - `close`: Add a Block comment + close the issue
   - Other value: interpret as a custom action (always add a comment)
4. Add Block comment to the issue tracker:
   [block comment template]
5. If Notifications -> Webhook URL exists and On events contains `issue-blocked`:
   [inline curl with wrong keys]

6. Update `state.json`: set top-level `status` to `"blocked"`, write `block` object...
```

**After (implement-feature, 4 lines):**
```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.
```

This matches fix-ticket L605-609 exactly.

### Why the state.json line stays

`core/block-handler.md` step 6 already mandates the state.json update. But both fix-ticket (L609) and fix-bugs (L704) include a state.json reminder after the delegation. This is intentional LLM-directed repetition: the state.json update is the MOST IMPORTANT side-effect of a block, and a redundant reminder after delegation ensures the LLM does not skip it even if it summarizes the core contract steps.

Keep it for consistency with the other two callers and for LLM reliability.

### Bugs fixed by this change

1. **Unconditional rollback removed:** The inline called rollback-agent for ALL blocking agents. `core/block-handler.md` step 1 has the correct guard: only rollback for fixer, reviewer, test-engineer, e2e-test-engineer, or smoke-check. For spec-analyst or architect blocks, no rollback needed (no git changes).

2. **Webhook format fixed:** The inline curl had wrong keys (`issue` instead of `issue_id`, `{agent}` instead of `{agent_name}`), missing `--max-time 5`, missing `--retry 0`, missing `timestamp`. Delegating to core uses the correct format automatically.

3. **Missing status-verification fixed:** The inline skipped the `core/status-verification.md` follow-up after setting issue state. Core step 2 includes it.

4. **Missing mcp-body-formatting reference fixed:** The inline skipped the `core/mcp-body-formatting.md` reference when constructing the block comment. Core step 4 includes it.

### Why NOT touch fix-bugs step X

fix-bugs step X (L667-710) has the same delegation-then-inline problem, but it has three genuinely skill-specific addenda:
1. Worktree-aware rollback context string (L674)
2. Per-issue `.ceos-agents/{ISSUE-ID}/state.json` path (L704)
3. Block counter logic (L706-708: `block_count`, `Max blocked per run`, skip to step 9)

These MUST remain. Cleaning up fix-bugs step X requires carefully extracting only the addenda while removing the duplicated core steps. That is a separate work item with different risk characteristics. Out of scope for v6.7.2.

### Diff estimate

- **implement-feature/SKILL.md:** -21 lines (remove inline steps 1-5 + block comment template + curl block), +0 lines (delegation line and state.json line already exist at L644 and L666)
- **Net:** ~21 lines removed

### Risk assessment

**LOW.** Removing redundant inline code that already references the core contract. The delegation line already exists (L644: "Follow `core/block-handler.md`:"). We are removing what comes after the colon and changing `:` to ` for the block protocol.` No new logic added.

---

## WI4: Documentation Fixes (5 items)

### Design Decision: Exact targeted edits, minimal surrounding context changes

Each fix is a scalpel edit. No reformatting of surrounding text. No expanding scope to "while we're here" improvements.

### Fix 1: core/fix-verification.md L21 -- mode-neutral success comment

**Before:** `[ceos-agents] ✅ Fix verified. Verify command: \`{command}\`. Output: {first 500 chars}.`
**After:** `[ceos-agents] ✅ Verified. Verify command: \`{command}\`. Output: {first 500 chars}.`

One word removed ("Fix"). This file is used by implement-feature (features, not fixes), so "Fix verified" is misleading for features.

### Fix 2: core/fix-verification.md L26 -- mode-neutral failure comment

**Before:** `[ceos-agents] ❌ Fix verification failed.`
**After:** `[ceos-agents] ❌ Verification failed.`

Same rationale as Fix 1.

### Fix 3: core/state-manager.md L41-43 -- inline heuristic detection

**Before:**
```
2. If state.json does not exist:
   - Fall back to heuristic detection (see resume-ticket.md existing logic)
   - Return resume_point from heuristic with reduced context
```

**After:**
```
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

This removes the forward-reference loop (core contract referencing a skill above it). The heuristic table is self-contained. The `(no AC list, no iteration counts)` qualifier on reduced context makes the output explicit.

### Fix 4: state/schema.md -- e2e_test section parity

**Location:** After the `e2e_test.status` row (L226), before `browser_verification` (L227).

**Insert 3 rows:**
```
| `e2e_test.attempts` | integer | Yes | `0` | Number of completed E2E test attempts. |
| `e2e_test.max_attempts` | integer | Yes | `3` | Maximum allowed attempts (from retry limits). |
| `e2e_test.last_result` | string or null | No | `null` | Most recent E2E test outcome: `PASSED` or `FAILED`. |
```

**Also update the JSON example block.** The `e2e_test` object in the example (find it) should show all 4 fields:
```json
"e2e_test": {
  "status": "pending",
  "attempts": 0,
  "max_attempts": 3,
  "last_result": null
}
```

The field names, types, defaults, and descriptions all match the existing `test.*` section pattern exactly.

### Fix 5: core/fixer-reviewer-loop.md L44 -- caller reference completeness

**Before:**
```
- `NEEDS_DECOMPOSITION` -> returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `skills/fix-ticket/SKILL.md` step 5).
```

**After:**
```
- `NEEDS_DECOMPOSITION` -> returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md`). Enforcement varies by caller: `fix-ticket` and `fix-bugs` each enforce a one-decomposition-per-ticket limit (Block if already decomposed); `implement-feature` always Blocks (decomposition mode Blocks the subtask; single-pass mode Blocks the issue).
```

This replaces a reference to a single caller with an accurate summary of all three callers' behavior. The research confirmed: fix-ticket and fix-bugs use counter-based enforcement; implement-feature uses zero-tolerance Block.

### Diff estimate

- **core/fix-verification.md:** 2 lines modified (L21, L26)
- **core/state-manager.md:** 3 lines replaced with 8 lines (L41-43)
- **state/schema.md:** 3 rows inserted after L226, JSON example updated
- **core/fixer-reviewer-loop.md:** 1 line modified (L44)
- **Net:** ~12 lines added, ~6 lines modified

### Risk assessment

**VERY LOW.** All changes are documentation-only. No behavioral impact. The state schema additions document fields that already exist in practice (e2e-test-engineer writes them). The fix-verification comment changes are cosmetic (the `[ceos-agents]` prefix is the machine-parseable part; the human-readable text after it is advisory).

---

## Implementation Order

1. **WI4 first** (documentation fixes). Zero risk, independent of everything else. Gets the easy wins committed.
2. **WI1 second** (tracker subtask extraction). Largest change. Creates the new core contract file. Skills get smaller.
3. **WI3 third** (block handler inline removal). Depends on understanding the pattern established by WI1's delegation style. Also, WI3's webhook fix is subsumed by the delegation.
4. **WI2 last** (webhook alignment). Touches fix-bugs step 8b which must be done AFTER WI1 changes to fix-bugs are stable (WI1 removes ~165 lines earlier in the file, shifting all line numbers).

### Why this order

- WI4 is isolated and cannot conflict with anything.
- WI1 has the largest diff; doing it before WI2/WI3 means WI2/WI3 work against the post-extraction file state.
- WI3 removes the implement-feature inline block handler, which contains the broken webhook from WI2 -- so WI3 auto-fixes one of WI2's targets.
- WI2 is last because it needs stable line numbers after WI1 and WI3 have restructured the files.

---

## Files Changed Summary

| # | File | WI | Action | Lines delta |
|---|------|----|--------|-------------|
| 1 | `core/tracker-subtask-creator.md` | WI1 | **NEW** | +~200 |
| 2 | `skills/fix-ticket/SKILL.md` | WI1 | Replace step 4b-tracker block | -~165, +~5 |
| 3 | `skills/fix-bugs/SKILL.md` | WI1+WI2 | Replace step 3b-tracker, remove step 8b, fix step X webhook keys | -~175, +~6 |
| 4 | `skills/implement-feature/SKILL.md` | WI1+WI2+WI3 | Replace step 5a, remove step 10a inline curl, replace step X | -~190, +~8 |
| 5 | `core/fix-verification.md` | WI4 | 2 word changes | 0 |
| 6 | `core/state-manager.md` | WI4 | Replace heuristic reference with inline table | +~5 |
| 7 | `state/schema.md` | WI4 | Add 3 e2e_test field rows + JSON example update | +~6 |
| 8 | `core/fixer-reviewer-loop.md` | WI4 | Expand caller reference | 0 (line gets longer) |

**Total:** 1 new file, 7 modified files. ~530 lines removed, ~230 lines added. Net reduction: ~300 lines.

## What This Approach Does NOT Do

1. **Does not clean up fix-bugs block handler (step X).** Out of scope. The skill-specific addenda require careful surgery. Roadmap item for v6.8.x.
2. **Does not fix the fix-bugs YOLO latent bug.** Out of scope. The YOLO reference is in the AC coverage step, not in the tracker subtask code. Roadmap item.
3. **Does not change fix-bugs step 8a's hook summary lines.** These are LLM comprehension aids, not duplication bugs. They don't cause double-firing.
4. **Does not rename `core/fix-verification.md` to `core/verification.md`.** The filename is not user-facing and renaming it would require updating 3 skill references + any tests. The two-word fix inside the file is sufficient.
5. **Does not add mode-applicability notes to state/schema.md triage fields.** The research (Q4.6/Q4.7) identified this as a potential fix, but the phase-0 analysis lists it as a WI4 item. On re-reading the analysis: "No documentation about field reuse across modes -- Add inline note about feature pipeline reuse." This IS in scope. Add a note after the `triage` section header: "Note: `triage.*` fields are populated in bug-fix, feature, and scaffold modes. `triage.severity` and `triage.reproduction_steps` are bug-fix-only. `triage.area` is bug-fix-only (not set in feature/scaffold mode)."

---

## CLAUDE.md Impact

| Count | Before | After | Change? |
|-------|--------|-------|---------|
| Agents | 21 | 21 | No |
| Skills | 28 | 28 | No |
| Core contracts | 14 | **15** | **Yes** (+1: tracker-subtask-creator) |
| Optional config sections | 17 | 17 | No |

Update CLAUDE.md line mentioning "14 core contracts" to "15 core contracts". This appears in:
- Repository Structure section: `core/ -- 14 shared pipeline pattern contracts`
- Project Conventions bullet: `Total: 21 agents, 28 skills, 14 core contracts, 17 optional config sections`

Both must say 15.

---

## Test Impact

Run `tests/harness/run-tests.sh` and check:
- Any test that greps for inline tracker subtask pseudocode text
- Any test that checks step numbers (8b->8b renumbering in fix-bugs)
- Any test that checks webhook curl format in skill files
- The block-handler delegation pattern is tested implicitly by structural tests

No new test files needed. Existing tests should pass after the changes because they test behavioral contracts, not inline text.
