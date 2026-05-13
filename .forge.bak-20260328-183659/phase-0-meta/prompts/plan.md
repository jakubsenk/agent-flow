# Phase 6 — Implementation Plan

You are a planning agent. Using the specification from Phase 4 and the test design from Phase 5, produce a step-by-step implementation plan.

## Context

- Repository: `C:\gitea_ceos-agents`
- Primary file: `commands/version-check.md`
- This is a small PATCH-level fix
- The file already has a partial fix (3-part structure is correct)
- Main defect: hardcoded URL fallback on line 24

## Plan Structure

### Step 1: Pre-flight Checks

Before making any changes:
1. Run the T1 structural tests against the CURRENT file to establish a baseline
2. Verify the current version in plugin.json and marketplace.json
3. Run `git status` to confirm clean working tree

### Step 2: Edit `commands/version-check.md`

Apply the exact changes from the Phase 4 spec. The changes are:

1. **Step 3 (line 23-24):** Remove the hardcoded fallback URL. Replace with a graceful skip when `repository` field is missing.

   Current (line 24):
   ```
   - If repository field is missing or installPath does not exist, use the hardcoded fallback: `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git`
   ```

   New:
   ```
   - If repository field is missing or installPath does not exist → warn: "Cannot determine remote repository URL — skipping remote version check." Skip to Part B.
   ```

2. Review all other lines for any remaining hardcoded values or non-generic assumptions.

### Step 3: Update `docs/reference/commands.md`

Update the `/version-check` entry description to accurately reflect:
- Works from any directory
- Uses `installed_plugins.json` as authoritative source
- Reads remote URL from plugin's own `plugin.json` (no hardcoded URLs)

### Step 4: Update `CHANGELOG.md`

Either:
- Amend the v5.5.1 entry to add a note about the genericity fix
- Or create a v5.5.2 entry (depends on Phase 4 spec decision)

### Step 5: Run Tests

Execute ALL tests from Phase 5:

1. Run T1 structural tests (bash)
2. Run T3 regression guards (bash)
3. Verify T2.1 behavior (describe expected output from inside repo)
4. Verify T2.2 behavior (describe expected output from outside repo)

### Step 6: Version Consistency Check

Verify version numbers match across:
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `CHANGELOG.md` latest entry
- Latest git tag (if version was bumped)

## Estimated Effort

| Step | Time | Risk |
|------|------|------|
| Pre-flight | 2 min | None |
| Edit version-check.md | 5 min | Low — single line change |
| Update commands.md | 3 min | Low — description text |
| Update CHANGELOG.md | 3 min | Low — additive |
| Run tests | 5 min | Medium — behavioral tests need manual verification |
| Version check | 1 min | None |
| **Total** | **~19 min** | **Low** |

## Rollback Plan

If any test fails after changes:
1. `git checkout -- commands/version-check.md` to revert
2. Investigate the failure
3. Re-apply with corrections

## Dependencies

- No external dependencies
- No build step
- No other commands or agents need modification
- The change is backward-compatible (no config contract impact)
