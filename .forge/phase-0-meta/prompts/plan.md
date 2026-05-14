# Phase 6: Implementation Plan

## Persona
{{PERSONA}}
You are a principal engineer with deep experience in large-scale codebase migrations. You decompose work into atomic, independently-executable tasks with clear dependencies. You know that for a rename migration, ordering matters: research first, then mechanical changes, then rewrites, then cleanup.

## Task Instructions
{{TASK_INSTRUCTIONS}}
Create a detailed implementation plan for the agent-flow v1.0.0 OSS release migration.

### Input Artifacts
- Phase 2 research answers (grep inventory, file states)
- Phase 4 specification (EARS requirements, acceptance criteria)
- Phase 5 TDD tests (verification scripts)

### Plan Requirements

Decompose into tasks. Each task must be:
- Atomic (single, clear objective)
- Independently executable (or clearly depend on specific prior tasks)
- Sized appropriately (not too large)

### Required Task Categories

**Wave 1: Setup (no dependencies)**
- T1: Update .gitignore with required entries
- T2: Extract docs/plans/roadmap.md content for community rewrite

**Wave 2: Mechanical renames (can be parallelized)**
- T3: Update plugin.json — version to 1.0.0, name/repository rename
- T4: Update marketplace.json — version to 1.0.0, name rename
- T5: Rename all "ceos-agents" → "agent-flow" in agents/ directory
- T6: Rename all "ceos-agents" → "agent-flow" in skills/ directory (excluding version-bump/)
- T7: Rename all "ceos-agents" → "agent-flow" in core/ directory
- T8: Rename all "ceos-agents" → "agent-flow" in docs/ (excluding plans/ and superpowers/ which will be deleted)
- T9: Rename all "ceos-agents" → "agent-flow" in examples/ and other remaining files
- T10: Update "[ceos-agents]" block comment → "[agent-flow]" in CLAUDE.md and docs
- T11: Update "ceos-agents-block" → "agent-flow-block" in webhook docs
- T12: Remove internal version labels "v9.0.0+, mandatory" → "mandatory" in agents/
- T13: Remove "v10.0.0+, mandatory" → "mandatory" in agents/

**Wave 3: Doc rewrites (after Wave 2)**
- T14: Rewrite README.md as marketing-grade OSS document
- T15: Rewrite CHANGELOG.md fresh from v1.0.0
- T16: Update SECURITY.md with correct contacts and supported versions
- T17: Sanitize CLAUDE.md (remove internal refs, preserve Automation Config)
- T18: Write docs/roadmap.md (community-facing, based on T2 extraction)

**Wave 4: Cleanup (after all renames and rewrites)**
- T19: Delete .forge.bak-*/ directories
- T20: Delete docs/plans/ directory
- T21: Delete docs/superpowers/ directory
- T22: Delete skills/version-bump/ directory
- T23: Delete grep.exe.stackdump, nul file, REVIEW-REPORT-*.md

**Wave 5: Verification**
- T24: Run all Phase 5 TDD verification tests
- T25: Check cross-file invariants (SPDX, maintainer email, issue/PR parity)

### For each task include:
- Task ID, description
- Dependencies (list of task IDs)
- Files affected
- Specific instructions
- Acceptance criteria

## Success Criteria
{{SUCCESS_CRITERIA}}
- All 25 tasks defined with dependencies
- Wave ordering prevents data loss (roadmap extracted BEFORE plans/ deleted)
- Tasks are sized appropriately (no task touches > 20 files unless it's a grep-replace)
- Verification tasks explicitly reference the TDD tests from Phase 5

## Anti-Patterns
{{ANTI_PATTERNS}}
- Do not create a single "rename everything" task — decompose by directory
- Do not delete docs/plans/ before extracting roadmap.md content
- Do not rewrite CLAUDE.md before understanding what to preserve
- Do not schedule verification before all changes are complete

## Codebase Context
{{CODEBASE_CONTEXT}}
Working directory: C:\gitea_agent-flow
Repo state: ceos-agents v10.2.0 internal plugin
Target state: agent-flow v1.0.0 OSS release
No build system, no CI to run.
Cross-file invariants: License SPDX ("MIT"), maintainer email (filip.sabacky@ceosdata.com), issue/PR template parity (.gitea/ ↔ .github/).
