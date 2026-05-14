#!/bin/bash
# Covers: AC-45 (v8-doc-skills-enumeration.sh removes 4 deleted skills),
#         AC-46 (v8-invariant-doc-enumeration-parity.sh removes 4 deleted skills),
#         AC-47 (v9.3.0-doc-count-sync.sh checks 18 not 22),
#         AC-48 (regression-skill-count-29.sh count = 18),
#         AC-49 (sprint-counts.sh -ne 18, not -ne 22),
#         AC-50 (v6.9.0-doc-count-drift.sh -eq 18 not -eq 22),
#         AC-51 (happy-path.sh lower-bound = 18)
# Skills reduced from 22 to 18; post-cleanup baseline.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: v9-5-doc-enumeration-tests-updated — $1"; FAIL=1; }

# AC-45: v8-doc-skills-enumeration.sh
FILE45="$REPO_ROOT/tests/scenarios/v8-doc-skills-enumeration.sh"
if [ ! -f "$FILE45" ]; then
  fail "tests/scenarios/v8-doc-skills-enumeration.sh not found"
else
  if grep -qE '"(migrate-config|estimate|pipeline-status|scaffold-validate)"' "$FILE45"; then
    fail "v8-doc-skills-enumeration.sh still references deleted skills"
  else
    echo "PASS: deleted skills absent from v8-doc-skills-enumeration.sh"
  fi
fi

# AC-46: v8-invariant-doc-enumeration-parity.sh
FILE46="$REPO_ROOT/tests/scenarios/v8-invariant-doc-enumeration-parity.sh"
if [ ! -f "$FILE46" ]; then
  fail "tests/scenarios/v8-invariant-doc-enumeration-parity.sh not found"
else
  if grep -qE '"(migrate-config|estimate|pipeline-status|scaffold-validate)"' "$FILE46"; then
    fail "v8-invariant-doc-enumeration-parity.sh still references deleted skills"
  else
    echo "PASS: deleted skills absent from v8-invariant-doc-enumeration-parity.sh"
  fi
fi

# AC-47: v9.3.0-doc-count-sync.sh
FILE47="$REPO_ROOT/tests/scenarios/v9.3.0-doc-count-sync.sh"
if [ ! -f "$FILE47" ]; then
  fail "tests/scenarios/v9.3.0-doc-count-sync.sh not found"
else
  if grep -qE '18.*[Ss]kill|[Ss]kill.*18|-eq 18' "$FILE47"; then
    echo "PASS: v9.3.0-doc-count-sync.sh checks for 18"
  else
    fail "v9.3.0-doc-count-sync.sh does not check for 18"
  fi
  if grep -qE '-eq 22|-ne 22|expected.*22 skill' "$FILE47"; then
    fail "v9.3.0-doc-count-sync.sh still checks for 22"
  else
    echo "PASS: 22-check absent from v9.3.0-doc-count-sync.sh"
  fi
fi

# AC-48: regression-skill-count-29.sh
FILE48="$REPO_ROOT/tests/scenarios/regression-skill-count-29.sh"
if [ ! -f "$FILE48" ]; then
  fail "tests/scenarios/regression-skill-count-29.sh not found"
else
  if grep -qE '\-ne 18|expected exactly 18' "$FILE48"; then
    echo "PASS: regression-skill-count-29.sh expects 18 skills"
  else
    fail "regression-skill-count-29.sh does not expect 18 skills"
  fi
  if grep -qE '\-ne 22|expected exactly 22' "$FILE48"; then
    fail "regression-skill-count-29.sh still expects 22"
  else
    echo "PASS: 22-expectation absent from regression-skill-count-29.sh"
  fi
fi

# AC-49: sprint-counts.sh
FILE49="$REPO_ROOT/tests/scenarios/sprint-counts.sh"
if [ ! -f "$FILE49" ]; then
  fail "tests/scenarios/sprint-counts.sh not found"
else
  MATCH18=$(grep -c '\-ne 18' "$FILE49" 2>/dev/null || echo 0)
  if [ "$MATCH18" -ge 2 ]; then
    echo "PASS: sprint-counts.sh has at least 2 occurrences of '-ne 18'"
  else
    fail "sprint-counts.sh has fewer than 2 occurrences of '-ne 18' (found: $MATCH18)"
  fi
  if grep -qF '\-ne 22' "$FILE49"; then
    fail "sprint-counts.sh still has '-ne 22'"
  else
    echo "PASS: '-ne 22' absent from sprint-counts.sh"
  fi
fi

# AC-50: v6.9.0-doc-count-drift.sh
FILE50="$REPO_ROOT/tests/scenarios/v6.9.0-doc-count-drift.sh"
if [ ! -f "$FILE50" ]; then
  fail "tests/scenarios/v6.9.0-doc-count-drift.sh not found"
else
  if grep -qE '\-eq 18|expected 18' "$FILE50"; then
    echo "PASS: v6.9.0-doc-count-drift.sh checks for 18"
  else
    fail "v6.9.0-doc-count-drift.sh does not check for -eq 18"
  fi
  if grep -qE '\-eq 22|expected 22 skill' "$FILE50"; then
    fail "v6.9.0-doc-count-drift.sh still checks for 22"
  else
    echo "PASS: '-eq 22' absent from v6.9.0-doc-count-drift.sh"
  fi
fi

# AC-51: happy-path.sh
FILE51="$REPO_ROOT/tests/scenarios/happy-path.sh"
if [ ! -f "$FILE51" ]; then
  fail "tests/scenarios/happy-path.sh not found"
else
  if grep -qE '\-lt 18|expected.*>=.*18' "$FILE51"; then
    echo "PASS: happy-path.sh lower-bound is 18"
  else
    fail "happy-path.sh does not have lower-bound of 18 (-lt 18)"
  fi
  if grep -qE '\-lt 22|expected.*>=.*22' "$FILE51"; then
    fail "happy-path.sh still has lower-bound of 22"
  else
    echo "PASS: '-lt 22' absent from happy-path.sh"
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-doc-enumeration-tests-updated — all 7 doc/count test scenarios updated for 18 skills"
fi
exit "$FAIL"
