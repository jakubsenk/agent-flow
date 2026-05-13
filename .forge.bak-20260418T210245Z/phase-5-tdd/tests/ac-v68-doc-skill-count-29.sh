#!/usr/bin/env bash
set -euo pipefail

# AC-23: Skill count bumped 28 → 29 in CLAUDE.md and docs/reference/skills.md
# Traces: AUTOPILOT-R1
# Description: Verifies CLAUDE.md and docs/reference/skills.md mention 29 skills, not 28

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../../.."

FAIL=0

# CLAUDE.md must have 29 skills
if ! grep -nE '29 skills' CLAUDE.md | grep -q .; then
  echo "FAIL: CLAUDE.md does not contain '29 skills'" >&2
  FAIL=1
fi

# CLAUDE.md must NOT have 28 skills (old count)
if grep -nE '28 skills' CLAUDE.md | grep -q .; then
  echo "FAIL: CLAUDE.md still contains '28 skills' — must be replaced by '29 skills'" >&2
  FAIL=1
fi

# docs/reference/skills.md check
SKILLS_REF="docs/reference/skills.md"
if [ -f "$SKILLS_REF" ]; then
  if ! grep -nE '29 skills' "$SKILLS_REF" | grep -q .; then
    echo "FAIL: $SKILLS_REF does not contain '29 skills'" >&2
    FAIL=1
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-23 — CLAUDE.md and docs/reference/skills.md show 29 skills"
exit "$FAIL"
