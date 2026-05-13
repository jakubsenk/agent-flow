#!/usr/bin/env bash
# v9.3.0 TDD — tests written before implementation
# T-04: Skill deletion verification (AC-025 through AC-027)
#
# Tests that skills/fix-ticket/, skills/scaffold-add/, and skills/resume-ticket/
# directories DO NOT EXIST after v9.3.0 deployment.
# No passthrough stubs are shipped per Gate 1 design.
#
# RED until Phase 7 implementation is complete — that is correct TDD behavior.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
[ -f "$REPO_ROOT/tests/lib/fixtures.sh" ] || REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# AC-025: skills/fix-ticket/ directory DOES NOT EXIST
# ---------------------------------------------------------------------------
echo "--- AC-025: skills/fix-ticket/ does NOT exist ---"
if [ -e "$REPO_ROOT/skills/fix-ticket" ]; then
  fail "AC-025 — skills/fix-ticket/ still exists (Phase 7 deletion not applied)"
else
  echo "PASS: skills/fix-ticket/ correctly absent"
fi

# Double-check the SKILL.md file specifically
if [ -f "$REPO_ROOT/skills/fix-ticket/SKILL.md" ]; then
  fail "AC-025 — skills/fix-ticket/SKILL.md still exists"
else
  echo "PASS: skills/fix-ticket/SKILL.md correctly absent"
fi

# ---------------------------------------------------------------------------
# AC-026: skills/scaffold-add/ directory DOES NOT EXIST
# ---------------------------------------------------------------------------
echo "--- AC-026: skills/scaffold-add/ does NOT exist ---"
if [ -e "$REPO_ROOT/skills/scaffold-add" ]; then
  fail "AC-026 — skills/scaffold-add/ still exists (Phase 7 deletion not applied)"
else
  echo "PASS: skills/scaffold-add/ correctly absent"
fi

if [ -f "$REPO_ROOT/skills/scaffold-add/SKILL.md" ]; then
  fail "AC-026 — skills/scaffold-add/SKILL.md still exists"
else
  echo "PASS: skills/scaffold-add/SKILL.md correctly absent"
fi

# ---------------------------------------------------------------------------
# AC-027: skills/resume-ticket/ directory DOES NOT EXIST
# ---------------------------------------------------------------------------
echo "--- AC-027: skills/resume-ticket/ does NOT exist ---"
if [ -e "$REPO_ROOT/skills/resume-ticket" ]; then
  fail "AC-027 — skills/resume-ticket/ still exists (Phase 7 deletion not applied)"
else
  echo "PASS: skills/resume-ticket/ correctly absent"
fi

if [ -f "$REPO_ROOT/skills/resume-ticket/SKILL.md" ]; then
  fail "AC-027 — skills/resume-ticket/SKILL.md still exists"
else
  echo "PASS: skills/resume-ticket/SKILL.md correctly absent"
fi

# ---------------------------------------------------------------------------
# AC-044 (bonus): No DEPRECATED v9.3.0 passthrough markers in any skill
# Gate 1 explicitly forbids passthrough stubs.
# ---------------------------------------------------------------------------
echo "--- AC-044: No [DEPRECATED v9.3.0] passthrough markers ---"
DEPRECATED_HITS=$(grep -rln 'DEPRECATED v9.3.0' "$REPO_ROOT/skills/" 2>/dev/null || true)
if [ -n "$DEPRECATED_HITS" ]; then
  fail "AC-044 — Found DEPRECATED v9.3.0 markers in skills/ (no passthroughs allowed): $DEPRECATED_HITS"
else
  echo "PASS: No DEPRECATED v9.3.0 passthrough markers found in skills/"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.3.0-skill-deletion-check — all skill deletion checks passed"
fi
exit "$FAIL"
