# Phase 2: Directory Restructure — Implementation Plan

**Phase:** 2 of 4 (Documentation Overhaul)
**Design doc:** `docs/plans/2026-03-01-documentation-overhaul-design.md`
**Scope:** Move files to Diataxis structure, create directory skeleton, update links
**Risk:** LOW
**Estimated changes:** 4 file moves, 3 link edits, 1 new file, 1 directory deletion

---

## Prerequisites

1. **Phase 1 (Translation) MUST be complete** — all 4 files in `docs/setup/` must already be translated to English. Verify by confirming no Czech prose remains in:
   - `docs/setup/installation.md`
   - `docs/setup/tokens.md`
   - `docs/setup/mcp-configuration.md`
   - `docs/setup/cross-platform-checklist.md`
2. **`README.cs.md` must be deleted** — Phase 1 removes this file. Confirm it no longer exists (it contains `docs/setup/` references that would otherwise need updating).
3. **Clean working tree** — no uncommitted changes.

---

## Steps

### Step 1: Create new directories

```bash
mkdir -p docs/guides
mkdir -p docs/reference
```

Both directories are new. `docs/guides/` will receive the 4 moved files. `docs/reference/` is an empty skeleton for Phase 3 (new reference docs).

### Step 2: Move files

Execute all 4 moves using `git mv` to preserve history:

```bash
git mv docs/setup/installation.md docs/guides/installation.md
git mv docs/setup/mcp-configuration.md docs/guides/mcp-configuration.md
git mv docs/setup/tokens.md docs/guides/tokens.md
git mv docs/setup/cross-platform-checklist.md docs/guides/cross-platform.md
```

Note: the fourth file is **renamed** during the move (`cross-platform-checklist.md` → `cross-platform.md`). This is intentional — the shorter name aligns with the Diataxis guide naming convention.

### Step 3: Update internal links

Three files contain active references to `docs/setup/` paths that must be updated. Historical `docs/plans/` files are left as-is (archival content).

#### 3a. `CLAUDE.md` — line 21

| | Value |
|---|---|
| **File** | `CLAUDE.md` |
| **Line** | 21 |
| **Old** | `- \`docs/setup/\` — Installation and configuration guides` |
| **New** | `- \`docs/guides/\` — Installation and configuration guides` |

#### 3b. `CHANGELOG.md` — line 164

| | Value |
|---|---|
| **File** | `CHANGELOG.md` |
| **Line** | 164 |
| **Old** | `- docs: instalační průvodce — \`docs/setup/\` (v1.2)` |
| **New** | `- docs: instalační průvodce — \`docs/guides/\` (v1.2)` |

Note: This line will already be translated to English after Phase 1. The exact old/new values shown above reflect the **pre-Phase-1 state** for traceability. At execution time, use the actual English text from the translated file and replace only the path portion `docs/setup/` → `docs/guides/`.

#### 3c. `docs/guides/installation.md` — line 74

This is a relative cross-reference between files that are all moving to the same directory. The link target file has been renamed.

| | Value |
|---|---|
| **File** | `docs/guides/installation.md` (already moved in Step 2) |
| **Line** | 74 |
| **Old** | `- Detaily viz [cross-platform-checklist.md](cross-platform-checklist.md)` |
| **New** | `- Detaily viz [cross-platform.md](cross-platform.md)` |

Note: After Phase 1 translation, this line will be in English. At execution time, match the actual translated text and update only the link target `cross-platform-checklist.md` → `cross-platform.md`.

### Step 4: Delete empty directory

After all 4 files are moved, `docs/setup/` should be empty:

```bash
rmdir docs/setup
```

Git does not track empty directories, so `git mv` in Step 2 already handles this implicitly. If the directory still appears on disk, remove it manually. Verify:

```bash
ls docs/setup 2>/dev/null && echo "ERROR: docs/setup/ still exists" || echo "OK: docs/setup/ removed"
```

### Step 5: Create `docs/reference/.gitkeep`

Since `docs/reference/` is empty until Phase 3, add a `.gitkeep` so git tracks the directory:

```bash
touch docs/reference/.gitkeep
git add docs/reference/.gitkeep
```

### Step 6: Create `docs/plans/README.md`

Create the design doc index file with the following content:

