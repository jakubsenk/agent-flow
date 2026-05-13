#!/usr/bin/env bash
set -euo pipefail

# AC-4 + AC-30: Autopilot documents stale lock detection (>120min) and recovery
# Traces: AUTOPILOT-R4, AUTOPILOT-R2
# Description: Verifies SKILL.md documents 120-minute stale lock threshold and re-acquire

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

# Must document 120-minute stale threshold
if ! grep -qE '120' "$SKILL"; then
  echo "FAIL: $SKILL does not mention 120 (stale lock threshold in minutes)" >&2
  exit 1
fi

# Must document Lock timeout config key
if ! grep -qiE 'Lock timeout|lock_timeout' "$SKILL"; then
  echo "FAIL: $SKILL does not reference 'Lock timeout' config key" >&2
  exit 1
fi

# Must document stale lock recovery (re-acquire)
if ! grep -qiE 'stale|re.acqui' "$SKILL"; then
  echo "FAIL: $SKILL does not document stale lock detection/recovery" >&2
  exit 1
fi

echo "PASS: AC-4 — Autopilot SKILL.md documents 120-min stale lock detection and recovery"
exit 0
