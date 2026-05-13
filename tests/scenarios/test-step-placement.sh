#!/usr/bin/env bash
# Test: FC-1, FC-3 — Tracker-subtask creation step exists at the correct logical
# position in each skill's step pipeline (v10 thin-controller layout).
#
# v10 layout: heading-based step ordering (### 5a, ### 4b-tracker) is replaced
# by numbered step files. Decomposition + tracker-subtask creation lives in
# step 03 of implement-feature and step 02 of fix-bugs, with shared logic in
# core/tracker-subtask-creator.md.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# -----------------------------------------------------------------------
# FC-1: implement-feature — decomposition + tracker-subtask creation step
#       exists in steps/, references the shared core contract, and is
#       logically positioned BEFORE the fixer-reviewer loop.
# -----------------------------------------------------------------------
IF_DIR="$REPO_ROOT/skills/implement-feature/steps"
IF_DECOMP=$(ls "$IF_DIR"/0?-decomp*.md 2>/dev/null | head -1)
IF_FIXER=$(ls "$IF_DIR"/0?-fixer*.md 2>/dev/null | head -1)

if [ -z "$IF_DECOMP" ]; then
  fail "FC-1: implement-feature/steps/ missing decomposition step file (NN-decomposition.md)"
elif ! grep -qiE 'Create tracker subtask|tracker-subtask|tracker_effective_status|tracker-subtask-creator' "$IF_DECOMP"; then
  fail "FC-1: implement-feature decomposition step does not mention tracker subtask creation"
fi

if [ -n "$IF_DECOMP" ] && [ -n "$IF_FIXER" ]; then
  decomp_num=$(basename "$IF_DECOMP" | sed -E 's/^([0-9]+)-.*/\1/')
  fixer_num=$(basename "$IF_FIXER" | sed -E 's/^([0-9]+)-.*/\1/')
  if [ "$decomp_num" -ge "$fixer_num" ]; then
    fail "FC-1: decomposition step ($decomp_num) must come before fixer-reviewer step ($fixer_num)"
  fi
fi

# -----------------------------------------------------------------------
# FC-3: fix-bugs — decomposition mechanics exist in step 02 (impact +
#       decomposition decision) and reference the shared core contract.
# -----------------------------------------------------------------------
FB_DIR="$REPO_ROOT/skills/fix-bugs/steps"
FB_IMPACT="$FB_DIR/02-impact.md"
FB_FIXER=$(ls "$FB_DIR"/0?-fixer*.md 2>/dev/null | head -1)

if [ ! -f "$FB_IMPACT" ]; then
  fail "FC-3: skills/fix-bugs/steps/02-impact.md missing"
elif ! grep -qiE 'decomposition\.decision|Create tracker subtask|tracker-subtask-creator|decomposition-heuristics' "$FB_IMPACT"; then
  fail "FC-3: fix-bugs step 02-impact.md does not reference decomposition mechanics"
fi

if [ -f "$FB_IMPACT" ] && [ -n "$FB_FIXER" ]; then
  fb_decomp_num=02
  fb_fixer_num=$(basename "$FB_FIXER" | sed -E 's/^([0-9]+)-.*/\1/')
  if [ "$fb_decomp_num" -ge "$fb_fixer_num" ]; then
    fail "FC-3: fix-bugs decomposition step ($fb_decomp_num) must come before fixer-reviewer step ($fb_fixer_num)"
  fi
fi

# -----------------------------------------------------------------------
# Shared contract: core/tracker-subtask-creator.md must exist
# -----------------------------------------------------------------------
if [ ! -f "$REPO_ROOT/core/tracker-subtask-creator.md" ]; then
  fail "Shared core contract missing: core/tracker-subtask-creator.md"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Tracker-subtask creation step exists at correct logical position in v10 thin-controller layout (FC-1, FC-3)"
exit "$FAIL"
