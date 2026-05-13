# Brainstorm Synthesis — v6.7.2 Pipeline Consistency & Dedup

## Judge-Mediator Verdict

Three proposals reviewed: Contract Design Architect (Agent 1), Refactoring Pragmatist (Agent 2), Documentation Systems Engineer (Agent 3). All three converge on the same fundamental approach for every work item. Differences are in scope boundaries and edge-case handling. This synthesis selects the best approach for each decision point.

---

## WI1: Tracker Subtask Extraction to `core/tracker-subtask-creator.md`

### Consensus

All three agents agree on:
- Extract the ~140-line pseudocode block into a new `core/tracker-subtask-creator.md`
- Follow the established core contract pattern (Purpose/Input Contract/Process/Output Contract/Failure Handling)
- 9-field Input Contract table
- Triple gate moves into the contract
- Callers become pure delegation stubs (~5 lines each)
- `tracker_effective_status` gets formally defined in the contract
- The cosmetic `mcp-body-formatting.md` reference difference (list-item vs. paragraph) is normalized to paragraph form
- YOLO latent bug in fix-bugs is out of scope for this PATCH

### Conflicts and Resolutions

**Conflict 1: Per-Tracker table and Issue Description Template — extract or keep in callers?**

- Agent 1: Extract everything into the core contract.
- Agent 2: Initially proposed keeping the table in callers, then reversed to "extract everything" after reflection.
- Agent 3: Extract everything into the core contract.

**Resolution: Extract everything.** All three ultimately agree. The table is byte-identical across callers, has three sync points, and belongs in the single source of truth. Callers become pure delegation stubs.

**Conflict 2: Input Contract table format — 3-column or 4-column?**

- Agent 1: 4 columns (Field, Type, Default, Notes) — includes defaults for optional fields.
- Agent 2: 3 columns (Field, Type, Notes).
- Agent 3: 3 columns (Field, Type, Notes).

**Resolution: 3-column table.** The 4-column format from Agent 1 is more precise but inconsistent with the established pattern in `core/block-handler.md` and `core/post-publish-hook.md`, which both use 3 columns. Defaults are documented in the Notes column (e.g., `(default: "enabled")`). Consistency with existing contracts takes priority.

**Conflict 3: Output Contract format**

- Agent 1: Bullet list with `success_count`, `failure_count`, `created_issues` plus "Pipeline continues regardless."
- Agent 2: Bullet list with same fields plus "YAML committed if success_count > 0."
- Agent 3: Table format with COMPLETED/SKIPPED results.

**Resolution: Agent 1 bullet-list format with Agent 2's YAML note.** The COMPLETED/SKIPPED table from Agent 3 is overengineered for a contract that is fire-and-forget (pipeline never blocks here). The bullet list matches `core/post-publish-hook.md` style. Add Agent 2's YAML commit note as it is useful operational context.

**Conflict 4: Should the YOLO bug be documented anywhere?**

- Agent 1: Note in changelog as known issue.
- Agent 2: Document in TODO or roadmap entry.
- Agent 3: Flag in implementation notes.

**Resolution: Add a one-line entry to `docs/plans/roadmap.md`.** This follows the project convention (feedback_roadmap_items.md: "all forge follow-ups go to roadmap.md"). Do NOT clutter the changelog with known-issue notes for bugs that existed before this version.

### Selected Approach

Create `core/tracker-subtask-creator.md` with this structure:

```
# Tracker Subtask Creator

## Purpose
Create tracker sub-issues from a decomposition plan, with idempotency, per-tracker MCP dispatch, and dual-store (YAML + state.json) persistence.

## Input Contract
| Field | Type | Notes |
|-------|------|-------|
| issue_id | string | Parent issue tracker ID |
| tracker_type | string | From Automation Config → Issue Tracker → Type |
| tracker_project | string | From Automation Config → Issue Tracker → Project |
| tracker_effective_status | string | `"ready"` or `"unavailable"` — set by caller from MCP pre-flight output (`core/mcp-preflight.md`) |
| decomposition_decision | string | `"DECOMPOSE"` or `"SINGLE_PASS"` |
| create_tracker_subtasks_config | string | Value of Decomposition → Create tracker subtasks (default: `"enabled"`) |
| subtask_list | object[] | Subtask objects from decomposition (in topological order) |
| yaml_path | string | Path to `.claude/decomposition/{ISSUE-ID}.yaml` |
| state_json_path | string | Path to `.ceos-agents/{ISSUE-ID}/state.json` |

## Process

### Triple Gate
Skip this procedure entirely (no WARN, expected behavior) if ANY of:
1. decomposition_decision != "DECOMPOSE"
2. create_tracker_subtasks_config == "disabled"
3. tracker_effective_status != "ready"

### Subtask Creation Loop
[Full pseudocode block — verbatim from existing copies]

## Per-Tracker Issue Creation Parameters
[6-row table — verbatim from existing copies]

## Issue Description Template
[Template block + conditional rules + mcp-body-formatting reference (paragraph form)]

## Output Contract
- `success_count` (integer): number of tracker issues created or recovered
- `failure_count` (integer): number of creation failures
- `created_issues` (list): `{subtask_id, tracker_issue_id, title}` tuples
- YAML committed if success_count > 0
- Pipeline continues regardless of outcome. NEVER block here.

## Failure Handling
- Individual subtask creation failure → log warning, increment failure_count, continue loop
- GitHub/Gitea checklist update failure → log warning, continue (standalone sub-issues still exist)
- All creations failed → display warning message, pipeline continues
- YAML commit failure → log warning, continue (tracker issues exist, YAML linkage lost — recoverable on resume via state.json fallback)
```

