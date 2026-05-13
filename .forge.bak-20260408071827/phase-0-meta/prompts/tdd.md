# Phase 5 — TDD (Test Plan)

## Persona
{{PERSONA}}
You are a QA engineer specializing in cross-platform CLI testing, with expertise in testing installation scripts and download validation logic across Windows, Linux, and macOS.

## Task Instructions
{{TASK_INSTRUCTIONS}}

### Objective
Define a test plan for verifying the bugfix. Since this is a pure markdown plugin with no runtime code, "tests" are manual verification scenarios and structural checks.

### Test Categories

**T1: Structural Validation — SKILL.md**
- Verify that the download validation step exists between steps 4 and 6
- Verify that the size check uses a threshold > 1 MB
- Verify that the Windows fallback section references `go install`
- Verify that the manual fallback is preserved as ultimate last resort
- Verify that Linux/macOS download paths are unchanged

**T2: Structural Validation — Documentation**
- Verify mcp-configuration.md Windows line warns about missing upstream binary
- Verify installation.md Windows section mentions Go requirement for forgejo-mcp
- Verify all URLs in modified sections are valid (codeberg.org links)

**T3: Scenario Validation (Manual)**
- Scenario A: Windows + Go installed + no existing binary → should attempt download, fail validation, succeed with go install
- Scenario B: Windows + Go NOT installed + no existing binary → should attempt download, fail validation, show clear error with instructions
- Scenario C: Linux + existing binary → should skip download entirely (no regression)
- Scenario D: Linux + no existing binary → should download, pass validation, succeed (no regression)
- Scenario E: Windows + existing valid binary → should skip download (no regression)

**T4: Edge Cases**
- Verify that if upstream eventually publishes a Windows binary, the download path works (size check passes for valid binary)
- Verify that the tag variable is used in `go install` (not hardcoded `@latest`)

### Existing Test Framework
The repository has a manual test suite in `tests/` run via `./tests/harness/run-tests.sh`. Check if any existing tests cover the init skill and whether new scenarios should be added.

## Success Criteria
{{SUCCESS_CRITERIA}}
1. All structural validations (T1, T2) pass via grep/read of modified files
2. Scenario descriptions are clear enough for manual execution
3. No regressions in Linux/macOS paths

## Anti-Patterns
{{ANTI_PATTERNS}}
- DO NOT attempt to run the actual init skill as a test — it requires interactive MCP server setup
- DO NOT write automated tests that curl external URLs — they are flaky and depend on network
- DO NOT skip edge case T4 — it ensures forward compatibility

## Codebase Context
{{CODEBASE_CONTEXT}}
- Pure markdown plugin — no unit test framework, no CI runner (Gitea Actions runner not configured)
- Tests in `tests/` are scenario-based markdown files validated by `tests/harness/run-tests.sh`
- 3 files modified: `skills/init/SKILL.md`, `docs/guides/mcp-configuration.md`, `docs/guides/installation.md`
