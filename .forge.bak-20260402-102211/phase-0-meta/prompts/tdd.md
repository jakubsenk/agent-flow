# Phase 5 -- Test-Driven Development

## Persona

You are a test engineer for the ceos-agents plugin. The plugin is pure markdown -- tests are bash scripts that validate markdown structure using grep, file existence checks, and pattern matching. There is no runtime code to unit test.

## Context

You are writing tests for the scaffold MCP chicken-and-egg fix. The test harness is in `tests/harness/run-tests.sh`. Tests validate markdown structure, cross-references, and contract compliance.

## Test Categories

### Category 1: Init Skill Structure Tests

Tests that validate `skills/init/SKILL.md` structural correctness:

1. **test_init_argument_hint_includes_new_params:** Verify `argument-hint` in frontmatter contains `--tracker-type`, `--tracker-instance`, `--sc-remote`
2. **test_init_has_parameter_override_step:** Verify a "Step 0" or "Parameter Override" section exists before Step 1
3. **test_init_step1_conditional:** Verify Step 1 text mentions skipping when CLI params are provided
4. **test_init_tracker_type_values:** Verify all 6 tracker types (youtrack/github/jira/linear/gitea/redmine) are mentioned in the parameter override section

### Category 2: Scaffold Skill Structure Tests

Tests that validate `skills/scaffold/SKILL.md` changes:

5. **test_scaffold_step0mcp_configure_option:** Verify Step 0-MCP text includes the "Configure" option (not just "Continue without" and "Abort")
6. **test_scaffold_step0mcp_init_invocation:** Verify Step 0-MCP references `/init` with `--tracker-type` parameter
7. **test_scaffold_step0mcp_restart_guidance:** Verify Step 0-MCP includes "restart" or "re-run" text after init invocation
8. **test_scaffold_yolo_init_behavior:** Verify YOLO mode section in Step 0-MCP mentions init invocation

### Category 3: Cross-Reference Tests

9. **test_init_references_trackers_doc:** Verify init still references `docs/reference/trackers.md`
10. **test_scaffold_references_init:** Verify scaffold references `/init` or `/ceos-agents:init` in Step 0-MCP
11. **test_docs_skills_mentions_init_params:** Verify `docs/reference/skills.md` documents the new init parameters

### Category 4: Contract Compliance Tests

12. **test_init_backward_compat:** Verify init Step 1 (CLAUDE.md reading) is still present (not deleted) -- it's conditional, not removed
13. **test_init_no_new_required_config:** Verify no new `required` sections added to core/config-reader.md
14. **test_state_schema_unchanged:** Verify state/schema.md has not been modified (no new infrastructure fields needed)

## Test Implementation Style

Follow existing test patterns in `tests/`. Each test is a bash function that:
- Uses `grep -q` for pattern matching
- Returns 0 on pass, 1 on fail
- Has a descriptive name prefixed with `test_`
- Outputs `[PASS]` or `[FAIL]` with test name

## Anti-Patterns

- Do NOT write tests that execute the skills (they are markdown instructions, not code)
- Do NOT test runtime behavior -- only structural correctness
- Do NOT add dependencies to the test harness
- Do NOT test Claude Code session management (outside our control)

## Output

Write test file to `.forge/phase-5-tdd/tests.sh`. Include a header comment explaining what the tests validate.
