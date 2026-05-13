#!/usr/bin/env bash
set -euo pipefail

# AC-4 (BusyBox fallback): Autopilot falls back to mtime check when awk mktime unavailable
# Traces: AUTOPILOT-R4
# Description: Verifies SKILL.md documents the BusyBox fallback path for stale-lock arithmetic
#
# NOTE: Structural test — verifies the fallback is documented, not runtime execution.
# Runtime BusyBox behavior cannot be tested in CI without a BusyBox container.

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

FAIL=0

# Must document BusyBox fallback
if ! grep -qiE 'BusyBox|busybox|awk.*mktime|mktime.*awk' "$SKILL"; then
  echo "FAIL: $SKILL does not document BusyBox/awk mktime fallback" >&2
  FAIL=1
fi

# Must document mtime-based fallback check
if ! grep -qiE 'mtime|find.*mmin|121.*min' "$SKILL"; then
  echo "FAIL: $SKILL does not document mtime-based fallback (find -mmin) for BusyBox" >&2
  FAIL=1
fi

# Must document iso_to_epoch function or equivalent
if ! grep -qiE 'iso_to_epoch|iso.*epoch|epoch.*iso' "$SKILL"; then
  echo "FAIL: $SKILL does not document iso_to_epoch (or equivalent) for stale arithmetic" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: autopilot-lock-stale-awk-missing — BusyBox mtime fallback documented"
exit "$FAIL"
