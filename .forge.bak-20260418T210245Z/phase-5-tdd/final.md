# Phase 5 Test Suite Review

**Verdict:** PASS (with one minor gap noted)

## Coverage
- ACs covered: 37/38 — AC-29 ("All tests pass" / run-tests.sh) has no dedicated test file; it is self-referential by nature and is implicitly satisfied when the full harness runs, but is not explicitly tagged in any `.forge/phase-5-tdd/` test header.
- EARS covered: 33/33 — README EARS table lists all 33 requirements (AUTOPILOT-R1..13, WEBHOOK-R1..8, COST-R1..12) with ≥1 test each.
- bash -n sample: 5/5 pass (ac-v68-autopilot-skill-exists.sh, ac-v68-cost-pipeline-accumulator.sh, ac-v68-webhook-payload-fields.sh, ac-v68-doc-changelog-entry.sh, ac-v68-autopilot-stale-lock-120min.sh)

## Findings

- **AC-29 uncovered**: No `ac-v68-*.sh` file carries an `AC-29` label. AC-29 is "All tests pass via run-tests.sh" — this is inherently meta/self-referential and cannot be a unit test in the same suite, but the gap should be noted.
- **Shebang + pipefail**: All 35 visible `ac-v68-*.sh` tests start with `#!/usr/bin/env bash` + `set -euo pipefail`. Compliant.
- **GNU `date -u -d`**: Not found in any test file across `tests/` or `tests-hidden/`. Portable.
- **Repo writes**: No `>` redirects targeting repo paths (skills/, agents/, docs/, core/, state/, etc.) found in `ac-v68-*.sh` tests. Tests are read-only.
- **Hidden tests**: 5 regression files present and all parse cleanly (`bash -n` OK). `regression-gate-1-decisions.sh` covers all 5 Gate-1 decisions (tokens_used, schema 1.0, no pipeline-events.md, mkdir lock, no step-skipped).
- **Test counts**: 35 visible `ac-v68-*.sh` + 5 hidden regression files. Scenario files in `tests/scenarios/` include all 20 scenario scripts listed in README.
- **README EARS table**: Claims "All 33 EARS requirements have ≥1 test" — verified by counting unique EARS identifiers: exactly 33.
