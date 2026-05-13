#!/usr/bin/env bash
# Test: implement-feature step X delegates to core/block-handler.md without inlining the procedure
# AC-7: implement-feature step X is <= 5 non-empty lines, references core/block-handler.md and state.json
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

IMPL_FEATURE="$REPO_ROOT/skills/implement-feature/SKILL.md"

if [ ! -f "$IMPL_FEATURE" ]; then
  fail "Missing file: skills/implement-feature/SKILL.md"
  exit 1
fi

# ---------------------------------------------------------------------------
# Extract step X content (between "### X." and the next "##" heading)
# ---------------------------------------------------------------------------

STEP_X=$(awk '/^### X\./,/^##/' "$IMPL_FEATURE" | grep -v "^### X\." | grep -v "^##" || true)

if [ -z "$STEP_X" ]; then
  fail "skills/implement-feature/SKILL.md: step '### X.' not found — block handler step may be missing or renamed"
  exit 1
fi

# ---------------------------------------------------------------------------
# Must reference core/block-handler.md
# ---------------------------------------------------------------------------

if ! echo "$STEP_X" | grep -q "core/block-handler.md"; then
  fail "skills/implement-feature/SKILL.md step X: does not reference 'core/block-handler.md'"
fi

# ---------------------------------------------------------------------------
# Must reference state.json (intentional LLM-directed redundancy — matching fix-ticket)
# ---------------------------------------------------------------------------

if ! echo "$STEP_X" | grep -q "state\.json"; then
  fail "skills/implement-feature/SKILL.md step X: does not contain 'state.json' reminder"
fi

# ---------------------------------------------------------------------------
# Must contain at most 5 non-blank lines (4-line delegation pattern per spec)
# ---------------------------------------------------------------------------

NON_BLANK_COUNT=$(echo "$STEP_X" | grep -c '[^[:space:]]' || true)
if [ "$NON_BLANK_COUNT" -gt 5 ]; then
  fail "skills/implement-feature/SKILL.md step X: has $NON_BLANK_COUNT non-blank lines — must be <= 5 (lean delegation pattern)"
fi

# ---------------------------------------------------------------------------
# Must NOT inline rollback, status-set, comment posting, or webhook logic
# ---------------------------------------------------------------------------

if echo "$STEP_X" | grep -qi "rollback"; then
  fail "skills/implement-feature/SKILL.md step X: still contains 'rollback' — inline rollback must be removed (handled by core/block-handler.md)"
fi

if echo "$STEP_X" | grep -qi "status.*set\|set.*status"; then
  fail "skills/implement-feature/SKILL.md step X: still contains inline status-set logic — must be delegated to core/block-handler.md"
fi

if echo "$STEP_X" | grep -q "curl"; then
  fail "skills/implement-feature/SKILL.md step X: still contains 'curl' — inline webhook must be removed (handled by core/block-handler.md)"
fi

# Must NOT contain old numbered inline steps 1. through 6.
for n in 1 2 3 4 5 6; do
  if echo "$STEP_X" | grep -qE "^${n}\. "; then
    fail "skills/implement-feature/SKILL.md step X: still contains old inline numbered step '${n}.' — must be fully delegated to core/block-handler.md"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: skills/implement-feature/SKILL.md step X delegates to core/block-handler.md in <= 5 non-blank lines, includes state.json reminder, and contains no inline rollback/status/curl/numbered steps (AC-7)"
exit "$FAIL"
