# Agent 2 — version-check Cross-Reference Research

**Task:** Document all references to `version-check` across the repository for the v5.5.1 fix.

---

## 1. All `version-check` / `version_check` Occurrences in .md Files

### Core Plugin Files

**`CLAUDE.md` (line 32):**
```
**Commands** (orchestration — WHAT to do): `/analyze-bug`, `/fix-ticket`, `/fix-bugs`, `/create-pr`, `/publish`, `/version-bump`, `/check-setup`, `/check-deploy`, `/resume-ticket`, `/status`, `/onboard`, `/init`, `/changelog`, `/version-check`, `/implement-feature`, ...
```

**`CLAUDE.md` (line 206):**
```
| MINOR (X.Y.0) | New backward-compatible feature — new optional key, new command/agent | `/version-check`, optional Hooks section |
```

**`CHANGELOG.md` (line 12):**
```
**PATCH** — Fix version-check: works from any directory, correct cache path detection. No contract or behavior changes.
```

**`CHANGELOG.md` (lines 15–16):**
```
- **version-check works from any directory:** Restructured into 3 parts — Part A (installed plugin status, always runs from anywhere), Part B (repo comparison, only in ceos-agents repo), Part C (cleanup checks, always runs). Previously required CWD to be the ceos-agents repository.
- **version-check cache path:** Was looking at `~/.claude/plugins/marketplaces/ceos-agents/` which does not exist. Now reads `~/.claude/plugins/installed_plugins.json` (the authoritative source) and finds `ceos-agents@ceos-agents` entry. Cache directories are snapshots, not git repos — removed broken `git pull` logic.
```

**`CHANGELOG.md` (line 347):**
```
- **version-check:** auto-updates stale plugin marketplace cache via `git pull` (step 6) — no manual uninstall/reinstall needed
```
*(Note: This is an older entry describing pre-fix behavior that was removed.)*

**`CHANGELOG.md` (line 404):**
```
- **version-check:** added note this is plugin-maintenance-only command
```

**`CHANGELOG.md` (line 520):**
```
- feat: `/version-check` — check for new plugin version (v2.1)
```

**`docs/reference/commands.md` (line 38):**
```
| Versioning | [/version-check](#version-check) | Compares installed vs latest version |
```

**`docs/reference/commands.md` (lines 621–639):**
Full section — see Section 3 below.

**`docs/reference/commands.md` (line 429):**
```
**Related commands:** [/check-setup](#check-setup), [/version-check](#version-check)
```

**`docs/reference/commands.md` (line 617):**
```
**Related commands:** [/version-check](#version-check), [/changelog](#changelog)
```

**`docs/reference/commands.md` (line 661):**
```
**Related commands:** [/version-bump](#version-bump), [/version-check](#version-check)
```

**`README.md` (line 156):**
```
| `/version-check` | Compare installed plugin version against latest available |
```

**`docs/guides/troubleshooting.md` (line 27):**
```
1. Run `/ceos-agents:version-check` to compare your installed version with the latest remote version
```

**`docs/guides/troubleshooting.md` (line 269):**
```
   - Run `/ceos-agents:version-check` and note the installed version
```

**`skills/workflow-router/SKILL.md` (line 22):**
```
| Check plugin version | `ceos-agents:version-check` | None | No |
```

**`skills/workflow-router/SKILL.md` (line 48):**
```
3. **If the operation is NOT destructive** (analyze-bug, check-setup, version-check, status, dashboard, metrics, estimate, prioritize, template, scaffold-validate, check-deploy without flags): invoke the command immediately
```

**`REVIEW-REPORT-v3.1.0.md` (lines 408–409):**
```
### [LOW-07] version-check.md — Funguje jen v CLAUDE-agents repo
- **Soubor:** `commands/version-check.md` (řádky 12–13)
```
*(Historical review that identified the bug fixed in v5.5.1.)*

---

## 2. All "Version Check" (Title Case) Occurrences

**`commands/version-check.md` (line 6):**
```
# Version Check
```

**`docs/plans/2026-02-25-v2.0-implementation-plan.md` (line 740):**
```
# Version Check
```
*(Historical plan file — original command design.)*

---

## 3. `docs/reference/commands.md` — Full version-check Section

Lines 621–641:

