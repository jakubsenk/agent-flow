# Agent 3: The QA Engineer (Break It)

## Position

The biggest risk is not the code -- it is that nobody has ever tested version-check from outside the repo. The command is a markdown specification interpreted by an LLM at runtime. You cannot unit-test it the way you test a shell script. You can only verify it by running it in controlled environments and inspecting the output. That means the spec itself must be airtight about what to do in every degenerate state -- because the LLM will improvise (badly) if the spec is silent.

The current fix (v5.5.1) solved the most visible symptom (wrong paths, git pull on non-repos) but left six failure modes unspecified. When the CEO runs `/ceos-agents:version-check` from their project directory and `installed_plugins.json` does not exist because they did a fresh Claude Code install, the command will crash with an opaque "file not found" or -- worse -- the LLM will hallucinate a fallback. When the remote has no tags, the `tail -1` returns empty, and the comparison logic produces garbage. These are not hypothetical -- they are the exact states a new user hits on day one.

---

## Top 3 Risks

### Risk 1: Missing `installed_plugins.json` produces undefined behavior (DEF-3, P0)

The file `~/.claude/plugins/installed_plugins.json` does not exist on a fresh Claude Code installation until the user installs at least one plugin via `/plugin install`. The current spec says "Read installed_plugins.json" in step 1 but provides no guard for the file not existing. An LLM executing this will either:
- Report a raw file-not-found error with no remediation message
- Silently skip the step and continue with undefined variables
- Hallucinate a default value

**Impact:** First-time users (the exact audience who needs version-check most) get broken output.

**Required fix:** Step 1 must begin with an explicit existence check: "If the file does not exist, report 'Claude Code plugin registry not found at ~/.claude/plugins/installed_plugins.json -- has any plugin been installed?' and STOP."

### Risk 2: Semantic version comparison is unspecified (DEF-6, P1)

The spec says compare `installed_version` with `remote_version` using `<`, `==`, `>` but never specifies HOW. An LLM doing string comparison will produce:
- `"5.10.0" < "5.9.0"` -- WRONG (lexicographic: "1" < "9")
- `"5.5.1" < "5.5.10"` -- WRONG (same reason)

This is not a future concern. The ceos-agents plugin is already at 5.5.1 and will eventually cross a two-digit minor or patch boundary.

**Impact:** False "up to date" or false "update available" messages -- exactly the thing version-check exists to prevent.

**Required fix:** The spec must explicitly state: "Compare versions as semantic versions -- split on '.', compare each component as an integer (major, then minor, then patch)."

### Risk 3: `git ls-remote` output contains annotated tag dereferences (DEF-8, P1)

When a repository uses annotated tags (which is best practice and what many forked repos will do), `git ls-remote --tags` returns both the tag ref and the dereferenced object:

```
abc123  refs/tags/v5.5.1
def456  refs/tags/v5.5.1^{}
```

The `sort -V | tail -1` pipeline may select the `^{}` line. Extracting the version from `refs/tags/v5.5.1^{}` yields `5.5.1^{}` -- not a valid semver string. The comparison then breaks.

**Impact:** Any plugin hosted on a repository that uses annotated tags (GitHub default for releases) will get garbled version output.

**Required fix:** Add `grep -v '\^{}'` before the sort, and add a guard for empty output after filtering.

---

## Test Matrix

