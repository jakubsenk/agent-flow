#!/usr/bin/env bash
# Test: GitHub/Gitea checklist format and sentinel comment in all 3 skills
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
    fail "$name: skill file not found"
    continue
  fi

  # v10 thin-controller: include SKILL.md + steps/*.md + core contract.
  SEARCH_FILES=("$f")
  skill_dir="$(dirname "$f")"
  if [ -d "$skill_dir/steps" ]; then
    while IFS= read -r -d '' sf; do
      SEARCH_FILES+=("$sf")
    done < <(find "$skill_dir/steps" -name '*.md' -type f -print0)
  fi
  if [ -f "$CORE_TSC" ]; then
    SEARCH_FILES+=("$CORE_TSC")
  fi

  # -----------------------------------------------------------------------
  # Sentinel comment format must be present
  # -----------------------------------------------------------------------
  if ! grep -q 'agent-flow:decomposition-checklist' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "$name: missing sentinel comment 'agent-flow:decomposition-checklist' for GitHub/Gitea idempotency guard"
  fi

  # -----------------------------------------------------------------------
  # Checklist format uses - [ ] checkboxes
  # -----------------------------------------------------------------------
  if ! grep -qE '\- \[ \]' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "$name: missing checklist format '- [ ]' for GitHub/Gitea decomposition checklist"
  fi

  # -----------------------------------------------------------------------
  # Parent issue update (read-modify-write) is described
  # -----------------------------------------------------------------------
  if ! grep -qE 'parent issue body|append.*checklist|checklist.*append|update.*parent.*body|body.*update' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "$name: missing parent issue body update instruction (read-modify-write for checklist)"
  fi

  # -----------------------------------------------------------------------
  # Sentinel check before appending (idempotency)
  # -----------------------------------------------------------------------
  if ! grep -qE 'sentinel.*(present|exists|found|skip)|skip.*sentinel|already.*checklist|checklist.*already|if.*sentinel' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "$name: missing sentinel-presence check before appending checklist"
  fi

  # -----------------------------------------------------------------------
  # Only successful subtasks included in checklist
  # -----------------------------------------------------------------------
  if ! grep -qE '(only|successfully).*(created|non-null)|failed.*omit|omit.*failed|non-null.*tracker_issue_id|tracker_issue_id.*non-null|tracker_issue_id != null|WHERE.*tracker_issue_id' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "$name: missing clause that only includes successfully created subtasks in checklist"
  fi

  # -----------------------------------------------------------------------
  # GitHub/Gitea standalone title prefix [PARENT-ISSUE-ID]
  # Accepts both uppercase ({PARENT-ISSUE-ID}, {ISSUE_ID}) and lowercase ({issue_id}) variants
  # -----------------------------------------------------------------------
  if ! grep -qE '\[.*PARENT.ISSUE.ID\]|\[.*ISSUE_ID\]|\[.*ISSUE.ID\]|\[\{ISSUE_ID\}\]|\[\{issue_id\}\]' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "$name: missing standalone issue title prefix for GitHub/Gitea"
  fi

done

[ "$FAIL" -eq 0 ] && echo "PASS: GitHub/Gitea checklist format with sentinel comment, parent body update, idempotency guard, and standalone title prefix present in all 3 skills"
exit "$FAIL"
