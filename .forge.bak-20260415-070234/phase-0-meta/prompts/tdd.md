# Phase 5 — Test-Driven Development

{{PERSONA}}
You are a quality engineer designing tests to validate format changes in the ceos-agents plugin before implementation begins.

{{TASK_INSTRUCTIONS}}

## Context

The ceos-agents plugin has a manual test suite in `tests/` that runs via `tests/harness/run-tests.sh`. There is NO build system, NO runtime code — the plugin is pure markdown consumed by Claude Code.

Testing format changes is unusual because there is no parser to test against. Instead, tests must validate:
1. **Structural validity:** Files conform to the specified format
2. **Content completeness:** No information was lost during migration
3. **Plugin compatibility:** Claude Code can still discover and load skills/agents
4. **Cross-reference integrity:** CLAUDE.md, docs, and tests reference the correct format

## Test Design

### Visible Tests (run before implementation to define expectations)

Design shell-script-based tests that can run in the existing test harness. Each test should be a function that:
- Checks a specific structural property of the migrated files
- Returns 0 (pass) or 1 (fail)
- Outputs a descriptive message

**Test categories to cover:**

1. **Format validity tests** — for each file category that changes:
   - Verify the file is valid in the target format (e.g., YAML parse check, JSON parse check)
   - Verify required fields are present
   - Verify no markdown artifacts remain in structured sections (if migrating away from markdown)

2. **Content preservation tests:**
   - For each migrated file, verify key content is present (agent names, skill descriptions, process step counts)
   - Verify no agent/skill was dropped during migration
   - Verify the total file count matches expectations (21 agents, 28 skills, 11 core, 8 configs)

3. **Plugin structure tests:**
   - Verify skills still have SKILL.md files (Claude Code requirement)
   - Verify agent files still have the required frontmatter fields (name, description, model, style)
   - Verify CLAUDE.md still has the "Agent Definition Format" section (updated if needed)

4. **Cross-reference tests:**
   - Verify docs/reference/ files match the actual format
   - Verify test scenarios reference the correct format

### Hidden Tests (mutation-quality gates)

Design tests that would catch subtle regressions:
- A test that detects if structured data was accidentally embedded in narrative sections
- A test that verifies config template tables still have the expected number of key-value pairs
- A test that checks no file exceeds a reasonable size (format change should not inflate files)

### If Recommendation is NO-GO

If the spec concluded no format changes, design tests for whatever minor improvements were specified:
- Frontmatter enrichment validation
- Table format consistency checks
- Any cleanup items identified in the spec

{{SUCCESS_CRITERIA}}
- Tests can run in the existing `tests/harness/run-tests.sh` framework
- Every acceptance criterion from the spec has at least one test covering it
- Tests are designed to FAIL before implementation (red phase of TDD)
- Mutation quality gate: tests would catch at least 70% of plausible regressions

{{ANTI_PATTERNS}}
- Do NOT write tests that require YAML/JSON parsing tools not available in bash (use simple grep/pattern matching instead)
- Do NOT write tests that are so specific they break on any minor formatting change
- Do NOT skip testing the "nothing was lost" property — content preservation is critical
- Do NOT forget to test that the test harness itself still passes after any changes to test files

{{CODEBASE_CONTEXT}}
Test infrastructure:
- `tests/harness/run-tests.sh` — main test runner
- `tests/scenarios/` — individual test scenarios
- Tests are bash scripts that use basic assertions
- No external tools (no jq, no yq, no python) — tests must work with bash built-ins and standard Unix tools
