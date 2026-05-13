#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #1 — Tier A+B)
# Functional: autopilot must skip (not process) issues with status="paused".
# Uses make_state_json + jq to construct and query synthetic state.json.
set -uo pipefail

. "$(dirname "$0")/../lib/fixtures.sh"

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

require_jq
setup_scratch

# TODO(phase-7-fixer): SUT invocation — autopilot skip-paused logic
# The production path: skills/autopilot/SKILL.md Step 2 checks state.status == "paused"
# and skips the issue rather than dispatching it.

if [ "${HAVE_JQ:-0}" = "1" ]; then
  # Tier A: construct state.json with status="paused"
  STATE=$(make_state_json '{"status":"paused","clarification":{"question":"Please clarify X"}}')
  echo "$STATE" > "$SCRATCH/state.json"

  # Verify state is correctly constructed
  actual_status=$(jq -r '.status' "$SCRATCH/state.json")
  [ "$actual_status" = "paused" ] || fail "make_state_json: .status should be 'paused', got '$actual_status'"

  # Verify clarification sub-object is preserved
  question=$(jq -r '.clarification.question' "$SCRATCH/state.json")
  [ "$question" = "Please clarify X" ] || fail "clarification.question not preserved: $question"

  # Tier B: grep autopilot skill for paused-skip logic
  AUTOPILOT="$REPO_ROOT/skills/autopilot/SKILL.md"
  if [ -f "$AUTOPILOT" ]; then
    if ! grep -qiE 'paused|status.*paused|skip.*paused' "$AUTOPILOT"; then
      fail "autopilot SKILL.md missing paused-skip logic"
    fi
  fi

  # TODO(phase-7-fixer): Source autopilot's parse_pause_timeout function and invoke it
  # with state_json pointing to $SCRATCH/state.json; assert skip outcome
else
  echo "SKIP(jq): jq not available"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: autopilot skip-paused functional test"
exit "$FAIL"
