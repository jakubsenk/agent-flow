#!/usr/bin/env bash
set -euo pipefail

# AC-15: state.json carries six usage fields per completed stage
# Traces: COST-R2, COST-R4
# Description: Verifies state/schema.md documents all six usage fields with the canonical
#              JSON example (triage stage as reference)
#
# NOTE: Structural test — validates schema documentation, not live state.json writes.
# Live dispatch testing requires Claude CLI.

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FILE="state/schema.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

FAIL=0

# Six required usage fields in schema
for field in tokens_used duration_ms tool_uses model started_at completed_at; do
  if ! grep -qF "$field" "$FILE"; then
    echo "FAIL: $FILE missing per-stage usage field '$field'" >&2
    FAIL=1
  fi
done

# triage must be the canonical stage example
if ! grep -qF '"triage"' "$FILE"; then
  echo "FAIL: $FILE missing triage stage in schema example" >&2
  FAIL=1
fi

# model value sonnet documented
if ! grep -qF '"sonnet"' "$FILE"; then
  echo "FAIL: $FILE missing '\"sonnet\"' model value in stage example" >&2
  FAIL=1
fi

# started_at and completed_at in ISO-8601 format documented
if ! grep -qiE 'ISO.?8601|2026-0[0-9]-[0-9]{2}T' "$FILE"; then
  echo "FAIL: $FILE missing ISO-8601 timestamp example for started_at/completed_at" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: cost-state-fields — state/schema.md documents all 6 usage fields"
exit "$FAIL"
