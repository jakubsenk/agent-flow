# Phase 1 — Research Questions

> **Fast-track note:** This phase is skipped. All required information is already available from the gap analysis and existing template references.

## Pre-Answered Questions

### Q1: What format do existing Automation Config templates follow?
**Source:** `examples/configs/redmine-rails.md`, `examples/configs/github-nextjs.md`
**Answer:** H1 heading with "Stack + Tracker — Automation Config Template", blockquote instruction, then `## Automation Config` with subsections. Required sections use active table format. Optional sections are included in HTML comments (see github-nextjs.md pattern).

### Q2: What Oracle PL/SQL toolchain details are needed for the template?
**Source:** `docs/plans/readmine-project/ceos-agents-gap-analysis.md` (sections 5, Appendix A, B)
**Answer:** Oracle XE 21c Docker, SQLcl 26.1, Flyway 9.22.3, utPLSQL 3.1.14. Build: `bash db/scripts/deploy.sh`. Test: `bash db/scripts/test.sh`.

### Q3: What Redmine-specific config values are needed?
**Source:** `examples/configs/redmine-rails.md` (existing Redmine template)
**Answer:** Type: redmine, Instance/Project as placeholders, Bug query with project_id/status_id/tracker_id params, State transitions with `status:` prefix, On start set with `status:In Progress`.

### Q4: Which files reference the template list?
**Source:** Grep for "redmine-rails" across entire codebase
**Answer:** Only `skills/template/SKILL.md` (line 33) contains the template catalog table. `docs/reference/skills.md` describes /template generically without listing templates. No other docs list templates.

### Q5: Are there test scenarios that validate template files?
**Source:** `tests/scenarios/scaffold-tracker-integration.sh` (lines 223-225)
**Answer:** Yes, test G-32 validates redmine-rails.md has "Done: status:Closed". The new template should follow the same pattern to avoid future test failures.

## No Additional Research Needed
All questions are answered from existing codebase artifacts.
