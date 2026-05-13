---
name: version-bump
description: Bumps version in plugin.json and marketplace.json (patch/minor/major)
allowed-tools: Read, Edit, Glob, Bash
disable-model-invocation: true
argument-hint: "patch | minor | major"
---

# Version Bump

Bump the ceos-agents plugin version.

## Arguments

`$ARGUMENTS` — optional bump type: `patch` (default), `minor`, `major`.

## Pre-bump Checklist

Before running version-bump, ensure:
1. **Tests pass:** Run `./tests/harness/run-tests.sh` — all scenarios must PASS
2. **Changelog exists:** `CHANGELOG.md` must have an entry for the new version
3. **Content committed:** All feature/fix changes must be committed BEFORE version-bump. Version-bump creates its own separate commit on top.

If any of these are not done, do them first — do not skip.

## Steps

1. Verify that `.claude-plugin/plugin.json` exists in the current directory. If not → report error: "This command only works in the ceos-agents repository."
2. **Remote sync guard:** Run `git fetch origin` then compare local HEAD with `origin/main`. If local branch is behind remote → error: "Local branch is behind origin/main. Run `git pull` before bumping."
3. **Test guard:** Run `./tests/harness/run-tests.sh`. If any test fails → error: "Tests failing. Fix before bumping."
4. Read the current version from `.claude-plugin/plugin.json` (field `"version"`). Version format is `MAJOR.MINOR.PATCH`.
5. Parse `$ARGUMENTS`:
   - If empty or `patch` → bump PATCH (e.g. 3.0.1 → 3.0.2)
   - If `minor` → bump MINOR and reset PATCH to zero (e.g. 3.0.1 → 3.1.0)
   - If `major` → bump MAJOR and reset MINOR and PATCH to zero (e.g. 3.0.1 → 4.0.0)
   - If any other value → report error: "Invalid argument '$ARGUMENTS'. Use: patch, minor, major."
6. **CHANGELOG guard:** Read `CHANGELOG.md` and verify it contains a heading `## [{new_version}]` (where `{new_version}` is the version about to be set). If not found → error: "CHANGELOG.md has no entry for {new_version}. Add a changelog entry before bumping."
7. **Uncommitted changes guard:** Run `git status`. If there are uncommitted changes (staged or unstaged, excluding `.claude/settings.local.json`) → error: "Uncommitted changes detected. Commit content changes before version-bump."
8. Write the new version to `.claude-plugin/plugin.json`
9. Write the same version to `.claude-plugin/marketplace.json` (field `plugins[0].version`)
10. Commit changes:
    ```bash
    git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
    git commit -m "chore: bump version {old_version} → {new_version}"
    ```
11. Create git tag: `git tag v{new_version}`
12. Display result: "Version bumped: {old} → {new} ({type}). Tag: v{new_version}"
