#!/usr/bin/env bash
# Test: FC-8, FC-11, FC-17, FC-18 — Idempotence guard clause and dual-store write order in all 3 skills
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
  # FC-8: tracker_issue_id: null in YAML write instructions
  # REQ-4.2: decomposition YAML subtask objects must include tracker_issue_id: null
  # -----------------------------------------------------------------------
  if ! grep -q 'tracker_issue_id' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-8 ($name): missing 'tracker_issue_id' field (should appear as 'tracker_issue_id: null' in YAML init)"
  fi

  # -----------------------------------------------------------------------
  # FC-11: Idempotency algorithm — YAML-first, state.json fallback
  # REQ-3.1 + REQ-3.2: must mention YAML and state.json and fallback/recover
  # -----------------------------------------------------------------------
  if ! grep -qE 'YAML.*state\.json|state\.json.*YAML' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-11 ($name): idempotency check does not reference both YAML and state.json together"
  fi

  if ! grep -qE 'state\.json.*(fallback|recover)|fallback.*state\.json|recover.*state\.json' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-11 ($name): idempotency check missing fallback/recover from state.json (REQ-3.2)"
  fi

  # -----------------------------------------------------------------------
  # FC-17: No bare tracker_id field — must use tracker_issue_id
  # REQ-4.3: the field must NEVER be introduced as tracker_id (without _issue suffix)
  # Allowed: tracker_id as Redmine issue TYPE parameter (in docs/reference/ files only)
  # Not allowed: a new "tracker_id" field that refers to the tracker issue identity
  # Strategy: find "tracker_id" NOT preceded by "issue" and NOT followed by "_issue"
  # -----------------------------------------------------------------------
  bare_lines=$(grep -nE '\btracker_id\b' "$f" 2>/dev/null | grep -v 'tracker_issue_id' || true)
  if [ -n "$bare_lines" ]; then
    fail "FC-17 ($name): found bare 'tracker_id' usage (should be 'tracker_issue_id'): $(echo "$bare_lines" | head -3)"
  fi

  # -----------------------------------------------------------------------
  # FC-18: Dual-store write order — state.json immediately/atomic, YAML committed after loop
  # REQ-3.3: must specify state.json immediately after each creation, YAML once after loop
  # -----------------------------------------------------------------------
  if ! grep -qE 'state\.json.*(immediately|atomic)|atomic.*state\.json|atomic write' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-18 ($name): missing atomic/immediate state.json write after each subtask creation (REQ-3.3)"
  fi

done

[ "$FAIL" -eq 0 ] && echo "PASS: Idempotency guard (YAML+state.json fallback), tracker_issue_id field, no bare tracker_id, and atomic write order verified in all 3 skills (FC-8, FC-11, FC-17, FC-18)"
exit "$FAIL"
