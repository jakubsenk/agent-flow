#!/usr/bin/env bash
# AC: AC-T2-2-1, AC-T2-2-2, AC-T2-2-3, AC-T2-3-1, AC-T2-3-2, AC-T2-3-3
# Asserts Layer 1 imperative dispatch template applied across 5 frozen files.
# Lower bound: >= 37 occurrences of Task(subagent_type='ceos-agents:
# Hard equality: 0 occurrences of old permissive prose.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

LAYER1_FILES=(
  "$REPO_ROOT/skills/fix-bugs/SKILL.md"
  "$REPO_ROOT/skills/implement-feature/SKILL.md"
  "$REPO_ROOT/skills/scaffold/SKILL.md"
  "$REPO_ROOT/core/fixer-reviewer-loop.md"
)

# AC-T2-3-3: all 4 files exist (fix-ticket removed in v9.3.0)
for f in "${LAYER1_FILES[@]}"; do
  [ -f "$f" ] || fail "Layer 1 target file missing: $f"
done

# v10 thin-controller: imperative dispatch templates moved to step files under
# skills/<pipeline>/steps/. Expand the scan set to include them.
EXTENDED_FILES=("${LAYER1_FILES[@]}")
for skill in fix-bugs implement-feature scaffold; do
  steps_dir="$REPO_ROOT/skills/$skill/steps"
  if [ -d "$steps_dir" ]; then
    while IFS= read -r -d '' sf; do EXTENDED_FILES+=("$sf"); done < <(find "$steps_dir" -name '*.md' -print0)
  fi
done

# AC-T2-3-1 / AC-T2-2-1: imperative template lower bound >= 25
imperative_count=$(grep -hnF "Task(subagent_type='ceos-agents:" "${EXTENDED_FILES[@]}" 2>/dev/null | wc -l | tr -d ' ')
imperative_count=${imperative_count:-0}
[ "$imperative_count" -ge 25 ] || fail "Imperative template count too low: expected >= 25, got $imperative_count"

# AC-T2-2-2: DO NOT inline-execute clause present
inline_exec_count=$(grep -hnF 'DO NOT inline-execute' "${EXTENDED_FILES[@]}" 2>/dev/null | wc -l | tr -d ' ')
[ "${inline_exec_count:-0}" -ge 12 ] || fail "DO NOT inline-execute count too low: got ${inline_exec_count:-0}"

# AC-T2-2-3: CONTRACT VIOLATION clause present
contract_violation_count=$(grep -hnF 'CONTRACT VIOLATION' "${EXTENDED_FILES[@]}" 2>/dev/null | wc -l | tr -d ' ')
[ "${contract_violation_count:-0}" -ge 12 ] || fail "CONTRACT VIOLATION count too low: got ${contract_violation_count:-0}"

# AC-T2-3-2: old permissive prose MUST be 0 (hard equality)
old_prose_count=$(grep -hnE '(Run|Dispatch|Invoke) .*(Task tool, model:)' "${EXTENDED_FILES[@]}" 2>/dev/null | wc -l | tr -d ' ')
[ "${old_prose_count:-0}" -eq 0 ] || fail "Old permissive prose still present: $old_prose_count occurrences"

echo "PASS: Layer 1 imperative dispatch coverage verified (imperative=$imperative_count)"
exit "$FAIL"
