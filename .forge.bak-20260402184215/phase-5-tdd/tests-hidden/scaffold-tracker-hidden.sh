#!/bin/bash
# Test: scaffold tracker integration — hidden edge-case assertions
# Validates: AC-4.3 (missing Done WARN), AC-2.2 (GitHub/Gitea fallback naming),
#            AC-8.1 (Final Report closed count), REQ-6 Done mapping presence
# Expected: ALL assertions FAIL before implementation, PASS after.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCAFFOLD_SKILL="$REPO_ROOT/skills/scaffold/SKILL.md"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# =============================================================================
# EDGE CASE 1: Step 8b skips with WARN when no "Done" mapping exists (AC-4.3)
# =============================================================================

# The WARN message must reference the exact phrase from AC-4.3
if ! grep -q "does not include a 'Done' mapping. Skipping issue closure\|does not include a 'Done' mapping" "$SCAFFOLD_SKILL"; then
  fail "AC-4.3: Step 8b missing WARN text for absent Done mapping ('does not include a .Done. mapping')"
fi

# WARN keyword must precede (be on same line or nearby) the Done mapping check
# This verifies the guard fires as a WARN, not a hard stop
DONE_WARN_LINE=$(grep -n "does not include a 'Done' mapping" "$SCAFFOLD_SKILL" | head -1 | cut -d: -f1)
if [ -n "$DONE_WARN_LINE" ]; then
  CONTEXT=$(sed -n "$((DONE_WARN_LINE - 3)),$((DONE_WARN_LINE + 3))p" "$SCAFFOLD_SKILL")
  if ! echo "$CONTEXT" | grep -qi 'WARN\|warn\|skip\|Skip'; then
    fail "AC-4.3: 'Done' mapping missing message not marked as WARN or skip"
  fi
fi

# =============================================================================
# EDGE CASE 2: GitHub/Gitea fallback uses standalone issue naming (AC-2.2)
# =============================================================================

# Fallback title must use [{epic_title}] prefix
if ! grep -q '\[{epic_title}\]' "$SCAFFOLD_SKILL"; then
  fail "AC-2.2: Step 4e missing GitHub/Gitea fallback title '[{epic_title}] {story_title}'"
fi

# Fallback must be conditional on tracker type (not always applied)
FALLBACK_LINE=$(grep -n '\[{epic_title}\]' "$SCAFFOLD_SKILL" | head -1 | cut -d: -f1)
if [ -n "$FALLBACK_LINE" ]; then
  CONTEXT=$(sed -n "$((FALLBACK_LINE - 10)),$((FALLBACK_LINE + 3))p" "$SCAFFOLD_SKILL")
  if ! echo "$CONTEXT" | grep -qi 'GitHub\|Gitea\|github\|gitea\|fallback\|does not support'; then
    fail "AC-2.2: '[{epic_title}]' title format not guarded by GitHub/Gitea tracker check"
  fi
fi

# =============================================================================
# EDGE CASE 3: Step 9 Final Report includes closed-issues count (AC-8.1)
# =============================================================================

# "issues closed" must appear in Final Report section (Step 9)
STEP9_LINE=$(grep -n "Step 9: Final Report\|### Step 9" "$SCAFFOLD_SKILL" | head -1 | cut -d: -f1)
if [ -z "$STEP9_LINE" ]; then
  fail "AC-8.1: 'Step 9: Final Report' not found — cannot verify closed count placement"
else
  # Closed count must appear in (or after) Step 9 section
  CLOSED_LINE=$(grep -n 'issues closed' "$SCAFFOLD_SKILL" | head -1 | cut -d: -f1)
  if [ -z "$CLOSED_LINE" ]; then
    fail "AC-8.1: 'issues closed' text not found in SKILL.md at all"
  elif [ "$CLOSED_LINE" -lt "$STEP9_LINE" ]; then
    fail "AC-8.1: 'issues closed' (line $CLOSED_LINE) appears before Step 9 (line $STEP9_LINE) — must be in Final Report"
  fi
fi

# Tracker line in Final Report must include closed count format
if ! grep -qE 'epics created.*issues closed|issues closed' "$SCAFFOLD_SKILL"; then
  fail "AC-8.1: Final Report tracker line missing 'issues closed' count alongside epics"
fi

# =============================================================================
# EDGE CASE 4: Example configs have Done mapping (spot-check references)
# =============================================================================

# At least one example config must contain a Done mapping (validates REQ-6 is not empty)
DONE_COUNT=0
for config in "$REPO_ROOT/examples/configs/"*.md; do
  if grep -qE 'Done:' "$config" 2>/dev/null; then
    DONE_COUNT=$((DONE_COUNT + 1))
  fi
done

if [ "$DONE_COUNT" -lt 6 ]; then
  fail "REQ-6: Expected at least 6 example configs with Done mapping, found $DONE_COUNT"
fi

# redmine-rails.md must not have been modified (pre-existing value)
if ! grep -qE 'Done:.*status:Closed' "$REPO_ROOT/examples/configs/redmine-rails.md"; then
  fail "REQ-6/AC-6.2: redmine-rails.md 'Done: status:Closed' removed or modified — must remain unchanged"
fi

# =============================================================================
# EDGE CASE 5: Negative assertions — things that must NOT appear (BC-8 through BC-11)
# =============================================================================

# BC-8: Step 7e must NOT appear in SKILL.md
if grep -q 'Step 7e' "$SCAFFOLD_SKILL"; then
  fail "BC-8: Step 7e must NOT appear in SKILL.md (brainstorm rejected this numbering)"
fi

# BC-9: 'On complete' must NOT appear as a new config key
if grep -q 'On complete' "$SCAFFOLD_SKILL"; then
  fail "BC-9: 'On complete' config key must NOT appear — Done is read from existing State transitions"
fi

# BC-10: tracker_issues must NOT appear as a state.json field reference
if grep -q 'tracker_issues' "$SCAFFOLD_SKILL"; then
  fail "BC-10: 'tracker_issues' state.json field must NOT appear — no state.json persistence of issue IDs"
fi

# BC-11: core/sub-issue-creator.md must NOT be created
if [ -f "$REPO_ROOT/core/sub-issue-creator.md" ]; then
  fail "BC-11: core/sub-issue-creator.md must NOT exist — single consumer, no shared contract needed"
fi

# =============================================================================
# EDGE CASE 6: Step 4e idempotency — story-level guard
# =============================================================================

# Story-level idempotency guard must reference the back-reference comment check
if ! grep -q 'back-reference.*story\|story.*back-reference\|<!-- {TrackerType}.*STORY\|idempotency.*story\|story.*idempotency\|skip.*back-reference\|back-reference.*skip' "$SCAFFOLD_SKILL"; then
  fail "AC-3.2: Step 4e missing story-level idempotency guard (skip if back-reference already exists)"
fi

# =============================================================================
# SUMMARY
# =============================================================================

[ "$FAIL" -eq 0 ] && echo "PASS: scaffold tracker hidden edge cases — AC-4.3, AC-2.2, AC-8.1, REQ-6, BC-8 through BC-11 verified"
exit "$FAIL"
