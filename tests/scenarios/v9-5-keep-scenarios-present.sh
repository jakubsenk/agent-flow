#!/bin/bash
# Covers: AC-67 (all 7 KEEP scenarios continue to exist)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: v9-5-keep-scenarios-present — $1"; FAIL=1; }

KEEP_SCENARIOS=(
  "ac-v68-cost-resume-backward-compat.sh"
  "v9.2.0-overlay-md-rejected.sh"
  "v8-agents-deleted-old-names.sh"
  "v8-overlay-array-append.sh"
  "v8-overlay-table-deepmerge.sh"
  "v8-overlay-unknown-key.sh"
  "ac-v68-cost-defensive-null.sh"
)

for scenario in "${KEEP_SCENARIOS[@]}"; do
  if [ -f "$REPO_ROOT/tests/scenarios/$scenario" ]; then
    echo "PASS: KEEP scenario tests/scenarios/$scenario exists"
  else
    fail "KEEP scenario tests/scenarios/$scenario is missing — should not have been deleted"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-keep-scenarios-present — all 7 KEEP scenarios still present"
fi
exit "$FAIL"
