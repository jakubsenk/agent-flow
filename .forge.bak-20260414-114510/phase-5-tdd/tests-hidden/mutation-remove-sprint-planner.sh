#!/usr/bin/env bash
# Hidden mutation test: Temporarily rename agents/sprint-planner.md and verify that
# sprint-planner-agent.sh FAILS, then restore the file.
# This validates that sprint-planner-agent.sh correctly catches a missing agent.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

AGENT_FILE="$REPO_ROOT/agents/sprint-planner.md"
AGENT_BACKUP="$REPO_ROOT/agents/sprint-planner.md.mutation_bak"
TEST_SCRIPT="$REPO_ROOT/.forge/phase-5-tdd/tests/sprint-planner-agent.sh"

# Prerequisite: test script must exist
if [ ! -f "$TEST_SCRIPT" ]; then
  fail "Visible test sprint-planner-agent.sh not found at $TEST_SCRIPT"
  exit 1
fi

# If the agent file doesn't exist yet (pre-implementation), just confirm the visible test fails
if [ ! -f "$AGENT_FILE" ]; then
  if bash "$TEST_SCRIPT" > /dev/null 2>&1; then
    fail "MUTATION: sprint-planner-agent.sh PASSED even though agents/sprint-planner.md does not exist — test is not detecting missing file"
  else
    echo "OK: sprint-planner-agent.sh correctly fails when agents/sprint-planner.md is absent"
  fi
  [ "$FAIL" -eq 0 ] && echo "PASS: mutation-remove-sprint-planner — test correctly detects absent agent"
  exit "$FAIL"
fi

# Agent exists — perform rename mutation
mv "$AGENT_FILE" "$AGENT_BACKUP"

# Run the visible test — it MUST fail
if bash "$TEST_SCRIPT" > /dev/null 2>&1; then
  mv "$AGENT_BACKUP" "$AGENT_FILE"
  fail "MUTATION ESCAPED: sprint-planner-agent.sh passed even with agents/sprint-planner.md removed"
else
  echo "OK: sprint-planner-agent.sh correctly fails when agents/sprint-planner.md is removed"
fi

# Restore
mv "$AGENT_BACKUP" "$AGENT_FILE"

[ "$FAIL" -eq 0 ] && echo "PASS: mutation-remove-sprint-planner — removal of agents/sprint-planner.md is correctly caught by sprint-planner-agent.sh"
exit "$FAIL"
