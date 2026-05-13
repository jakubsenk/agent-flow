#!/bin/bash
# Test: Scaffold v2 --no-implement backwards compatibility
# Validates: --no-implement produces v3.x behavior (no spec phase, stack-selector used)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"

# Verify --no-implement flag is documented
if ! grep -q "\-\-no-implement" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing --no-implement flag"
  exit 1
fi

# Verify --no-implement skips to legacy flow
if ! grep -q "Legacy Flow" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing legacy flow section for --no-implement"
  exit 1
fi

# Verify legacy flow uses stack-selector
if ! grep -q "stack-selector" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md legacy flow missing stack-selector reference"
  exit 1
fi

# Verify legacy flow does NOT use spec-writer in the --no-implement path
# (spec-writer should only appear in v2 mode steps)
# Check that the legacy flow section contains stack-selector but the flow
# explicitly exits before spec phase
if ! grep -q "EXIT pipeline" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md --no-implement must EXIT pipeline before spec phase"
  exit 1
fi

# Verify legacy flow has report with v3.x format (Next steps with manual feature creation)
if ! grep -q "Create issues in your issue tracker" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md legacy report missing v3.x next steps"
  exit 1
fi

# --- v5.5.0 ---

# Step 0-INFRA present even in --no-implement flow
if ! grep -q "Infrastructure Declaration" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Infrastructure Declaration (must run for --no-implement too)"
  exit 1
fi

# L5b Push to Remote present in legacy flow
if ! grep -q "L5b" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md legacy flow missing L5b (Push to Remote)"
  exit 1
fi

echo "PASS: Scaffold v2 --no-implement backwards compatibility verified"
