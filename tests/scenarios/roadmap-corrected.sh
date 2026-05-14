#!/bin/bash
# Covers: AC-68 (roadmap "17 -> 16 core" claim corrected to "17 core (unchanged)")
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/docs/roadmap.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-roadmap-corrected — docs/roadmap.md not found"
  exit 1
fi

FAIL=0
fail() { echo "FAIL: v9-5-roadmap-corrected — $1"; FAIL=1; }

# The incorrect phrase must be absent
# Use grep -F with explicit Unicode arrow as fixed string (no regex)
if grep -qF '17 → 16' "$REPO_ROOT/docs/roadmap.md"; then
  echo "FAIL: v9-5-roadmap-corrected — stale '17 → 16' text still present in roadmap.md"
  exit 1
fi
echo "PASS: '17 → 16' incorrect claim absent from roadmap.md"
# Also check the ASCII arrow form
if grep -qE '17[[:space:]]*->[[:space:]]*16[[:space:]]*(core|contracts)' "$FILE"; then
  fail "docs/roadmap.md still contains '17 -> 16 core' (incorrect claim)"
else
  echo "PASS: '17 -> 16 core' incorrect claim absent from roadmap.md"
fi

# The corrected phrase must be present
if grep -qE '17 core \(unchanged' "$FILE"; then
  echo "PASS: docs/roadmap.md contains '17 core (unchanged)' corrected claim"
else
  fail "docs/roadmap.md does not contain '17 core (unchanged)' corrected claim"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-roadmap-corrected — roadmap correctly states 17 core (unchanged)"
fi
exit "$FAIL"
