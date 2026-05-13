#!/usr/bin/env bash
# Verifies: AC-MODE-MATRIX-007, REQ-MODE-002
# Description: scaffold + --yolo = zero gates, no brainstorm regardless of description vagueness
# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Assertion 1: scaffold SKILL.md documents --yolo zero gates/brainstorm
# ---------------------------------------------------------------------------
echo "--- Assertion 1: scaffold SKILL.md documents --yolo zero gates ---"
SCAFFOLD_SKILL="$REPO_ROOT/skills/scaffold/SKILL.md"
if [ ! -f "$SCAFFOLD_SKILL" ]; then
  echo "SKIP: skills/scaffold/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE '\-\-yolo|yolo.*no.*brainstorm|yolo.*zero.*gate' "$SCAFFOLD_SKILL"; then
  echo "OK: scaffold SKILL.md references --yolo flag"
else
  fail "scaffold SKILL.md missing --yolo zero-gates documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 2: --yolo skips brainstorm even for vague descriptions
# ---------------------------------------------------------------------------
echo "--- Assertion 2: --yolo skips brainstorm regardless of description vagueness ---"
if grep -qiE 'yolo.*brainstorm|brainstorm.*skip.*yolo|no.*brainstorm.*yolo' "$SCAFFOLD_SKILL"; then
  echo "OK: scaffold SKILL.md documents --yolo skips brainstorm"
else
  fail "scaffold SKILL.md missing --yolo skips brainstorm documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 3: --yolo triggers autonomous execution in scaffold
#   (Observable: no Spec checkpoint, no Feature Plan checkpoint, no user prompts)
# ---------------------------------------------------------------------------
echo "--- Assertion 3: scaffold --yolo autonomous execution (no checkpoint prompts) ---"
if grep -qiE 'yolo.*no.*checkpoint|yolo.*spec.*skip|yolo.*feature.*plan.*skip|yolo.*autonomous' "$SCAFFOLD_SKILL" || \
   grep -qiE 'skip.*checkpoint.*yolo|checkpoint.*skip.*yolo|all.*checkpoint.*skip' "$SCAFFOLD_SKILL"; then
  echo "OK: scaffold SKILL.md documents --yolo autonomous (no checkpoint prompts)"
else
  fail "scaffold SKILL.md missing observable --yolo autonomous execution contract"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-MODE-MATRIX-007 — scaffold --yolo zero gates + no brainstorm documented"
fi
exit "$FAIL"
