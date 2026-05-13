#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #9 — Tier B)
# Functional: fixer agent has NEEDS_CLARIFICATION block in constraints.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

FIXER="$REPO_ROOT/agents/fixer.md"
[ -f "$FIXER" ] || { fail "agents/fixer.md not found"; exit 1; }

# Fixer Constraints must mention NEEDS_CLARIFICATION
if ! grep -qiE 'NEEDS_CLARIFICATION' "$FIXER"; then
  fail "agents/fixer.md ## Constraints missing NEEDS_CLARIFICATION mention"
fi

# NEEDS_CLARIFICATION must be in Constraints section (not just anywhere)
in_constraints=0
while IFS= read -r line; do
  if echo "$line" | grep -qE '^## Constraints'; then in_constraints=1; fi
  if echo "$line" | grep -qE '^## [A-Z]' && ! echo "$line" | grep -qE '^## Constraints'; then in_constraints=0; fi
  if [ "$in_constraints" -eq 1 ] && echo "$line" | grep -qiE 'NEEDS_CLARIFICATION'; then
    in_constraints=2; break
  fi
done < "$FIXER"
[ "$in_constraints" -eq 2 ] || fail "NEEDS_CLARIFICATION not found inside ## Constraints section of fixer.md"

# Fixer must emit the NEEDS_CLARIFICATION fenced block format
if ! grep -qiE 'NEEDS_CLARIFICATION|clarification_needed' "$FIXER"; then
  fail "agents/fixer.md missing NEEDS_CLARIFICATION output format"
fi

# Mutation guard: not just a comment
nc_lines=$(grep -cE 'NEEDS_CLARIFICATION' "$FIXER")
[ "$nc_lines" -ge 1 ] || fail "NEEDS_CLARIFICATION referenced 0 times in fixer.md"

[ "$FAIL" -eq 0 ] && echo "PASS: fixer.md NEEDS_CLARIFICATION constraint verified"
exit "$FAIL"
