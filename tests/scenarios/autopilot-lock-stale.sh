#!/usr/bin/env bash
set -euo pipefail

# AC-4: Autopilot recovers from stale lock (>120min)
# Traces: AUTOPILOT-R4
# Description: Verifies SKILL.md documents stale lock recovery (re-acquire after stale threshold)

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

FAIL=0

# Must document stale detection
if ! grep -qiE 'stale' "$SKILL"; then
  echo "FAIL: $SKILL does not document stale lock detection" >&2
  FAIL=1
fi

# Must document the 120-minute threshold (or Lock timeout reference)
if ! grep -qE '120' "$SKILL"; then
  echo "FAIL: $SKILL does not document 120-minute stale threshold" >&2
  FAIL=1
fi

# Must document rm -rf of stale lock
if ! grep -qiE 'rm -rf.*LOCK|rm.*lock_dir|remove.*stale' "$SKILL"; then
  echo "FAIL: $SKILL does not document removing stale lock directory" >&2
  FAIL=1
fi

# Must document re-acquire (once, not loop)
if ! grep -qiE 're.?acqui|try.*mkdir|mkdir.*again' "$SKILL"; then
  echo "FAIL: $SKILL does not document re-acquiring lock after stale removal" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: autopilot-lock-stale — SKILL.md documents stale lock (>120min) recovery"
exit "$FAIL"
