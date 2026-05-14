#!/bin/bash
# Covers: AC-19 (tests/scenarios/v8-count-core-contracts.sh line 3 comment says 17 not 16)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/tests/scenarios/v8-count-core-contracts.sh"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-count-core-contracts-test — tests/scenarios/v8-count-core-contracts.sh not found"
  exit 1
fi

LINE3=$(sed -n '3p' "$FILE")
if echo "$LINE3" | grep -qF '17 .md files'; then
  echo "PASS: v9-5-count-core-contracts-test — v8-count-core-contracts.sh line 3 says '17 .md files'"
  exit 0
else
  echo "FAIL: v9-5-count-core-contracts-test — line 3 of v8-count-core-contracts.sh does not say '17 .md files': $LINE3"
  exit 1
fi
