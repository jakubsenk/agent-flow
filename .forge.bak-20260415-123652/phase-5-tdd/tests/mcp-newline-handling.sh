#!/usr/bin/env bash
# Test: MCP body formatting contract exists and all vulnerable files reference it (T-013)
# Validates:
#   Check A: core/mcp-body-formatting.md exists AND contains "NEVER use" marker
#   Check B: All 5 previously-vulnerable files reference core/mcp-body-formatting.md
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

CONTRACT="core/mcp-body-formatting.md"
CONTRACT_PATH="$REPO_ROOT/$CONTRACT"

# Check A: Contract file exists and contains the NEVER use marker
if [ ! -f "$CONTRACT_PATH" ]; then
  fail "$CONTRACT does not exist"
else
  if ! grep -q "NEVER use" "$CONTRACT_PATH"; then
    fail "$CONTRACT exists but is missing the 'NEVER use' marker in Constraints"
  fi
fi

# Check B: All 5 files that previously held inline NEVER instructions now reference the contract
REFERENCE_FILES=(
  "agents/publisher.md"
  "core/block-handler.md"
  "skills/fix-ticket/SKILL.md"
  "skills/implement-feature/SKILL.md"
  "skills/fix-bugs/SKILL.md"
)

for rel_path in "${REFERENCE_FILES[@]}"; do
  f="$REPO_ROOT/$rel_path"
  if [ ! -f "$f" ]; then
    fail "File not found: $rel_path"
    continue
  fi
  if ! grep -q "core/mcp-body-formatting.md" "$f"; then
    fail "$rel_path missing reference to core/mcp-body-formatting.md"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: core/mcp-body-formatting.md contract exists with NEVER use marker, and all 5 files reference it (T-013)"
exit "$FAIL"
