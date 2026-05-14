# Phase 2 Research Agent 2: Version References, Plugin Config, and Cleanup Inventory

**Research conducted:** 2026-05-13  
**Repository:** C:\gitea_agent-flow  
**Scope:** Internal version references (v6–v10), agent version labels, plugin configuration, and files to delete

---

## V-1: Internal Version References (Search Results)

### Files with Version References (v6.x–v10.x)

**User-facing files with version tags:**

1. **CHANGELOG.md** — Extensive v9.x and v10.x references
   - Lines 10–162+ contain version release notes for v10.2.0, v10.1.0, v10.0.0, v9.6.1, v9.2.0, v9.1.0, v9.0.2, etc.
   - Patterns found: "v10.0.0", "v10.2.0", "v9.0.0", "v9.1.0", "v9.2.0", "v9.4.x", "v9.5.0", "v9.6.0", "v9.6.1", "v9.7.0", "v9.8.0", "v9.9.0", "v8.0.0", "v7.0.0", "v6.x", "v6.7.x", "v6.8.0", "v6.9.0", "v6.9.1", "v6.10.0"
   - Primary version format: vX.Y.Z (semantic versioning)
   - Special instances: "v10.0.0+" (forward compatibility marker)

2. **CLAUDE.md** (L101–106) — Mandatory version contracts for agents
   - **L101:** "## Output Contract (v9.0.0+, mandatory — structured output schema agents return)"
   - **L102:** "## Step Completion Invariants (v10.0.0+, mandatory — fields the orchestrator MUST verify in state.json...)"
   - **L106:** "> **v10.0.0 reliability contract:** \## Step Completion Invariants\ is a mandatory structured section..."
   - Also contains "v9.0.0+, mandatory" for Output Contract and "v10.0.0+, mandatory" for Step Completion Invariants
   - Migration guide reference: "migration-v7-to-v8.md", "migration-v8-to-v9.md"

3. **README.md** (L72)
   - "Migrating from v7?" with link to migration guide
   - Pattern: "v7", "v8", "v9" context

4. **docs/guides/migration-v7-to-v8.md** (L1–210)
   - Title: "Migration Guide: v7.0.0 → v8.0.0"
   - L3: "(v9.5.0): The \/migrate-config\ skill referenced throughout this guide was removed in v9.5.0"
   - L11: "v8.0.0 is the last major structural change before the v9.0.0 public launch"
   - L41: "Verify your v7.0.0 pipeline is working"
   - L53–88: Before/after v7.0.0 vs v8.0.0 format changes
   - L108–137: Agent list migration v7 to v8
   - L210+: Pipeline profiles and step override documentation for v8.0.0

5. **docs/guides/migration-v8-to-v9.md** (L1–16)
   - Title: "Migration Guide: v8.0.0 → v9.0.0"
   - L5: "v9.0.0 is a MAJOR release bundling three deliverables"
   - L8: "Pre-announced \.md\ agent overlay hard removal. Per \docs/guides/migration-v7-to-v8.md:445-454\, v8.0.0 emitted [WARN] on \customization/{agent}.md\ overlays. v9.0.0 emits [ERROR] and refuses dispatch"
   - L11: "The agent count moves from 18 → 17 in v9.0.0 — \gents/stack-selector.md\ is deleted"

6. **docs/plans/roadmap.md** (L5–6, L24+)
   - **L5:** "> **Current version:** v9.6.1"
   - **L6:** "> **Last updated:** 2026-05-11"
   - L24–100+: Historical roadmap entries for v4.1.0, v5.0.0, v5.1.0 with detailed delivery notes

7. **docs/reference/mcp-server-versions.md** (L6–7, L14–21)
   - L6: "Last verified: 2026-05-09"
   - L7: "Hard deadline: 2026-06-30 — Atlassian \/sse\ endpoint EOL"
   - L14–21: MCP server version pins (e.g., "gitea/gitea-mcp v1.1.0", protocol date "2025-06-18")

### Version Reference Forms Found

| Form | Occurrences | User-Facing? | Context |
|------|------------|--------------|---------|
| vX.Y.Z (semantic) | Dominant | Yes | Release identifiers (v10.2.0, v9.6.1, v8.0.0) |
| v9.0.0+, mandatory | 2 in CLAUDE.md | Yes | Agent definition contracts (Output Contract, Step Completion Invariants) |
| v10.0.0+, mandatory | 2 in CLAUDE.md | Yes | Agent definition contracts (Step Completion Invariants) |
| vX.Y.Z+ | Several | Yes | Forward-compatibility markers (e.g., "v6.8.0+", "v9.5.0+") |
| Migration guide refs | 3 files | Yes | "migration-v7-to-v8.md", "migration-v8-to-v9.md" |

