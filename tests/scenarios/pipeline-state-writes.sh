#!/usr/bin/env bash
# Test: Each pipeline command references state.json writes for its major phases
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# Helper: assert that a file (or its v10 step tree) contains a pattern.
# In v10 thin-controller layout, the SKILL.md sequences via step files in steps/*.md.
# We aggregate SKILL.md + steps/*.md for the check.
assert_contains() {
  local file="$1" pattern="$2" label="$3"
  local skill_dir
  skill_dir="$(dirname "$file")"
  local files_to_check=("$file")
  if [ -d "$skill_dir/steps" ]; then
    while IFS= read -r -d '' f; do
      files_to_check+=("$f")
    done < <(find "$skill_dir/steps" -name '*.md' -type f -print0)
  fi
  if ! grep -hqE "$pattern" "${files_to_check[@]}"; then
    fail "$label: $(basename "$file") does not contain pattern: $pattern"
  fi
}

# --- fix-bugs/SKILL.md (absorbs fix-ticket) ---
FT="$REPO_ROOT/skills/fix-bugs/SKILL.md"
if [ ! -f "$FT" ]; then
  fail "skills/fix-bugs/SKILL.md does not exist"
else
  assert_contains "$FT" "triage\.status|triage\.acceptance_criteria" \
    "fix-bugs state: triage"
  assert_contains "$FT" "code_analysis\.status|code_analysis\." \
    "fix-bugs state: code_analysis"
  assert_contains "$FT" "fixer_reviewer\.(status|iterations)" \
    "fix-bugs state: fixer_reviewer"
  assert_contains "$FT" "test\.status" \
    "fix-bugs state: test"
  assert_contains "$FT" "publisher\.status" \
    "fix-bugs state: publisher"
fi

# --- implement-feature/SKILL.md ---
IF="$REPO_ROOT/skills/implement-feature/SKILL.md"
if [ ! -f "$IF" ]; then
  fail "skills/implement-feature/SKILL.md does not exist"
else
  # spec-analyst reuses triage field
  assert_contains "$IF" "triage\.status|triage\.acceptance_criteria" \
    "implement-feature state: triage (spec-analyst)"
  assert_contains "$IF" "fixer_reviewer\.(status|iterations)" \
    "implement-feature state: fixer_reviewer"
  assert_contains "$IF" "test\.status" \
    "implement-feature state: test"
  assert_contains "$IF" "publisher\.status" \
    "implement-feature state: publisher"
fi

# --- scaffold/SKILL.md ---
SC="$REPO_ROOT/skills/scaffold/SKILL.md"
if [ ! -f "$SC" ]; then
  fail "skills/scaffold/SKILL.md does not exist"
else
  assert_contains "$SC" "state\.json" \
    "scaffold state: state.json reference"
  # state-manager protocol must be followed
  assert_contains "$SC" "state-manager" \
    "scaffold state: state-manager reference"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: All pipeline commands reference state.json writes for their major phases"
exit "$FAIL"
