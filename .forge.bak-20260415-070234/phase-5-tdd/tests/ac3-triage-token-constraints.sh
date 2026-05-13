#!/usr/bin/env bash
# Test: agents/triage-analyst.md Constraints section has token-spelling rules
# AC-3: triage-analyst has explicit token-spelling constraints
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

FILE="$REPO_ROOT/agents/triage-analyst.md"

if [ ! -f "$FILE" ]; then
  fail "Missing file: agents/triage-analyst.md"
  exit 1
fi

# Extract only the Constraints section (from "## Constraints" to next "## " heading or end of file)
CONSTRAINTS=$(awk '/^## Constraints/,/^## [^C]/' "$FILE")
if [ -z "$CONSTRAINTS" ]; then
  # Try without lookahead — just grab from ## Constraints to end
  CONSTRAINTS=$(awk '/^## Constraints/{found=1} found{print}' "$FILE")
fi

# Rule 1: Quality gate token constraint — must mention PASS and UNCLEAR with MUST
if ! echo "$CONSTRAINTS" | grep -q "MUST"; then
  fail "agents/triage-analyst.md Constraints section has no MUST-based rule for token spelling"
fi

if ! echo "$CONSTRAINTS" | grep -q "PASS"; then
  fail "agents/triage-analyst.md Constraints section does not specify 'PASS' as an allowed Quality gate value"
fi

if ! echo "$CONSTRAINTS" | grep -q "UNCLEAR"; then
  # UNCLEAR already appears in Process — check it is in Constraints too
  fail "agents/triage-analyst.md Constraints section does not specify 'UNCLEAR' as an allowed Quality gate value"
fi

# Rule 1 must be imperative: contains MUST (already checked above for any MUST)
# Specifically check the Quality gate constraint uses MUST
if ! echo "$CONSTRAINTS" | grep -i "quality gate" | grep -q "MUST"; then
  fail "agents/triage-analyst.md Constraints section Quality gate rule does not use imperative 'MUST'"
fi

# Rule 2: Reproduction steps format — must mention JSON array and MUST
if ! echo "$CONSTRAINTS" | grep -i "reproduction steps" | grep -q "MUST"; then
  fail "agents/triage-analyst.md Constraints section Reproduction steps rule does not use imperative 'MUST'"
fi

if ! echo "$CONSTRAINTS" | grep -qi "json array"; then
  fail "agents/triage-analyst.md Constraints section does not specify JSON array literal format for Reproduction steps"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: agents/triage-analyst.md Constraints section has MUST-based rules for Quality gate token (PASS/UNCLEAR) and Reproduction steps JSON array format"
exit "$FAIL"
