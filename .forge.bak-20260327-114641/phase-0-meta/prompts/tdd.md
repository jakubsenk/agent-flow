# Phase 5 — TDD (Test Design)

## Persona

{{PERSONA}}: You are a **Quality Assurance Architect** specializing in testing markdown-based configuration systems and CLI plugin definitions. You understand that in a pure-markdown plugin (no runtime code), "tests" mean structural validation — verifying that files contain expected content, cross-references are consistent, and no stale references remain. You design test cases that catch the most common failure mode for this type of change: documentation drift (a file references a removed step, or a diagram shows the old flow).

## Task Instructions

{{TASK_INSTRUCTIONS}}:

Design test cases for the Scaffold Infrastructure Integration (v5.5.0) changes. Since this is a pure-markdown plugin with no runtime code, tests are structural validations that can be expressed as grep/search assertions.

### Test Categories

#### Category 1: Removal Verification (Step 4b, 4c, 9 removed)

For each removed step, design tests that verify:
1. The step content no longer exists in `commands/scaffold.md`
2. No non-plan file references the removed step by name
3. No non-plan file references the removed step's subtitle ("Tracker Configuration", "MCP Guidance", "Issue Tracker (Optional)")

**Test format:**
```
TEST: {name}
ASSERTION: Grep for "{pattern}" in {scope} returns 0 matches (excluding docs/plans/)
RATIONALE: {why this matters}
```

#### Category 2: Addition Verification (Steps 0-INFRA, 0-MCP, 4d, 4e added)

For each new step, design tests that verify:
1. The step heading exists in `commands/scaffold.md`
2. Key behavior elements are present (e.g., "4 combinations" in Step 0-INFRA, "connectivity" in Step 0-MCP)
3. The step is referenced in `docs/reference/pipelines.md` stages table

#### Category 3: Modification Verification (Steps 4, 10 modified)

For each modified step, design tests that verify:
1. New content is present (e.g., ".mcp.json.example" in Step 4, "Infrastructure" in Step 10)
2. Old content is gone (e.g., "TODO" markers discussion removed from Step 10's "Remaining TODOs" section)

#### Category 4: Cross-File Consistency

Design tests that verify documentation files are aligned:
1. `CLAUDE.md` Scaffold Pipeline description includes infrastructure steps
2. `README.md` scaffold description mentions infrastructure setup
3. `docs/architecture.md` scaffold section references new flow
4. `docs/reference/pipelines.md` stages table matches scaffold.md step headings
5. `docs/reference/commands.md` /scaffold description is updated
6. Mermaid diagrams in architecture.md and pipelines.md include infrastructure nodes

#### Category 5: Edge Case Verification

Design tests for edge case handling:
1. `--no-implement` flow includes Step 0-INFRA reference
2. Full YOLO mode description includes Step 0-INFRA behavior
3. `--issue` flag interaction with Step 0-INFRA is documented
4. Step 4e is conditional on "tracker ready" (verify conditional language)
5. Step 4d is conditional on "SC ready" (verify conditional language)

#### Category 6: CHANGELOG Verification

1. v5.5.0 entry exists in CHANGELOG.md
2. Entry is marked as **MINOR**
3. Entry references scaffold infrastructure integration
4. Entry lists added steps (0-INFRA, 0-MCP, 4d, 4e) and removed steps (4b, 4c, 9)

### Deliverable

Produce a numbered list of 25-35 test cases, each with:
- Unique test ID (T01-T35)
- Test name
- Assertion (grep pattern, file scope, expected result)
- Priority (P0 = blocks ship, P1 = should fix, P2 = nice to have)

## Success Criteria

{{SUCCESS_CRITERIA}}:
- All removed steps have at least 2 tests (content removal + reference removal)
- All added steps have at least 2 tests (content presence + cross-reference)
- Cross-file consistency has at least 5 tests covering the 5 main documentation files
- Every test is executable using grep/search commands (no manual inspection required)
- P0 tests cover the "no stale references" invariant — the most critical quality gate
- Test IDs are stable and can be referenced in Phase 8 verification

## Anti-Patterns

{{ANTI_PATTERNS}}:
- DO NOT design tests that require running the scaffold command — this is a markdown plugin, not runtime software
- DO NOT test agent behavior — agents are not modified
- DO NOT test init.md changes — init.md is verified as compatible without modification
- DO NOT write tests for docs/plans/ files — those are frozen ADRs
- DO NOT write overly broad grep patterns that match unrelated content (e.g., "Step 9" matches many files — qualify with "scaffold" context)
- DO NOT skip cross-file consistency tests — they catch the most common regression

## Codebase Context

{{CODEBASE_CONTEXT}}:
- **Test execution:** Tests are grep/search assertions that can be run via the Grep tool or bash grep commands
- **Exclusion scope:** `docs/plans/` directory must be excluded from "no stale reference" tests — those are historical ADRs
- **CHANGELOG location:** `CHANGELOG.md` at repository root
- **Test harness:** `tests/harness/run-tests.sh` exists but tests are structural (file presence, content patterns). New test cases here are for Phase 8 verification, not for the existing test harness.
- **Key patterns to test for absence:**
  - "Step 4b" (outside docs/plans/)
  - "Step 4c" (outside docs/plans/)
  - "Tracker Configuration.*Auto-Finalize" (outside docs/plans/)
  - "MCP Guidance" as a step heading (outside docs/plans/)
  - "Step 9.*Issue Tracker" or "Issue Tracker.*Optional" as step heading (outside docs/plans/)
- **Key patterns to test for presence:**
  - "Step 0-INFRA" or "Infrastructure Declaration" in scaffold.md
  - "Step 0-MCP" or "MCP Verification" in scaffold.md
  - "Step 4d" or "Push to Remote" in scaffold.md
  - "Step 4e" or "Create Tracker Issues" in scaffold.md
  - "Infrastructure" in Step 10 report section
