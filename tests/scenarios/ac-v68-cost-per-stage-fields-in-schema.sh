#!/usr/bin/env bash
set -euo pipefail

# AC-15: state.json carries six usage fields per completed stage
# Traces: COST-R2, COST-R4
# Description: Verifies state/schema.md documents tokens_used, duration_ms, tool_uses,
#              model, started_at, completed_at on stage entries

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FILE="state/schema.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

FAIL=0

# The six required usage fields
for field in tokens_used duration_ms tool_uses model started_at completed_at; do
  if ! grep -qF "$field" "$FILE"; then
    echo "FAIL: $FILE missing per-stage usage field '$field'" >&2
    FAIL=1
  fi
done

# Must be on stage objects (triage at minimum as the canonical example)
if ! grep -qF '"triage"' "$FILE"; then
  echo "FAIL: $FILE missing 'triage' stage example in schema" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-15 — state/schema.md documents all 6 per-stage usage fields"
exit "$FAIL"
