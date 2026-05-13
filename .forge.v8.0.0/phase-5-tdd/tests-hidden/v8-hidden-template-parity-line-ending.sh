#!/usr/bin/env bash
# Hidden adversarial test — do NOT reference in spec/visible
# Tests: CRLF vs LF line ending mismatch between .gitea/ and .github/ template pair
# byte-identical check must detect this difference
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT INT TERM

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Setup: create LF and CRLF versions of "same" template
# ---------------------------------------------------------------------------
mkdir -p "$TMPDIR_TEST/gitea" "$TMPDIR_TEST/github"

# LF version
printf '# Bug Report\n\n## Description\n' > "$TMPDIR_TEST/gitea/bug.md"

# CRLF version (Windows line endings)
printf '# Bug Report\r\n\r\n## Description\r\n' > "$TMPDIR_TEST/github/bug.md"

# ---------------------------------------------------------------------------
# Assertion 1: diff -q detects CRLF vs LF difference
# ---------------------------------------------------------------------------
echo "--- Assertion 1: diff -q detects CRLF vs LF difference ---"
if diff -q "$TMPDIR_TEST/gitea/bug.md" "$TMPDIR_TEST/github/bug.md" > /dev/null 2>&1; then
  fail "diff -q did NOT detect CRLF vs LF difference (byte-identical check broken)"
else
  echo "OK: diff -q correctly detects CRLF vs LF mismatch"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Identical content (same LF endings) passes diff -q
# ---------------------------------------------------------------------------
echo "--- Assertion 2: identical LF files pass diff -q ---"
printf '# Bug Report\n\n## Description\n' > "$TMPDIR_TEST/github/bug-lf.md"
cp "$TMPDIR_TEST/gitea/bug.md" "$TMPDIR_TEST/gitea/bug-lf-copy.md"

if diff -q "$TMPDIR_TEST/gitea/bug-lf-copy.md" "$TMPDIR_TEST/github/bug-lf.md" > /dev/null 2>&1; then
  echo "OK: identical LF files pass diff -q"
else
  fail "Identical LF files did not pass diff -q (byte-identical check broken)"
fi

# ---------------------------------------------------------------------------
# Assertion 3: Real .gitea and .github templates are byte-identical
# ---------------------------------------------------------------------------
echo "--- Assertion 3: real .gitea/ and .github/ templates are byte-identical ---"
GITEA_BUG="$REPO_ROOT/.gitea/issue_template/bug.md"
GITHUB_BUG="$REPO_ROOT/.github/ISSUE_TEMPLATE/bug.md"

if [ -f "$GITEA_BUG" ] && [ -f "$GITHUB_BUG" ]; then
  if diff -q "$GITEA_BUG" "$GITHUB_BUG" > /dev/null 2>&1; then
    echo "OK: real bug.md templates are byte-identical (same line endings)"
  else
    fail "Real bug.md templates differ — possible CRLF/LF mismatch"
  fi
else
  echo "INFO: real template files not present yet (implementation pending)"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: CRLF/LF mismatch detection works; real templates byte-identical"
fi
exit "$FAIL"
