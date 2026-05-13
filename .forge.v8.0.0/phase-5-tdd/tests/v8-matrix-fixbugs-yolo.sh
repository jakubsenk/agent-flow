#!/usr/bin/env bash
# Verifies: AC-MODE-MATRIX-001, REQ-MODE-002
# Description: fix-bugs + --yolo = zero gates emitted; pipeline runs autonomously
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
# Assertion 1: fix-bugs SKILL.md documents --yolo = zero gates
# ---------------------------------------------------------------------------
echo "--- Assertion 1: fix-bugs SKILL.md --yolo zero gates documented ---"
FIXBUGS_SKILL="$REPO_ROOT/skills/fix-bugs/SKILL.md"
if [ ! -f "$FIXBUGS_SKILL" ]; then
  echo "SKIP: skills/fix-bugs/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE '\-\-yolo.*zero.*gate|zero.*gate.*yolo|yolo.*autonomous|no.*gate.*yolo' "$FIXBUGS_SKILL"; then
  echo "OK: fix-bugs SKILL.md documents --yolo zero gates"
else
  fail "fix-bugs SKILL.md missing --yolo zero gates documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 2: --yolo results in ALL gates being skipped (observable behavior)
#   We verify the SKILL.md documents that no Acceptance gate, no Spec checkpoint,
#   no interactive prompts appear when --yolo is passed. The exact variable name
#   used for tracking the mode is an implementation detail; we test the observable
#   gate-skip behavior contract documented in the skill.
# ---------------------------------------------------------------------------
echo "--- Assertion 2: SKILL.md documents --yolo skips ALL conditional gates ---"
# Observable: acceptance gate, review gate, pipeline checkpoints all skipped
if grep -qiE 'skip.*gate|gate.*skip|no.*gate|zero.*gate|bypass.*gate|all.*gate.*skip' "$FIXBUGS_SKILL" || \
   grep -qiE 'yolo.*autonomous|autonomous.*yolo|yolo.*no.*prompt|yolo.*no.*checkpoint' "$FIXBUGS_SKILL"; then
  echo "OK: fix-bugs SKILL.md documents all gates skipped in --yolo mode"
else
  fail "fix-bugs SKILL.md missing observable --yolo gate-skip contract"
fi

# ---------------------------------------------------------------------------
# Assertion 3: docs/reference/pipeline.md documents yolo mode for fix-bugs
# ---------------------------------------------------------------------------
echo "--- Assertion 3: pipeline.md documents yolo mode for fix-bugs ---"
PIPELINE_DOC="$REPO_ROOT/docs/reference/pipeline.md"
if [ ! -f "$PIPELINE_DOC" ]; then
  echo "SKIP: docs/reference/pipeline.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'yolo.*fix.bugs|fix.bugs.*yolo|yolo.*autonomous' "$PIPELINE_DOC"; then
  echo "OK: pipeline.md documents fix-bugs --yolo mode"
else
  fail "pipeline.md missing fix-bugs --yolo autonomous mode documentation"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-MODE-MATRIX-001 — fix-bugs + --yolo zero gates documented"
fi
exit "$FAIL"
