#!/usr/bin/env bash
# Verifies: AC-AGT-006, REQ-AGT-006, REQ-MIG-006
# Description: Legacy customization/triage-analyst.md dispatches to analyst --phase triage
#   with [WARN] "Agent name 'triage-analyst' deprecated; use 'analyst' (removed in v9.0.0)"
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

EXPECTED_WARN="Agent name 'triage-analyst' deprecated; use 'analyst' (removed in v9.0.0)"

# ---------------------------------------------------------------------------
# Assertion 1: fix-bugs SKILL.md documents triage-analyst deprecation alias
# ---------------------------------------------------------------------------
echo "--- Assertion 1: fix-bugs SKILL.md documents triage-analyst deprecation ---"
FIXBUGS_SKILL="$REPO_ROOT/skills/fix-bugs/SKILL.md"
if [ ! -f "$FIXBUGS_SKILL" ]; then
  echo "SKIP: skills/fix-bugs/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'triage-analyst.*deprecated|deprecated.*triage-analyst' "$FIXBUGS_SKILL"; then
  echo "OK: fix-bugs SKILL.md documents triage-analyst deprecation"
else
  fail "fix-bugs SKILL.md missing triage-analyst deprecation documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Exact WARN text documented
# ---------------------------------------------------------------------------
echo "--- Assertion 2: exact WARN text documented ---"
FOUND_WARN=0
for file in "$FIXBUGS_SKILL" \
            "$REPO_ROOT/docs/guides/migration-v7-to-v8.md" \
            "$REPO_ROOT/skills/setup-agents/SKILL.md"; do
  if [ -f "$file" ] && grep -qF "$EXPECTED_WARN" "$file"; then
    echo "OK: '$EXPECTED_WARN' found in $(basename "$file")"
    FOUND_WARN=1
  fi
done
if [ "$FOUND_WARN" -eq 0 ]; then
  fail "Exact WARN text '$EXPECTED_WARN' not found in any file"
fi

# ---------------------------------------------------------------------------
# Assertion 3: Code-analyst deprecation alias also documented
# ---------------------------------------------------------------------------
echo "--- Assertion 3: code-analyst deprecation alias documented ---"
FOUND_CODE_ANALYST=0
for skill in fix-bugs fix-ticket implement-feature; do
  SKILL_FILE="$REPO_ROOT/skills/$skill/SKILL.md"
  if [ -f "$SKILL_FILE" ] && grep -qiE "code-analyst.*deprecated|deprecated.*code-analyst" "$SKILL_FILE"; then
    echo "OK: $skill/SKILL.md documents code-analyst deprecation"
    FOUND_CODE_ANALYST=1
  fi
done
if [ "$FOUND_CODE_ANALYST" -eq 0 ]; then
  fail "code-analyst deprecation alias not documented in any pipeline skill"
fi

# ---------------------------------------------------------------------------
# Assertion 4: v9.0.0 removal documented in migration guide
# ---------------------------------------------------------------------------
echo "--- Assertion 4: v9.0.0 removal timeline documented ---"
MIG_GUIDE="$REPO_ROOT/docs/guides/migration-v7-to-v8.md"
if [ -f "$MIG_GUIDE" ]; then
  if grep -qiE 'v9|removed.*v9|v9.*removed' "$MIG_GUIDE"; then
    echo "OK: migration guide documents v9.0.0 removal"
  else
    fail "migration guide missing v9.0.0 removal timeline"
  fi
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-AGT-006 — triage-analyst deprecation alias with exact WARN text documented"
fi
exit "$FAIL"
