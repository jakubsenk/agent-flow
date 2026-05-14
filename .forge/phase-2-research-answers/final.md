# Phase 2: Research Answers — Final

> **Synthesized from:** agent-1.md (occurrence inventory), agent-2.md (version refs, plugin config, deletions), and direct file reads for Section 3 (agent-3.md was not produced — gap filled from live file reads).
> **Date:** 2026-05-13

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Files with "ceos-agents" (any pattern, main repo excl. .forge) | 224 |
| Estimated total occurrences (main repo) | ~3,900+ |
| Files with "ceos-agents:" skill-prefix pattern | 127 |
| Files with internal URL (gitea.internal.ceosdata.com) | 101 |
| Install command occurrences | ~35 (30 files) |
| dispatch_witness references | 147 files |
| Binary office files (.pdf/.docx/.pptx) | 0 |
| .forge.bak-* directories to delete | 61 confirmed |
| docs/plans/ files to delete | 96 confirmed (roadmap.md must be relocated first) |
| docs/superpowers/ files to delete | 8 confirmed |
| skills/version-bump/ | EXISTS — delete |
| REVIEW-REPORT-v3.1.0.md | EXISTS — delete |
| grep.exe.stackdump | EXISTS — delete |
| nul (root file) | NOT FOUND — no action |
| Current plugin version | 10.2.0 |
| NEW plugin name | agent-flow |
| NEW skill prefix | agent-flow: |
| NEW canonical repo | https://github.com/asysta-act/agent-flow |
| README.md | 283 lines, well-structured OSS format — rename, not full rewrite |

---

## Critical Findings (must inform Phase 7 planning)

1. **Rename scope is "ceos-agents" → "agent-flow" across ~224 files / ~3,900 occurrences.** No binary office files exist. Pure text search-and-replace is viable, but several patterns require distinct handling (see Section 1).

2. **"v9.0.0+, mandatory" and "v10.0.0+, mandatory" are in CLAUDE.md only — NOT in individual agents/*.md files.** The per-agent section headers (`## Output Contract`, `## Step Completion Invariants`) exist in agents/*.md as plain section names without the version label. Three agents (fixer.md L139, publisher.md L136, reviewer.md L153) have prose references to "v10.0.0 3-layer defense" — these are informational, not contract labels. No search-and-replace needed in agents/*.md for version strings.

3. **Plugin metadata files are in .claude-plugin/, not at root level.** `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` are the only canonical version/name sources. No root-level plugin.json or marketplace.json exist.

4. **roadmap.md MUST be relocated before deleting docs/plans/.** The roadmap records the v10.3.0/v1.0.0 public launch decisions and is the active strategic document. Phase 7 must do `git mv docs/plans/roadmap.md docs/roadmap.md` as a separate first commit before the bulk docs/plans/ deletion. All downstream refs (README.md L268, CHANGELOG entries) must be updated to `docs/roadmap.md`.

5. **README.md is already OSS-structured (283 lines).** It has mermaid pipeline diagrams, skills table, agents table, configuration section, and documentation index. The primary work is renaming "ceos-agents" occurrences and updating install commands/URLs — not a structural rewrite.

6. **.gitignore is critically incomplete (4 entries only).** Currently ignores only `.vs/`, `nul`, `.claude/settings.local.json`, `.env`. Missing: `.forge/`, `.forge.bak-*/`, `.forge.v*/`, `.ceos-agents/`, `*.stackdump`, `REVIEW-REPORT-*.md`, `docs/plans/`, `docs/superpowers/`. All 7 patterns must be added before the deletions.

7. **Internal URL has TWO distinct forms:** `gitea.internal.ceosdata.com` (bare domain, 101 files) and `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` (canonical full URL, 2 files: plugin.json and marketplace.json). The full URL must become `https://github.com/asysta-act/agent-flow`. Bare domain occurrences (mostly in test fixtures, examples, and docs) must all be updated.

