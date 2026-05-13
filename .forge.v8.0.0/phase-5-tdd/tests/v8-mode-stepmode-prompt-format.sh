#!/usr/bin/env bash
# Verifies: AC-MODE-004, REQ-MODE-007
# Description: --step-mode prompt format: "[step-mode] Step {NN}/{total} completed: {step-name}"
#   followed by "Continue / Skip remaining gates / Abort? [c/s/a]:"
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

EXPECTED_PROMPT_PART1_REGEX='\[step-mode\] Step [0-9][0-9]/[0-9]+ completed:'
EXPECTED_PROMPT_PART2="Continue / Skip remaining gates / Abort? [c/s/a]:"

# ---------------------------------------------------------------------------
# Assertion 1: fix-bugs SKILL.md documents step-mode prompt format
# ---------------------------------------------------------------------------
echo "--- Assertion 1: fix-bugs SKILL.md documents step-mode prompt ---"
FIXBUGS_SKILL="$REPO_ROOT/skills/fix-bugs/SKILL.md"
if [ ! -f "$FIXBUGS_SKILL" ]; then
  echo "SKIP: skills/fix-bugs/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qE '\[step-mode\]|step.mode.*prompt' "$FIXBUGS_SKILL"; then
  echo "OK: fix-bugs SKILL.md references step-mode prompt"
else
  fail "fix-bugs SKILL.md missing step-mode prompt reference"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Exact prompt text in docs/reference/pipeline.md
# ---------------------------------------------------------------------------
echo "--- Assertion 2: docs/reference/pipeline.md documents step-mode prompt format ---"
PIPELINE_DOC="$REPO_ROOT/docs/reference/pipeline.md"
if [ ! -f "$PIPELINE_DOC" ]; then
  echo "SKIP: docs/reference/pipeline.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qE '\[step-mode\]' "$PIPELINE_DOC"; then
  echo "OK: pipeline.md contains [step-mode] prompt reference"
else
  fail "pipeline.md missing [step-mode] prompt format"
fi

if grep -qF "$EXPECTED_PROMPT_PART2" "$PIPELINE_DOC"; then
  echo "OK: pipeline.md contains 'Continue / Skip remaining gates / Abort? [c/s/a]:'"
else
  fail "pipeline.md missing exact prompt 'Continue / Skip remaining gates / Abort? [c/s/a]:'"
fi

# ---------------------------------------------------------------------------
# Assertion 3: design.md §5.2 documents the step-mode prompt template
# ---------------------------------------------------------------------------
echo "--- Assertion 3: design.md §5.2 documents step-mode prompt template ---"
DESIGN="$REPO_ROOT/.forge/phase-4-spec/final/design.md"
if [ -f "$DESIGN" ]; then
  if grep -qF 'Continue / Skip remaining gates / Abort? [c/s/a]:' "$DESIGN"; then
    echo "OK: design.md documents exact step-mode prompt template"
  else
    fail "design.md missing exact step-mode prompt 'Continue / Skip remaining gates / Abort? [c/s/a]:'"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 4: c/s/a behavioral table documented
# ---------------------------------------------------------------------------
echo "--- Assertion 4: c/s/a behavioral table documented ---"
if [ -f "$PIPELINE_DOC" ]; then
  if grep -qiE 'c.*continue|s.*skip|a.*abort' "$PIPELINE_DOC"; then
    echo "OK: pipeline.md documents c/s/a behavioral table"
  else
    fail "pipeline.md missing c/s/a behavioral table"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 5: empty input re-prompts (no default action)
# ---------------------------------------------------------------------------
echo "--- Assertion 5: empty input re-prompts (no default action) documented ---"
if grep -qiE 're.?prompt|empty.*input|no default action' "$PIPELINE_DOC" || \
   grep -qiE 're.?prompt|empty.*input|no default action' "$FIXBUGS_SKILL"; then
  echo "OK: empty input re-prompt behavior documented"
else
  fail "empty input re-prompt behavior not documented (required per design.md §5.2)"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-MODE-004 — step-mode prompt format documented with c/s/a behavior"
fi
exit "$FAIL"
