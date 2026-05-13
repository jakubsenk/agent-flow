# Phase 2 Research Answers — Agent 1 (Items 1, 4, Release)

## Item 1: Config Template Autopilot Rows

### Q1.1 — Optional-section format and Autopilot insertion position across all 8 templates

**Evidence:**

**Template 1: `examples/configs/github-nextjs.md` (lines 48–134)**

This is the ONLY template with a `<!-- ... -->` comment block. All optional sections live inside the block. The comment block header is:
```
> **Uncomment and customize optional sections as needed.**

<!--
```
The optional sections inside the comment block (in order):
```
### Build & Test (extended — Verify command)
### Retry Limits (optional)
### Hooks (optional)
### Custom Agents (optional)
### Notifications (optional)
### Worktrees (optional)
### E2E Test (optional)
### Error Handling (optional)
### Extra labels (optional)
### Feature Workflow (optional)
### Decomposition (optional)
### Pipeline Profiles (optional)
### Metrics (optional)
```
Table header inside the comment block: `| Key | Value |`
`### Autopilot` is ABSENT from this template (confirmed: not present in the 134-line file).

**Template 2: `examples/configs/github-python-fastapi.md` (lines 1–47)**

NO optional sections at all. File ends at line 47 after `### Build & Test`. No comment block.
`### Autopilot` is ABSENT.

**Template 3: `examples/configs/github-dotnet.md` (lines 1–50)**

NO optional sections at all. File ends at line 50 after `### Build & Test`. No comment block.
`### Autopilot` is ABSENT.

**Template 4: `examples/configs/gitea-spring-boot.md` (lines 1–47)**

NO optional sections at all. File ends at line 47 after `### Build & Test`. No comment block.
`### Autopilot` is ABSENT.

**Template 5: `examples/configs/jira-react.md` (lines 1–46)**

NO optional sections at all. File ends at line 46 after `### Build & Test`. No comment block.
`### Autopilot` is ABSENT.

**Template 6: `examples/configs/youtrack-python.md` (lines 1–49)**

NO optional sections at all. File ends at line 49 after `### Build & Test`. No comment block.
`### Autopilot` is ABSENT.

**Template 7: `examples/configs/redmine-rails.md` (lines 1–48)**

NO optional sections at all. File ends at line 48 after `### Build & Test`. No comment block.
`### Autopilot` is ABSENT.

**Template 8: `examples/configs/redmine-oracle-plsql.md` (lines 1–181)**

This template is the SECOND template with explicit optional sections. It has a MIX:
- Some optional sections are UNCOMMENTED (active) with inline comments above them:
  ```
  ### Retry Limits       (lines 58–65, active, no "optional" label in heading)
  ### Pipeline Profiles  (lines 69–73, active, no "optional" label in heading)
  ### Agent Overrides    (lines 77–83, active, no "optional" label in heading)
  ### Local Deployment   (lines 85–97, active, no "optional" label in heading)
  ### Error Handling     (lines 98–103, active, no "optional" label in heading)
  ### Decomposition      (lines 104–111, active, no "optional" label in heading)
  ```
- Remaining optional sections are inside a `<!-- ... -->` comment block (lines 113–181):
  ```
  > **Uncomment and customize optional sections as needed.**

  <!--
  ### Feature Workflow (optional)
  ### Hooks (optional)
  ### Custom Agents (optional)
  ### Notifications (optional)
  ### Worktrees (optional)
  ### E2E Test (optional)
  ### Browser Verification (optional)
  ### Extra labels (optional)
  ### Module Docs (optional)
  ### Metrics (optional)
  -->
  ```
Table header: `| Key | Value |` for active sections; `| Key | Value |` inside comment block too.
`### Autopilot` is ABSENT from both active sections AND the comment block.

**Summary of conventions across 8 templates:**

| Template | Has comment block? | Active optional sections? | `### Autopilot` present? |
|----------|--------------------|--------------------------|--------------------------|
| github-nextjs | YES (lines 50–134) | NO | NO |
| github-python-fastapi | NO | NO | NO |
| github-dotnet | NO | NO | NO |
| gitea-spring-boot | NO | NO | NO |
| jira-react | NO | NO | NO |
| youtrack-python | NO | NO | NO |
| redmine-rails | NO | NO | NO |
| redmine-oracle-plsql | YES (lines 113–181) | YES (6 active sections) | NO |

