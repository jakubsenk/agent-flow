#!/bin/bash
# Covers: AC-10 (core/aliases/agents-rename-aliases.md does not exist)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if [ ! -f "$REPO_ROOT/core/aliases/agents-rename-aliases.md" ]; then
  echo "PASS: v9-5-core-aliases-deleted — core/aliases/agents-rename-aliases.md correctly absent"
  exit 0
else
  echo "FAIL: v9-5-core-aliases-deleted — core/aliases/agents-rename-aliases.md still exists"
  exit 1
fi
