# Phase 5 — Test-Driven Development

You are writing test scenarios for the design awareness feature BEFORE implementation. These tests define the acceptance criteria and will be used to verify the implementation.

## Context

Read:
- `.forge/phase-4-spec/spec.md` — full specification
- `.forge/phase-4-spec/formal-criteria.md` — acceptance criteria
- `tests/scenarios/scaffold-v2-happy-path.sh` — example test format
- `tests/scenarios/scaffold-v2-input-conflicts.sh` — example validation test
- `tests/harness/run-tests.sh` — test harness

## Test Format

All tests in ceos-agents are bash scripts in `tests/scenarios/`. They validate markdown content (grep for expected strings in agent/skill files). There is no runtime execution — the plugin is pure markdown.

Pattern from existing tests:
```bash
#!/bin/bash
# Test: Description
# Validates: what this test checks
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Check file exists
if [ ! -f "$REPO_ROOT/path/to/file.md" ]; then
  echo "FAIL: Missing file"
  exit 1
fi

# Check content
if ! grep -q "expected content" "$REPO_ROOT/path/to/file.md"; then
  echo "FAIL: Missing expected content in file"
  exit 1
fi

echo "PASS: Test description"
```

## Test Scenarios to Write

### Visible Tests (test what the implementation must do)

1. **`scaffold-design-detection.sh`** — Validates that the scaffold pipeline or relevant agents contain web project detection logic
   - Check that the detection keywords/heuristics exist in the appropriate file
   - Check that detection produces a boolean-like flag (web_project / has_frontend)

2. **`scaffold-design-stack-selector.sh`** — Validates stack-selector has CSS framework awareness
   - Check that stack-selector.md mentions CSS/design framework selection
   - Check that the output format includes a design-related field

3. **`scaffold-design-spec-writer.sh`** — Validates spec-writer has conditional Design & UX section
   - Check that spec-writer.md contains "Design" or "UX" section logic
   - Check that the section is conditional (not generated for all projects)

4. **`scaffold-design-scaffolder.sh`** — Validates scaffolder generates design files for web projects
   - Check that scaffolder.md contains a design-related batch or design instructions
   - Check that the batch is conditional on web project type

5. **`scaffold-design-backward-compat.sh`** — Validates that non-web project flow is unaffected
   - Check that all design additions are conditional (grep for conditional markers)
   - Check that existing 5 batches are unchanged for non-web projects
   - Check that agent frontmatter (name, description, model, style) is preserved

### Hidden Tests (test edge cases and robustness)

6. **`scaffold-design-spec-reviewer.sh`** — Validates spec-reviewer can check the new Design & UX section
   - Check that spec-reviewer.md references the new section in its completeness checks

7. **`scaffold-design-accessibility.sh`** — Validates accessibility is part of the design awareness
   - Check that at least one agent mentions accessibility, semantic HTML, or ARIA

8. **`scaffold-design-no-aesthetic-choices.sh`** — Validates the implementation doesn't make aesthetic decisions
   - Grep for forbidden patterns: specific color values (#hex, rgb), font-family declarations with specific fonts, hardcoded spacing values
   - The agents should reference framework defaults/presets, not make choices

## Output

Write all test files to `tests/scenarios/` with the exact filenames above.

Also create a test index entry: add the new test names to `tests/README.md` if it has a test list.

Save a test plan summary to `.forge/phase-5-tdd/test-plan.md` listing all tests with their purpose and pass criteria.

### Mutation Quality Gate

After writing tests, verify that:
1. Each test would FAIL if the feature were not implemented (grep for strings that don't exist yet)
2. Each test would PASS after correct implementation
3. No test is trivially satisfied by existing content (false positive check)

List any tests that might have false positive/negative risks.
