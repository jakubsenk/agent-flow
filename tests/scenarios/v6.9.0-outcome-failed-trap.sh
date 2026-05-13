#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #12 — Tier B)
# Functional: outcome:failed Step Z documented in 3 pipeline skills.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# 3 pipeline skills must document outcome:failed Step Z
# (fix-ticket removed in v9.3.0 — its logic absorbed into fix-bugs)
PIPELINE_SKILLS=(
  "$REPO_ROOT/skills/fix-bugs/SKILL.md"
  "$REPO_ROOT/skills/implement-feature/SKILL.md"
)

# v10 thin-controller: outcome:failed trap detail lives in step files
# (block-handler / publish / result steps). Aggregate SKILL.md + steps/*.md.
agg_for() {
  local skill="$1"
  local skill_dir
  skill_dir="$(dirname "$skill")"
  cat "$skill" 2>/dev/null
  [ -d "$skill_dir/steps" ] && cat "$skill_dir/steps"/*.md 2>/dev/null
}

for skill in "${PIPELINE_SKILLS[@]}"; do
  [ -f "$skill" ] || { fail "Missing skill: $skill"; continue; }
  body=$(agg_for "$skill")
  if ! printf '%s' "$body" | grep -qiE 'outcome.*failed|failed.*outcome|outcome:failed'; then
    fail "$(basename "$(dirname "$skill")"): missing outcome:failed documentation"
  fi
done

# Mutation guard: confirmed to be in at least 1 of 2 files
found_count=0
for skill in "${PIPELINE_SKILLS[@]}"; do
  [ -f "$skill" ] || continue
  body=$(agg_for "$skill")
  if printf '%s' "$body" | grep -qiE 'outcome.*failed|failed.*outcome'; then
    found_count=$((found_count + 1))
  fi
done
[ "$found_count" -ge 1 ] || fail "outcome:failed found in only $found_count of 2 pipeline skills"

[ "$FAIL" -eq 0 ] && echo "PASS: outcome:failed documented in pipeline skills"
exit "$FAIL"
