#!/bin/bash
# Covers: AC-22 (check-setup SKILL.md documents Docker dry-build check: 4 branches + skip-build)
#         AC-23 (check-setup Docker check respects --skip-build)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/skills/check-setup/SKILL.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-check-setup-docker — skills/check-setup/SKILL.md not found"
  exit 1
fi

FAIL=0
fail() { echo "FAIL: v9-5-check-setup-docker — $1"; FAIL=1; }

# AC-22: all 4 branches + skip-build flag
if grep -qF 'docker build --no-cache' "$FILE"; then
  echo "PASS: 'docker build --no-cache' present"
else
  fail "'docker build --no-cache' not found in check-setup SKILL.md"
fi

if grep -qF '[OK] Docker' "$FILE"; then
  echo "PASS: '[OK] Docker' branch present"
else
  fail "'[OK] Docker' not found in check-setup SKILL.md"
fi

if grep -qF '[FAIL] Docker' "$FILE"; then
  echo "PASS: '[FAIL] Docker' branch present"
else
  fail "'[FAIL] Docker' not found in check-setup SKILL.md"
fi

if grep -qF '[SKIP] Docker - no Dockerfile' "$FILE"; then
  echo "PASS: '[SKIP] Docker - no Dockerfile' branch present"
else
  fail "'[SKIP] Docker - no Dockerfile' not found in check-setup SKILL.md"
fi

if grep -qF '[SKIP] Docker - docker binary not found' "$FILE"; then
  echo "PASS: '[SKIP] Docker - docker binary not found' branch present"
else
  fail "'[SKIP] Docker - docker binary not found' not found in check-setup SKILL.md"
fi

# AC-23: --skip-build interaction documented near docker build line
if grep -B2 -A5 'docker build --no-cache' "$FILE" | grep -qF 'skip-build'; then
  echo "PASS: --skip-build interaction documented near docker build command"
else
  fail "--skip-build not referenced near 'docker build --no-cache' in check-setup SKILL.md"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-check-setup-docker — Docker dry-build check fully documented with all branches"
fi
exit "$FAIL"