8. **61 .forge.bak-* directories exist but are NOT in .gitignore.** They must be added to .gitignore AND deleted. Estimated savings: ~32 MB / 2415 files.

9. **skills/version-bump/ is confirmed present and must be deleted.** This reduces skills count from 18 → 17. The doc-count drift audit (CLAUDE.md, README.md, docs/reference/skills.md, docs/architecture.md) must be updated to reflect 17 skills.

10. **The ".ceos-agents/" runtime state path (52 files) must become ".agent-flow/"** — this affects the state directory referenced in CLAUDE.md, docs/reference/automation-config.md, state/schema.md, docs/guides/installation.md (.gitignore recommendations), and core/ contracts.

---

## Section 1: Rename Inventory

### 1.1 ceos-agents occurrence statistics

| Pattern | Files (main repo, excl. .forge) | Est. Occurrences | Primary Locations |
|---------|--------------------------------|-------------------|-------------------|
| `ceos-agents` (all, case-sensitive) | 224 | ~3,900+ | Docs, skills, agents, core, tests |
| `ceos-agents:` (skill prefix) | 127 | ~1,200+ | Skill step files, docs references, test scenarios |
| `[ceos-agents]` (block comment marker) | 299 | ~400+ | Webhook schemas, tests, guard-block.md files |
| `ceos-agents-block` (webhook event name) | 52 | ~80+ | core/block-handler.md, core/post-publish-hook.md, tests |
| `.ceos-agents/` (runtime state path) | 52 | ~60+ | Installation guide, state schema, CLAUDE.md |
| `ceos-agents@ceos-agents` (install cmd) | 30 | ~35+ | README.md, getting-started.md, installation.md, CLAUDE.md |
| `CEOS-AGENTS` (uppercase variant) | 4 (mainly .forge) | ~8 | Presentation slides, research notes (most in .forge — skip) |
| **Total unique files affected** | **~400+** | **~3,900+** | — |

**Rename targets:**
- `ceos-agents` → `agent-flow`
- `ceos-agents:` → `agent-flow:`
- `[ceos-agents]` → `[agent-flow]`
- `ceos-agents-block` → `agent-flow-block`
- `.ceos-agents/` → `.agent-flow/`
- `ceos-agents@ceos-agents` → `agent-flow@agent-flow`

### 1.2 dispatch_witness sha256 seeds

- **147 files contain "dispatch_witness"**
- Primary locations: `tests/scenarios/` (v10-dispatch-witness-audit.sh, v10-witness-large-triage-block.sh, v10-schema-witness-coverage.sh, v10-hidden-witness-format.sh, v10-strict-mode-exit.sh), `tests/fixtures/v10-witness/` (triage-5ac.json, state-a.json, state-b.json, state-c.json), `state/schema.md`, `core/lib/stage-invariant.sh`
- SHA256 seed payloads reference `"source": "ceos-agents:fix-bugs-skill"` etc. — these "ceos-agents:" strings inside witness JSON payloads must be renamed to `agent-flow:` to match the new namespace
- Estimated 45+ fixture/state files with hardcoded JSON sha256 witness seed strings

### 1.3 Install command occurrences

**Files: 30 files / ~35 exact occurrences**

Key files (must update install commands):
- `README.md` — Quick Start section: `claude plugin install ceos-agents@ceos-agents`
- `docs/getting-started.md` — Step 1: `claude plugin install ceos-agents@ceos-agents`
- `docs/guides/installation.md` — Section 2: `claude plugin install ceos-agents@ceos-agents`
- `CLAUDE.md` — line ~10: `claude plugin install ceos-agents@ceos-agents`

New install command after rename: `claude plugin install agent-flow@agent-flow`

Related patterns also requiring update (~10 more files):
- `claude plugin marketplace add <path-to-repo>` — no rename needed (generic)
- Marketplace add with old host reference — update host
- Test scenario mocks: `tests/scenarios/v6.9.0-installation-md-no-internal-host.sh` and related

