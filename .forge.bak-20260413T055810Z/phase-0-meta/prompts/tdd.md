# Phase 5: Test-Driven Development

## Persona

You are a test engineer designing verification tests for a markdown-only plugin. Your tests use bash scripts with grep, file inspection, and structural assertions. No runtime tests — only static analysis of markdown files.

## Task Instructions

Design test cases for v6.4.4 acceptance criteria. The test harness is bash-based (`tests/harness/run-tests.sh`). Tests are scenario files in `tests/scenarios/`.

### Test Design Approach

For a markdown plugin, tests verify:
1. **Structural presence:** Required patterns exist in files (grep)
2. **Structural absence:** Forbidden patterns do not exist (grep -v / ! grep)
3. **Consistency:** Patterns match across files (diff, comparison)
4. **Completeness:** All affected files are covered (exhaustive check)

### Test Cases to Design

**Item 1: Bare Path Migration**

- **T1 (AC-2):** Verify no bare `docs/reference/trackers.md` as direct Read instruction remains in skill/core files. Pattern: grep for bare references in skills/ and core/ directories, excluding check-setup (already migrated). Should find zero matches that are direct Read instructions (as opposed to Glob patterns or path-note comments).
- **T2 (AC-1):** Verify each of the 4 affected files contains the path-note blockquote. Pattern: grep for "Path note" or "Glob" in each file.
- **T3 (AC-3):** Verify files with multiple references have "resolve once" language. Pattern: grep for "resolved in Step" or "resolved earlier" or similar reuse indicator in onboard and scaffold.
- **T4 (AC-5):** Verify the Glob resolution pattern uses all 3 layers. Pattern: grep for `.claude/plugins/**/docs/reference/trackers.md` in each file.

**Item 2: Structured error_type**

- **T5 (AC-6):** Verify `core/mcp-detection.md` Output Contract contains `error_type` field.
- **T6 (AC-7):** Verify `core/mcp-detection.md` Process section contains error classification logic with all 5 enum values.
- **T7 (AC-8, AC-9):** Verify the TLS and auth error patterns in mcp-detection match those in check-setup Step 9.
- **T8 (AC-10):** Verify `not_found` and `timeout` patterns are present in the classification logic.

**Item 3: Step 10 TLS Treatment**

- **T9 (AC-12):** Verify Step 10 contains TLS error classification with the same string patterns as Step 9.
- **T10 (AC-13):** Verify Step 10 contains curl probe logic.
- **T11 (AC-14):** Verify Step 10 contains NODE_OPTIONS hint.
- **T12 (AC-16):** Verify Step 10 error messages say "Source control" not "Issue tracker".

**Cross-Cutting**

- **T13 (AC-18):** Run existing test suite and verify check-setup-improvements.sh passes.
- **T14 (AC-17):** Verify no changes to CLAUDE.md config contract sections.

### Test File Location

Add to existing `tests/scenarios/check-setup-improvements.sh` or create new `tests/scenarios/v644-diagnostics-hardening.sh`.

### Visible vs Hidden Tests

- **Visible tests (T1-T12):** Published in test file, guide implementation
- **Hidden tests (T13-T14):** Run existing suite, verify no regression

## Success Criteria

- All 14 test cases are implementable as bash assertions
- Tests cover all 19 acceptance criteria (some tests cover multiple ACs)
- Test file follows existing scenario file conventions (see `tests/scenarios/` for examples)
- Tests can run independently and in any order

## Anti-Patterns

- Do NOT write tests that require runtime execution of the plugin
- Do NOT write tests that depend on network connectivity
- Do NOT write tests that modify files (read-only assertions only)
- Do NOT duplicate existing tests in check-setup-improvements.sh

## Codebase Context

- Test harness: `tests/harness/run-tests.sh`
- Existing scenarios: `tests/scenarios/*.sh`
- Test pattern: `pass "message"` / `fail "message"` functions
- Reference: `tests/scenarios/check-setup-improvements.sh` for style conventions
