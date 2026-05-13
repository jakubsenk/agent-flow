# Agent-3: Defect Analysis — version-check command

## Full Text of commands/version-check.md (quoted verbatim)

```
---
description: Compares installed plugin version with the latest available
allowed-tools: Read, Bash
---

# Version Check

Check whether the installed ceos-agents version is up to date. Works from any directory.

## Steps

### Part A: Installed Plugin Status (always runs)

1. Read `~/.claude/plugins/installed_plugins.json`.
   - Find the entry with key `ceos-agents@ceos-agents` (the plugin identifier).
   - If not found → report "ceos-agents plugin is not installed. Run: `/plugin install ceos-agents@ceos-agents`" and STOP.
   - Read `version` and `installPath` from the entry. Store as `installed_version`.

2. Verify installPath exists on disk.
   - If it does not → warn: "Install path {path} does not exist — plugin may be broken. Reinstall with `/plugin uninstall ceos-agents` then `/plugin install ceos-agents@ceos-agents`"

3. Determine the latest available version from remote:
   - Read the `repository` field from `{installPath}/.claude-plugin/plugin.json` to get the remote URL.
   - If repository field is missing or installPath does not exist, use the hardcoded fallback: `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git`
   - Run:
     ```bash
     git ls-remote --tags {repository_url} 'refs/tags/v*' | sort -t/ -k3 -V | tail -1
     ```
   - Extract version from the tag (e.g. `refs/tags/v5.5.1` → `5.5.1`). Store as `remote_version`.
   - On network failure: warn "Failed to determine remote version" and skip remote comparison.

4. Compare and display:
   - **Up to date:** `installed_version` == `remote_version` → "ceos-agents {installed_version} — up to date"
   - **Update available:** `installed_version` < `remote_version` → "ceos-agents {installed_version} → {remote_version} — update available. Run: `/plugin uninstall ceos-agents` then `/plugin install ceos-agents@ceos-agents`"
   - **Locally newer:** `installed_version` > `remote_version` → "ceos-agents {installed_version} > {remote_version} — installed version is newer than remote"

### Part B: Repo Comparison (only when in ceos-agents repo)

5. Check if `.claude-plugin/plugin.json` exists in the current directory.
   - If not → skip Part B (not in ceos-agents repo, which is fine).
   - If yes → read `version` as `repo_version`.

6. Compare repo version with installed version:
   - **Match:** "Repo version matches installed plugin ({repo_version})"
   - **Repo is newer:** "Repo is {repo_version} but installed plugin is {installed_version} — reinstall to pick up local changes. Run: `/plugin uninstall ceos-agents` then `/plugin install ceos-agents@ceos-agents`"
   - **Repo is older:** "Repo is {repo_version} but installed plugin is {installed_version} — repo is behind"

### Part C: Cleanup Checks (always runs)

7. Check for legacy marketplace remnant:
   - Check if `~/.claude/plugins/marketplaces/CLAUDE-agents/` exists (old marketplace name before rename to ceos-agents).
   - If it exists → warn: "Legacy marketplace clone found at ~/.claude/plugins/marketplaces/CLAUDE-agents/ (version {version}). This is from the old repo name and is NOT used. Safe to delete: `rm -rf ~/.claude/plugins/marketplaces/CLAUDE-agents/`"
   - If it does not exist → skip (clean state).

## Rules

- Part A (steps 1-4) works from ANY directory — no repo dependency
- Part B (steps 5-6) only runs when CWD is the ceos-agents repository
- Part C (step 7) works from ANY directory
- All steps are read-only (report only, no auto-update)
- Plugin updates require `/plugin uninstall` + `/plugin install` — cache directories are snapshots, NOT git repos, so `git pull` does not work
- The authoritative source for installed version is `~/.claude/plugins/installed_plugins.json`, NOT the cache directory structure
```

---

## Defect Inventory

### DEF-1 — Hardcoded plugin identifier `ceos-agents@ceos-agents`
**Severity: P0 — blocks usage for any other plugin**
**Location:** Step 1 (lookup key), Step 2 (reinstall instruction), Step 4 (update instructions), Step 6 (reinstall instructions), Rules section.

The identifier `ceos-agents@ceos-agents` is a literal string baked into steps 1, 2, 4, and 6. If this command is ever published as part of a generic plugin framework or renamed, every occurrence must be manually updated. More critically, a user invoking `/version-check` from a different plugin that copies this command verbatim would look up the wrong plugin entry entirely and stop with a false "not installed" error.

The plugin name should be derived dynamically: read the `name` field from `.claude-plugin/plugin.json` in the CWD (when in a plugin repo) or from the already-resolved `installPath`. If neither is available, the identifier cannot be known and the command must fail gracefully with an explanation, not silently use a hardcoded value.

---

### DEF-2 — Hardcoded fallback repository URL
**Severity: P1 — produces wrong result for any non-ceos-agents deployment**
**Location:** Step 3, fallback line: `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git`

