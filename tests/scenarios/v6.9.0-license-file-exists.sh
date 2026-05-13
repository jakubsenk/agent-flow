#!/usr/bin/env bash
# Scenario: REQ-001, REQ-002 — LICENSE file at repo root with verbatim MIT text + copyright
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

LICENSE="$REPO_ROOT/LICENSE"

# Guard: LICENSE file must exist
if [ ! -f "$LICENSE" ]; then
  echo "FAIL: LICENSE file does not exist at repo root ($LICENSE)" >&2
  exit 1
fi

# Assertion 1 (AC-001): first line must be "MIT License"
echo "--- Assertion 1 (AC-001): 'MIT License' on first line ---"
if grep -q '^MIT License$' "$LICENSE"; then
  echo "OK: LICENSE starts with 'MIT License'"
else
  fail "AC-001: LICENSE does not contain 'MIT License' on its own line (expected verbatim OSI MIT text)"
fi

# Assertion 2 (AC-001): copyright line with correct year range and name
echo "--- Assertion 2 (AC-001): copyright line present ---"
if grep -q 'Copyright (c) 2024-2026 Filip Sabacky' "$LICENSE"; then
  echo "OK: LICENSE contains correct copyright line"
else
  fail "AC-001: LICENSE missing 'Copyright (c) 2024-2026 Filip Sabacky' — expected exact verbatim form"
fi

# Assertion 3 (AC-001): key MIT-required permission grant phrase
echo "--- Assertion 3 (AC-001): permission grant clause present ---"
if grep -q 'Permission is hereby granted, free of charge' "$LICENSE"; then
  echo "OK: LICENSE contains MIT permission grant clause"
else
  fail "AC-001: LICENSE missing canonical MIT permission grant clause"
fi

# Assertion 4 (AC-001): warranty disclaimer present
echo "--- Assertion 4 (AC-001): warranty disclaimer present ---"
if grep -q 'THE SOFTWARE IS PROVIDED "AS IS"' "$LICENSE"; then
  echo "OK: LICENSE contains AS IS warranty disclaimer"
else
  fail "AC-001: LICENSE missing 'THE SOFTWARE IS PROVIDED \"AS IS\"' warranty disclaimer"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 LICENSE file exists with verbatim MIT canonical text and correct copyright"
fi
exit "$FAIL"
