# Phase 4 — Specification (Streamlined)

## Persona
{{PERSONA}}: Senior plugin architect specializing in ceos-agents state management and decomposition pipeline contracts.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

The specification IS the roadmap item from `docs/plans/roadmap.md`. This phase validates completeness rather than creating new spec.

### Requirements (from roadmap)

Port 4 persistence fixes from `implement-feature/SKILL.md` to `fix-ticket/SKILL.md`:

1. **SINGLE_PASS state.json write for `--no-decompose` path (step 4b)**
   When `decompose_mode = DISABLED`, before skipping to step 4d, write:
   - `decomposition.status` = `"completed"`
   - `decomposition.decision` = `"SINGLE_PASS"`
   - `decomposition.strategy` = `null`

2. **AUTO→SINGLE_PASS fallthrough state.json write (step 4b)**
   When AUTO mode does not indicate decomposition, before skipping to step 3d/4d, write same fields as fix 1.

3. **`mkdir -p .claude/decomposition/` before YAML write (step 4b)**
   Before first write to `.claude/decomposition/{ISSUE-ID}.yaml`, ensure directory exists.

4. **Explicit per-subtask persistence (step 4c/3c)**
   Replace vague "Save commit_hash and restore_point to the task tree" with explicit instructions:
   - Update `.claude/decomposition/{ISSUE-ID}.yaml`: set subtask `status: "completed"`, `commit_hash: {SHA}`, `restore_point: {SHA}`
   - Update `state.json`: find matching subtask in `decomposition.subtasks` by `id`, set `status: "completed"`, `commit_hash: {SHA}`

Port same 4 fixes to `fix-bugs/SKILL.md` (steps 3b, 3c — identical structure).

Update `state/schema.md`: document subtask runtime fields within `decomposition.subtasks[]`:
- `id` (string) — subtask identifier
- `title` (string) — subtask title
- `status` (string) — one of: `pending`, `in_progress`, `completed`, `failed`, `blocked`
- `commit_hash` (string or null) — git commit SHA after subtask completion
- `restore_point` (string or null) — git commit SHA before subtask started (for rollback)

### Additional requirement (discovered during Phase 0)

Also add `state.json` write for the DECOMPOSE path's decomposition save in fix-ticket step 4b and fix-bugs step 3b — matching implement-feature step 5 line 240:
- `decomposition.status` = `"completed"`
- `decomposition.decision` = `"DECOMPOSE"` or `"SINGLE_PASS"`
- `decomposition.strategy`
- `decomposition.subtasks` list

And add runtime fields to the "Save task tree" instruction:
- Include `status: "pending"`, `commit_hash: null`, `restore_point: null` per subtask in the YAML write

## Success Criteria
{{SUCCESS_CRITERIA}}:
1. All 4 fixes present in `fix-ticket/SKILL.md`
2. All 4 fixes present in `fix-bugs/SKILL.md`
3. `state/schema.md` documents all subtask runtime fields
4. All state.json writes reference `core/state-manager.md` atomic write protocol
5. Step numbers and cross-references are correct for each target file
6. No changes to `implement-feature/SKILL.md` (reference only)

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT change the implement-feature/SKILL.md reference file
- Do NOT add new config keys (this is PATCH, not MINOR)
- Do NOT change agent definitions
- Do NOT alter the decomposition heuristics logic itself — only the state persistence around it
- Do NOT copy implement-feature text verbatim — adapt step numbers and context references

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Pure markdown plugin, no build system, no runtime code
- 3 pipeline skills with decomposition: fix-ticket (steps 4a-4c), fix-bugs (steps 3a-3c), implement-feature (step 5, 6h)
- State schema: `state/schema.md`, state manager contract: `core/state-manager.md`
- Version files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- Changelog: `CHANGELOG.md`
