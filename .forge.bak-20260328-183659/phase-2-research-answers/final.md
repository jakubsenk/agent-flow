# Phase 2 Research Answers — version-check Genericity Investigation

Synthesized from agent-1 (plugin infrastructure), agent-2 (cross-reference surface), and agent-3 (defect analysis).

---

## 1. Plugin System Architecture

*From agent-1 findings.*

### How Claude Code Plugin Loading Actually Works

**Single source of truth: `installed_plugins.json`**

Path: `~/.claude/plugins/installed_plugins.json`

Claude Code determines which version of a plugin to load exclusively from this file. The `installPath` field in each plugin entry points to the exact cache subdirectory that is active at runtime. All other version directories in the cache are orphaned leftovers — they are never cleaned up and are never loaded.

**Plugin identifier format:** `{plugin-name}@{marketplace-name}`

Example entries observed on this machine:
- `ceos-agents@ceos-agents` — version 4.0.0, directory marketplace
- `superpowers@claude-plugins-official` — version 5.0.6, GitHub marketplace
- `filip-superpowers@filip-superpowers-marketplace` — version 0.3.1, directory marketplace

**Cache layout:** `~/.claude/plugins/cache/{marketplace}/{plugin}/{version}/`

Each installed version is a snapshot copy of the plugin contents. For directory-type marketplaces, this is a plain file copy — not a git clone, not a symlink. Old version snapshots accumulate indefinitely.

**Marketplace types and how they load:**

| Source type | Clone behavior | In-place? |
|-------------|---------------|-----------|
| `directory` | No clone — used from the live local path | Yes |
| `github` | Cloned from `owner/repo` on GitHub | No |
| `git` | Cloned from a full git URL | No |

For `directory`-type marketplaces, `installLocation` == `path` (the live directory IS the marketplace). The `ceos-agents` marketplace is of this type.

**Update mechanism (directory marketplace):**
1. Read `{live_dir}/.claude-plugin/marketplace.json` — check plugin's `version` field.
2. If version > installed version: copy live directory contents to `cache/{marketplace}/{plugin}/{new_version}/`.
3. Update `installed_plugins.json` with new version + new `installPath`.
4. Requires Claude Code restart to apply.

**`repository` field reliability:**

The `repository` field in `.claude-plugin/plugin.json` is NOT universally present.

| Plugin type | `repository` present? |
|-------------|----------------------|
| True git-repo plugins (ceos-agents, superpowers) | YES — HTTPS URL usable by `git ls-remote` |
| External MCP wrapper plugins | NO |
| Anthropic internal plugins | NO |

**Key finding on ceos-agents state mismatch (this machine):**
- `installed_plugins.json`: 4.0.0 (never updated since 2026-03-06)
- Live directory plugin.json: 5.5.1
- Remote latest tag: v5.5.1
- Cache contains orphaned versions: 4.0.0, 5.1.0, 5.2.0, 5.3.0, 5.4.1

**Remote tags available on the ceos-agents Gitea repo:**
`v5.1.0`, `v5.2.0`, `v5.3.0`, `v5.5.0`, `v5.5.1`

Notable gaps: no `v4.0.0`, `v5.4.0`, `v5.4.1` tags on remote.

---

## 2. Defect Registry

*All 9 defects from agent-3.*

