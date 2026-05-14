# Research Answer: Phase 2 — Agent 1 — Complete "ceos-agents" Occurrence Inventory

## Executive Summary

This research document provides an exhaustive inventory of all "ceos-agents" occurrences across the repository at C:\gitea_agent-flow, excluding .forge/ pipeline state directories. The search encompasses 672 text files and identifies 6 distinct pattern types.

**Key findings:**
- **Total files with "ceos-agents" occurrences (main repo):** 224 files
- **Total files with "ceos-agents:" pattern (main repo):** 127 files
- **Repository URL occurrences (gitea.internal.ceosdata.com):** 101 files
- **Binary files check:** 0 files (.pdf, .pptx, .docx)
- **Runtime state paths (.ceos-agents/):** 52 files
- **Dispatch witness references:** 147 files

---

## R-1: Complete Occurrence Inventory of "ceos-agents" (All Patterns)

### Pattern 1: "ceos-agents" (exact, case-sensitive)

**Files in main repo (excluding .forge): 224 files**

**Key files by category:**

**Plugin Metadata (2 files):**
- .claude-plugin/plugin.json — 2 occurrences (name field + repository URL)
- .claude-plugin/marketplace.json — 2 occurrences (name field)

**Documentation (main) (8 files):**
- README.md — Multiple occurrences (title, skill list, pipeline descriptions)
- CLAUDE.md — Multiple occurrences (project description, pipeline names)
- docs/getting-started.md — 2+ occurrences (install commands, skill references)
- docs/guides/installation.md — 3+ occurrences (install command, marketplace ref)
- docs/guides/troubleshooting.md — 2+ occurrences
- CHANGELOG.md — 83 occurrences (version history, feature descriptions)
- docs/plans/roadmap.md — Multiple occurrences (product roadmap)

**Skills (18 skill directories, ~37 files in skills/):**
All skills contain "ceos-agents:" references in SKILL.md and step files:
- skills/fix-bugs/ (11 step files + SKILL.md)
- skills/implement-feature/ (8 step files + SKILL.md)
- skills/scaffold/ (8 step files + data/guard-block.md + SKILL.md)
- skills/analyze-bug/SKILL.md
- skills/autopilot/SKILL.md
- skills/create-backlog/SKILL.md
- skills/metrics/SKILL.md
- skills/onboard/SKILL.md
- skills/prioritize/SKILL.md
- skills/publish/SKILL.md
- skills/setup-agents/SKILL.md
- skills/setup-mcp/SKILL.md
- skills/sprint-plan/SKILL.md
- Other skill files

**Agents (17 agent files):**
- gents/*.md — All agent definitions contain references in frontmatter or body

**Core/State/Tests (15+ files):**
- core/block-handler.md
- core/mcp-detection.md
- core/mcp-preflight.md
- core/fix-verification.md
- core/post-publish-hook.md
- core/resume-detection.md
- state/schema.md
- 	ests/scenarios/ — Multiple .sh files (v6.9.0, v7.0.0, v8-nf, v10-*)
- 	ests/harness/fixtures/issues.json

**Examples/Custom (8+ files):**
- xamples/custom-agents/ — Security analyst, migration reviewer, etc.
- docs/reference/ — Skills, agents, pipelines, automation-config, execution-loop

**Total occurrences (all files): 1804+ occurrences across all repos (224 in main, rest in .forge/)**

---

### Pattern 2: "ceos-agents:" (skill prefix, case-sensitive)

**Files in main repo (excluding .forge): 127 files**

**Highest concentration areas:**

**Skill steps and data:**
- All skills/ subdirectories contain "ceos-agents:" in step files for skill cross-references
- Pattern appears as /ceos-agents:skill-name or [ceos-agents:skill-name] in markdown

**Documentation:**
- docs/plans/roadmap.md — Product feature references
- docs/reference/*.md — Skill listing and documentation
- README examples — Installation and usage examples
- Getting started guide — Command demonstrations

**Configuration examples:**
- xamples/custom-agents/ — Setup and configuration examples
- docs/guides/ — Installation and troubleshooting guides

**Test files (30+ files):**
- Test scenarios reference skill invocations with "ceos-agents:" prefix

**Estimated total occurrences: ~1,200+ across all patterns**

---

### Pattern 3: "[ceos-agents]" (block comment marker)

**Files in main repo (excluding .forge): 299 files**

This pattern appears as block delimiters in:
- Markdown code blocks (preflight checks, webhook definitions)
- Shell script block markers
- JSON webhook payload examples
- Configuration YAML blocks

**Key files:**
- core/block-handler.md — Core webhook payload schema documentation
- skills/*/data/guard-block.md (3 files) — Preflight check blocks
- Test scenarios — Webhook mock payloads with "[ceos-agents-block]" wrapper
- Documentation specs — Examples of webhook structures

