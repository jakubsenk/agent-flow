#!/usr/bin/env bash
# AC-COUNTS-10, design.md §2.3 (Phase 3 R8 Windows hazard mitigation)
# Asserts that no orphan empty directories exist under skills/ after the v7.0.0
# renames and deletions. Windows git mv can leave empty directories that inflate
# the skill count or otherwise break the 28-directory invariant.
# The expected result: find skills -maxdepth 1 -mindepth 1 -type d -empty | wc -l == 0
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Functional check 1: no orphan empty directories under skills/
empty_dirs=$(find skills -maxdepth 1 -mindepth 1 -type d -empty | wc -l | tr -d ' ')
if [ "$empty_dirs" != "0" ]; then
  echo "FAIL: Found $empty_dirs empty directory(ies) under skills/:" >&2
  find skills -maxdepth 1 -mindepth 1 -type d -empty >&2
  FAIL=1
fi

# Functional check 2: skills/status/ is not an empty orphan (must be fully absent)
if [ -d skills/status ]; then
  fail "skills/status/ still exists (should have been removed by git mv or git rm)"
fi

# Functional check 3: skills/init/ is not an empty orphan (must be fully absent)
if [ -d skills/init ]; then
  fail "skills/init/ still exists (should have been removed by git mv or git rm)"
fi

# Functional check 4: skills/create-pr/ is not an empty orphan (must be fully absent)
if [ -d skills/create-pr ]; then
  fail "skills/create-pr/ still exists (should have been removed by git rm)"
fi

# Functional check 5: total skill directory count is 28 (no inflation from orphan dirs)
skill_count=$(find skills -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
if [ "$skill_count" != "28" ]; then
  fail "skills/ contains $skill_count directories, expected exactly 28"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-COUNTS-10 — no empty orphan directories under skills/; skill count is 28"
exit "$FAIL"
