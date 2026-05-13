#!/bin/bash
# Covers: AC-4 (migrate-config absent), AC-5 (estimate absent),
#         AC-6 (pipeline-status absent), AC-7 (scaffold-validate absent)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: v9-5-skills-deleted — $1"; FAIL=1; }

for skill in migrate-config estimate pipeline-status scaffold-validate; do
  if [ -d "$REPO_ROOT/skills/$skill" ]; then
    fail "skills/$skill still exists — should have been deleted in v9.5.0"
  else
    echo "PASS: skills/$skill correctly absent"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-skills-deleted — all 4 deleted skills absent"
fi
exit "$FAIL"
