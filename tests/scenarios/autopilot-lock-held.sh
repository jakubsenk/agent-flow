#!/usr/bin/env bash
set -euo pipefail

# AC-3: Autopilot exits 2 when lock is held (fresh lock)
# Traces: AUTOPILOT-R3
# Description: Verifies SKILL.md documents exit 2 + error message when lock held

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

FAIL=0

# Must document exit 2 for lock held
if ! grep -qE 'exit 2' "$SKILL"; then
  echo "FAIL: $SKILL does not document 'exit 2' for lock-held case" >&2
  FAIL=1
fi

# Must document the error message
if ! grep -qF '[autopilot][ERROR] Another Autopilot run in progress' "$SKILL"; then
  echo "FAIL: $SKILL missing '[autopilot][ERROR] Another Autopilot run in progress' error message" >&2
  FAIL=1
fi

# Must document that the pre-existing lock directory is NOT removed on exit 2
# (trap must NOT fire for failed acquisition — trap registered AFTER successful mkdir)
if ! grep -qiE 'AFTER.*mkdir|mkdir.*AFTER|trap.*after|registered.*after' "$SKILL"; then
  echo "FAIL: $SKILL does not document trap registered AFTER successful mkdir (prevents trap-race)" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: autopilot-lock-held — SKILL.md documents exit 2 + pre-existing lock preserved"
exit "$FAIL"
