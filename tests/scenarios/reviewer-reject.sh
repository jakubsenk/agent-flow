#!/bin/bash
# Test: Reviewer agent has APPROVE/REQUEST_CHANGES output
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AGENT_FILE="$REPO_ROOT/agents/reviewer.md"

[ -f "$AGENT_FILE" ] || { echo "FAIL: reviewer.md not found"; exit 1; }

if grep -q "APPROVE" "$AGENT_FILE" && grep -q "REQUEST_CHANGES" "$AGENT_FILE"; then
  echo "PASS: reviewer has APPROVE/REQUEST_CHANGES output"
else
  echo "FAIL: reviewer missing APPROVE/REQUEST_CHANGES"
  exit 1
fi
