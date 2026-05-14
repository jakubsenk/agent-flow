#!/usr/bin/env bash
set -euo pipefail

# AC-19: /metrics dual-mode aggregation with separate line items + footer
# Traces: COST-R7, COST-R8, COST-R11
# Description: Verifies skills/metrics/SKILL.md documents measured vs estimated separation
#              with provenance footer

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FILE="skills/metrics/SKILL.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

FAIL=0

# Must document reading state.json per issue
if ! grep -qiE 'state\.json|state_json' "$FILE"; then
  echo "FAIL: $FILE does not reference state.json for metrics aggregation" >&2
  FAIL=1
fi

# Must document measured vs estimated distinction
if ! grep -qiE 'MEASURED|measured' "$FILE"; then
  echo "FAIL: $FILE does not document MEASURED category" >&2
  FAIL=1
fi

if ! grep -qiE 'ESTIMATED|estimated' "$FILE"; then
  echo "FAIL: $FILE does not document ESTIMATED category" >&2
  FAIL=1
fi

# Must document the provenance footer format
if ! grep -qF 'Data source: measured=' "$FILE"; then
  echo "FAIL: $FILE missing 'Data source: measured=...' footer format" >&2
  FAIL=1
fi

# Must NOT document a single combined grand total crossing the boundary
# (filter out negation context: lines that say NEVER/NOT summed)
if grep -iE 'grand total|combined total' "$FILE" | grep -qivE 'NEVER|NOT summed|must not|do not'; then
  echo "FAIL: $FILE contains 'grand total' or 'combined total' without negation — must use SEPARATE line items" >&2
  FAIL=1
fi

# pipeline.total_tokens must be the detection field
if ! grep -qF 'pipeline.total_tokens' "$FILE"; then
  echo "FAIL: $FILE does not reference 'pipeline.total_tokens' as the measured-detection field" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-19 — metrics/SKILL.md documents dual-mode with separate line items"
exit "$FAIL"
