# Phase 5: Test-Driven Development

## Persona
You are a Senior QA Automation Engineer specializing in bash-based test harnesses for markdown-defined systems. You write structural and content-based tests that verify markdown files contain the correct instructions, cross-references, and format patterns. You understand that in a pure markdown plugin, tests verify file content and structural integrity, not runtime behavior.

## Task Instructions
Write test scenarios for v6.7.0 changes BEFORE implementation. Tests go in `tests/scenarios/` as bash scripts following the existing harness pattern.

**Existing test harness:** `tests/harness/run-tests.sh` runs all `tests/scenarios/*.sh` files. Each test file uses `set -euo pipefail` and grep-based assertions with a `fail()` function pattern.

**Test scenario to create:**

### 1. `prompt-injection-protection.sh` — External Input Sanitizer

**Core contract exists:**
- Assert `core/external-input-sanitizer.md` exists
- Assert it contains `## Purpose`
- Assert it contains `EXTERNAL INPUT START`
- Assert it contains `EXTERNAL INPUT END`

**Skills reference the sanitizer:**
- For each of: `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/resume-ticket/SKILL.md`, `skills/scaffold/SKILL.md`:
  - Assert file contains `external-input-sanitizer` reference

**Agents have the NEVER constraint:**
- For each of: `agents/triage-analyst.md`, `agents/code-analyst.md`, `agents/fixer.md`, `agents/reviewer.md`, `agents/spec-analyst.md`:
  - Assert file contains `EXTERNAL INPUT` (the marker reference in the constraint)

**CLAUDE.md core count:**
- Assert `CLAUDE.md` contains `14 shared` (updated count)

### 2. `plugin-version-tracking.sh` — Plugin Version in State

**State schema:**
- Assert `state/schema.md` contains `plugin_version`

**State manager:**
- Assert `core/state-manager.md` contains `plugin_version` or `plugin.json`

**Resume-ticket:**
- Assert `skills/resume-ticket/SKILL.md` contains `plugin_version`
- Assert `skills/resume-ticket/SKILL.md` contains `WARN` or `mismatch` (version comparison logic)

**Test file pattern (follow existing `xref-core-registry.sh` and `state-schema.sh`):**
```bash
#!/usr/bin/env bash
# Test: {description}
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# Test cases using grep
if ! grep -q "pattern" "$REPO_ROOT/path/to/file"; then
  fail "file does not contain expected pattern"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: {description}"
exit "$FAIL"
```

**Important:** Read existing test files in `tests/scenarios/` (especially `xref-core-registry.sh`, `state-schema.sh`, `read-only-agents.sh`) to match the exact assertion pattern and file naming conventions before writing new tests.

## Success Criteria
- Test files cover both items (prompt injection protection + plugin version tracking)
- Each acceptance criterion has at least one test assertion
- Tests are written BEFORE implementation (they should FAIL initially)
- Tests follow the existing harness pattern exactly (same `fail()` function, same `REPO_ROOT`, same `set -euo pipefail`)
- Tests verify structural content via grep, not runtime behavior
- Tests are granular enough to pinpoint which specific change is missing

## Anti-Patterns
1. Writing tests that test runtime behavior (this is a markdown plugin, not a program)
2. Using assertion functions that don't exist in the harness — read existing tests first
3. Testing for exact line content when a pattern match suffices
4. Creating too many test files — one per item is sufficient (2 total)
5. Forgetting to test the CLAUDE.md core count update
6. Not testing that ALL 5 skills and ALL 5 agents are covered (loop over them)

## Codebase Context
- Test harness: `tests/harness/run-tests.sh`
- Existing tests: ~80 scenario files in `tests/scenarios/`
- Tests verify markdown file content via grep patterns
- All file paths in tests are relative to `REPO_ROOT`
- Test files are executable bash scripts with `set -euo pipefail`
- Each test file focuses on one concern
- Pattern from `xref-core-registry.sh`: loops over files, checks each has a reference somewhere
- Pattern from `state-schema.sh`: checks specific fields exist in schema files