### 1.4 Internal URL (gitea.internal.ceosdata.com)

**Files: 101 files / ~150+ occurrences**

Two distinct URL forms:
1. **Canonical full URL** (2 critical files):
   - `.claude-plugin/plugin.json` line 8: `"repository": "https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git"`
   - `.claude-plugin/marketplace.json` line 10: source reference
   - New value: `"https://github.com/asysta-act/agent-flow"`

2. **Bare domain** (101 files including the 2 above):
   - Appears in: docs/guides/installation.md (4 examples), examples/ (config templates), tests/ (mock URL refs), docs/guides/cross-platform.md
   - New value: `github.com/asysta-act/agent-flow` (context-dependent)

Also present but do NOT rename:
- `gitea.com/gitea/gitea-mcp` — external Gitea MCP repo (5 files) — keep as-is
- `<your-git-host>` placeholder templates (6 files) — keep as-is

### 1.5 Binary files

**0 binary office files (.pdf, .pptx, .docx, .xlsx) exist in the repository.**

One HTML file exists: `docs/superpowers/specs/2026-04-27-ceo-presentation.html` — in the `docs/superpowers/` deletion path, no rename needed.

---

## Section 2: Version References & Deletions

### 2.1 "v9.0.0+, mandatory" and "v10.0.0+, mandatory" — ACTUAL LOCATION

