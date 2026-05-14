#!/usr/bin/env bash
# ===========================================================================
# Test:        v10-counts-invariants.sh
# FC mapped:   FC-7 (5 count invariants)
# What it checks:
#   1) skills/ direct-child dirs == 17
#   2) core/ top-level *.md (maxdepth 1) == 17
#   3) agents/*.md == 17
#   4) docs/reference/*.md == 11
#   5) Automation Config H3 sub-section count == 18.
#      Spec says "sections under `## Automation Config` in CLAUDE.md
#      AND docs/reference/automation-config.md (must MATCH)". This release adds
#      `## Automation Config` headings to BOTH; the assertion accepts either file
#      so long as one of them yields exactly 18 H3 sub-sections AND the other
#      yields the same count.
# Expected RED phase status:
#   - assertions 1-4 already pass on current repo (counts already at 17/17/17/11).
#     These act as regression gates against future bloat.
#   - assertion 5 will FAIL on current repo because CLAUDE.md uses the heading
#     '## Config Contract (for consuming projects)' not '## Automation Config',
#     so the H3-section-under-Automation-Config sub-count yields 0 ≠ 18 today.
#     This makes the test currently RED on assertion #5, with assertions #1-4
#     gating against regression.
# Expected GREEN phase (post-impl): PASS for all 5.
# ===========================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT" || { echo "FAIL: cannot cd to REPO_ROOT=$REPO_ROOT" >&2; exit 1; }

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# 1) Skills count == 17
n=$(find skills -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
if [ "$n" -ne 17 ]; then
  fail "FC-7.1: skills/ direct-child dir count = ${n} (expected 17)"
fi

# 2) core top-level *.md count == 17
n=$(find core -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
if [ "$n" -ne 17 ]; then
  fail "FC-7.2: core/*.md (maxdepth 1) count = ${n} (expected 17)"
fi

# 3) agents/*.md count == 17
n=$(find agents -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
if [ "$n" -ne 17 ]; then
  fail "FC-7.3: agents/*.md count = ${n} (expected 17)"
fi

# 4) docs/reference/*.md count == 11
n=$(find docs/reference -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
if [ "$n" -ne 11 ]; then
  fail "FC-7.4: docs/reference/*.md count = ${n} (expected 11)"
fi

# 5) Automation Config H3 sections == 18.
# Read from CLAUDE.md AND docs/reference/automation-config.md; assertion is
# satisfied iff BOTH files have a '## Automation Config' section AND their H3
# sub-section count is exactly 18 in each (per spec "must MATCH" clause).
sec_claude=$(awk '/^## Automation Config[[:space:]]*$/{f=1;next} /^## /&&f{exit} f' CLAUDE.md 2>/dev/null | grep -c '^### ' || true)
[ -z "$sec_claude" ] && sec_claude=0
sec_docref=$(awk '/^## Automation Config[[:space:]]*$/{f=1;next} /^## /&&f{exit} f' docs/reference/automation-config.md 2>/dev/null | grep -c '^### ' || true)
[ -z "$sec_docref" ] && sec_docref=0

if [ "$sec_claude" -ne 18 ]; then
  fail "FC-7.5a: CLAUDE.md '## Automation Config' section H3 sub-count = ${sec_claude} (expected 18)"
fi
if [ "$sec_docref" -ne 18 ]; then
  fail "FC-7.5b: docs/reference/automation-config.md '## Automation Config' section H3 sub-count = ${sec_docref} (expected 18)"
fi
if [ "$sec_claude" -ne "$sec_docref" ]; then
  fail "FC-7.5c: Automation Config H3 sub-count mismatch: CLAUDE.md=${sec_claude}, docs/reference=${sec_docref} (must MATCH)"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v10-counts-invariants — 17 skills / 17 core / 17 agents / 11 docs-ref / 18 config-sections (matched)"
  exit 0
fi
exit 1
