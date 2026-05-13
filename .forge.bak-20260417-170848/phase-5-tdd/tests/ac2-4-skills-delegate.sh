#!/usr/bin/env bash
# Test: All 3 skills delegate tracker subtask creation to core/tracker-subtask-creator.md
# AC-2 (delegation stub), AC-3 (no inline pseudocode), AC-4 (no inline curl in implement-feature)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

FIX_TICKET="$REPO_ROOT/skills/fix-ticket/SKILL.md"
FIX_BUGS="$REPO_ROOT/skills/fix-bugs/SKILL.md"
IMPL_FEATURE="$REPO_ROOT/skills/implement-feature/SKILL.md"

for f in "$FIX_TICKET" "$FIX_BUGS" "$IMPL_FEATURE"; do
  if [ ! -f "$f" ]; then
    fail "Missing file: $f"
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# AC-2 / AC-3: fix-ticket step 4b-tracker
# ---------------------------------------------------------------------------

# Must reference core contract
if ! grep -q "tracker-subtask-creator.md" "$FIX_TICKET"; then
  fail "skills/fix-ticket/SKILL.md: does not reference core/tracker-subtask-creator.md in tracker subtask step"
fi

# Must NOT contain inline pseudocode
if grep -q "FOR EACH subtask" "$FIX_TICKET"; then
  fail "skills/fix-ticket/SKILL.md: still contains inline pseudocode 'FOR EACH subtask' — must delegate to core contract"
fi

# Must NOT contain Per-Tracker table header (inline duplication)
if grep -qi "MCP Tool Pattern" "$FIX_TICKET"; then
  fail "skills/fix-ticket/SKILL.md: still contains 'MCP Tool Pattern' table header — Per-Tracker table must live only in core contract"
fi

# Must NOT contain Issue Description Template variable substitution
if grep -q "{subtask\.scope}" "$FIX_TICKET"; then
  fail "skills/fix-ticket/SKILL.md: still contains '{subtask.scope}' template — Issue Description Template must live only in core contract"
fi

# ---------------------------------------------------------------------------
# AC-2 / AC-3: fix-bugs step 3b-tracker
# ---------------------------------------------------------------------------

if ! grep -q "tracker-subtask-creator.md" "$FIX_BUGS"; then
  fail "skills/fix-bugs/SKILL.md: does not reference core/tracker-subtask-creator.md in tracker subtask step"
fi

if grep -q "FOR EACH subtask" "$FIX_BUGS"; then
  fail "skills/fix-bugs/SKILL.md: still contains inline pseudocode 'FOR EACH subtask' — must delegate to core contract"
fi

if grep -qi "MCP Tool Pattern" "$FIX_BUGS"; then
  fail "skills/fix-bugs/SKILL.md: still contains 'MCP Tool Pattern' table header — Per-Tracker table must live only in core contract"
fi

if grep -q "{subtask\.scope}" "$FIX_BUGS"; then
  fail "skills/fix-bugs/SKILL.md: still contains '{subtask.scope}' template — Issue Description Template must live only in core contract"
fi

# ---------------------------------------------------------------------------
# AC-2 / AC-3: implement-feature step 5a
# ---------------------------------------------------------------------------

if ! grep -q "tracker-subtask-creator.md" "$IMPL_FEATURE"; then
  fail "skills/implement-feature/SKILL.md: does not reference core/tracker-subtask-creator.md in tracker subtask step"
fi

if grep -q "FOR EACH subtask" "$IMPL_FEATURE"; then
  fail "skills/implement-feature/SKILL.md: still contains inline pseudocode 'FOR EACH subtask' — must delegate to core contract"
fi

if grep -qi "MCP Tool Pattern" "$IMPL_FEATURE"; then
  fail "skills/implement-feature/SKILL.md: still contains 'MCP Tool Pattern' table header — Per-Tracker table must live only in core contract"
fi

if grep -q "{subtask\.scope}" "$IMPL_FEATURE"; then
  fail "skills/implement-feature/SKILL.md: still contains '{subtask.scope}' template — Issue Description Template must live only in core contract"
fi

# ---------------------------------------------------------------------------
# AC-4: implement-feature must have zero occurrences of 'curl'
# ---------------------------------------------------------------------------

CURL_COUNT=$(grep -c "curl" "$IMPL_FEATURE" || true)
if [ "$CURL_COUNT" -ne 0 ]; then
  fail "skills/implement-feature/SKILL.md: contains $CURL_COUNT occurrence(s) of 'curl' — all inline curl must be replaced with core contract delegation"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: All 3 skills delegate tracker subtask creation to core/tracker-subtask-creator.md with no inline pseudocode, no Per-Tracker table, no Issue Description Template, and no bare curl (AC-2/AC-3/AC-4)"
exit "$FAIL"
