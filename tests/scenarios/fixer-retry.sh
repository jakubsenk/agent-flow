#!/bin/bash
# Test: Fixer agent has retry/iteration awareness
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AGENT_FILE="$REPO_ROOT/agents/fixer.md"

[ -f "$AGENT_FILE" ] || { echo "FAIL: fixer.md not found"; exit 1; }

# Check for iteration awareness
if grep -q "iteration\|retry\|attempt" "$AGENT_FILE"; then
  echo "PASS: fixer has iteration awareness"
else
  echo "FAIL: fixer missing iteration awareness"
  exit 1
fi

# Check model is opus
if head -5 "$AGENT_FILE" | grep -q "model: opus"; then
  echo "PASS: fixer uses opus model"
else
  echo "FAIL: fixer not using opus model"
  exit 1
fi