The fallback fires in two situations:
1. `repository` field is absent from `plugin.json`.
2. `installPath` does not exist (already flagged as broken in step 2).

In situation 1, the correct behavior is to report "Cannot determine remote URL — `repository` field missing from plugin.json" and skip the remote comparison. Using a private internal URL as a fallback means:
- Any user whose `installPath` is intact but whose `plugin.json` lacks `repository` will attempt to query `gitea.internal.ceosdata.com`, which is an internal private server inaccessible outside the author's organization.
- The `git ls-remote` call will time out or return an authentication error. The error message "Failed to determine remote version" will surface — confusing because it looks like a network problem, not a configuration problem.
- In situation 2, `installPath` is already known broken; querying the hardcoded remote produces a `remote_version` number that cannot be acted on (reinstall instructions still reference the broken path).

---

### DEF-3 — `installed_plugins.json` non-existence not handled
**Severity: P0 — unhandled failure**
**Location:** Step 1.

Step 1 says "Read `~/.claude/plugins/installed_plugins.json`" and then "Find the entry …". There is no instruction for what to do if the file itself does not exist (Claude Code not installed, first-run scenario, wrong home directory on Windows, etc.). The LLM executing this command would either throw a tool error or silently proceed with `null` data, reaching an unhandled state. The correct handling is: if the file does not exist, report "Claude Code plugin registry not found at ~/.claude/plugins/installed_plugins.json — is Claude Code installed?" and STOP.

---

### DEF-4 — Step 5 (Part B) triggers on ANY `.claude-plugin/plugin.json`, not just ceos-agents
**Severity: P1 — wrong result / misleading output**
**Location:** Step 5.

The guard condition is: "Check if `.claude-plugin/plugin.json` exists in the current directory." This file exists in the root of any Claude Code plugin repository, not only ceos-agents. If the user runs `/version-check` from the root of a different plugin's repo (one that also has `.claude-plugin/plugin.json`), Part B will execute and compare that plugin's `version` against the installed ceos-agents version, producing a spurious mismatch message like "Repo is 1.2.0 but installed plugin is 5.5.1 — reinstall to pick up local changes."

The guard should additionally check that the `name` field inside `plugin.json` matches the plugin being checked. Since the plugin name is already hardcoded (DEF-1), fixing this defect depends on first resolving DEF-1.

---

### DEF-5 — Legacy cleanup check is hardcoded to `CLAUDE-agents` directory name
**Severity: P2 — not generic, irrelevant for other users**
**Location:** Step 7.

The check for `~/.claude/plugins/marketplaces/CLAUDE-agents/` is specific to the author's personal renaming history (old repo name `CLAUDE-agents` → new name `ceos-agents`). This directory name is hardcoded and will never match for any user who did not install the old version under the old name. For all other users, the step produces no output (clean state), which is harmless but wasteful. More importantly, it cannot be generalized because the "old names" are plugin-specific history — there is no generic mechanism to know prior names. This step should be removed from any generic version of the command, or explicitly documented as ceos-agents-specific with a comment that other plugin authors must substitute their own history here.

Additionally, step 7 says to report `(version {version})` but gives no instruction for how to read the version from `~/.claude/plugins/marketplaces/CLAUDE-agents/` — the version variable is undefined at that point. The agent must guess (likely read from `plugin.json` inside that directory), but the command does not specify this.

---

### DEF-6 — Version string comparison is undefined for semantic versions
**Severity: P1 — may produce wrong result**
**Location:** Step 4.

The comparison uses `<`, `==`, `>` on version strings (e.g. "5.5.1"). String comparison of semver is incorrect: "5.10.0" < "5.9.0" lexicographically. The command does not specify how the comparison is performed. An LLM may apply string comparison and produce wrong results for minor/patch version numbers ≥ 10. The instruction should explicitly say "compare as semantic versions (major.minor.patch integers)" or provide a bash snippet using `sort -V`.

---

### DEF-7 — Reinstall instructions in Steps 2, 4, 6 hardcode the plugin identifier
**Severity: P1 — wrong result if plugin name differs**
**Location:** Steps 2, 4, 6.

All user-facing remediation messages say `/plugin uninstall ceos-agents` and `/plugin install ceos-agents@ceos-agents`. These are not derived from the installed entry — they are literal strings. If the plugin identifier or name ever changes, these instructions silently give users the wrong commands to run. The identifiers in remediation messages must be substituted from the resolved plugin name (once DEF-1 is fixed).

---

### DEF-8 — `git ls-remote` version extraction may fail on annotated tags or empty output
**Severity: P1 — may produce wrong remote_version**
**Location:** Step 3.

The pipeline `git ls-remote --tags {url} 'refs/tags/v*' | sort -t/ -k3 -V | tail -1` can produce:
- Empty output if no `v*` tags exist (new repo, no releases yet). `tail -1` returns nothing. The command must explicitly handle empty output as "no remote version available."
- Lines with `^{}` suffix for annotated tag dereferences (e.g., `abc123 refs/tags/v5.5.1^{}`). The extraction step `refs/tags/v5.5.1` → `5.5.1` works correctly if the `^{}` line sorts last, but this is not guaranteed. The command should filter out lines ending in `^{}` before sorting.