```markdown
### /version-check

> Compares installed plugin version with latest available.

**Syntax:**

```
/ceos-agents:version-check
```

**What it does:** Reads the installed plugin version from plugin.json and compares it with the latest version available in the remote repository. Reports whether an update is available and what version it is. Useful for staying current with plugin releases.

**Example:**

```
/ceos-agents:version-check
```

**Related commands:** [/version-bump](#version-bump), [/migrate-config](#migrate-config)
```

---

## 4. `CLAUDE.md` — version-check References

Two mentions:
1. Line 32: Listed in the Commands enumeration (25 commands total).
2. Line 206: Used as the example of a MINOR version bump trigger in the Versioning Policy table.

No behavioral description of version-check in CLAUDE.md — it only catalogs the command by name.

---

## 5. `commands/init.md` — version-check Reference

**Finding: No reference to version-check in `commands/init.md`.**

The file is 219 lines covering MCP/token/permissions setup. It references `/ceos-agents:check-setup` (step 9, closing message) but does NOT mention `/version-check`.

---

## 6. `skills/workflow-router/SKILL.md` — version-check Route

Yes — two references:

**Line 22 (Intent Mapping table):**
```
| Check plugin version | `ceos-agents:version-check` | None | No |
```

**Line 48 (Process step 3):**
```
3. **If the operation is NOT destructive** (analyze-bug, check-setup, version-check, status, dashboard, metrics, estimate, prioritize, template, scaffold-validate, check-deploy without flags): invoke the command immediately
```

The skill correctly marks version-check as non-destructive (no confirmation required).

---

## 7. `README.md` — version-check Reference

One reference, line 156 (commands table):

```
| `/version-check` | Compare installed plugin version against latest available |
```

No other mentions in README.md.

---

## 8. `docs/guides/installation.md` — version-check Reference

**Finding: No references to version-check in `docs/guides/installation.md`.**

The file does not mention the version-check command.

---

## 9. `CHANGELOG.md` — v5.5.1 Entry (the version-check fix)

Lines 10–18:

```markdown
## [5.5.1] — 2026-03-27

**PATCH** — Fix version-check: works from any directory, correct cache path detection. No contract or behavior changes.

### Fixed
- **version-check works from any directory:** Restructured into 3 parts — Part A (installed plugin status, always runs from anywhere), Part B (repo comparison, only in ceos-agents repo), Part C (cleanup checks, always runs). Previously required CWD to be the ceos-agents repository.
- **version-check cache path:** Was looking at `~/.claude/plugins/marketplaces/ceos-agents/` which does not exist. Now reads `~/.claude/plugins/installed_plugins.json` (the authoritative source) and finds `ceos-agents@ceos-agents` entry. Cache directories are snapshots, not git repos — removed broken `git pull` logic.
- **Legacy marketplace detection:** New Step 7 detects and warns about old `CLAUDE-agents` marketplace remnant (pre-rename clone, not used).
```

---

## Summary

### Files with version-check references (active plugin files):
| File | References | Notes |
|------|-----------|-------|
| `commands/version-check.md` | Primary command definition | 3-part structure (A/B/C) |
| `CLAUDE.md` | 2 | Command list + versioning policy example |
| `CHANGELOG.md` | 5+ | v5.5.1 fix + historical entries |
| `docs/reference/commands.md` | 5 | Full section + related-command cross-refs |
| `README.md` | 1 | Commands table |
| `skills/workflow-router/SKILL.md` | 2 | Intent route + non-destructive classification |
| `docs/guides/troubleshooting.md` | 2 | Upgrade troubleshooting steps |
| `commands/init.md` | 0 | No reference |
| `docs/guides/installation.md` | 0 | No reference |

### Key Fix Summary (v5.5.1)
The fix addressed two bugs identified in `REVIEW-REPORT-v3.1.0.md` [LOW-07]:
1. **CWD dependency:** Command only worked when run from the ceos-agents repo directory. Fixed by splitting into Part A (any directory), Part B (repo-only), Part C (any directory).
2. **Wrong cache path:** Was looking for `~/.claude/plugins/marketplaces/ceos-agents/` (non-existent). Fixed to read `~/.claude/plugins/installed_plugins.json` — the authoritative source.
3. **Bonus:** Step 7 added to detect legacy `CLAUDE-agents` marketplace remnant from pre-rename.
