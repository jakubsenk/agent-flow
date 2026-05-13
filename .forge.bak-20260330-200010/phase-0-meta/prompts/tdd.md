# Phase 5 — TDD (Test-Driven Development)

## Context

You are defining test criteria for v5.6.1 (UX Polish) of the ceos-agents plugin. This is a pure markdown plugin with a bash-based structural test harness (`tests/harness/run-tests.sh`). There is no runtime code to unit-test — tests verify file structure, content patterns, and consistency.

## Test Strategy

Since all changes are markdown text edits, testing focuses on:
1. **Structural consistency** — files still parse correctly, sections exist
2. **Content verification** — old patterns removed, new patterns present
3. **Cross-file consistency** — `--infra` format is consistent between scaffold.md and resume-ticket.md

## Test Cases

### T1: --infra Format Updated (UXP-1)

**Verify in `commands/scaffold.md`:**
- [ ] The string `{tracker},{sc}` (old positional format description) no longer appears
- [ ] The string `tracker:{ready|later},sc:{ready|later}` (new format) appears in flag parsing section
- [ ] Error message references the new format: `--infra tracker:ready,sc:later`
- [ ] No occurrence of `--infra ready,later` as an example (old format)

### T2: Canary-Write Announcement (UXP-2)

**Verify in `core/mcp-detection.md`:**
- [ ] Input Contract includes `interactive` parameter
- [ ] Step 4 contains "Testing write access" announcement text before canary creation
- [ ] Interactive confirmation prompt exists (`Proceed? [Y/n]`)

**Verify in `commands/scaffold.md`:**
- [ ] Step 0-MCP passes `interactive` parameter when calling mcp-detection

### T3: No MCP Jargon (UXP-3)

**Verify in `core/mcp-detection.md`:**
- [ ] No occurrence of "MCP server for" or "No MCP tool matching"
- [ ] Failure messages use "Cannot connect" or "integration" language

**Verify in `commands/scaffold.md`:**
- [ ] No occurrence of "MCP server for" in display messages
- [ ] No occurrence of "MCP for {type} not available"
- [ ] Error messages include actionable next steps ("Run /ceos-agents:check-setup" or "Run /ceos-agents:init")
- [ ] Note: Technical references to "MCP" in HTML comments (<!-- -->) or internal references to core/mcp-detection.md are acceptable

### T4: Resume --infra Override (UXP-4)

**Verify in `commands/resume-ticket.md`:**
- [ ] `--infra` flag is mentioned in $ARGUMENTS parsing or input section
- [ ] Logic for comparing --infra with state.json infrastructure exists
- [ ] Display message "Infrastructure changed since last run. Using new values." is present
- [ ] Warning for non-scaffold pipelines exists
- [ ] Format matches UXP-1 (tracker:ready,sc:later)

### T5: Cross-File Consistency

- [ ] `--infra` format description in `scaffold.md` matches format description in `resume-ticket.md`
- [ ] No file introduces a new occurrence of "MCP server for" jargon

## Existing Test Harness Check

Before modifying files, run `tests/harness/run-tests.sh` to establish baseline. After modifications, run again to verify no regressions. Focus on:
- Structural tests that check scaffold.md section headings
- Tests that validate core/*.md file existence
- Tests that check resume-ticket.md structure

## Notes

- These are verification criteria, not executable test code (the plugin has no runtime)
- The test harness (`run-tests.sh`) checks structural properties — manual review covers semantic correctness
- Run the existing test suite before AND after changes to catch any regressions