```markdown
# Design Documents Index

This directory contains all architecture decision records (ADRs) and design documents
for the CLAUDE-agents plugin. Documents are listed in chronological order.

## Legend

| Status | Meaning |
|--------|---------|
| IMPLEMENTED | Design was approved and fully implemented in the listed version |
| SUPERSEDED | Design was replaced by a newer, consolidated document |
| APPROVED | Design was approved but implementation is tracked by a newer consolidated doc |
| PROPOSED | Design is under review; not yet implemented |
| ARCHIVE | Supporting document (review, sync doc, upgrade guide) — not a design |

---

## Documents

### Foundation (v1.0 era)

| Date | File | Title | Status | Version |
|------|------|-------|--------|---------|
| 2026-02-16 | `2026-02-16-commands-to-plugin-design.md` | Commands to Plugin Migration | APPROVED | v1.0 |
| 2026-02-19 | `2026-02-19-skills-vs-commands.md` | Skills vs Commands | APPROVED | v1.0 |
| 2026-02-19 | `2026-02-19-plugin-update-process.md` | Plugin Update Process | APPROVED | v1.0 |
| 2026-02-19 | `2026-02-19-agent-docs-audit.md` | Agent Docs Audit | APPROVED | v1.0 |
| 2026-02-24 | `2026-02-24-genericize-and-routing-skill.md` | Genericize Plugin + Routing Skill | APPROVED | v1.0 |

### v1.x–v2.x Designs (consolidated into v2.0.0 release)

| Date | File | Title | Status | Version |
|------|------|-------|--------|---------|
| 2026-02-25 | `2026-02-25-v1.2-installation-docs-design.md` | Installation Documentation | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.3-config-validation-design.md` | Config Validation (`/check-setup`) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.4-linux-compatibility-design.md` | Linux Compatibility | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.5-pipeline-reporting-design.md` | Pipeline Reporting (Dry-Run + Summary) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.6-pipeline-extension-design.md` | Pipeline Extension (Worktrees, Multi-tracker, Rollback) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.7-reliability-design.md` | Reliability (E2E Tests, Retry Limits, Error Reporting) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.8-pipeline-resume-design.md` | Pipeline Resume (`/resume-ticket`) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.9-dx-commands-design.md` | DX Commands (`/status`, `/onboard`, `/changelog`) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v2.0-extensibility-design.md` | Extensibility (Hooks + Custom Agents) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v2.1-integrations-design.md` | Integrations (Webhook, `/version-check`, Token Estimation) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v2.0-sync-document.md` | v2.0 Sync Document (conflict matrix + dependency graph) | ARCHIVE | v2.0 |
| 2026-02-25 | `2026-02-25-v2.0-implementation-plan.md` | v2.0 Implementation Plan | ARCHIVE | v2.0 |
| 2026-02-25 | `2026-02-25-bifito-v2.0-upgrade.md` | BIFITO v2.0 Upgrade Guide | ARCHIVE | v2.0 |
| 2026-02-25 | `2026-02-25-future-roadmap.md` | Future Roadmap (v2.0 era) | SUPERSEDED | v2.0 |

### v3.0 Designs (consolidated into v3.0.0 release)

| Date | File | Title | Status | Version |
|------|------|-------|--------|---------|
| 2026-02-27 | `2026-02-27-01-feature-pipeline-v3.0.md` | Feature Pipeline Design | SUPERSEDED | v3.0 |
| 2026-02-27 | `2026-02-27-02-decomposition-v3.1.md` | Task Decomposition Design | SUPERSEDED | v3.0 |
| 2026-02-27 | `2026-02-27-03-dashboard-v3.2.md` | Dashboard L1 Design | SUPERSEDED | v3.0 |
| 2026-02-27 | `2026-02-27-04-scaffold-plugin-v1.0.md` | Scaffold Plugin Design | SUPERSEDED | v3.0 |
| 2026-02-27 | `2026-02-27-01-feature-pipeline-v3.0-REVIEW.md` | Feature Pipeline Code Review | ARCHIVE | v3.0 |
| 2026-02-27 | `2026-02-27-02-decomposition-v3.1-REVIEW.md` | Task Decomposition Code Review | ARCHIVE | v3.0 |
| 2026-02-27 | `2026-02-27-03-dashboard-v3.2-REVIEW.md` | Dashboard L1 Code Review | ARCHIVE | v3.0 |
| 2026-02-27 | `2026-02-27-04-scaffold-plugin-v1.0-REVIEW.md` | Scaffold Plugin Code Review | ARCHIVE | v3.0 |
| 2026-02-28 | `2026-02-28-v3.0-unified-design.md` | v3.0 Unified Design Document | IMPLEMENTED | v3.0 |
| 2026-02-28 | `2026-02-28-v3.0-plan-review.md` | v3.0 Implementation Plan Review | ARCHIVE | v3.0 |
| 2026-02-28 | `2026-02-28-v3.0-implementation-plan.md` | v3.0 Implementation Plan | ARCHIVE | v3.0 |

### v3.1 Designs (consolidated into v3.1.0 release)

| Date | File | Title | Status | Version |
|------|------|-------|--------|---------|
| 2026-02-28 | `2026-02-28-v3.1-v5.0-roadmap-design.md` | v3.1–v5.0 Roadmap | SUPERSEDED | v3.1 |
| 2026-03-01 | `2026-03-01-v3.1-unified-design.md` | v3.1 Unified Release Design | IMPLEMENTED | v3.1 |
| 2026-03-01 | `2026-03-01-v3.1-implementation-plan.md` | v3.1 Implementation Plan | ARCHIVE | v3.1 |
| 2026-03-01 | `v3.1-scalability-assessment.md` | Pure Markdown Scalability Assessment | ARCHIVE | v3.1 |

### v3.2 Documentation Overhaul

| Date | File | Title | Status | Version |
|------|------|-------|--------|---------|
| 2026-03-02 | `2026-03-01-documentation-overhaul-design.md` | Documentation Overhaul — Full EN Rewrite | PROPOSED | v3.2 |
| 2026-03-02 | `2026-03-02-docs-overhaul-phase-1-plan.md` | Phase 1: Translation (CZ → EN) Plan | PROPOSED | v3.2 |
| 2026-03-02 | `2026-03-02-docs-overhaul-phase-2-plan.md` | Phase 2: Directory Restructure Plan | PROPOSED | v3.2 |
| 2026-03-02 | `2026-03-02-docs-overhaul-phase-3-plan.md` | Phase 3: New Documentation Plan | PROPOSED | v3.2 |
| 2026-03-02 | `2026-03-02-docs-overhaul-phase-4-plan.md` | Phase 4: README Rewrite Plan | PROPOSED | v3.2 |
```

