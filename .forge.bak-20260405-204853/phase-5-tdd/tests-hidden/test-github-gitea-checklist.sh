#!/usr/bin/env bash
# Test: FC-13 — GitHub/Gitea checklist format and sentinel comment in all 3 skills
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
    fail "$name: skill file not found"
    continue
  fi

  # -----------------------------------------------------------------------
  # FC-13: Sentinel comment format must be present
  # REQ-7.2: <!-- ceos-agents:decomposition-checklist:{PARENT-ISSUE-ID} -->
  # -----------------------------------------------------------------------
  if ! grep -q 'ceos-agents:decomposition-checklist' "$f" 2>/dev/null; then
    fail "FC-13 ($name): missing sentinel comment 'ceos-agents:decomposition-checklist' for GitHub/Gitea idempotency guard"
  fi

  # -----------------------------------------------------------------------
  # FC-13: Checklist format uses - [ ] checkboxes
  # REQ-7.1: checklist format with - [ ] items
  # -----------------------------------------------------------------------
  if ! grep -qE '\- \[ \]' "$f" 2>/dev/null; then
    fail "FC-13 ($name): missing checklist format '- [ ]' for GitHub/Gitea decomposition checklist (REQ-7.1)"
  fi

  # -----------------------------------------------------------------------
  # FC-13: Parent issue update (read-modify-write) is described
  # REQ-7.3: checklist is appended to parent issue body
  # -----------------------------------------------------------------------
  if ! grep -qE 'parent issue body|append.*checklist|checklist.*append|update.*parent.*body|body.*update' "$f" 2>/dev/null; then
    fail "FC-13 ($name): missing parent issue body update instruction (read-modify-write for checklist, REQ-7.3)"
  fi

  # -----------------------------------------------------------------------
  # FC-13: Sentinel check before appending (idempotency)
  # REQ-7.2: skip checklist append if sentinel already present in parent body
  # -----------------------------------------------------------------------
  if ! grep -qE 'sentinel.*(present|exists|found|skip)|skip.*sentinel|already.*checklist|checklist.*already|if.*sentinel' "$f" 2>/dev/null; then
    fail "FC-13 ($name): missing sentinel-presence check before appending checklist (REQ-7.2)"
  fi

  # -----------------------------------------------------------------------
  # FC-13: Only successful subtasks included in checklist
  # REQ-7.4: failed creations are omitted from checklist
  # -----------------------------------------------------------------------
  if ! grep -qE '(only|successfully).*(created|non-null)|failed.*omit|omit.*failed|non-null.*tracker_issue_id|tracker_issue_id.*non-null' "$f" 2>/dev/null; then
    fail "FC-13 ($name): missing clause that only includes successfully created subtasks in checklist (REQ-7.4)"
  fi

  # -----------------------------------------------------------------------
  # FC-13: GitHub/Gitea standalone title prefix [PARENT-ISSUE-ID]
  # REQ-7.5: standalone issue titled [{PARENT-ISSUE-ID}] {subtask-title}
  # -----------------------------------------------------------------------
  if ! grep -qE '\[.*PARENT-ISSUE-ID\]|\[.*PARENT-ISSUE.*\].*title' "$f" 2>/dev/null; then
    fail "FC-13 ($name): missing standalone issue title prefix '[{PARENT-ISSUE-ID}]' for GitHub/Gitea (REQ-7.5)"
  fi

done

[ "$FAIL" -eq 0 ] && echo "PASS: GitHub/Gitea checklist format with sentinel comment, parent body update, idempotency guard, and standalone title prefix present in all 3 skills (FC-13)"
exit "$FAIL"
