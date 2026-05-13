#!/usr/bin/env bash
# AC: AC-T1-1-1, AC-T1-1-2, AC-T1-12-1 (hidden — RETIRE scenarios produce exit 77)
# Verifies that all 4 RETIRE scenarios produce exit code 77 (SKIP).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

RETIRE_SCENARIOS=(
  "tests/scenarios/v6.9.0-changelog-completeness.sh"
  "tests/scenarios/v6.9.0-plugin-repo-url-invalid-tld.sh"
  "tests/scenarios/ac-v692-autopilot-bash-dispatch.sh"
  "tests/scenarios/v6.9.0-webhook-proto-coverage.sh"
)

# AC-T1-1-1: all 4 have exit 77 line
for scenario in "${RETIRE_SCENARIOS[@]}"; do
  full_path="$REPO_ROOT/$scenario"
  [ -f "$full_path" ] || { fail "RETIRE scenario missing: $scenario"; continue; }
  if ! grep -qE '^exit 77' "$full_path"; then
    fail "$scenario: missing 'exit 77' on its own line"
  fi
done

# AC-T1-1-2: actually produce exit 77 when run
for scenario in "${RETIRE_SCENARIOS[@]}"; do
  full_path="$REPO_ROOT/$scenario"
  [ -f "$full_path" ] || continue
  actual_exit=0
  bash "$full_path" >/dev/null 2>&1 || actual_exit=$?
  [ "$actual_exit" -eq 77 ] || fail "$scenario: expected exit 77 (SKIP), got $actual_exit"
done

echo "PASS: all 4 RETIRE scenarios produce exit 77"
exit "$FAIL"
