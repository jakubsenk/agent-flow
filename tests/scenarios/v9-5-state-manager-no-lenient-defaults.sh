#!/bin/bash
# Covers: AC-14 (core/state-manager.md lenient-read defaults block deleted)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/core/state-manager.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-state-manager-no-lenient-defaults — core/state-manager.md not found"
  exit 1
fi

if grep -qF "Missing \`tokens_used\` / \`duration_ms\` / \`tool_uses\` -> treat as \`0\`" "$FILE"; then
  echo "FAIL: v9-5-state-manager-no-lenient-defaults — v6.7.x lenient-defaults fallback still present in core/state-manager.md"
  exit 1
else
  echo "PASS: v9-5-state-manager-no-lenient-defaults — v6.7.x lenient-defaults line absent from core/state-manager.md"
  exit 0
fi
