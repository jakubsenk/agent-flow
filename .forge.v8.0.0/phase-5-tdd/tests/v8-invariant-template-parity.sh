#!/usr/bin/env bash
# Verifies: AC-INV-TEMPLATE-001, REQ-INV-003
# Description: .gitea/ and .github/ issue/PR templates are byte-identical pairs
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

# ---------------------------------------------------------------------------
# Pairs to verify (byte-identical)
# ---------------------------------------------------------------------------
check_pair() {
  local left="$1"
  local right="$2"
  local left_full="$REPO_ROOT/$left"
  local right_full="$REPO_ROOT/$right"

  if [ ! -f "$left_full" ]; then
    fail "Missing: $left"
    return
  fi
  if [ ! -f "$right_full" ]; then
    fail "Missing: $right"
    return
  fi

  if diff -q "$left_full" "$right_full" > /dev/null 2>&1; then
    echo "OK: $left == $right (byte-identical)"
  else
    fail "$left and $right differ (not byte-identical)"
    echo "  Diff:"
    diff "$left_full" "$right_full" | head -10 || true
  fi
}

# Issue templates
check_pair ".gitea/issue_template/bug.md" ".github/ISSUE_TEMPLATE/bug.md"
check_pair ".gitea/issue_template/feature.md" ".github/ISSUE_TEMPLATE/feature.md"

# PR template
check_pair ".gitea/pull_request_template.md" ".github/PULL_REQUEST_TEMPLATE.md"

# ---------------------------------------------------------------------------
# Additional: verify .gitea/ directory structure exists
# ---------------------------------------------------------------------------
echo "--- Checking .gitea/ directory structure ---"
if [ -d "$REPO_ROOT/.gitea/issue_template" ]; then
  echo "OK: .gitea/issue_template/ directory exists"
else
  fail ".gitea/issue_template/ directory missing"
fi

if [ -d "$REPO_ROOT/.github/ISSUE_TEMPLATE" ]; then
  echo "OK: .github/ISSUE_TEMPLATE/ directory exists"
else
  fail ".github/ISSUE_TEMPLATE/ directory missing"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-INV-TEMPLATE-001 — .gitea/ and .github/ templates are byte-identical"
fi
exit "$FAIL"
