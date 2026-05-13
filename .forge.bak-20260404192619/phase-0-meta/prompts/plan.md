# Phase 6 — Implementation Plan (Streamlined)

## Persona
{{PERSONA}}: Senior plugin architect specializing in ceos-agents pipeline orchestration and state management.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

### Execution Order (sequential — each step depends on the previous)

#### Step 1: Fix `skills/fix-ticket/SKILL.md` — Step 4b (Decomposition Decision)

**Fix 1a — DISABLED path state write:**
After line 156 ("skip to step 4d (pre-fix hook)"), add:
```
Update `state.json`: set `decomposition.status` to `"completed"`, `decomposition.decision` to `"SINGLE_PASS"`, `decomposition.strategy` to `null`. Follow atomic write protocol from `core/state-manager.md`.
```

**Fix 1b — mkdir before YAML write:**
Change line 171 from:
```
**Save task tree to `.claude/decomposition/{ISSUE-ID}.yaml`**
```
to:
```
**Save task tree:** Create `.claude/decomposition/` if it does not exist (`mkdir -p .claude/decomposition/`). Write the full task tree (including all subtask fields and runtime fields `status: "pending"`, `commit_hash: null`, `restore_point: null`) to `.claude/decomposition/{ISSUE-ID}.yaml`.
```

**Fix 1c — DECOMPOSE state.json write:**
After the "Save task tree" instruction, add:
```
Update `state.json`: set `decomposition.status` to `"completed"`, write `decomposition.decision` (`"DECOMPOSE"` or `"SINGLE_PASS"`), `decomposition.strategy`, `decomposition.subtasks` list. Follow atomic write protocol from `core/state-manager.md`.
```

**Fix 1d — AUTO→SINGLE_PASS fallthrough:**
The current fix-ticket step 4b has no explicit AUTO→SINGLE_PASS path. After the DECOMPOSE block and AC coverage check, add the AUTO fallthrough:
```
If `decompose_mode = AUTO` and decomposition is not indicated → skip to step 4d (pre-fix hook).
Update `state.json`: set `decomposition.status` to `"completed"`, `decomposition.decision` to `"SINGLE_PASS"`, `decomposition.strategy` to `null`. Follow atomic write protocol from `core/state-manager.md`.
```

#### Step 2: Fix `skills/fix-ticket/SKILL.md` — Step 4c (Subtask Execution)

Replace line 196:
```
9. Commit subtask: `git add -A && git commit -m "fix({subtask-id}): {subtask-title}"`. Save commit_hash and restore_point to the task tree.
```
with:
```
9. Commit subtask:
   ```bash
   git add -A
   git commit -m "fix({subtask-id}): {subtask-title}"
   ```
   Update the current subtask entry in `.claude/decomposition/{ISSUE-ID}.yaml`:
   - Set `status` to `"completed"`
   - Set `commit_hash` to the new commit SHA
   - Set `restore_point` to the commit SHA before this subtask (HEAD~1 or branch creation point for first subtask)

   Update `state.json`: find the matching subtask in `decomposition.subtasks` by `id`, set its `status` to `"completed"` and `commit_hash` to the new commit SHA. Follow atomic write protocol from `core/state-manager.md`.
```

#### Step 3: Fix `skills/fix-bugs/SKILL.md` — Step 3b (Decomposition Decision)

Apply identical fixes 1a-1d but with fix-bugs step numbers:
- DISABLED path: after "skip to step 3d (pre-fix hook)"
- mkdir + runtime fields: expand the "Save task tree" line
- DECOMPOSE state.json write: after Save task tree
- AUTO→SINGLE_PASS fallthrough: after DECOMPOSE block

#### Step 4: Fix `skills/fix-bugs/SKILL.md` — Step 3c (Subtask Execution)

Apply identical fix 2 but for fix-bugs step 3c, line 185.

#### Step 5: Update `state/schema.md`

Expand the `decomposition.subtasks` row in the field definitions table. Add a new subsection "Subtask Object Fields" documenting:
- `id` (string) — subtask identifier from architect task tree
- `title` (string) — subtask title
- `status` (string) — Step Status Enum subset: `pending`, `in_progress`, `completed`, `failed`, `blocked`
- `commit_hash` (string or null) — git SHA after successful subtask commit, null while pending
- `restore_point` (string or null) — git SHA before subtask execution started, for per-subtask rollback
- `depends_on` (string[]) — IDs of prerequisite subtasks
- `scope` (string) — subtask scope description
- `files` (string[]) — files to modify
- `estimated_lines` (integer) — estimated lines changed
- `acceptance_criteria` (string[]) — per-subtask acceptance criteria
- `maps_to` (string[]) — parent AC references (format: `AC-{N}: {text}`)

#### Step 6: Version bump + changelog

- Update `.claude-plugin/plugin.json` version to `6.1.9`
- Update `.claude-plugin/marketplace.json` version to `6.1.9`
- Add `[6.1.9]` entry to `CHANGELOG.md` (before `[6.1.8]`)

## Success Criteria
{{SUCCESS_CRITERIA}}:
1. `fix-ticket/SKILL.md` step 4b has all 4 state persistence additions
2. `fix-ticket/SKILL.md` step 4c has explicit per-subtask field writes
3. `fix-bugs/SKILL.md` step 3b has all 4 state persistence additions
4. `fix-bugs/SKILL.md` step 3c has explicit per-subtask field writes
5. `state/schema.md` has Subtask Object Fields subsection with all runtime fields
6. Version bumped to 6.1.9 in both plugin files
7. Changelog entry follows existing format
8. Test suite passes (`./tests/harness/run-tests.sh`)

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT modify implement-feature/SKILL.md
- Do NOT add new config sections or keys
- Do NOT change decomposition heuristic logic — only persistence around it
- Do NOT forget the atomic write protocol reference on every state.json write
- Do NOT use implement-feature step numbers in fix-ticket/fix-bugs text

## Codebase Context
{{CODEBASE_CONTEXT}}:
- fix-ticket decomposition: steps 4a (flag parse), 4b (decision), 4c (execution)
- fix-bugs decomposition: steps 3a (flag parse), 3b (decision), 3c (execution)
- implement-feature decomposition: step 5 (decision), 6h (commit subtask) — REFERENCE
- State writes always end with "Follow atomic write protocol from `core/state-manager.md`."
