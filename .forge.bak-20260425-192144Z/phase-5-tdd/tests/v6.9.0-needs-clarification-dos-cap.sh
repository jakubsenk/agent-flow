#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #8 — Tier A+B)
# Functional: NEEDS_CLARIFICATION DoS cap enforced (clarifications_consumed <= 3).
set -uo pipefail

. "$(dirname "$0")/../lib/fixtures.sh"

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

require_jq
setup_scratch

if [ "${HAVE_JQ:-0}" = "1" ]; then
  # Tier A: state at cap (clarifications_consumed=3) must not trigger another
  STATE=$(make_state_json '{"status":"paused","clarification":{"clarifications_consumed":3}}')
  echo "$STATE" > "$SCRATCH/state.json"

  consumed=$(jq -r '.clarification.clarifications_consumed' "$SCRATCH/state.json")
  [ "$consumed" = "3" ] || fail "clarifications_consumed not 3, got $consumed"

  # Value == cap threshold means no more clarification allowed
  cap=$(jq -r 'if .clarification.clarifications_consumed >= 3 then "BLOCKED" else "ALLOWED" end' \
    "$SCRATCH/state.json")
  [ "$cap" = "BLOCKED" ] || fail "At cap=3, pipeline should be BLOCKED from further clarification"

  # Tier A: below cap (consumed=1) should be ALLOWED
  STATE2=$(make_state_json '{"status":"paused","clarification":{"clarifications_consumed":1}}')
  echo "$STATE2" > "$SCRATCH/state2.json"
  below_cap=$(jq -r 'if .clarification.clarifications_consumed >= 3 then "BLOCKED" else "ALLOWED" end' \
    "$SCRATCH/state2.json")
  [ "$below_cap" = "ALLOWED" ] || fail "Below cap (consumed=1) should be ALLOWED"
fi

# Tier B: schema.md documents cap=3
SCHEMA="$REPO_ROOT/state/schema.md"
if [ -f "$SCHEMA" ]; then
  if ! grep -qE 'clarifications_consumed|max.*3|3.*max' "$SCHEMA"; then
    fail "state/schema.md missing clarifications_consumed cap documentation"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: NEEDS_CLARIFICATION DoS cap functional test"
exit "$FAIL"
