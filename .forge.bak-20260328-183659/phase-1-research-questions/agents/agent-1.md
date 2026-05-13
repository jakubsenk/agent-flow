# Agent 1 — Plugin Infrastructure Investigation

**Task:** Investigate the actual Claude Code plugin system on this machine to understand version resolution, cache structure, and reliability of the `repository` field.

---

## 1. `installed_plugins.json` — Full Structure

**Path:** `C:\Users\FSABACKY\.claude\plugins\installed_plugins.json`

```json
{
  "version": 2,
  "plugins": {
    "superpowers@claude-plugins-official": [
      {
        "scope": "user",
        "installPath": "C:\\Users\\FSABACKY\\.claude\\plugins\\cache\\claude-plugins-official\\superpowers\\5.0.6",
        "version": "5.0.6",
        "installedAt": "2026-02-04T12:22:14.948Z",
        "lastUpdated": "2026-03-25T19:38:46.777Z",
        "gitCommitSha": "06b92f36820f38175b2ed6ff3f8df45157d54731"
      }
    ],
    "ceos-agents@ceos-agents": [
      {
        "scope": "user",
        "installPath": "C:\\Users\\FSABACKY\\.claude\\plugins\\cache\\ceos-agents\\ceos-agents\\4.0.0",
        "version": "4.0.0",
        "installedAt": "2026-03-06T08:59:33.907Z",
        "lastUpdated": "2026-03-06T08:59:33.907Z",
        "gitCommitSha": "2bb8fc6f6af830b803d13ca7b52600a3a562111a"
      }
    ],
    "filip-superpowers@filip-superpowers-marketplace": [
      {
        "scope": "user",
        "installPath": "C:\\Users\\FSABACKY\\.claude\\plugins\\cache\\filip-superpowers-marketplace\\filip-superpowers\\0.3.1",
        "version": "0.3.1",
        "installedAt": "2026-03-24T09:15:53.159Z",
        "lastUpdated": "2026-03-26T10:39:06.524Z",
        "gitCommitSha": "f98b77b233b638f4f5a45de6bbe4f3e4ab28d993"
      }
    ]
  }
}
```

**Key observations:**
- Top-level `"version": 2` — schema version of the registry file itself.
- Plugin identifier format: `{plugin-name}@{marketplace-name}`.
- `installPath` always points into `cache/{marketplace}/{plugin}/{version}/`.
- `gitCommitSha` tracks the exact commit that was snapshotted.
- `lastUpdated` updates on each `plugin update` call; `installedAt` is set once.
- For `ceos-agents@ceos-agents`: installed 2026-03-06, never updated since → shows 4.0.0 while the live directory is now at 5.5.1.

---

## 2. Cache Directory Structure — All Versions

**Top-level cache dirs:**
```
~/.claude/plugins/cache/
  ceos-agents/
  claude-plugins-official/
  filip-superpowers-marketplace/
  temp_git_1774530705626_2r89po/    ← temporary clone artifact
```

**ceos-agents versions in cache:**

| Version | Is git repo? | Has `.claude-plugin/plugin.json`? | Notes |
|---------|-------------|-----------------------------------|-------|
| 4.0.0   | NO (snapshot) | YES | Installed 2026-03-06, matches `installed_plugins.json` |
| 5.1.0   | NO (snapshot) | YES | Orphaned from earlier update attempt |
| 5.2.0   | YES (git clone) | YES | HEAD = 7d2dd09 (chore: bump 5.1.0 → 5.2.0); remote = gitea SSH |
| 5.3.0   | YES (git clone) | YES | HEAD = 117cf38 (tag: v5.3.0); remote = gitea SSH |
| 5.4.1   | YES (git clone) | YES | HEAD = 6cf9d65 (current main); remote = gitea SSH |

**Why the inconsistency?** Versions 4.0.0 and 5.1.0 are plain file snapshots. Versions 5.2.0–5.4.1 are actual git clones — they share hooksPath with the main repo (`C:/gitea_ceos-agents/.git/hooks`) and have `origin` pointing to `gitea@gitea.internal.ceosdata.com:fsabacky/ceos-agents.git`. These were likely created by the forge pipeline (worktree-style development), not by the plugin system itself.

