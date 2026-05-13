#!/bin/bash
# Test: Test-engineer agent has failure handling
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AGENT_FILE="$REPO_ROOT/agents/test-engineer.md"

[ -f "$AGENT_FILE" ] || { echo "FAIL: test-engineer.md not found"; exit 1; }

if grep -q "NEVER\|Constraint" "$AGENT_FILE"; then
  echo "PASS: test-engineer has constraints"
else
  echo "FAIL: test-engineer missing constraints"
  exit 1
fi
