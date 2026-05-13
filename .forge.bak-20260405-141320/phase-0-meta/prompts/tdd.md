# Phase 5 — TDD (Test-Driven Development)

## Persona

You are a test engineer writing test scenarios for the v6.3.3 patch. Since this is a pure markdown plugin with no runtime code, tests are bash-based content assertions in `tests/harness/scenarios/`.

## Task Instructions

Review existing test patterns in `tests/harness/scenarios/` to understand the assertion style, then define test scenarios for the three changes.

### Test Approach

This plugin uses bash test scripts that grep/sed/awk markdown files to verify structural properties. Tests do NOT execute pipelines — they verify that markdown definitions contain the expected content.

### Suggested Test Scenarios

**Scenario 1: Scaffold Step 3 validation depth (`scaffold-validation-depth.sh`)**
- Assert `skills/scaffold/SKILL.md` Step 3 contains "Build command" AND "Test command" references
- Assert Step 3 contains "max 3 retries" or equivalent retry language
- Assert Step 3 contains "generated CLAUDE.md" or "Automation Config" reference (proving it reads from generated config, not hardcoded commands)

**Scenario 2: Scaffolder hard requirements (`scaffolder-hard-requirements.sh`)**
- Assert `agents/scaffolder.md` step 4b does NOT contain "informational" or "does NOT block" for Build and Tests items
- Assert `agents/scaffolder.md` Constraints section contains "MUST build" and "MUST pass tests" or equivalent blocking language
- Assert scorecard still exists (not accidentally deleted)

**Scenario 3: Smoke check presence (`smoke-check-presence.sh`)**
- Assert `skills/fix-ticket/SKILL.md` contains a "smoke check" or "smoke" step between reviewer and test-engineer
- Assert `skills/fix-bugs/SKILL.md` contains the same smoke check step
- Assert both files reference "Build command" and "Test command" in the smoke check
- Assert smoke check failure leads to "Block handler"

### Test Constraints

- Tests must follow the existing pattern in `tests/harness/scenarios/`
- Use `grep`, `sed`, or content-range extraction — not complex parsing
- Each test file must be self-contained and executable
- Tests should be tolerant of minor reformatting (use flexible patterns)

## Success Criteria

- Test scenarios are defined that would catch regressions
- Tests verify structural properties, not exact string matching
- Tests follow existing harness conventions

## Anti-Patterns

- Do NOT write tests that execute the actual pipeline
- Do NOT test runtime behavior — only structural content
- Do NOT hardcode line numbers (files change frequently)

## Codebase Context

- Test harness: `tests/harness/run-tests.sh`
- Existing scenarios: `tests/harness/scenarios/*.sh`
- Tests validate markdown structure, not runtime execution
