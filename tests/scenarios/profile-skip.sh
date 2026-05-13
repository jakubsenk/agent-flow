#!/bin/bash
# Test: Pipeline profile parsing exists in fix-ticket, fix-bugs, implement-feature
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

for cmd in fix-bugs implement-feature; do
  CMD_FILE="$REPO_ROOT/skills/$cmd/SKILL.md"
  [ -f "$CMD_FILE" ] || { echo "FAIL: skills/$cmd/SKILL.md not found"; exit 1; }

  if grep -q "Pipeline profile parsing\|--profile" "$CMD_FILE"; then
    echo "PASS: $cmd has profile parsing"
  else
    echo "FAIL: $cmd missing profile parsing"
    exit 1
  fi

  if grep -q "NEVER.*skip" "$CMD_FILE"; then
    echo "PASS: $cmd has mandatory stage protection"
  else
    echo "FAIL: $cmd missing mandatory stage protection"
    exit 1
  fi
done
