#!/usr/bin/env bash
# v9.3.0 TDD — tests written before implementation
# T-02: Resume detection prompt behavior (AC-007 through AC-020)
#
# Tests the core/resume-detection.md contract existence and structural content.
# Also tests the --yolo matrix (AC-011 through AC-013) via SKILL.md content checks.
#
# RED until Phase 7 implementation is complete — that is correct TDD behavior.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
[ -f "$REPO_ROOT/tests/lib/fixtures.sh" ] || REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

SCRATCH="$(setup_scratch)"
trap "rm -rf '$SCRATCH'" EXIT

RESUME_CONTRACT="$REPO_ROOT/core/resume-detection.md"

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Prerequisite: core/resume-detection.md must exist
# ---------------------------------------------------------------------------
if [ ! -f "$RESUME_CONTRACT" ]; then
  echo "FAIL: core/resume-detection.md does not exist — resume detection contract not created" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# AC-007: state.json with status=running → prompt shown
# Verify the contract describes the interactive prompt for running status
# ---------------------------------------------------------------------------
echo "--- AC-007: status=running → prompt shown ---"
if grep -qF 'Found in-progress pipeline' "$RESUME_CONTRACT"; then
  echo "PASS: 'Found in-progress pipeline' prompt text found in resume-detection.md"
else
  fail "AC-007 — 'Found in-progress pipeline' prompt text not found in core/resume-detection.md"
fi

# ---------------------------------------------------------------------------
# AC-007 (continued): [Y=resume / n=restart / abort] prompt format
# ---------------------------------------------------------------------------
if grep -qF 'Y=resume / n=restart / abort' "$RESUME_CONTRACT"; then
  echo "PASS: '[Y=resume / n=restart / abort]' prompt format found"
else
  fail "AC-007 — '[Y=resume / n=restart / abort]' prompt format not found in core/resume-detection.md"
fi

# ---------------------------------------------------------------------------
# AC-008: status=completed → no prompt, fresh run (completed entry in status matrix)
# ---------------------------------------------------------------------------
echo "--- AC-008: status=completed (non-yolo) → prompt for new run confirmation ---"
if grep -qE '"completed"' "$RESUME_CONTRACT"; then
  echo "PASS: 'completed' status branch found in resume-detection.md"
else
  fail "AC-008 — 'completed' status branch not found in core/resume-detection.md"
fi

# ---------------------------------------------------------------------------
# AC-009: state.json absent → no prompt (FRESH path)
# ---------------------------------------------------------------------------
echo "--- AC-009: state.json absent → RESUME_POINT=FRESH ---"
if grep -qF 'RESUME_POINT="FRESH"' "$RESUME_CONTRACT" || grep -qF "RESUME_POINT='FRESH'" "$RESUME_CONTRACT"; then
  echo "PASS: RESUME_POINT=FRESH assignment found"
else
  fail "AC-009 — RESUME_POINT=\"FRESH\" assignment not found in core/resume-detection.md"
fi

# The no-state-file path must return 0 / exit early
if grep -qF '! -f "$STATE_FILE"' "$RESUME_CONTRACT"; then
  echo "PASS: state file absence check found"
else
  fail "AC-009 — state file absence check '! -f \"\$STATE_FILE\"' not found"
fi

# ---------------------------------------------------------------------------
# AC-011/AC-012: --yolo + status=paused behavior described
# AC-011: --yolo + paused + no clarification → exit 1
# AC-012: --yolo + paused + --clarification → continue
# ---------------------------------------------------------------------------
echo "--- AC-011: --yolo + paused + no clarification → exit 1 ---"
if grep -qF 'pipeline paused awaiting clarification' "$RESUME_CONTRACT"; then
  echo "PASS: '--yolo: pipeline paused awaiting clarification' warning text found"
else
  fail "AC-011 — '--yolo: pipeline paused awaiting clarification' not found in resume-detection.md"
fi

echo "--- AC-012: --yolo + paused + clarification text → continue ---"
if grep -qF 'CLARIFICATION_TEXT' "$RESUME_CONTRACT"; then
  echo "PASS: CLARIFICATION_TEXT variable referenced in resume-detection.md"
else
  fail "AC-012 — CLARIFICATION_TEXT not referenced in core/resume-detection.md"
fi

# ---------------------------------------------------------------------------
# AC-013: --yolo + status=completed → archive and start fresh
# ---------------------------------------------------------------------------
echo "--- AC-013: --yolo + status=completed → archive state.json ---"
if grep -qE 'state\.json\.\{.*run_id' "$RESUME_CONTRACT" || grep -qF 'state.json.{old_run_id}' "$RESUME_CONTRACT"; then
  echo "PASS: state.json archive naming pattern found"
else
  fail "AC-013 — state.json archive pattern 'state.json.{old_run_id}' not found in resume-detection.md"
fi

# ---------------------------------------------------------------------------
# AC-014: --yolo + blocked → warn and exit 1
# ---------------------------------------------------------------------------
echo "--- AC-014/blocked: --yolo + status=blocked → warn and exit 1 ---"
if grep -qF 'needs human resolution' "$RESUME_CONTRACT"; then
  echo "PASS: 'needs human resolution' warning text for blocked status found"
else
  fail "AC-014/blocked — '--yolo: skipping blocked pipeline — needs human resolution' not found"
fi

# ---------------------------------------------------------------------------
# AC-017: staleness check (updated_at > 7 days → STALENESS_WARN)
# ---------------------------------------------------------------------------
echo "--- AC-017: staleness check (>7 days) → STALENESS_WARN populated ---"
if grep -qF 'STALENESS_WARN' "$RESUME_CONTRACT"; then
  echo "PASS: STALENESS_WARN variable found in resume-detection.md"
else
  fail "AC-017 — STALENESS_WARN variable not found in core/resume-detection.md"
fi

# 7 days = 604800 seconds
if grep -qF '604800' "$RESUME_CONTRACT"; then
  echo "PASS: 604800 (7-day threshold in seconds) found in resume-detection.md"
else
  fail "AC-017 — 604800 (7-day staleness threshold) not found in core/resume-detection.md"
fi

if grep -qF 'stale' "$RESUME_CONTRACT"; then
  echo "PASS: 'stale' terminology found in staleness warning"
else
  fail "AC-017 — 'stale' not found in core/resume-detection.md staleness warning"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.3.0-resume-detection-prompt — all resume detection prompt checks passed"
fi
exit "$FAIL"
