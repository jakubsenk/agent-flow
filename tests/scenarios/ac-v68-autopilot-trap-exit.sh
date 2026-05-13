#!/usr/bin/env bash
set -euo pipefail

# AC-5: Autopilot SKILL.md registers trap ... EXIT for lock release
# Traces: AUTOPILOT-R5
# Description: Verifies SKILL.md documents trap EXIT handler after successful mkdir

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

# Must have at least one trap ... EXIT reference
TRAP_COUNT=$(grep -cE 'trap .*EXIT' "$SKILL" || echo 0)
if [ "$TRAP_COUNT" -eq 0 ]; then
  echo "FAIL: $SKILL has no 'trap ... EXIT' handler — required for lock release" >&2
  exit 1
fi

# The trap must reference the autopilot.lock path (absolute or variable reference)
if ! grep -E 'trap .*EXIT' "$SKILL" | grep -qE 'autopilot\.lock|LOCK_DIR'; then
  # Allow indirect reference: trap body elsewhere may reference the variable
  if ! grep -qE 'autopilot\.lock|LOCK_DIR' "$SKILL"; then
    echo "FAIL: $SKILL trap does not reference autopilot.lock or LOCK_DIR" >&2
    exit 1
  fi
fi

echo "PASS: AC-5 — skills/autopilot/SKILL.md registers trap ... EXIT for lock cleanup"
exit 0
