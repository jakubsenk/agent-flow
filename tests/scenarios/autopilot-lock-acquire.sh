#!/usr/bin/env bash
set -euo pipefail

# AC-2 / AC-36: Autopilot lock-acquire scenario
# Traces: AUTOPILOT-R2, AUTOPILOT-R13
# Description: Verifies that SKILL.md documents the owner.json lock structure
#              and that the INFO hostname line is documented.
#
# NOTE: This is a STRUCTURAL test (grep-based, no Claude CLI invocation).
# Runtime lock-acquire behavior is validated when running the actual autopilot skill.
#
# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

FAIL=0

# owner.json must be documented with all three required keys
for key in '"pid"' '"hostname"' '"acquired_at"'; do
  if ! grep -qF "$key" "$SKILL"; then
    echo "FAIL: $SKILL missing owner.json key $key" >&2
    FAIL=1
  fi
done

# INFO line with hostname documented (AC-36 / AUTOPILOT-R13)
if ! grep -qF '[autopilot][INFO] Running on host' "$SKILL"; then
  echo "FAIL: $SKILL missing [autopilot][INFO] Running on host INFO line" >&2
  FAIL=1
fi

# Lock is a directory
if ! grep -qiE 'mkdir.*autopilot\.lock|autopilot\.lock.*mkdir' "$SKILL"; then
  echo "FAIL: $SKILL does not document mkdir for lock directory" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: autopilot-lock-acquire — SKILL.md documents lock acquire with owner.json + INFO line"
exit "$FAIL"
