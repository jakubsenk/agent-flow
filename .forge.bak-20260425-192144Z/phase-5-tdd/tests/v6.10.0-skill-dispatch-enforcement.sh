#!/usr/bin/env bash
# AC: AC-T2-7-1, AC-T2-7-2
# Layer 4 functional test: validates dispatch enforcement end-to-end
# using fixtures.sh helpers and synthetic state.json.
set -uo pipefail

. "$(dirname "$0")/../lib/fixtures.sh"

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
HOOK="$REPO_ROOT/hooks/validate-dispatch.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# AC-T2-7-1: scenario sources fixtures.sh (structural check — implicit in this file)
# And validator exists
[ -f "$HOOK" ] || { fail "hooks/validate-dispatch.sh not found"; exit 1; }

require_jq
setup_scratch

if [ "${HAVE_JQ:-0}" = "1" ]; then
  # Positive case: all stages dispatched
  STATE=$(make_state_json '{
    "triage": {"dispatched_at": "2026-04-23T12:00:00Z"},
    "code_analysis": {"dispatched_at": "2026-04-23T12:01:00Z"},
    "fixer_reviewer": {"dispatched_at": "2026-04-23T12:02:00Z"},
    "test": {"dispatched_at": "2026-04-23T12:03:00Z"},
    "publisher": {"dispatched_at": "2026-04-23T12:04:00Z"}
  }')
  echo "$STATE" > "$SCRATCH/state.json"
  LOG="$SCRATCH/audit-positive.log"

  CEOS_STATE_JSON="$SCRATCH/state.json" CEOS_AUDIT_LOG="$LOG" bash "$HOOK" >/dev/null 2>&1 \
    || fail "Hook must exit 0 (positive case)"
  ok_count=$(grep -c 'OK' "$LOG" 2>/dev/null || echo 0)
  [ "$ok_count" -ge 5 ] || fail "Expected >= 5 OK audit lines, got $ok_count"

  # Negative case: stages without dispatched_at → MISSING verdict
  STATE2=$(make_state_json '{"triage": {"dispatched_at": "2026-04-23T12:00:00Z"}}')
  echo "$STATE2" > "$SCRATCH/state_sparse.json"
  LOG2="$SCRATCH/audit-sparse.log"

  CEOS_STATE_JSON="$SCRATCH/state_sparse.json" CEOS_AUDIT_LOG="$LOG2" bash "$HOOK" >/dev/null 2>&1 \
    || fail "Hook must exit 0 even with missing dispatched_at (negative case)"
  missing_count=$(grep -c 'MISSING' "$LOG2" 2>/dev/null || echo 0)
  [ "$missing_count" -ge 1 ] || fail "Expected MISSING verdict for stages without dispatched_at"

  # Log format: 3 space-separated fields per line
  first_line=$(head -1 "$LOG" 2>/dev/null || echo "")
  field_count=$(echo "$first_line" | awk '{print NF}')
  [ "$field_count" -ge 3 ] || fail "Audit log line has < 3 fields: '$first_line'"
else
  echo "SKIP(jq): jq not available — functional dispatch test skipped"
fi

echo "PASS: Layer 4 dispatch enforcement functional test"
exit "$FAIL"