**filip-superpowers versions in cache** (directory marketplace, updated multiple times):
```
0.1.0 0.1.2 0.1.3 0.1.4 0.1.5 0.1.6 0.1.7 0.1.8 0.2.0 0.3.0 0.3.1
```
All are plain snapshots (NOT git repos). `installed_plugins.json` points to 0.3.1.

**Conclusion:** For directory-type marketplaces, cache entries are plain file copies. Old versions accumulate and are NOT cleaned up automatically. Only the version in `installed_plugins.json` is loaded.

---

## 3. Marketplace Directories

**Path:** `~/.claude/plugins/marketplaces/`

| Directory | Is git repo? | Source type | Remote / Path |
|-----------|-------------|------------|---------------|
| `CLAUDE-agents/` | YES | git (SSH) | `gitea@gitea.internal.ceosdata.com:fsabacky/CLAUDE-agents.git` |
| `claude-plugins-official/` | NO (extracted) | github | `anthropics/claude-plugins-official` |
| `superpowers-marketplace/` | YES | github (shallow) | `https://github.com/obra/superpowers-marketplace` |

Note: `ceos-agents` marketplace is NOT in the `marketplaces/` directory — because its source type is `"directory"` pointing to `C:\gitea_ceos-agents`. Directory-type marketplaces are used in-place; they don't get cloned here.

---

## 4. Per-Version ceos-agents Cache — Detailed Findings

All five versions have `.claude-plugin/plugin.json`. Key content comparison:

| Version | `repository` field | `version` field |
|---------|-------------------|-----------------|
| 4.0.0   | `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` | `4.0.0` |
| 5.1.0   | `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` | `5.1.0` |
| 5.2.0   | `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` | `5.2.0` |
| 5.3.0   | `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` | `5.3.0` |
| 5.4.1   | `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` | `5.4.1` |

`installPath` in `installed_plugins.json` points to the **4.0.0** cache entry. The `repository` field at that path is `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` — an HTTPS URL usable by `git ls-remote`.

---

## 5. `repository` Field Reliability Across Plugin Types

| Plugin | Source type | `repository` present? | Format |
|--------|------------|----------------------|--------|
| `ceos-agents` (all versions) | directory marketplace | YES | HTTPS git URL |
| `superpowers@claude-plugins-official` | url (github) | YES | HTTPS GitHub URL |
| `filip-superpowers` | directory marketplace | YES | HTTPS git URL |
| `context7@claude-plugins-official` | external_plugin (MCP) | NO | — |
| `slack@claude-plugins-official` | external_plugin (MCP) | NO | — |
| `github@claude-plugins-official` | external_plugin (MCP) | NO | — |
| `agent-sdk-dev@claude-plugins-official` | internal plugin | NO | — |
| `feature-dev@claude-plugins-official` | internal plugin | NO | — |

**Conclusion: `repository` is NOT universally present.** It is absent for:
- External MCP plugins (they are wrappers around MCP servers, not git repos)
- Anthropic's internal plugins in the official marketplace (no version, no repository)
- The marketplace metadata entries themselves (only in individual plugin caches)

`repository` IS reliable for plugins that are actual git repositories distributed via their own git URLs — which covers ceos-agents and superpowers (both have HTTPS URLs usable by `git ls-remote`).

---

## 6. `known_marketplaces.json` — Full Structure

**Path:** `C:\Users\FSABACKY\.claude\plugins\known_marketplaces.json`

```json
{
  "claude-plugins-official": {
    "source": { "source": "github", "repo": "anthropics/claude-plugins-official" },
    "installLocation": "C:\\Users\\FSABACKY\\.claude\\plugins\\marketplaces\\claude-plugins-official",
    "lastUpdated": "2026-03-26T18:55:32.430Z"
  },
  "superpowers-marketplace": {
    "source": { "source": "github", "repo": "obra/superpowers-marketplace" },
    "installLocation": "C:\\Users\\FSABACKY\\.claude\\plugins\\marketplaces\\superpowers-marketplace",
    "lastUpdated": "2026-01-21T06:28:25.748Z"
  },
  "CLAUDE-agents": {
    "source": { "source": "git", "url": "gitea@gitea.internal.ceosdata.com:fsabacky/CLAUDE-agents.git" },
    "installLocation": "C:\\Users\\FSABACKY\\.claude\\plugins\\marketplaces\\CLAUDE-agents",
    "lastUpdated": "2026-02-16T08:19:25.748Z"
  },
  "ceos-agents": {
    "source": { "source": "directory", "path": "C:\\gitea_ceos-agents" },
    "installLocation": "C:\\gitea_ceos-agents",
    "lastUpdated": "2026-03-05T19:36:14.005Z"
  },
  "filip-superpowers-marketplace": {
    "source": { "source": "directory", "path": "C:\\gitea_filip-superpowers" },
    "installLocation": "C:\\gitea_filip-superpowers",
    "lastUpdated": "2026-03-26T10:39:01.874Z"
  }
}
```

