# Phase 1 — Research Questions

You are 3 parallel research agents investigating the version-check command fix. Each agent has a distinct focus area. Produce factual findings only — no recommendations yet.

---

## Agent 1: Plugin System Structure

Investigate how Claude Code's plugin system resolves and manages plugin versions.

### Questions

1. **installed_plugins.json schema:** Read `~/.claude/plugins/installed_plugins.json`. Document the exact JSON structure. What fields exist per plugin entry? Is `version` always present? Is `installPath` always present? Can there be multiple entries per plugin key (version history)?

2. **Cache directory layout:** List contents of `~/.claude/plugins/cache/`. For the `ceos-agents/ceos-agents/` subdirectory, list all version folders. Verify that NONE of them are git repos (check for `.git` directory). Document the path pattern: `cache/{marketplace-name}/{plugin-name}/{version}/`.

3. **Marketplace directory (legacy):** Check if `~/.claude/plugins/marketplaces/` exists. List its contents. For any directories found, check if they ARE git repos. Document the difference between `marketplaces/` (git clones, legacy) and `cache/` (snapshots, current).

4. **plugin.json repository field:** Read `.claude-plugin/plugin.json` from the ceos-agents repo. Is the `repository` field always present in Claude Code plugins? Check if the cache copy at `{installPath}/.claude-plugin/plugin.json` also has this field. Is the format always a git URL (`.git` suffix)?

5. **Plugin identifier format:** From `installed_plugins.json`, confirm the key format is `{plugin-name}@{marketplace-name}`. Is this documented anywhere? Can we derive the plugin name from the key?

### Output Format

For each question, provide:
- **Finding:** What you found (with exact paths, JSON snippets, directory listings)
- **Implication for version-check:** How this affects the command design

---

## Agent 2: Documentation and Cross-References

Check all files that reference version-check to understand the documentation surface.

### Questions

1. **commands/version-check.md current state:** Read the full file. Document every step. Identify the hardcoded URL on line 24. Is the 3-part structure (A/B/C) sound?

2. **docs/reference/commands.md:** Read the `/version-check` entry. Does it accurately describe the current behavior? Does it mention "works from any directory"? Does it mention `installed_plugins.json`?

3. **CHANGELOG.md v5.5.1 entry:** Read the entry. Is it accurate? Does it mention the hardcoded URL issue?

4. **Other references:** Check these files for version-check mentions:
   - `skills/workflow-router/SKILL.md`
   - `docs/guides/troubleshooting.md`
   - `commands/init.md` (closing message)
   - `README.md`
   Do any of them need updating?

5. **Version alignment:** Compare version numbers across:
   - `.claude-plugin/plugin.json` → `version`
   - `.claude-plugin/marketplace.json` → `plugins[0].version`
   - Latest git tag
   - `CHANGELOG.md` latest entry
   Are they all `5.5.1`?

### Output Format

For each question, provide:
- **Finding:** Exact content found
- **Action needed:** Whether this file needs updating (yes/no + what)

---

## Agent 3: Current version-check.md Defect Analysis

Perform a line-by-line review of the current `commands/version-check.md` looking for remaining bugs.

### Questions

1. **Hardcoded URL (line 24):** The fallback `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` is non-generic. What should happen instead when `repository` is missing? Options:
   - a) Skip remote comparison entirely (report "cannot determine remote version")
   - b) Try to infer from git remote of CWD
   - c) Error out

2. **Plugin identifier hardcoding:** Steps 1 and 6 reference `ceos-agents@ceos-agents` and `CLAUDE-agents`. Are these the ONLY hardcoded identifiers? Should the command auto-detect the plugin identifier instead?

3. **git ls-remote reliability:** Step 3 uses `git ls-remote --tags`. What if the remote requires authentication? What if there are no tags? What if tags don't follow `v*` pattern?

4. **Version comparison logic:** Step 4 says `installed_version < remote_version`. How should semver comparison work in a bash/markdown command? Is this reliable?

5. **Part B trigger:** Step 5 checks for `.claude-plugin/plugin.json` in CWD. What if you're in a subdirectory of the ceos-agents repo? Should it walk up the tree?

6. **Edge cases:**
   - Plugin installed but installPath deleted
   - installed_plugins.json doesn't exist (fresh Claude Code install)
   - Multiple versions in installed_plugins.json array for same key
   - Network timeout on git ls-remote

### Output Format

For each question, provide:
- **Current behavior:** What the command does now
- **Defect severity:** Critical / Minor / Acceptable
- **Recommendation:** What to change (brief, will be expanded in later phases)
