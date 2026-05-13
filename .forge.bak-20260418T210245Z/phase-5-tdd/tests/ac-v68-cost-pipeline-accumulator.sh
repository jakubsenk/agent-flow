#!/usr/bin/env bash
set -euo pipefail

# AC-18: pipeline accumulator and summary_table in state/schema.md
# Traces: COST-R6
# Description: Verifies state/schema.md documents top-level pipeline object with
#              total_tokens, total_duration_ms, total_tool_uses, summary_table

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../../.."

FILE="state/schema.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

FAIL=0

# Must have pipeline accumulator fields
for field in total_tokens total_duration_ms total_tool_uses summary_table; do
  if ! grep -qF "$field" "$FILE"; then
    echo "FAIL: $FILE missing pipeline accumulator field '$field'" >&2
    FAIL=1
  fi
done

# pipeline object must be top-level
if ! grep -qF '"pipeline"' "$FILE"; then
  echo "FAIL: $FILE missing top-level '\"pipeline\"' accumulator object" >&2
  FAIL=1
fi

# summary_table must start with | Stage (markdown table)
if ! grep -qF '"| Stage' "$FILE"; then
  echo "FAIL: $FILE missing summary_table example starting with '| Stage'" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-18 — state/schema.md documents pipeline accumulator with all 4 fields"
exit "$FAIL"
