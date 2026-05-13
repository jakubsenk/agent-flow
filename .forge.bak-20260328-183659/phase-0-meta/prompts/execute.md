# Phase 7 — Execute

You are the execution agent. Apply the implementation plan from Phase 6, following the specification from Phase 4 exactly. Make no creative decisions — implement what was specified.

## Context

- Repository: `C:\gitea_ceos-agents`
- You have access to: Read, Write, Edit, Bash, Glob, Grep tools
- The primary change is to `commands/version-check.md` (remove hardcoded URL)
- Secondary changes: `docs/reference/commands.md`, `CHANGELOG.md`

## Execution Steps

### E1: Read current state of all files to be modified

Read these files in full:
1. `C:\gitea_ceos-agents\commands\version-check.md`
2. `C:\gitea_ceos-agents\docs\reference\commands.md` (the /version-check section, around line 620-640)
3. `C:\gitea_ceos-agents\CHANGELOG.md` (first 20 lines for the latest entry)

### E2: Apply changes to `commands/version-check.md`

Use the Edit tool to make the following change:

**Change 1:** Remove hardcoded URL fallback in step 3.

Find this exact text:
```
   - If repository field is missing or installPath does not exist, use the hardcoded fallback: `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git`
```

Replace with:
```
   - If repository field is missing or installPath does not exist, warn: "Cannot determine remote repository URL — skipping remote version check." and skip to step 5 (Part B).
```

Verify no other hardcoded URLs remain in the file.

### E3: Apply changes to `docs/reference/commands.md`

Update the version-check description to be accurate. Find the current description text in the /version-check section and update it to mention:
- Works from any directory
- Reads installed version from `installed_plugins.json`
- Reads remote URL from plugin's `plugin.json` `repository` field
- No hardcoded URLs

### E4: Update `CHANGELOG.md`

Amend the v5.5.1 entry OR create a new entry (per Phase 4 spec decision). The entry should note:
- Removed hardcoded URL fallback — version-check is now fully generic
- Remote URL read from plugin.json `repository` field
- Graceful skip when repository field is missing

### E5: Run structural tests

Execute the T1 tests from Phase 5:

```bash
cd C:\gitea_ceos-agents

# T1.1: No hardcoded URLs
! grep -q 'gitea.internal.ceosdata.com' commands/version-check.md && echo "T1.1 PASS" || echo "T1.1 FAIL"

# T1.3: Required sections exist
grep -q '### Part A' commands/version-check.md && echo "T1.3a PASS" || echo "T1.3a FAIL"
grep -q '### Part B' commands/version-check.md && echo "T1.3b PASS" || echo "T1.3b FAIL"
grep -q '### Part C' commands/version-check.md && echo "T1.3c PASS" || echo "T1.3c FAIL"

# T1.5: No git pull
! grep -qi 'git pull' commands/version-check.md && echo "T1.5 PASS" || echo "T1.5 FAIL"

# T1.6: References installed_plugins.json
grep -q 'installed_plugins.json' commands/version-check.md && echo "T1.6 PASS" || echo "T1.6 FAIL"

# T1.7: Graceful fallback for missing repository
grep -q 'Cannot determine remote' commands/version-check.md && echo "T1.7 PASS" || echo "T1.7 FAIL"

# T3.1: Regression guards
! grep -q 'marketplaces/ceos-agents' commands/version-check.md && echo "T3.1a PASS" || echo "T3.1a FAIL"
! grep -q 'git -C.*pull' commands/version-check.md && echo "T3.1b PASS" || echo "T3.1b FAIL"
```

### E6: Run version consistency check

```bash
cd C:\gitea_ceos-agents
PLUGIN_V=$(grep '"version"' .claude-plugin/plugin.json | head -1 | sed 's/.*"\([0-9][0-9.]*\)".*/\1/')
MARKET_V=$(grep '"version"' .claude-plugin/marketplace.json | sed 's/.*"\([0-9][0-9.]*\)".*/\1/')
echo "plugin.json: $PLUGIN_V"
echo "marketplace.json: $MARKET_V"
[ "$PLUGIN_V" = "$MARKET_V" ] && echo "VERSIONS MATCH" || echo "VERSION MISMATCH"
```

## Completion Criteria

All of the following must be true:
- [ ] `commands/version-check.md` has no hardcoded URLs
- [ ] `commands/version-check.md` has graceful fallback for missing repository field
- [ ] `docs/reference/commands.md` accurately describes version-check behavior
- [ ] `CHANGELOG.md` entry is updated
- [ ] All T1 structural tests pass
- [ ] All T3 regression guards pass
- [ ] Version numbers are consistent across plugin.json and marketplace.json

## Rules

- Use Edit tool (not Write) for modifying existing files
- Read each file before editing
- Run tests AFTER all edits are complete
- Do NOT modify plugin.json or marketplace.json version numbers (no version bump unless Phase 4 spec requires it)
- Do NOT create new files
- Do NOT modify any agent definitions
