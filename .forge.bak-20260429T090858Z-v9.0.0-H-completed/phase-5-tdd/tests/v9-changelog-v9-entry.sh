#!/bin/bash
# PURPOSE: Assert CHANGELOG.md has a v9.0.0 entry with the required sub-section heading
#          "Sub-projekt H: Agent I/O Contracts" (REQ-H-041, AC-H-102).
# AC-H-N covered: AC-H-102
# INVOKED BY: tests/harness/run-tests.sh
# EXPECTED ON v8.0.0: FAIL (no v9.0.0 changelog entry yet)
# EXPECTED ON v9.0.0: PASS (CHANGELOG.md has v9.0.0 entry with required sub-section)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

CHANGELOG="$REPO_ROOT/CHANGELOG.md"

if [ ! -f "$CHANGELOG" ]; then
  fail "CHANGELOG.md not found at $CHANGELOG"
  exit 1
fi

# Assert v9.0.0 entry header exists
if ! grep -qE '^\#\# \[9\.0\.0\]' "$CHANGELOG"; then
  fail "CHANGELOG.md missing v9.0.0 entry header '## [9.0.0]'"
  # Mutation catch: missing changelog entry fails here
fi

# Assert the entry contains "Sub-projekt H: Agent I/O Contracts" sub-section
if ! grep -qE 'Sub-projekt H.*Agent I/O Contracts|Agent I/O Contracts.*Sub-projekt H' "$CHANGELOG"; then
  fail "CHANGELOG.md v9.0.0 entry missing 'Sub-projekt H: Agent I/O Contracts' sub-section"
  # Mutation catch: misspelling the sub-section heading fails here
fi

# Assert the entry mentions the key deliverables (belt-and-suspenders on content)
if ! grep -qF 'Output Contract' "$CHANGELOG"; then
  fail "CHANGELOG.md v9.0.0 entry does not mention '## Output Contract' (the headline change)"
fi

# Assert v9.0.0 entry appears BEFORE v8.0.0 (changelog is in reverse-chronological order)
v9_line=$(grep -nE '^\#\# \[9\.0\.0\]' "$CHANGELOG" | head -1 | cut -d: -f1)
v8_line=$(grep -nE '^\#\# \[8\.0\.0\]' "$CHANGELOG" | head -1 | cut -d: -f1)

if [ -n "$v9_line" ] && [ -n "$v8_line" ]; then
  if [ "$v9_line" -ge "$v8_line" ]; then
    fail "CHANGELOG.md v9.0.0 entry (line $v9_line) must appear before v8.0.0 entry (line $v8_line) — changelog is reverse-chronological"
  fi
fi

# Negative assertion: no stale "v9.0.0 — PLACEHOLDER" marker (sanity check for incomplete entry)
if grep -qiE '\[9\.0\.0\].*placeholder|\[9\.0\.0\].*TBD' "$CHANGELOG"; then
  fail "CHANGELOG.md v9.0.0 entry appears to be a placeholder — must be filled out"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-H-102 — CHANGELOG.md has v9.0.0 entry with 'Sub-projekt H: Agent I/O Contracts' sub-section"
fi
exit "$FAIL"
