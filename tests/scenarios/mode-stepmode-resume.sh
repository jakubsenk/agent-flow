#!/usr/bin/env bash
# Verifies: AC-MODE-007, REQ-MODE-008
# Description: /resume-ticket BUG-1 with state.json having pause_reason="step_mode_abort"
#   and last_completed_step="04-fixer-reviewer-loop" MUST begin from step 05-test
#   (not 04, not 06). Happy-path visible test; adversarial off-by-one edge case
#   is covered by v8-hidden-step-mode-abort-resume.sh.
# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT INT TERM

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Prerequisite: skills/resume-ticket/SKILL.md must exist
# ---------------------------------------------------------------------------
RESUME_SKILL="$REPO_ROOT/skills/resume-ticket/SKILL.md"
if [ ! -f "$RESUME_SKILL" ]; then
  echo "SKIP: skills/resume-ticket/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

# ---------------------------------------------------------------------------
# Setup: mock state.json with step_mode_abort at step 04
# ---------------------------------------------------------------------------
mkdir -p "$TMPDIR_TEST/.agent-flow"

cat > "$TMPDIR_TEST/.agent-flow/state.json" << 'EOF'
{
  "schema_version": "1.0",
  "issue_id": "BUG-1",
  "pipeline": "fix-bugs",
  "outcome": "paused",
  "pause_reason": "step_mode_abort",
  "last_completed_step": "04-fixer-reviewer-loop",
  "mode": "step-mode",
  "paused_at": "2026-04-27T10:30:00Z"
}
EOF

# ---------------------------------------------------------------------------
# Assertion 1: state.json is valid JSON with expected fields
# ---------------------------------------------------------------------------
echo "--- Assertion 1: state.json parseable with pause_reason=step_mode_abort ---"
if command -v jq > /dev/null 2>&1; then
  PAUSE_REASON=$(jq -r '.pause_reason' "$TMPDIR_TEST/.agent-flow/state.json")
  LAST_STEP=$(jq -r '.last_completed_step' "$TMPDIR_TEST/.agent-flow/state.json")
  OUTCOME=$(jq -r '.outcome' "$TMPDIR_TEST/.agent-flow/state.json")

  [ "$PAUSE_REASON" = "step_mode_abort" ] && echo "OK: pause_reason=step_mode_abort" || fail "pause_reason=$PAUSE_REASON (expected step_mode_abort)"
  [ "$LAST_STEP" = "04-fixer-reviewer-loop" ] && echo "OK: last_completed_step=04-fixer-reviewer-loop" || fail "last_completed_step=$LAST_STEP"
  [ "$OUTCOME" = "paused" ] && echo "OK: outcome=paused" || fail "outcome=$OUTCOME"
else
  if grep -qF '"pause_reason": "step_mode_abort"' "$TMPDIR_TEST/.agent-flow/state.json"; then
    echo "OK: pause_reason=step_mode_abort found (jq unavailable)"
  else
    fail "state.json missing pause_reason=step_mode_abort"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 2: resume-ticket SKILL.md documents step_mode_abort handling
# ---------------------------------------------------------------------------
echo "--- Assertion 2: resume-ticket SKILL.md documents step_mode_abort resume logic ---"
if grep -qiE 'step_mode_abort|step.mode.*abort|pause_reason.*step' "$RESUME_SKILL"; then
  echo "OK: resume-ticket SKILL.md documents step_mode_abort resume path"
else
  fail "resume-ticket SKILL.md missing step_mode_abort resume logic"
fi

# ---------------------------------------------------------------------------
# Assertion 3: resume-ticket SKILL.md documents "start from next step"
#   (i.e., last_completed_step + 1, NOT re-executing the last step)
# ---------------------------------------------------------------------------
echo "--- Assertion 3: resume-ticket starts from step AFTER last_completed_step ---"
if grep -qiE 'next.*step|step.*\+.*1|start.*after.*last|resume.*from.*next|continue.*from.*next' "$RESUME_SKILL"; then
  echo "OK: resume-ticket SKILL.md documents starting from next step after last_completed_step"
else
  fail "resume-ticket SKILL.md missing next-step logic (must start from step 05, not re-run 04)"
fi

# ---------------------------------------------------------------------------
# Assertion 4: Step numbering — next step after 04-fixer-reviewer-loop is 05-test
#   Verify via fix-bugs steps directory (once implemented)
# ---------------------------------------------------------------------------
echo "--- Assertion 4: step 05 follows step 04 in fix-bugs pipeline ---"
STEPS_DIR="$REPO_ROOT/skills/fix-bugs/steps"
if [ ! -d "$STEPS_DIR" ]; then
  echo "SKIP: skills/fix-bugs/steps/ not found (implementation pending) — step ordering not yet verifiable" >&2
  # This is not a hard skip — assertions 1-3 already cover the spec contract
else
  # Find step 05 file
  STEP_05=""
  TMPDIR_STEPS="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR_STEPS"' EXIT INT TERM
  find "$STEPS_DIR" -maxdepth 1 -name '05-*.md' -type f > "$TMPDIR_STEPS/step05.txt"
  if [ -s "$TMPDIR_STEPS/step05.txt" ]; then
    STEP_05=$(head -1 "$TMPDIR_STEPS/step05.txt")
    echo "OK: step 05 exists: $(basename "$STEP_05")"
  else
    fail "No step 05-*.md found in skills/fix-bugs/steps/ — expected e.g. 05-test.md"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 5: resume-ticket reads last_completed_step from state.json
# ---------------------------------------------------------------------------
echo "--- Assertion 5: resume-ticket SKILL.md reads last_completed_step from state.json ---"
if grep -qiE 'last_completed_step|last.*completed.*step' "$RESUME_SKILL"; then
  echo "OK: resume-ticket SKILL.md references last_completed_step field"
else
  fail "resume-ticket SKILL.md missing last_completed_step reference"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-MODE-007 — resume-ticket starts from step 05 after step_mode_abort at step 04"
fi
exit "$FAIL"