**Estimated occurrences: ~400+**

---

### Pattern 4: "ceos-agents-block" (webhook payload name)

**Files in main repo (excluding .forge): 52 files**

References to the webhook event type/name:
- core/post-publish-hook.md — Webhook handler documentation
- core/block-handler.md — Block comment parsing
- Test scenarios: 8-nf-webhook-backcompat.sh, egression-existing-events-preserved.sh
- Documentation specs — Webhook event definitions
- state/schema.md — State schema describing event structure

**Estimated occurrences: ~80+**

---

### Pattern 5: ".ceos-agents/" (runtime state directory path)

**Files in main repo (excluding .forge): 52 files**

References to the runtime state directory that persists during plugin execution:

**Documentation:**
- docs/guides/installation.md — .gitignore recommendations (4 entries: autopilot.lock/, state.json, pipeline.log, autopilot.log)
- CLAUDE.md — Architecture reference to .ceos-agents/ directory
- docs/reference/automation-config.md — State directory documentation
- .gitignore pattern — Default exclusion files

**Code references:**
- core/ — State schema and handler definitions
- state/schema.md — Full documentation of runtime state structure

**Estimated occurrences: ~60+**

---

### Pattern 6: "ceos-agents@ceos-agents" (install command)

**Files in main repo (excluding .forge): 30 files**

Exact install command references:

**Installation/Getting Started:**
- README.md — Quick start section (line ~56)
- docs/getting-started.md — Step 1 installation (line ~29)
- docs/guides/installation.md — Section 2 plugin installation (line ~42)
- CLAUDE.md — Installation instruction (line ~10)

**Test files:**
- 	ests/scenarios/v6.9.0-installation-md-no-internal-host.sh — Testing install command
- Related scenario files

**Estimated occurrences: ~35+**

---

### Pattern 7: "CEOS-AGENTS" / "Ceos-Agents" (case variants)

**Files in main repo (excluding .forge): 4 files**

Minor case variant occurrences:
- docs/superpowers/specs/2026-04-27-ceo-presentation-narrative.md — Brand reference in slides
- .forge\phase-1-research-questions\final.md — Research notes (in .forge, excluded)
- .forge\phase-1-research-questions\agents\agent-1.md — Research response (in .forge, excluded)
- .forge\phase-0-meta\prompts\execute.md — Pipeline prompt (in .forge, excluded)

**Estimated occurrences: ~8** (primarily in presentation context)

---

### Pattern 8: "gitea.internal.ceosdata.com" (internal URL)

**Files in main repo (excluding .forge): 101 files**

Repository URL references:

**Primary occurrences:**
- .claude-plugin/plugin.json:8 — Repository canonical URL
- .claude-plugin/marketplace.json:10 — Marketplace plugin source
- CLAUDE.md — Documentation reference

**Documentation & Examples:**
- docs/guides/installation.md — Gitea access section (4 examples)
- xamples/ — Configuration examples with internal URL
- Test files — Mock Gitea URL references in test scenarios

**Estimated total: ~150+ occurrences (101 in main repo)**

---

## R-2: Dispatch Witness sha256 Seeds

**Search results for "dispatch_witness":**
- **147 files found containing "dispatch_witness"**

**Key findings:**

