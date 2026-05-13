#!/usr/bin/env bash
# Test: All 5 documentation fixes are applied (AC-8 through AC-12)
# AC-8:  fix-verification.md mode-neutral language
# AC-9:  state-manager.md inline heuristic (no forward reference to resume-ticket.md)
# AC-10: state/schema.md e2e_test fields (verdict, result_path, attempts)
# AC-11: fixer-reviewer-loop.md lists all 3 callers for NEEDS_DECOMPOSITION
# AC-12: CLAUDE.md says "15 shared pipeline pattern contracts" (not 14)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# ---------------------------------------------------------------------------
# AC-8: core/fix-verification.md — mode-neutral language
# ---------------------------------------------------------------------------

FIX_VERIFICATION="$REPO_ROOT/core/fix-verification.md"

if [ ! -f "$FIX_VERIFICATION" ]; then
  fail "Missing file: core/fix-verification.md"
else
  # Must NOT contain fix-specific phrases
  if grep -q "Fix verified" "$FIX_VERIFICATION"; then
    fail "core/fix-verification.md: still contains 'Fix verified' — must be changed to 'Verified'"
  fi
  if grep -q "Fix verification failed" "$FIX_VERIFICATION"; then
    fail "core/fix-verification.md: still contains 'Fix verification failed' — must be changed to 'Verification failed'"
  fi
  if grep -q "confirm the fix works" "$FIX_VERIFICATION"; then
    fail "core/fix-verification.md: still contains 'confirm the fix works' — must be changed to 'confirm the changes work'"
  fi

  # Must contain the mode-neutral replacements
  if ! grep -q "Verified" "$FIX_VERIFICATION"; then
    fail "core/fix-verification.md: 'Verified' (success comment) missing — mode-neutral replacement not applied"
  fi
  if ! grep -q "Verification failed" "$FIX_VERIFICATION"; then
    fail "core/fix-verification.md: 'Verification failed' (failure comment) missing — mode-neutral replacement not applied"
  fi
  if ! grep -q "confirm the changes work" "$FIX_VERIFICATION"; then
    fail "core/fix-verification.md: 'confirm the changes work' missing — mode-neutral Purpose line not updated"
  fi
fi

# ---------------------------------------------------------------------------
# AC-9: core/state-manager.md — inline heuristic, no forward reference
# ---------------------------------------------------------------------------

STATE_MANAGER="$REPO_ROOT/core/state-manager.md"

if [ ! -f "$STATE_MANAGER" ]; then
  fail "Missing file: core/state-manager.md"
else
  # Must NOT forward-reference resume-ticket
  if grep -q "resume-ticket" "$STATE_MANAGER"; then
    fail "core/state-manager.md: still contains forward reference to 'resume-ticket' — must be replaced with inline heuristic table"
  fi

  # Must contain the 6 checkpoint states in the inline table
  for checkpoint in "PUBLISHED" "DECOMPOSE_PARTIAL" "POST_REVIEW" "POST_FIX" "POST_ANALYSIS" "POST_TRIAGE"; do
    if ! grep -q "$checkpoint" "$STATE_MANAGER"; then
      fail "core/state-manager.md: heuristic table missing checkpoint '$checkpoint'"
    fi
  done

  # Must contain exactly 6 data rows in the heuristic table
  # Count lines that start with | followed by one of the known checkpoints
  TABLE_ROWS=$(grep -cE "^\| (PUBLISHED|DECOMPOSE_PARTIAL|POST_REVIEW|POST_FIX|POST_ANALYSIS|POST_TRIAGE)" "$STATE_MANAGER" || true)
  if [ "$TABLE_ROWS" -ne 6 ]; then
    fail "core/state-manager.md: heuristic table has $TABLE_ROWS data rows — expected exactly 6"
  fi
fi

# ---------------------------------------------------------------------------
# AC-10: state/schema.md — e2e_test fields verdict, result_path, attempts
# ---------------------------------------------------------------------------

SCHEMA="$REPO_ROOT/state/schema.md"

if [ ! -f "$SCHEMA" ]; then
  fail "Missing file: state/schema.md"
