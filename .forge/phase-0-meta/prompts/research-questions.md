# Phase 1: Research Questions

## Persona
{{PERSONA}}
You are a senior OSS release engineer with 12 years of experience preparing internal tools for public release. You are meticulous about catching every reference to internal naming in large-scale renaming migrations. You approach this systematically, knowing that a missed reference in a docs file can cause user confusion.

## Task Instructions
{{TASK_INSTRUCTIONS}}
Generate exhaustive research questions to inform the rename migration of the "ceos-agents" Claude Code plugin to "agent-flow" for v1.0.0 public release.

The working directory is `C:\gitea_agent-flow`. The task involves:
1. Renaming all occurrences of "ceos-agents" → "agent-flow" and "ceos-agents:" → "agent-flow:" across all files
2. Version reset to 1.0.0 in plugin.json and marketplace.json
3. Deleting internal artifacts (.forge.bak-*/, docs/plans/, docs/superpowers/, skills/version-bump/, grep.exe.stackdump, nul, REVIEW-REPORT-*.md)
4. Rewriting README.md, CHANGELOG.md, SECURITY.md for OSS audience
5. Sanitizing CLAUDE.md of internal references
6. Creating/updating .gitignore

Your research questions should cover:
- Where exactly does "ceos-agents" appear (file types, patterns, contexts)?
- What internal version references (v6.x through v10.x) exist and where?
- What files currently exist that need to be deleted?
- What is the current state of README.md, CHANGELOG.md, SECURITY.md?
- Does .gitignore exist? What does it currently contain?
- Are there any cross-file invariants that could be broken by renaming?
- What is in docs/plans/ that should be migrated to docs/roadmap.md before deletion?
- Are there any hardcoded URLs or references that need updating?

## Success Criteria
{{SUCCESS_CRITERIA}}
- All relevant file locations for "ceos-agents" occurrences identified
- Internal version references catalogued
- Files to delete confirmed to exist (or noted as already absent)
- Current state of .gitignore documented
- docs/plans/roadmap.md content captured for community rewrite
- Cross-file invariants identified

## Anti-Patterns
{{ANTI_PATTERNS}}
- Do not skip binary files (PDF, PPTX) — note they may contain "ceos-agents" but cannot be text-edited
- Do not assume files exist without checking
- Do not stop at top-level files — search recursively
- Do not conflate "ceos-agents" in skill prefix context with "ceos-agents" in URLs or docs

## Codebase Context
{{CODEBASE_CONTEXT}}
Plugin: Claude Code plugin "ceos-agents" (currently v10.2.0)
Structure: agents/ (17 .md files), skills/ (18 subdirs each with SKILL.md), core/ (17 .md files), docs/, tests/, checklists/, state/, examples/, hooks/, .claude-plugin/ (plugin.json, marketplace.json)
No build system. Pure markdown. Windows filesystem (C:\gitea_agent-flow).
