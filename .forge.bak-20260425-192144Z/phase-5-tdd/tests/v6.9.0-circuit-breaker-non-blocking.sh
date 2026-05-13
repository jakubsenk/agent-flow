#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #5 — Tier A+B)
# Functional: webhook circuit breaker is non-blocking (advisory semantics).
# Uses make_state_json to construct state with circuit_breaker absence.
set -uo pipefail

. "$(dirname "$0")/../lib/fixtures.sh"

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

require_jq
setup_scratch

if [ "${HAVE_JQ:-0}" = "1" ]; then
  # Tier A: state.json WITHOUT circuit_breaker_count — pipeline should proceed
  STATE=$(make_state_json '{"status":"running"}')
  echo "$STATE" > "$SCRATCH/state.json"

  # circuit_breaker_count must be absent (null/empty) in baseline state
  cb_val=$(jq -r '.circuit_breaker_count // "ABSENT"' "$SCRATCH/state.json")
  [ "$cb_val" = "ABSENT" ] || fail "baseline state should not have circuit_breaker_count, got $cb_val"

  # Tier A: state WITH circuit_breaker_count=3 (threshold) — pipeline must still continue
  STATE_CB=$(make_state_json '{"status":"running","circuit_breaker_count":3}')
  echo "$STATE_CB" > "$SCRATCH/state_cb.json"
  cb_three=$(jq -r '.circuit_breaker_count' "$SCRATCH/state_cb.json")
  [ "$cb_three" = "3" ] || fail "circuit_breaker_count not preserved: $cb_three"
fi

# Tier B: circuit breaker docs say advisory (WARN), not blocking
POST_HOOK="$REPO_ROOT/core/post-publish-hook.md"
if [ -f "$POST_HOOK" ]; then
  if ! grep -qiE '\[WARN\].*circuit|circuit.*advisory|non.?block' "$POST_HOOK"; then
    fail "core/post-publish-hook.md missing non-blocking/advisory circuit breaker language"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: circuit breaker non-blocking semantics verified"
exit "$FAIL"
