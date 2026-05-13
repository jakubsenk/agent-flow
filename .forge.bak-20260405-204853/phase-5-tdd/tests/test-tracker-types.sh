#!/usr/bin/env bash
# Test: FC-5, FC-6 — All 6 tracker types covered with correct parent parameters in all 3 skills
# TDD red phase: expects FAIL on pre-implementation codebase
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

IF="$REPO_ROOT/skills/implement-feature/SKILL.md"
FT="$REPO_ROOT/skills/fix-ticket/SKILL.md"
FB="$REPO_ROOT/skills/fix-bugs/SKILL.md"

SKILL_FILES=("$IF" "$FT" "$FB")
SKILL_NAMES=("implement-feature" "fix-ticket" "fix-bugs")

for i in "${!SKILL_FILES[@]}"; do
  f="${SKILL_FILES[$i]}"
  name="${SKILL_NAMES[$i]}"

  if [ ! -f "$f" ]; then
    fail "$name: skill file not found: $f"
    continue
  fi

  # -----------------------------------------------------------------------
  # FC-5: YouTrack parent parameter
  # Each skill must document: parent: {PARENT-ISSUE-ID} for YouTrack
  # -----------------------------------------------------------------------
  if ! grep -q 'parent:.*PARENT-ISSUE' "$f" 2>/dev/null; then
    fail "FC-5 ($name): missing YouTrack/Jira 'parent: {PARENT-ISSUE' parameter documentation"
  fi

  # -----------------------------------------------------------------------
  # FC-5: Jira issuetype Sub-task parameter
  # -----------------------------------------------------------------------
  if ! grep -qE 'issuetype.*Sub-task|Sub-task.*issuetype' "$f" 2>/dev/null; then
    fail "FC-5 ($name): missing Jira 'issuetype: \"Sub-task\"' parameter documentation"
  fi

  # -----------------------------------------------------------------------
  # FC-5: Linear parentId parameter
  # -----------------------------------------------------------------------
  if ! grep -q 'parentId:' "$f" 2>/dev/null; then
    fail "FC-5 ($name): missing Linear 'parentId:' parameter documentation"
  fi

  # -----------------------------------------------------------------------
  # FC-5: Redmine parent_issue_id parameter
  # -----------------------------------------------------------------------
  if ! grep -q 'parent_issue_id:' "$f" 2>/dev/null; then
    fail "FC-5 ($name): missing Redmine 'parent_issue_id:' parameter documentation"
  fi

  # -----------------------------------------------------------------------
  # FC-5: GitHub standalone title prefix [PARENT-ISSUE-ID]
  # -----------------------------------------------------------------------
  if ! grep -qE '\[.*(PARENT|ISSUE).*\]' "$f" 2>/dev/null; then
    fail "FC-5 ($name): missing GitHub standalone '[{PARENT-ISSUE-ID}]' title prefix documentation"
  fi

  # -----------------------------------------------------------------------
  # FC-5: Gitea coverage
  # -----------------------------------------------------------------------
  if ! grep -qi 'gitea' "$f" 2>/dev/null; then
    fail "FC-5 ($name): missing Gitea tracker coverage"
  fi

  # -----------------------------------------------------------------------
  # FC-6: Jira nested sub-task guard
  # The step must describe the edge case: parent is Sub-task → flat issue + WARN
  # -----------------------------------------------------------------------
  if ! grep -qE 'Sub-task.*(flat issue|without parent)|flat issue.*Sub-task|parent.*Sub-task.*WARN|Sub-task.*WARN.*flat' "$f" 2>/dev/null; then
    fail "FC-6 ($name): missing Jira nested sub-task guard (parent Sub-task → flat issue + WARN)"
  fi

done

[ "$FAIL" -eq 0 ] && echo "PASS: All 6 tracker types (YouTrack, Jira, Linear, Redmine, GitHub, Gitea) covered with correct parent parameters and Jira guard in all 3 skills (FC-5, FC-6)"
exit "$FAIL"
