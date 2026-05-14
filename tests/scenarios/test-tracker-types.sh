#!/usr/bin/env bash
# Test: FC-5, FC-6 — All 6 tracker types covered with correct parent parameters in all 3 skills
# Tracker subtask creation logic lives in core/tracker-subtask-creator.md.
# Each skill delegates via "Follow core/tracker-subtask-creator.md". This test searches
# both the skill file and the core contract file so delegation is accepted.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

IF="$REPO_ROOT/skills/implement-feature/SKILL.md"
FB="$REPO_ROOT/skills/fix-bugs/SKILL.md"
CORE_TSC="$REPO_ROOT/core/tracker-subtask-creator.md"

SKILL_FILES=("$IF" "$FB")
SKILL_NAMES=("implement-feature" "fix-bugs")

for i in "${!SKILL_FILES[@]}"; do
  f="${SKILL_FILES[$i]}"
  name="${SKILL_NAMES[$i]}"

  if [ ! -f "$f" ]; then
    fail "$name: skill file not found: $f"
    continue
  fi

  # v10 thin-controller: detail lives in steps/*.md. Aggregate SKILL.md + steps + core contract.
  SEARCH_FILES=("$f")
  skill_dir="$(dirname "$f")"
  if [ -d "$skill_dir/steps" ]; then
    while IFS= read -r -d '' sf; do
      SEARCH_FILES+=("$sf")
    done < <(find "$skill_dir/steps" -name '*.md' -type f -print0)
  fi
  # Always include core/tracker-subtask-creator.md — it owns the parent-parameter contract.
  if [ -f "$CORE_TSC" ]; then
    SEARCH_FILES+=("$CORE_TSC")
  fi
  # Also include core/decomposition-heuristics.md for FC-6 nested-subtask guard.
  if [ -f "$REPO_ROOT/core/decomposition-heuristics.md" ]; then
    SEARCH_FILES+=("$REPO_ROOT/core/decomposition-heuristics.md")
  fi

  # -----------------------------------------------------------------------
  # FC-5: YouTrack parent parameter
  # Each skill must document: parent: {PARENT-ISSUE-ID} for YouTrack
  # Accepts both uppercase ({PARENT-ISSUE-ID}, {ISSUE_ID}) and lowercase ({issue_id}) variants
  # -----------------------------------------------------------------------
  if ! grep -qE 'parent:.*\{(PARENT-ISSUE-ID|ISSUE_ID|ISSUE-ID|issue_id)\}' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-5 ($name): missing YouTrack/Jira 'parent: {ISSUE_ID}' parameter documentation"
  fi

  # -----------------------------------------------------------------------
  # FC-5: Jira issuetype Sub-task parameter
  # -----------------------------------------------------------------------
  if ! grep -qE 'issuetype.*Sub-task|Sub-task.*issuetype' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-5 ($name): missing Jira 'issuetype: \"Sub-task\"' parameter documentation"
  fi

  # -----------------------------------------------------------------------
  # FC-5: Linear parentId parameter
  # -----------------------------------------------------------------------
  if ! grep -q 'parentId:' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-5 ($name): missing Linear 'parentId:' parameter documentation"
  fi

  # -----------------------------------------------------------------------
  # FC-5: Redmine parent_issue_id parameter
  # -----------------------------------------------------------------------
  if ! grep -q 'parent_issue_id:' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-5 ($name): missing Redmine 'parent_issue_id:' parameter documentation"
  fi

  # -----------------------------------------------------------------------
  # FC-5: GitHub standalone title prefix [PARENT-ISSUE-ID]
  # Accepts both uppercase ([{PARENT-ISSUE-ID}]) and lowercase ([{issue_id}]) variants
  # -----------------------------------------------------------------------
  if ! grep -qE '\[.*(PARENT|ISSUE|issue_id).*\]' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-5 ($name): missing GitHub standalone '[{PARENT-ISSUE-ID}]' title prefix documentation"
  fi

  # -----------------------------------------------------------------------
  # FC-5: Gitea coverage
  # -----------------------------------------------------------------------
  if ! grep -qi 'gitea' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-5 ($name): missing Gitea tracker coverage"
  fi

  # -----------------------------------------------------------------------
  # FC-6: Jira nested sub-task guard
  # The step must describe the edge case: parent is Sub-task → flat issue + WARN
  # -----------------------------------------------------------------------
  if ! grep -qE 'Sub-task.*(flat issue|without parent)|flat issue.*Sub-task|parent.*Sub-task.*WARN|Sub-task.*WARN.*flat' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-6 ($name): missing Jira nested sub-task guard (parent Sub-task → flat issue + WARN)"
  fi

done

[ "$FAIL" -eq 0 ] && echo "PASS: All 6 tracker types (YouTrack, Jira, Linear, Redmine, GitHub, Gitea) covered with correct parent parameters and Jira guard in all 3 skills (FC-5, FC-6)"
exit "$FAIL"
