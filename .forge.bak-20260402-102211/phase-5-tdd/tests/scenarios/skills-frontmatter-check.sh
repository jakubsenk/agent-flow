#!/usr/bin/env bash
# Test: Every SKILL.md has required frontmatter, and pipeline skills have disable-model-invocation
# Verifies: FC-4 (name + description), FC-5 (14 pipeline skills disable-model-invocation: true),
#           FC-6 (11 read-only skills do NOT have disable-model-invocation)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILLS_DIR="$REPO_ROOT/skills"

if [ ! -d "$SKILLS_DIR" ]; then
  echo "FAIL: skills/ directory not found at $SKILLS_DIR"
  exit 1
fi

# -----------------------------------------------------------------------
# FC-4: Every SKILL.md has name: and description: in frontmatter
# -----------------------------------------------------------------------
echo "--- FC-4: name: and description: in every SKILL.md ---"
for f in "$SKILLS_DIR"/*/SKILL.md; do
  if [ ! -f "$f" ]; then
    fail "No SKILL.md files found under $SKILLS_DIR"
    break
  fi

  skill_dir=$(basename "$(dirname "$f")")

  if ! grep -q "^name:" "$f"; then
    fail "$skill_dir/SKILL.md missing frontmatter field: name:"
  fi

  if ! grep -q "^description:" "$f"; then
    fail "$skill_dir/SKILL.md missing frontmatter field: description:"
  fi
done

# -----------------------------------------------------------------------
# FC-5: 14 pipeline skills have disable-model-invocation: true
# -----------------------------------------------------------------------
echo "--- FC-5: 14 pipeline skills have disable-model-invocation: true ---"

PIPELINE_SKILLS=(
  fix-ticket
  fix-bugs
  implement-feature
  scaffold
  publish
  create-pr
  onboard
  init
  scaffold-add
  check-deploy
  resume-ticket
  changelog
  version-bump
  migrate-config
)

pipeline_pass_count=0
for skill in "${PIPELINE_SKILLS[@]}"; do
  f="$SKILLS_DIR/$skill/SKILL.md"
  if [ ! -f "$f" ]; then
    fail "$skill/SKILL.md does not exist"
    continue
  fi
  if ! grep -q "^disable-model-invocation: true" "$f"; then
    fail "$skill/SKILL.md missing 'disable-model-invocation: true'"
  else
    echo "OK: $skill has disable-model-invocation: true"
    ((pipeline_pass_count++))
  fi
done

if [ "$pipeline_pass_count" -eq "${#PIPELINE_SKILLS[@]}" ]; then
  echo "OK: all ${#PIPELINE_SKILLS[@]} pipeline skills have disable-model-invocation: true"
fi

# -----------------------------------------------------------------------
# FC-6: 11 read-only skills do NOT have disable-model-invocation
# -----------------------------------------------------------------------
echo "--- FC-6: 11 read-only skills do NOT have disable-model-invocation ---"

READONLY_SKILLS=(
  analyze-bug
  check-setup
  status
  dashboard
  metrics
  estimate
  prioritize
  template
  scaffold-validate
  version-check
  discuss
)

readonly_pass_count=0
for skill in "${READONLY_SKILLS[@]}"; do
  f="$SKILLS_DIR/$skill/SKILL.md"
  if [ ! -f "$f" ]; then
    fail "$skill/SKILL.md does not exist"
    continue
  fi
  if grep -q "disable-model-invocation" "$f"; then
    fail "$skill/SKILL.md has 'disable-model-invocation' but should not (it is a read-only skill)"
  else
    echo "OK: $skill correctly omits disable-model-invocation"
    ((readonly_pass_count++))
  fi
done

if [ "$readonly_pass_count" -eq "${#READONLY_SKILLS[@]}" ]; then
  echo "OK: all ${#READONLY_SKILLS[@]} read-only skills omit disable-model-invocation"
fi

# -----------------------------------------------------------------------
# Final result
# -----------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: skills frontmatter check — FC-4 (name/description), FC-5 (14 pipeline skills), FC-6 (11 read-only skills)"
fi
exit "$FAIL"