**These strings appear ONLY in CLAUDE.md (lines 101–106). They do NOT appear in individual agents/*.md files.**

CLAUDE.md line 101: `## Output Contract (v9.0.0+, mandatory — structured output schema agents return)`
CLAUDE.md line 102: `## Step Completion Invariants (v10.0.0+, mandatory — fields the orchestrator MUST verify...)`
CLAUDE.md line 106: `> **v10.0.0 reliability contract:** \`## Step Completion Invariants\` is a mandatory structured section...`

In `agents/*.md` files, the section headers appear as **plain section names only**, e.g.:
- `## Output Contract` (no version label)
- `## Step Completion Invariants` (no version label)

**Phase 7 implication:** No search-and-replace of version labels is needed in agents/*.md. The CLAUDE.md schema template text can be preserved as-is (it's historical context), or updated to drop the version labels if the new README/docs adopt a simpler format. Decision deferred to Phase 7.

### 2.2 Other internal version references

| Location | Content | Action |
|----------|---------|--------|
| `CHANGELOG.md` | 83 occurrences of "ceos-agents"; full v6.x–v10.2.0 history | Replace "ceos-agents" → "agent-flow" throughout; the internal versioning history is preserved but the name changes |
| `docs/plans/roadmap.md` | L5: "Current version: v9.6.1" (stale); L1519–L1529: v10.3.0/v1.0.0 decisions | Relocate to `docs/roadmap.md`; for public version rewrite to community-facing future plan only |
| `docs/guides/migration-v7-to-v8.md` | Internal v7→v8 migration guide | Stays in repo (consumer-facing migration docs); update "ceos-agents" → "agent-flow" occurrences |
| `docs/guides/migration-v8-to-v9.md` | Internal v8→v9 migration guide | Same as above |
| `docs/reference/mcp-server-versions.md` | Pinned MCP server versions (gitea-mcp v1.1.0, protocol 2025-06-18); Atlassian SSE EOL 2026-06-30 | No version rename needed; URL update if gitea-mcp refs change |
| Three agents (fixer.md L139, publisher.md L136, reviewer.md L153) | "v10.0.0 3-layer defense" prose reference | Keep as-is — informational, not a contract label |

### 2.3 Deletion inventory (confirmed exists/not exists)

| Item | Exists? | Size/Count | Action |
|------|---------|------------|--------|
| `.forge.bak-*/` directories | YES — 61 directories | ~32 MB / 2415 files | DELETE (after adding to .gitignore) |
| `docs/plans/` directory | YES — 96 files | ~2.9 MB | Step 1: `git mv docs/plans/roadmap.md docs/roadmap.md`; Step 2: DELETE remaining 95 files |
| `docs/superpowers/specs/` | YES — 8 files | ~340 KB | DELETE |
| `skills/version-bump/` | YES | — | DELETE; update doc counts: 18 → 17 skills |
| `REVIEW-REPORT-v3.1.0.md` | YES — root level | — | DELETE |
| `grep.exe.stackdump` | YES — root level | — | DELETE |
| `nul` | NOT FOUND | — | No action |
| CEO-deck.md / CEO-deck-marp.md | NOT FOUND | — | No action |
| `.forge/` (current run dir) | YES | ~755 KB | ADD to .gitignore; delete per release policy |

**KEEP confirmed (runtime-referenced):**
- `tests/` — 10+ refs from core/, docs/, core/snippets/
- `checklists/` — 2 refs from agents/test-engineer.md, agents/reviewer.md
- `state/` — 7 refs from 3 core contracts + 4 skills/snippets
- `examples/` — 28 files, consumer-facing config templates
- `hooks/` — Claude Code event hooks

### 2.4 Current .gitignore state

**Current contents (4 entries):**
```
.vs/
nul
.claude/settings.local.json
.env
```

**7 patterns to add (in Phase 7):**
```
.forge/
.forge.bak-*/
.forge.v*/
.ceos-agents/
*.stackdump
REVIEW-REPORT-*.md
docs/plans/
docs/superpowers/
```

**Note on `.claude/`:** Currently only `settings.local.json` is ignored. Consider broadening to `.claude/` (entire directory) or keeping the specific file pattern — decision for Phase 7.

---

## Section 3: Key File States

### 3.1 plugin.json (.claude-plugin/plugin.json)

**Current state (all 10 lines):**
```json
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
```

**Required changes for v1.0.0 public launch:**
- `name`: `"ceos-agents"` → `"agent-flow"`
- `description`: Replace "CEOS CLAUDE Agents — development automation: bug-fix, feature pipeline, scaffold, decomposition, dashboard" with OSS-facing description
- `version`: `"10.2.0"` → `"1.0.0"`
- `repository`: `"https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git"` → `"https://github.com/asysta-act/agent-flow"`

### 3.2 marketplace.json (.claude-plugin/marketplace.json)

**Current state:**
```json
{
  "name": "ceos-agents",
  "owner": { "name": "Filip Sabacky" },
  "plugins": [{
    "name": "ceos-agents",
    "source": "./",
    "description": "CEOS CLAUDE Agents — development automation: bug-fix, feature pipeline, scaffold, decomposition, dashboard",
    "version": "10.2.0",
    "license": "MIT"
  }]
}
```

**Required changes:**
- `name` (root): `"ceos-agents"` → `"agent-flow"`
- `plugins[0].name`: `"ceos-agents"` → `"agent-flow"`
- `plugins[0].description`: same OSS-facing update
- `plugins[0].version`: `"10.2.0"` → `"1.0.0"`

### 3.3 README.md

**Current state:** 283 lines, well-structured OSS format. Contains:
- Title: `# ceos-agents`
- Mermaid architecture diagram (plugin/project/external services)
- "What It Does" section (6 bullets)
- Quick Start (5-step bash block with `claude plugin install ceos-agents@ceos-agents`)
- Three mermaid pipeline diagrams (bug-fix, feature, scaffold)
- Skills table (18 skills with `/ceos-agents:` prefix commands)
- Agents table (17 agents)
- Configuration section (required + optional)
- Documentation index table
- Roadmap link → `docs/plans/roadmap.md` (must update to `docs/roadmap.md`)
- Contributing and Author/License sections

