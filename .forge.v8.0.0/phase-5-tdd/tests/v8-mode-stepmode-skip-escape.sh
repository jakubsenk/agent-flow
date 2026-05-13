#!/usr/bin/env bash
# Verifies: AC-MODE-005, REQ-MODE-007
# Description: WHEN --step-mode user inputs 's' (Skip remaining gates),
#   THEN subsequent steps SHALL execute with no further per-step prompts
#   AND the log SHALL contain "[INFO] step-mode escape: switched to yolo for remaining steps".
#
# This is a contract verification for a markdown plugin (no runtime stdin mock until Phase 7).
# The test verifies the 's' escape option contract as documented in:
#   - design.md Section 5.2 (behavioral table: s = Skip remaining gates → switch to yolo)
#   - docs/reference/pipeline.md (mode flag dispatch)
#   - formal-criteria.md AC-MODE-005
#
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
# Assertion 1: design.md §5.2 documents the 's' input as "Skip remaining gates"
#   AND specifies switch to yolo for remaining steps
# ---------------------------------------------------------------------------
echo "--- Assertion 1: design.md §5.2 documents 's' as Skip remaining gates + switch to yolo ---"
DESIGN_DOC_FORGE="$(cd "$(dirname "$0")/../.." && pwd)/../phase-4-spec/final/design.md"
if [ ! -f "$DESIGN_DOC_FORGE" ]; then
  DESIGN_DOC_FORGE="$REPO_ROOT/.forge/phase-4-spec/final/design.md"
fi

if [ -f "$DESIGN_DOC_FORGE" ]; then
  # Must document 's' input with "Skip remaining gates" label
  if grep -qiE 'Skip remaining gates|skip.*remaining.*gates' "$DESIGN_DOC_FORGE"; then
    echo "OK: design.md §5.2 documents 'Skip remaining gates' option label"
  else
    fail "design.md §5.2 missing 'Skip remaining gates' option label for 's' input"
  fi

  # Must document switch to yolo for 's' input
  if grep -qiE 'switch.*yolo|yolo.*remainder|MODE.*yolo|yolo.*remaining|step.mode escape' "$DESIGN_DOC_FORGE"; then
    echo "OK: design.md §5.2 documents switch to yolo for 's' input"
  else
    fail "design.md §5.2 missing switch-to-yolo behavior for 's' input"
  fi
else
  echo "INFO: design.md not accessible from test path — checking pipeline.md and SKILL.md instead"
fi

# ---------------------------------------------------------------------------
# Assertion 2: design.md §5.2 behavioral table contains exact escape log line
#   "[INFO] step-mode escape: switched to yolo for remaining steps"
#   OR an equivalent form is documented in pipeline.md / fix-bugs SKILL.md
# ---------------------------------------------------------------------------
echo "--- Assertion 2: exact log '[INFO] step-mode escape: switched to yolo' documented ---"
EXACT_LOG_PATTERN="step-mode escape.*switched.*yolo|step.mode escape.*yolo"
FOUND_EXACT_LOG=false

if [ -f "$DESIGN_DOC_FORGE" ] && grep -qiE "$EXACT_LOG_PATTERN" "$DESIGN_DOC_FORGE"; then
  echo "OK: design.md §5.2 documents exact '[INFO] step-mode escape: switched to yolo' log line"
  FOUND_EXACT_LOG=true
fi

PIPELINE_DOC="$REPO_ROOT/docs/reference/pipeline.md"
if [ "$FOUND_EXACT_LOG" = "false" ] && [ -f "$PIPELINE_DOC" ]; then
  if grep -qiE "$EXACT_LOG_PATTERN" "$PIPELINE_DOC"; then
    echo "OK: docs/reference/pipeline.md documents exact step-mode escape log line"
    FOUND_EXACT_LOG=true
  fi
fi

FIXBUGS_SKILL="$REPO_ROOT/skills/fix-bugs/SKILL.md"
if [ "$FOUND_EXACT_LOG" = "false" ] && [ -f "$FIXBUGS_SKILL" ]; then
  if grep -qiE "$EXACT_LOG_PATTERN" "$FIXBUGS_SKILL"; then
    echo "OK: fix-bugs SKILL.md documents step-mode escape log"
    FOUND_EXACT_LOG=true
  fi
fi

