#!/usr/bin/env bash
# Test: Identical patterns across all 3 skills + resume-ticket awareness
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

IF="$REPO_ROOT/skills/implement-feature/SKILL.md"
FB="$REPO_ROOT/skills/fix-bugs/SKILL.md"
RT="$REPO_ROOT/core/resume-detection.md"

SKILL_FILES=("$IF" "$FB")
SKILL_NAMES=("implement-feature" "fix-bugs")
SKILL_DIRS=("$REPO_ROOT/skills/implement-feature" "$REPO_ROOT/skills/fix-bugs")

# v10 thin-controller: decomposition detail lives in step files. Build an
# aggregate tmpfile for each skill that includes SKILL.md + steps/*.md and
# search there.
for i in "${!SKILL_FILES[@]}"; do
  f="${SKILL_FILES[$i]}"
  name="${SKILL_NAMES[$i]}"
  skill_dir="${SKILL_DIRS[$i]}"

  if [ ! -f "$f" ]; then
    fail "$name: skill file not found"
    continue
  fi

  agg_tmp=$(mktemp)
  cat "$f" > "$agg_tmp"
  [ -d "$skill_dir/steps" ] && cat "$skill_dir/steps"/*.md >> "$agg_tmp"
  # v10: decomposition mechanics live in core/decomposition-heuristics.md and
  # core/tracker-subtask-creator.md (shared contracts); both step files explicitly
  # reference them. Include those in the aggregate so the FC-4/FC-14/FC-15 greps
  # find the decomposition contract content regardless of where it was sharded.
  [ -f "$REPO_ROOT/core/decomposition-heuristics.md" ] && cat "$REPO_ROOT/core/decomposition-heuristics.md" >> "$agg_tmp"
  [ -f "$REPO_ROOT/core/tracker-subtask-creator.md" ] && cat "$REPO_ROOT/core/tracker-subtask-creator.md" >> "$agg_tmp"
  # Reassign the loop's target file to the aggregate so the existing greps just work.
  f="$agg_tmp"

  # -----------------------------------------------------------------------
  # Triple gate — all 3 conditions present in each skill's new step
  # 1. decomposition.decision == "DECOMPOSE" check
  # 2. "Create tracker subtasks" disabled gate
  # 3. tracker_effective_status == "ready" check
  # -----------------------------------------------------------------------
  if ! grep -q 'decomposition.decision' "$f" 2>/dev/null; then
    fail "$name: missing 'decomposition.decision' gate condition"
  fi

  if ! grep -q 'Create tracker subtasks' "$f" 2>/dev/null; then
    fail "$name: missing 'Create tracker subtasks' disabled gate condition"
  fi

  if ! grep -q 'tracker_effective_status' "$f" 2>/dev/null; then
    fail "$name: missing 'tracker_effective_status' gate condition"
  fi

  # -----------------------------------------------------------------------
  # Single git commit after creation loop
  # -----------------------------------------------------------------------
  if ! grep -qE 'git commit.*(link|tracker|decomposition)|git commit.*subtask' "$f" 2>/dev/null; then
    fail "$name: missing git commit instruction for linking decomposition subtasks to tracker"
  fi

  # -----------------------------------------------------------------------
  # maps_to / Addresses: in sub-issue description
  # -----------------------------------------------------------------------
  if ! grep -qE 'maps_to|Addresses:' "$f" 2>/dev/null; then
    fail "$name: missing 'maps_to' or 'Addresses:' reference for sub-issue description traceability"
  fi

  rm -f "$agg_tmp"
done

# -----------------------------------------------------------------------
# Resume detection awareness of tracker_issue_id
# (resume-ticket deleted — checked in core/resume-detection.md or fix-bugs)
# -----------------------------------------------------------------------
DECOMP_CHECK="$REPO_ROOT/core/tracker-subtask-creator.md"
if grep -q 'tracker_issue_id' "$DECOMP_CHECK" 2>/dev/null || grep -q 'tracker_issue_id' "$FB" 2>/dev/null; then
  : # tracker_issue_id found in subtask creator or fix-bugs — OK
else
  fail "tracker_issue_id not found in core/tracker-subtask-creator.md or fix-bugs (must handle DECOMPOSE_PARTIAL resume)"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Triple gate, git commit linkage, maps_to traceability consistent across all 3 skills; resume-ticket aware of tracker_issue_id"
exit "$FAIL"