**Key convention differences:**
1. 6 of 8 templates have NO optional sections at all — they are the minimal "required only" templates.
2. `github-nextjs` has a comment block with ALL optional sections but none active — it is the "full menu" template.
3. `redmine-oracle-plsql` has a hybrid: selected optional sections active (those relevant to Oracle) + comment block for the rest.
4. Table header is uniformly `| Key | Value |` (NOT `| Key | Default |`) in all templates.
5. Optional section headings: in comment blocks use `### Section Name (optional)` style; when active, no `(optional)` suffix.

**Answer:** All 8 templates are confirmed to lack `### Autopilot`. The insertion is straightforward: add it to the comment block in `github-nextjs.md` and `redmine-oracle-plsql.md`, and optionally add a minimal footer comment to the 6 bare templates. For the 6 bare templates, the cleanest approach (matching their pattern) is to add a trailing comment block with `### Autopilot (optional)` — consistent with the other templates' patterns.

**Insertion position (sort order):**
In `github-nextjs.md` comment block, `### Autopilot (optional)` should go AFTER `### Feature Workflow (optional)` and BEFORE or AFTER `### Decomposition (optional)`. Looking at CLAUDE.md ordering, Autopilot is the last optional section listed. In `redmine-oracle-plsql.md` comment block, it should go at the end (after `### Metrics (optional)`).

---

### Q1.2 — Canonical 7-key Autopilot table format

**Evidence:**

`docs/reference/config.md:26–41` (Example section):
```
### Autopilot
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |
```
(Note: this example omits the `| Key | Value |` header row — it uses bare rows without a header)

`docs/guides/autopilot.md:40–51`:
```
### Autopilot

| Key | Value |
|-----|-------|
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | true |
```
(Note: guide uses `Dry run | true` as the example value — dry-run mode for safe first test)

`skills/autopilot/SKILL.md:47–57` — canonical key definitions:
- `On error`: enum `skip | stop`, default `skip`
- `Dry run`: boolean, default `false`

`CLAUDE.md` Autopilot Config Keys table uses 3 columns: `Key | Default | Purpose` — this is the reference documentation format, NOT the config template format.

**Answer:** The authoritative template format is `| Key | Value |` with a `|-----|-------|` separator, values as literal defaults. The `On error` value in templates should be `skip` (not `skip | stop`). The `Dry run` value should be `false` (not `true` — the guide uses `true` as an example for safe first-run, but the canonical default is `false`). The `docs/guides/autopilot.md` example is the best model for the config template row content.

**Proposed canonical Autopilot row block for templates (comment-block style):**
```markdown
### Autopilot (optional)
| Key | Value |
|-----|-------|
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |
```

**For `redmine-oracle-plsql.md` active-section style (no `(optional)` suffix):**
```markdown
### Autopilot
| Key | Value |
|-----|-------|
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |
```

---

### Q1.3 — Does docs/reference/config.md have the Autopilot section already?

**Evidence:**

`docs/reference/config.md:1–51` (full Autopilot section):
```
# Config Reference

This file documents the **Autopilot** section and the updated **Notifications** event tokens...

## Autopilot

Optional section...

### Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| Max issues per run | int | `1` | Total cap on issues dispatched...
| Lock timeout | int (minutes) | `120` | Age threshold...
| Log file | string | `.ceos-agents/autopilot.log` | ...
| Bug limit | int | `0` | Per-type cap on bug dispatches...
| Feature limit | int | `0` | Per-type cap on feature dispatches...
| On error | enum | `skip` | Per-issue error policy...
| Dry run | bool | `false` | `true` = full short-circuit...
```

**Answer:** `docs/reference/config.md` IS already correct and complete. It has all 7 keys with a `| Key | Type | Default | Description |` 4-column format. This is the authoritative reference — templates should use its default values verbatim. The template format differs (2-column `| Key | Value |`) but the values match. Phase 4 implementers should mirror the defaults from `docs/reference/config.md` into the 2-column template format.

---

## Item 4: Lock-Timeout Text Alignment

