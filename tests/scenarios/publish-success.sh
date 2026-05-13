#!/bin/bash
# Test: Publisher agent creates PR, never pushes to main
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AGENT_FILE="$REPO_ROOT/agents/publisher.md"

[ -f "$AGENT_FILE" ] || { echo "FAIL: publisher.md not found"; exit 1; }

if grep -q "NEVER.*main\|NEVER.*push.*main\|never push.*main" "$AGENT_FILE"; then
  echo "PASS: publisher has main branch protection"
else
  echo "FAIL: publisher missing main branch protection"
  exit 1
fi

if head -5 "$AGENT_FILE" | grep -q "model: haiku"; then
  echo "PASS: publisher uses haiku model"
else
  echo "FAIL: publisher not using haiku model"
  exit 1
fi
