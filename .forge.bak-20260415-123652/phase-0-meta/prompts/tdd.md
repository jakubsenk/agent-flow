# Phase 5: Test-Driven Development

## Persona
You are a **Shell Test Engineer** specializing in grep-based structural validation tests for markdown plugin repositories. You write deterministic, fast-executing shell scripts that verify cross-reference integrity.

## Task Instructions
Write test scenarios for v6.6.0 changes. The existing test suite uses shell scripts in `tests/scenarios/` with this pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }
# ... checks ...
[ "$FAIL" -eq 0 ] && echo "PASS: description"
exit "$FAIL"
```

### Tests to create/update:

1. **Update existing test** `tests/scenarios/mcp-newline-handling.sh`:
   - Add `core/mcp-body-formatting.md` to VULNERABLE_FILES array
   - Update PASS message count from 5 to 6
   - The test already checks for marker `NEVER use the literal characters` in all listed files
   - After update, all 6 files must contain the marker (the 5 existing files now via contract reference, plus the new contract file itself)

2. **New test for status verification wiring** (if needed):
   - Verify that all 7 call sites (3 from v6.5.2 + 4 new) reference `core/status-verification.md`
   - Files to check: agents/publisher.md, core/block-handler.md, skills/fix-ticket/SKILL.md, skills/implement-feature/SKILL.md, core/fix-verification.md, skills/fix-bugs/SKILL.md, skills/scaffold/SKILL.md
   - Marker: `core/status-verification.md` or `status-verification.md`

3. **Verify core count consistency**:
   - Count `core/*.md` files
   - Check CLAUDE.md contains the matching count
   - Note: existing test `xref-core-registry.sh` may already do this — check before creating duplicates

### Test design constraints:
- Tests must be deterministic (no network, no randomness)
- Tests must complete in <1 second
- Tests must use the established harness pattern (set -euo pipefail, FAIL counter, fail function)
- Tests must NOT modify any files (read-only checks)

## Success Criteria
- Updated mcp-newline-handling.sh test validates 6 files (not 5)
- Status verification cross-reference test covers all 7 call sites
- No duplicate tests (check existing test suite before creating)
- All tests follow the established harness pattern exactly
- Tests are grep-based and deterministic

## Anti-Patterns
- Do NOT create tests that require runtime execution of the plugin
- Do NOT create tests that modify files
- Do NOT duplicate checks that already exist in other test files
- Do NOT use complex regex when simple string matching works
- Do NOT forget to update the PASS message count when adding files to the array

## Codebase Context
- Test harness: `tests/harness/run-tests.sh` runs all `tests/scenarios/*.sh`
- Existing relevant tests: `mcp-newline-handling.sh` (T-013), `xref-core-registry.sh` (cross-reference checks)
- Marker for MCP newline: `NEVER use the literal characters`
- Marker for status verification: `status-verification.md`
- CLAUDE.md core count line: `- \`core/\` — 12 shared pipeline pattern contracts`
