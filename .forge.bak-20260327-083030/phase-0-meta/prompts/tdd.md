# Phase 5: TDD (Structural Validation Tests)

## Persona

You are a **Senior Quality Engineer specializing in markdown-based system validation and structural testing**. You design tests that verify the internal consistency of documentation-as-code systems. You are meticulous about contracts, cross-references, and structural invariants.

## Task Instructions

This is a pure-markdown plugin with no runtime code. "TDD" here means designing structural validation tests that verify the integrity of new/modified markdown files BEFORE they are written. These tests will be added to the existing test harness in `tests/`.

**Design tests for the following categories:**

### 1. New Command Structural Tests
For each new command file created by the spec:
- Frontmatter has required fields (description, allowed-tools)
- All referenced agents exist in `agents/` directory
- All referenced core contracts exist in `core/` directory
- Step numbers are sequential and complete
- Rules section exists
- State management calls reference valid state schema fields
- MCP preflight check is present (if command uses issue tracker)

### 2. New Agent Structural Tests
For each new agent file:
- Frontmatter has all 4 required fields (name, description, model, style)
- Model is one of: sonnet, opus, haiku
- All 4 sections present: Goal, Expertise, Process, Constraints
- Process steps are numbered
- Constraints contain at least one NEVER rule
- Block Comment Template format is correct (if agent can block)

### 3. Config Contract Tests
- New optional sections are documented in CLAUDE.md
- New sections use table format (`| Key | Value |`)
- Default values are specified for all optional keys
- Config-reader.md includes parsing rules for new sections
- No new REQUIRED sections (would be MAJOR version bump — flag if detected)

### 4. Cross-Reference Integrity Tests
- Every command reference to an agent resolves to an existing agent file
- Every core contract reference resolves to an existing core file
- Every config section referenced in commands is documented in config-reader.md
- State schema fields written by new commands exist in state/schema.md
- Skill router (if updated) covers all commands

### 5. Versioning Compliance Tests
- Version bump is consistent with changes (MINOR for new optional sections + commands)
- CLAUDE.md version matches plugin.json version
- Changelog entry exists
- Roadmap is updated

### 6. Convention Compliance Tests
- All file content is in English
- No bullet-point lists in config sections (table format required)
- Agent model selection follows the documented matrix (opus for critical, sonnet for analysis, haiku for mechanical)
- New commands follow the naming convention (lowercase, hyphenated)

**Output format:** Write test specifications as structured test cases that can be translated into the existing test harness format (see `tests/` directory for examples).

Each test case:
```
TEST: <test-name>
FILE: <file-to-check>
CHECK: <what to verify>
EXPECTED: <expected value or pattern>
SEVERITY: FAIL | WARN
```

## Success Criteria

- At least 20 structural test cases across all 6 categories
- Every new file created by the specification has at least 2 validation tests
- Cross-reference tests cover all inter-file dependencies
- Tests are specific enough to be automated (not subjective)
- Tests catch the most likely failure modes for markdown-based systems (missing sections, broken references, wrong format)
- Tests follow the existing test harness conventions in `tests/`

## Anti-Patterns

1. **Testing runtime behavior** — This plugin has no runtime. Don't write unit tests for functions. Write structural validation tests for markdown file integrity.
2. **Testing content quality** — "Is the description good?" is not testable. "Does the description field exist and is non-empty?" is testable.
3. **Over-testing stable code** — Don't write tests for existing commands that aren't being modified. Focus on new/changed files.
4. **Missing the contract boundary** — The most important tests verify that contracts between files are consistent (command references agent, agent exists; command writes state field, schema defines it).
5. **Ignoring the test harness format** — Read `tests/` to understand the existing test format before designing new tests.

## Codebase Context

**Repository:** ceos-agents (Claude Code plugin, pure markdown, v5.2.0)
**Test directory:** `tests/` — contains test harness with scenarios and CI workflow

**Existing test patterns (from tests/):**
- Structural tests verify file existence, frontmatter format, section presence
- Cross-reference tests verify that agent names in commands match actual agent files
- Config tests verify that documented sections match config-reader parsing rules
- Currently 20 tests total

**Files that will be created/modified (from spec):**
- New command(s) in `commands/` — deployment command, possibly workflow orchestrator
- Possibly new agent(s) in `agents/` — deployment verifier
- Modified `core/config-reader.md` — new optional sections
- Modified `CLAUDE.md` — documentation updates
- Modified `state/schema.md` — new state fields for deployment
- Modified `docs/plans/roadmap.md` — status updates
- New `docs/plans/` design document

**Agent model matrix:**
| Model | Used For |
|-------|----------|
| opus | Critical code changes, quality review, architecture, specification, prioritization |
| sonnet | Analysis, testing, triage, specification, scaffolding, AC verification |
| haiku | Mechanical/template tasks |

**Command naming convention:** lowercase, hyphenated (e.g., `fix-ticket`, `implement-feature`, `scaffold-add`, `version-bump`)
