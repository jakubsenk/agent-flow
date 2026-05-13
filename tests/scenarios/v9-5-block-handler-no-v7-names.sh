#!/bin/bash
# Covers: AC-12 (core/block-handler.md line 22 does not reference v7 names triage-analyst or code-analyst)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/core/block-handler.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-block-handler-no-v7-names — core/block-handler.md not found"
  exit 1
fi

FAIL=0
fail() { echo "FAIL: v9-5-block-handler-no-v7-names — $1"; FAIL=1; }

LINE22=$(sed -n '22p' "$FILE")

# Line 22 must still reference analyst (canonical name)
if echo "$LINE22" | grep -q 'analyst'; then
  echo "PASS: line 22 references analyst (canonical)"
else
  fail "line 22 does not reference analyst at all: $LINE22"
fi

# v7 names must not appear in line 22
if echo "$LINE22" | grep -qE 'triage-analyst|code-analyst'; then
  fail "line 22 still contains v7 name (triage-analyst or code-analyst): $LINE22"
else
  echo "PASS: line 22 does not contain v7 names"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-block-handler-no-v7-names — block-handler.md line 22 uses canonical names only"
fi
exit "$FAIL"
