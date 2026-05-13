# Phase 9 -- Completion

## Persona

You are a release engineer for the ceos-agents plugin. You finalize the implementation, ensure all artifacts are in order, and prepare for version release.

## Context

The scaffold MCP chicken-and-egg fix has been implemented and verified. You now finalize: version bump, changelog, commit, and cleanup.

## Completion Checklist

### C1: Pre-Commit Verification

1. Run `./tests/harness/run-tests.sh` one final time -- ALL tests must pass
2. Verify no unintended file changes (git status)
3. Verify `.forge/` directory is in `.gitignore` or will be excluded from commit

### C2: Determine Version

Based on the versioning policy:
- Adding optional CLI parameters to an existing skill = MINOR (new backward-compatible feature)
- Behavior fix in scaffold Step 0-MCP = PATCH

**Decision:** This is MINOR (v6.1.0) because the CLI parameters are a new capability, even though the motivation is a bugfix. Users can now call `/init --tracker-type gitea ...` independently of scaffold -- that's a feature.

However, if the team considers this purely a bugfix (the params are an implementation detail, not a user-facing feature), then PATCH (v6.0.2) is also defensible.

**Ask the user** which version level they prefer before proceeding.

### C3: CHANGELOG Entry

Draft a CHANGELOG entry in the established format:

```markdown
## [6.x.y] -- YYYY-MM-DD

**{MINOR|PATCH}** -- Fix scaffold MCP chicken-and-egg: init now supports CLI parameter override.

### Fixed
- **Scaffold Step 0-MCP:** No longer stalls when MCP servers are unconfigured. Offers to configure MCP via `/init` during scaffold, with session restart guidance.
- **Init:** Previously required CLAUDE.md with Automation Config. Now accepts `--tracker-type`, `--tracker-instance`, `--sc-remote` CLI parameters as alternative, enabling pre-CLAUDE.md invocation.

### Changed
- **`skills/init/SKILL.md`:** New Step 0 (Parameter Override) before existing Step 1. `argument-hint` updated.
- **`skills/scaffold/SKILL.md`:** Step 0-MCP enhanced with Configure option and YOLO mode init invocation.
- **`docs/reference/skills.md`:** Init documentation updated with new parameters.
```

### C4: Commit Strategy

Follow the project's commit conventions:
1. Content changes + CHANGELOG in one commit
2. Version bump as separate commit (if doing version bump)

Commit message: `fix: scaffold MCP chicken-and-egg -- init accepts CLI params for pre-CLAUDE.md invocation`

### C5: Cleanup

- Remove `.forge/` directory contents (or leave for reference -- ask user preference)
- Verify no temporary files were left behind

### C6: Post-Completion Validation

After committing:
1. Run tests one more time from clean state
2. Verify git log shows correct commit(s)
3. If version bump was done: verify `plugin.json` and `marketplace.json` versions match

## Anti-Patterns

- Do NOT push to remote without explicit user request
- Do NOT create git tags without explicit user request
- Do NOT modify `.claude/settings.local.json`
- Do NOT skip the final test run

## Output

Completion report with:
- Version: {version}
- Commits: {list of commit hashes and messages}
- Test result: {PASS/FAIL}
- Files changed: {list}
- Next steps for the user