**Work required:** Rename "ceos-agents" occurrences, update install commands, update roadmap link — NOT a structural rewrite. The existing structure is already production-quality for OSS.

### 3.4 CHANGELOG.md

**Current state:** Full internal history from v3.x through v10.2.0.

- First line: `# Changelog`
- Line 3: `All notable changes to the ceos-agents plugin.`
- Line 10: "Repo split note (2026-04-28)" — internal history note referencing `ceos-agents-web`
- 83 "ceos-agents" occurrences throughout
- Decision per roadmap.md L1524: "CHANGELOG začíná čistě od v1.0.0" — the public CHANGELOG should start fresh at v1.0.0 with only a single entry describing the initial public release. The full v6–v10 internal history is archived in Gitea.

**Work required:** Replace internal-versioning CHANGELOG with a clean v1.0.0 entry. The old content should be preserved in Gitea only.

### 3.5 SECURITY.md

**Current state (16 lines):**
- Heading: `# Security Policy`
- `## Reporting a Vulnerability` section
- Email contact: `filip.sabacky@ceosdata.com` — **matches Cross-File Invariant #2**
- Response SLA: 5 business days
- `## Supported Versions` section: latest version only

**Roadmap decision (L1632):** GitHub Security Advisories to be added as secondary channel. Primary contact (`filip.sabacky@ceosdata.com`) stays. A supported versions matrix may be added.

**Work required:** Rename "ceos-agents" in text; optionally add GitHub Security Advisories channel; add supported versions matrix if desired.

### 3.6 CLAUDE.md structure summary