Each caller becomes:

```markdown
### {step}. Create tracker subtasks

Follow `core/tracker-subtask-creator.md`.

Required in-memory values: `ISSUE_ID`, `tracker_type`, `tracker_project`, `tracker_effective_status`, `decomposition_decision`, `create_tracker_subtasks_config`, subtask list, YAML path (`.claude/decomposition/{ISSUE-ID}.yaml`), state.json path (`.ceos-agents/{ISSUE-ID}/state.json`).
```

---

## WI2: Webhook Format Alignment

### Consensus

All three agents agree on:
- implement-feature step 10a inline curl must be removed (5 deviations from canonical format)
- implement-feature step X inline webhook is subsumed by WI3
- fix-bugs step 8b is a double-fire bug (step 8a already delegates to core which fires the webhook)
- fix-bugs step 9a (pipeline-complete) is unique and stays untouched
- fix-ticket is already clean

### Conflicts and Resolutions

**Conflict 1: fix-bugs step 8b — remove entirely or keep as pointer?**

- Agent 1: Keep as no-op with note "Handled by `core/post-publish-hook.md` in step 8a."
- Agent 2: Remove step 8b entirely, renumber 8c to 8b.
- Agent 3: Keep as pointer, same rationale as Agent 1.

**Resolution: Keep step 8b as a pointer.** Agent 2's renumbering approach is cleaner structurally but breaks external references to "step 8c" (fix verification) which may exist in documentation or user notes. A no-op pointer preserves step numbering stability while clearly explaining why the step is empty. This also matches the principle of least surprise — readers scanning the skill see all step numbers in sequence.

**Conflict 2: fix-bugs step X (block handler) — clean up now or defer?**

- Agent 1: YES, clean up fix-bugs step X now (remove duplicate steps 4-5, keep only skill-specific addenda). This is the most aggressive approach.
- Agent 2: NO, defer fix-bugs step X cleanup to future version. Only fix the webhook key names (`issue` → `issue_id`, `agent` → `agent_name`, add `timestamp`) as a 1-line patch.
- Agent 3: Partial — remove the inline webhook (step 5) and replace with a pointer note, but keep the rest of the inline.

**Resolution: Agent 1's full cleanup.** The reasoning is compelling: fix-bugs step X currently says "Follow `core/block-handler.md` for the block protocol" at L669 and then re-lists the entire 6-step procedure below it. Steps 1-5 are duplicates of the core contract (with deviation bugs in the webhook). Only three items are genuinely skill-specific: worktree-aware rollback context, per-issue state.json path, and block counter logic. Agent 2's "only fix the key names" approach leaves a contradictory inline that delegates to core then re-implements core. Agent 3's partial approach is inconsistent — removing only the webhook while leaving the other duplicate steps creates an unfinished state.

The full cleanup keeps the core delegation line + lists ONLY the skill-specific overrides:

```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

**Skill-specific context:**
- Rollback execution context: `{worktree_path}` (parallel mode) or `CWD` (sequential mode). Pass this in the rollback-agent Task context string.
- State path: `.ceos-agents/{ISSUE-ID}/state.json` (per-issue, not per-run).
- Block counter: After core block protocol completes, increment `block_count`. If `Max blocked per run` is not `unlimited` and `block_count >= Max blocked per run`:
  - Display: "Max blocked per run ({N}) reached. Remaining {M} bugs skipped."
  - Skip to step 9 (Summary) — DO NOT process remaining bugs.
- Continue with next bug.
```

**Conflict 3: Is fix-bugs step 8b a duplicate or additive?**

Verified from the source: step 8a delegates to `core/post-publish-hook.md` which fires the `pr-created` webhook at its Process step 3. Step 8b then fires the same `pr-created` event again with deviant keys. This is a confirmed double-fire bug — both fire the same event type. Step 8b is purely a duplicate.

