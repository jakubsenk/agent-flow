# Phase 0 Input — version-check Bug Fix

## Task

Fix the `version-check` command in the ceos-agents Claude Code plugin. The current implementation has bugs:
1. Looked at wrong path (`~/.claude/plugins/marketplaces/ceos-agents/`) -- doesn't exist
2. Used `git pull` on cache directories that are NOT git repos (they're snapshots)
3. Was hardcoded to only work inside the ceos-agents repo directory
4. A first fix was applied but it hardcoded a repo URL -- not generic

The command must:
- Work from ANY directory (not just ceos-agents repo)
- Use `installed_plugins.json` as the authoritative source for installed version
- Be GENERIC -- this plugin could be used by other teams with their own internal plugins
- Be deterministic and reliable -- a CEO should be able to run version-check and get a clear, correct answer
- Detect legacy marketplace remnants
- Test from BOTH inside the repo AND from a different directory

## Current State

The file `commands/version-check.md` already has a partial fix applied (v5.5.1). We need to review it, fix the hardcoded URL, ensure genericity, and verify comprehensively.

## Repository Context

- `commands/version-check.md` -- the command to fix (already partially fixed)
- `commands/init.md` -- references version-check in closing message
- `.claude-plugin/plugin.json` -- contains repo version + repository URL
- `~/.claude/plugins/installed_plugins.json` -- Claude Code's authoritative plugin registry
- `~/.claude/plugins/cache/{marketplace}/{plugin}/{version}/` -- versioned snapshot directories (NOT git repos)
- `~/.claude/plugins/marketplaces/` -- old-style marketplace git clones (legacy)
- `docs/reference/commands.md` -- may reference version-check
- `CHANGELOG.md` -- needs update for the fix

## Key Facts From Investigation

- `installed_plugins.json` structure: `{"plugins": {"ceos-agents@ceos-agents": [{"version": "4.0.0", "installPath": "..."}]}}`
- Cache dirs at `~/.claude/plugins/cache/ceos-agents/ceos-agents/` contain versions: 4.0.0, 5.1.0, 5.2.0, 5.3.0, 5.4.1
- Cache dirs are NOT git repos -- `git -C` fails on them
- `~/.claude/plugins/marketplaces/CLAUDE-agents/` is a git clone of an OLD repo name (pre-rename)
- The `repository` field in `.claude-plugin/plugin.json` contains the remote URL -- use THIS instead of hardcoding
- Plugin identifier format: `{plugin-name}@{marketplace-name}`
