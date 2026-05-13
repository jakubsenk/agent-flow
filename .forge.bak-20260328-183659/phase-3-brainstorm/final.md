# Phase 3 Brainstorm Synthesis -- Judge Ruling

## Consensus

All three agents agree on the following without reservation:

| # | Decision | All 3 Agree |
|---|----------|-------------|
| 1 | Remove hardcoded fallback URL (`https://gitea.internal.ceosdata.com/...`) entirely | YES -- security concern, fails for all non-author users |
| 2 | When `repository` field is absent, skip remote comparison with clear message | YES -- no silent fallback, no guessing |
| 3 | Guard against missing `installed_plugins.json` at Step 1 (DEF-3, P0) | YES -- all three flagged this independently as the top missing defect |
| 4 | Fix `git ls-remote` to filter `^{}` annotated tag dereference lines (DEF-8) | YES -- `grep -v '\^{}'` before sort |
| 5 | Fix semver comparison to be numeric, not lexicographic (DEF-6) | YES -- `"5.10.0" < "5.9.0"` is wrong with string comparison |
| 6 | Guard for empty `git ls-remote` output (zero tags or no matching `v*` tags) | YES -- report "No version tags found" and skip |
| 7 | Part B must validate CWD's plugin name against the target plugin name (DEF-4, DEF-9) | YES -- prevents false matches when CWD is a different plugin repo |
| 8 | All steps remain read-only; no auto-update, no git pull | YES |
| 9 | No new config keys, no new commands, no contract changes -- this is a PATCH | YES |

---

## Resolved Disagreements

### 1. Plugin Identity: Hardcoded String vs Plugin Identity Table vs Runtime Derivation vs Argument

**Pragmatist:** Use `ceos-agents` as a self-referencing constant. It IS the plugin. Searching `installed_plugins.json` for a key starting with `ceos-agents@` is a self-reference, not a hardcode. If the plugin gets renamed, you update the one reference.

**Architect:** Create a `## Plugin Identity` table at the top with `| Plugin name | ceos-agents |`. All steps reference this table. One-field change for anyone copying the template. Also add an optional argument to override the identity for checking other plugins.

**QA Engineer:** Does not care about the mechanism -- cares that whichever mechanism is chosen is tested for the "different plugin repo" case and the "renamed plugin" case.

**RULING: Plugin Identity table. No argument override.**

Rationale:
- The Architect's table is the right abstraction. It is a single, clearly-marked declaration point that any plugin author can change. It costs nothing (3 lines of markdown) and eliminates every scattered `ceos-agents` literal from the Steps section.
- The Pragmatist's concern about over-engineering is valid, but a table is not engineering -- it is documentation. The steps already need to reference the plugin name in 6+ places; a variable is cleaner than 6 literals.
- The Architect's optional argument override is **rejected**. It is scope creep. version-check is "am I up to date?" for the plugin that provides it. Checking OTHER plugins is a different command (`/plugin-status` or similar). The Pragmatist is right that this is a use case nobody has asked for, and it adds untestable complexity (how do you find the installPath for a plugin you don't control?).
- Runtime derivation (reading own plugin.json from install path) is **rejected**. All three agents acknowledged the bootstrap problem: a markdown command has no `__FILE__`. The Pragmatist correctly identified this as circular. The Plugin Identity table is the honest solution.

### 2. Legacy Cleanup (Part C): Keep, Remove, or Make Generic

**Pragmatist:** Remove entirely. It is one author's one-time artifact.

**Architect:** Remove from generic template. Optionally keep as a clearly-marked non-generic section, or replace with a generic "orphaned cache" check.

**QA Engineer:** Tests 23-24 in the matrix test it. Implicitly expects it to exist.

**RULING: Remove Part C entirely.**

Rationale:
- The Pragmatist is right. The `CLAUDE-agents` check is a personal migration artifact with zero value for any other user. It references an undefined `{version}` variable (DEF-5). It hardcodes a directory name.
- The Architect's "orphaned cache cleanup" idea is interesting but is a new feature, not a bug fix. Out of scope.
- QA Engineer's tests 23-24 become N/A. The test matrix is updated accordingly (see below).
- The author can run `rm -rf ~/.claude/plugins/marketplaces/CLAUDE-agents/` once. Done.

