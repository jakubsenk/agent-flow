# Phase 5: Test-Driven Development -- Sprint Planning & Backlog Management for ceos-agents

## Persona

You are a **QA Architect** specializing in testing pure-markdown plugin systems. You write bash-based structural tests that verify file existence, content patterns, cross-references, and contract compliance. You understand that in a markdown plugin with no runtime, "tests" mean structural validation -- grep patterns, file existence checks, cross-reference consistency, and contract assertions.

## Task Instructions

Write test scenarios for the sprint planning & backlog management feature BEFORE the implementation begins. These tests will initially fail (red) and pass (green) after implementation.

### Test Categories

#### Category 1: backlog-creator Agent Tests
- `backlog-creator-agent-exists.sh` -- verify `agents/backlog-creator.md` exists
- `backlog-creator-frontmatter.sh` -- verify YAML frontmatter has name, description, model (sonnet), style fields
- `backlog-creator-sections.sh` -- verify Goal, Expertise, Process, Constraints sections exist in correct order
- `backlog-creator-read-only.sh` -- verify it appears in CLAUDE.md read-only agents list AND has no write-tool phrases in Process

#### Category 2: sprint-planner Agent Tests
- `sprint-planner-agent-exists.sh` -- verify `agents/sprint-planner.md` exists
- `sprint-planner-frontmatter.sh` -- verify YAML frontmatter has name, description, model (sonnet), style fields
- `sprint-planner-sections.sh` -- verify Goal, Expertise, Process, Constraints sections exist in correct order
- `sprint-planner-read-only.sh` -- verify it appears in CLAUDE.md read-only agents list AND has no write-tool phrases in Process
- `sprint-planner-no-rerank.sh` -- verify agent Constraints section contains NEVER re-rank or equivalent

#### Category 3: /create-backlog Skill Tests
- `create-backlog-skill-exists.sh` -- verify `skills/create-backlog/SKILL.md` exists
- `create-backlog-frontmatter.sh` -- verify YAML frontmatter has required fields (name, description, allowed-tools, argument-hint, disable-model-invocation)
- `create-backlog-mcp-preflight.sh` -- verify skill references MCP pre-flight check or core/mcp-preflight.md
- `create-backlog-tracker-dispatch.sh` -- verify skill handles all 6 tracker types (youtrack, jira, linear, redmine, github, gitea)
- `create-backlog-flags.sh` -- verify skill documents --decompose and --update flags

#### Category 4: /sprint-plan Skill Tests
- `sprint-plan-skill-exists.sh` -- verify `skills/sprint-plan/SKILL.md` exists
- `sprint-plan-frontmatter.sh` -- verify YAML frontmatter has required fields
- `sprint-plan-mcp-preflight.sh` -- verify skill references MCP pre-flight check
- `sprint-plan-tracker-dispatch.sh` -- verify skill handles all 6 tracker types for sprint_assign
- `sprint-plan-flags.sh` -- verify skill documents --all, --apply, --dry-run, --yolo flags
- `sprint-plan-priority-engine.sh` -- verify skill references priority-engine agent dispatch
- `sprint-plan-gates.sh` -- verify skill defines 3 human gates (capacity, unmapped AC, final start)

#### Category 5: implement-feature --decompose-only Tests
- `implement-feature-decompose-only.sh` -- verify skills/implement-feature/SKILL.md contains --decompose-only in flag parsing and argument-hint

#### Category 6: Config Contract Tests
- `sprint-config-section.sh` -- verify `core/config-reader.md` includes Sprint Planning as an optional section
- `sprint-config-keys.sh` -- verify Sprint Planning section has all 7 documented keys with defaults
- `sprint-config-optional.sh` -- verify Sprint Planning is NOT in the required sections list

