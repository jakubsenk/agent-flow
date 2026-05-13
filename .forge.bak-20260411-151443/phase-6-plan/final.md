# Phase 6 — Implementation Plan

## Task Graph

### Task 1: Create Oracle PL/SQL template file
- **File:** `examples/configs/redmine-oracle-plsql.md`
- **Action:** CREATE
- **Dependencies:** None
- **Details:**
  1. H1 heading: `# Oracle PL/SQL + Redmine — Automation Config Template`
  2. Blockquote: `> Copy the section below into your project's CLAUDE.md`
  3. Required sections (active):
     - Issue Tracker (Redmine type, placeholders for instance/project/query)
     - Source Control (placeholders for remote/branch)
     - PR Rules (ForReview label)
     - PR Description Template (Oracle-specific: Root Cause, utPLSQL mention)
     - Build & Test (bash db/scripts/deploy.sh, bash db/scripts/test.sh)
  4. Oracle-relevant optional sections (active, per task spec):
     - Local Deployment (Oracle XE Docker)
     - Agent Overrides (customization/ path)
     - Retry Limits (conservative: fixer 3, test 2, build 2)
     - Decomposition (max 5 subtasks, fail-fast, squash, tracker subtasks disabled)
     - Pipeline Profiles (oracle-backend profile skipping browser/e2e/reproducer)
     - Error Handling (comment on block, max 3 blocked per run)
  5. Additional optional sections as comments for user to uncomment if needed:
     - Feature Workflow, Hooks, Notifications, Worktrees, E2E Test, Metrics, Extra labels, Custom Agents, Browser Verification, Module Docs

### Task 2: Update template catalog in SKILL.md
- **File:** `skills/template/SKILL.md`
- **Action:** MODIFY (add one table row)
- **Dependencies:** None (parallel with Task 1)
- **Details:**
  - Add `| redmine-oracle-plsql | Oracle PL/SQL | Redmine |` after the `redmine-rails` row

### Task 3: Verify no other docs need updating
- **Action:** VERIFY (already confirmed in Phase 0)
- **Dependencies:** None
- **Result:** Confirmed — no docs in docs/reference/ or README reference template lists. Only `skills/template/SKILL.md` has the catalog.

### Task 4: Run test suite
- **Action:** VERIFY
- **Dependencies:** Tasks 1, 2
- **Details:** Run `./tests/harness/run-tests.sh` and confirm all pass

## Execution Order
1. Tasks 1 + 2 (parallel — independent files)
2. Task 4 (after both complete)

## Constraints
- Do NOT perform version bump
- Template format must match existing redmine-rails.md structure exactly
- Use generic placeholders (`<...>`), not project-specific values
- All file content in English
