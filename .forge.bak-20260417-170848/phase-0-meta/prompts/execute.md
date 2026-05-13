# Phase 7: Execution — v6.7.2 Pipeline Consistency & Dedup

## Persona
{{PERSONA}}: You are a **precision markdown editor** implementing an exact specification. You make only the changes specified in the plan, verify each change, and ensure no unintended side effects.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Implement all changes from the Phase 6 plan. Execute in dependency order:

### Task Group 1: Core Contract Creation (must be first)

**Task 1a: Create `core/tracker-subtask-creator.md`**
- Create the new core contract file
- Content extracted from the inline pseudocode in the 3 skills
- Follow standard core contract structure: Purpose, Input Contract, Process, Output Contract, Failure Handling
- Include the Per-Tracker Issue Creation Parameters table
- Include the Issue Description Template
- Include the `core/mcp-body-formatting.md` reference

### Task Group 2: Skill Refactors (after Task 1a, parallelizable)

**Task 2a: Refactor `skills/fix-ticket/SKILL.md` step 4b-tracker**
- Replace the inline pseudocode (~153 lines) with delegation to `core/tracker-subtask-creator.md`
- Keep the step header and any skill-specific context
- Provide the input values table

**Task 2b: Refactor `skills/fix-bugs/SKILL.md` step 3b-tracker**
- Same pattern as 2a
- Preserve the `<!-- Contributor note:` comment (it's about state.json writes, not tracker subtasks)

**Task 2c: Refactor `skills/implement-feature/SKILL.md` step 5a**
- Same pattern as 2a
- Also fix step 10a webhook (WI-2) and step X block handler (WI-3) while editing this file

### Task Group 3: implement-feature Cleanup (can be combined with 2c)

**Task 3a: Fix webhook in step 10a**
- Change `"issue":"{issue_id}"` to `"issue_id":"{issue_id}"`
- Change `"pr":"{pr_url}"` to `"pr_url":"{pr_url}"`
- Add `--max-time 5 --retry 0` flags
- Add `"timestamp":"{ISO8601}"`

**Task 3b: Remove inline block handler from step X**
- Remove the inline 6-step procedure
- Keep only the "Follow `core/block-handler.md`" reference
- Keep the state.json update instruction (skill-specific)

**Task 3c: Fix webhook in step X**
- Change `"issue":"{issue_id}"` to `"issue_id":"{issue_id}"`
- Add `--max-time 5 --retry 0` flags
- Add `"timestamp":"{ISO8601}"`

### Task Group 4: Doc Fixes (independent, parallelizable)

**Task 4a: `core/fix-verification.md`** — mode-neutral title
**Task 4b: `core/state-manager.md`** — inline heuristic replacing forward reference
**Task 4c: `state/schema.md`** — add e2e_test fields (verdict, result_path, attempts)
**Task 4d: `state/schema.md`** — add triage/code_analysis field reuse note
**Task 4e: `core/fixer-reviewer-loop.md`** — list all 3 pipeline skills for NEEDS_DECOMPOSITION

### Task Group 5: Cross-References

**Task 5a: Update CLAUDE.md** — change "14 shared pipeline pattern contracts" to "15"
**Task 5b: Check docs/ for stale contract counts** — grep for "14" near "core" or "contract"

### Verification After Each Task

- Read the modified file to confirm the change
- Run `grep` to verify presence/absence of key markers
- Ensure no unintended changes to surrounding content

## Success Criteria
{{SUCCESS_CRITERIA}}:
- All 12 acceptance criteria from the spec are met
- `core/tracker-subtask-creator.md` exists with correct structure
- All 3 skills delegate to the core contract (no inline pseudocode)
- All webhook calls use canonical format
- implement-feature step X has no inline block procedure
- All 5 doc fixes applied
- No content loss (all tracker types, idempotency, checklist patterns preserved)
- CLAUDE.md updated to reflect 15 core contracts

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Making changes beyond what the spec requires
2. Reformatting or restructuring content that wasn't flagged for change
3. Accidentally deleting the fix-bugs contributor note comment
4. Forgetting to include ALL 6 tracker types in the core contract
5. Leaving orphaned references to the removed inline code
6. Breaking markdown heading hierarchy
7. Changing step numbers in other steps when removing inline content

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Use the Edit tool for surgical changes to existing files
- Use the Write tool only for the new core contract file
- The 3 skill files are large (400-800 lines) — be precise about which section to modify
- After editing implement-feature, verify that step X still has a coherent heading and content
- The core contract should be ~180-200 lines (the extracted pseudocode plus Input/Output/Failure sections)
