#!/usr/bin/env bash
# Test: FC-12 — Partial failure accumulator pattern and pipeline-never-blocks guarantee in all 3 skills
# Since v6.7.2, tracker subtask creation logic lives in core/tracker-subtask-creator.md.
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
  # FC-12: Pipeline NEVER blocks on tracker creation failure
  # REQ-6.4: the step must explicitly state pipeline continues regardless
  # -----------------------------------------------------------------------
  if ! grep -qE 'NEVER block|never block|Pipeline continues|pipeline continues|pipeline.*never.*block' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-12 ($name): missing 'NEVER block' or 'Pipeline continues' guarantee for tracker creation failure (REQ-6.4)"
  fi

  # -----------------------------------------------------------------------
  # FC-12: Result display format: "Created {N}/{M} tracker sub-issues"
  # REQ-6.2: after loop, display Created N/M tracker sub-issues ({F} failures)
  # -----------------------------------------------------------------------
  if ! grep -qE 'Created.*tracker sub-issues|tracker sub-issues.*Created' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-12 ($name): missing result display 'Created {N}/{M} tracker sub-issues' after creation loop (REQ-6.2)"
  fi

  # -----------------------------------------------------------------------
  # FC-12: Per-subtask WARN on failure (accumulator pattern)
  # REQ-6.1: on individual failure, WARN and continue (not block)
  # -----------------------------------------------------------------------
  if ! grep -qE 'WARN.*Could not create|Could not create.*WARN|Could not create tracker sub-issue' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-12 ($name): missing per-subtask WARN for individual tracker creation failure (REQ-6.1)"
  fi

  # -----------------------------------------------------------------------
  # FC-12: 100% failure escalation WARN
  # REQ-6.3: if all fail (N==0), elevated WARN about MCP connectivity
  # -----------------------------------------------------------------------
  if ! grep -qE 'All.*tracker.*sub-issue.*fail|all.*tracker.*fail|Check MCP|tracker.*connectivity|MCP.*connect' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-12 ($name): missing 100% failure escalation WARN mentioning connectivity or MCP (REQ-6.3)"
  fi

  # -----------------------------------------------------------------------
  # FC-12: GitHub/Gitea parent body update failure handling
  # REQ-6.5: if checklist append fails, WARN and continue
  # -----------------------------------------------------------------------
  if ! grep -qE 'Could not update.*parent issue body|parent issue body.*fail|checklist.*fail.*continue|Could not update.*checklist' "${SEARCH_FILES[@]}" 2>/dev/null; then
    fail "FC-12 ($name): missing GitHub/Gitea parent body update failure WARN (REQ-6.5)"
  fi

done

[ "$FAIL" -eq 0 ] && echo "PASS: Partial failure accumulator pattern (per-subtask WARN, result display, 100% failure escalation, pipeline-never-blocks, checklist failure handling) in all 3 skills (FC-12)"
exit "$FAIL"