**Conflict 4: implement-feature step 10a — keep "If Hooks → Post-publish" summary line?**

- Agent 1: Remove everything, match fix-ticket pattern exactly (one delegation line).
- Agent 2: Initially considered keeping the hook summary line, then decided to match fix-ticket.
- Agent 3: Keep the summary line for LLM comprehension.

**Resolution: Match fix-ticket pattern (Agent 1/2).** The summary line duplicates what core/post-publish-hook.md Process step 1 already says. fix-ticket is the cleanest caller — it proves the bare delegation line is sufficient for LLM comprehension.

### Selected Approach

1. **implement-feature step 10a** → replace with: `Follow core/post-publish-hook.md for hook execution and webhook firing.`
2. **fix-bugs step 8b** → replace with pointer: `Handled by core/post-publish-hook.md (invoked in step 8a above). No additional action needed.`
3. **fix-bugs step X** → full cleanup to delegation + skill-specific addenda (as described above)
4. **implement-feature step X** → handled by WI3

---

## WI3: Block Handler Inline Removal (implement-feature)

### Consensus

All three agents fully agree:
- Replace the 25-line inline (L642-666) with the 4-line fix-ticket-style delegation
- Keep the state.json reminder line (intentional LLM-directed redundancy, matches fix-ticket L609)
- This automatically fixes the unconditional rollback bug (core has the correct guard)
- This automatically fixes 5+ additional deviations (missing status-verification, missing mcp-body-formatting reference, deviant webhook format, missing failure handling)

### Conflicts and Resolutions

**Conflict: Whether to touch fix-bugs step X as part of WI3**

- Agent 1: YES, clean fix-bugs step X as part of WI2+WI3 combined.
- Agent 2: NO, leave fix-bugs step X for a future version.
- Agent 3: Partial — remove only the webhook, keep the rest.

**Resolution: Already resolved under WI2 Conflict 2 above. Clean fix-bugs step X fully.** The combined WI2+WI3 scope for fix-bugs step X is Agent 1's approach. It would be inconsistent to clean implement-feature's block handler (WI3) while leaving fix-bugs's block handler with duplicate core steps plus deviant webhooks. Both are the same class of problem — "delegate then duplicate" — and both should be fixed together in this release.

### Selected Approach

**implement-feature step X (after):**
```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.
```

Matches fix-ticket L605-609 exactly. Zero skill-specific addenda needed (implement-feature has none).

---

## WI4: Documentation Fixes

### Consensus

All three agents agree on all 5 fixes with identical before/after text.

### Conflicts and Resolutions

**Conflict 1: Agent 3 proposes a 6th fix — Purpose line in `core/fix-verification.md` (L5)**

Agent 3 suggests changing L5 from:
> Run the verify command after PR merge to confirm the fix works on the target branch.

to:
> Run the verify command after PR merge to confirm the changes work on the target branch.

- Agent 1: Not mentioned.
- Agent 2: Not mentioned.
- Agent 3: Proposes as part of Fix 1/Fix 2 scope.

**Resolution: INCLUDE the 6th fix.** Agent 3 is correct — the Purpose line has the same "fix"-centric language as the comment templates. Changing one word ("fix" → "changes") is trivially safe, and leaving it creates an inconsistency within the same file (mode-neutral comments but mode-specific Purpose line). This is a scalpel edit with zero risk.

**Conflict 2: Agent 2 proposes adding triage field reuse notes to state/schema.md**

Agent 2 notes: "Add a note after the triage section header: Note: triage.* fields are populated in bug-fix, feature, and scaffold modes. triage.severity and triage.reproduction_steps are bug-fix-only..."

- Agent 1: Not mentioned.
- Agent 3: Not mentioned.

**Resolution: EXCLUDE.** The phase-0 analysis mentions this as a potential fix under WI4 ("No documentation about field reuse across modes — Add inline note about feature pipeline reuse"), but none of the research phases validated what the actual reuse pattern is. Adding undocumented assertions about which fields are mode-specific without research confirmation risks introducing incorrect documentation. Defer to a future version where the assertion can be verified.

### Selected Approach — 6 Fixes

**Fix 1 — `core/fix-verification.md` L5: Mode-neutral Purpose**
- Before: `Run the verify command after PR merge to confirm the fix works on the target branch.`
- After: `Run the verify command after PR merge to confirm the changes work on the target branch.`

**Fix 2 — `core/fix-verification.md` L21: Mode-neutral success comment**
- Before: `[ceos-agents] ✅ Fix verified. Verify command: ...`
- After: `[ceos-agents] ✅ Verified. Verify command: ...`

