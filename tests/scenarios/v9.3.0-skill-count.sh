#!/usr/bin/env bash
# v9.3.0 TDD — tests written before implementation
# T-08: Skill count = 22 (AC-037 through AC-040)
#
# Tests that:
#   1. There are exactly 22 skill directories under skills/
#   2. The 3 deleted skills are absent (fix-ticket, scaffold-add, resume-ticket)
#   3. Key surviving skills are present (fix-bugs, scaffold, scaffold-validate)
#
# RED until Phase 7 implementation is complete — that is correct TDD behavior.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
[ -f "$REPO_ROOT/tests/lib/fixtures.sh" ] || REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

SKILLS_DIR="$REPO_ROOT/skills"

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Count skill directories
# ---------------------------------------------------------------------------
echo "--- Skill count: expect exactly 18 directories ---"
SKILL_COUNT=$(ls -1d "$SKILLS_DIR"/*/  2>/dev/null | wc -l | tr -d ' ')

if [ "$SKILL_COUNT" -eq 18 ]; then
  echo "PASS: Found exactly 18 skill directories"
else
  fail "Skill count is $SKILL_COUNT, expected 18. Skills present:"
  ls -1d "$SKILLS_DIR"/*/ 2>/dev/null | xargs -I{} basename {} | sort >&2 || true
fi

# ---------------------------------------------------------------------------
# Deleted skills must be absent
# ---------------------------------------------------------------------------
echo "--- Deleted skills absent ---"
for deleted_skill in "fix-ticket" "scaffold-add" "resume-ticket" "estimate" "migrate-config" "pipeline-status" "scaffold-validate"; do
  if [ -d "$SKILLS_DIR/$deleted_skill" ]; then
    fail "Deleted skill '$deleted_skill' still present in skills/ (v9.3.0/v9.5.0 deletion not applied)"
  else
    echo "PASS: '$deleted_skill' correctly absent"
  fi
done

# ---------------------------------------------------------------------------
# Surviving key skills must be present
# ---------------------------------------------------------------------------
echo "--- Surviving skills present ---"
for expected_skill in "fix-bugs" "scaffold" "implement-feature" "autopilot" "publish" "metrics"; do
  if [ -d "$SKILLS_DIR/$expected_skill" ]; then
    echo "PASS: '$expected_skill' skill directory present"
  else
    fail "Expected skill '$expected_skill' is missing from skills/"
  fi
done

# ---------------------------------------------------------------------------
# Full expected skill list check (all 18 from v9.5.0 cleanup)
# ---------------------------------------------------------------------------
echo "--- Full 18-skill list check ---"
EXPECTED_SKILLS=(
  "analyze-bug"
  "autopilot"
  "changelog"
  "check-setup"
  "create-backlog"
  "discuss"
  "fix-bugs"
  "implement-feature"
  "metrics"
  "onboard"
  "prioritize"
  "publish"
  "scaffold"
  "setup-agents"
  "setup-mcp"
  "sprint-plan"
  "version-bump"
  "version-check"
)

for skill in "${EXPECTED_SKILLS[@]}"; do
  if [ -d "$SKILLS_DIR/$skill" ]; then
    echo "PASS: skill '$skill' present"
  else
    fail "Expected skill '$skill' missing from skills/"
  fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.3.0-skill-count — skill count is 18 (v9.5.0 post-cleanup), all expected skills present, deleted skills absent"
fi
exit "$FAIL"
