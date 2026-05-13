# Design — version-check.md Complete Rewrite

This document contains the **verbatim new content** of `commands/version-check.md`. The entire file below (between the START and END markers) is ready to be written as-is using the Write tool.

---

## START OF FILE: `commands/version-check.md`

```markdown
---
description: Compares installed plugin version with the latest available
allowed-tools: Read, Bash
---

# Version Check

Check whether the installed plugin version is up to date. Works from any directory.

## Plugin Identity

| Key | Value |
|-----|-------|
| Plugin | ceos-agents |
| Marketplace | ceos-agents |

All steps below use `{plugin}` and `{marketplace}` from this table.
When searching `installed_plugins.json`, find the key `{plugin}@{marketplace}`.

## Steps

### Part A: Installed Plugin Status (always runs)

1. Read `~/.claude/plugins/installed_plugins.json`.
   - If the file does not exist → report: "Claude Code plugin registry not found at `~/.claude/plugins/installed_plugins.json`. No plugins installed — run `/plugin install` first." and STOP.
   - If the file is empty or is not valid JSON → report: "Plugin registry at `~/.claude/plugins/installed_plugins.json` is empty or corrupt — cannot parse." and STOP.
   - Find the entry with key `{plugin}@{marketplace}`.
   - If no matching key found → report: "{plugin} plugin is not installed. Run: `/plugin install {plugin}@{marketplace}`" and STOP.
   - Read `version` and `installPath` from the entry. Store as `installed_version` and `install_path`.

2. Verify `install_path` exists on disk.
   - If it does not exist → warn: "Install path `{install_path}` does not exist — plugin may need reinstalling. Run: `/plugin uninstall {plugin}` then `/plugin install {plugin}@{marketplace}`". Continue to step 3.

3. Determine the latest available version from remote.
   - Read `{install_path}/.claude-plugin/plugin.json` and extract the `repository` field.
   - If `install_path` does not exist on disk (from step 2), OR the file cannot be read, OR the `repository` field is missing or empty → report: "Remote version check skipped — no `repository` field available in plugin.json." Skip to step 4 (show installed version only).
   - Run:
     ```bash
     timeout 10 git ls-remote --tags {repository} 'refs/tags/v*' 2>/dev/null | grep -v '\^{}' | sort -t/ -k3 -V | tail -1
     ```
     If `timeout` is not available, omit it and run `git ls-remote` directly.
   - If the command fails (network error, authentication failure, timeout) → report: "Cannot reach remote repository. Showing installed version only." Skip to step 4.
   - If the output is empty (no tags, or no tags matching `v*`) → report: "No version tags found on remote repository. Showing installed version only." Skip to step 4.
   - Extract the version string from the tag reference (e.g., `refs/tags/v5.5.1` → `5.5.1`). Store as `remote_version`.

4. Compare and display.
   - If `remote_version` is not available (skipped in step 3) → display: "{plugin} {installed_version} (installed) — remote version unknown" and proceed to Part B.
   - Compare `installed_version` and `remote_version` as semantic versions: split each on `.` and compare each component (major, minor, patch) as integers — NOT as strings. To determine which version is smaller, use:
     ```bash
     printf '%s\n' "$installed_version" "$remote_version" | sort -V | head -1
     ```
     If the result equals `$installed_version` and `$installed_version` != `$remote_version`, then `remote_version` is newer.
   - **Up to date:** `installed_version` == `remote_version` → "{plugin} {installed_version} — up to date"
   - **Update available:** `installed_version` < `remote_version` → "{plugin} {installed_version} → {remote_version} — update available. Run: `/plugin uninstall {plugin}` then `/plugin install {plugin}@{marketplace}`"
   - **Locally newer:** `installed_version` > `remote_version` → "{plugin} {installed_version} > {remote_version} — installed version is newer than remote"

### Part B: Repo Comparison (conditional — only when CWD is the plugin's own repo)

5. Check if `.claude-plugin/plugin.json` exists in the current working directory.
   - If not present → skip Part B silently (not in any plugin repo).
   - If present → read the `name` field from it.
   - If `name` does not equal `{plugin}` → skip Part B silently (CWD is a different plugin's repo).
   - If `name` equals `{plugin}` → read `version` from the same file. Store as `repo_version`.

6. Compare `repo_version` with `installed_version`.
   - Use the same semantic version comparison as step 4.
   - **Match:** "Repo version matches installed plugin ({repo_version})"
   - **Repo is newer:** "Repo is {repo_version} but installed plugin is {installed_version} — reinstall to pick up local changes. Run: `/plugin uninstall {plugin}` then `/plugin install {plugin}@{marketplace}`"
   - **Repo is older:** "Repo is {repo_version} but installed plugin is {installed_version} — repo is behind installed version"

## Rules

- Part A (steps 1-4) works from ANY directory — no repo or project dependency
- Part B (steps 5-6) only activates when CWD contains `.claude-plugin/plugin.json` whose `name` field matches the Plugin Identity
- All steps are read-only — report only, never auto-update, never run git pull
- Plugin updates require `/plugin uninstall` + `/plugin install` — cache directories are snapshots, NOT git repos
- The authoritative source for the installed version is `~/.claude/plugins/installed_plugins.json`, NOT the cache directory structure
- The authoritative source for the remote URL is the `repository` field in `{install_path}/.claude-plugin/plugin.json` — never use a hardcoded URL
- When any step fails or data is unavailable, report clearly what was skipped and why, then continue with what is available — never halt silently
```

## END OF FILE

---

## Design Rationale

### Plugin Identity Table

The table at the top is the single declaration point for the plugin's own name and marketplace name. Every step references `{plugin}` and `{marketplace}` from this table. To adapt this command for a different plugin, change exactly two values in the table. No other line in the file contains a literal plugin name.

### Two-Part Structure

- **Part A** is the core value: "is my installed version current?" This works from any directory.
- **Part B** is a developer convenience: "does my local repo match what's installed?" This only fires when the developer is actively working in the plugin's source repo.
- **No Part C**: The legacy `CLAUDE-agents` cleanup was a one-time author artifact. It has been removed entirely.

### Error Handling Strategy

Every conditional branch has an explicit message and action (STOP, skip, warn+continue). There are 10 distinct error paths, all enumerated in the steps. The LLM executing this command has no ambiguous states to improvise through.

### Semver Comparison

Both the conceptual explanation ("split on `.`, compare as integers") and the bash one-liner (`sort -V`) are provided. This gives the LLM two independent ways to get the comparison right, reducing the chance of string-comparison bugs.

### Remote Tag Parsing

The pipeline `timeout 10 git ls-remote --tags {repository} 'refs/tags/v*' 2>/dev/null | grep -v '\^{}' | sort -t/ -k3 -V | tail -1` addresses four issues from the defect registry:
1. `timeout 10` prevents hangs on unreachable hosts
2. `2>/dev/null` suppresses stderr noise
3. `grep -v '\^{}'` filters annotated tag dereference lines
4. Empty output is explicitly guarded after the pipeline
