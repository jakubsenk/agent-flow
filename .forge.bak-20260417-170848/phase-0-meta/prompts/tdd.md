# Phase 5: Test Design — v6.7.2 Pipeline Consistency & Dedup

## Persona
{{PERSONA}}: You are a **test engineer** for markdown-based plugin systems. You design structural validation tests that verify file existence, content patterns, cross-reference integrity, and contract compliance — without needing a runtime environment.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Design tests for the 4 work items in v6.7.2. Tests are bash scripts in `tests/` that validate structural properties of the markdown files.

### Test Categories

**Visible tests** (run during development):

1. **AC-1: Core contract exists and has correct structure**
   - `core/tracker-subtask-creator.md` exists
   - Contains sections: Purpose, Input Contract, Process, Output Contract, Failure Handling
   - Contains the Per-Tracker Issue Creation Parameters table
   - Contains the Issue Description Template

2. **AC-2/3/4: Skills delegate to core contract**
   - `skills/fix-ticket/SKILL.md` contains "Follow `core/tracker-subtask-creator.md`"
   - `skills/fix-ticket/SKILL.md` does NOT contain the inline pseudocode marker (e.g., "FOR EACH subtask IN decomposition.subtasks")
   - Same checks for fix-bugs and implement-feature

3. **AC-5/6: Webhook format alignment**
   - `skills/implement-feature/SKILL.md` does NOT contain `"issue":` or `"pr":` (wrong key names)
   - `skills/implement-feature/SKILL.md` webhook sections contain `--max-time 5 --retry 0`
   - All webhook calls contain `timestamp`

4. **AC-7: Block handler inline removed**
   - implement-feature step X does NOT contain inline block procedure steps (e.g., "Set issue state to Blocked")
   - implement-feature step X contains "Follow `core/block-handler.md`"

5. **AC-8-12: Doc fixes**
   - `core/fix-verification.md` title does not contain "Fix verification" (case-sensitive check)
   - `core/state-manager.md` does not contain "resume-ticket.md" in the Resume Process section
   - `state/schema.md` e2e_test section contains `verdict`, `result_path`, `attempts`
   - `core/fixer-reviewer-loop.md` contains "fix-ticket", "fix-bugs", and "implement-feature" near NEEDS_DECOMPOSITION

**Hidden tests** (regression):

1. **No content loss in tracker subtask extraction**
   - The core contract contains ALL tracker types (youtrack, jira, linear, redmine, github, gitea)
   - The core contract contains the idempotency check pattern
   - The core contract contains the GitHub/Gitea checklist pattern

2. **Webhook canonical format consistency**
   - ALL curl commands across skills/ and core/ use `--max-time 5 --retry 0` (grep check)
   - No curl command uses bare `"issue":` without `_id` suffix (except as part of `issue_id`)

### Test Script Conventions

Follow the existing test harness patterns in `tests/`:
- Scripts are bash, exit 0 on pass, exit 1 on fail
- Use grep/file existence checks
- Output human-readable pass/fail messages
- Test file naming: `{ac-number}-{description}.sh`

## Success Criteria
{{SUCCESS_CRITERIA}}:
- At least 5 visible tests covering all acceptance criteria
- At least 2 hidden regression tests
- Tests are implementable as bash scripts using grep/file checks
- Tests catch the specific issues identified in the analysis (wrong webhook keys, inline duplication, missing fields)
- Tests do NOT test behavior (no runtime execution) — only structural properties

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Writing tests that require a running pipeline or MCP server
2. Testing for exact line counts or positions (too brittle for markdown)
3. Testing for content that was intentionally left in place (e.g., state.json write instructions in skills)
4. Writing overly broad grep patterns that match false positives
5. Forgetting to test negative cases (content that should NOT be present after refactoring)

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Test harness: `tests/harness/run-tests.sh`
- Existing test structure: `tests/` directory with bash scripts
- ~39 existing test scenarios
- Tests validate markdown structure, not runtime behavior
- Key markers to test for/against:
  - Present: "Follow `core/tracker-subtask-creator.md`"
  - Absent: "FOR EACH subtask IN decomposition.subtasks" (in skills, after extraction)
  - Present: `--max-time 5 --retry 0` (in all webhook curls)
  - Absent: `"issue":"{issue_id}"` pattern with bare `issue` key (in implement-feature)
