#!/usr/bin/env bash
# Scenario: REQ-064, REQ-064a — CLAUDE.md + README.md count drift: 15->16 core contracts; 18->19 optional sections
# v6.10.0 EXTEND (REQ-T1-10, AC-T1-10-1, AC-T1-10-2, AC-META-5-1):
# Added enumeration-based cross-checks against filesystem source of truth.
# Expected outcome: PASS when CLAUDE.md counts match filesystem counts.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
PROMPT_INJ="$REPO_ROOT/tests/scenarios/prompt-injection-protection.sh"

if [ ! -f "$CLAUDE_MD" ]; then
  echo "FAIL: CLAUDE.md not found" >&2; exit 1
fi

# --- Pre-existing assertions (preserved per REQ-T1-3) ---

echo "--- Assertion 1 (AC-064): CLAUDE.md says '16 shared pipeline pattern contracts' ---"
if grep -qF '16 shared pipeline pattern contracts' "$CLAUDE_MD"; then
  echo "OK (AC-064): CLAUDE.md updated to 16 core contracts"
else
  fail "AC-064: CLAUDE.md missing '16 shared pipeline pattern contracts'"
fi
if grep -qF '15 shared pipeline pattern contracts' "$CLAUDE_MD"; then
  fail "AC-064 NEGATIVE: CLAUDE.md still contains stale '15 shared pipeline pattern contracts'"
fi

echo "--- Assertion 2 (AC-064): prompt-injection-protection.sh updated ---"
if [ -f "$PROMPT_INJ" ]; then
  if grep -qE '16.*core|core.*16|-ne 16|expected 16' "$PROMPT_INJ" 2>/dev/null; then
    echo "OK (AC-064): prompt-injection-protection.sh references 16 as expected core count"
  else
    fail "AC-064: prompt-injection-protection.sh does not reference 16 as expected core count"
  fi
fi

echo "--- Assertion 3 (AC-064a): CLAUDE.md says '19 optional config sections in total' ---"
if grep -qF '19 optional config sections in total' "$CLAUDE_MD"; then
  echo "OK (AC-064a): CLAUDE.md says 19 optional config sections"
else
  fail "AC-064a: CLAUDE.md missing '19 optional config sections in total'"
fi

echo "--- Assertion 4 (AC-064a): Pause Limits row in CLAUDE.md ---"
if grep -qF '| Pause Limits |' "$CLAUDE_MD"; then
  echo "OK (AC-064a): Pause Limits row present"
else
  fail "AC-064a: CLAUDE.md missing Pause Limits row"
fi

echo "--- Assertion 5 (AC-064a NEGATIVE): no stale 18 optional ---"
if grep -qF '18 optional config sections in total' "$CLAUDE_MD"; then
  fail "AC-064a: CLAUDE.md still has stale '18 optional config sections in total'"
fi

# --- v6.10.0 EXTEND: enumeration cross-checks (AC-T1-10-1, AC-T1-10-2, AC-META-5-1) ---

echo "--- v6.10.0 EXTEND: enumerate core/*.md files ---"
core_count=$(find "$REPO_ROOT/core" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')
[ "$core_count" -eq 16 ] || fail "core/*.md count = $core_count, expected 16 (CLAUDE.md says 16)"

echo "--- v6.10.0 EXTEND: enumerate agents/*.md files ---"
agents_count=$(find "$REPO_ROOT/agents" -maxdepth 1 -name '*.md' -type f -not -name 'README.md' | wc -l | tr -d ' ')
[ "$agents_count" -eq 21 ] || fail "agents/*.md count = $agents_count, expected 21 (CLAUDE.md says 21)"

echo "--- v6.10.0 EXTEND: enumerate skills/*/SKILL.md files ---"
skills_count=$(find "$REPO_ROOT/skills" -maxdepth 1 -type d | tail -n +2 | wc -l | tr -d ' ')
[ "$skills_count" -eq 29 ] || fail "skills/ directory count = $skills_count, expected 29 (CLAUDE.md says 29)"

echo "--- v6.10.0 EXTEND: count optional-section table rows in CLAUDE.md ---"
optional_count=$(awk '/^### Optional sections/,/^---/' "$CLAUDE_MD" 2>/dev/null \
  | grep -cE '^\| [A-Z]' || echo 0)
if [ "$optional_count" -gt 0 ]; then
  [ "$optional_count" -eq 19 ] || fail "Optional sections table row count = $optional_count, expected 19"
  echo "OK: optional sections table row count = $optional_count"
else
  # Fallback: count via CLAUDE.md prose
  echo "INFO: optional sections table not found via awk — using prose count check"
  if ! grep -qF '19 optional config sections in total' "$CLAUDE_MD"; then
    fail "CLAUDE.md does not state '19 optional config sections in total'"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v6.9.0/v6.10.0 doc count drift checks passed (16 core, 21 agents, 29 skills, 19 optional)"
exit "$FAIL"
