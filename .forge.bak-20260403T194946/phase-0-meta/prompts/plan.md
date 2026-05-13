# Phase 6 — Plan + Execute

## Persona
{{PERSONA}}: Senior Claude Code Plugin Engineer with deep expertise in markdown-based pipeline orchestration, state persistence contracts, and LLM-executable instruction design.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

You are fixing two bugs in `skills/implement-feature/SKILL.md`. The reference implementation is `skills/fix-ticket/SKILL.md`.

### Bug 1: Subtask Persistence Failure

**Root cause analysis (from Phase 1 research):**

The implement-feature skill has THREE persistence gaps compared to fix-ticket:

**Gap A — Task tree file write at Step 5 is present but may lack explicitness.**
- implement-feature line 235: `**Save task tree:** Write to .claude/decomposition/{ISSUE-ID}.yaml`
- fix-ticket line 171: `**Save task tree to .claude/decomposition/{ISSUE-ID}.yaml**`
- Both mention saving. BUT: implement-feature's Step 5 state.json update (line 237) writes `decomposition.status`, `decomposition.decision`, `decomposition.strategy`, `decomposition.subtasks` — this is correct and complete per the schema.

**Gap B — Step 6h task tree update during subtask execution is vague.**
- implement-feature line 322: `Update the task tree state on disk (.claude/decomposition/).`
- fix-ticket line 196: `Save commit_hash and restore_point to the task tree.` (within the commit step, in context of the full subtask loop at 4c)
- The implement-feature instruction at 6h does not explicitly say WHAT fields to update (commit_hash, restore_point, status) — just "update the task tree state." An LLM executor may not know what to write.

**Gap C — No explicit instruction to create the `.claude/decomposition/` directory before writing.**
- fix-ticket does not explicitly create the directory either, but its instruction flow is more sequentially clear.
- implement-feature should add a mkdir instruction at Step 5 before the save.

**Gap D — The decomposition subtasks are not persisted to the issue tracker.**
- The user reported subtasks are "not persisted to files or issue tracker." The issue tracker persistence is NOT part of the current design for fix-ticket either — subtasks are tracked in `.claude/decomposition/` YAML, not as tracker issues. However, the `state.json` `decomposition.subtasks` field should mirror the YAML. If neither the YAML write nor the state.json write works, subtasks exist only in agent memory.

### Bug 2: Confirmation Flow Disorder

**Confirmation inventory in implement-feature:**

| # | Step | Prompt | --yolo bypass? | Assessment |
|---|------|--------|----------------|------------|
| 1 | 0c.4 | Duplicate check "Create anyway? [y/N]" | Yes (YOLO skips entire duplicate check) | CORRECT |
| 2 | 0c.5 | Card creation "Create this card? [Y/n]" | Yes (line 131/140) | CORRECT |
| 3 | 5 | AC unmapped "Continue anyway? [Y/n]" | Yes (line 211 — YOLO blocks instead of confirming) | CORRECT but note YOLO blocks |
| 4 | 5 | Decomposition plan "Continue? [Y/n]" | Yes (line 233) | CORRECT |
| 5 | 9 | PR creation "Create PR? [Y/n]" | Yes (line 347) | CORRECT |

All 5 confirmation points have `--yolo` bypass branches. The flow appears correct in the SKILL.md text.

**Potential autonomous-execution issue:** The problem may be that when the skill runs WITHOUT `--yolo`, the confirmation prompts break the flow because Claude Code's `disable-model-invocation: true` setting means the skill cannot "ask" the user — it just renders the prompt and stops. With `disable-model-invocation: true`, the skill must be fully autonomous or explicitly designed to pause for input.

Actually, re-reading the frontmatter: `disable-model-invocation: true` means the skill itself does not invoke a model — it orchestrates via Task tool calls. The skill CAN display text and wait for user input because it IS the model's current context. The confirmations should work as intended in interactive mode.

The user's complaint "asks user for confirmations at wrong points" suggests the issue is about WHICH points, not the mechanism. Review whether all 5 confirmation points are appropriate.

### Execution Plan

**Task 1: Fix subtask persistence (Gap B — most impactful)**
- File: `skills/implement-feature/SKILL.md`
- Location: Step 6h (around line 316-322)
- Change: Replace the vague "Update the task tree state on disk" with explicit instructions matching fix-ticket's pattern:
  ```
  Save commit_hash and restore_point to the subtask entry in `.claude/decomposition/{ISSUE-ID}.yaml`.
  Set the subtask's `status` to `"completed"` in the YAML file.
  Update `state.json`: find the matching subtask in `decomposition.subtasks` and set its `status` to `"completed"`, `commit_hash` to the new commit hash. Follow atomic write protocol from `core/state-manager.md`.
  ```

**Task 2: Add directory creation at Step 5**
- File: `skills/implement-feature/SKILL.md`
- Location: Step 5, before the "Save task tree" instruction (around line 235)
- Change: Add `Create directory .claude/decomposition/ if it does not exist.` before the save instruction.

**Task 3: Review and document confirmation flow**
- File: `skills/implement-feature/SKILL.md`
- Review all 5 confirmation points. If any are misplaced or missing --yolo handling, fix them. Based on analysis above, the textual definitions appear correct — the issue may be in execution behavior, not definition.

**Task 4: Ensure decomposition.subtasks state.json write includes all fields**
- File: `skills/implement-feature/SKILL.md`
- Location: Step 5, state.json update section (line 237)
- Verify the `decomposition.subtasks` write includes the full subtask objects (not just IDs).

## Success Criteria
{{SUCCESS_CRITERIA}}:
1. Step 5 explicitly creates `.claude/decomposition/` directory before writing the task tree YAML
2. Step 5's "Save task tree" instruction matches the explicitness of fix-ticket's Step 4b
3. Step 6h explicitly names the fields to update in both YAML and state.json (commit_hash, restore_point, status)
4. All confirmation points have documented --yolo bypass behavior
5. The `decomposition.subtasks` state.json write at Step 5 explicitly includes full subtask objects
6. Test suite passes after changes

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Adding persistence instructions that conflict with the state schema (state/schema.md)
2. Making the fix too verbose — implement-feature should match fix-ticket's pattern, not exceed it
3. Breaking the existing confirmation flow while fixing persistence
4. Forgetting to update both persistence targets (YAML file AND state.json)
5. Adding new confirmation points that don't exist in the design
6. Changing agent definitions (agents/*.md) when the bug is in the skill definition
7. Over-engineering the fix with new features (tracker issue creation for subtasks) when the bug is about basic file persistence

## Codebase Context
{{CODEBASE_CONTEXT}}:
Pure markdown Claude Code plugin. No runtime code. Edit only:
- `skills/implement-feature/SKILL.md` — primary fix target
Reference files (read-only):
- `skills/fix-ticket/SKILL.md` — reference for correct persistence pattern
- `state/schema.md` — persistence schema contract
- `core/decomposition-heuristics.md` — decomposition decision logic
- `core/state-manager.md` — state write protocol
