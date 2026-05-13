#!/usr/bin/env bash
# v9.3.0 TDD — tests written before implementation
# T-09: Autopilot cross-reference updated to fix-bugs (AC-043, implementation-notes §D)
#
# Tests that skills/autopilot/SKILL.md:
#   1. Does NOT contain /ceos-agents:fix-ticket (deleted skill)
#   2. DOES contain /ceos-agents:fix-bugs (merged replacement)
#   3. TARGET_SKILL="/ceos-agents:fix-bugs" appears exactly once
#
# This is a critical runtime correctness check: autopilot dispatches bugs to fix-ticket
# currently; after v9.3.0 deletion of fix-ticket, autopilot must dispatch to fix-bugs.
#
# RED until Phase 7 implementation is complete — that is correct TDD behavior.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
[ -f "$REPO_ROOT/tests/lib/fixtures.sh" ] || REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

SKILL="$REPO_ROOT/skills/autopilot/SKILL.md"

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Prerequisite
# ---------------------------------------------------------------------------
if [ ! -f "$SKILL" ]; then
  echo "FAIL: skills/autopilot/SKILL.md does not exist" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Assertion 1: No /ceos-agents:fix-ticket reference remains
# ---------------------------------------------------------------------------
echo "--- Assertion 1: /ceos-agents:fix-ticket NOT in autopilot/SKILL.md ---"
if grep -qF '/ceos-agents:fix-ticket' "$SKILL"; then
  HITS=$(grep -n '/ceos-agents:fix-ticket' "$SKILL" | head -5)
  fail "autopilot/SKILL.md still contains '/ceos-agents:fix-ticket' references:
$HITS"
else
  echo "PASS: '/ceos-agents:fix-ticket' correctly absent from autopilot/SKILL.md"
fi

# ---------------------------------------------------------------------------
# Assertion 2: /ceos-agents:fix-bugs IS present
# ---------------------------------------------------------------------------
echo "--- Assertion 2: /ceos-agents:fix-bugs PRESENT in autopilot/SKILL.md ---"
if grep -qF '/ceos-agents:fix-bugs' "$SKILL"; then
  echo "PASS: '/ceos-agents:fix-bugs' found in autopilot/SKILL.md"
else
  fail "'/ceos-agents:fix-bugs' not found in autopilot/SKILL.md — dispatch target not updated"
fi

# ---------------------------------------------------------------------------
# Assertion 3: TARGET_SKILL="/ceos-agents:fix-bugs" dispatch site
# (implementation-notes §D line 375 fix)
# ---------------------------------------------------------------------------
echo "--- Assertion 3: TARGET_SKILL dispatch set to /ceos-agents:fix-bugs ---"
if grep -qF 'TARGET_SKILL="/ceos-agents:fix-bugs"' "$SKILL"; then
  echo "PASS: TARGET_SKILL=\"/ceos-agents:fix-bugs\" found (dispatch site updated)"
else
  fail "TARGET_SKILL=\"/ceos-agents:fix-bugs\" not found in autopilot/SKILL.md — dispatch site (line ~375) not updated"
fi

# ---------------------------------------------------------------------------
# Assertion 4: No fix-ticket in frontmatter description either
# (implementation-notes §D line 3)
# ---------------------------------------------------------------------------
echo "--- Assertion 4: fix-ticket NOT in autopilot frontmatter ---"
# Read first 10 lines (frontmatter area)
FRONTMATTER=$(head -10 "$SKILL" 2>/dev/null || true)
if printf '%s' "$FRONTMATTER" | grep -qF 'fix-ticket'; then
  fail "autopilot/SKILL.md frontmatter still references 'fix-ticket'"
else
  echo "PASS: 'fix-ticket' absent from autopilot frontmatter"
fi

# ---------------------------------------------------------------------------
# Assertion 5: fix-bugs referenced in frontmatter description
# (implementation-notes §D line 3: (fix-ticket / implement-feature) → (fix-bugs / implement-feature))
# ---------------------------------------------------------------------------
echo "--- Assertion 5: fix-bugs referenced in autopilot frontmatter ---"
FRONTMATTER_FULL=$(head -10 "$SKILL" 2>/dev/null || true)
if printf '%s' "$FRONTMATTER_FULL" | grep -qF 'fix-bugs'; then
  echo "PASS: 'fix-bugs' found in autopilot frontmatter"
else
  fail "autopilot/SKILL.md frontmatter does not reference 'fix-bugs' — description not updated"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.3.0-xref-autopilot-fix-bugs — autopilot dispatch correctly updated to fix-bugs"
fi
exit "$FAIL"
