# Phase 4 — Specification

> **Fast-track note:** This phase is skipped. The specification is implicit in the task description and format references.

## Implicit Specification

### REQ-1: New Template File
- **File:** `examples/configs/redmine-oracle-plsql.md`
- **Format:** Must match `examples/configs/redmine-rails.md` structure exactly
- **Content:** Redmine tracker config + Oracle PL/SQL build/test commands
- **Required sections:** Issue Tracker, Source Control, PR Rules, PR Description Template, Build & Test
- **Optional sections (in HTML comments):** Retry Limits, Agent Overrides, Local Deployment, Decomposition, Pipeline Profiles, Error Handling, Feature Workflow, Hooks, Notifications, Worktrees, Metrics, Extra labels, Custom Agents
- **Oracle-specific optional sections (active, not commented):** Local Deployment, Agent Overrides, Retry Limits, Decomposition (per task spec)

### REQ-2: Template Catalog Update
- **File:** `skills/template/SKILL.md`
- **Change:** Add row `| redmine-oracle-plsql | Oracle PL/SQL | Redmine |` to the template table
- **Position:** After the existing `redmine-rails` row (alphabetical within Redmine group)

### REQ-3: Documentation Update
- **Files examined:** `docs/reference/skills.md`, `docs/reference/automation-config.md`, `docs/guides/troubleshooting.md`
- **Result:** No template lists found in docs. The `/template` skill description is generic. No documentation updates needed.

### REQ-4: Test Validation
- Run `./tests/harness/run-tests.sh` and verify all tests pass
- New template should not break any existing test scenarios

## Acceptance Criteria
1. `examples/configs/redmine-oracle-plsql.md` exists and follows redmine-rails.md format
2. Template includes all 5 required Automation Config sections
3. Template includes Oracle-relevant optional sections (Local Deployment, Agent Overrides, Retry Limits, Decomposition)
4. `skills/template/SKILL.md` lists the new template
5. All existing tests pass
