# Phase 5: Test Design (TDD)

## Objective
Define test criteria: what should the test harness validate after changes? What structural properties must hold?

## Existing Test Infrastructure
- 55 test scenarios in `tests/scenarios/`
- Test harness: `tests/harness/run-tests.sh`
- Tests are bash scripts that validate structural properties of markdown files
- Tests check: frontmatter, section order, cross-references, consistency, state schema, etc.

## Test Categories

### Existing Tests That Must Still Pass
ALL 55 existing test scenarios must continue to pass after changes. This is the primary backward compatibility gate.

Key existing tests to watch:
- `frontmatter-completeness.sh` — all agents have required frontmatter fields
- `model-assignment.sh` — correct model per agent
- `pipeline-agent-dispatch-models.sh` — agent dispatch references in skills match agent definitions
- `pipeline-consistency.sh` — cross-pipeline consistency checks
- `pipeline-feature-agents.sh` — feature pipeline agent references
- `read-only-agents.sh` — read-only agents never mention code modification
- `section-order.sh` — Goal -> Expertise -> Process -> Constraints order preserved
- `xref-agent-registry.sh` — all agents referenced in skills exist in agents/
- `xref-core-registry.sh` — all core contracts referenced in skills exist in core/

### New Test Criteria (if changes warrant new tests)
Based on the spec from Phase 4, determine if new test scenarios are needed:

1. **Mode awareness test** — if agents get mode-specific content, verify the content is structurally sound
2. **Cross-mode consistency test** — if shared agents are modified, verify they work for all pipeline modes
3. **State schema field test** — if schema changes, verify schema doc matches actual field references in skills

## Test Execution Plan
1. Run full test suite BEFORE any changes (baseline)
2. After each major category of changes, run affected tests
3. Run full test suite AFTER all changes (verification)

## Output Format
```
## Test Plan

### Baseline
- Run: `./tests/harness/run-tests.sh`
- Expected: ALL PASS (current state)

### New Tests (if any)
- Test name: {name}
- File: tests/scenarios/{name}.sh
- What it validates: {description}
- Script: {bash script content}

### Verification
- Run: `./tests/harness/run-tests.sh`
- Expected: ALL PASS (including any new tests)
- Watch for: {specific tests most likely to be affected by changes}
```
