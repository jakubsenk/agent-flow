#!/bin/bash
# Covers: AC-13 (Block Comment Template uses "Agent: analyst" not "Agent: triage-analyst"
#         in both skills/fix-bugs/SKILL.md and skills/analyze-bug/SKILL.md)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: v9-5-block-comment-template — $1"; FAIL=1; }

for skill_file in "$REPO_ROOT/skills/fix-bugs/SKILL.md" "$REPO_ROOT/skills/analyze-bug/SKILL.md"; do
  if [ ! -f "$skill_file" ]; then
    fail "$skill_file not found"
    continue
  fi

  skill_name=$(basename "$(dirname "$skill_file")")
  skill_dir="$(dirname "$skill_file")"

  # v10 thin-controller: Block Comment Template lives in step files (e.g.,
  # steps/01-triage.md for fix-bugs). Aggregate SKILL.md + steps/*.md.
  agg_tmp=$(mktemp)
  cat "$skill_file" > "$agg_tmp"
  [ -d "$skill_dir/steps" ] && cat "$skill_dir/steps"/*.md >> "$agg_tmp"

  # Must have canonical form
  if grep -qE '^[[:space:]]*Agent: analyst$' "$agg_tmp"; then
    echo "PASS: $skill_name has 'Agent: analyst' in Block Comment Template"
  else
    fail "$skill_name missing 'Agent: analyst' line in Block Comment Template"
  fi

  # Must NOT have old v7 form
  if grep -qE '^[[:space:]]*Agent: triage-analyst$' "$agg_tmp"; then
    fail "$skill_name still has 'Agent: triage-analyst' — must be updated to 'Agent: analyst'"
  else
    echo "PASS: $skill_name does not contain 'Agent: triage-analyst'"
  fi
  rm -f "$agg_tmp"
done

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-block-comment-template — both skills use 'Agent: analyst'"
fi
exit "$FAIL"
