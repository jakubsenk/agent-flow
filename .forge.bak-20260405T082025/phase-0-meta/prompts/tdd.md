# Phase 5 — TDD (Test-Driven Development)

## Persona
{{PERSONA}}: Senior QA Engineer specializing in bash test harnesses for markdown-based plugin systems. Expert in writing grep-based assertions that are semantically accurate, resilient to cosmetic changes, and fail only when the tested behavior actually breaks.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Write or update tests BEFORE implementation. For this task, only one test file is affected: `tests/scenarios/scaffolder-e2e-batch.sh`. The other two fixes (UNCLEAR handler) don't have dedicated test files — they are tested by the existing test harness structure (and could be tested manually via the pipeline).

### Test updates for `tests/scenarios/scaffolder-e2e-batch.sh`:

**Existing tests to modify (fix 3 — grep fragility):**

1. **Line 16 — Batch 7 conditional pattern:**
   Replace `grep -q "Skip this batch entirely" "$SCAFFOLDER"` with section-aware check:
   ```bash
   sed -n '/Batch 7/,/Batch 8/p' "$SCAFFOLDER" | grep -q "Skip this batch entirely" || fail "scaffolder.md Batch 7 missing conditional skip pattern"
   ```

2. **Line 45 — File count ceiling:**
   Replace `grep -q "27" "$SCAFFOLDER"` with:
   ```bash
   grep -q "up to 27" "$SCAFFOLDER" || fail "scaffolder.md constraints missing updated file count ceiling (27)"
   ```

**New tests to add (fix 2 — cross-stack detection):**

3. **Cross-stack Playwright detection — Python:**
   ```bash
   grep -q "pytest-playwright" "$SCAFFOLDER" || fail "scaffolder.md Batch 7 missing Python Playwright detection (pytest-playwright)"
   ```

4. **Cross-stack Playwright detection — Ruby:**
   ```bash
   grep -q "capybara-playwright-driver" "$SCAFFOLDER" || fail "scaffolder.md Batch 7 missing Ruby Playwright detection (capybara-playwright-driver)"
   ```

5. **Language-aware test file generation:**
   ```bash
   grep -q "test_smoke.py" "$SCAFFOLDER" || fail "scaffolder.md Batch 7 missing Python test file pattern (test_smoke.py)"
   ```

6. **Multi-ecosystem detection table:**
   ```bash
   sed -n '/Batch 7/,/Batch 8/p' "$SCAFFOLDER" | grep -q "pyproject.toml" || fail "scaffolder.md Batch 7 missing pyproject.toml detection"
   ```

### Test execution order:
1. First, update the test file with the new/modified assertions
2. Run the test — it should FAIL (red phase) because scaffolder.md hasn't been updated yet
3. After implementation, run the test again — it should PASS (green phase)

### Mutation quality gate:
- Each new assertion must fail if the corresponding text is removed from scaffolder.md
- The section-aware grep must NOT match Batch 6's "Skip this batch entirely" when Batch 7's is removed
- The "up to 27" check must NOT match if only bare "27" appears elsewhere

## Success Criteria
{{SUCCESS_CRITERIA}}:
- All modified/new test assertions are semantically tied to their target section
- No assertion matches content from a different section (the core bug being fixed)
- Test file remains under 80 lines (currently 58, adding ~6 new assertions)
- All tests pass after implementation
- Mutation: removing any single fix from scaffolder.md causes at least one test to fail

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT use line-number-based checks (`sed -n '67,76p'`) — fragile to any line shift
- Do NOT add tests for the UNCLEAR handler fixes (no test infrastructure for skill behavior)
- Do NOT create new test files — modify the existing one
- Do NOT use `grep -c` for exact count matching — fragile to additions
- Do NOT test implementation details — test observable behavior (presence of keywords in correct sections)

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Test harness: `tests/harness/run-tests.sh` runs all `tests/scenarios/*.sh`
- Test convention: `set -euo pipefail`, `FAIL=0`, `fail()` function, exit with `$FAIL`
- Current test: 58 lines, 15 assertions, all using `grep -q`
- Scaffolder sections: Batch 1-8, each with a heading like `**Batch N — Name:**`
