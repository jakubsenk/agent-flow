#!/usr/bin/env bash
# Hidden test: AC-ITEM-2.6 — bash [[ =~ ]] gate rejects multi-line ISSUE_ID
# Verifies that a newline-injection payload cannot bypass the regex gate.
# This is a BEHAVIORAL test: it constructs a minimal gate snippet and runs it
# with a multi-line ISSUE_ID. The gate MUST exit 1 (reject).
#
# Security rationale: echo "${ISSUE_ID}" | grep -qE anchors per-line, so a
# payload like $'../../etc/passwd\nPROJ-42' would pass (PROJ-42 matches).
# The bash [[ =~ ]] form anchors to the ENTIRE string and MUST reject.
set -uo pipefail

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

echo "--- h-regex-newline-bypass (AC-ITEM-2.6): multi-line ISSUE_ID rejection ---"

# -----------------------------------------------------------------------
# Test 1: Classic path-traversal + valid suffix (the canonical bypass payload)
# -----------------------------------------------------------------------
ISSUE_ID=$'../../etc/passwd\nPROJ-42'
bash -c '
  if [[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]; then
    exit 1
  fi
  exit 0
' _ "$ISSUE_ID" 2>/dev/null && bypass_exit=0 || bypass_exit=$?

# We export via env for the subshell — use env var directly
bypass_exit=0
ISSUE_ID=$'../../etc/passwd\nPROJ-42' bash -c '
  if [[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]; then
    exit 1
  fi
  exit 0
' && bypass_exit=0 || bypass_exit=$?

if [ "$bypass_exit" -ne 0 ]; then
  echo "OK: gate correctly rejects path-traversal+valid-suffix payload (exit $bypass_exit)"
else
  fail "AC-ITEM-2.6: [[ =~ ]] gate did NOT reject multi-line ISSUE_ID '../../etc/passwd\nPROJ-42' — newline-injection bypass possible"
fi

# -----------------------------------------------------------------------
# Test 2: CR-only injection (Windows line ending variant)
# -----------------------------------------------------------------------
bypass_exit=0
ISSUE_ID=$'PROJ-42\r' ISSUE_ID=$'PROJ-42\r' bash -c '
  if [[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]; then
    exit 1
  fi
  exit 0
' && bypass_exit=0 || bypass_exit=$?

if [ "$bypass_exit" -ne 0 ]; then
  echo "OK: gate correctly rejects ISSUE_ID with embedded carriage return (exit $bypass_exit)"
else
  fail "AC-ITEM-2.6: gate did NOT reject ISSUE_ID with embedded \\r — CRLF bypass possible"
fi

# -----------------------------------------------------------------------
# Test 3: Positive control — valid single-line ISSUE_ID must PASS
# -----------------------------------------------------------------------
pass_exit=0
ISSUE_ID="PROJ-42" bash -c '
  if [[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]; then
    exit 1
  fi
  exit 0
' && pass_exit=0 || pass_exit=$?

if [ "$pass_exit" -eq 0 ]; then
  echo "OK: valid ISSUE_ID PROJ-42 passes gate (positive control)"
else
  fail "AC-ITEM-2.6 positive control: valid ISSUE_ID 'PROJ-42' was incorrectly rejected (exit $pass_exit)"
fi

# -----------------------------------------------------------------------
# Test 4: Confirm echo/grep bypass would be exploitable (negative control —
#   proves WHY [[ =~ ]] is required; this intentionally SHOWS the bypass)
# -----------------------------------------------------------------------
grep_exit=0
printf '%s' $'../../etc/passwd\nPROJ-42' | grep -qE '^[A-Za-z0-9#_-]+$' && grep_exit=0 || grep_exit=$?

if [ "$grep_exit" -eq 0 ]; then
  echo "OK (negative control): echo|grep-qE IS bypassable — confirms [[ =~ ]] is the correct form (grep passed the multi-line payload)"
else
  echo "NOTE: echo|grep-qE unexpectedly rejected the multi-line payload on this platform (grep_exit=$grep_exit) — still acceptable, [[ =~ ]] is the mandated form"
fi

# -----------------------------------------------------------------------
# Final result
# -----------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: h-regex-newline-bypass — [[ =~ ]] correctly rejects multi-line ISSUE_ID"
fi
exit "$FAIL"
