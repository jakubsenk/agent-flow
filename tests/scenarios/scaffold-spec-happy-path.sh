#!/bin/bash
# Test: Scaffold spec-first full pipeline happy path
# Validates: spec-writer/spec-reviewer agents exist, scaffold command supports spec-first pipeline,
#            all 10 steps are defined, mode selection is present
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Check new agent files exist
for agent in spec-writer spec-reviewer; do
  if [ ! -f "$REPO_ROOT/agents/$agent.md" ]; then
    echo "FAIL: Missing agent file: agents/$agent.md"
    exit 1
  fi
done

# Verify agent frontmatter
for agent in spec-writer spec-reviewer; do
  if ! grep -q "^model: opus$" "$REPO_ROOT/agents/$agent.md"; then
    echo "FAIL: Agent $agent must use model: opus"
    exit 1
  fi
done

# Verify scaffold command contains v2 pipeline steps
SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"

# Step 0: Mode selection
if ! grep -q "Mode Selection" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Step 0: Mode Selection"
  exit 1
fi

# Step 1: Specification phase (spec-writer)
if ! grep -q "spec-writer" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing spec-writer reference"
  exit 1
fi

# Step 1: spec-reviewer loop
if ! grep -q "spec-reviewer" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing spec-reviewer reference"
  exit 1
fi

# Step 5: Architecture
if ! grep -qE "agent-flow:architect|architect agent" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Step 5: Architecture"
  exit 1
fi

# Step 7: Feature implementation loop
if ! grep -q "Feature Implementation Loop" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Step 7: Feature Implementation Loop"
  exit 1
fi

# Step 8: E2E tests
if ! grep -q "E2E Tests" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Step 8: E2E Tests"
  exit 1
fi

# Step 10/9: Final report
if ! grep -q "Final Report" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Final Report step"
  exit 1
fi

# Verify three modes are offered
if ! grep -q "Interactive" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Interactive mode"
  exit 1
fi
if ! grep -q "YOLO with checkpoint" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing YOLO with checkpoint mode"
  exit 1
fi
if ! grep -q "Full YOLO" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Full YOLO mode"
  exit 1
fi

# --- v5.5.0 Step additions ---

# Step 0-INFRA: Infrastructure Declaration present
if ! grep -q "Infrastructure Declaration" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Step 0-INFRA: Infrastructure Declaration"
  exit 1
fi

# Step 0-MCP present
if ! grep -q "0-MCP" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Step 0-MCP"
  exit 1
fi

# Step 4d: Push to Remote present
if ! grep -q "Push to Remote" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Step 4d: Push to Remote"
  exit 1
fi

# Step 4e: Create Tracker Issues present
if ! grep -q "Create Tracker Issues" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Step 4e: Create Tracker Issues"
  exit 1
fi

# --- v5.5.0 Step removals (regression guards) ---

# Step 4b REMOVED
if grep -q "Step 4b" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md must NOT contain Step 4b (removed in v5.5.0)"
  exit 1
fi

# Step 4c REMOVED
if grep -q "Step 4c" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md must NOT contain Step 4c (removed in v5.5.0)"
  exit 1
fi

# Old Step 9: Issue Tracker REMOVED
if grep -q "Step 9: Issue Tracker" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md must NOT contain 'Step 9: Issue Tracker' (removed in v5.5.0)"
  exit 1
fi

# --- v5.5.0 Ordering assertion ---

# Step 0-INFRA appears before Mode Selection
INFRA_LINE=$(grep -n "Infrastructure Declaration" "$SCAFFOLD_CMD" | head -1 | cut -d: -f1)
MODE_LINE=$(grep -n "Step 0: Mode Selection" "$SCAFFOLD_CMD" | head -1 | cut -d: -f1)
if [ -z "$INFRA_LINE" ] || [ -z "$MODE_LINE" ] || [ "$INFRA_LINE" -ge "$MODE_LINE" ]; then
  echo "FAIL: Step 0-INFRA must appear before Step 0: Mode Selection"
  exit 1
fi

# Step 9 is now Final Report (not Issue Tracker)
if ! grep -q "Step 9: Final Report" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Step 9: Final Report (renumbered from Step 10)"
  exit 1
fi

# No remaining "Step 10" references
if grep -q "Step 10" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md must NOT contain Step 10 references (renumbered in v5.5.0)"
  exit 1
fi

echo "PASS: Scaffold spec-first happy path — all pipeline steps and agents present"
