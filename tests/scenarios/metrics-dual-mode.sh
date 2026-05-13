#!/usr/bin/env bash
set -euo pipefail

# AC-19: /metrics dual-mode aggregation (measured vs estimated) with provenance footer
# Traces: COST-R7, COST-R8, COST-R11
# Description: Verifies skills/metrics/SKILL.md documents measured vs estimated separation

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FILE="skills/metrics/SKILL.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

FAIL=0

# Must document reading state.json per issue
if ! grep -qiE 'state\.json' "$FILE"; then
  echo "FAIL: $FILE does not reference state.json for measured aggregation" >&2
  FAIL=1
fi

# Must document MEASURED category (pipeline.total_tokens exists)
if ! grep -qiE 'MEASURED|pipeline\.total_tokens' "$FILE"; then
  echo "FAIL: $FILE does not document MEASURED classification" >&2
  FAIL=1
fi

# Must document ESTIMATED category (heuristic fallback)
if ! grep -qiE 'ESTIMATED|estimated|heuristic' "$FILE"; then
  echo "FAIL: $FILE does not document ESTIMATED heuristic fallback" >&2
  FAIL=1
fi

# Provenance footer format (COST-R8)
if ! grep -qF 'Data source: measured=' "$FILE"; then
  echo "FAIL: $FILE missing 'Data source: measured=...' footer" >&2
  FAIL=1
fi

# Must NOT combine measured + estimated into a single grand total
# (filter out negation context: lines with NEVER/NOT before the pattern)
if grep -iE 'grand total.*combining|combined.*grand total' "$FILE" | grep -qivE 'NEVER|NOT summed|must not|do not'; then
  echo "FAIL: $FILE documents a combined grand total — must use SEPARATE line items" >&2
  FAIL=1
fi

# COST-R11: hybrid runs reported as ESTIMATED at pipeline level
if ! grep -qiE 'hybrid|partial.*measured|partial.*estimated' "$FILE"; then
  echo "FAIL: $FILE does not document hybrid partial-measurement handling (COST-R11)" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: metrics-dual-mode — metrics/SKILL.md documents dual-mode + provenance footer"
exit "$FAIL"
