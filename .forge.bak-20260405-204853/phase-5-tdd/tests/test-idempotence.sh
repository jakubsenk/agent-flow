#!/usr/bin/env bash
# Test: FC-8, FC-11, FC-17, FC-18 — Idempotence guard clause and dual-store write order in all 3 skills
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
  # FC-8: tracker_issue_id: null in YAML write instructions
  # REQ-4.2: decomposition YAML subtask objects must include tracker_issue_id: null
  # -----------------------------------------------------------------------
  if ! grep -q 'tracker_issue_id' "$f" 2>/dev/null; then
    fail "FC-8 ($name): missing 'tracker_issue_id' field (should appear as 'tracker_issue_id: null' in YAML init)"
  fi

  # -----------------------------------------------------------------------
  # FC-11: Idempotency algorithm — YAML-first, state.json fallback
  # REQ-3.1 + REQ-3.2: must mention YAML and state.json and fallback/recover
  # -----------------------------------------------------------------------
  if ! grep -qE 'YAML.*state\.json|state\.json.*YAML' "$f" 2>/dev/null; then
    fail "FC-11 ($name): idempotency check does not reference both YAML and state.json together"
  fi

  if ! grep -qE 'state\.json.*(fallback|recover)|fallback.*state\.json|recover.*state\.json' "$f" 2>/dev/null; then
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
  if ! grep -qE 'state\.json.*(immediately|atomic)|atomic.*state\.json|atomic write' "$f" 2>/dev/null; then
    fail "FC-18 ($name): missing atomic/immediate state.json write after each subtask creation (REQ-3.3)"
  fi

done

[ "$FAIL" -eq 0 ] && echo "PASS: Idempotency guard (YAML+state.json fallback), tracker_issue_id field, no bare tracker_id, and atomic write order verified in all 3 skills (FC-8, FC-11, FC-17, FC-18)"
exit "$FAIL"
