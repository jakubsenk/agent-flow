#!/usr/bin/env bash
set -euo pipefail

# AC-24: /autopilot row appears in docs/reference/skills.md
# Traces: AUTOPILOT-R1
# Description: Verifies docs/reference/skills.md has a table row for /autopilot

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FILE="docs/reference/skills.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

# Exactly 1 match for /autopilot row (AC-24 verify command)
MATCHES=$(grep -cE '^[|] /autopilot ' "$FILE" || echo 0)
if [ "$MATCHES" -lt 1 ]; then
  echo "FAIL: $FILE missing '| /autopilot ...' table row (expected ≥1 match)" >&2
  exit 1
fi

echo "PASS: AC-24 — docs/reference/skills.md has /autopilot table row ($MATCHES match)"
exit 0
