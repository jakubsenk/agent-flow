#!/usr/bin/env bash
# AC-PAUSE-LIMITS-DOC-1, AC-PAUSE-LIMITS-DOC-2
# Asserts the Pause Limits row in docs/reference/automation-config.md Quick reference
# table lists active lifecycle participants (v9.3.0: 4 participants after fix-ticket + resume-ticket deletion):
# /fix-bugs, /implement-feature, /scaffold, /autopilot
# Old row (fix-ticket + resume-ticket) must be absent.
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

DOC="docs/reference/automation-config.md"

# Functional check 1: doc file exists
if [ ! -f "$DOC" ]; then
  echo "FAIL: $DOC missing" >&2
  exit 1
fi

# Functional check 2: Pause Limits row lists v9.3.0 participants (4, not 6)
if ! grep -E '^\| Pause Limits \|' "$DOC" | grep -q '/fix-bugs'; then
  fail "$DOC: Pause Limits row missing /fix-bugs"
fi

# Functional check 3: deleted skills must NOT appear in Pause Limits row
for deleted in '/fix-ticket' '/resume-ticket'; do
  if grep -E '^\| Pause Limits \|' "$DOC" | grep -q "$deleted"; then
    fail "$DOC: Pause Limits row still lists deleted skill '$deleted'"
  fi
done

# Functional check 4: each of the 4 active skills is named in the row
for skill in '/fix-bugs' '/implement-feature' '/scaffold' '/autopilot'; do
  if ! grep -E '^\| Pause Limits \|' "$DOC" | grep -q "$skill"; then
    fail "$DOC: Pause Limits row missing skill '$skill'"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: AC-PAUSE-LIMITS-DOC-1,2 — Pause Limits row lists all v9.3.0 lifecycle participants"
exit "$FAIL"
