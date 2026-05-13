#!/usr/bin/env bash
# Verifies: AC-MODE-MATRIX-008, AC-MODE-008, AC-MODE-009, REQ-MODE-003, REQ-MODE-009
# Description: scaffold + default mode = brainstorm only for vague descriptions;
#   2 checkpoints (Spec + Feature Plan) always visible; no interactive 3-mode prompt
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Assertion 1: No interactive 3-mode prompt (a/b/c) in scaffold SKILL.md
# ---------------------------------------------------------------------------
echo "--- Assertion 1: scaffold SKILL.md has NO interactive a/b/c 3-mode prompt ---"
SCAFFOLD_SKILL="$REPO_ROOT/skills/scaffold/SKILL.md"
if [ ! -f "$SCAFFOLD_SKILL" ]; then
  echo "SKIP: skills/scaffold/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

# These are the REMOVED v7 strings per REQ-DOC-014
if grep -qF '(a) Interactive' "$SCAFFOLD_SKILL" || \
   grep -qF '(b) YOLO with checkpoint' "$SCAFFOLD_SKILL" || \
   grep -qF '(c) Full YOLO' "$SCAFFOLD_SKILL"; then
  fail "scaffold SKILL.md still contains v7 interactive 3-mode prompt strings (should be removed)"
else
  echo "OK: scaffold SKILL.md does not contain v7 3-mode prompt strings"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Brainstorm only for vague descriptions documented
# ---------------------------------------------------------------------------
echo "--- Assertion 2: brainstorm triggers only for vague descriptions in default mode ---"
if grep -qiE 'vague.*brainstorm|brainstorm.*vague|heuristic.*brainstorm' "$SCAFFOLD_SKILL"; then
  echo "OK: scaffold SKILL.md documents vague-description brainstorm trigger"
else
  fail "scaffold SKILL.md missing vague-description brainstorm trigger documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 3: 2 checkpoints (Spec + Feature Plan) in default mode
# ---------------------------------------------------------------------------
echo "--- Assertion 3: 2 checkpoints (Spec + Feature Plan) in scaffold default mode ---"
if grep -qiE 'spec.*checkpoint' "$SCAFFOLD_SKILL"; then
  echo "OK: scaffold SKILL.md documents Spec Checkpoint"
else
  fail "scaffold SKILL.md missing Spec Checkpoint in default mode"
fi

if grep -qiE 'feature.*plan.*checkpoint|checkpoint.*feature.*plan' "$SCAFFOLD_SKILL"; then
  echo "OK: scaffold SKILL.md documents Feature Plan Checkpoint"
else
  fail "scaffold SKILL.md missing Feature Plan Checkpoint"
fi

# ---------------------------------------------------------------------------
# Assertion 4: CLAUDE.md does NOT contain v7 mode descriptor strings
# ---------------------------------------------------------------------------
echo "--- Assertion 4 (AC-DOC-014b): CLAUDE.md has no v7 scaffold mode strings ---"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
if grep -qF '(a) Interactive' "$CLAUDE_MD" || \
   grep -qF '(b) YOLO with checkpoint' "$CLAUDE_MD" || \
   grep -qF '(c) Full YOLO' "$CLAUDE_MD"; then
  fail "CLAUDE.md still contains v7 scaffold mode strings (AC-DOC-014b)"
else
  echo "OK: CLAUDE.md does not contain v7 3-mode scaffold strings"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-MODE-MATRIX-008 + AC-MODE-008 — scaffold default mode: vague brainstorm + 2 checkpoints"
fi
exit "$FAIL"