---

## Critical Points

1. **Phase 1 must be complete first.** If Phase 1 has not translated the setup docs, moving them to `docs/guides/` creates Czech files in the new structure — defeating the purpose.
2. **The `cross-platform-checklist.md` → `cross-platform.md` rename** changes the file name. The only internal cross-reference (in `installation.md` line 74) must be updated in the same commit.
3. **Historical `docs/plans/` files are NOT updated.** They contain ~40 references to `docs/setup/` but are archival records. Modifying them would falsify history. The `docs/plans/README.md` index provides navigation.
4. **`README.cs.md` is already deleted** in Phase 1. It contained 4 references to `docs/setup/` — these are no longer relevant.
5. **`REVIEW-REPORT-v3.1.0.md` is untracked.** It references `docs/setup/` paths but is not part of the committed codebase. It should be deleted as part of stale artifact cleanup (design doc Section 5.2), not updated.
6. **Relative cross-references between the 4 guide files** (`tokens.md`, `mcp-configuration.md`, `cross-platform.md`) use relative paths. Since all 4 files move to the same directory (`docs/guides/`), these relative links continue to work without changes — except for the renamed file.

---

## Verification

After all steps, run these checks to confirm correctness:

### V1: No remaining `docs/setup/` references in active files

```bash
grep -rn "docs/setup/" --include="*.md" \
  --exclude-dir=docs/plans \
  --exclude="REVIEW-REPORT-v3.1.0.md" \
  .
```

Expected: **zero matches.** Any match indicates a missed link update.

### V2: Directory structure is correct

```bash
ls docs/guides/
```

Expected: `cross-platform.md  installation.md  mcp-configuration.md  tokens.md`

```bash
ls docs/reference/
```

Expected: `.gitkeep`

```bash
ls docs/setup/ 2>/dev/null
```

Expected: error (directory should not exist)

### V3: Cross-reference integrity

```bash
grep -n "cross-platform-checklist" docs/guides/installation.md
```

Expected: **zero matches.** The old filename should be replaced with `cross-platform`.

### V4: Plans index exists

```bash
test -f docs/plans/README.md && echo "OK" || echo "MISSING"
```

Expected: `OK`

### V5: Git status is clean after commit

```bash
git status
```

Expected: nothing to commit, working tree clean.

---

## Commit Message

```
docs: restructure docs/ directory to Diataxis layout (Phase 2)

- Move docs/setup/ → docs/guides/ (4 files)
- Rename cross-platform-checklist.md → cross-platform.md
- Create docs/reference/ skeleton for Phase 3
- Create docs/plans/README.md design doc index
- Update internal links in CLAUDE.md, CHANGELOG.md, installation.md
```
