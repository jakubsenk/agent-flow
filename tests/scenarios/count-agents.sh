#!/bin/bash
# Covers: AC-3 (agent count = 17, UNCHANGED)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

ACTUAL=$(find "$REPO_ROOT/agents" -name '*.md' -type f | wc -l | tr -d ' ')
if [ "$ACTUAL" -eq 17 ]; then
  echo "PASS: v9-5-count-agents — agents/ .md count = 17 (unchanged)"
  exit 0
else
  echo "FAIL: v9-5-count-agents — expected 17 agent .md files, got $ACTUAL"
  exit 1
fi
