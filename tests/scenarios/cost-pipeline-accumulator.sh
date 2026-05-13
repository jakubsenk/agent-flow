#!/usr/bin/env bash
set -euo pipefail

# AC-18: pipeline accumulator and summary_table in state/schema.md
# Traces: COST-R6
# Description: Verifies state/schema.md documents top-level pipeline accumulator

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FILE="state/schema.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

FAIL=0

# pipeline accumulator object
if ! grep -qF '"pipeline"' "$FILE"; then
  echo "FAIL: $FILE missing top-level '\"pipeline\"' accumulator" >&2
  FAIL=1
fi

# Four required accumulator fields
for field in total_tokens total_duration_ms total_tool_uses summary_table; do
  if ! grep -qF "$field" "$FILE"; then
    echo "FAIL: $FILE missing pipeline accumulator field '$field'" >&2
    FAIL=1
  fi
done

# summary_table must start with | Stage (markdown table format)
if ! grep -qF '"| Stage' "$FILE"; then
  echo "FAIL: $FILE summary_table example must start with '| Stage'" >&2
  FAIL=1
fi

# Written at pipeline end (before terminal state write)
if ! grep -qiE 'pipeline end|terminal.*write|before.*terminal' "$FILE"; then
  echo "FAIL: $FILE does not document pipeline accumulator written at pipeline end" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: cost-pipeline-accumulator — state/schema.md documents pipeline accumulator"
exit "$FAIL"
