#!/usr/bin/env bash
# Test: v9.6.1 — Self-assign on On-start-set in fix-bugs Step 1
# Validates:
#   AC-001: skills/fix-bugs/SKILL.md Step 1 prose mentions assignee setting (self-assign intent)
#   AC-002: Step 1 prose references "On start set" context (assignee fires alongside transition)
#   AC-003: Step 1 prose lists per-tracker assignee tools — ALL 4 unique tools required (tightened 2026-05-11):
#           editIssue (jira/gitea), update_issue (youtrack/redmine), issueUpdate (linear), addAssignees (github)
#   AC-004: Step 1 prose mentions advisory failure mode (WARN/advisory/non-blocking) for assignee
#   AC-005: Step 1 prose references the status-verification.md pattern (or equivalent advisory contract reference)
#
# REQ mapping: v9.6.1 R1 (implicit self-assign) + R3 (advisory failure)
# Phase 5 TDD — RED phase expected (implementation does not exist yet)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL="$REPO_ROOT/skills/fix-bugs/SKILL.md"
STEP1_FILE="$REPO_ROOT/skills/fix-bugs/steps/01-triage.md"

# v10 thin-controller: Step 1 detail (tracker-set + self-assign) lives in the
# orchestrator preamble of SKILL.md OR in steps/01-triage.md. Combine both for
# the v9.6.1 self-assign assertions.
STEP1=$( (cat "$SKILL"; [ -f "$STEP1_FILE" ] && cat "$STEP1_FILE") 2>/dev/null )

# ============================================================
# AC-001: Step 1 prose mentions assignee
# ============================================================
if ! echo "$STEP1" | grep -qiE 'assign(ee)?|self-assign'; then
  fail "AC-001: skills/fix-bugs/SKILL.md Step 1 does not mention assignee/self-assign"
fi

# ============================================================
# AC-002: Step 1 references On start set context
# ============================================================
if ! echo "$STEP1" | grep -qF "On start set"; then
  fail "AC-002: skills/fix-bugs/SKILL.md Step 1 missing 'On start set' context reference"
fi

# ============================================================
# AC-003: Per-tracker assignee tools — at least 3 of the 4 keywords
# ============================================================
COUNT=0
for tool in editIssue update_issue issueUpdate addAssignees; do
  if echo "$STEP1" | grep -qF "$tool"; then
    COUNT=$((COUNT+1))
  fi
done
if [ "$COUNT" -lt 4 ]; then
  fail "AC-003: Step 1 references only $COUNT/4 per-tracker assignee tools (expected ALL 4): editIssue, update_issue, issueUpdate, addAssignees"
fi

# ============================================================
# AC-004: Advisory failure mode mention
# ============================================================
if ! echo "$STEP1" | grep -qiE 'advisory|WARN|non-blocking|never block|do not block'; then
  fail "AC-004: Step 1 does not mention advisory failure mode for assignee (WARN/advisory/non-blocking)"
fi

# ============================================================
# AC-005: References status-verification.md pattern
# ============================================================
if ! echo "$STEP1" | grep -qF "status-verification"; then
  fail "AC-005: Step 1 does not reference core/status-verification.md pattern"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v9.6.1 self-assign in fix-bugs Step 1 — all AC-001..005 assertions pass"
exit "$FAIL"
