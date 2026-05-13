#!/usr/bin/env bash
# v9.3.0 TDD — tests written before implementation
# T-06: make_state_json_bash enum fix (AC-031, AC-032)
#
# Tests that tests/lib/fixtures.sh make_state_json and make_state_json_bash
# use "pending" (valid schema enum) instead of "not_started" (invalid).
#
# RED until Phase 7 fixes the fixture functions — that is correct TDD behavior.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
[ -f "$REPO_ROOT/tests/lib/fixtures.sh" ] || REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

FIXTURES="$REPO_ROOT/tests/lib/fixtures.sh"

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Prerequisite
# ---------------------------------------------------------------------------
if [ ! -f "$FIXTURES" ]; then
  echo "FAIL: tests/lib/fixtures.sh does not exist" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# AC-032: make_state_json_bash DOES NOT contain "not_started"
# ---------------------------------------------------------------------------
echo "--- AC-032: make_state_json_bash does NOT contain 'not_started' ---"
if grep -qF '"not_started"' "$FIXTURES"; then
  fail "AC-032 — tests/lib/fixtures.sh still contains invalid enum value \"not_started\"; replace with \"pending\""
else
  echo "PASS: 'not_started' enum value correctly absent from fixtures.sh"
fi

# ---------------------------------------------------------------------------
# AC-032: make_state_json_bash DOES contain "pending" as initial status
# ---------------------------------------------------------------------------
echo "--- AC-032: make_state_json_bash DOES contain 'pending' ---"
if grep -qF '"pending"' "$FIXTURES"; then
  echo "PASS: \"pending\" enum value found in fixtures.sh"
else
  fail "AC-032 — tests/lib/fixtures.sh does not contain \"pending\"; make_state_json_bash not fixed"
fi

# ---------------------------------------------------------------------------
# AC-031 (jq variant): make_state_json function does not contain "not_started"
# The jq variant is in the make_state_json() function (not bash variant).
# We check that the literal not_started string is absent from the whole file.
# (Both variants are in the same file — AC-031 and AC-032 collapse to the same assertion.)
# ---------------------------------------------------------------------------
echo "--- AC-031: make_state_json (jq variant) does NOT contain 'not_started' ---"
# Already checked above — not_started must be absent from the whole file
if ! grep -qF '"not_started"' "$FIXTURES" 2>/dev/null; then
  echo "PASS: no 'not_started' occurrences in fixtures.sh (both variants fixed)"
else
  fail "AC-031/AC-032 — 'not_started' still present in fixtures.sh"
fi

# ---------------------------------------------------------------------------
# AC-033: Duplicate-key concatenation mechanism preserved (lines ~91-97)
# The mechanism uses base_no_close + override_inner concat.
# We verify the key structural elements are still present.
# ---------------------------------------------------------------------------
echo "--- AC-033: Duplicate-key concatenation mechanism preserved ---"
if grep -qF 'override_inner' "$FIXTURES"; then
  echo "PASS: override_inner variable found (concat mechanism present)"
else
  fail "AC-033 — override_inner variable not found; duplicate-key concatenation mechanism may have been removed"
fi

if grep -qF 'base_no_close' "$FIXTURES"; then
  echo "PASS: base_no_close variable found (concat mechanism present)"
else
  fail "AC-033 — base_no_close variable not found; duplicate-key concatenation mechanism may have been removed"
fi

if grep -qF 'RFC 8259' "$FIXTURES" || grep -qF 'last-write-wins' "$FIXTURES"; then
  echo "PASS: RFC 8259 / last-write-wins comment preserved"
else
  fail "AC-033 — RFC 8259 / last-write-wins comment not found; duplicate-key mechanism comment may have been removed"
fi

# ---------------------------------------------------------------------------
# Functional test: make_state_json_bash output does not contain not_started
# ---------------------------------------------------------------------------
echo "--- Functional: make_state_json_bash output does not contain not_started ---"
SCRATCH="$(setup_scratch)"
trap "rm -rf '$SCRATCH'" EXIT

OUTPUT=$(make_state_json_bash 2>/dev/null || echo "ERROR")
if printf '%s' "$OUTPUT" | grep -qF 'not_started'; then
  fail "Functional — make_state_json_bash output still contains 'not_started'"
else
  echo "PASS: make_state_json_bash output does not contain 'not_started'"
fi

# Also verify "pending" appears in the output (in fixer_reviewer status field)
if printf '%s' "$OUTPUT" | grep -qF '"pending"'; then
  echo "PASS: make_state_json_bash output contains 'pending'"
else
  fail "Functional — make_state_json_bash output does not contain 'pending' as expected enum value"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.3.0-fixtures-make-state-json — all fixture enum fix checks passed"
fi
exit "$FAIL"
