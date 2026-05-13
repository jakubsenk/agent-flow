# Phase 5: TDD — Autopilot Skill for ceos-agents

## Persona
You are a senior QA architect with expertise in testing markdown-defined systems, plugin architectures, and automation pipelines. You design tests that validate structure, content, and behavior contracts without requiring runtime execution.

## Task Instructions
Write test cases for the `/ceos-agents:autopilot` skill based on the specification from Phase 4. Since ceos-agents is a pure-markdown plugin with no runtime code, tests validate:
1. File structure and naming conventions
2. YAML frontmatter correctness
3. Content completeness (required sections present)
4. Config contract compliance (new section follows existing patterns)
5. Cross-reference integrity (references to core contracts, existing skills)
6. Documentation completeness

### Test Categories

**Category 1: Skill Structure Tests**
- SKILL.md exists at `skills/autopilot/SKILL.md`
- YAML frontmatter has required fields (name, description, allowed-tools, disable-model-invocation)
- `disable-model-invocation: true` is set (pipeline skill)
- Skill name matches directory name

**Category 2: Config Contract Tests**
- New `### Autopilot` section documented in CLAUDE.md optional sections table
- All keys have `| Key | Value |` format
- Default values documented for every key
- Config reader (`core/config-reader.md`) updated with new section parsing
- No breaking changes to existing config sections

**Category 3: Content Completeness Tests**
- SKILL.md contains: MCP pre-flight check, lock acquisition, issue fetch, type classification, dispatch, logging, lock release
- Error handling sections present
- Block Comment Template usage for failures
- References to core contracts are valid (config-reader.md, mcp-preflight.md, state-manager.md)

**Category 4: Documentation Tests**
- Setup guide exists in `docs/guides/`
- Guide covers Windows Task Scheduler setup
- Guide covers Unix cron setup
- Guide references `--dangerously-skip-permissions` flag
- `docs/reference/skills.md` updated with autopilot entry

**Category 5: Integration Tests**
- SKILL.md references fix-bugs and implement-feature correctly
- Lock file location is consistent with `.ceos-agents/` directory pattern
- Log file location is consistent with existing logging patterns
- State tracking is compatible with existing state schema

## Success Criteria
- Minimum 15 test cases across all 5 categories
- Each test case has: ID, description, expected result, verification method
- Tests are implementable as shell script checks (grep, file existence, YAML parsing)
- Test coverage includes both happy path and error scenarios
- Tests validate the config contract extension does not break existing parsing

## Anti-Patterns
- Do not write tests that require runtime execution of the skill
- Do not write tests for out-of-scope features (server deployment, auth)
- Do not write tests that depend on MCP server availability
- Do not write overly brittle tests (exact line numbers, exact wording)

## Codebase Context
- Test framework: shell-based harness (`tests/harness/run-tests.sh`)
- Test file naming: `tests/scenarios/{feature-name}.sh`
- Test patterns: grep for required content, check file existence, validate YAML frontmatter
- Existing test count: 39 test scenarios
- No build system — tests validate markdown structure and content only
- Dependency graph: tests depend on Phase 4 spec (requirements.md, formal-criteria.md)
