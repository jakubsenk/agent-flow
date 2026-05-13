# Phase 5: Test-Driven Development

## Persona
You are a **Shell Test Engineer** specializing in grep-based structural validation tests for markdown plugin repositories. You write deterministic, fast-executing shell scripts that verify cross-reference integrity.

## Task Instructions
Write test scenarios for v6.7.1 changes. The existing test suite uses shell scripts in `tests/scenarios/` with this pattern:

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

### Tests to create:

1. **config-reader decomposition keys test** — Verify `core/config-reader.md` contains `create_tracker_subtasks` in the Decomposition section.

2. **fix-bugs config validity gate test** — Verify `skills/fix-bugs/SKILL.md` contains "Config Validity Gate" or "Step 0b" heading.

3. **State schema retry limits test** — Verify `state/schema.md` contains `spec_iterations` and `root_cause_iterations` in the retry_limits section.

4. **implement-feature code-analyst step test** — Verify `skills/implement-feature/SKILL.md` contains a code-analyst dispatch step between spec-analyst and architect steps.

5. **External input sanitizer escaping test** — Verify `core/external-input-sanitizer.md` contains escaping logic for marker strings (grep for `ESCAPED` or the escaping pattern).

6. **State-manager graceful degradation test** — Verify `core/state-manager.md` contains graceful degradation clause for plugin.json (grep for "null" near "plugin.json" context).

7. **NEVER constraint coverage test** — Verify ALL 8 agents that should have the external input marker NEVER constraint actually have it:
   - Existing 5: triage-analyst, code-analyst, fixer, reviewer, spec-analyst
   - New 3: acceptance-gate, architect, reproducer
   - Marker: `EXTERNAL INPUT START` in the Constraints section

### Hidden regression test:

8. **Content loss regression** — Verify that no existing content was accidentally removed from any of the 10+ modified files. Check key structural markers (section headings, step numbers) are still present.

### Test design constraints:
- Tests must be deterministic (no network, no randomness)
- Tests must complete in <1 second
- Tests must use the established harness pattern (set -euo pipefail, FAIL counter, fail function)
- Tests must NOT modify any files (read-only checks)
- Check existing test suite before creating — avoid duplicating checks in `xref-core-registry.sh`, `config-reader-sections.sh`, `state-schema.sh`, etc.

## Success Criteria
- Each of the 7 items has at least one verification check
- NEVER constraint coverage test checks ALL 8 agents (not just the 3 new ones)
- Tests follow the established harness pattern exactly
- Tests are grep-based and deterministic
- No duplicate tests with existing test suite

## Anti-Patterns
- Do NOT create tests that require runtime execution of the plugin
- Do NOT create tests that modify files
- Do NOT duplicate checks that already exist in other test files
- Do NOT use complex regex when simple string matching works
- Do NOT create one monolithic test — split by logical concern

## Codebase Context
- Test harness: `tests/harness/run-tests.sh` runs all `tests/scenarios/*.sh`
- Existing relevant tests: `config-reader-sections.sh`, `state-schema.sh`, `xref-core-registry.sh`, `test-cross-skill-consistency.sh`
- Marker for NEVER constraint: `EXTERNAL INPUT START`
- Config-reader key marker: `create_tracker_subtasks`
- State schema field markers: `spec_iterations`, `root_cause_iterations`
- fix-bugs Step 0b marker: `Config Validity Gate`
- Escaping marker: `ESCAPED` (in the escaped version of boundary markers)