CLAUDE.md is 2,000+ characters describing the full plugin architecture. Key rename points:
- Line ~6: `A Claude Code plugin (\`ceos-agents\`)` → `agent-flow`
- Line ~9: `Installation: \`claude plugin install ceos-agents@ceos-agents\`` → new install command
- Line ~101–106: "v9.0.0+, mandatory" and "v10.0.0+, mandatory" labels — in CLAUDE.md only (not in agents/*.md)
- Multiple `ceos-agents:` skill prefix references throughout
- `## Automation Config` section references `.ceos-agents/` runtime path → `.agent-flow/`
- Line ~30+: Plugin composability section explicitly names `ceos-agents:` namespace

**CLAUDE.md is a consumer-facing file** (ships in the repo, read by users setting up the plugin). It needs full "ceos-agents" → "agent-flow" rename treatment but its structural content is correct and comprehensive.

### 3.7 docs/plans/roadmap.md — content for extraction

Roadmap.md (2192 lines) contains:
- **Public launch decision record** (L1519–1529): plugin rename `ceos-agents` → `agent-flow`, canonical repo `https://github.com/asysta-act/agent-flow`, version reset to v1.0.0, clean CHANGELOG, orphan commit for GitHub, community-facing roadmap rewrite
- **v10.3.0 cleanup scope** (L1539–1621): exact list of MUST REMOVE / KEEP items, .gitignore patterns, estimated savings (~35 MB / 2530+ files)
- **v10.4.0 public release polish** (L1623–1668): pre-release decisions (ALL resolved 2026-05-13), announcement checklist, messaging constraints
- **Historical v4.1.0–v10.2.0 done work** (L24–1488): reference material

**Extraction action (Phase 7):**
1. `git mv docs/plans/roadmap.md docs/roadmap.md` (first commit, separate)
2. Rewrite `docs/roadmap.md` for community audience: future plans only, no internal Czech notes, no renumbering history
3. Update all refs: `README.md` L268, any CHANGELOG entries pointing to `docs/plans/roadmap.md` → `docs/roadmap.md`

---

## Section 4: Cross-File Invariants

### Invariant #1 — License SPDX consistency

All three sources must contain `"MIT"` (exact string, case-sensitive):
- `.claude-plugin/plugin.json` → `"license": "MIT"` ✓ (confirmed from file)
- `.claude-plugin/marketplace.json` → `"license": "MIT"` ✓ (confirmed from file)
- `LICENSE` first heading → must contain `"MIT"` (not directly verified in this research; assumed correct given current passing state)

**Phase 7 action:** Verify `LICENSE` file heading after rename — no changes expected.

### Invariant #2 — Maintainer email consistency

All three community health files must reference `filip.sabacky@ceosdata.com`:
- `SECURITY.md` → `filip.sabacky@ceosdata.com` ✓ (confirmed from file read)
- `CODE_OF_CONDUCT.md` → not directly verified in this research session
- `CONTRIBUTING.md` → not directly verified in this research session

**Phase 7 action:** Verify CODE_OF_CONDUCT.md and CONTRIBUTING.md contain the canonical email. If any file references an older email variant, update. This invariant is unaffected by the ceos-agents → agent-flow rename.

### Invariant #3 — Issue/PR template parity

Corresponding files under `.gitea/` and `.github/` must be byte-identical pairs:
- `.gitea/issue_template/` ↔ `.github/ISSUE_TEMPLATE/` — not directly verified in this research
- `.gitea/pull_request_template.md` ↔ `.github/PULL_REQUEST_TEMPLATE.md` — not directly verified

**Phase 7 action:** After renaming "ceos-agents" occurrences in any template files, verify parity is maintained (re-apply identical edits to both `.gitea/` and `.github/` counterparts). Run `diff -q` as the verification step.

---

## Phase 7 Execution Checklist

Ordered sequence for atomic, reviewable execution:

### Step 0 — Prerequisites and safety
- [ ] Confirm working branch is clean (`git status`)
- [ ] Add all 8 .gitignore patterns (`.forge/`, `.forge.bak-*/`, `.forge.v*/`, `.ceos-agents/`, `*.stackdump`, `REVIEW-REPORT-*.md`, `docs/plans/`, `docs/superpowers/`) — commit as "chore: expand .gitignore for OSS cleanup"

### Step 1 — Relocate roadmap.md (MUST be first, before docs/plans/ deletion)
- [ ] `git mv docs/plans/roadmap.md docs/roadmap.md` — commit as "docs: relocate roadmap.md from docs/plans/ to docs/"
- [ ] Update `README.md` L268 reference from `docs/plans/roadmap.md` → `docs/roadmap.md`
- [ ] Update any CHANGELOG.md roadmap refs → `docs/roadmap.md`
- [ ] Rewrite `docs/roadmap.md` for community audience (future-only, English, no internal notes)

### Step 2 — Bulk deletions (~35 MB, 2530+ files)
- [ ] Delete 61 `.forge.bak-*/` directories
- [ ] Delete `docs/plans/` (95 remaining files after Step 1)
- [ ] Delete `docs/superpowers/specs/` (8 files)
- [ ] Delete `skills/version-bump/` directory
- [ ] Delete `REVIEW-REPORT-v3.1.0.md`
- [ ] Delete `grep.exe.stackdump`
- [ ] Commit as "chore: remove internal artifacts, planning docs, version-bump skill (pre-OSS-launch cleanup)"

### Step 3 — Plugin metadata rename + version reset
- [ ] `.claude-plugin/plugin.json`: rename `name`, update `description`, set `version` = `"1.0.0"`, update `repository` URL
- [ ] `.claude-plugin/marketplace.json`: rename `name` (root + plugins[0]), update `description`, set `version` = `"1.0.0"`
- [ ] Commit as "chore: rename plugin ceos-agents → agent-flow, reset version to 1.0.0"

### Step 4 — Mass text rename (224 files / ~3,900+ occurrences)
Execute in sub-batches for reviewability:

**4a — Skill prefix rename (127 files):**
- [ ] Replace `ceos-agents:` → `agent-flow:` across all skill step files, SKILL.md files, documentation, test scenarios

**4b — Install command and URL rename (30+101 files):**
- [ ] Replace `ceos-agents@ceos-agents` → `agent-flow@agent-flow`
- [ ] Replace `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` → `https://github.com/asysta-act/agent-flow`
- [ ] Replace remaining `gitea.internal.ceosdata.com` bare domain occurrences → `github.com/asysta-act/agent-flow` (context-dependent)

**4c — Runtime state path rename (52 files):**
- [ ] Replace `.ceos-agents/` → `.agent-flow/` in CLAUDE.md, docs/reference/automation-config.md, state/schema.md, docs/guides/installation.md, core/ contracts

**4d — Remaining "ceos-agents" rename (remaining of 224 files):**
- [ ] Replace `ceos-agents` → `agent-flow` (all remaining occurrences not covered by 4a–4c)
- [ ] Replace `[ceos-agents]` → `[agent-flow]` (block comment markers, 299 files)
- [ ] Replace `ceos-agents-block` → `agent-flow-block` (webhook event name, 52 files)
- [ ] Replace dispatch_witness JSON seed strings: `"ceos-agents:` → `"agent-flow:` (45+ fixture files)

**4e — CLAUDE.md update:**
- [ ] Update plugin name, install command, namespace references
- [ ] Update `.ceos-agents/` → `.agent-flow/` runtime state path
- [ ] Update doc-count: 18 skills → 17 skills (skills list, architecture section)

### Step 5 — doc-count drift audit
- [ ] Update CLAUDE.md skills count: 18 → 17
- [ ] Update README.md skills table: remove `/version-bump` row (18 → 17 rows)
- [ ] Update `docs/reference/skills.md`: remove version-bump entry
- [ ] Update `docs/architecture.md`: 18 → 17 skills count
- [ ] Verify all four files are consistent

### Step 6 — CHANGELOG.md replacement
- [ ] Replace full CHANGELOG with clean v1.0.0 entry (internal v6–v10 history archived in Gitea only)

### Step 7 — Cross-file invariant verification
- [ ] Verify `LICENSE` heading contains `"MIT"` — Invariant #1
- [ ] Verify `CODE_OF_CONDUCT.md` and `CONTRIBUTING.md` both reference `filip.sabacky@ceosdata.com` — Invariant #2
- [ ] Run `diff -q` on .gitea/ vs .github/ template pairs — Invariant #3
- [ ] Apply identical "agent-flow" renames to both .gitea/ and .github/ template counterparts if any templates contained "ceos-agents"

### Step 8 — Final validation
- [ ] `grep -rn "ceos-agents" --include="*.md" --include="*.json" --include="*.sh"` — must return 0 hits (excluding .forge/ and .forge.bak-*/)
- [ ] `grep -rn "gitea.internal.ceosdata.com"` — must return 0 hits
- [ ] `grep -rn "ceos-agents@ceos-agents"` — must return 0 hits
- [ ] Verify `.claude-plugin/plugin.json` has `"version": "1.0.0"` and `"name": "agent-flow"`
- [ ] Verify `docs/roadmap.md` exists; `docs/plans/roadmap.md` does NOT exist
- [ ] Verify `skills/version-bump/` does NOT exist
- [ ] Confirm `.gitignore` has all 8 new patterns

### Step 9 — Git history reset for GitHub (orphan commit)
- [ ] `git checkout --orphan public-launch`
- [ ] `git add` all remaining files (post-cleanup state)
- [ ] Single initial commit: "feat: initial public release as agent-flow v1.0.0"
- [ ] Push to `https://github.com/asysta-act/agent-flow`
- [ ] Gitea repo (`gitea.internal.ceosdata.com/fsabacky/ceos-agents`) preserved as archive with full history

---

*Phase 2 synthesis complete. All critical rename targets, deletion inventory, version reference locations, key file states, and cross-file invariants are documented. Phase 3 (Brainstorming) and Phase 7 (Execution) can proceed from this document as the single source of truth.*
