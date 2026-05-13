#!/usr/bin/env bash
# v9.3.0 TDD — tests written before implementation
# T-07: core/resume-detection.md exists and has required structure (AC-028, AC-029, AC-030)
#
# Tests that core/resume-detection.md:
#   1. EXISTS at the expected path
#   2. Contains all 7 required structural elements (frontmatter, H1, 5 H2 sections)
#   3. Has Steps 1-10 under ## Process
#   4. Uses [[ =~ ]] for ISSUE_ID path-traversal validation (NOT grep -qE)
#   5. Contains ZERO jq invocations
#
# RED until Phase 7 implementation is complete — that is correct TDD behavior.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
[ -f "$REPO_ROOT/tests/lib/fixtures.sh" ] || REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

RESUME_CONTRACT="$REPO_ROOT/core/resume-detection.md"

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# AC-028: File exists
# ---------------------------------------------------------------------------
echo "--- AC-028: core/resume-detection.md EXISTS ---"
if [ ! -f "$RESUME_CONTRACT" ]; then
  echo "FAIL: core/resume-detection.md does not exist — Phase 7 must create it" >&2
  exit 1
fi
echo "PASS: core/resume-detection.md exists"

# ---------------------------------------------------------------------------
# AC-028: Structural element 1 — YAML frontmatter with name: resume-detection
# ---------------------------------------------------------------------------
echo "--- AC-028 element 1: YAML frontmatter 'name: resume-detection' ---"
if grep -qE '^name: resume-detection$' "$RESUME_CONTRACT"; then
  echo "PASS: frontmatter 'name: resume-detection' found"
else
  fail "AC-028 — frontmatter 'name: resume-detection' not found"
fi

# ---------------------------------------------------------------------------
# AC-028: Structural element 1b — version: v1 in frontmatter
# ---------------------------------------------------------------------------
echo "--- AC-028 element 1b: frontmatter 'version: v1' ---"
if grep -qE '^version: v1$' "$RESUME_CONTRACT"; then
  echo "PASS: frontmatter 'version: v1' found"
else
  fail "AC-028 — frontmatter 'version: v1' not found"
fi

# ---------------------------------------------------------------------------
# AC-028: Structural element 2 — # Resume Detection H1 heading
# ---------------------------------------------------------------------------
echo "--- AC-028 element 2: '# Resume Detection' H1 heading ---"
if grep -qE '^# Resume Detection$' "$RESUME_CONTRACT"; then
  echo "PASS: '# Resume Detection' H1 heading found"
else
  fail "AC-028 — '# Resume Detection' H1 heading not found"
fi

# ---------------------------------------------------------------------------
# AC-028: Structural element 3 — ## Purpose section
# ---------------------------------------------------------------------------
echo "--- AC-028 element 3: '## Purpose' section ---"
if grep -qE '^## Purpose$' "$RESUME_CONTRACT"; then
  echo "PASS: '## Purpose' section found"
else
  fail "AC-028 — '## Purpose' H2 section not found"
fi

# ---------------------------------------------------------------------------
# AC-028: Structural element 4 — ## Input Contract section
# ---------------------------------------------------------------------------
echo "--- AC-028 element 4: '## Input Contract' section ---"
if grep -qE '^## Input Contract$' "$RESUME_CONTRACT"; then
  echo "PASS: '## Input Contract' section found"
else
  fail "AC-028 — '## Input Contract' H2 section not found"
fi

# ---------------------------------------------------------------------------
# AC-028: Structural element 5 — ## Output Contract section
# ---------------------------------------------------------------------------
echo "--- AC-028 element 5: '## Output Contract' section ---"
if grep -qE '^## Output Contract$' "$RESUME_CONTRACT"; then
  echo "PASS: '## Output Contract' section found"
else
  fail "AC-028 — '## Output Contract' H2 section not found"
fi

