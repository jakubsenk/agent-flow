#!/usr/bin/env bash
# Test: v9.6.1 — Self-assign failure mode is advisory (WARN, never block)
# Validates:
#   AC-011: docs/reference/automation-config.md "On start set" row mentions implicit self-assign behavior
#   AC-012: CHANGELOG.md has v9.6.1 entry describing implicit self-assign
#   AC-013: fix-bugs Step 1 describes assignee failure as advisory/WARN/non-blocking
#           (implement-feature out of scope — has no explicit On start set step in v9.6.1)
#   AC-014: fix-bugs does NOT instruct the pipeline to BLOCK on assignee failure
#   AC-015: docs/reference/automation-config.md does NOT introduce a NEW required config key
#           (e.g., no row labeled "On start assign" — strict PATCH discipline)
#
# REQ mapping: v9.6.1 R2 (no contract change) + R3 (advisory failure) + R4 (CHANGELOG)
# Phase 5 TDD — RED phase expected
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

AUTOCONFIG="$REPO_ROOT/docs/reference/automation-config.md"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"
FIXBUGS="$REPO_ROOT/skills/fix-bugs/SKILL.md"

# ============================================================
# AC-011: automation-config.md "On start set" row mentions implicit self-assign
# Find the row containing "On start set" and check next 5 lines for assignee reference
# ============================================================
if ! grep -A 3 'On start set' "$AUTOCONFIG" | grep -qiE 'assign(ee)?|self-assign'; then
  fail "AC-011: docs/reference/automation-config.md 'On start set' row does not document implicit self-assign behavior"
fi

# ============================================================
# AC-012: CHANGELOG has v9.6.1 entry mentioning self-assign
# ============================================================
if ! grep -F '## [9.6.1]' "$CHANGELOG" > /dev/null; then
  fail "AC-012: CHANGELOG.md missing v9.6.1 entry"
elif ! awk '/^## \[9\.6\.1\]/,/^## \[9\.6\.0\]/' "$CHANGELOG" | grep -qiE 'self-assign|assignee'; then
  fail "AC-012: CHANGELOG.md v9.6.1 entry does not mention self-assign/assignee"
fi

# ============================================================
# AC-013: fix-bugs Step 1 describes assignee failure as advisory
# v10 thin-controller: read SKILL.md + steps/01-triage.md aggregate
# ============================================================
STEP1_FILE="$REPO_ROOT/skills/fix-bugs/steps/01-triage.md"
FIXBUGS_STEP1=$( (cat "$FIXBUGS"; [ -f "$STEP1_FILE" ] && cat "$STEP1_FILE") 2>/dev/null )

if ! echo "$FIXBUGS_STEP1" | grep -qiE 'advisory|WARN|non-blocking|never block|do not block'; then
  fail "AC-013: fix-bugs Step 1 missing advisory-failure language for assignee"
fi

# ============================================================
# AC-014: fix-bugs does NOT instruct BLOCK on assignee failure
# Negative: must NOT contain "block" near "assignee" without negation
# ============================================================
if echo "$FIXBUGS_STEP1" | grep -qiE 'block.{0,80}assign|assign.{0,80}\bblock\b'; then
  if ! echo "$FIXBUGS_STEP1" | grep -qiE '(never|not|no) block'; then
    fail "AC-014: fix-bugs Step 1 may instruct BLOCK on assignee failure (block + assign in close proximity, no negation)"
  fi
fi

# ============================================================
# AC-015: NO new required config key like "On start assign"
# Strict PATCH discipline — keep contract unchanged
# ============================================================
if grep -qF 'On start assign' "$AUTOCONFIG"; then
  fail "AC-015: docs/reference/automation-config.md introduces NEW config key 'On start assign' — would be MINOR scope, violates PATCH discipline"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v9.6.1 failure-advisory + no-contract-change — all AC-011..015 assertions pass"
exit "$FAIL"