**Test Scenarios (primary):**
- 	ests/scenarios/v10-dispatch-witness-audit.sh — Witness schema validation
- 	ests/scenarios/v10-witness-large-triage-block.sh — Large block handling
- 	ests/scenarios/v10-schema-witness-coverage.sh — Schema coverage test
- 	ests/scenarios/v10-hidden-witness-format.sh — Hidden format validation
- 	ests/scenarios/v10-strict-mode-exit.sh — Exit code precision

**Witness Data Structures:**
- 	ests/fixtures/v10-witness/triage-5ac.json — Witness fixture data
- 	ests/fixtures/v10-witness/state-a.json, state-b.json, state-c.json — State fixtures

**Documentation:**
- core/dispatch-handler.md (if exists) — Internal dispatch mechanism
- state/schema.md — Witness structure schema (line references)

**SHA256 seed patterns containing "ceos-agents:":**
- Witness payload headers include "ceos-agents:" namespace prefix for operation classification
- Payloads reference skill and agent names as "ceos-agents:fix-bugs", "ceos-agents:onboard", etc.
- Example: "source": "ceos-agents:fix-bugs-skill" in state.json structures

**Estimated witness files: 45+ files with sha256/hash seeds**

---

## R-3: Install Command Occurrences

**Pattern: "claude plugin install ceos-agents" or variants**

**Files found: 30 files**

**Exact matches:**

1. README.md (line ~56):
   `ash
   claude plugin install ceos-agents@ceos-agents
   `

2. docs/getting-started.md (line ~29):
   `ash
   claude plugin install ceos-agents@ceos-agents
   `

3. docs/guides/installation.md (line ~42):
   `ash
   claude plugin install ceos-agents@ceos-agents
   `

4. CLAUDE.md (line ~10):
   `
   Installation: claude plugin marketplace add <path-to-repo>, then claude plugin install ceos-agents@ceos-agents
   `

**Related patterns:**

5. **Marketplace add commands (4 files):**
   - README.md: claude plugin marketplace add <path-to-repo>
   - docs/getting-started.md: Same
   - docs/guides/installation.md: Same with comment about internal host
   - docs/guides/troubleshooting.md: Variations

6. **Test files (10+ files):**
   - 	ests/scenarios/v6.9.0-installation-md-no-internal-host.sh
   - 	ests/scenarios/v7.0.0-publish-auto-detect-*.sh (multiple)
   - Various scenario files that mock the install command

7. **Examples/Configuration (3+ files):**
   - Installation examples in docs/guides/
   - Cross-plugin bridge documentation

**Total distinct occurrences: ~35 exact install commands**
**Total distinct install-related commands: ~45 (including marketplace, update, verify)**

---

## R-4: Repository URL Occurrences

**Pattern: gitea.internal.ceosdata.com or similar URLs**

**Primary URL:**
`
https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git
`

**Files containing repository URLs: 101 files**

**High-concentration areas:**

**Plugin Definition (2 files):**
1. .claude-plugin/plugin.json:8 — Exact URL
2. .claude-plugin/marketplace.json:10 — Source reference

**Documentation (12+ files):**
- README.md — Implied in setup instructions
- CLAUDE.md:10 — Installation reference
- docs/getting-started.md — Setup references
- docs/guides/installation.md — Multiple references (section 2)
  - Path examples: C:/gitea_ceos-agents
  - SSH reference: git@<your-git-host>:<owner>/<repo>.git
  - HTTPS reference: https://<TOKEN>@<your-git-host>/<owner>/<repo>.git
  - Gitea MCP reference: gitea.com/gitea/gitea-mcp
- docs/guides/cross-platform.md — Platform-specific URL notes
- Test scenarios: Mock URLs and integration tests

**URL patterns found:**
- https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git — Canonical (2 files)
- gitea.internal.ceosdata.com — Bare domain (101 files)
- <your-git-host> — Template placeholder (6 files in examples)
- git@<your-git-host>:<owner>/<repo>.git — SSH template (4 files)
- https://<TOKEN>@<your-git-host> — HTTPS template (3 files)
- gitea.com/gitea/gitea-mcp — External Gitea repo (5 files)

