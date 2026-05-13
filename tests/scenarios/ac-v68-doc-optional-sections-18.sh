#!/usr/bin/env bash
set -euo pipefail

# AC-22: Optional sections table bumped 17 → 18 in CLAUDE.md
# Traces: AUTOPILOT-R1
# Description: Verifies CLAUDE.md mentions 18 optional sections (not 17)

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FAIL=0

# Must have 18 or 19 optional (v6.9.0 bumped 18 → 19)
if ! grep -nE '(18|19) optional' CLAUDE.md | grep -q .; then
  echo "FAIL: CLAUDE.md does not contain '18 optional' or '19 optional' (optional sections table not bumped)" >&2
  FAIL=1
fi

# Must NOT have 17 optional (old count)
if grep -nE '17 optional' CLAUDE.md | grep -q .; then
  echo "FAIL: CLAUDE.md still contains '17 optional' — must be replaced by '18 optional' or higher" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-22 — CLAUDE.md shows 18 or 19 optional sections"
exit "$FAIL"