### Q4.1 — Complete numeric audit of 120/121/125 in SKILL.md

**Evidence — all occurrences with exact line numbers:**

`skills/autopilot/SKILL.md`:
- Line 52: `| \`Lock timeout\` | integer (minutes) | 120 | Age threshold after which an existing lock directory is considered stale and auto-recovered. |`
- Line 101: `**Stale detection:** if an existing lock has \`acquired_at\` older than \`Lock timeout\` minutes (default 120), the lock is considered stale and recovery re-acquires it exactly once. Stale-arithmetic primary path uses \`awk mktime\`; on BusyBox < 1.30 (Alpine 3.9 and earlier) \`awk mktime\` is not available — the fallback uses a filesystem mtime check via \`find -mmin +121\`.`
- Line 127: `LOCK_TIMEOUT=${LOCK_TIMEOUT:-120}                    # minutes`
- Line 128: `LOCK_TIMEOUT_WITH_BUFFER=$((LOCK_TIMEOUT + 5))       # +5min NFS/CIFS skew buffer`
- Line 191: `        if find "$LOCK_DIR/owner.json" -mmin +121 -print 2>/dev/null | grep -q .; then`
- Line 202: `          echo "[autopilot][ERROR] Another Autopilot run in progress (awk mktime unavailable; mtime age < 121min)" >&2`
- Line 208: `        if [ "$age_min" -gt "$LOCK_TIMEOUT_WITH_BUFFER" ]; then`
- Line 238: `6. Stale threshold carries a +5 minute buffer to absorb NFS/CIFS clock skew.`
- Line 368: `...lock is <120min old, wait for stale timeout...`

`docs/guides/autopilot.md`:
- Line 45: `| Lock timeout | 120 |` (config example table)
- Line 58: `| \`Lock timeout\` | integer (minutes) | \`120\` | Age threshold...`
- Line 350: `**Auto-recovery:** Autopilot auto-recovers stale locks older than 120 minutes. If the lock file is older than 120 minutes (plus a 5-minute NFS/CIFS skew buffer), the next run re-acquires it automatically.`
- Line 370: `On minimal Alpine images with BusyBox < 1.30, \`awk mktime\` is not available. Autopilot falls back to a filesystem mtime check: if \`owner.json\` was last modified more than 121 minutes ago, the lock is considered stale.`
- Line 373: `find .ceos-agents/autopilot.lock/owner.json -mmin +121 -print`

**Analysis:**

The discrepancy table (Agent-3 hypothesis confirmed):

| Location | Value | Meaning |
|----------|-------|---------|
| Config key default | 120 | User-facing threshold |
| Primary path threshold | `LOCK_TIMEOUT_WITH_BUFFER` = 120+5 = 125 | Internal: 120 + NFS clock skew buffer |
| BusyBox fallback `find -mmin` | +121 | Internal: 120 + 1 min (BusyBox `-mmin` resolves to 1-minute granularity) |
| Troubleshooting prose (SKILL.md line 368) | `<120min old` | INCONSISTENT — says "120" but the actual threshold is 125 |

**Interpretation:**
- 120 = the user-facing contract (what operators configure and see in docs)
- 125 = the implementation threshold on the primary path (120 + 5 min NFS/CIFS skew buffer)
- 121 = the BusyBox fallback threshold (`find -mmin +121` means "older than 121 minutes" — a 1-minute conservative buffer for `-mmin` integer resolution)

**The bug:** SKILL.md line 368 says `lock is <120min old` in the troubleshooting section, but the actual stale threshold on the primary path is 125 minutes (and 121 on BusyBox). An operator reading this would incorrectly think a 122-minute-old lock (primary path: NOT stale, because 122 < 125) would auto-recover. The troubleshooting text should say the effective threshold is 120 minutes as configured but auto-recovery only fires at 120+buffer minutes.

The guide (`docs/guides/autopilot.md` line 350) already correctly documents both: "older than 120 minutes (plus a 5-minute NFS/CIFS skew buffer)". The BusyBox path is also documented at line 370 with the 121-minute value explained.

**The SKILL.md gap:** Line 368 says `<120min old` without mentioning the buffer. The guide is MORE accurate than SKILL.md on this specific point.