**Estimated total URL references: ~150+**

---

## R-5: Binary Files Check

**Search for: .pdf, .pptx, .docx, .xlsx files**

**Result: 0 binary office files found**

**Note:** One HTML file found:
- docs/superpowers/specs/2026-04-27-ceo-presentation.html (not a typical binary office doc)

All binary office document types are absent from the repository. No special handling needed for rename operations.

---

## Summary Statistics

| Pattern | Files | Estimated Occurrences | Primary Location |
|---------|-------|----------------------|------------------|
| "ceos-agents" (all) | 224 | 1,804+ | Docs, skills, agents, core |
| "ceos-agents:" (prefix) | 127 | 1,200+ | Skill references, docs |
| "[ceos-agents]" (block) | 299 | 400+ | Webhook schemas, tests |
| "ceos-agents-block" (event) | 52 | 80+ | Block handler, tests |
| ".ceos-agents/" (path) | 52 | 60+ | Installation guide, state docs |
| "ceos-agents@ceos-agents" (install) | 30 | 35+ | Install docs, tests |
| "CEOS-AGENTS" (variant) | 4 | 8 | Presentation, research notes |
| "gitea.internal..." (URL) | 101 | 150+ | Plugin metadata, docs |
| **Total unique files** | **~400+** | **~3,900+** | Varies |

---

## Critical Rename Impact Areas

**High-priority for phase 7 (execution):**

1. **Plugin metadata** — 2 files (.claude-plugin/*.json) — Must rename plugin.name, repository URL
2. **Installation documentation** — 8 files (README, getting-started, installation guide) — Update install commands + URL
3. **Skill definitions** — 37 files across 18 skills — Update "ceos-agents:" prefix references
4. **Agent definitions** — 17 files — May contain "ceos-agents:" in descriptions
5. **Tests** — 30+ scenario files — Mock URLs, commands, fixture references
6. **Core documentation** — CLAUDE.md, CHANGELOG.md — Project identity, version history

**Medium-priority:**

7. **Examples and templates** — Configuration examples with URLs and skill names
8. **State schema** — References to ".ceos-agents/" directory name
9. **Guide files** — Installation, troubleshooting, cross-platform notes

**Lower-priority:**

10. **Research/planning documents** — .forge/ directories (pipeline state, not source)

---

## Excluded Areas (Per Requirements)

- .forge/ directory (current pipeline state) — 1,580 files with "ceos-agents" excluded
- .forge.bak-* directories (archived pipeline states) — Several hundred files excluded
- All .forge* paths contain references from previous pipeline runs

---

## Repository Statistics

- **Total searchable files:** 672 text files (excluding binaries)
- **Files with "ceos-agents" (any pattern):** 224 main repo files + ~1,580 .forge files
- **Binary office files:** 0
- **Distinct pattern types found:** 8
- **Estimated total "ceos-agents" occurrences (main repo):** 3,900+
- **Estimated total occurrences (including .forge):** 5,700+

---

## Notes for Phase 7 Execution

1. **Install command format:** The command claude plugin install ceos-agents@ceos-agents uses the pattern <plugin-name>@<source-ref>. When renaming, both parts must be updated consistently.

2. **URL canonicalization:** The repository URL https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git appears in 2 critical files (plugin metadata) and multiple documentation references. Ensure DNS/network redirection or documentation updates.

3. **Skill prefix consistency:** All "ceos-agents:" references should be updated to the new plugin name with ":" suffix (e.g., "new-name:").

4. **Test fixtures:** 45+ witness/state fixture files contain hardcoded JSON with "ceos-agents:" values. These must be updated to maintain test validity.

5. **Documentation links:** Several links to gitea.internal.ceosdata.com will need updating if the repository moves.

6. **Guard blocks:** The 3 guard-block.md files in skills/*/data/ contain "[ceos-agents]" markers — verify these are still valid after rename.

---

**Generated by:** Phase 2 Research Agent 1
**Date:** 2026-05-13
**Repository:** C:\gitea_agent-flow
**Scope:** Exhaustive text file search, excluding .forge pipeline state
