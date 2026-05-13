# Phase 7 — Execute

## Persona
{{PERSONA}}: Senior Claude Code Plugin Engineer with expertise in markdown pipeline definitions, state persistence, and LLM-executable instruction clarity.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Apply the following changes to `skills/implement-feature/SKILL.md`. Use the Edit tool for all changes. Do NOT modify any other files.

### Change 1: Step 5 — Add directory creation and strengthen task tree save

At Step 5 ("Decomposition decision"), find the "Save task tree" section and replace it with an expanded version that:
1. Creates the `.claude/decomposition/` directory if it doesn't exist
2. Writes the full YAML task tree with all subtask fields
3. Is explicit about what gets saved (matching fix-ticket's pattern)

Locate around line 235:
```
**Save task tree:** Write to `.claude/decomposition/{ISSUE-ID}.yaml`
```

Replace with:
```
**Save task tree:**
1. Create directory `.claude/decomposition/` if it does not exist: `mkdir -p .claude/decomposition/`
2. Write the full task tree YAML (including all subtask fields: id, title, scope, files, estimated_lines, depends_on, maps_to, acceptance_criteria, and runtime fields status=pending, commit_hash=null, restore_point=null) to `.claude/decomposition/{ISSUE-ID}.yaml`
```

### Change 2: Step 5 — Ensure state.json decomposition.subtasks includes full objects

Verify that the state.json update at Step 5 (line 237) explicitly says to write full subtask objects (not just references). The current text:

```
Update `state.json`: set `decomposition.status` to `"completed"`, write `decomposition.decision` (`"DECOMPOSE"` or `"SINGLE_PASS"`), `decomposition.strategy`, `decomposition.subtasks` list. Follow atomic write protocol from `core/state-manager.md`.
```

This is already correct in specifying the fields. Strengthen by adding "full subtask objects (mirroring the YAML)" after `decomposition.subtasks`:

```
Update `state.json`: set `decomposition.status` to `"completed"`, write `decomposition.decision` (`"DECOMPOSE"` or `"SINGLE_PASS"`), `decomposition.strategy`, `decomposition.subtasks` list (full subtask objects mirroring the YAML). Follow atomic write protocol from `core/state-manager.md`.
```

### Change 3: Step 6h — Replace vague task tree update with explicit field list

At Step 6h ("Commit subtask"), find around line 316-322:
```
Save commit_hash and restore_point to the task tree.
Update the task tree state on disk (.claude/decomposition/).
```

Replace with:
```
Update the subtask entry in `.claude/decomposition/{ISSUE-ID}.yaml`:
- Set `status` to `"completed"`
- Set `commit_hash` to the new commit SHA
- Set `restore_point` to the commit SHA of the previous subtask (or branch creation point for the first subtask)

Update `state.json`: find the matching subtask in `decomposition.subtasks` by `id`, set its `status` to `"completed"` and `commit_hash` to the new commit SHA. Follow atomic write protocol from `core/state-manager.md`.
```

### Change 4: Review confirmation flow — add Rules section note about autonomous execution

At the end of the "Rules" section (around line 413-417), add a rule clarifying the confirmation model:

```
- Confirmation points: Step 0c (card creation), Step 5 (decomposition plan + AC coverage), Step 9 (PR creation). All other steps run autonomously without user interaction. `--yolo` auto-approves all confirmation points.
```

### Verification

After applying all changes:
1. Read the modified file to verify changes are correct
2. Run `./tests/harness/run-tests.sh` to ensure tests pass
3. Verify that Step 5 now has explicit directory creation + full YAML write instructions
4. Verify that Step 6h now has explicit field names for YAML and state.json updates
5. Verify that the Rules section documents all confirmation points

## Success Criteria
{{SUCCESS_CRITERIA}}:
1. `skills/implement-feature/SKILL.md` modified with all 4 changes applied
2. No other files modified
3. Step 5 task tree save is explicit (directory creation + full field list)
4. Step 6h task tree update names exact fields (status, commit_hash, restore_point)
5. State.json write at Step 5 specifies "full subtask objects mirroring the YAML"
6. Rules section enumerates all confirmation points
7. Test suite passes

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Editing agent definitions (agents/*.md) — bug is in the skill, not the agent
2. Editing core contracts (core/*.md) — the contracts are correct; the skill doesn't follow them
3. Adding new features (tracker subtask creation, new confirmation points) beyond the bug fix
4. Breaking existing YOLO behavior or confirmation logic while fixing persistence
5. Making changes that contradict the state schema (state/schema.md)

## Codebase Context
{{CODEBASE_CONTEXT}}:
Pure markdown Claude Code plugin. Only file to edit: `skills/implement-feature/SKILL.md`.
Reference files for verification: `skills/fix-ticket/SKILL.md`, `state/schema.md`, `core/state-manager.md`.
Test suite: `tests/harness/run-tests.sh`.
