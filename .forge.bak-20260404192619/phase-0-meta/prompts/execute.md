# Phase 7 — Execute

## Persona
{{PERSONA}}: Senior plugin engineer executing a mechanical port of decomposition persistence fixes across ceos-agents pipeline skills.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Execute the 6-step plan from Phase 6. All changes are to markdown files in a pure markdown plugin.

### Step-by-step execution

**1. Edit `skills/fix-ticket/SKILL.md` — Step 4b (Decomposition Decision)**

Read the current step 4b. Apply these changes:

a) After the DISABLED line ("skip to step 4d"), insert the state.json write block matching implement-feature step 5 line 196.

b) Expand the "Save task tree" line to include `mkdir -p`, runtime fields, matching implement-feature step 5 line 238.

c) After the expanded Save task tree, add the DECOMPOSE state.json write matching implement-feature step 5 line 240.

d) Add the AUTO→SINGLE_PASS fallthrough with state.json write, matching implement-feature step 5 lines 242-243.

**2. Edit `skills/fix-ticket/SKILL.md` — Step 4c (Subtask Execution)**

Replace the single-line commit instruction (line 9 in the subtask loop) with the expanded version matching implement-feature step 6h lines 322-332. Use `fix({subtask-id})` prefix (not `feat`).

**3. Edit `skills/fix-bugs/SKILL.md` — Step 3b (Decomposition Decision)**

Apply identical changes as step 1, but:
- Step reference is "3d" instead of "4d"
- Everything else is identical pattern

**4. Edit `skills/fix-bugs/SKILL.md` — Step 3c (Subtask Execution)**

Apply identical change as step 2, but for fix-bugs step 3c.

**5. Edit `state/schema.md`**

After the `decomposition.strategy` row in the field definitions table, add a "Subtask Object Fields" subsection documenting all fields within each `decomposition.subtasks[]` object.

**6. Version bump + changelog**

- Edit `.claude-plugin/plugin.json`: change version from "6.1.8" to "6.1.9"
- Edit `.claude-plugin/marketplace.json`: change version from "6.1.8" to "6.1.9"
- Edit `CHANGELOG.md`: add `[6.1.9]` entry before `[6.1.8]`

### Implementation rules

- Preserve exact markdown formatting of the target files
- Every state.json write MUST end with "Follow atomic write protocol from `core/state-manager.md`."
- Use `fix(` prefix in fix-ticket/fix-bugs commit messages (not `feat(`)
- Match the indentation and section heading levels of surrounding content
- Do NOT modify any file not listed in the plan

## Success Criteria
{{SUCCESS_CRITERIA}}:
1. All 4 persistence fixes present in fix-ticket step 4b
2. Explicit per-subtask writes in fix-ticket step 4c
3. All 4 persistence fixes present in fix-bugs step 3b
4. Explicit per-subtask writes in fix-bugs step 3c
5. Subtask Object Fields documented in state/schema.md
6. Version = 6.1.9 in both plugin files
7. Changelog entry present and correctly formatted
8. No changes to implement-feature/SKILL.md
9. Test suite passes

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Forgetting the atomic write protocol reference
- Using implement-feature step numbers in fix-ticket/fix-bugs text
- Breaking existing markdown structure (heading levels, code blocks)
- Modifying decomposition heuristic logic
- Adding new config keys or sections
- Copying implement-feature text verbatim without adapting context (e.g., "spec-analyst" should be "triage" in fix-ticket)

## Codebase Context
{{CODEBASE_CONTEXT}}:
- `skills/fix-ticket/SKILL.md`: 394 lines, decomposition at steps 4a-4c
- `skills/fix-bugs/SKILL.md`: decomposition at steps 3a-3c
- `skills/implement-feature/SKILL.md`: REFERENCE ONLY (do not edit), decomposition at step 5, commit at step 6h
- `state/schema.md`: field definitions table starting at line 135
- `.claude-plugin/plugin.json`: version at line 4
- `.claude-plugin/marketplace.json`: version at line 10
- `CHANGELOG.md`: newest entry at top (after header)
