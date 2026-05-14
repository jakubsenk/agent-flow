#!/usr/bin/env bash
# ===========================================================================
# Test:        v10-thin-controller-line-count.sh
# FC mapped:   FC-1 (sub-assertions A, B, C, D)
# What it checks:
#   A) skills/fix-bugs/SKILL.md ≤ 260 lines
#   A) skills/implement-feature/SKILL.md ≤ 200 lines
#   B) Verbatim "Use the Read tool to load" dispatch phrase present in both SKILL.md
#   C) Guard-block.md load instruction at file-position <6% (≤L16 fix-bugs / ≤L12 impl)
#   D) Zero inline Task() dispatch directives in SKILL.md body
# Expected RED phase: FAIL — current line counts are 929 / 371 + no guard-block
# Expected GREEN phase (post-impl): PASS
# CRLF-safe: uses `tr -d '\r' | wc -l` for line counting.
# ===========================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT" || { echo "FAIL: cannot cd to REPO_ROOT=$REPO_ROOT" >&2; exit 1; }

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# CRLF-safe line counter
count_lines() {
  # shellcheck disable=SC2002
  tr -d '\r' < "$1" | wc -l | tr -d ' '
}

# --- A. Line-count ceilings ---
FB_SKILL="skills/fix-bugs/SKILL.md"
IF_SKILL="skills/implement-feature/SKILL.md"

[ -f "$FB_SKILL" ] || { fail "missing $FB_SKILL"; exit 1; }
[ -f "$IF_SKILL" ] || { fail "missing $IF_SKILL"; exit 1; }

FB_LINES=$(count_lines "$FB_SKILL")
IF_LINES=$(count_lines "$IF_SKILL")

if [ "$FB_LINES" -gt 260 ]; then
  fail "FC-1.A1: $FB_SKILL = ${FB_LINES}L (ceiling 260)"
fi
if [ "$IF_LINES" -gt 200 ]; then
  fail "FC-1.A2: $IF_SKILL = ${IF_LINES}L (ceiling 200)"
fi

# --- B. Verbatim dispatch-table phrase present ---
if ! grep -q 'Use the Read tool to load' "$FB_SKILL"; then
  fail "FC-1.B1: $FB_SKILL missing 'Use the Read tool to load' phrase"
fi
if ! grep -q 'Use the Read tool to load' "$IF_SKILL"; then
  fail "FC-1.B2: $IF_SKILL missing 'Use the Read tool to load' phrase"
fi

# --- C. Guard-block load instruction at <6% file position ---
FB_GUARD_LINE=$(grep -n 'data/guard-block.md' "$FB_SKILL" | head -n 1 | cut -d: -f1)
IF_GUARD_LINE=$(grep -n 'data/guard-block.md' "$IF_SKILL" | head -n 1 | cut -d: -f1)

if [ -z "$FB_GUARD_LINE" ]; then
  fail "FC-1.C1: $FB_SKILL has no 'data/guard-block.md' load reference"
elif [ "$FB_GUARD_LINE" -gt 16 ]; then
  fail "FC-1.C1: $FB_SKILL guard-block load at L${FB_GUARD_LINE} (must be ≤16, i.e. 6% of 260)"
fi

if [ -z "$IF_GUARD_LINE" ]; then
  fail "FC-1.C2: $IF_SKILL has no 'data/guard-block.md' load reference"
elif [ "$IF_GUARD_LINE" -gt 12 ]; then
  fail "FC-1.C2: $IF_SKILL guard-block load at L${IF_GUARD_LINE} (must be ≤12, i.e. 6% of 200)"
fi

# --- D. No inline Task() dispatch directives in SKILL.md body ---
# Allowed: dispatch table introductory paragraph references in code-fence examples.
# Forbidden: imperative dispatch directives matching either trigger phrase.
FB_TASK=$(grep -cE 'You MUST invoke Task|Task\(subagent_type' "$FB_SKILL" || true)
IF_TASK=$(grep -cE 'You MUST invoke Task|Task\(subagent_type' "$IF_SKILL" || true)
[ -z "$FB_TASK" ] && FB_TASK=0
[ -z "$IF_TASK" ] && IF_TASK=0

if [ "$FB_TASK" -gt 0 ]; then
  fail "FC-1.D1: $FB_SKILL contains $FB_TASK inline Task() dispatch references (must be 0)"
fi
if [ "$IF_TASK" -gt 0 ]; then
  fail "FC-1.D2: $IF_SKILL contains $IF_TASK inline Task() dispatch references (must be 0)"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v10-thin-controller-line-count — fix-bugs=${FB_LINES}L, impl=${IF_LINES}L; phrases + guard-position + zero-Task all OK"
  exit 0
fi
exit 1
