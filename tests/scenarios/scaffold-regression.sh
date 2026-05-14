#!/bin/bash
# Test: scaffold.md v5.6.1 regression — key structural elements not accidentally removed
# Validates: UXP-1/2/3/4 edits did not remove existing required content
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# 1. --infra flag still present in Flag Parsing
if ! grep -q '\-\-infra' "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing --infra flag (accidentally removed?)"
fi

# 2. Infrastructure Declaration heading still present
if ! grep -q "Infrastructure Declaration" "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing Step 0-INFRA: Infrastructure Declaration"
fi

# 3. Step 0-MCP still present
if ! grep -q "Step 0-MCP" "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing Step 0-MCP section"
fi

# 4. On resume paragraph still present
if ! grep -q "On resume" "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing 'On resume' paragraph"
fi

# 5. Four valid combinations table still present (ready/later matrix)
if ! grep -q "Tracker.*SC.*Downstream\|ready.*ready.*Full integration\|later.*later.*Fully local" "$SCAFFOLD_CMD"; then
  if ! grep -q "Four valid combinations" "$SCAFFOLD_CMD"; then
    fail "scaffold.md missing infrastructure combinations table (ready/later matrix)"
  fi
fi

# 6. State persistence block still present (state.json write after infra collection)
if ! grep -q "infrastructure.tracker_status\|infrastructure.sc_status" "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing state persistence block (infrastructure.tracker_status / infrastructure.sc_status)"
fi

# 7. tracker_effective_status and sc_effective_status variables still defined
if ! grep -q "tracker_effective_status" "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing tracker_effective_status variable definition"
fi
if ! grep -q "sc_effective_status" "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing sc_effective_status variable definition"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: scaffold.md v5.6.1 regression — all structural elements intact"
exit "$FAIL"
