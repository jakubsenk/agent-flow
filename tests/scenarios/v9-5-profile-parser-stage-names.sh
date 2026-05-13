#!/bin/bash
# Covers: AC-11 (core/profile-parser.md lists only canonical v8/v9 stage names, no code-analyst)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/core/profile-parser.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-profile-parser-stage-names — core/profile-parser.md not found"
  exit 1
fi

FAIL=0
fail() { echo "FAIL: v9-5-profile-parser-stage-names — $1"; FAIL=1; }

# Canonical v8/v9 names must be present
if grep '6\. Validate each stage name' "$FILE" | grep -q 'analyst-impact'; then
  echo "PASS: analyst-impact present in valid stage set"
else
  fail "analyst-impact not found in valid stage set in core/profile-parser.md"
fi

if grep '6\. Validate each stage name' "$FILE" | grep -q 'browser-agent-reproduce'; then
  echo "PASS: browser-agent-reproduce present in valid stage set"
else
  fail "browser-agent-reproduce not found in valid stage set in core/profile-parser.md"
fi

# v7 name code-analyst must NOT be in the valid set list
if grep '6\. Validate each stage name' "$FILE" | grep -q 'code-analyst'; then
  fail "v7 name code-analyst still listed in valid stage set in core/profile-parser.md"
else
  echo "PASS: code-analyst correctly absent from valid stage set"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-profile-parser-stage-names — profile-parser uses only canonical stage names"
fi
exit "$FAIL"