### 3. Semver Comparison: Explicit Instruction vs Bash `sort -V`

**Pragmatist:** Add explicit instruction to the markdown: "split on `.`, compare each component as integers."

**Architect:** Use a bash `sort -V` pipeline: `printf '%s\n' "$a" "$b" | sort -V | head -1` to delegate to coreutils.

**QA Engineer:** Does not prescribe a method. Demands it works for `5.10.0 vs 5.9.0` and `5.5.10 vs 5.5.9`.

**RULING: Explicit instruction in the markdown spec, with a bash `sort -V` one-liner as the recommended implementation.**

Rationale:
- The command is a markdown spec interpreted by an LLM. The LLM needs BOTH: the explicit instruction ("compare as semantic versions: split on `.`, compare each component as integers, major then minor then patch") gives the LLM the conceptual framework; the `sort -V` one-liner gives it a deterministic implementation to copy.
- Using only `sort -V` without the explanation risks the LLM misunderstanding which value is "lower." Using only the explanation without `sort -V` risks the LLM doing string comparison anyway.
- Note: `sort -V` is GNU coreutils. On macOS without Homebrew this may not exist. However, the command already uses `sort -t/ -k3 -V` for tag sorting, so this is an existing dependency. The LLM can also implement the comparison in bash arithmetic as a fallback.

### 4. Timeout on `git ls-remote`

**QA Engineer:** Add `timeout 10` before `git ls-remote`. Hard requirement.

**Pragmatist:** Not mentioned explicitly.

**Architect:** Not mentioned explicitly.

**RULING: Adopt `timeout 10` from QA Engineer.**

Rationale:
- The QA Engineer is right. A CEO running a quick status check should not wait 30+ seconds for a hung SSH connection. `timeout 10` is trivial to add and has no downside.
- On Windows (the current dev platform), `timeout` as a coreutil may not exist. However, Claude Code's bash environment (Git Bash or similar) typically provides it. The spec should note: "Use `timeout 10` if available; if not, proceed without timeout."
- Also adopt `2>/dev/null` on stderr to prevent the LLM from interpreting git error messages as version data.

### 5. Empty/Corrupt `installed_plugins.json`

**QA Engineer:** Tests 5 and 6 cover empty file and invalid JSON.

**Pragmatist:** Mentioned the file-not-found case but not empty/corrupt.

**Architect:** Mentioned file-not-found only.

**RULING: Guard for three states: (1) file does not exist, (2) file is empty or not valid JSON, (3) file is valid but plugin not found. All produce distinct, clear messages and STOP.**

Rationale: The QA Engineer's exhaustive testing exposed that "file exists but is empty" and "file exists but is invalid JSON" are distinct failure modes from "file does not exist." All three must be handled because the LLM will improvise badly if the spec is silent.

---

## Adopted Design

### Plugin Identity

The command declares its own identity in a table at the top of the Steps section. All subsequent steps reference `{plugin_name}` from this table.

```markdown
## Plugin Identity

| Key | Value |
|-----|-------|
| Plugin name | ceos-agents |

All steps below use `{plugin_name}` from this table.
When searching `installed_plugins.json`, find the key that starts with `{plugin_name}@`.
```

No argument override. No runtime derivation. One field, one place.

### Command Structure

```
---
description: Compares installed plugin version with the latest available
allowed-tools: Read, Bash
---

# Version Check

## Plugin Identity
(table as above)

## Steps

### Part A: Installed Plugin Status (always runs)

Step 1: Read installed_plugins.json
  - Guard: file missing -> message + STOP
  - Guard: file empty/corrupt -> message + STOP
  - Search for key starting with {plugin_name}@
  - Guard: no match -> "not installed" + STOP
  - Guard: multiple matches -> list them + STOP
  - Extract version, installPath

Step 2: Verify installPath exists on disk
  - Guard: missing -> warning + reinstall hint (continue to step 3)

Step 3: Determine remote version
  - Read repository from {installPath}/.claude-plugin/plugin.json
  - Guard: repository missing -> "Remote check skipped" (skip to step 4)
  - Run: timeout 10 git ls-remote --tags {repo} 'refs/tags/v*' 2>/dev/null | grep -v '\^{}' | sort -t/ -k3 -V | tail -1
  - Guard: empty output -> "No version tags found" (skip comparison)
  - Extract version string

Step 4: Compare and display
  - Compare as semantic versions: split on '.', compare each component as integer
  - Use: printf '%s\n' "$installed" "$remote" | sort -V | head -1
  - Three outcomes: up to date / update available / locally newer

### Part B: Repo Comparison (conditional)

Step 5: Check CWD for .claude-plugin/plugin.json
  - If not present -> skip Part B
  - If present, read name field
  - If name != {plugin_name} -> skip Part B (different plugin repo)
  - If name == {plugin_name} -> read version as repo_version

Step 6: Compare repo_version with installed_version
  - Three outcomes: match / repo newer / repo older

## Rules
(read-only, works from any directory, cache dirs are snapshots not git repos, etc.)
```

