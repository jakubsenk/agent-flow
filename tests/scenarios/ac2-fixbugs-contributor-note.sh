#!/usr/bin/env bash
# Test: fix-bugs SKILL.md + step files preserve the contributor note about
# intentional atomic-write repetition. v10 thin-controller: atomic-write
# invocations live in steps/*.md, not in SKILL.md.
# AC-2 (post-v10): the contributor note exists somewhere in the fix-bugs tree
# and the aggregate has at least 14 atomic-write references.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

FILE="$REPO_ROOT/skills/fix-bugs/SKILL.md"
STEPS_DIR="$REPO_ROOT/skills/fix-bugs/steps"

if [ ! -f "$FILE" ]; then
  fail "Missing file: skills/fix-bugs/SKILL.md"
  exit 1
fi

# Build aggregate (SKILL.md + steps/*.md)
AGG_FILE=$(mktemp)
cat "$FILE" > "$AGG_FILE"
[ -d "$STEPS_DIR" ] && cat "$STEPS_DIR"/*.md >> "$AGG_FILE"

# The aggregate must contain an HTML comment
if ! grep -q "<!--" "$AGG_FILE"; then
  fail "fix-bugs SKILL.md + step files have no HTML comment (<!--...-->) at all"
fi

# The aggregate must contain "intentional" or "@snippet" (the v10 consolidation mechanism)
if ! grep -qiE "intentional|@snippet:" "$AGG_FILE"; then
  fail "fix-bugs SKILL.md + step files do not contain 'intentional' or '@snippet:' contributor note"
fi

# The aggregate must contain "Do not consolidate" OR @snippet: citations
if ! grep -qi "do not consolidate" "$AGG_FILE" && ! grep -qF "@snippet:" "$AGG_FILE"; then
  fail "fix-bugs SKILL.md + step files lack 'Do not consolidate' note or @snippet citations"
fi

# Atomic-write reference count across aggregate must be >= 14
ATOMIC_COUNT=$(grep -v "<!--" "$AGG_FILE" | grep -c "atomic write protocol\|Follow atomic write" || true)
if [ "$ATOMIC_COUNT" -lt 14 ]; then
  fail "fix-bugs aggregate: expected at least 14 atomic-write references, found $ATOMIC_COUNT"
fi

rm -f "$AGG_FILE"

[ "$FAIL" -eq 0 ] && echo "PASS: fix-bugs aggregate has contributor note + at least 14 atomic-write references (v10 thin-controller)"
exit "$FAIL"