**Proposed prose fix for SKILL.md line 368:**

Current text:
```
- **`[autopilot][ERROR] Another Autopilot run in progress`** → check `.ceos-agents/autopilot.lock/owner.json` for the owning PID and host. If the owning process is gone but the lock is <120min old, wait for stale timeout or manually `rm -rf .ceos-agents/autopilot.lock/` (only after verifying no live process).
```

Proposed replacement:
```
- **`[autopilot][ERROR] Another Autopilot run in progress`** → check `.ceos-agents/autopilot.lock/owner.json` for the owning PID and host. If the owning process is gone but the lock is less than `Lock timeout` minutes old (default 120 min; effective threshold is 120 + 5 min NFS/CIFS buffer = 125 min on primary path, 121 min on BusyBox fallback), wait for stale auto-recovery or manually `rm -rf .ceos-agents/autopilot.lock/` (only after verifying no live process).
```

**Alternatively, a shorter 1-sentence fix** (drop-in for the parenthetical):
Replace `<120min old` with `less than the effective stale threshold (Lock timeout + 5 min buffer; default 125 min, or 121 min on BusyBox fallback)`.

**Answer summary:** 120 is the user-facing contract. 125 is the primary-path implementation threshold (120 + 5). 121 is the BusyBox fallback threshold (120 + 1). These are INTENTIONAL different values, not a bug. The only textual bug is SKILL.md line 368 which says `<120min` but should reference the effective threshold including the buffer. The `docs/guides/autopilot.md` already correctly documents all three values.

---

### Q4.2 — Guide phrasing vs SKILL.md consistency

**Evidence:**

`docs/guides/autopilot.md:350`:
```
**Auto-recovery:** Autopilot auto-recovers stale locks older than 120 minutes. If the lock file is older than 120 minutes (plus a 5-minute NFS/CIFS skew buffer), the next run re-acquires it automatically.
```

`docs/guides/autopilot.md:368–376`:
```
### BusyBox awk fallback (Alpine 3.9 and earlier)

On minimal Alpine images with BusyBox < 1.30, `awk mktime` is not available. Autopilot falls back to a filesystem mtime check: if `owner.json` was last modified more than 121 minutes ago, the lock is considered stale. This check uses:

```bash
find .ceos-agents/autopilot.lock/owner.json -mmin +121 -print
```
```

**Answer:** The guide IS more complete than SKILL.md line 368. The guide names all three values (120, 125 via "+5 buffer", and 121 for BusyBox) in appropriate sections. SKILL.md line 368 is the ONLY location with the inconsistency — a simple amendment to that one line is sufficient. No changes needed to the guide.

---

## Release Process

### Q7.1 — CHANGELOG v6.8.0 structure, Known Issues, and version-bump pre-flight guard

**Evidence — CHANGELOG.md v6.8.0 structure (lines 10–46):**

Section headings in order:
1. `## [6.8.0] — 2026-04-17` + bold summary line
2. `### Added` (bullet list with bold feature names)
3. `### Changed` (bullet list with bold file names)
4. `### Migration notes` (bullet list)
5. `### Known Issues (deferred to v6.8.1)` (bullet list)
6. `### Internal` (bullet list)