---

## V-2: Agent Version Labels (agents/ Directory Scan)

### Pattern Search: "v9.0.0+, mandatory" and "v10.0.0+, mandatory"

**Result:** No exact matches for these patterns found in agents/*.md files.

**Note:** The agents/*.md files do not contain the strings "v9.0.0+, mandatory" or "v10.0.0+, mandatory" directly. These patterns are **defined in CLAUDE.md** (the schema template) but **not duplicated in individual agent files**.

### Related Content Found in agents/*.md

Three agent files contain **references to v10.0.0** in prose (not as version labels):

1. **agents/fixer.md (L139)**
   - "This invariant check is the agent-side half of the v10.0.0 3-layer defense; pairs with \hooks/validate-dispatch.sh\ (host-side witness audit) and \core/lib/stage-invariant.sh\ (witness compute helper)."

2. **agents/publisher.md (L136)**
   - "This invariant check is the agent-side half of the v10.0.0 3-layer defense; pairs with \hooks/validate-dispatch.sh\ (host-side witness audit) and \core/lib/stage-invariant.sh\ (witness compute helper)."

3. **agents/reviewer.md (L153)**
   - "This invariant check is the agent-side half of the v10.0.0 3-layer defense; pairs with \hooks/validate-dispatch.sh\ (host-side witness audit) and \core/lib/stage-invariant.sh\ (witness compute helper)."

**No agent files have explicit "mandatory" version labels in headers.** The mandatory version requirement is encoded in CLAUDE.md as a schema template (L101–106).

---

## V-3: Current Version Fields in Plugin Configuration Files

### C:\gitea_agent-flow\.claude-plugin\plugin.json

`
{
  "name": "ceos-agents",
  "description": "CEOS CLAUDE Agents — development automation: bug-fix, feature pipeline, scaffold, decomposition, dashboard",
  "version": "10.2.0",
  "author": {
    "name": "Filip Sabacky"
  },
  "repository": "https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git",
  "license": "MIT"
}
`

**Keys present:**
- name (string)
- description (string)
- version (string) — **Current: "10.2.0"**
- author.name (string)
- repository (string)
- license (string)

### C:\gitea_agent-flow\.claude-plugin\marketplace.json

`
{
  "name": "ceos-agents",
  "owner": {
    "name": "Filip Sabacky"
  },
  "plugins": [
    {
      "name": "ceos-agents",
      "source": "./",
      "description": "CEOS CLAUDE Agents — development automation: bug-fix, feature pipeline, scaffold, decomposition, dashboard",
      "version": "10.2.0",
      "license": "MIT"
    }
  ]
}
`

**Keys present:**
- name (string)
- owner.name (string)
- plugins[0].name (string)
- plugins[0].source (string)
- plugins[0].description (string)
- plugins[0].version (string) — **Current: "10.2.0"**
- plugins[0].license (string)

### Root-Level Files Check

- **C:\gitea_agent-flow\plugin.json** — NOT FOUND (no root-level plugin.json)
- **C:\gitea_agent-flow\marketplace.json** — NOT FOUND (no root-level marketplace.json)

**Conclusion:** Version configuration is centralized in .claude-plugin/ directory only. Both files currently show version **10.2.0**.

---

## D-1: Files to Delete — Existence Confirmation

### .forge.bak-*/ Directories

| Finding | Count | Details |
|---------|-------|---------|
| **Exist?** | YES | 61 backup directories found |
| **Sample (first 5):** | | • .forge.bak-20260325-204006 |
| | | • .forge.bak-20260327-083030 |
| | | • .forge.bak-20260327-114641 |
| | | • .forge.bak-20260328-183659 |
| | | • .forge.bak-20260330-122643 |
| **Action** | DELETE | All 61 directories should be removed per cleanup plan |

### docs/plans/ Directory

| Finding | Details |
|---------|---------|
| **Exist?** | YES |
| **File count** | 96 markdown files |
| **Notable subdirs** | readmine-project/ (3 files) |
| **Action** | DELETE per cleanup spec |

Sample files in docs/plans/:
- roadmap.md
- sprint-planning-feature-spec.md
- 2026-04-29-overlay-toml-dispatch-hotfix-brief.md
- competitive-analysis.md
- readmine-project/drmax-readmine-test-setup-zadani.md

### docs/superpowers/ Directory

| Finding | Details |
|---------|---------|
| **Exist?** | YES |
| **File count** | 8 markdown files (in specs/ subdirectory) |
| **Sample files** | • 2026-04-27-F-dashboard-brainstorm.md |
| | • 2026-04-27-E-showcase-brainstorm.md |
| | • 2026-04-27-ceo-presentation-narrative.md |
| | • 2026-04-27-B-hitl-design.md |
| | • 2026-04-26-A-agent-shape-design.md |
| **Action** | DELETE per cleanup spec |

