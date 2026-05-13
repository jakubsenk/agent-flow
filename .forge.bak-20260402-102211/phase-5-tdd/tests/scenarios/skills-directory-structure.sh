#!/usr/bin/env bash
# Test: skills/ directory structure is complete and correct after migration
# Verifies: FC-1 (commands/ deleted), FC-2 (26 skill directories), FC-3 (each has SKILL.md)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILLS_DIR="$REPO_ROOT/skills"

# -----------------------------------------------------------------------
# FC-1: commands/ directory does not exist
# -----------------------------------------------------------------------
echo "--- FC-1: commands/ directory must not exist ---"
if [ -d "$REPO_ROOT/commands" ]; then
  fail "commands/ directory still exists at $REPO_ROOT/commands — must be deleted after migration"
else
  echo "OK: commands/ directory does not exist"
fi

# -----------------------------------------------------------------------
# FC-2: skills/ contains exactly 26 directories
# -----------------------------------------------------------------------
echo "--- FC-2: skills/ contains exactly 26 directories ---"

# The 26 expected skill directories
EXPECTED_SKILLS=(
  analyze-bug
  changelog
  check-deploy
  check-setup
  create-pr
  dashboard
  discuss
  estimate
  fix-bugs
  fix-ticket
  implement-feature
  init
  metrics
  migrate-config
  onboard
  prioritize
  publish
  resume-ticket
  scaffold
  scaffold-add
  scaffold-validate
  status
  template
  version-bump
  version-check
  workflow-router
)

if [ ! -d "$SKILLS_DIR" ]; then
  fail "skills/ directory not found at $SKILLS_DIR"
  echo "Cannot continue without skills/ directory"
  exit 1
fi

# Count actual directories
actual_count=$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
expected_count="${#EXPECTED_SKILLS[@]}"  # 26

if [ "$actual_count" -eq "$expected_count" ]; then
  echo "OK: skills/ contains exactly $actual_count directories"
else
  fail "skills/ directory count: expected $expected_count, found $actual_count"
fi

# Verify each expected skill directory exists
for skill in "${EXPECTED_SKILLS[@]}"; do
  if [ -d "$SKILLS_DIR/$skill" ]; then
    echo "OK: skills/$skill/ exists"
  else
    fail "skills/$skill/ directory missing"
  fi
done

# Check for unexpected directories (directories not in the expected list)
while IFS= read -r dir; do
  skill_name=$(basename "$dir")
  found=0
  for expected in "${EXPECTED_SKILLS[@]}"; do
    if [ "$skill_name" = "$expected" ]; then
      found=1
      break
    fi
  done
  if [ "$found" -eq 0 ]; then
    fail "Unexpected directory found: skills/$skill_name/ (not in expected skill list)"
  fi
done < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

# -----------------------------------------------------------------------
# FC-3: Each skill directory contains exactly 1 file named SKILL.md
# -----------------------------------------------------------------------
echo "--- FC-3: Each skill directory contains exactly 1 SKILL.md ---"

fc3_fail=0
for dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$dir")
  skill_md_count=$(find "$dir" -maxdepth 1 -name "SKILL.md" | wc -l | tr -d ' ')

  if [ "$skill_md_count" -eq 1 ]; then
    echo "OK: skills/$skill_name/SKILL.md exists"
  elif [ "$skill_md_count" -eq 0 ]; then
    fail "skills/$skill_name/ has no SKILL.md"
    fc3_fail=1
  else
    fail "skills/$skill_name/ has $skill_md_count SKILL.md files (expected exactly 1)"
    fc3_fail=1
  fi
done

if [ "$fc3_fail" -eq 0 ]; then
  echo "OK: all skill directories contain exactly 1 SKILL.md"
fi

# -----------------------------------------------------------------------
# Final result
# -----------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: skills directory structure — FC-1 (commands/ deleted), FC-2 (26 directories), FC-3 (each has SKILL.md)"
fi
exit "$FAIL"
