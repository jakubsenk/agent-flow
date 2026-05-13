#!/usr/bin/env bash
# Verifies: AC-INV-EMAIL-001, REQ-INV-002
# Description: SECURITY.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md each contain
#   filip.sabacky@ceosdata.com; whitelist check for other email-like tokens
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

EXPECTED_EMAIL="filip.sabacky@ceosdata.com"
EMAIL_REGEX='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
NON_MAINTAINER_CONTEXT_PATTERNS='example\.com|example\.org|example\.net|localhost|noreply@|do-not-reply@'

FILES=("SECURITY.md" "CODE_OF_CONDUCT.md" "CONTRIBUTING.md")

for doc in "${FILES[@]}"; do
  DOC_PATH="$REPO_ROOT/$doc"
  echo "--- Checking $doc ---"

  if [ ! -f "$DOC_PATH" ]; then
    fail "$doc not found"
    continue
  fi

  # Assertion 1: contains filip.sabacky@ceosdata.com
  if grep -qi "$EXPECTED_EMAIL" "$DOC_PATH"; then
    echo "OK: $doc contains $EXPECTED_EMAIL"
  else
    fail "$doc does not contain $EXPECTED_EMAIL"
  fi

  # Assertion 2: whitelist check — every email-like token is either the maintainer email
  # or appears in a non-maintainer context
  echo "  -- whitelist check for $doc --"

  # Extract email-like tokens (line by line)
  FAIL_LOCAL=0
  while IFS= read -r line; do
    # Skip lines that contain non-maintainer context markers
    if echo "$line" | grep -qiE "$NON_MAINTAINER_CONTEXT_PATTERNS"; then
      continue
    fi
    # Skip fenced code blocks beginning with # example or # placeholder
    # (Simplified: skip lines starting with # in code context — advisory)

    # Extract email tokens from this line
    TOKENS=$(echo "$line" | grep -oE "$EMAIL_REGEX" || true)
    if [ -z "$TOKENS" ]; then
      continue
    fi

    while IFS= read -r token; do
      TOKEN_LOWER=$(echo "$token" | tr '[:upper:]' '[:lower:]')
      EXPECTED_LOWER=$(echo "$EXPECTED_EMAIL" | tr '[:upper:]' '[:lower:]')
      if [ "$TOKEN_LOWER" != "$EXPECTED_LOWER" ]; then
        echo "FAIL: $doc — found unexpected email token '$token' outside non-maintainer context"
        FAIL_LOCAL=1
        FAIL=1
      fi
    done <<< "$TOKENS"
  done < "$DOC_PATH"

  if [ "$FAIL_LOCAL" -eq 0 ]; then
    echo "OK: $doc whitelist check passed"
  fi
done

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-INV-EMAIL-001 — maintainer email consistent in all 3 files"
fi
exit "$FAIL"
