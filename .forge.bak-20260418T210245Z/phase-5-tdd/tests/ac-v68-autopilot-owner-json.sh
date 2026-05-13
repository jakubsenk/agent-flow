#!/usr/bin/env bash
set -euo pipefail

# AC-2: Autopilot lock owner.json structure documented (pid, hostname, acquired_at)
# Traces: AUTOPILOT-R2
# Description: Verifies SKILL.md documents owner.json with required keys

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

# owner.json must be referenced
if ! grep -qF 'owner.json' "$SKILL"; then
  echo "FAIL: $SKILL does not reference owner.json" >&2
  exit 1
fi

# Required JSON keys
for key in pid hostname acquired_at; do
  if ! grep -qF "$key" "$SKILL"; then
    echo "FAIL: $SKILL does not document owner.json key '$key'" >&2
    exit 1
  fi
done

echo "PASS: AC-2 — Autopilot SKILL.md documents owner.json with pid, hostname, acquired_at"
exit 0
