#!/usr/bin/env bash
# Hidden regression tests: v6.4.4 — T13-T14
# Validates: existing test suite unbroken (AC-18), CLAUDE.md config contract unchanged (AC-17, AC-19)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# -----------------------------------------------------------------------
# T13 (AC-18): Existing check-setup-improvements.sh still passes
# -----------------------------------------------------------------------
echo "--- T13 (AC-18): Existing test check-setup-improvements.sh passes ---"

EXISTING_TEST="$REPO_ROOT/tests/scenarios/check-setup-improvements.sh"
if [ ! -f "$EXISTING_TEST" ]; then
  fail "AC-18: test file not found: tests/scenarios/check-setup-improvements.sh"
else
  if bash "$EXISTING_TEST"; then
    echo "OK (AC-18): check-setup-improvements.sh passed"
  else
    fail "AC-18: check-setup-improvements.sh FAILED — v6.4.4 changes introduced a regression"
  fi
fi

# Bonus: also run check-setup-edge-cases.sh if present (mentioned in formal-criteria.md)
EDGE_CASES_TEST="$REPO_ROOT/tests/scenarios/check-setup-edge-cases.sh"
if [ -f "$EDGE_CASES_TEST" ]; then
  if bash "$EDGE_CASES_TEST"; then
    echo "OK (AC-18): check-setup-edge-cases.sh passed"
  else
    fail "AC-18: check-setup-edge-cases.sh FAILED — v6.4.4 changes introduced a regression"
  fi
else
  echo "SKIP (AC-18): check-setup-edge-cases.sh not found — skipping edge cases regression"
fi

# -----------------------------------------------------------------------
# T14 (AC-17, AC-19): No changes to CLAUDE.md config contract
# -----------------------------------------------------------------------
echo "--- T14 (AC-17, AC-19): CLAUDE.md config contract and Input Contracts unchanged ---"

# AC-17: CLAUDE.md must not be modified in the working tree
if ! git -C "$REPO_ROOT" diff --name-only HEAD | grep -q '^CLAUDE\.md$'; then
  echo "OK (AC-17): CLAUDE.md not in git diff — config contract unchanged"
else
  fail "AC-17: CLAUDE.md is modified in the working tree — config contract must not change in a PATCH release"
fi

# AC-19 (part 1): No Input Contract changes in core/ files
input_contract_additions=$(git -C "$REPO_ROOT" diff HEAD -- core/ \
  | sed -n '/## Input Contract/,/## /p' \
  | grep '^+' \
  | grep -v '+++' \
  | grep -v '^+$' \
  || true)

if [ -z "$input_contract_additions" ]; then
  echo "OK (AC-19): No additions to Input Contract sections in core/ files"
else
  fail "AC-19: Input Contract section(s) in core/ modified — PATCH must not change Input Contracts:
$input_contract_additions"
fi

# AC-19 (part 2): CLAUDE.md must not be modified at all
if ! git -C "$REPO_ROOT" diff HEAD -- CLAUDE.md | grep -q .; then
  echo "OK (AC-19): CLAUDE.md not modified — zero breaking changes to config contract"
else
  fail "AC-19: CLAUDE.md has diff output — PATCH release must not change the config contract"
fi

# AC-19 (part 3): error_type must only appear in OUTPUT Contract, not Input Contract
# (Verify the diff adds error_type in the correct section)
error_type_input=$(git -C "$REPO_ROOT" diff HEAD -- core/mcp-detection.md \
  | sed -n '/## Input Contract/,/## /p' \
  | grep '^+.*error_type' \
  || true)

if [ -z "$error_type_input" ]; then
  echo "OK (AC-19): error_type addition is NOT in Input Contract (correct — it belongs in Output Contract)"
else
  fail "AC-19: error_type found in Input Contract diff — it must be in Output Contract / Failure Handling only"
fi

# -----------------------------------------------------------------------
# Final result
# -----------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.4.4 regression — existing tests pass (AC-18), config contract unchanged (AC-17, AC-19)"
fi
exit "$FAIL"
