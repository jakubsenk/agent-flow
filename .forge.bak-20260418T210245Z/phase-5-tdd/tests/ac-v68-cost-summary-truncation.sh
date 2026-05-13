#!/usr/bin/env bash
set -euo pipefail

# AC-37: pipeline.summary_table truncation rule documented (≤20 rows AND ≤4000 chars)
# Traces: COST-R10
# Description: Verifies state/schema.md and/or core/state-manager.md document the
#              truncation rule for summary_table

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../../.."

FAIL=0

# Check state/schema.md for truncation documentation
SCHEMA="state/schema.md"
if [ ! -f "$SCHEMA" ]; then
  echo "FAIL: $SCHEMA does not exist" >&2
  FAIL=1
else
  # Must document 20-row limit
  if ! grep -qE '20 rows?|≤20|<= *20|max.*20' "$SCHEMA"; then
    echo "FAIL: $SCHEMA does not document 20-row limit for summary_table" >&2
    FAIL=1
  fi

  # Must document 4000 character limit
  if ! grep -qE '4000|4,000' "$SCHEMA"; then
    echo "FAIL: $SCHEMA does not document 4000-character limit for summary_table" >&2
    FAIL=1
  fi

  # Must document truncation notice row format
  if ! grep -qF 'truncated' "$SCHEMA"; then
    echo "FAIL: $SCHEMA does not document 'truncated' notice row for summary_table" >&2
    FAIL=1
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-37 — state/schema.md documents summary_table truncation (≤20 rows, ≤4000 chars)"
exit "$FAIL"