### skills/version-bump/ Directory

| Finding | Details |
|---------|---------|
| **Exist?** | YES |
| **Purpose** | Skill for version bumping (SKILL.md + steps) |
| **Action** | DELETE per cleanup spec |

### grep.exe.stackdump

| Finding | Details |
|---------|---------|
| **Exist?** | YES, at root level |
| **Location** | C:\gitea_agent-flow\grep.exe.stackdump |
| **Action** | DELETE |

### nul

| Finding | Details |
|---------|---------|
| **Exist?** | NO |
| **Location** | C:\gitea_agent-flow\nul (searched but not found) |
| **Status** | Confirmed absent — no action needed |

### REVIEW-REPORT-*.md Files

| Finding | Details |
|---------|---------|
| **Exist?** | YES, 1 file found |
| **File** | REVIEW-REPORT-v3.1.0.md |
| **Location** | C:\gitea_agent-flow\REVIEW-REPORT-v3.1.0.md |
| **Action** | DELETE (matches .gitignore pattern REVIEW-REPORT-*.md) |

### CEO-deck Related Files

| Finding | Details |
|---------|---------|
| **CEO-deck.md** | NOT FOUND |
| **CEO-deck-marp.md** | NOT FOUND |
| **CEO-deck-marp.pdf** | NOT FOUND |
| **Status** | No CEO-deck files exist in repository |
| **Action** | N/A — no deletion needed |

---

## G-1: Current .gitignore State

**File location:** C:\gitea_agent-flow\.gitignore

**Current contents:**
\\\
.vs/
nul
.claude/settings.local.json
.env
\\\

**Analysis:**
- 4 entries total
- Notably **ABSENT:** Any patterns for .forge/, .forge.bak-*/, .forge.v*/, .ceos-agents/, *.stackdump, or REVIEW-REPORT-*.md
- The nul entry exists in .gitignore even though the nul file itself is NOT present on disk

---

## G-2: Required Additions to .gitignore

**Patterns to add (per cleanup spec):**

| Pattern | Currently in .gitignore? | Status | Reason |
|---------|-------------------------|--------|--------|
| .forge/ | NO | **MISSING** | Excludes current forge pipeline workspace |
| .forge.bak-*/ | NO | **MISSING** | Excludes 61 backup directories awaiting cleanup |
| .forge.v*/ | NO | **MISSING** | Excludes future version-tagged forge backups |
| .ceos-agents/ | NO | **MISSING** | Excludes per-run pipeline state (state.json, pipeline.log, etc.) |
| .claude/ | PARTIAL | Partially present (only .claude/settings.local.json is ignored) | Should be broadened to .claude/ (entire dir) |
| *.stackdump | NO | **MISSING** | Excludes Cygwin/MSYS2 crash dumps (e.g., grep.exe.stackdump) |
| nul | YES | Present | Correct |
| REVIEW-REPORT-*.md | NO | **MISSING** | Excludes versioned review reports |
| docs/plans/ | NO | **MISSING** | Excludes internal planning docs (per cleanup spec) |

**Summary:** 7 new patterns need to be added (or clarified for .claude/).

---

## Summary

### Key Findings

1. **Version References:** Current version is **10.2.0** (per plugin.json and marketplace.json). CHANGELOG and CLAUDE.md contain extensive v6–v10 references; all are correctly formatted as vX.Y.Z or v{X}.0.0+, mandatory patterns.

2. **Mandatory Labels:** The strings "v9.0.0+, mandatory" and "v10.0.0+, mandatory" appear **only in CLAUDE.md** (L101–102) as schema template definitions, not in individual agent files. Three agents (fixer, publisher, reviewer) reference v10.0.0 in prose at lines 136–153.

3. **Plugin Config:** Both .claude-plugin/plugin.json and .claude-plugin/marketplace.json are properly configured with version **10.2.0**. No root-level files exist.

4. **Files to Delete:** 
   - 61 .forge.bak-*/ directories (confirmed)
   - 96 files in docs/plans/ (confirmed)
   - 8 files in docs/superpowers/ (confirmed)
   - skills/version-bump/ skill (confirmed)
   - REVIEW-REPORT-v3.1.0.md (confirmed)
   - grep.exe.stackdump (confirmed)
   - nul (NOT found — skip)

5. **.gitignore Gaps:** Current file is minimal (4 entries). Needs 7 new patterns to fully cover .forge, .forge.bak-*, .ceos-agents, *.stackdump, REVIEW-REPORT-*.md, and docs/plans/.
