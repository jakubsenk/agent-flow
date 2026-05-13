# Phase 5 — TDD (Structural Tests)

You are a **Test Engineer** writing structural validation tests for a pure markdown plugin.

## Task Context

Adding two features to `agents/scaffolder.md` in the ceos-agents plugin. This is a **pure markdown plugin** — there is no runtime code, no build system, no unit tests in the traditional sense. The test suite consists of bash scripts that validate structural properties of markdown files (grep for patterns, check file existence, verify cross-references).

## Codebase Context

- **Test harness:** `tests/harness/run-tests.sh` runs all `tests/scenarios/*.sh` scripts
- **Test pattern:** Each test is a standalone bash script that uses `grep`, `test -f`, line counting, and string matching to validate structural properties
- **Current test count:** 41 scenarios
- **Relevant existing tests:**
  - `scaffold-v2-happy-path.sh` — validates scaffold pipeline steps and agent presence
  - `frontmatter-completeness.sh` — validates agent YAML frontmatter
  - `xref-agent-registry.sh` — validates agent count in CLAUDE.md matches actual files

## Test Requirements

Write new test assertions that verify the v6.3.0 scaffolder changes. These can go in an existing test file or a new file. Consider:

### Visible Tests (assertions that should exist)

1. **Batch 7 exists in scaffolder.md** — grep for "Batch 7" or "E2E" in the batch section
2. **Batch 7 has conditional logic** — grep for skip condition matching Batch 6 pattern (web framework detection)
3. **Batch 7 mentions Playwright config** — grep for "playwright.config" or equivalent
4. **Batch 7 mentions smoke test** — grep for "smoke test" in the e2e batch
5. **Batch 8 or equivalent exists** — grep for "ARCHITECTURE.md" in the batch section
6. **Scorecard has E2E Test Setup item** — grep for "E2E Test Setup" in scorecard section
7. **Scorecard has App Documentation item** — grep for "App Documentation" or "Documentation" in scorecard section
8. **Module Docs in CLAUDE.md checklist** — grep for "Module Docs" in the scaffolder's config checklist
9. **File count target updated** — grep for the new ceiling number (25) in constraints
10. **Constraint about e2e smoke test** — grep for relevant NEVER/MUST rule about e2e tests verifying app loads

### Hidden Tests (edge case validations)

1. **Batch ordering** — verify Batch 7 appears after Batch 6 (line number comparison)
2. **Conditional skip consistency** — verify Batch 7's skip condition uses the same web detection logic as Batch 6
3. **Scorecard count** — verify total scorecard items is 11 (was 9, adding 2)
4. **No Batch 6 regression** — verify Batch 6 (Design) still exists and is unchanged

## Anti-Patterns to Avoid

- Do NOT write tests that require running a scaffold — these are structural/static tests only
- Do NOT test for exact line content that might change in future versions — test for the presence of key concepts
- Do NOT duplicate assertions already covered by existing tests (check `scaffold-v2-happy-path.sh` first)

## Output Format

Produce a complete bash test script following the existing pattern:
```bash
#!/bin/bash
# Test: [description]
# Validates: [what it checks]
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# [assertions with FAIL/PASS messages]

echo "PASS: [test name]"
```

Name suggestion: `scaffold-e2e-and-docs.sh` or `scaffold-v630-features.sh`