# ---------------------------------------------------------------------------
# AC-028: Structural element 6 — ## Process section with numbered Steps 1-10
# ---------------------------------------------------------------------------
echo "--- AC-028 element 6: '## Process' section with Steps 1-10 ---"
if grep -qE '^## Process$' "$RESUME_CONTRACT"; then
  echo "PASS: '## Process' section found"
else
  fail "AC-028 — '## Process' H2 section not found"
fi

# Check that Steps 1 through 10 are present (as ### Step N or numbered list items)
for step_n in 1 2 3 4 5 6 7 8 9 10; do
  if grep -qE "Step ${step_n}[[:space:]]" "$RESUME_CONTRACT"; then
    echo "PASS: Step ${step_n} found in ## Process"
  else
    fail "AC-028 — Step ${step_n} not found in ## Process section"
  fi
done

# ---------------------------------------------------------------------------
# AC-028: Structural element 7 — ## Constraints section
# ---------------------------------------------------------------------------
echo "--- AC-028 element 7: '## Constraints' section ---"
if grep -qE '^## Constraints$' "$RESUME_CONTRACT"; then
  echo "PASS: '## Constraints' section found"
else
  fail "AC-028 — '## Constraints' H2 section not found"
fi

# ---------------------------------------------------------------------------
# AC-029: Uses [[ =~ ]] for ISSUE_ID path-traversal validation (NOT grep -qE)
# Critical: bash [[ =~ ]] anchors to entire string; grep -qE does not.
# ---------------------------------------------------------------------------
echo "--- AC-029: [[ =~ ]] operator used for ISSUE_ID validation ---"
if grep -qE '\[\[.*=~' "$RESUME_CONTRACT"; then
  echo "PASS: [[ =~ ]] operator found in resume-detection.md"
else
  fail "AC-029 — [[ =~ ]] operator not found; must use bash regex for whole-string ISSUE_ID anchoring"
fi

# Verify grep -qE is NOT used for ISSUE_ID validation (would miss multi-line payloads)
if grep -qF 'grep -qE.*ISSUE_ID' "$RESUME_CONTRACT"; then
  fail "AC-029 — grep -qE used for ISSUE_ID validation (INSECURE — use [[ =~ ]] instead)"
else
  echo "PASS: grep -qE not used for ISSUE_ID validation"
fi

# ---------------------------------------------------------------------------
# AC-030: ZERO jq invocations in core/resume-detection.md
# ---------------------------------------------------------------------------
echo "--- AC-030: No jq in core/resume-detection.md ---"
JQ_COUNT=$(grep -c '\bjq\b' "$RESUME_CONTRACT" 2>/dev/null || true)
JQ_COUNT="${JQ_COUNT:-0}"
if [ "${JQ_COUNT}" -eq 0 ]; then
  echo "PASS: No jq invocations found in resume-detection.md"
else
  fail "AC-030 — Found $JQ_COUNT jq invocation(s) in core/resume-detection.md; all parsing must use grep/sed/awk/tr"
fi

# ---------------------------------------------------------------------------
# Content check: Path-traversal check uses [BLOCK] prefix (AC-014 spec wording)
# ---------------------------------------------------------------------------
echo "--- AC-014: [BLOCK] message for path-traversal rejection ---"
if grep -qF '[BLOCK] Invalid issue_id' "$RESUME_CONTRACT"; then
  echo "PASS: '[BLOCK] Invalid issue_id' message found"
else
  fail "AC-014 — '[BLOCK] Invalid issue_id:' message not found in core/resume-detection.md"
fi

# ---------------------------------------------------------------------------
# Content check: Step 6 status matrix — all 5 status values handled
# ---------------------------------------------------------------------------
echo "--- AC-028: Step 6 handles all 5 status values ---"
for status in "running" "paused" "completed" "blocked" "aborted_by_system"; do
  if grep -qF "$status" "$RESUME_CONTRACT"; then
    echo "PASS: status '$status' referenced in resume-detection.md"
  else
    fail "AC-028 — status '$status' not found in Step 6 status matrix"
  fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.3.0-core-resume-detection-contract — all contract structure checks passed"
fi
exit "$FAIL"
