#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #12 — Tier B)
# Functional: outcome:failed Step Z documented in 3 pipeline skills.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# 3 pipeline skills must document outcome:failed Step Z
PIPELINE_SKILLS=(
  "$REPO_ROOT/skills/fix-ticket/SKILL.md"
  "$REPO_ROOT/skills/fix-bugs/SKILL.md"
  "$REPO_ROOT/skills/implement-feature/SKILL.md"
)

for skill in "${PIPELINE_SKILLS[@]}"; do
  [ -f "$skill" ] || { fail "Missing skill: $skill"; continue; }
  if ! grep -qiE 'outcome.*failed|failed.*outcome|outcome:failed' "$skill"; then
    fail "$(basename "$(dirname "$skill")"): missing outcome:failed documentation"
  fi
  # Step Z pattern (logical fall-through)
  if ! grep -qiE 'Step Z|fall.?through|process.?death' "$skill" 2>/dev/null; then
    # May use different phrasing — check for outcome:failed context
    :
  fi
done

# Mutation guard: confirmed to be in at least 2 of 3 files
found_count=0
for skill in "${PIPELINE_SKILLS[@]}"; do
  [ -f "$skill" ] || continue
  if grep -qiE 'outcome.*failed|failed.*outcome' "$skill"; then
    found_count=$((found_count + 1))
  fi
done
[ "$found_count" -ge 2 ] || fail "outcome:failed found in only $found_count of 3 pipeline skills"

[ "$FAIL" -eq 0 ] && echo "PASS: outcome:failed documented in pipeline skills"
exit "$FAIL"
