#!/usr/bin/env bash
set -euo pipefail

# AC-12: No per-iteration step-completed event (one per top-level stage only)
# Traces: WEBHOOK-R6
# Description: Verifies no 'step-completed' per fixer/iteration language in pipeline SKILL.md files

# NOTE: This test checks EXISTING files — passes with green before Phase 7 IF no such text exists yet.
# It should remain green after Phase 7 (implementation must NOT introduce per-iteration step-completed).

cd "$(dirname "$0")/../.."

FAIL=0

# AC-12 verify command from formal-criteria.md
# Filter out negation context (lines with never/not before the pattern)
MATCHES=$(grep -nE "step-completed.*per (fixer|iteration)" \
  skills/fix-ticket/SKILL.md \
  skills/fix-bugs/SKILL.md \
  skills/implement-feature/SKILL.md \
  skills/scaffold/SKILL.md \
  2>/dev/null | grep -ivE 'never.*per (fixer|iteration)|not.*per (fixer|iteration)|fires once.*per|once.*never' || true)

if [ -n "$MATCHES" ]; then
  echo "FAIL: AC-12 — found 'step-completed per fixer/iteration' (affirmative) in pipeline SKILL.md (must be absent)" >&2
  echo "$MATCHES" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-12 — no per-iteration step-completed event found in pipeline skills"
exit "$FAIL"