else
  # JSON example block must include all 3 fields
  if ! grep -q '"verdict"' "$SCHEMA"; then
    fail "state/schema.md: JSON example block missing '\"verdict\"' field in e2e_test section"
  fi
  if ! grep -q '"result_path"' "$SCHEMA"; then
    fail "state/schema.md: JSON example block missing '\"result_path\"' field in e2e_test section"
  fi
  if ! grep -q '"attempts"' "$SCHEMA"; then
    fail "state/schema.md: JSON example block missing '\"attempts\"' field in e2e_test section"
  fi

  # Field definition table must include all 3 dotted names
  if ! grep -q "e2e_test\.verdict" "$SCHEMA"; then
    fail "state/schema.md: field definition table missing row 'e2e_test.verdict'"
  fi
  if ! grep -q "e2e_test\.result_path" "$SCHEMA"; then
    fail "state/schema.md: field definition table missing row 'e2e_test.result_path'"
  fi
  if ! grep -q "e2e_test\.attempts" "$SCHEMA"; then
    fail "state/schema.md: field definition table missing row 'e2e_test.attempts'"
  fi
fi

# ---------------------------------------------------------------------------
# AC-11: core/fixer-reviewer-loop.md — all 3 callers listed for NEEDS_DECOMPOSITION
# ---------------------------------------------------------------------------

FIXER_LOOP="$REPO_ROOT/core/fixer-reviewer-loop.md"

if [ ! -f "$FIXER_LOOP" ]; then
  fail "Missing file: core/fixer-reviewer-loop.md"
else
  # All three skill paths must appear in the NEEDS_DECOMPOSITION context
  # Strategy: extract lines around NEEDS_DECOMPOSITION and check for all 3 callers
  DECOMP_CONTEXT=$(grep -A 10 "NEEDS_DECOMPOSITION" "$FIXER_LOOP" || true)

  if [ -z "$DECOMP_CONTEXT" ]; then
    fail "core/fixer-reviewer-loop.md: no context found around 'NEEDS_DECOMPOSITION'"
  else
    if ! echo "$DECOMP_CONTEXT" | grep -q "skills/fix-ticket/SKILL\.md\|fix-ticket"; then
      fail "core/fixer-reviewer-loop.md: NEEDS_DECOMPOSITION section does not reference 'skills/fix-ticket/SKILL.md'"
    fi
    if ! echo "$DECOMP_CONTEXT" | grep -q "skills/fix-bugs/SKILL\.md\|fix-bugs"; then
      fail "core/fixer-reviewer-loop.md: NEEDS_DECOMPOSITION section does not reference 'skills/fix-bugs/SKILL.md'"
    fi
    if ! echo "$DECOMP_CONTEXT" | grep -q "skills/implement-feature/SKILL\.md\|implement-feature"; then
      fail "core/fixer-reviewer-loop.md: NEEDS_DECOMPOSITION section does not reference 'skills/implement-feature/SKILL.md'"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# AC-12: CLAUDE.md — "15 shared pipeline pattern contracts" (not 14)
# ---------------------------------------------------------------------------

CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

if [ ! -f "$CLAUDE_MD" ]; then
  fail "Missing file: CLAUDE.md"
else
  MATCH_15=$(grep -c "15 shared pipeline pattern contracts" "$CLAUDE_MD" || true)
  if [ "$MATCH_15" -ne 1 ]; then
    fail "CLAUDE.md: expected exactly 1 match for '15 shared pipeline pattern contracts', found $MATCH_15"
  fi

  MATCH_14=$(grep -c "14 shared pipeline pattern contracts" "$CLAUDE_MD" || true)
  if [ "$MATCH_14" -ne 0 ]; then
    fail "CLAUDE.md: still contains '14 shared pipeline pattern contracts' — count not updated to 15"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: All 5 documentation fixes applied — fix-verification.md mode-neutral, state-manager.md inline heuristic, state/schema.md e2e_test fields, fixer-reviewer-loop.md all-3-callers, CLAUDE.md 15 contracts (AC-8/AC-9/AC-10/AC-11/AC-12)"
exit "$FAIL"