Part C is removed entirely.

### Error Handling

Complete list of error paths:

| Condition | Message | Action |
|-----------|---------|--------|
| `installed_plugins.json` does not exist | "Claude Code plugin registry not found at ~/.claude/plugins/installed_plugins.json -- has any plugin been installed?" | STOP |
| `installed_plugins.json` is empty or invalid JSON | "Plugin registry is empty or corrupt -- cannot parse." | STOP |
| No key starting with `{plugin_name}@` found | "{plugin_name} plugin is not installed. Run: /plugin install {plugin_name}" | STOP |
| Multiple keys match `{plugin_name}@` prefix | "Multiple entries found for {plugin_name}: {list}. Cannot determine which to check." | STOP |
| `installPath` does not exist on disk | "Install path {path} does not exist -- plugin may be broken. Reinstall recommended." | WARN, continue to step 3 |
| `repository` field missing from plugin.json | "Remote check skipped -- no repository field in plugin.json." | Skip remote, show installed version only |
| `git ls-remote` fails (network, auth, timeout) | "Failed to determine remote version (network/auth error). Skipping remote comparison." | Skip remote, show installed version only |
| `git ls-remote` returns empty (no tags or no `v*` tags) | "No version tags found on remote. Skipping remote comparison." | Skip remote, show installed version only |
| CWD has `.claude-plugin/plugin.json` but name does not match | (no message) | Silently skip Part B |
| CWD does not have `.claude-plugin/plugin.json` | (no message) | Silently skip Part B |

### Version Comparison

The spec must include BOTH:

1. **Conceptual instruction:** "Compare versions as semantic versions: split on `.` and compare each component as an integer -- major first, then minor, then patch. Do NOT use string/lexicographic comparison."

2. **Bash implementation hint:** "To compare two versions deterministically, use: `printf '%s\n' \"$v1\" \"$v2\" | sort -V | head -1`. If the result equals `$v1` and `$v1` != `$v2`, then `$v2` is newer."

### Remote Tag Parsing

The full pipeline:

```bash
timeout 10 git ls-remote --tags {repository_url} 'refs/tags/v*' 2>/dev/null | grep -v '\^{}' | sort -t/ -k3 -V | tail -1
```

Changes from current:
- Added `timeout 10` (QA Engineer)
- Added `grep -v '\^{}'` to filter annotated tag dereferences (all 3 agents)
- Added `2>/dev/null` to suppress stderr noise (QA Engineer)
- Added empty-output guard after the pipeline (all 3 agents)

### Legacy Cleanup

**Removed.** Part C is deleted entirely. The command has two parts: Part A (installed plugin status, always runs) and Part B (repo comparison, conditional on CWD).

### Test Matrix

Adopted from QA Engineer with modifications (Part C tests removed, numbering adjusted):

