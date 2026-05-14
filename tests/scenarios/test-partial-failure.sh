#!/usr/bin/env bash
# Test: Partial failure accumulator pattern and pipeline-never-blocks guarantee in all 3 skills
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
  # Pipeline NEVER blocks on tracker creation failure
  # -----------------------------------------------------------------------
  if ! grep -qE 'NEVER block|never block|Pipeline continues|pipeline continues|pipeline.*never.*block' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "$name: missing 'NEVER block' or 'Pipeline continues' guarantee for tracker creation failure"
  fi

  # -----------------------------------------------------------------------
  # Result display format: "Created {N}/{M} tracker sub-issues"
  # -----------------------------------------------------------------------
  if ! grep -qE 'Created.*tracker sub-issues|tracker sub-issues.*Created' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "$name: missing result display 'Created {N}/{M} tracker sub-issues' after creation loop"
  fi

  # -----------------------------------------------------------------------
  # Per-subtask WARN on failure (accumulator pattern)
  # -----------------------------------------------------------------------
  if ! grep -qE 'WARN.*Could not create|Could not create.*WARN|Could not create tracker sub-issue' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "$name: missing per-subtask WARN for individual tracker creation failure"
  fi

  # -----------------------------------------------------------------------
  # 100% failure escalation WARN
  # -----------------------------------------------------------------------
  if ! grep -qE 'All.*tracker.*sub-issue.*fail|all.*tracker.*fail|Check MCP|tracker.*connectivity|MCP.*connect' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "$name: missing 100% failure escalation WARN mentioning connectivity or MCP"
  fi

  # -----------------------------------------------------------------------
  # GitHub/Gitea parent body update failure handling
  # -----------------------------------------------------------------------
  if ! grep -qE 'Could not update.*parent issue body|parent issue body.*fail|checklist.*fail.*continue|Could not update.*checklist' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "$name: missing GitHub/Gitea parent body update failure WARN"
  fi

done

[ "$FAIL" -eq 0 ] && echo "PASS: Partial failure accumulator pattern (per-subtask WARN, result display, 100% failure escalation, pipeline-never-blocks, checklist failure handling) in all 3 skills"
exit "$FAIL"
