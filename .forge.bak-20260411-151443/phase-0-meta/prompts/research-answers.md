# Phase 2 — Research Answers

> **Fast-track note:** This phase is skipped. Research questions were pre-answered in Phase 1 from existing codebase artifacts.

## Consolidated Findings

### Template Format Standard
All 7 existing templates follow identical structure:
1. `# {Stack} + {Tracker} — Automation Config Template` (H1)
2. `> Copy the section below into your project's CLAUDE.md` (blockquote)
3. `## Automation Config` (H2)
4. Required sections: Issue Tracker, Source Control, PR Rules, PR Description Template, Build & Test
5. Optional sections either omitted (simple templates like redmine-rails.md) or included in `<!-- -->` HTML comments (comprehensive templates like github-nextjs.md)

### Oracle PL/SQL Build/Test Commands
- Build: `bash db/scripts/deploy.sh` (Flyway migrations + compilation + validation)
- Test: `bash db/scripts/test.sh` (utPLSQL test runner)
- These are generic placeholders — actual scripts are project-specific

### Redmine State Transition Format
From redmine-rails.md: `In Progress: status:In Progress, Blocked: status:Blocked, For Review: status:For Review, Done: status:Closed`
The `status:` prefix is Redmine-specific syntax used by the publisher agent.

### Template List Location
Single source of truth: `skills/template/SKILL.md` lines 26-34 (table with Template | Stack | Tracker columns).

### Agent Override Pattern for Oracle
Gap analysis Appendices A and B provide complete agent override content for fixer and test-engineer. These should be referenced in the template's Agent Overrides section but NOT embedded (they are project-level files, not plugin-level).

## Decision
Proceed directly to implementation. No unknowns remain.
