#!/usr/bin/env bash
# AC-COUNTS-2, AC-COUNTS-3, AC-COUNTS-5, AC-COUNTS-9
# Asserts all anchor files show "18 optional config sections" (not 19).
# Also verifies agent count remains 21 (unchanged by v7.0.0 actions).
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Functional check 1: CLAUDE.md has "18 optional config sections in total", not 19
if ! grep -qF '18 optional config sections in total' CLAUDE.md 2>/dev/null; then
  fail "CLAUDE.md: '18 optional config sections in total' not found"
fi
if grep -qF '19 optional config sections in total' CLAUDE.md 2>/dev/null; then
  fail "CLAUDE.md: stale '19 optional config sections in total' still present"
fi

# Functional check 2: README.md has "18 optional sections", not 19
if ! grep -qF '18 optional sections' README.md 2>/dev/null; then
  fail "README.md: '18 optional sections' not found"
fi
if grep -qE '\b19 optional sections\b' README.md 2>/dev/null; then
  fail "README.md: stale '19 optional sections' still present"
fi

# Functional check 3: docs/reference/automation-config.md has "18 optional sections"
if ! grep -qF '18 optional sections' docs/reference/automation-config.md 2>/dev/null; then
  fail "docs/reference/automation-config.md: '18 optional sections' not found"
fi
if grep -qE '\b19 optional sections\b' docs/reference/automation-config.md 2>/dev/null; then
  fail "docs/reference/automation-config.md: stale '19 optional sections' still present"
fi

# Functional check 4: agent count remains 21 (v7.0.0 must NOT change agents)
agent_count=$(find agents -maxdepth 1 -mindepth 1 -name '*.md' | wc -l | tr -d ' ')
if [ "$agent_count" != "21" ]; then
  fail "Filesystem: found $agent_count agent .md files under agents/, expected 21"
fi

# Functional check 5: v6.9.0-bc-no-renamed-section.sh mutation guard updated to 18
# (cross-check that the companion test was updated per design.md §7)
if ! grep -qE '\-eq 18' tests/scenarios/v6.9.0-bc-no-renamed-section.sh 2>/dev/null; then
  fail "tests/scenarios/v6.9.0-bc-no-renamed-section.sh: mutation guard not updated to -eq 18"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-COUNTS-2,3,5,9 — all anchor files show 18 optional sections; agent count stable at 21"
exit "$FAIL"
