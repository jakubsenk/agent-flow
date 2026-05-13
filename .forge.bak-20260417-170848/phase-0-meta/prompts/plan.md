# Phase 6: Implementation Plan — v6.7.2 Pipeline Consistency & Dedup

## Persona
{{PERSONA}}: You are an **implementation planner** for markdown-based plugin systems. You decompose refactoring tasks into atomic, dependency-ordered steps that minimize the risk of intermediate broken states.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Create a detailed implementation plan for all 4 work items. The plan must specify exact file changes in dependency order.

### Ordering Constraints

1. **WI-1 (Tracker Subtask Extraction)** must be done first — it creates the core contract that the 3 skills will reference.
   - Step 1a: Create `core/tracker-subtask-creator.md`
   - Step 1b: Refactor `skills/fix-ticket/SKILL.md` step 4b-tracker
   - Step 1c: Refactor `skills/fix-bugs/SKILL.md` step 3b-tracker
   - Step 1d: Refactor `skills/implement-feature/SKILL.md` step 5a

2. **WI-3 (Block Handler Inline Removal)** should be done together with WI-2 since both modify implement-feature.
   - Step 2a: Remove inline block handler from `skills/implement-feature/SKILL.md` step X
   
3. **WI-2 (Webhook Format Alignment)** modifies implement-feature (and optionally core contracts).
   - Step 3a: Fix `skills/implement-feature/SKILL.md` step 10a webhook
   - Step 3b: Fix `skills/implement-feature/SKILL.md` step X webhook (if not already removed by WI-3)

4. **WI-4 (Doc Fixes)** is independent of all other items.
   - Step 4a: Fix `core/fix-verification.md`
   - Step 4b: Fix `core/state-manager.md`
   - Step 4c: Fix `state/schema.md` (e2e_test fields)
   - Step 4d: Fix `state/schema.md` (triage/code_analysis reuse note)
   - Step 4e: Fix `core/fixer-reviewer-loop.md`

### Parallelization

- WI-1 steps 1b/1c/1d can run in parallel (after 1a)
- WI-4 steps 4a-4e can all run in parallel (independent of everything)
- WI-2 and WI-3 both modify implement-feature — they should be sequential or combined into a single task

### For Each Step, Specify:

1. **File path** (absolute)
2. **Section to modify** (heading or line range)
3. **Action** (create / replace / delete)
4. **Before text** (exact current text, or "N/A" for create)
5. **After text** (exact target text)
6. **Verification** (grep command or test to confirm the change)

### Key Implementation Details

**core/tracker-subtask-creator.md structure:**
- Purpose: Extracted from the inline pseudocode
- Input Contract: ISSUE_ID, tracker_type, tracker_project, decomposition_subtasks, decomposition_yaml_path, state_json_path, tracker_effective_status, create_tracker_subtasks_config
- Process: Triple gate + the full pseudocode (idempotency, per-tracker MCP, dual store, checklist, commit, display)
- Output Contract: success_count, failure_count, created_issues list
- Failure Handling: per-subtask error isolation, never block

**Skill delegation replacement pattern:**
```markdown
### {Step}. Create tracker subtasks

Follow `core/tracker-subtask-creator.md` with these inputs:

| Input | Value |
|-------|-------|
| ISSUE_ID | `{ISSUE_ID}` |
| tracker_type | from Automation Config -> Issue Tracker -> Type |
| tracker_project | from Automation Config -> Issue Tracker -> Project |
| decomposition_subtasks | from decomposition step |
| decomposition_yaml_path | `.claude/decomposition/{ISSUE-ID}.yaml` |
| state_json_path | `.ceos-agents/{ISSUE-ID}/state.json` |
| tracker_effective_status | from MCP pre-flight |
| create_tracker_subtasks_config | from Decomposition section (default: "enabled") |
```

## Success Criteria
{{SUCCESS_CRITERIA}}:
- Plan covers all 12 acceptance criteria
- Dependencies are correctly ordered (core contract before skill refactors)
- Each step has exact before/after text for the implementation phase
- Parallelization opportunities are identified
- Total estimated scope: ~10 file modifications, 1 new file

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Planning changes to files not listed in the work items
2. Combining unrelated changes into a single step (each step should be independently verifiable)
3. Creating the core contract without including ALL content from the inline copies
4. Forgetting to update the CLAUDE.md core contract count (14 -> 15)
5. Planning behavioral changes disguised as refactoring
6. Not specifying the exact section/heading where changes occur in large files

## Codebase Context
{{CODEBASE_CONTEXT}}:
- CLAUDE.md references "14 shared pipeline pattern contracts" in core/ — must update to 15
- docs/reference/skills.md or similar may reference the contract count
- The fix-bugs contributor note `<!-- Contributor note: ... -->` must NOT be removed
- implement-feature is the largest file (~678 lines) — changes must be precisely located
- fix-ticket step 4b-tracker starts around line 207
- fix-bugs step 3b-tracker starts around line 224
- implement-feature step 5a starts around line 266