| # | Scenario | CWD | `installed_plugins.json` | Network | Remote Tags | Expected Output |
|---|----------|-----|--------------------------|---------|-------------|-----------------|
| 1 | Happy path, up to date | `/tmp` | Present, version 5.5.1 | Up | v5.5.1 | "ceos-agents 5.5.1 -- up to date" |
| 2 | Happy path, update available | `/tmp` | Present, version 5.4.1 | Up | v5.5.0, v5.5.1 | "ceos-agents 5.4.1 -> 5.5.1 -- update available. Run: ..." |
| 3 | Happy path, locally newer | `/tmp` | Present, version 5.6.0 | Up | v5.5.1 | "ceos-agents 5.6.0 > 5.5.1 -- installed version is newer than remote" |
| 4 | File missing entirely | `/tmp` | Does not exist | Up | v5.5.1 | "Claude Code plugin registry not found at ~/.claude/plugins/installed_plugins.json -- ..." STOP |
| 5 | File empty (0 bytes) | `/tmp` | Exists but empty | Up | v5.5.1 | "Plugin registry is empty or corrupt" STOP |
| 6 | File is invalid JSON | `/tmp` | `{broken` | Up | v5.5.1 | "Plugin registry is corrupt -- cannot parse" STOP |
| 7 | File valid but no ceos-agents entry | `/tmp` | `{"plugins":{}}` | Up | v5.5.1 | "ceos-agents plugin is not installed. Run: ..." STOP |
| 8 | installPath does not exist on disk | `/tmp` | Points to deleted dir | Up | v5.5.1 | Warning about broken install + reinstall instructions |
| 9 | No `repository` field in plugin.json | `/tmp` | Valid entry | Up | v5.5.1 | "Cannot determine remote URL -- repository field missing from plugin.json. Skipping remote comparison." |
| 10 | Network down (git ls-remote fails) | `/tmp` | Valid entry | DOWN | N/A | "Failed to determine remote version (network error). Skipping remote comparison." Still shows installed version. |
| 11 | git ls-remote times out (hangs) | `/tmp` | Valid entry | Slow | N/A | Same as #10 (needs a timeout strategy -- 10s max) |
| 12 | Remote has zero tags | `/tmp` | Valid entry | Up | (none) | "No version tags found on remote. Skipping remote comparison." |
| 13 | Remote has tags but none match `v*` | `/tmp` | Valid entry | Up | `release-1.0` | Same as #12 |
| 14 | Remote has annotated tags (`^{}`) | `/tmp` | Valid entry | Up | v5.5.1, v5.5.1^{} | Filters `^{}`, shows "5.5.1" correctly |
| 15 | Semver edge: 5.10.0 vs 5.9.0 | `/tmp` | version 5.9.0 | Up | v5.10.0 | "update available" (NOT "up to date") |
| 16 | Semver edge: 5.5.10 vs 5.5.9 | `/tmp` | version 5.5.9 | Up | v5.5.10 | "update available" |
| 17 | In plugin repo, versions match | ceos-agents repo | version 5.5.1 | Up | v5.5.1 | Part A output + Part B: "Repo version matches installed plugin (5.5.1)" |
| 18 | In plugin repo, repo newer | ceos-agents repo | version 5.4.1 | Up | v5.5.1 | Part A output + Part B: "Repo is 5.5.1 but installed plugin is 5.4.1 -- reinstall ..." |
| 19 | In a DIFFERENT plugin's repo | other-plugin repo | ceos-agents 5.5.1 | Up | v5.5.1 | Part A output. Part B SKIPPED (name mismatch). No spurious comparison. |
| 20 | In a subdirectory of plugin repo | ceos-agents/agents/ | version 5.5.1 | Up | v5.5.1 | Part B SKIPPED (`.claude-plugin/plugin.json` not in CWD). Part A works normally. |
| 21 | SSH-only remote URL (requires key) | `/tmp` | Valid, repo URL is `git@...` | Up but auth fails | N/A | "Failed to determine remote version (authentication error). Skipping remote comparison." |
| 22 | Multiple plugin entries (duplicate keys) | `/tmp` | Two entries for ceos-agents | Up | v5.5.1 | Uses the first/active entry, does not crash |
| 23 | Legacy marketplace dir exists | `/tmp` | Valid entry | Up | v5.5.1 | Part A + Part C warning about CLAUDE-agents remnant |
| 24 | Legacy marketplace dir does not exist | `/tmp` | Valid entry | Up | v5.5.1 | Part A + Part C silently skipped (clean state) |

---

## The One Thing the Current Fix Missed

**The spec has no timeout for `git ls-remote`.**

The current command runs:
```bash
git ls-remote --tags {repository_url} 'refs/tags/v*' | sort -t/ -k3 -V | tail -1
```

If the remote URL points to an unreachable host (corporate VPN required, SSH key missing, DNS resolution hangs), `git ls-remote` will block for up to 30 seconds (the default git timeout) or indefinitely on some configurations. During this time, the LLM is stalled and the user sees nothing.

The spec says "On network failure: warn and skip" -- but `git ls-remote` hanging is not the same as failing. It will eventually time out with an error, but the user experience during that wait is terrible. For a command that a CEO is supposed to run for a quick status check, 30 seconds of silence is unacceptable.

**Fix:** The spec should explicitly instruct:
```bash
timeout 10 git ls-remote --tags {repository_url} 'refs/tags/v*' 2>/dev/null | grep -v '\^{}' | sort -t/ -k3 -V | tail -1
```

This adds three things the current pipeline is missing:
1. `timeout 10` -- hard cap at 10 seconds
2. `grep -v '\^{}'` -- filter annotated tag dereferences
3. `2>/dev/null` -- suppress git's stderr noise (auth prompts, connection errors) so the LLM does not try to interpret error messages as version data

Additionally, the spec should add an explicit empty-output check after the pipeline: "If the pipeline produces no output, report 'No version tags found on remote' and skip the comparison."

---

## CEO Experience Verification

When a CEO runs `/ceos-agents:version-check`, they should see ONE of these outputs:

**Best case (up to date, from any directory):**
```
ceos-agents 5.5.1 -- up to date
```

**Update available:**
```
ceos-agents 5.4.1 -> 5.5.1 -- update available.
Run: /plugin uninstall ceos-agents then /plugin install ceos-agents@ceos-agents
```

**Network issue (graceful degradation):**
```
ceos-agents 5.5.1 (installed)
Failed to determine remote version -- skipping remote comparison.
```

**Not installed:**
```
ceos-agents plugin is not installed.
Run: /plugin install ceos-agents@ceos-agents
```

The command should NEVER show:
- Raw error messages from git or JSON parsing
- Empty/blank output
- A comparison with garbled version strings (e.g., `5.5.1^{}`)
- A hang longer than 10 seconds
- A false "up to date" when it is not

---

## Summary

The current fix (v5.5.1) addressed the structural problems (wrong paths, git pull on snapshots) but left the spec silent on six failure modes that real users WILL hit. The three highest-priority gaps are: missing `installed_plugins.json` (P0), unspecified semver comparison (P1), and unfiltered annotated tags (P1). The one thing nobody noticed: there is no timeout on `git ls-remote`, which means a single unreachable remote turns a quick status check into a 30-second hang. Every one of these issues can be fixed by adding 5-10 words of explicit instruction to the markdown spec -- no architectural changes needed.
