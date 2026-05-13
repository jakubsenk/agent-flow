#!/bin/bash
# Covers: AC-25 (v8-nf-state-additive-readable.sh deleted),
#         AC-26 (v8-agents-state-additive.sh deleted),
#         AC-35 (v8-nf-v7-project-compat.sh deleted)
# These 3 are Wave-1 atomicity deletions (REQ-9.5-W1-S8b)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: v9-5-wave1-scenarios-deleted — $1"; FAIL=1; }

for scenario in \
  "v8-nf-state-additive-readable.sh" \
  "v8-agents-state-additive.sh" \
  "v8-nf-v7-project-compat.sh"
do
  if [ -f "$REPO_ROOT/tests/scenarios/$scenario" ]; then
    fail "tests/scenarios/$scenario still exists — should be deleted in Wave-1 (v9.5.0)"
  else
    echo "PASS: tests/scenarios/$scenario correctly absent"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-wave1-scenarios-deleted — all 3 Wave-1 deleted scenarios absent"
fi
exit "$FAIL"
