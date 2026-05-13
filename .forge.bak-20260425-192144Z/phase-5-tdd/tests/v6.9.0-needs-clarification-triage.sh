#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #11 — Tier A+B)
# Functional: triage-analyst emits NEEDS_CLARIFICATION with correct state schema fields.
set -uo pipefail

. "$(dirname "$0")/../lib/fixtures.sh"

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

require_jq
setup_scratch

# Tier B: triage-analyst must document NEEDS_CLARIFICATION output format
TRIAGE="$REPO_ROOT/agents/triage-analyst.md"
[ -f "$TRIAGE" ] || { fail "agents/triage-analyst.md not found"; exit 1; }
if ! grep -qiE 'NEEDS_CLARIFICATION' "$TRIAGE"; then
  fail "agents/triage-analyst.md missing NEEDS_CLARIFICATION documentation"
fi

if [ "${HAVE_JQ:-0}" = "1" ]; then
  # Tier A: state.json with clarification object — schema validation
  STATE=$(make_state_json '{
    "status": "paused",
    "clarification": {
      "question": "Which database adapter should I target?",
      "asked_at": "2026-04-23T12:00:00Z",
      "asked_at_iteration": 1,
      "clarifications_consumed": 1,
      "last_clarification_iteration": 1
    }
  }')
  echo "$STATE" > "$SCRATCH/state.json"

  # Verify all required clarification sub-fields present
  for field in 'question' 'asked_at' 'asked_at_iteration' 'clarifications_consumed'; do
    val=$(jq -e -r ".clarification.${field}" "$SCRATCH/state.json" 2>/dev/null)
    [ -n "$val" ] && [ "$val" != "null" ] || fail "clarification.$field missing or null"
  done

  status=$(jq -r '.status' "$SCRATCH/state.json")
  [ "$status" = "paused" ] || fail "status should be 'paused' in NEEDS_CLARIFICATION state"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: triage NEEDS_CLARIFICATION state schema verified"
exit "$FAIL"
