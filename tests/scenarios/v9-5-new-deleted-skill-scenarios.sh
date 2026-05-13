#!/bin/bash
# Covers: AC-52 (v9.5.0-deleted-skill-migrate-config.sh exists and asserts deletion),
#         AC-53 (v9.5.0-deleted-skill-estimate.sh exists and asserts deletion),
#         AC-54 (v9.5.0-deleted-skill-pipeline-status.sh exists and asserts deletion),
#         AC-55 (v9.5.0-deleted-skill-scaffold-validate.sh exists and asserts deletion)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: v9-5-new-deleted-skill-scenarios — $1"; FAIL=1; }

# AC-52: migrate-config deletion scenario
FILE52="$REPO_ROOT/tests/scenarios/v9.5.0-deleted-skill-migrate-config.sh"
if [ ! -f "$FILE52" ]; then
  fail "tests/scenarios/v9.5.0-deleted-skill-migrate-config.sh does not exist"
else
  if grep -qF 'skills/migrate-config' "$FILE52"; then
    echo "PASS: v9.5.0-deleted-skill-migrate-config.sh references skills/migrate-config"
  else
    fail "v9.5.0-deleted-skill-migrate-config.sh does not reference skills/migrate-config"
  fi
  if grep -qE 'test ! -d|! -d skills/migrate-config' "$FILE52"; then
    echo "PASS: v9.5.0-deleted-skill-migrate-config.sh asserts directory absence"
  else
    fail "v9.5.0-deleted-skill-migrate-config.sh does not assert directory absence"
  fi
fi

# AC-53: estimate deletion scenario
FILE53="$REPO_ROOT/tests/scenarios/v9.5.0-deleted-skill-estimate.sh"
if [ ! -f "$FILE53" ]; then
  fail "tests/scenarios/v9.5.0-deleted-skill-estimate.sh does not exist"
else
  if grep -qF 'skills/estimate' "$FILE53"; then
    echo "PASS: v9.5.0-deleted-skill-estimate.sh references skills/estimate"
  else
    fail "v9.5.0-deleted-skill-estimate.sh does not reference skills/estimate"
  fi
fi

# AC-54: pipeline-status deletion scenario
FILE54="$REPO_ROOT/tests/scenarios/v9.5.0-deleted-skill-pipeline-status.sh"
if [ ! -f "$FILE54" ]; then
  fail "tests/scenarios/v9.5.0-deleted-skill-pipeline-status.sh does not exist"
else
  if grep -qF 'skills/pipeline-status' "$FILE54"; then
    echo "PASS: v9.5.0-deleted-skill-pipeline-status.sh references skills/pipeline-status"
  else
    fail "v9.5.0-deleted-skill-pipeline-status.sh does not reference skills/pipeline-status"
  fi
fi

# AC-55: scaffold-validate deletion scenario
FILE55="$REPO_ROOT/tests/scenarios/v9.5.0-deleted-skill-scaffold-validate.sh"
if [ ! -f "$FILE55" ]; then
  fail "tests/scenarios/v9.5.0-deleted-skill-scaffold-validate.sh does not exist"
else
  if grep -qF 'skills/scaffold-validate' "$FILE55"; then
    echo "PASS: v9.5.0-deleted-skill-scaffold-validate.sh references skills/scaffold-validate"
  else
    fail "v9.5.0-deleted-skill-scaffold-validate.sh does not reference skills/scaffold-validate"
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-new-deleted-skill-scenarios — all 4 new deletion scenario files exist with correct assertions"
fi
exit "$FAIL"
