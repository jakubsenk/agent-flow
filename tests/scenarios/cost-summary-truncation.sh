#!/usr/bin/env bash
set -euo pipefail

# AC-37: summary_table truncation rule applied when stage count > 20
# Traces: COST-R10
# Description: Verifies state/schema.md documents truncation with ≤20 rows + truncation notice

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FILE="state/schema.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

FAIL=0

# 20-row limit documented (matches "20 rows", "20 data rows", "≤20", "max 20")
if ! grep -qE '20 (data )?rows?|20 row|[≤<]=?20|max.*20' "$FILE"; then
  echo "FAIL: $FILE does not document 20-row limit for summary_table" >&2
  FAIL=1
fi

# 4000-character limit documented
if ! grep -qE '4000|4,000' "$FILE"; then
  echo "FAIL: $FILE does not document 4000-char limit for summary_table" >&2
  FAIL=1
fi

# Truncation notice row documented (use -E not -iF to avoid Windows grep SIGABRT)
if ! grep -qiE 'truncat' "$FILE"; then
  echo "FAIL: $FILE does not document truncation notice row" >&2
  FAIL=1
fi

# pipeline.log forward reference (truncated stages go there)
if ! grep -qiE 'pipeline\.log|pipeline_log' "$FILE"; then
  echo "FAIL: $FILE does not reference pipeline.log for truncated stage details" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: cost-summary-truncation — state/schema.md documents truncation rule"
exit "$FAIL"
