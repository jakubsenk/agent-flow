# Phase 5: Test-Driven Development

## Persona
{{PERSONA}}: Senior QA Engineer specializing in markdown-based plugin testing, scenario-driven test harnesses, and integration test design for workflow automation systems.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Design test scenarios for the Decomposition Subtask Tracker Creation feature. The ceos-agents plugin uses a manual test suite in `tests/` with bash scripts that validate markdown structure and content patterns.

### Test Design Protocol

1. **Read existing test patterns** in `tests/` to understand the harness format
2. **Design test scenarios** that validate:
   - New step presence in all 3 skill files
   - Tracker-specific content for all 6 tracker types
   - Idempotence guard clause text
   - State schema tracker_id field
   - Config contract key presence
   - Guard clause (skip when decomposition is SINGLE_PASS or config is false)
   - Partial failure handling text
   - GitHub/Gitea checklist approach text
   - Cross-skill consistency (identical behavior patterns)

### Test Scenarios

#### Scenario 1: Step Presence (structural)
Validate that the "Create tracker subtasks" step exists in all 3 skills:
- `skills/implement-feature/SKILL.md` contains "Create tracker subtasks" or equivalent heading
- `skills/fix-ticket/SKILL.md` contains the same step
- `skills/fix-bugs/SKILL.md` contains the same step

#### Scenario 2: Tracker-Specific Parent Link
Validate that all 6 tracker types are mentioned in the new step:
- YouTrack: `parent:` parameter
- Jira: `parent:` + `issuetype: "Sub-task"`
- Linear: `parentId:` parameter
- Redmine: `parent_issue_id:` parameter
- GitHub: checklist in parent issue body
- Gitea: checklist in parent issue body

#### Scenario 3: Idempotence
Validate that idempotence guard clause is present:
- Check for `tracker_id` null check
- Check for title match fallback

#### Scenario 4: State Schema
Validate `tracker_id` field in state/schema.md:
- Field exists in Subtask Object Fields table
- Type is `string or null`
- Default is `null`

#### Scenario 5: Config Contract
Validate config key in CLAUDE.md:
- `Create tracker subtasks` appears in Decomposition section
- Default value is documented

#### Scenario 6: Cross-Skill Consistency
Validate that the 3 skills have consistent:
- Guard clause text
- Tracker iteration pattern
- State update pattern
- Partial failure handling

#### Scenario 7: Documentation
Validate doc updates:
- CHANGELOG.md has v6.4.0 entry
- roadmap.md mentions the feature as DONE

### Test Format
Follow existing test harness patterns in `tests/harness/`:
```bash
#!/usr/bin/env bash
# Test: {scenario name}
# Validates: {what it checks}

set -euo pipefail
source "$(dirname "$0")/../harness/helpers.sh"

# Test assertions using grep patterns on target files
assert_contains "skills/implement-feature/SKILL.md" "Create [Tt]racker [Ss]ubtasks"
# ...
```

## Success Criteria
{{SUCCESS_CRITERIA}}:
- [ ] At least 7 test scenarios covering all 6 items from the task
- [ ] Tests are structural (grep-based on markdown files) — no runtime testing needed
- [ ] Tests validate cross-skill consistency
- [ ] Tests cover all 6 tracker types
- [ ] Tests follow existing harness patterns
- [ ] Tests can run before implementation (TDD red phase)

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT write tests that require runtime execution (no MCP, no tracker APIs)
- Do NOT write overly brittle tests (grep for patterns, not exact line matches)
- Do NOT skip any of the 6 tracker types in tests
- Do NOT test agent definitions (architect output format is unchanged)
- Do NOT create tests that duplicate existing test coverage

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Test harness: `tests/harness/run-tests.sh`, `tests/harness/helpers.sh`
- Existing test scenarios: `tests/scenarios/` directory
- Test pattern: bash scripts with `grep`, `assert_contains`, `assert_not_contains`
- Target files for assertions: 3 skill files, state/schema.md, CLAUDE.md, CHANGELOG.md, roadmap.md
- No runtime code to test — all validation is structural/content-based