Key verbatim from lines 41–42:
```
### Known Issues (deferred to v6.8.1)
- **`examples/config-templates/*`** — Autopilot section not yet added per template. Operators can copy from `docs/reference/config.md`.
```
(Note: the Known Issues entry says `examples/config-templates/*` but the actual path is `examples/configs/` — this is a pre-existing path discrepancy in the CHANGELOG, not introduced by this research.)

**Evidence — version-bump SKILL.md pre-flight guards (lines 18–37):**

```
## Pre-bump Checklist

Before running version-bump, ensure:
1. **Tests pass:** Run `./tests/harness/run-tests.sh` — all scenarios must PASS
2. **Changelog exists:** `CHANGELOG.md` must have an entry for the new version
3. **Content committed:** All feature/fix changes must be committed BEFORE version-bump. Version-bump creates its own separate commit on top.

If any of these are not done, do them first — do not skip.
```

Step 6 (CHANGELOG guard):
```
6. **CHANGELOG guard:** Read `CHANGELOG.md` and verify it contains a heading `## [{new_version}]` (where `{new_version}` is the version about to be set). If not found → error: "CHANGELOG.md has no entry for {new_version}. Add a changelog entry before bumping."
```

Step 7 (Uncommitted changes guard):
```
7. **Uncommitted changes guard:** Run `git status`. If there are uncommitted changes (staged or unstaged, excluding `.claude/settings.local.json`) → error: "Uncommitted changes detected. Commit content changes before version-bump."
```

Steps 8–11: version-bump only writes `plugin.json` and `marketplace.json`, commits those two files, and creates a tag. It does NOT touch `CHANGELOG.md`.

**Confirmed commit sequence:**
1. Content changes + `CHANGELOG.md` entry for `[6.8.1]` → committed together (content commit)
2. `/ceos-agents:version-bump patch` → separate commit (`chore: bump version 6.8.0 → 6.8.1`) + tag `v6.8.1`

The CHANGELOG guard at Step 6 verifies `## [6.8.1]` heading exists BEFORE the bump, confirming that the human must author the entry in the content commit.

**Proposed v6.8.1 CHANGELOG entry structure:**

```markdown
## [6.8.1] — 2026-04-18

**PATCH** — Config template completeness: Autopilot section added to all 8 config templates. Lock-timeout troubleshooting prose alignment. Crash-recovery regression test for fixer-reviewer token accumulation. Test harness exit-code robustness.

### Fixed
- **`examples/configs/*`** — `### Autopilot` section (7 keys, commented-out) added to all 8 config templates. Closes Known Issue from v6.8.0.
- **`skills/autopilot/SKILL.md` line 368** — Troubleshooting prose: `<120min old` → references effective stale threshold (120 + 5 min buffer = 125 min primary; 121 min BusyBox fallback). Consistent with `docs/guides/autopilot.md`.
- **[Item 2 — issue_id regex gate]** — [to be filled by Phase 4]
- **[Item 3 — JSON-encode payload note]** — [to be filled by Phase 4]
- **[Item 5 — crash-recovery test]** — New scenario `tests/scenarios/v681-autopilot-crash-recovery.sh` verifying fixer-reviewer token accumulation write-after-iteration.
- **[Item 6 — exit-code harness]** — [to be filled by Phase 4]

### Internal
- [test scenario count update]
```

**Notes on v6.8.1 structure:**
- No `### Added` section (all items are fixes/corrections, no new features)
- No `### Changed` section unless CLAUDE.md counts change (optional config sections stay at 18; skills stay at 29)
- `### Fixed` is the primary section (this is a PATCH release)
- `### Known Issues` section is DROPPED (the known issue from 6.8.0 is being resolved)
- `### Internal` section for test count update

**Answer:** The CHANGELOG.md must have `## [6.8.1]` heading authored in the content commit before `/ceos-agents:version-bump patch` is run. Version-bump ONLY writes `plugin.json` and `marketplace.json`; it does NOT write `CHANGELOG.md`. The pre-flight guard at Step 6 enforces this: it errors if `## [6.8.1]` is absent. The v6.8.0 `### Known Issues` entry used `examples/config-templates/*` as the path (line 42) but the actual path is `examples/configs/` — Phase 4 should use `examples/configs/*` in the v6.8.1 Fixed entry.

---

## Cross-Cutting Notes

### Path discrepancy in Known Issues
`CHANGELOG.md:42` says `examples/config-templates/*` but the actual directory is `examples/configs/`. This is a minor existing inaccuracy. Phase 4 should use `examples/configs/*` in the v6.8.1 entry.

### Template convention divergence — 6 bare vs 2 full
The 6 minimal templates (github-python-fastapi, github-dotnet, gitea-spring-boot, jira-react, youtrack-python, redmine-rails) have NO optional sections at all. Adding a `### Autopilot` block to them requires adding a comment block from scratch. The minimal approach: append the comment block verbatim (matching github-nextjs style) to each bare template. This is additive and non-breaking.

### `| Key | Value |` table header — uniform across all templates
Every table in every template uses `| Key | Value |` with `|------|---------|` or `|-----|-------|` separator (minor spacing variation). This is the authoritative format for config templates.
