# Phase 5: Test-Driven Development -- Sprint Planning for ceos-agents

## Persona

You are a **QA Architect** specializing in testing pure-markdown plugin systems. You write bash-based structural tests that verify file existence, content patterns, cross-references, and contract compliance. You understand that in a markdown plugin with no runtime, "tests" mean structural validation -- grep patterns, file existence checks, cross-reference consistency, and contract assertions.

## Task Instructions

Write test scenarios for the sprint planning feature BEFORE the implementation begins. These tests will initially fail (red) and pass (green) after implementation.

### Test Categories

#### Category 1: Agent Definition Tests
- `sprint-planner-agent-exists.sh` -- verify `agents/sprint-planner.md` exists
- `sprint-planner-frontmatter.sh` -- verify YAML frontmatter has name, description, model, style fields
- `sprint-planner-sections.sh` -- verify Goal, Expertise, Process, Constraints sections exist
- `sprint-planner-model.sh` -- verify model assignment matches the spec (opus)
- `sprint-planner-read-only-or-not.sh` -- verify the agent's read/write classification is consistent with CLAUDE.md agent list

#### Category 2: Skill Definition Tests
- `sprint-plan-skill-exists.sh` -- verify `skills/sprint-plan/SKILL.md` exists
- `sprint-plan-frontmatter.sh` -- verify YAML frontmatter has required fields (name, description, allowed-tools, argument-hint)
- `sprint-plan-mcp-preflight.sh` -- verify skill references MCP pre-flight check
- `sprint-plan-tracker-dispatch.sh` -- verify skill handles all 6 tracker types (youtrack, jira, linear, redmine, github, gitea)
- `sprint-plan-flag-parsing.sh` -- verify skill documents flag parsing for --mode, --duration, --dry-run

#### Category 3: Config Contract Tests
- `sprint-plan-config-section.sh` -- verify `core/config-reader.md` includes Sprint Planning section
- `sprint-plan-config-optional.sh` -- verify Sprint Planning is listed as an optional section (not required)
- `sprint-plan-config-keys.sh` -- verify all documented keys have defaults

#### Category 4: Integration Tests
- `sprint-plan-workflow-router.sh` -- verify workflow-router has sprint planning intent rows
- `sprint-plan-priority-engine.sh` -- verify sprint-plan skill references priority-engine
- `sprint-plan-state-schema.sh` -- verify state/schema.md includes sprint planning fields
- `sprint-plan-agent-registry.sh` -- verify CLAUDE.md agent count is updated (20 agents)
- `sprint-plan-skill-count.sh` -- verify CLAUDE.md skill count is updated (27 skills)

#### Category 5: Cross-Reference Tests
- `sprint-plan-xref-agent-skill.sh` -- verify agent name in skill matches agent file name
- `sprint-plan-xref-block-template.sh` -- verify agent uses Block Comment Template format

### Test Implementation Pattern

Follow the existing pattern from `tests/scenarios/`:
```bash
#!/usr/bin/env bash
# Test: {description}
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# Test assertions here...

[ "$FAIL" -eq 0 ] && echo "PASS: {test description}"
exit "$FAIL"
```

### Test Split

**Visible tests** (run in CI, verify structural correctness):
- All Category 1-5 tests above

**Hidden tests** (mutation quality gate -- verify the tests actually catch regressions):
- Remove the sprint-planner agent file and verify Category 1 tests fail
- Remove the Sprint Planning config section and verify Category 3 tests fail
- Remove workflow-router rows and verify Category 4 tests fail

## Success Criteria

- At least 15 test scenarios covering all 5 categories
- Every test follows the existing bash test pattern (set -euo pipefail, fail() function, PASS/FAIL output)
- Tests are specific enough to catch regressions (not just "file exists" but content pattern matching)
- Tests cover all 6 tracker types in the dispatch table
- Tests verify both the new components AND their integration with existing components
- Hidden tests demonstrate that visible tests actually catch mutations

## Anti-Patterns

1. **Tests that always pass** -- a test that checks "does file exist OR does it not exist" is useless. Tests must fail when the feature is not implemented.
2. **Runtime tests in a markdown plugin** -- do not write tests that try to execute the skill. Tests verify structural/content properties only.
3. **Overly brittle tests** -- do not match exact line numbers or exact whitespace. Use grep patterns that match the semantic content.
4. **Missing negative cases** -- include at least 2 tests that verify error handling (e.g., missing config section behavior).
5. **Ignoring existing test count** -- after adding new tests, the total test count will change. Verify the test harness can discover and run all new tests.

## Codebase Context

- **Test harness:** `tests/harness/run-tests.sh` -- discovers and runs all `tests/scenarios/*.sh` files
- **Test pattern:** `set -euo pipefail`, `REPO_ROOT` variable, `fail()` function, exit code 0 = PASS, 1 = FAIL, 77 = SKIP
- **Existing test count:** 54 scenarios in `tests/scenarios/`
- **Example test files:** `tests/scenarios/pipeline-feature-agents.sh` (agent dispatch verification), `tests/scenarios/frontmatter-completeness.sh` (YAML frontmatter checks), `tests/scenarios/xref-agent-registry.sh` (cross-reference validation)
- **Agent file path:** `agents/{agent-name}.md`
- **Skill file path:** `skills/{skill-name}/SKILL.md`
- **Config reader:** `core/config-reader.md`
- **State schema:** `state/schema.md`
- **Workflow router:** `skills/workflow-router/SKILL.md`
- **CLAUDE.md agent/skill counts:** "19 agents" and "26 skills" (will become 20 and 27)
