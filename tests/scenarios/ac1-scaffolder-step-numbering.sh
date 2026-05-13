#!/usr/bin/env bash
# Test: scaffolder.md Process section has sequential steps 1-6 with no 4b labels
# AC-1: Scaffolder step numbering is sequential 1-6
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

FILE="$REPO_ROOT/agents/scaffolder.md"

if [ ! -f "$FILE" ]; then
  fail "Missing file: agents/scaffolder.md"
  exit 1
fi

# Step 4b must NOT exist
if grep -q "^4b\." "$FILE"; then
  fail "agents/scaffolder.md still has step '4b.' label — must be renumbered to 5"
fi

# Step 5 must be "Generate quality scorecard"
if ! grep -q "^5\. Generate quality scorecard" "$FILE"; then
  fail "agents/scaffolder.md step 5 is not 'Generate quality scorecard' (previously 4b)"
fi

# Step 6 must be "Output"
if ! grep -q "^6\. Output" "$FILE"; then
  fail "agents/scaffolder.md step 6 is not 'Output' (previously 5)"
fi

# Step 4 must still exist (unchanged)
if ! grep -q "^4\. Verify the skeleton builds and tests pass" "$FILE"; then
  fail "agents/scaffolder.md step 4 was modified or removed unexpectedly"
fi

# Steps 1, 2, 3 must still exist (unchanged labels)
for n in 1 2 3; do
  if ! grep -qE "^${n}\." "$FILE"; then
    fail "agents/scaffolder.md step ${n} is missing or removed"
  fi
done

# No step labelled "5. Output:" with the old numbering (old step 5 should now be step 6)
# Ensure there is no second "Output" step with number 5
if grep -qE "^5\. Output" "$FILE"; then
  fail "agents/scaffolder.md step 5 is still 'Output' — renumbering to step 6 was not applied"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: agents/scaffolder.md Process section uses sequential steps 1-6 with no 4b labels"
exit "$FAIL"
