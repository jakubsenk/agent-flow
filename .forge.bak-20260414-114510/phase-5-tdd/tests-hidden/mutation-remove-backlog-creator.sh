#!/usr/bin/env bash
# Hidden mutation test: Temporarily rename agents/backlog-creator.md and verify that
# backlog-creator-agent.sh FAILS, then restore the file.
# This validates that backlog-creator-agent.sh correctly catches a missing agent.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

AGENT_FILE="$REPO_ROOT/agents/backlog-creator.md"
AGENT_BACKUP="$REPO_ROOT/agents/backlog-creator.md.mutation_bak"
TEST_SCRIPT="$REPO_ROOT/.forge/phase-5-tdd/tests/backlog-creator-agent.sh"

# Prerequisite: test script must exist
if [ ! -f "$TEST_SCRIPT" ]; then
  fail "Visible test backlog-creator-agent.sh not found at $TEST_SCRIPT"
  exit 1
fi

# If the agent file doesn't exist yet (pre-implementation), just confirm the visible test fails
if [ ! -f "$AGENT_FILE" ]; then
  if bash "$TEST_SCRIPT" > /dev/null 2>&1; then
    fail "MUTATION: backlog-creator-agent.sh PASSED even though agents/backlog-creator.md does not exist — test is not detecting missing file"
  else
    echo "OK: backlog-creator-agent.sh correctly fails when agents/backlog-creator.md is absent"
  fi
  [ "$FAIL" -eq 0 ] && echo "PASS: mutation-remove-backlog-creator — test correctly detects absent agent"
  exit "$FAIL"
fi

# Agent exists — perform rename mutation
mv "$AGENT_FILE" "$AGENT_BACKUP"

# Run the visible test — it MUST fail
if bash "$TEST_SCRIPT" > /dev/null 2>&1; then
  # Test passed despite missing file — mutation was NOT caught
  mv "$AGENT_BACKUP" "$AGENT_FILE"
  fail "MUTATION ESCAPED: backlog-creator-agent.sh passed even with agents/backlog-creator.md removed"
else
  echo "OK: backlog-creator-agent.sh correctly fails when agents/backlog-creator.md is removed"
fi

# Restore
mv "$AGENT_BACKUP" "$AGENT_FILE"

[ "$FAIL" -eq 0 ] && echo "PASS: mutation-remove-backlog-creator — removal of agents/backlog-creator.md is correctly caught by backlog-creator-agent.sh"
exit "$FAIL"
