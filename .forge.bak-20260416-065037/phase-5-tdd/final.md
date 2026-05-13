# Phase 5: TDD — Test Suite Summary
# ceos-agents v6.7.1

## Test Directory

All TDD tests live in:
- `.forge/phase-5-tdd/tests/plugin-version-tracking/` — 7 AC test files (ac1–ac7)
- `.forge/phase-5-tdd/tests-hidden/` — 1 regression guard

## Test Files

### AC Tests (`tests/plugin-version-tracking/`)

| File | Items | AC IDs | Description |
|------|-------|--------|-------------|
| `ac1-state-manager-graceful-degradation.sh` | Item 6 | AC-32 to AC-35 | state-manager Step 2a null fallback for missing/malformed plugin.json |
| `ac2-config-reader-decomposition-key.sh` | Item 1 | AC-1 to AC-3 | config-reader has `decomposition.create_tracker_subtasks` with default `enabled` |
| `ac3-fix-bugs-config-validity-gate.sh` | Item 2 | AC-4 to AC-9 | fix-bugs SKILL.md has Step 0b Config Validity Gate in correct position |
| `ac4-state-schema-retry-limits.sh` | Item 3 | AC-10 to AC-15 | state/schema.md has `spec_iterations` and `root_cause_iterations` fields |
| `ac5-implement-feature-code-analyst.sh` | Item 4 | AC-16 to AC-25 | implement-feature has unconditional Step 3a code-analyst before architect |
| `ac6-sanitizer-marker-escaping.sh` | Item 5 | AC-26 to AC-31 | external-input-sanitizer Step 1b escapes nested markers with `[ESCAPED: ...]` |
| `ac7-never-constraint-10-agents.sh` | Item 7 | AC-36 to AC-42 | All 10 agents have NEVER external-input constraint; test file updated to 10-agent array |

### Regression Tests (`tests-hidden/`)

| File | Description |
|------|-------------|
| `regression-no-content-loss.sh` | Structural markers survive in all 10 modified files (5 agents, 2 skills, 2 core, 1 state schema) |

## Coverage

| Spec Item | AC Count | Test File | Status |
|-----------|----------|-----------|--------|
| Item 1 — config-reader missing key | 3 (AC-1–3) | ac2-config-reader-decomposition-key.sh | Written |
| Item 2 — Config Validity Gate in fix-bugs | 6 (AC-4–9) | ac3-fix-bugs-config-validity-gate.sh | Written |
| Item 3 — State schema retry limit fields | 6 (AC-10–15) | ac4-state-schema-retry-limits.sh | Written |
| Item 4 — Code-analyst before architect | 10 (AC-16–25) | ac5-implement-feature-code-analyst.sh | Written |
| Item 5 — Sanitizer marker escaping | 6 (AC-26–31) | ac6-sanitizer-marker-escaping.sh | Written |
| Item 6 — State-manager graceful degradation | 4 (AC-32–35) | ac1-state-manager-graceful-degradation.sh | Written |
| Item 7 — NEVER constraint 10 agents | 7 (AC-36–42) | ac7-never-constraint-10-agents.sh | Written |
| Regression — no content loss | — | regression-no-content-loss.sh | Written |

**Total: 44 AC checks across 7 AC tests + 1 regression guard**

## Test Patterns

- All tests use `set -euo pipefail` and a `fail()` helper that sets `FAIL=1`
- `REPO_ROOT` is resolved from `$(dirname "$0")/../../..` (3 levels up from the test file)
- Tests are read-only, deterministic, complete in under 1 second
- Each test prints `PASS: <description>` on success and exits 0, or one or more `FAIL: <message>` lines and exits 1
- Structural position checks (line ordering) use `grep -n` + `cut -d: -f1` + arithmetic comparison

## Pre-Implementation State

All 7 AC test files are expected to **fail** on the current v6.7.0 codebase (tests are written before the implementation). The regression test is expected to **pass** on the current codebase (verifying no pre-existing content loss).