---

### DEF-9 — Part B description says "only when in ceos-agents repo" — misleading heading
**Severity: P2 — confusing UX**
**Location:** Step 5 heading: "Part B: Repo Comparison (only when in ceos-agents repo)".

The actual condition is "`.claude-plugin/plugin.json` exists in CWD" — which is true for any plugin repo, not exclusively ceos-agents (see DEF-4). The heading misleads both the executing LLM and human readers into thinking the guard is stronger than it is.

---

## Summary Table

| ID    | Severity | Description |
|-------|----------|-------------|
| DEF-1 | P0       | Plugin identifier `ceos-agents@ceos-agents` hardcoded throughout |
| DEF-2 | P1       | Fallback repository URL is a private internal URL; wrong for all other users |
| DEF-3 | P0       | No handling when `installed_plugins.json` does not exist |
| DEF-4 | P1       | Part B triggers on any plugin repo, not only ceos-agents |
| DEF-5 | P2       | Legacy cleanup check hardcoded to old `CLAUDE-agents` name; version variable undefined |
| DEF-6 | P1       | Version comparison not defined as semver; string comparison gives wrong results for ≥10 |
| DEF-7 | P1       | Remediation messages in Steps 2, 4, 6 contain hardcoded plugin identifiers |
| DEF-8 | P1       | `git ls-remote` output not guarded against empty result or `^{}` annotated tag lines |
| DEF-9 | P2       | Part B heading says "ceos-agents repo" but guard is weaker (any plugin repo) |

---

## Specific Checks

### Q1: Does the command handle `plugin.json` missing the `repository` field?

Partially, but incorrectly. Step 3 says: "If repository field is missing … use the hardcoded fallback." This means the code does not fail gracefully — it substitutes a private internal URL. The user will experience a `git ls-remote` timeout or auth failure, surfacing as the generic "Failed to determine remote version" warning with no explanation that the root cause is a missing field. Correct handling: when `repository` is absent, report "Cannot determine remote version — `repository` field is missing from {installPath}/.claude-plugin/plugin.json" and skip remote comparison entirely.

### Q2: What happens if `installed_plugins.json` doesn't exist at all?

The command provides no handling for this case. Step 1 says "Read … installed_plugins.json" without a guard. The Read tool will return an error (file not found). An LLM executing this command has no instruction for that error path and may:
- Halt with an unstructured error message.
- Proceed with null/empty data and reach step 2 or 3 in an undefined state.

This is a P0 defect (DEF-3).

### Q3: Is the plugin identifier `ceos-agents@ceos-agents` hardcoded or derived?

**Hardcoded.** It appears as a literal string in:
- Step 1: lookup key in `installed_plugins.json`
- Step 1: "not installed" error message
- Step 2: reinstall warning
- Step 4: update-available message
- Step 6: "repo is newer" message

There is no derivation logic anywhere in the command. The identifier is never read from a file, environment variable, or command argument.

### Q4: Simulation — running from `/tmp` (no `.claude-plugin/` in CWD)

**Trace through each step:**

**Step 1** — Read `~/.claude/plugins/installed_plugins.json`.
- The file is in the home directory, not CWD, so running from `/tmp` does not affect this step.
- If the file exists and contains `ceos-agents@ceos-agents`, execution proceeds normally.
- If the file does not exist → **unhandled error** (DEF-3).

**Step 2** — Verify `installPath` exists on disk.
- `installPath` comes from the registry entry, not from CWD. Unaffected by running from `/tmp`.

**Step 3** — Read `{installPath}/.claude-plugin/plugin.json`.
- Again uses `installPath` from the registry, not CWD. Unaffected.
- If `installPath` exists and its `plugin.json` has `repository`, `git ls-remote` runs normally.
- If `repository` is missing → hardcoded fallback URL fires (DEF-2).

**Step 4** — Compare and display.
- Unaffected by CWD.

**Step 5** — Check if `.claude-plugin/plugin.json` exists in CWD (`/tmp`).
- `/tmp/.claude-plugin/plugin.json` does not exist.
- Condition is false → **Part B is correctly skipped.**

**Step 6** — Skipped (Part B skipped in step 5).

**Step 7** — Check `~/.claude/plugins/marketplaces/CLAUDE-agents/`.
- Uses home directory path, not CWD. Unaffected by running from `/tmp`.

**Conclusion for `/tmp` scenario:** Part A and C work correctly (subject to other defects). Part B is correctly skipped. The `/tmp` scenario itself does not trigger new defects beyond those already catalogued. The claim "Works from any directory" in the command header is accurate for the CWD-dependency aspect only; the other defects (DEF-1 through DEF-9) still apply regardless of CWD.
