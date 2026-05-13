#!/usr/bin/env bash
# Hidden adversarial test — do NOT reference in spec/visible
# Tests: --step-mode abort mid-step → resume-ticket correctly picks up from next step
# Edge: last_completed_step is 04, resume must start at 05 (not re-run 04)
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
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
# Setup: state.json with step-mode abort after step 04
# ---------------------------------------------------------------------------
mkdir -p "$TMPDIR_TEST/.ceos-agents"

cat > "$TMPDIR_TEST/.ceos-agents/state.json" << 'EOF'
{
  "schema_version": "1.0",
  "issue_id": "BUG-555",
  "pipeline": "fix-bugs",
  "outcome": "paused",
  "pause_reason": "step_mode_abort",
  "last_completed_step": "04-fixer-reviewer-loop",
  "paused_at": "2026-04-27T12:00:00Z"
}
EOF

# ---------------------------------------------------------------------------
# Assertion 1: state.json correctly identifies last_completed_step
# ---------------------------------------------------------------------------
echo "--- Assertion 1: state.json last_completed_step = 04-fixer-reviewer-loop ---"
if command -v jq > /dev/null 2>&1; then
  LAST_STEP=$(jq -r '.last_completed_step' "$TMPDIR_TEST/.ceos-agents/state.json")
  if [ "$LAST_STEP" = "04-fixer-reviewer-loop" ]; then
    echo "OK: last_completed_step = 04-fixer-reviewer-loop"
  else
    fail "last_completed_step = '$LAST_STEP' (expected 04-fixer-reviewer-loop)"
  fi
else
  grep -qF '"last_completed_step": "04-fixer-reviewer-loop"' "$TMPDIR_TEST/.ceos-agents/state.json" && \
    echo "OK (grep): last_completed_step = 04-fixer-reviewer-loop" || \
    fail "last_completed_step not found"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Resume logic should start from step 05 (next after 04)
# ---------------------------------------------------------------------------
echo "--- Assertion 2: resume from step 05 (next after 04) ---"
# Verify the step ordering in fix-bugs/steps/ (04 is 4th, 05 is 5th)
STEPS_DIR="$REPO_ROOT/skills/fix-bugs/steps"
if [ -d "$STEPS_DIR" ]; then
  STEP_04=$(find "$STEPS_DIR" -maxdepth 1 -name '04-*.md' -type f | head -1)
  STEP_05=$(find "$STEPS_DIR" -maxdepth 1 -name '05-*.md' -type f | head -1)
  if [ -n "$STEP_04" ] && [ -n "$STEP_05" ]; then
    echo "OK: fix-bugs/steps/ has both 04-* and 05-* files (resume from 05 is possible)"
  else
    echo "SKIP: fix-bugs/steps/ not populated yet (implementation pending)" >&2
    exit 77
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 3: resume-ticket SKILL.md documents step_mode_abort resume logic
# ---------------------------------------------------------------------------
echo "--- Assertion 3: resume-ticket SKILL.md documents step_mode_abort resume ---"
RESUME_SKILL="$REPO_ROOT/skills/resume-ticket/SKILL.md"
if [ ! -f "$RESUME_SKILL" ]; then
  echo "SKIP: skills/resume-ticket/SKILL.md not found" >&2
  exit 77
fi

if grep -qiE 'step_mode_abort|step.mode.*abort|last_completed_step.*resume' "$RESUME_SKILL"; then
  echo "OK: resume-ticket SKILL.md documents step_mode_abort resume"
else
  fail "resume-ticket SKILL.md missing step_mode_abort resume logic"
fi

# AC-MODE-007: resume from last_completed_step + 1
if grep -qiE 'last.*completed.*step.*\+.*1|next.*after.*last|resume.*from.*next' "$RESUME_SKILL"; then
  echo "OK: resume-ticket SKILL.md resumes from last_completed_step + 1"
else
  fail "resume-ticket SKILL.md missing 'resume from next step' logic"
fi

# ---------------------------------------------------------------------------
# Assertion 4: Off-by-one guard — step 04 NOT re-executed on resume
# ---------------------------------------------------------------------------
echo "--- Assertion 4: step 04 NOT re-executed (only 05+ on resume) ---"
if grep -qiE 'NOT.*re.?execut|skip.*completed|begin.*next.*step|start.*after' "$RESUME_SKILL"; then
  echo "OK: resume-ticket SKILL.md guards against re-executing completed steps"
else
  fail "resume-ticket SKILL.md missing guard against re-executing last_completed_step"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: step-mode abort → resume correctly starts from next step (no re-run of 04)"
fi
exit "$FAIL"
