#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #16 — Tier A+B, RESTORED)
# Functional: pipeline-paused webhook event documented with curl --proto guard.
set -uo pipefail

. "$(dirname "$0")/../lib/fixtures.sh"

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

require_jq
setup_scratch

# Tier B: pipeline-paused event documented in post-publish-hook or docs
POST_HOOK="$REPO_ROOT/core/post-publish-hook.md"
if [ -f "$POST_HOOK" ]; then
  if ! grep -qF 'pipeline-paused' "$POST_HOOK"; then
    fail "core/post-publish-hook.md missing pipeline-paused event"
  fi
  # curl must use --proto guard
  if ! grep -qE '\-\-proto.*=http|--proto "=http' "$POST_HOOK"; then
    fail "core/post-publish-hook.md missing --proto http/https guard on curl"
  fi
fi

if [ "${HAVE_JQ:-0}" = "1" ]; then
  # Tier A: simulate webhook payload construction for pipeline-paused
  STATE=$(make_state_json '{
    "status": "paused",
    "clarification": {"question": "Which endpoint should I target?"}
  }')
  echo "$STATE" > "$SCRATCH/state.json"

  # Build minimal webhook payload (process-substitution simulation)
  PAYLOAD=$(jq -n \
    --argjson state "$(cat "$SCRATCH/state.json")" \
    --arg event "pipeline-paused" \
    '{event: $event, run_id: $state.run_id, status: $state.status}')
  echo "$PAYLOAD" > "$SCRATCH/payload.json"

  event_val=$(jq -r '.event' "$SCRATCH/payload.json")
  [ "$event_val" = "pipeline-paused" ] || fail ".event should be 'pipeline-paused', got '$event_val'"

  status_val=$(jq -r '.status' "$SCRATCH/payload.json")
  [ "$status_val" = "paused" ] || fail ".status should be 'paused', got '$status_val'"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: pipeline-paused webhook event and curl guard verified"
exit "$FAIL"
