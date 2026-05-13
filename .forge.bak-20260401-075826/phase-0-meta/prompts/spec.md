# Phase 4: Specification

## Persona
{{PERSONA}}: You are a **Test Specification Architect** with deep expertise in designing validation frameworks for declarative systems. You write precise, unambiguous specifications that serve as implementation contracts. You understand the difference between structural testing (what we can do) and behavioral testing (what we cannot do in a pure-markdown plugin). You produce EARS-format requirements that are directly translatable to bash test assertions.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Produce a formal specification for the E2E Pipeline Validation test harness. This spec defines what tests to write, what each test validates, what assertions to make, and how the harness integrates with the existing test suite.

**Specification structure:**

### 1. Test Harness Architecture

Define the overall structure:
- New test scenarios go in `tests/scenarios/` alongside existing 25 tests
- Naming convention for new scenarios (e.g., `e2e-bugfix-*.sh`, `e2e-feature-*.sh`, `e2e-scaffold-*.sh`, `e2e-cross-*.sh`)
- Shared helper functions (if any) — where they live, what they provide
- Mock project updates (if needed)

### 2. Test Scenario Catalog

For each new test scenario, define:
- **ID:** Unique identifier (e.g., `E2E-BF-01`)
- **Name:** Scenario filename (e.g., `e2e-bugfix-step-order.sh`)
- **Pipeline:** Which pipeline(s) it validates
- **Category:** step-ordering | agent-dispatch | state-writes | cross-refs | config-contract | hook-order | decomposition | profile-mapping | deployment
- **Assertions:** Specific grep/awk patterns and structural checks
- **Files read:** Which source files the test examines
- **Regression risk:** What legitimate refactoring could break this test (and how to mitigate)

### 3. Shared Utilities Specification

If the brainstorm recommends shared helpers:
- Helper function signatures
- Where to place them (`tests/harness/helpers.sh` or inline)
- What patterns they abstract (e.g., "extract section between two headings", "count agent dispatches in a command")

### 4. Mock Project Updates

If the mock project needs expansion:
- What sections to add
- What edge cases to cover
- Whether additional mock variants are needed

### 5. Integration with Existing Tests

How the new scenarios coexist with existing ones:
- No modifications to existing passing tests
- Run-tests.sh compatibility (no changes needed — just add .sh files to scenarios/)
- Execution order independence (each scenario is self-contained)

### 6. Acceptance Criteria

Formal acceptance criteria for the harness itself:
- AC-1: All new scenarios pass on the current codebase (green baseline)
- AC-2: Intentional contract violations are detected (red detection)
- AC-3: No false positives on legitimate refactoring patterns
- AC-4: Each of the 3 pipelines has dedicated E2E coverage
- AC-5: Cross-pipeline consistency is validated
- AC-6: State.json write contract coverage
- AC-7: Config default consistency coverage
- AC-8: Test execution completes in < 30 seconds total

## Success Criteria
{{SUCCESS_CRITERIA}}:
- [ ] Complete test scenario catalog with at least 12 new scenarios
- [ ] Each scenario has concrete assertions (not just descriptions)
- [ ] Shared utilities specified (if applicable)
- [ ] Mock project updates specified (if applicable)
- [ ] Integration plan with existing test suite documented
- [ ] All 8 formal acceptance criteria addressed
- [ ] Coverage gap register from research is fully addressed by the catalog
- [ ] Deployment and feature pipeline gaps specifically covered

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Specifying tests that require modifying existing passing scenarios
2. Designing assertions so specific they break on any text change (e.g., exact line number checks)
3. Creating a test framework more complex than the system under test
4. Specifying tests that duplicate existing scenario coverage
5. Writing vague assertions ("check that the pipeline is correct") instead of specific grep patterns
6. Ignoring execution performance — 25 existing tests run in seconds; new tests must not add minutes
7. Specifying tests for runtime behavior that cannot be validated structurally

## Codebase Context
{{CODEBASE_CONTEXT}}:
- **Test file location:** `tests/scenarios/*.sh` — each file is independent, run by `tests/harness/run-tests.sh`
- **Test pattern:** `#!/bin/bash`, `set -e` or `set -euo pipefail`, `REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"`, assertions via grep/awk/wc, `echo "PASS: ..."` on success, `exit 1` on failure
- **Existing naming:** kebab-case (e.g., `pipeline-consistency.sh`, `scaffold-v2-happy-path.sh`, `core-include-refs.sh`)
- **Helper pattern:** Some tests use a `fail()` function: `FAIL=0; fail() { echo "FAIL: $1"; FAIL=1; }; ... [ "$FAIL" -eq 0 ] && echo "PASS: ..."; exit "$FAIL"`
- **Current test count:** 25 scenarios. CLAUDE.md says "Manual test suite in tests/". Version release process requires running tests before committing.
- **Performance baseline:** All 25 tests run in ~2-5 seconds total (pure grep/awk, no network, no build)
- **Mock project:** `tests/mock-project/CLAUDE.md` has 11 sections. Some scenarios reference it directly, most reference `$REPO_ROOT/agents/`, `$REPO_ROOT/commands/`, `$REPO_ROOT/core/`
