#!/usr/bin/env bash
# Scenario: REQ-015, REQ-016 — CODE_OF_CONDUCT.md Contributor Covenant + CONTRIBUTING.md link
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — CODE_OF_CONDUCT.md does not exist yet
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

COC="$REPO_ROOT/CODE_OF_CONDUCT.md"
CONTRIBUTING="$REPO_ROOT/CONTRIBUTING.md"

# Guard: CODE_OF_CONDUCT.md must exist
if [ ! -f "$COC" ]; then
  echo "FAIL: CODE_OF_CONDUCT.md does not exist at repo root — required by REQ-015" >&2
  exit 1
fi

# Assertion 1 (AC-015): Contributor Covenant reference
echo "--- Assertion 1 (AC-015): Contributor Covenant reference ---"
if grep -q 'Contributor Covenant' "$COC"; then
  echo "OK: CODE_OF_CONDUCT.md references Contributor Covenant"
else
  fail "AC-015: CODE_OF_CONDUCT.md missing 'Contributor Covenant' reference"
fi

# Assertion 2 (AC-015): version 2.1 specified
echo "--- Assertion 2 (AC-015): version 2.1 specified ---"
if grep -q 'version 2.1' "$COC"; then
  echo "OK: CODE_OF_CONDUCT.md specifies Contributor Covenant version 2.1"
else
  fail "AC-015: CODE_OF_CONDUCT.md missing 'version 2.1'"
fi

# Assertion 3 (AC-015): conduct contact email present
echo "--- Assertion 3 (AC-015): conduct contact email present ---"
if grep -q 'filip.sabacky@ceosdata.com' "$COC"; then
  echo "OK: CODE_OF_CONDUCT.md lists filip.sabacky@ceosdata.com as contact"
else
  fail "AC-015: CODE_OF_CONDUCT.md missing 'filip.sabacky@ceosdata.com' conduct contact"
fi

# Assertion 4 (AC-015): review SLA 5 business days
echo "--- Assertion 4 (AC-015): enforcement note with 5 business days ---"
if grep -qE '5 business days' "$COC"; then
  echo "OK: CODE_OF_CONDUCT.md has 5 business days enforcement SLA"
else
  fail "AC-015: CODE_OF_CONDUCT.md missing '5 business days' enforcement review SLA"
fi

# Assertion 5 (AC-015): enforcement responses enumerated
echo "--- Assertion 5 (AC-015): enforcement responses include warning, ban ---"
if grep -qE '(warning|temporary ban|permanent ban)' "$COC"; then
  echo "OK: CODE_OF_CONDUCT.md lists enforcement responses (warning/temporary ban/permanent ban)"
else
  fail "AC-015: CODE_OF_CONDUCT.md missing enforcement responses (expected: warning, temporary ban, permanent ban)"
fi

# Assertion 6 (AC-016): CONTRIBUTING.md replaced inline bullets with single link
echo "--- Assertion 6 (AC-016): CONTRIBUTING.md links to CODE_OF_CONDUCT.md ---"
if [ ! -f "$CONTRIBUTING" ]; then
  fail "AC-016: CONTRIBUTING.md not found"
else
  if grep -qF 'See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for the full Code of Conduct.' "$CONTRIBUTING"; then
    echo "OK (AC-016): CONTRIBUTING.md contains single CoC link"
  else
    fail "AC-016: CONTRIBUTING.md missing 'See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for the full Code of Conduct.'"
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 CODE_OF_CONDUCT.md exists with Contributor Covenant 2.1 content; CONTRIBUTING.md updated"
fi
exit "$FAIL"
