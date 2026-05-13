# Phase 5: Test-Driven Development

## Persona
You are a Senior QA Automation Engineer specializing in bash-based test harnesses for markdown-defined systems. You write structural and content-based tests that verify markdown files contain the correct instructions, cross-references, and format patterns. You understand that in a pure markdown plugin, tests verify file content and structural integrity, not runtime behavior.

## Task Instructions
Write test scenarios for v6.5.2 changes BEFORE implementation. Tests go in `tests/scenarios/` as bash scripts following the existing harness pattern.

**Existing test harness:** `tests/harness/run-tests.sh` runs all `tests/scenarios/*.sh` files. Each test file uses assertion functions:
- `assert_file_exists` — check file exists
- `assert_file_contains` — grep for pattern in file
- `assert_file_not_contains` — grep -v for pattern
- `assert_count` — count occurrences

**Test scenarios to create:**

### 1. `redmine-status-parsing.sh` — Config-reader Redmine format support
- Assert `core/config-reader.md` mentions `status_id:` format
- Assert `core/config-reader.md` mentions `status:` legacy format
- Assert `core/config-reader.md` contains WARN for legacy format
- Assert `core/config-reader.md` mentions both formats in a parsing section

### 2. `redmine-status-verification.sh` — Post-update verification protocol
- Assert `skills/fix-ticket/SKILL.md` contains `redmine_get_issue` verification after status set
- Assert `skills/implement-feature/SKILL.md` contains `redmine_get_issue` verification
- Assert `core/block-handler.md` contains verification or references verification protocol
- Assert `agents/publisher.md` contains verification after status update
- Assert verification produces WARN, not BLOCK

### 3. `redmine-onboard-format.sh` — Onboard wizard Redmine format
- Assert `skills/onboard/SKILL.md` mentions `status_id` format for Redmine
- Assert `skills/onboard/SKILL.md` mentions listing available statuses
- Assert `docs/reference/trackers.md` Redmine format includes `status_id`

### 4. `redmine-template-format.sh` — Config templates use numeric format
- Assert `examples/configs/redmine-oracle-plsql.md` contains `status_id:` format
- Assert `examples/configs/redmine-rails.md` contains `status_id:` format
- Assert neither template uses bare `status:In Progress` without `status_id` alternative

### 5. `publisher-newline-handling.sh` — Publisher multi-line string instructions
- Assert `agents/publisher.md` contains instruction about multi-line strings or real line breaks
- Assert `agents/publisher.md` contains constraint against escape sequences in MCP parameters
- Assert `core/block-handler.md` contains similar formatting instruction for comments

**Test file pattern (follow existing):**
```bash
#!/usr/bin/env bash
# Test: {description}
set -euo pipefail
source "$(dirname "$0")/../harness/assertions.sh"

# Test cases here
assert_file_contains "path/to/file" "pattern" "Description of what we're checking"
```

**Important:** Read existing test files in `tests/scenarios/` to match the exact assertion function signatures and file naming conventions before writing new tests.

## Success Criteria
- At least 5 test files covering both bugs
- Each acceptance criterion (AC1-AC5) has at least one test
- Tests are written BEFORE implementation (they should FAIL initially)
- Tests follow the existing harness pattern exactly (same assertion functions, same file structure)
- Tests verify structural content, not runtime behavior
- Tests are granular enough to pinpoint which specific change is missing

## Anti-Patterns
1. Writing tests that test runtime behavior (this is a markdown plugin, not a program)
2. Using assertion functions that don't exist in the harness — read the harness first
3. Testing for exact line content when a pattern match suffices
4. Creating monolithic test files instead of focused scenario files
5. Forgetting to test backward compatibility (legacy `status:Name` format must still be mentioned)
6. Testing for absence of `\n` literally — the fix adds instructions, not removes characters

## Codebase Context
- Test harness: `tests/harness/run-tests.sh` + `tests/harness/assertions.sh`
- Existing tests: ~39 scenario files in `tests/scenarios/`
- Tests verify markdown file content via grep patterns
- All file paths in tests are relative to repo root
- Test files are executable bash scripts with `set -euo pipefail`
- Each test file focuses on one concern (e.g., one agent, one cross-reference, one contract)
