# T19-T20 Test Results — v6.8.0 Phase 7

## Overall Result: FAIL (harness exit 1)

- **Total tests**: 140 (was 101 before T19 mirror)
- **Passed**: 99
- **Failed**: 41
- **Skipped**: 0

---

## T19 Mirror Summary

Tests copied to `tests/scenarios/`:
- 35 × `ac-v68-*.sh` (from `.forge/phase-5-tdd/tests/`)
- 4 × `regression-*.sh` (from `.forge/phase-5-tdd/tests-hidden/`; `regression-no-content-loss.sh` already existed)
- **39 files mirrored total** (no existing files clobbered)

Category breakdown:
| Category | Count |
|---|---|
| autopilot (ac-v68-autopilot-*) | 14 |
| cost (ac-v68-cost-*) | 9 |
| doc (ac-v68-doc-*) | 5 |
| webhook (ac-v68-webhook-*) | 7 |
| regression (hidden) | 4 |
| **Total mirrored** | **39** |

---

## Failure Analysis

### Category 1: Test Path Bug — ac-v68-* tests (32 failures, plus 4 hidden regression false-positives)

**Root cause**: All 35 `ac-v68-*.sh` tests and 4 of the 5 hidden regression tests use:
```
cd "$(dirname "$0")/../../.."
```
This navigates 3 levels up from `tests/scenarios/`, landing at `/c` instead of the repo root (`/c/gitea_ceos-agents`). The tests were authored assuming they would live at `.forge/phase-5-tdd/tests/` (which is 3 levels from repo root), but they were mirrored into `tests/scenarios/` which is only 2 levels from root.

**Classification**: **Test bug (structural — wrong path depth)**

**3 of the 4 hidden regression tests** (`regression-existing-events-preserved`, `regression-gate-1-decisions`, `regression-skill-count-29`) PASS despite the path bug because their assertions are either negative (checking files don't exist, which is vacuously true) or fall through due to bash `[ ]` integer expression errors with `set -e`. These are **false positives**.

Failing tests in this category:
- All 14 `ac-v68-autopilot-*` tests
- 8 of 9 `ac-v68-cost-*` tests (1 passes via negative assertion)
- All 5 `ac-v68-doc-*` tests
- 5 of 7 `ac-v68-webhook-*` tests (2 pass via negative assertion)
- `regression-no-breaking-config-changes`

**Recommended fix (NOT done per T19/T20 constraints)**: Change `../../..` to `../..` in all 35 ac-v68 and 4 hidden regression test files, OR move them into a subdirectory `tests/scenarios/v68/` and update the harness to recurse.

---

### Category 2: Implementation Drift (7 real failures)

These tests find real gaps in the Phase 7 implementation:

| Test | Failure | Classification |
|---|---|---|
| `ac-v68-autopilot-skill-exists` (path bug) | `skills/autopilot/SKILL.md` missing `argument-hint: "[--dry-run]"` frontmatter key | Implementation drift |
| `autopilot-dry-run` | `skills/autopilot/SKILL.md` missing `[DRY RUN]` output marker | Implementation drift |
| `cost-summary-truncation` | `state/schema.md` missing 20-row limit + truncation notice documentation | Implementation drift |
| `cost-usage-null-defensive` | `core/state-manager.md` defensive-null wording incorrect (documents retry/block instead of default 0) | Implementation drift |
| `metrics-dual-mode` | `skills/metrics/SKILL.md` missing `Data source: measured=...` footer + uses combined grand total instead of separate line items | Implementation drift |
| `skills-directory-structure` | Test expects 28 skills dirs, finds 29 (autopilot/ now exists) — test not updated for v6.8.0 | **Spec-drift (test outdated)** |
| `sprint-counts` | Test expects 28 skills, finds 29; CLAUDE.md now says 29 — test hardcoded to 28+sprint-plan+create-backlog | **Spec-drift (test outdated)** |
| `webhook-no-step-skipped` | `core/post-publish-hook.md` contains `step-skipped` event (must be absent per WEBHOOK-R7) | Implementation drift |
| `ac2-fixbugs-contributor-note` | `skills/fix-bugs/SKILL.md` has 30 occurrences of "Follow atomic write protocol" instead of expected 14 | Spec-drift (count hardcoded) |

---

## Per-Category Breakdown

| Category | Tests | Pass | Fail |
|---|---|---|---|
| ac-v68-autopilot | 14 | 0 | 14 (path bug) |
| ac-v68-cost | 9 | 1 | 8 (path bug) |
| ac-v68-doc | 5 | 0 | 5 (path bug) |
| ac-v68-webhook | 7 | 2 | 5 (path bug) |
| regression (hidden) | 4 | 3* | 1 |
| autopilot (older tests) | 10 | 9 | 1 |
| cost (older tests) | 6 | 4 | 2 |
| metrics | 1 | 0 | 1 |
| webhooks (older) | 3 | 2 | 1 |
| skills/sprint structure | 2 | 0 | 2 |
| all other | 79 | 78 | 1 |
| **TOTAL** | **140** | **99** | **41** |

*3 hidden regression tests PASS but are false positives due to path bug — see Category 1 above.

---

## Recommendations

### Priority 1 — Fix test path bug (blocks 32+ tests)
All `ac-v68-*.sh` and the 4 new hidden regression tests need `../../..` changed to `../..`. This is a one-line fix per file (×39 files). These are spec tests that should be PASSING after Phase 7 implementation, so the path bug is masking whether the implementation is correct.

**Verdict**: Test bug, not implementation drift.

### Priority 2 — Fix implementation gaps (7 tests, real gaps)
1. **`webhook-no-step-skipped`**: Remove `step-skipped` from `core/post-publish-hook.md` — Gate 1 explicitly rejected this event
2. **`autopilot-dry-run`**: Add `[DRY RUN]` output marker to `skills/autopilot/SKILL.md`
3. **`cost-summary-truncation`**: Document 20-row limit and truncation notice in `state/schema.md`
4. **`cost-usage-null-defensive`**: Fix `core/state-manager.md` wording to say "default to 0" not "retry/block"
5. **`metrics-dual-mode`**: Add `Data source: measured=...` footer and split cumulative total into separate line items in `skills/metrics/SKILL.md`

### Priority 3 — Update stale test hardcodes (2 tests, spec-drift)
- `skills-directory-structure`: Update expected count from 28 to 29
- `sprint-counts`: Update expected count from 28 to 29
- `ac2-fixbugs-contributor-note`: Update expected "Follow atomic write protocol" count from 14 to 30