**Marketplace source types observed:**
- `"github"` — cloned from GitHub shorthand (`owner/repo`)
- `"git"` — cloned from a full git URL (supports SSH)
- `"directory"` — used in-place from a local path (no clone, no network)

For `directory` type: `installLocation` == `path` (the live local directory IS the marketplace).

---

## 7. Claude Plugin CLI — Update Mechanism

**Available plugin commands** (`claude plugin --help`):
- `install` — install from marketplace
- `update` — update to latest version (restart required)
- `uninstall` — remove
- `list` — show installed
- `enable` / `disable` — toggle
- `validate` — validate manifest
- `marketplace` — manage marketplaces

**`claude plugin list` output (current state):**
```
ceos-agents@ceos-agents      Version: 4.0.0  Status: enabled
filip-superpowers@...         Version: 0.3.1  Status: enabled
superpowers@claude-plugins-official  Version: 5.0.6  Status: enabled
```

**How update works (inferred from cache evidence):**

For `directory` marketplace:
1. Read `{live_dir}/.claude-plugin/marketplace.json` → find plugin entry → read `version` field.
2. If version > installed version: copy live directory contents to `cache/{marketplace}/{plugin}/{new_version}/`.
3. Update `installed_plugins.json` with new version + new installPath.
4. Requires restart to apply.

For `git`/`github`/`url` marketplace:
1. Run `git fetch` on the cached marketplace clone.
2. Check marketplace's plugin listing for the latest `version`.
3. Clone the plugin's git repo at the tagged version into `cache/{marketplace}/{plugin}/{version}/`.
4. Update `installed_plugins.json`.

**What the CLI loads:** Always reads `installPath` from `installed_plugins.json`. That directory is authoritative. The other version directories in cache are orphaned leftovers.

---

## 8. Key Answers

### How does Claude Code determine which version to load?

`installed_plugins.json` is the single source of truth. The `installPath` field points to the exact cache subdirectory that is loaded. All other cache entries for other versions are ignored at runtime.

### Relationship between `installed_plugins.json` version and cache dir versions?

`installed_plugins.json` always tracks the CURRENTLY INSTALLED version. The cache accumulates all versions that were ever installed/updated — they are never cleaned. The `version` field in `installed_plugins.json` matches the version subdirectory of the active `installPath`. For ceos-agents, `installed_plugins.json` shows `4.0.0` but the cache has 4.0.0 through 5.4.1 — the extra entries are orphaned.

### Is `repository` field reliable across all plugin types?

**No.** It is absent for MCP wrapper plugins and Anthropic internal plugins. However, for plugins that are true git repositories (like ceos-agents), `repository` is consistently present in the plugin.json copied into the cache snapshot. The version-check command's current approach (read `repository` from `{installPath}/.claude-plugin/plugin.json`, fallback gracefully if absent) is correct and sufficient for ceos-agents and similar git-based plugins.

### Is the hardcoded fallback URL a problem?

Yes. The hardcoded URL `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` only works for this specific team's installation. For any other team that clones and publishes their own fork, the fallback would point to the wrong repo. The fix (use `repository` from plugin.json, skip remote check if absent) is the right approach.

### Remote tags available on ceos-agents gitea repo:

```
v5.1.0 v5.2.0 v5.3.0 v5.5.0 v5.5.1
```
Notable gaps: no `v4.0.0`, no `v5.4.0`, no `v5.4.1` tags on remote.

### Current state mismatch:
- `installed_plugins.json` says: `4.0.0` (loaded from snapshot)
- Live directory (`C:\gitea_ceos-agents`) plugin.json: `5.5.1`
- Remote latest tag: `v5.5.1`
- `plugin update ceos-agents` would bring the installed version to 5.5.1.
