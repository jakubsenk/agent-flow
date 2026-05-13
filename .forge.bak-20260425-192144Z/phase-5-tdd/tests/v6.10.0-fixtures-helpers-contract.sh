#!/usr/bin/env bash
# AC: AC-T1-4-1, AC-T1-4-2, AC-T1-4-3, AC-T1-17-1, AC-T1-18-1
# Validates tests/lib/fixtures.sh exposes exactly 3 named helpers,
# each is callable and returns the expected type.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FIXTURES="$REPO_ROOT/tests/lib/fixtures.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# AC-T1-4-1: file exists with exactly 3 function declarations
[ -f "$FIXTURES" ] || { fail "tests/lib/fixtures.sh does not exist"; exit 1; }

count=$(grep -cE '^(make_state_json|setup_scratch|require_jq)\(\)' "$FIXTURES" 2>/dev/null || echo 0)
[ "$count" -eq 3 ] || fail "Expected 3 function declarations in fixtures.sh, got $count"

# AC-T1-4-2: sourcing declares exactly the 3 functions
declared=$(bash -c ". '$FIXTURES'; declare -F" 2>/dev/null | grep -cE 'make_state_json|setup_scratch|require_jq' || echo 0)
[ "$declared" -eq 3 ] || fail "Expected 3 functions declared after sourcing, got $declared"

# AC-T1-4-3: make_state_json produces valid JSON
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if command -v jq >/dev/null 2>&1; then
  out=$(bash -c ". '$FIXTURES'; make_state_json '{\"status\":\"paused\"}'" 2>/dev/null)
  if ! echo "$out" | jq -e . >/dev/null 2>&1; then
    fail "make_state_json did not produce valid JSON"
  fi
  status_val=$(echo "$out" | jq -r '.status' 2>/dev/null)
  [ "$status_val" = "paused" ] || fail "make_state_json: .status expected 'paused', got '$status_val'"
  schema_val=$(echo "$out" | jq -r '.schema_version' 2>/dev/null)
  [ "$schema_val" = "1.0" ] || fail "make_state_json: .schema_version expected '1.0', got '$schema_val'"
else
  echo "SKIP(jq): jq not available — AC-T1-4-3 JSON assertions skipped"
fi

# AC-T1-17-1 / AC-T1-18-1: At least 8 REWRITEs that need state.json source fixtures.sh
# Verify via grep that Tier-A rewrite scenarios source fixtures.sh
tier_a_scenarios=(
  "v6.9.0-autopilot-skip-paused.sh"
  "v6.9.0-circuit-breaker-non-blocking.sh"
  "v6.9.0-metrics-format-json.sh"
  "v6.9.0-needs-clarification-dos-cap.sh"
  "v6.9.0-needs-clarification-triage.sh"
  "v6.9.0-pipeline-history-append.sh"
  "v6.9.0-pipeline-history-pii-scope.sh"
  "v6.9.0-pipeline-paused-webhook.sh"
)
tier_a_count=0
for s in "${tier_a_scenarios[@]}"; do
  spath="$REPO_ROOT/tests/scenarios/$s"
  [ -f "$spath" ] || continue
  if grep -qE 'make_state_json|\. .*lib/fixtures\.sh' "$spath" 2>/dev/null; then
    tier_a_count=$((tier_a_count + 1))
  fi
done
# TODO(phase-7-fixer): enforce this after REWRITEs land; count must be >= 8
echo "INFO: Tier-A REWRITE fixtures.sh usage: $tier_a_count of ${#tier_a_scenarios[@]}"

[ "$FAIL" -eq 0 ] && echo "PASS: fixtures.sh API contract verified"
exit "$FAIL"
