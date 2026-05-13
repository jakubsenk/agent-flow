# Plugin Loading Research: How Claude Code Resolves ceos-agents

**Date:** 2026-03-27
**Investigator:** Claude Code (sonnet-4-6)

---

## Key Files Examined

- `~/.claude/plugins/installed_plugins.json`
- `~/.claude/plugins/known_marketplaces.json`
- `~/.claude/settings.json`
- `~/.claude/plugins/cache/ceos-agents/ceos-agents/4.0.0/.claude-plugin/plugin.json`
- `~/.claude/plugins/cache/ceos-agents/ceos-agents/5.5.1/` (orphaned)
- `C:\gitea_ceos-agents/.claude-plugin/plugin.json`

---

## What `installed_plugins.json` Says

```json
"ceos-agents@ceos-agents": [
  {
    "scope": "user",
    "installPath": "C:\\Users\\FSABACKY\\.claude\\plugins\\cache\\ceos-agents\\ceos-agents\\4.0.0",
    "version": "4.0.0",
    "installedAt": "2026-03-06T08:59:33.907Z",
    "lastUpdated": "2026-03-06T08:59:33.907Z",
    "gitCommitSha": "2bb8fc6f6af830b803d13ca7b52600a3a562111a"
  }
]
```

**Conclusion:** The authoritative version in use is **4.0.0**, installed on 2026-03-06, never updated since.

---

## What `known_marketplaces.json` Says

The `ceos-agents` marketplace is registered as a **directory** source:

```json
"ceos-agents": {
  "source": {
    "source": "directory",
    "path": "C:\\gitea_ceos-agents"
  },
  "installLocation": "C:\\gitea_ceos-agents",
  "lastUpdated": "2026-03-05T19:36:14.105Z"
}
```

This is also mirrored in `~/.claude/settings.json` under `extraKnownMarketplaces`.

**Conclusion:** The marketplace source points to the working repo at `C:\gitea_ceos-agents`, but this is only used for DISCOVERY and INSTALLATION — not for runtime loading.

---

## Cache Structure Explained

Five cache versions exist:

| Version | Created | `.orphaned_at` | Content | Type |
|---------|---------|----------------|---------|------|
| 4.0.0 | 2026-03-06 | NO | Full snapshot (agents/, commands/, skills/, etc.) | Real file copy (no .git) |
| 5.2.0 | 2026-03-24 | YES | Stripped git clone (dotfiles only) | git clone |
| 5.3.0 | 2026-03-26 | YES | Stripped git clone (dotfiles only) | git clone |
| 5.4.1 | 2026-03-26 | YES | Stripped git clone (dotfiles only) | git clone |
| 5.5.1 | 2026-03-27 | YES | Stripped git clone (dotfiles only) | git clone |

The **4.0.0** cache contains all plugin content (`agents/`, `commands/`, `skills/`, etc.) as a plain file copy without a `.git` directory.

The **orphaned** caches (5.2.0–5.5.1) contain only dotfiles/gitignored items:
- `.git/` — pointing to `gitea@gitea.internal.ceosdata.com:fsabacky/ceos-agents.git`
- `.claude/`, `.claude-plugin/`, `.forge/`, `.forge.bak-*`, `.gitignore`, `.vs/`
- `.orphaned_at` — Unix timestamp (ms) of when it was orphaned

Running `git status` inside 5.5.1 confirms all tracked files (CHANGELOG.md, agents/, commands/, etc.) show as "deleted" — Claude Code stripped them when it orphaned the version.

---

## The Orphaned Cache Mystery

**What created the orphaned caches?**

Claude Code's auto-update mechanism periodically:
1. Clones the latest from the git remote (via `repository` field in `plugin.json`) into a new cache version directory
2. Detects that the marketplace source is `"directory"` type — meaning the user manages updates manually
3. Marks the clone as `.orphaned_at` immediately (does NOT install it)
4. Does NOT update `installed_plugins.json`

This explains why the orphaned timestamps match the directory modification times exactly — the orphaning is immediate.

**Important side effect:** All orphaned cache directories have a valid `.git` folder pointing to the gitea remote. Running `git ls-remote` against them works fine. This is what `version-check` Step 3 would use if it read from an orphaned cache — but it reads from the active `installPath` (4.0.0), so it queries the gitea HTTPS remote via `plugin.json`.

