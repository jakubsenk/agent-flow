#!/bin/bash
# Covers: AC-CNT-1 (CLAUDE.md states 18 skills),
#         AC-CNT-2 (README.md states 18 skills),
#         AC-CNT-3 (all 5 count-bearing docs reference 17 core),
#         AC-CNT-4 (no production claim of 22 skills or 16 core)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: v9-5-doc-count-sync — $1"; FAIL=1; }

# AC-CNT-1: CLAUDE.md states 18 skills
if grep -qE '\b18 skills\b|skills.*\b18\b|18\b.*skills' "$REPO_ROOT/CLAUDE.md"; then
  echo "PASS: CLAUDE.md references 18 skills"
else
  fail "CLAUDE.md does not reference 18 skills"
fi

# AC-CNT-2: README.md states 18 skills
if grep -qE '\b18 skills\b|skills.*\b18\b|18\b.*skills' "$REPO_ROOT/README.md"; then
  echo "PASS: README.md references 18 skills"
else
  fail "README.md does not reference 18 skills"
fi

# AC-CNT-3: All 5 docs reference 17 core
for f in CLAUDE.md README.md docs/reference/automation-config.md docs/reference/skills.md docs/architecture.md; do
  if grep -qE '17[[:space:]]+(core|shared pipeline|contracts)' "$REPO_ROOT/$f"; then
    echo "PASS: $f references 17 core"
  else
    fail "$f does not reference 17 core / 17 contracts / 17 shared pipeline"
  fi
done

# AC-CNT-4: No stale "22 skills" or "16 core" in production docs
COUNT=$(grep -rn '\b22 skills\b\|\b16 core\b\|\b16 contracts\b' \
  --include='*.md' \
  "$REPO_ROOT/CLAUDE.md" "$REPO_ROOT/README.md" "$REPO_ROOT/docs/" \
  2>/dev/null \
  | grep -v 'CHANGELOG.md' \
  | grep -v 'docs/plans/' \
  | wc -l | tr -d ' ')

if [ "$COUNT" -eq 0 ]; then
  echo "PASS: no stale '22 skills' or '16 core' claims in production docs"
else
  echo "FAIL: v9-5-doc-count-sync — found $COUNT stale count claim(s) in production docs"
  grep -rn '\b22 skills\b\|\b16 core\b\|\b16 contracts\b' \
    --include='*.md' \
    "$REPO_ROOT/CLAUDE.md" "$REPO_ROOT/README.md" "$REPO_ROOT/docs/" \
    2>/dev/null \
    | grep -v 'CHANGELOG.md' \
    | grep -v 'docs/plans/' \
    || true
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-doc-count-sync — all 5 docs correctly reference 18 skills and 17 core"
fi
exit "$FAIL"
