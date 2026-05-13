#!/bin/bash
# Covers: AC-18 (core/agent-override-injector.md says 17 not 16 for core contract count)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/core/agent-override-injector.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-agent-override-injector-count — core/agent-override-injector.md not found"
  exit 1
fi

FAIL=0
fail() { echo "FAIL: v9-5-agent-override-injector-count — $1"; FAIL=1; }

if grep -qE 'count must remain 17|maxdepth-1.*17|17 contracts' "$FILE"; then
  echo "PASS: core/agent-override-injector.md references 17 (correct count)"
else
  fail "core/agent-override-injector.md does not reference 17 core contracts"
fi

if grep -qF 'count must remain 16' "$FILE"; then
  fail "core/agent-override-injector.md still references 16 (stale count)"
else
  echo "PASS: stale count '16' absent from core/agent-override-injector.md"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-agent-override-injector-count — injector references correct count of 17"
fi
exit "$FAIL"
