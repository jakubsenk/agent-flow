#!/usr/bin/env bash
# AC-PAUSE-LIMITS-DOC-1, AC-PAUSE-LIMITS-DOC-2
# Asserts the Pause Limits row in docs/reference/automation-config.md Quick reference
# table lists all 6 lifecycle participants (per Phase 2 DISAGREEMENT B resolution):
# /fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket
# Old row (autopilot only) must be absent.
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

# Functional check 2: Pause Limits row now lists all 6 participants
# The row must contain /fix-ticket as the key indicator (whole-row match per AC)
if ! grep -E '^\| Pause Limits \| No \| /fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket \|' "$DOC" >/dev/null 2>&1; then
  fail "$DOC: Pause Limits row does not list all 6 lifecycle participants (fix-ticket through resume-ticket)"
fi

# Functional check 3: old single-/autopilot row must be absent
if grep -E '^\| Pause Limits \| No \| /autopilot \|$' "$DOC" >/dev/null 2>&1; then
  fail "$DOC: old Pause Limits row with only /autopilot still present"
fi

# Functional check 4: each of the 6 skills is named in the row individually
# (structural check — verifies no partial list slipped through)
for skill in '/fix-ticket' '/fix-bugs' '/implement-feature' '/scaffold' '/autopilot' '/resume-ticket'; do
  if ! grep -E '^\| Pause Limits \|' "$DOC" | grep -q "$skill"; then
    fail "$DOC: Pause Limits row missing skill '$skill'"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: AC-PAUSE-LIMITS-DOC-1,2 — Pause Limits row lists all 6 lifecycle participants"
exit "$FAIL"