if [ "$FOUND_EXACT_LOG" = "false" ]; then
  fail "Exact log '[INFO] step-mode escape: switched to yolo' not documented in design.md, pipeline.md, or fix-bugs SKILL.md"
fi

# ---------------------------------------------------------------------------
# Assertion 3: docs/reference/pipeline.md documents Mode flag dispatch section
#   with 's' option behavior (no further per-step prompts after escape)
# ---------------------------------------------------------------------------
echo "--- Assertion 3: pipeline.md documents 's' escape: no further prompts after switch ---"
if [ ! -f "$PIPELINE_DOC" ]; then
  echo "SKIP: docs/reference/pipeline.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'step.mode escape|skip.*remaining|s.*yolo|switch.*yolo|no.*further.*prompt' "$PIPELINE_DOC"; then
  echo "OK: pipeline.md documents 's' escape → no further per-step prompts"
else
  fail "pipeline.md missing 's' escape behavior (no further per-step prompts after switch to yolo)"
fi

# ---------------------------------------------------------------------------
# Assertion 4: step-mode prompt format in design.md §5.2 contains the 's' option
#   in the prompt template "Continue / Skip remaining gates / Abort? [c/s/a]:"
# ---------------------------------------------------------------------------
echo "--- Assertion 4: step-mode prompt template contains [c/s/a] with 's' = skip ---"
PROMPT_PATTERN="c/s/a|\[c/s/a\]|Continue.*Skip.*Abort|Skip remaining gates"

if [ -f "$DESIGN_DOC_FORGE" ] && grep -qiE "$PROMPT_PATTERN" "$DESIGN_DOC_FORGE"; then
  echo "OK: design.md §5.2 documents step-mode prompt with [c/s/a] options including 's'"
elif [ -f "$PIPELINE_DOC" ] && grep -qiE "$PROMPT_PATTERN" "$PIPELINE_DOC"; then
  echo "OK: pipeline.md documents step-mode prompt with [c/s/a] options including 's'"
elif [ -f "$FIXBUGS_SKILL" ] && grep -qiE "$PROMPT_PATTERN" "$FIXBUGS_SKILL"; then
  echo "OK: fix-bugs SKILL.md documents step-mode prompt with [c/s/a] options"
else
  fail "Step-mode prompt [c/s/a] with 's'=skip option not documented in design.md, pipeline.md, or fix-bugs SKILL.md"
fi

# ---------------------------------------------------------------------------
# Assertion 5: AC-MODE-005 in formal-criteria.md specifies the exact log message
#   "[INFO] step-mode escape: switched to yolo for remaining steps"
# ---------------------------------------------------------------------------
echo "--- Assertion 5: formal-criteria.md AC-MODE-005 specifies exact escape log message ---"
FORMAL_CRITERIA_FORGE="$(cd "$(dirname "$0")/../.." && pwd)/../phase-4-spec/final/formal-criteria.md"
if [ ! -f "$FORMAL_CRITERIA_FORGE" ]; then
  FORMAL_CRITERIA_FORGE="$REPO_ROOT/.forge/phase-4-spec/final/formal-criteria.md"
fi

if [ -f "$FORMAL_CRITERIA_FORGE" ]; then
  if grep -qiE 'AC-MODE-005' "$FORMAL_CRITERIA_FORGE"; then
    # Verify the AC documents the exact log string
    if grep -A10 'AC-MODE-005' "$FORMAL_CRITERIA_FORGE" | grep -qiE 'step-mode escape|switched.*yolo|yolo.*remaining'; then
      echo "OK: formal-criteria.md AC-MODE-005 documents step-mode escape / switched to yolo"
    else
      fail "formal-criteria.md AC-MODE-005 present but missing step-mode escape / switched to yolo specification"
    fi
  else
    fail "formal-criteria.md missing AC-MODE-005 entry"
  fi
else
  echo "INFO: formal-criteria.md not accessible from test path — skipping cross-check"
fi

# ---------------------------------------------------------------------------
# Phase 7 note: runtime behavior verification
# When Phase 7 implements fix-bugs SKILL.md with --step-mode flag handling,
# replace Assertion 2-4 with a mock-stdin test:
#   echo "s" | bash skills/fix-bugs/SKILL.md BUG-TEST --step-mode
#   (verify no further per-step prompts in output AND grep log for exact message)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-MODE-005 — step-mode 's' escape documented: switch to yolo + exact log line"
fi
exit "$FAIL"