| # | Scenario | CWD | Preconditions | Expected Output |
|---|----------|-----|---------------|-----------------|
| 1 | Happy path, up to date | /tmp | installed 5.5.1, remote v5.5.1 | "{plugin_name} 5.5.1 -- up to date" |
| 2 | Update available | /tmp | installed 5.4.1, remote v5.5.1 | "{plugin_name} 5.4.1 -> 5.5.1 -- update available" |
| 3 | Locally newer | /tmp | installed 5.6.0, remote v5.5.1 | "{plugin_name} 5.6.0 > 5.5.1 -- installed is newer" |
| 4 | installed_plugins.json missing | /tmp | file absent | "Plugin registry not found..." STOP |
| 5 | installed_plugins.json empty | /tmp | 0 bytes | "Plugin registry is empty or corrupt" STOP |
| 6 | installed_plugins.json invalid JSON | /tmp | `{broken` | "Plugin registry is empty or corrupt" STOP |
| 7 | Plugin not in registry | /tmp | file valid, no matching key | "{plugin_name} is not installed" STOP |
| 8 | installPath missing on disk | /tmp | points to deleted dir | Warning + continue |
| 9 | No repository field | /tmp | valid entry, no repo URL | "Remote check skipped" + installed version only |
| 10 | Network down | /tmp | valid entry | "Failed to determine remote version" + installed version only |
| 11 | git ls-remote timeout | /tmp | unreachable host | Same as #10 (timeout 10 triggers) |
| 12 | Zero tags on remote | /tmp | valid entry, no tags | "No version tags found" + installed version only |
| 13 | Tags exist but none match v* | /tmp | tags like `release-1.0` | Same as #12 |
| 14 | Annotated tags with ^{} | /tmp | v5.5.1 + v5.5.1^{} | Filters ^{}, shows 5.5.1 correctly |
| 15 | Semver: 5.10.0 vs 5.9.0 | /tmp | installed 5.9.0, remote v5.10.0 | "update available" (NOT "up to date") |
| 16 | Semver: 5.5.10 vs 5.5.9 | /tmp | installed 5.5.9, remote v5.5.10 | "update available" |
| 17 | In plugin repo, versions match | plugin repo | installed 5.5.1, repo 5.5.1 | Part A + Part B: "Repo version matches" |
| 18 | In plugin repo, repo newer | plugin repo | installed 5.4.1, repo 5.5.1 | Part A + Part B: "Repo is newer, reinstall" |
| 19 | In different plugin's repo | other repo | installed 5.5.1 | Part A only, Part B silently skipped |
| 20 | In subdirectory of plugin repo | plugin/agents/ | installed 5.5.1 | Part A only, Part B skipped (no plugin.json in CWD) |
| 21 | SSH remote with auth failure | /tmp | repo URL is git@... | "Failed to determine remote version" + installed only |
| 22 | Multiple registry entries | /tmp | two entries for {plugin_name}@ | List entries, ask user to specify, STOP |

Tests 23-24 (legacy cleanup) are removed since Part C is removed.

---

## Divergence Assessment

```json
{
  "divergence_class": "REFINED",
  "original_keywords": [
    "remove-hardcoded-url",
    "generic-plugin-check",
    "installed-plugins-json",
    "legacy-cleanup",
    "repo-comparison",
    "semver-comparison"
  ],
  "recommended_keywords": [
    "plugin-identity-table",
    "remove-hardcoded-url",
    "installed-plugins-json-guards",
    "remove-legacy-cleanup",
    "repo-comparison-name-match",
    "semver-numeric-comparison",
    "annotated-tag-filtering",
    "git-ls-remote-timeout",
    "graceful-degradation"
  ],
  "keyword_overlap_score": 0.55
}
```

The original input focused on "remove hardcoded URL + make generic." The brainstorm refined this into a more precise set of 9 concrete fixes. The scope did not pivot (still a single-file PATCH to `commands/version-check.md`), but the definition of "done" expanded from "remove one URL" to "handle every failure mode the spec is currently silent on." This is REFINED, not PIVOTED -- the destination is the same, the path is better specified.

---

## GO/NO-GO

**GO.**

All three agents converged on the same core fixes. The disagreements were matters of degree (how generic? how much testing?), not direction. The adopted design is:

- **Scope:** Single file rewrite (`commands/version-check.md`), plus minor doc updates.
- **Risk:** Low. This is a markdown spec, not executable code. The changes make the spec more explicit, not more complex.
- **Contract impact:** None. No new required config keys, no new agents, no changed output formats. PATCH level.
- **Residual concern:** The `timeout` command may not be available in all environments (Windows Git Bash). The spec should include a note that `timeout` is preferred but not mandatory -- the LLM can proceed without it and rely on git's own timeout behavior.

Proceed to Phase 4 (Spec).
