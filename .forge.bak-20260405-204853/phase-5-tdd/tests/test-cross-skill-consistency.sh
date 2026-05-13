#!/usr/bin/env bash
# Test: FC-4, FC-14, FC-15, FC-16 — Identical patterns across all 3 skills + resume-ticket awareness
# TDD red phase: expects FAIL on pre-implementation codebase
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

IF="$REPO_ROOT/skills/implement-feature/SKILL.md"
FT="$REPO_ROOT/skills/fix-ticket/SKILL.md"
FB="$REPO_ROOT/skills/fix-bugs/SKILL.md"
RT="$REPO_ROOT/skills/resume-ticket/SKILL.md"

SKILL_FILES=("$IF" "$FT" "$FB")
SKILL_NAMES=("implement-feature" "fix-ticket" "fix-bugs")

for i in "${!SKILL_FILES[@]}"; do
  f="${SKILL_FILES[$i]}"
  name="${SKILL_NAMES[$i]}"

  if [ ! -f "$f" ]; then
    fail "$name: skill file not found"
    continue
  fi

  # -----------------------------------------------------------------------
  # FC-4: Triple gate — all 3 conditions present in each skill's new step
  # 1. decomposition.decision == "DECOMPOSE" check
  # 2. "Create tracker subtasks" disabled gate
  # 3. tracker_effective_status == "ready" check
  # -----------------------------------------------------------------------
  if ! grep -q 'decomposition.decision' "$f" 2>/dev/null; then
    fail "FC-4 ($name): missing 'decomposition.decision' gate condition"
  fi

  if ! grep -q 'Create tracker subtasks' "$f" 2>/dev/null; then
    fail "FC-4 ($name): missing 'Create tracker subtasks' disabled gate condition"
  fi

  if ! grep -q 'tracker_effective_status' "$f" 2>/dev/null; then
    fail "FC-4 ($name): missing 'tracker_effective_status' gate condition"
  fi

  # -----------------------------------------------------------------------
  # FC-14: Single git commit after creation loop
  # REQ: git commit with message referencing decomposition subtask linking
  # -----------------------------------------------------------------------
  if ! grep -qE 'git commit.*(link|tracker|decomposition)|git commit.*subtask' "$f" 2>/dev/null; then
    fail "FC-14 ($name): missing git commit instruction for linking decomposition subtasks to tracker"
  fi

  # -----------------------------------------------------------------------
  # FC-15: maps_to / Addresses: in sub-issue description
  # REQ-2.8: description includes Addresses: line with maps_to references
  # -----------------------------------------------------------------------
  if ! grep -qE 'maps_to|Addresses:' "$f" 2>/dev/null; then
    fail "FC-15 ($name): missing 'maps_to' or 'Addresses:' reference for sub-issue description traceability"
  fi

done

# -----------------------------------------------------------------------
# FC-16: resume-ticket awareness of tracker_issue_id
# REQ-8.1: resume-ticket must reference tracker_issue_id in DECOMPOSE_PARTIAL context
# -----------------------------------------------------------------------
if [ ! -f "$RT" ]; then
  fail "FC-16: skills/resume-ticket/SKILL.md not found"
else
  if ! grep -q 'tracker_issue_id' "$RT" 2>/dev/null; then
    fail "FC-16: skills/resume-ticket/SKILL.md does not reference 'tracker_issue_id' (must handle DECOMPOSE_PARTIAL resume)"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Triple gate, git commit linkage, maps_to traceability consistent across all 3 skills; resume-ticket aware of tracker_issue_id (FC-4, FC-14, FC-15, FC-16)"
exit "$FAIL"