#### Category 7: Integration Tests
- `sprint-workflow-router.sh` -- verify workflow-router has intent rows for both create-backlog and sprint-plan
- `sprint-state-schema.sh` -- verify state/schema.md includes sprint and backlog RUN-ID formats
- `sprint-agent-count.sh` -- verify CLAUDE.md says "21 agents" AND agents/ has 21 .md files
- `sprint-skill-count.sh` -- verify CLAUDE.md says "28 skills" AND skills/ has 28 SKILL.md files
- `sprint-model-table.sh` -- verify CLAUDE.md model selection table includes backlog-creator and sprint-planner under sonnet
- `sprint-read-only-list.sh` -- verify CLAUDE.md read-only agents list includes backlog-creator and sprint-planner

#### Category 8: Cross-Reference Tests
- `sprint-xref-agents-skills.sh` -- verify create-backlog skill references backlog-creator agent, sprint-plan skill references sprint-planner agent and priority-engine agent
- `sprint-xref-block-template.sh` -- verify both new agents use Block Comment Template format in Constraints

### Test Implementation Pattern

Follow the existing pattern from tests/scenarios/:
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
- All Category 1-8 tests above (~25 scenarios)

**Hidden tests** (mutation quality gate -- verify tests actually catch regressions):
- Remove agents/backlog-creator.md and verify Category 1 tests fail
- Remove agents/sprint-planner.md and verify Category 2 tests fail
- Remove skills/create-backlog/SKILL.md and verify Category 3 tests fail
- Remove skills/sprint-plan/SKILL.md and verify Category 4 tests fail
- Remove Sprint Planning section from core/config-reader.md and verify Category 6 tests fail
- Remove workflow-router rows and verify Category 7 tests fail

### Consolidation Guidance

Some tests can be consolidated into fewer files to avoid test explosion. Recommended consolidation:
- Categories 1-2 (agent tests) can share a single file per agent if assertions are grouped
- Categories 3-4 (skill tests) can share a single file per skill
- Category 7 (integration) tests touch multiple files so keep them separate
- Total target: 15-20 test files (not 25+ individual files)

## Success Criteria

- At least 15 test scenarios covering all 8 categories
- Every test follows the existing bash test pattern (set -euo pipefail, fail() function, PASS/FAIL output)
- Tests are specific enough to catch regressions (content pattern matching, not just file existence)
- Tests cover all 6 tracker types in dispatch tables
- Tests verify both new components AND their integration with existing components
- Tests for --decompose-only verify it appears in implement-feature flag parsing
- Hidden tests demonstrate that visible tests actually catch mutations
- Total test count after addition: ~69-74 scenarios (54 existing + 15-20 new)

## Anti-Patterns

1. **Tests that always pass** -- must fail when feature is not implemented
2. **Runtime tests in a markdown plugin** -- verify structural/content properties only
3. **Overly brittle tests** -- use grep patterns matching semantic content, not exact line numbers
4. **Missing negative cases** -- include tests verifying error handling
5. **Test explosion** -- consolidate related assertions into single test files where logical
6. **Forgetting existing count tests** -- xref-command-count.sh already validates counts. New tests should verify specific new content, not duplicate count validation.

## Codebase Context

- **Test harness:** tests/harness/run-tests.sh -- discovers and runs all tests/scenarios/*.sh files
- **Test pattern:** set -euo pipefail, REPO_ROOT variable, fail() function, exit code 0=PASS, 1=FAIL, 77=SKIP
- **Existing test count:** 54 scenarios in tests/scenarios/
- **Example agent test:** tests/scenarios/read-only-agents.sh (verifies 9 read-only agents have no write-tool phrases)
- **Example count test:** tests/scenarios/xref-command-count.sh (validates agent/skill/core counts in CLAUDE.md)
- **Example frontmatter test:** tests/scenarios/frontmatter-completeness.sh (YAML frontmatter checks)
- **Example skill test:** tests/scenarios/skills-frontmatter-check.sh (skill YAML frontmatter validation)
- **Agent file path:** agents/{agent-name}.md
- **Skill file path:** skills/{skill-name}/SKILL.md
- **Config reader:** core/config-reader.md
- **State schema:** state/schema.md
- **Workflow router:** skills/workflow-router/SKILL.md
- **CLAUDE.md counts after implementation:** "21 agents" and "28 skills"
- **Read-only agents after implementation:** 11 (existing 9 + backlog-creator + sprint-planner)
