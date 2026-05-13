# Phase 5: TDD -- Test Design

## Persona
You are a **test engineer** for a pure-markdown Claude Code plugin. You design bash-based test scenarios that validate skill definitions through structural analysis (grep, pattern matching) since there is no runtime to execute.

## Task Instructions

Design test cases for the three check-setup changes. Since this is a markdown plugin with no runtime, tests are structural validation scripts (bash + grep) that verify the skill file contains the expected patterns.

### Test Suite: check-setup-improvements

#### T1: TLS Diagnostic Block Exists
- Verify step 9 contains "curl" diagnostic sub-step
- Verify the text "NODE_OPTIONS" and "--use-system-ca" appears in the skill
- Verify both failure modes are distinguished: "server reachable" vs "server unreachable"
- Verify the curl command includes `--max-time` timeout

#### T2: No read:user Scope Check
- Verify the skill does NOT contain "read:user" anywhere
- Verify the skill does NOT contain "list_my_repositories" anywhere
- Verify step 10 contains "configured remote" or "declared remote" (not "list repositories")

#### T3: Robust Path Resolution
- Verify the skill contains a path resolution instruction (Glob or equivalent) before first trackers.md reference
- Verify the skill contains a fallback message for when trackers.md is not found
- Verify the bare string `Read docs/reference/trackers.md` (without resolution) does NOT appear

#### T4: Output Format Updated
- Verify the output format section contains the TLS diagnostic example line
- Verify the output format section contains "remote {owner/repo} confirmed" (not "list repositories")

#### T5: No Regressions
- Verify all 5 blocks are still present (Automation Config, MCP servers, Connectivity, Build & Test, Plugin Composability)
- Verify the Rules section is unchanged (read-only, placeholder detection, safe for repeated execution)
- Verify frontmatter is intact (name, description, allowed-tools, argument-hint)

### Test File Location
`tests/scenarios/check-setup-improvements.sh`

## Success Criteria
- All tests are structural (grep-based), not runtime tests
- Tests cover all 10 acceptance criteria from the spec
- Tests follow the existing test harness pattern in `tests/harness/run-tests.sh`
- No false positives -- tests are specific enough to not match unrelated content

## Anti-Patterns
- Do NOT write tests that require MCP connectivity or runtime execution
- Do NOT create mock MCP servers for this -- structural validation is sufficient
- Do NOT modify existing test files -- create a new test scenario file
- Do NOT test behavior that depends on LLM interpretation (only test the instruction text)

## Codebase Context
- Test harness: `tests/harness/run-tests.sh` -- discovers and runs `tests/scenarios/*.sh`
- Test pattern: each scenario defines `pass()` and `fail()` functions, uses grep on source files
- Example test: `tests/scenarios/config-required-keys.sh` -- greps skill files for required config keys
- Total existing tests: ~39 scenario files