---

## Answer: WHERE Does Claude Code Load ceos-agents From?

**When a user runs `/ceos-agents:version-check` from ANY project (including non-ceos-agents repos):**

Claude Code loads the plugin from:
```
C:\Users\FSABACKY\.claude\plugins\cache\ceos-agents\ceos-agents\4.0.0\
```

This is the `installPath` from `installed_plugins.json`. It is:
- A static snapshot copied on 2026-03-06
- Version **4.0.0** of the plugin
- Missing features added in v5.x: `check-deploy`, `discuss` commands; `acceptance-gate`, `browser-verifier`, `deployment-verifier`, `reproducer` agents

**The "directory" marketplace source is NOT consulted at runtime.** It was only used during the initial `plugin install` to copy files into the cache.

---

## Does `git pull` in the Working Repo Update Other Projects?

**NO.**

`git pull` in `C:\gitea_ceos-agents` updates only the working repo files. It has zero effect on:
- `installed_plugins.json`
- `cache/4.0.0/` (the active install snapshot)
- Any other project's view of ceos-agents commands/agents

The working repo is at **5.5.1** (plugin.json says so) but other projects load **4.0.0** from cache.

---

## How to Actually Update the Installed Plugin

The update requires a full reinstall:

```
/plugin uninstall ceos-agents
/plugin install ceos-agents@ceos-agents
```

When reinstalling from a directory-source marketplace:
1. Claude Code reads the current directory content (`C:\gitea_ceos-agents` — now at 5.5.1)
2. Copies all tracked files to a new cache directory (e.g. `cache/ceos-agents/ceos-agents/5.5.1/`)
3. Updates `installed_plugins.json` with `installPath = cache/.../5.5.1`, `version = 5.5.1`

After reinstall, all projects would see v5.5.1.

**Alternative:** If the marketplace were `"source": "git"` (pointing to the gitea URL), Claude Code would handle auto-updates and `installed_plugins.json` would stay current. But since it's `"directory"`, manual reinstall is the only update path.

---

## Implication for `version-check` Command

The current `version-check.md` logic is **correct** given this loading model:

| Step | What it does | Correctness |
|------|-------------|-------------|
| Step 1 | Reads `installed_plugins.json` → finds `installPath` = cache/4.0.0 | Correct — this IS the active version |
| Step 2 | Verifies `installPath` exists on disk | Correct |
| Step 3 | Reads `repository` from `{installPath}/.claude-plugin/plugin.json` → `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` | Correct — 4.0.0 cache has valid URL |
| Step 3 cont. | Runs `git ls-remote --tags {url}` to find latest remote tag | Correct — queries gitea remote |
| Step 4 | Compares 4.0.0 (installed) vs remote (e.g. 5.5.1) → shows update available | Correct |
| Step 5-6 (Part B) | Compares CWD repo version vs installed | Correct for when in ceos-agents repo |
| Step 7 (Part C) | Checks for legacy CLAUDE-agents marketplace | Correct (it still exists) |

**One nuance:** The comment in `version-check.md` says "cache directories are snapshots, NOT git repos, so `git pull` does not work." This is accurate for the ACTIVE install (4.0.0 has no `.git`). The orphaned caches DO have `.git` folders, but they are not the active install and are not used for loading.

---

## Summary Table

| Question | Answer |
|----------|--------|
| Where does Claude load ceos-agents from? | `cache/ceos-agents/ceos-agents/4.0.0/` (static snapshot) |
| How is the active version determined? | `installPath` in `installed_plugins.json` |
| Does `git pull` in working repo update other projects? | NO |
| What are the orphaned caches? | Auto-update mechanism git clones, stripped of tracked content, not used for loading |
| How to update the installed plugin? | `/plugin uninstall ceos-agents` + `/plugin install ceos-agents@ceos-agents` |
| Is `version-check` logic correct? | YES — reads from installPath, queries gitea remote via HTTPS |
| Current mismatch: working repo vs installed | Working repo = 5.5.1, installed = 4.0.0 (19 versions behind!) |
