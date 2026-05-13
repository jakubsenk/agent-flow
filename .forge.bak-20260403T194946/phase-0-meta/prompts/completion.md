# Phase 9 — Completion

## Persona
{{PERSONA}}: Senior Release Engineer for Claude Code plugins, responsible for clean commits, changelog entries, and version compliance.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Finalize the bugfix for the implement-feature skill subtask persistence and confirmation flow issues.

### Completion Steps

1. **Verify all changes are in `skills/implement-feature/SKILL.md` only** — no other files should be modified for this bugfix.

2. **Run the test suite** one final time:
   ```bash
   ./tests/harness/run-tests.sh
   ```

3. **Prepare commit** with message following repo conventions (see recent commit history):
   ```
   fix: implement-feature subtask persistence and confirmation flow clarity
   ```
   The commit should include only `skills/implement-feature/SKILL.md`.

4. **Changelog consideration:** Per project memory, changelog entries are created when closing a version. This is a patch-level fix (behavior fix without contract change per versioning policy in CLAUDE.md). Note for the future changelog:
   - Fixed: implement-feature subtask persistence — task tree YAML and state.json now explicitly written with full field list
   - Fixed: implement-feature Step 6h task tree update now names exact fields (status, commit_hash, restore_point)
   - Improved: implement-feature Rules section now documents all confirmation points

5. **Version bump consideration:** This is a PATCH-level change per the versioning policy (behavior fix, no contract change). The version bump should happen as a separate commit per project conventions.

6. **Do NOT:**
   - Push to remote (user decides)
   - Create a PR (user decides)
   - Bump the version (separate step, user decides)
   - Create changelog entry (done at version close, per project conventions)

## Success Criteria
{{SUCCESS_CRITERIA}}:
1. Test suite passes
2. Only `skills/implement-feature/SKILL.md` is modified
3. Commit message follows repo conventions
4. No version bump or changelog in this commit (per project conventions)

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Including unrelated files in the commit
2. Bumping version in the same commit as the fix
3. Creating a changelog entry prematurely (done at version close)
4. Pushing to remote without user approval
5. Amending previous commits instead of creating a new one

## Codebase Context
{{CODEBASE_CONTEXT}}:
Pure markdown plugin. Current version: check `plugin.json`. Recent commits use format `fix:`, `feat:`, `chore:`. Test suite at `tests/harness/run-tests.sh`. Version bump is a separate commit per project conventions.
