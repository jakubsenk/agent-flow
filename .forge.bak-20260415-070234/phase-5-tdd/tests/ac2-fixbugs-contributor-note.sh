#!/usr/bin/env bash
# Test: skills/fix-bugs/SKILL.md has HTML comment about intentional atomic-write repetition
# AC-2: Contributor note exists in fix-bugs/SKILL.md before first atomic-write reference
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

FILE="$REPO_ROOT/skills/fix-bugs/SKILL.md"

if [ ! -f "$FILE" ]; then
  fail "Missing file: skills/fix-bugs/SKILL.md"
  exit 1
fi

# The file must contain an HTML comment (starts with <!-- ... -->)
if ! grep -q "<!--" "$FILE"; then
  fail "skills/fix-bugs/SKILL.md has no HTML comment (<!--...-->) at all"
fi

# The HTML comment must contain "intentional" (case-insensitive)
if ! grep -qi "intentional" "$FILE"; then
  fail "skills/fix-bugs/SKILL.md HTML comment does not contain 'intentional'"
fi

# The HTML comment must contain "Do not consolidate" (or similar — check case-insensitively)
if ! grep -qi "do not consolidate" "$FILE"; then
  fail "skills/fix-bugs/SKILL.md HTML comment does not contain 'Do not consolidate'"
fi

# The comment must appear BEFORE the first occurrence of the atomic-write phrase.
# Strategy: find line numbers of the HTML comment open tag and the first atomic-write occurrence.
COMMENT_LINE=$(grep -n "<!--" "$FILE" | head -1 | cut -d: -f1)
ATOMIC_LINE=$(grep -n "Follow atomic write protocol from" "$FILE" | head -1 | cut -d: -f1)

if [ -z "$COMMENT_LINE" ]; then
  fail "skills/fix-bugs/SKILL.md: could not locate HTML comment line"
elif [ -z "$ATOMIC_LINE" ]; then
  fail "skills/fix-bugs/SKILL.md: could not locate first atomic write protocol line"
elif [ "$COMMENT_LINE" -gt "$ATOMIC_LINE" ]; then
  fail "skills/fix-bugs/SKILL.md: HTML comment (line $COMMENT_LINE) appears AFTER first atomic-write reference (line $ATOMIC_LINE) — must be before or adjacent to it"
fi

# All 16 occurrences of the atomic-write phrase must still be present
# The phrase appears both backtick-quoted (15x) and unquoted in a JS comment (1x)
ATOMIC_COUNT=$(grep -c "Follow atomic write protocol from" "$FILE" || true)
if [ "$ATOMIC_COUNT" -ne 16 ]; then
  fail "skills/fix-bugs/SKILL.md: expected 16 occurrences of 'Follow atomic write protocol from', found $ATOMIC_COUNT — some were removed or consolidated"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: skills/fix-bugs/SKILL.md has contributor note about intentional atomic-write repetition before first occurrence, all 16 occurrences intact"
exit "$FAIL"
