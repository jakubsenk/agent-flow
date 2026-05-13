#!/usr/bin/env bash
# Test: agents/code-analyst.md Constraints section has token-spelling rules
# AC-4: code-analyst has explicit token-spelling constraints
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

FILE="$REPO_ROOT/agents/code-analyst.md"

if [ ! -f "$FILE" ]; then
  fail "Missing file: agents/code-analyst.md"
  exit 1
fi

# Extract the Constraints section
CONSTRAINTS=$(awk '/^## Constraints/{found=1} found{print}' "$FILE")

if [ -z "$CONSTRAINTS" ]; then
  fail "agents/code-analyst.md has no ## Constraints section"
  exit 1
fi

# Rule 1: root cause confirmed must have YES and NO with MUST
if ! echo "$CONSTRAINTS" | grep -i "root cause confirmed" | grep -q "MUST"; then
  fail "agents/code-analyst.md Constraints section does not have a MUST rule for 'root cause confirmed' token spelling"
fi

if ! echo "$CONSTRAINTS" | grep -i "root cause confirmed" | grep -q "YES"; then
  fail "agents/code-analyst.md Constraints section does not specify 'YES' as allowed value for 'root cause confirmed'"
fi

if ! echo "$CONSTRAINTS" | grep -i "root cause confirmed" | grep -q "NO"; then
  fail "agents/code-analyst.md Constraints section does not specify 'NO' as allowed value for 'root cause confirmed'"
fi

# Rule 2: Risk level must have LOW, MEDIUM, HIGH with MUST
# The existing constraint line mentions Risk level criteria but does NOT have a MUST spelling rule.
# We need a NEW constraint with MUST for Risk level token values.
if ! echo "$CONSTRAINTS" | grep -i "risk level" | grep -q "MUST"; then
  fail "agents/code-analyst.md Constraints section does not have a MUST rule for Risk level token spelling"
fi

# The MUST rule for Risk level must include LOW, MEDIUM, HIGH
RISK_MUST_LINE=$(echo "$CONSTRAINTS" | grep -i "risk level" | grep "MUST")
if ! echo "$RISK_MUST_LINE" | grep -q "LOW"; then
  fail "agents/code-analyst.md Constraints MUST rule for Risk level does not mention 'LOW'"
fi
if ! echo "$RISK_MUST_LINE" | grep -q "MEDIUM"; then
  fail "agents/code-analyst.md Constraints MUST rule for Risk level does not mention 'MEDIUM'"
fi
if ! echo "$RISK_MUST_LINE" | grep -q "HIGH"; then
  fail "agents/code-analyst.md Constraints MUST rule for Risk level does not mention 'HIGH'"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: agents/code-analyst.md Constraints section has MUST-based rules for 'root cause confirmed' (YES/NO) and Risk level (LOW/MEDIUM/HIGH) token spelling"
exit "$FAIL"
