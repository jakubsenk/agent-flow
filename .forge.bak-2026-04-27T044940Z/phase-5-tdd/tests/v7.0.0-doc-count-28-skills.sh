#!/usr/bin/env bash
# AC-COUNTS-1, AC-COUNTS-3, AC-COUNTS-4, AC-COUNTS-6, AC-COUNTS-7, AC-COUNTS-8
# Asserts all 5 anchor files (CLAUDE.md, README.md, docs/reference/skills.md,
# docs/architecture.md, docs/getting-started.md) show "28 skills" and NOT "29 skills".
# Also verifies filesystem skill directory count is exactly 28.
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Functional check 1: CLAUDE.md has "28 skills", not "29 skills"
if ! grep -qF '28 skills' CLAUDE.md 2>/dev/null; then
  fail "CLAUDE.md: '28 skills' not found"
fi
if grep -qE '\b29 skills\b' CLAUDE.md 2>/dev/null; then
  fail "CLAUDE.md: stale '29 skills' still present"
fi

# Functional check 2: README.md has "28 skills", not "29 skills"
if ! grep -qF '28 skills' README.md 2>/dev/null; then
  fail "README.md: '28 skills' not found"
fi
if grep -qE '\b29 skills\b' README.md 2>/dev/null; then
  fail "README.md: stale '29 skills' still present"
fi

# Functional check 3: docs/reference/skills.md has "all 28 skills", not "all 29 skills"
if ! grep -qE 'all 28 skills' docs/reference/skills.md 2>/dev/null; then
  fail "docs/reference/skills.md: 'all 28 skills' not found"
fi
if grep -qE '\ball 29 skills\b' docs/reference/skills.md 2>/dev/null; then
  fail "docs/reference/skills.md: stale 'all 29 skills' still present"
fi

# Functional check 4: docs/architecture.md has SKL[28 Skills], not SKL[29 Skills]
if ! grep -qF 'SKL[28 Skills]' docs/architecture.md 2>/dev/null; then
  fail "docs/architecture.md: 'SKL[28 Skills]' mermaid label not found"
fi
if grep -qF 'SKL[29 Skills]' docs/architecture.md 2>/dev/null; then
  fail "docs/architecture.md: stale 'SKL[29 Skills]' still present"
fi

# Functional check 5: docs/getting-started.md has "all 28 skills"
if ! grep -qF 'all 28 skills' docs/getting-started.md 2>/dev/null; then
  fail "docs/getting-started.md: 'all 28 skills' not found"
fi
if grep -qF 'all 29 skills' docs/getting-started.md 2>/dev/null; then
  fail "docs/getting-started.md: stale 'all 29 skills' still present"
fi

# Functional check 6: filesystem skill directory count is exactly 28
skill_count=$(find skills -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
if [ "$skill_count" != "28" ]; then
  fail "Filesystem: found $skill_count skill directories under skills/, expected 28"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-COUNTS-1,3,4,6,7,8 — all anchor files show 28 skills; filesystem count is 28"
exit "$FAIL"