**Fix 3 — `core/fix-verification.md` L26: Mode-neutral failure comment**
- Before: `[ceos-agents] ❌ Fix verification failed.`
- After: `[ceos-agents] ❌ Verification failed.`

**Fix 4 — `core/state-manager.md` L41-43: Inline heuristic detection table**
- Replace forward reference to resume-ticket.md with self-contained 6-checkpoint heuristic table
- Add `(no AC list, no iteration counts)` qualifier to reduced context

**Fix 5 — `state/schema.md`: e2e_test section parity**
- JSON example: add `attempts`, `max_attempts`, `last_result` fields
- Field definition table: add 3 rows after `e2e_test.status`

**Fix 6 — `core/fixer-reviewer-loop.md` L44: Complete caller reference**
- Replace single fix-ticket reference with all three callers and their distinct enforcement strategies

---

## File Change Manifest

| # | File | WI | Action | Lines Delta (est.) |
|---|------|----|--------|-------------------|
| 1 | `core/tracker-subtask-creator.md` | WI1 | **NEW** (15th core contract) | +~200 |
| 2 | `skills/fix-ticket/SKILL.md` | WI1 | Replace step 4b-tracker block with delegation | -~160, +~5 |
| 3 | `skills/fix-bugs/SKILL.md` | WI1, WI2 | Replace step 3b-tracker with delegation; replace step 8b with pointer; replace step X with delegation + addenda | -~200, +~15 |
| 4 | `skills/implement-feature/SKILL.md` | WI1, WI2, WI3 | Replace step 5a with delegation; replace step 10a with one-liner; replace step X with 4-line delegation | -~190, +~8 |
| 5 | `core/fix-verification.md` | WI4 | 3 lines modified (L5, L21, L26) | 0 net |
| 6 | `core/state-manager.md` | WI4 | L41-43 replaced with inline heuristic table | +~5 |
| 7 | `state/schema.md` | WI4 | JSON example update + 3 table rows inserted | +~6 |
| 8 | `core/fixer-reviewer-loop.md` | WI4 | L44 expanded with all-caller documentation | 0 net (line gets longer) |
| 9 | `CLAUDE.md` | cross-cutting | L27: "14 shared pipeline pattern contracts" → "15" | 0 net |

**Totals:** 1 new file, 8 modified files. ~550 lines removed, ~240 lines added. Net reduction: ~310 lines.

## Implementation Order

```
WI4 (6 doc fixes — independent, zero risk)
  │
  v
WI1 (new core contract + 3 caller refactors — largest change)
  │
  v
WI3 (implement-feature block handler replacement)
  │
  v
WI2 (fix-bugs step 8b pointer + fix-bugs step X cleanup + implement-feature step 10a)
  │
  v
CLAUDE.md count update (14 → 15)
```

### Rationale for this order

1. **WI4 first:** Independent, touches different files from WI1-3, and fixes issues in core contracts (state-manager forward reference) that the new WI1 contract may reference.
2. **WI1 second:** Largest diff. Creates the new file. All subsequent work items operate against the post-extraction file state (smaller skills, stable line numbers for the remaining steps).
3. **WI3 third:** Removes implement-feature inline block handler. This must land before WI2 because the implement-feature step X webhook is inside the block handler removed by WI3 — WI3 subsumes that WI2 target.
4. **WI2 last:** Handles remaining webhook cleanup (fix-bugs step 8b pointer, fix-bugs step X full cleanup, implement-feature step 10a). These are the final surgical edits against already-stabilized files.
5. **CLAUDE.md update last:** Depends on WI1 completing (new file must exist before the count is updated).

## Verification Criteria

1. `core/tracker-subtask-creator.md` follows Purpose/Input Contract/Process/Output Contract/Failure Handling structure
2. All three callers' delegation blocks list exactly 9 required in-memory values
3. No inline curl commands remain in implement-feature (zero occurrences)
4. fix-bugs step 8b is a pointer referencing step 8a (no curl command)
5. fix-bugs step X contains exactly 4 skill-specific items (worktree context, state path, block counter, continue)
6. implement-feature step X is <= 5 lines (delegation + state.json reminder)
7. `core/fix-verification.md` contains "Verified" (not "Fix verified") in both comments and "changes" (not "fix") in Purpose
8. `core/state-manager.md` L41+ contains 6 heuristic checkpoints and no forward reference to resume-ticket
9. `state/schema.md` e2e_test section has 4 fields in both JSON example and field table
10. `core/fixer-reviewer-loop.md` L44 references all three callers with distinct enforcement strategies
11. `CLAUDE.md` says "15 shared pipeline pattern contracts"
12. All existing tests pass (`./tests/harness/run-tests.sh`)
13. fix-bugs YOLO latent bug added to roadmap.md (not fixed)