| ID | Severity | Description | Fix Strategy |
|----|----------|-------------|--------------|
| DEF-1 | P0 | Plugin identifier `ceos-agents@ceos-agents` hardcoded in steps 1, 2, 4, 6, and Rules | Derive identifier dynamically: read `name` field from `.claude-plugin/plugin.json` (CWD or `installPath`). Construct as `{name}@{marketplace-name}`. Fail gracefully if neither source is available. |
| DEF-2 | P1 | Fallback repository URL (`https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git`) is a private internal URL inaccessible to all other users | Remove hardcoded fallback entirely. When `repository` field is absent, report "Cannot determine remote URL — `repository` field missing from plugin.json" and skip remote comparison. |
| DEF-3 | P0 | No handling for `installed_plugins.json` not existing at all | Add explicit guard at step 1: if file does not exist, report "Claude Code plugin registry not found at ~/.claude/plugins/installed_plugins.json — is Claude Code installed?" and STOP. |
| DEF-4 | P1 | Part B triggers on any plugin repo (any `.claude-plugin/plugin.json`), not only ceos-agents — produces spurious mismatch messages when run from a different plugin's repo | After DEF-1 is fixed: add a name-match check inside step 5 — verify `plugin.json`'s `name` field matches the plugin being checked before executing Part B comparisons. |
| DEF-5 | P2 | Legacy cleanup (step 7) hardcoded to `CLAUDE-agents` directory name (author's personal rename history); `{version}` variable is also undefined at that point | Remove step 7 from any generic version of the command. If kept for ceos-agents specifically, add explicit instruction to read version from `~/.claude/plugins/marketplaces/CLAUDE-agents/.claude-plugin/plugin.json`. |
| DEF-6 | P1 | Version comparison (`<`, `==`, `>`) on version strings is undefined; string comparison gives wrong results for minor/patch numbers ≥ 10 (e.g., "5.10.0" < "5.9.0" lexicographically) | Specify explicitly: "compare as semantic versions (major.minor.patch integers)." Provide a bash snippet: `sort -V` or split on `.` and compare each component as integers. |
| DEF-7 | P1 | Remediation messages in steps 2, 4, 6 contain hardcoded `/plugin uninstall ceos-agents` and `/plugin install ceos-agents@ceos-agents` | After DEF-1 is fixed: substitute resolved plugin name and identifier into all user-facing remediation messages. |
| DEF-8 | P1 | `git ls-remote` pipeline not guarded against empty output (no tags) or `^{}` annotated tag dereference lines | Filter out `^{}` lines before sorting (`grep -v '\^{}'`). Explicitly handle empty output: if tail returns nothing, report "No remote version tags found" and skip comparison. |
| DEF-9 | P2 | Part B heading reads "only when in ceos-agents repo" but actual guard condition is weaker — any plugin repo with `.claude-plugin/plugin.json` qualifies | Update heading to "Part B: Repo Comparison (only when in the matching plugin's repo)" after DEF-4 is fixed. |

**P0 defects (2):** DEF-1, DEF-3 — these cause the command to produce wrong results or halt with no useful error for any non-author installation.

**P1 defects (5):** DEF-2, DEF-4, DEF-6, DEF-7, DEF-8 — these cause incorrect or misleading output but do not immediately prevent execution.

**P2 defects (2):** DEF-5, DEF-9 — cosmetic/confusing but functionally harmless for the original author.

---

## 3. Cross-Reference Surface

*All files that mention `version-check`, from agent-2.*

### Active Plugin Files

| File | Reference count | Nature of references |
|------|----------------|---------------------|
| `commands/version-check.md` | Primary | Command definition (3-part structure A/B/C) |
| `CLAUDE.md` | 2 | Line 32: command list enumeration; Line 206: MINOR versioning policy example |
| `CHANGELOG.md` | 5+ | Lines 10–18: v5.5.1 fix entry; Line 347: old behavior (now removed); Line 404: plugin-maintenance note; Line 520: original introduction |
| `docs/reference/commands.md` | 5 | Line 38: commands table; Lines 621–639: full section; Lines 429, 617, 661: related-command cross-refs |
| `README.md` | 1 | Line 156: commands table |
| `skills/workflow-router/SKILL.md` | 2 | Line 22: intent mapping table; Line 48: non-destructive classification list |
| `docs/guides/troubleshooting.md` | 2 | Lines 27, 269: upgrade troubleshooting steps |

### Files with No References

| File | Result |
|------|--------|
| `commands/init.md` | No reference (references `/ceos-agents:check-setup` instead) |
| `docs/guides/installation.md` | No reference |

### Historical / Non-Active Files

| File | Nature |
|------|--------|
| `REVIEW-REPORT-v3.1.0.md` | Lines 408–409: LOW-07 defect that identified the bug fixed in v5.5.1 |
| `docs/plans/2026-02-25-v2.0-implementation-plan.md` | Line 740: original command design |

---

## 4. Genericity Requirements

*What must change to make version-check work for ANY plugin, not just ceos-agents.*

### 4.1 Plugin Identifier Must Be Derived, Not Hardcoded

**Current state:** The string `ceos-agents@ceos-agents` appears as a literal in 5+ locations.

**Required change:** The command must derive the plugin identifier at runtime using this resolution order:
1. Read `name` from `.claude-plugin/plugin.json` in CWD (if the user is in a plugin repo).
2. Failing that, read `name` from `{installPath}/.claude-plugin/plugin.json` (using `installPath` from a partial scan of `installed_plugins.json`).
3. Failing both, report that the plugin identity cannot be determined and STOP — do not fall back to a hardcoded value.

The marketplace component of the identifier (`@{marketplace}`) must also be derived: it is the marketplace name under which the plugin is registered in `installed_plugins.json`, not a hardcoded string.

### 4.2 No Hardcoded URLs

**Current state:** Step 3 has a hardcoded fallback: `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git`.

**Required change:** Remove this fallback entirely. The `repository` field in `plugin.json` is the only authoritative source of the remote URL. If it is absent, the command must report the missing field explicitly and skip the remote version comparison — not silently query an unrelated private server.

### 4.3 Legacy Cleanup Must Be Configurable or Removed

**Current state:** Step 7 checks for `~/.claude/plugins/marketplaces/CLAUDE-agents/` — hardcoded to a single author's renaming history.

**Required change:** Two options:
- **Option A (generic):** Remove step 7 entirely from the command definition. Document in a comment that plugin authors who have a rename history may add their own equivalent step.
- **Option B (configurable):** Add an optional config key (e.g., `legacy_marketplace_name`) that, if set, enables step 7 with the configured old directory name.

Additionally, step 7 as currently written uses an undefined `{version}` variable — this must be fixed regardless: read the version from `~/.claude/plugins/marketplaces/CLAUDE-agents/.claude-plugin/plugin.json` or `marketplace.json` if the check is kept.

### 4.4 Part B Must Verify It Is in the CORRECT Plugin's Repo

**Current state:** Part B's only guard is the existence of `.claude-plugin/plugin.json` in CWD — which is true for any Claude Code plugin repository.

**Required change:** After resolving the plugin name (per 4.1), Part B must add a second guard: read the `name` field from `CWD/.claude-plugin/plugin.json` and compare it to the resolved plugin name. Only proceed if they match. If they do not match, skip Part B entirely (do not output any comparison — the user is in a different plugin's repo).

---

## 5. Key Design Question

*How should the command know WHICH plugin to check?*

### Options

**(a) Read from CWD's `.claude-plugin/plugin.json` name field**
- Works only when CWD is the plugin's own repository.
- Fails silently or produces wrong results when run from `/tmp`, a user project, or a different plugin repo.
- Does not cover the "check installed version from anywhere" use case (which is the primary advertised capability).

**(b) Accept plugin name as argument** — `/version-check [plugin-name]`
- Fully generic: any plugin can be checked from any directory.
- Requires the user to know and type the plugin name.
- Makes the no-argument form (`/version-check`) ambiguous — must either fail or fall back to another strategy.
- Adds friction for the common single-plugin case.

**(c) Check ALL installed plugins from `installed_plugins.json`**
- Fully generic, zero arguments needed.
- Produces a multi-plugin status report (may be desirable as a "health check" command).
- Scope creep: this is closer to `/check-setup` behavior than a focused version check.
- The "Part B repo comparison" concept breaks down — you cannot compare repo vs installed for all plugins simultaneously from a single CWD.

**(d) Use the command's own plugin identity (it IS ceos-agents, so check ceos-agents)**
- Conceptually clean: the command is part of the ceos-agents plugin, so it checks ceos-agents.
- Implementation: read the plugin name from the command file's own plugin context (the `.claude-plugin/plugin.json` in the same repository as the command).
- Problem: when the command is loaded from the cache snapshot (`installPath`), `installPath/.claude-plugin/plugin.json` contains the installed version's `name` — which is the correct plugin to check. This is self-consistent.
- Works from any CWD for Part A and C.
- Part B still needs the name-match guard (4.4) to avoid false comparisons from other plugin repos.

### Recommendation

**Option (d) is the strongest for a plugin-scoped command.**

Derivation logic:
1. The command is loaded from `installPath` (per `installed_plugins.json`).
2. Read `name` from `{installPath}/.claude-plugin/plugin.json` — this is always available when the plugin is installed (agent-1 confirmed all 5 cache versions have this file).
3. The plugin identifier for `installed_plugins.json` lookup is constructed as `{name}@{marketplace}` — the marketplace name can be extracted from the `installPath` structure (`cache/{marketplace}/{plugin}/{version}/`).
4. Part B: when in a repo, compare the CWD's `plugin.json` name against the resolved name — only proceed if they match (fix for DEF-4).

Option (b) as a complement: a `[plugin-name]` argument can override step 1 above, enabling the command to check any installed plugin. This is additive and does not break the zero-argument default behavior.

**The combined design:** `version-check [plugin-name]` where:
- No argument → derive from own plugin context (option d)
- Argument provided → look up that plugin by name in `installed_plugins.json` (option b)
- Part C (cleanup) → runs only if `plugin-name` matches `ceos-agents` and legacy dir exists, or is suppressed entirely for generic use

This satisfies all four genericity requirements (4.1–4.4) and is consistent with the plugin system architecture observed in agent-1.
