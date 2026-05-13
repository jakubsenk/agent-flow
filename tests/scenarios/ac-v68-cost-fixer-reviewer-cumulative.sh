#!/usr/bin/env bash
set -euo pipefail

# AC-17: Fixer-reviewer accumulates cumulatively with no per-iteration array
# Traces: COST-R5
# Description: Verifies SKILL.md and schema.md do NOT document per-iteration breakdown arrays
#              for fixer_reviewer

# NOTE: Negative assertion — passes green if no per-iteration array language exists.
# Must remain green after Phase 7.

cd "$(dirname "$0")/../.."

FAIL=0

# AC-17 verify command from formal-criteria.md:
# grep -nE "fixer_reviewer.*(iteration_breakdown|per_iteration|iterations_detail)"
# ... expected: no matches

for file in skills/fix-ticket/SKILL.md state/schema.md; do
  if [ ! -f "$file" ]; then
    continue
  fi
  if grep -nE 'fixer_reviewer.*(iteration_breakdown|per_iteration|iterations_detail)' "$file" | grep -q .; then
    echo "FAIL: AC-17 — $file contains per-iteration array pattern for fixer_reviewer (must be absent)" >&2
    FAIL=1
  fi
done

# Positive: schema must document cumulative semantics (Phase 7 adds this)
# NOTE: This check is RED until Phase 7 adds the fixer_reviewer cumulative docs to state/schema.md
if [ -f "state/schema.md" ]; then
  if ! grep -qiE 'cumulat|cumulative' "state/schema.md"; then
    echo "FAIL: state/schema.md does not document cumulative accumulation for fixer_reviewer (add in Phase 7)" >&2
    FAIL=1
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-17 — no per-iteration breakdown array for fixer_reviewer"
exit "$FAIL"
