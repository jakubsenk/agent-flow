#!/usr/bin/env bash
# v9.3.0 TDD — tests written before implementation
# T-01: Argument auto-detection / dispatch logic (AC-001 through AC-006)
#
# Tests the fix-bugs argument parsing (Step 0a) — tracker-type-aware disambiguation,
# --batch flag, ISSUE-ID format detection, and error cases.
#
# RED until Phase 7 implementation is complete — that is correct TDD behavior.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
[ -f "$REPO_ROOT/tests/lib/fixtures.sh" ] || REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

SCRATCH="$(setup_scratch)"
trap "rm -rf '$SCRATCH'" EXIT

SKILL="$REPO_ROOT/skills/fix-bugs/SKILL.md"

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Prerequisite: skill file must exist
# ---------------------------------------------------------------------------
if [ ! -f "$SKILL" ]; then
  echo "FAIL: skills/fix-bugs/SKILL.md does not exist — cannot run argument-dispatch tests" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# AC-001: PROJ-123 format (ISSUE-ID) → always single-ticket mode regardless of tracker type
# The skill must describe/declare single-ticket mode for PROJ-123 format.
# We verify the code pattern: the regex ^[A-Za-z][A-Za-z0-9_-]*-[0-9]+$ is present
# and routes to MODE=single.
# ---------------------------------------------------------------------------
echo "--- AC-001: PROJ-123 format routes to single-ticket mode ---"
if grep -qE 'MODE="single"' "$SKILL"; then
  echo "PASS: MODE=\"single\" assignment found in fix-bugs/SKILL.md"
else
  fail "AC-001 — skills/fix-bugs/SKILL.md does not contain MODE=\"single\" assignment"
fi

# The ISSUE-ID regex must be present
if grep -qE '\[A-Za-z\]\[A-Za-z0-9_-\].*-\[0-9\]' "$SKILL"; then
  echo "PASS: ISSUE-ID regex pattern [A-Za-z][A-Za-z0-9_-]*-[0-9]+ found"
else
  fail "AC-001 — ISSUE-ID regex '^[A-Za-z][A-Za-z0-9_-]*-[0-9]+\$' not found in fix-bugs/SKILL.md"
fi

# ---------------------------------------------------------------------------
# AC-002: Bare integer on YouTrack/Jira/Linear → batch mode + warning
# Verify warning text is present in skill body
# ---------------------------------------------------------------------------
echo "--- AC-002: Bare integer on YouTrack/Jira/linear → batch mode + WARN ---"
if grep -qF 'Treating' "$SKILL" && grep -qF 'batch count for' "$SKILL"; then
  echo "PASS: tracker-type batch disambiguation warning text found"
else
  fail "AC-002 — WARN text 'Treating ... as batch count for' not found in fix-bugs/SKILL.md"
fi

# Verify that youtrack|jira|linear branch routes to batch mode
if grep -qE 'youtrack\|jira\|linear' "$SKILL"; then
  echo "PASS: youtrack|jira|linear branch pattern found"
else
  fail "AC-002 — youtrack|jira|linear pattern not found in fix-bugs/SKILL.md"
fi

# ---------------------------------------------------------------------------
# AC-003: Bare integer on GitHub/Gitea/Redmine → single-ticket mode, no warning
# ---------------------------------------------------------------------------
echo "--- AC-003: Bare integer on github/gitea/redmine → single-ticket mode ---"
if grep -qE 'github\|gitea\|redmine' "$SKILL"; then
  echo "PASS: github|gitea|redmine branch pattern found"
else
  fail "AC-003 — github|gitea|redmine pattern not found in fix-bugs/SKILL.md"
fi

# ---------------------------------------------------------------------------
# AC-004: --batch flag always wins regardless of tracker type
# Verify --batch parsing and positive-integer validation
# ---------------------------------------------------------------------------
echo "--- AC-004: --batch flag always routes to batch mode ---"
if grep -qF 'GOT_BATCH=true' "$SKILL" || grep -qF 'GOT_BATCH' "$SKILL"; then
  echo "PASS: GOT_BATCH variable found in fix-bugs/SKILL.md"
else
  fail "AC-004 — GOT_BATCH variable not found in fix-bugs/SKILL.md"
fi

# AC-004b: --batch with non-positive integer → [ERROR]
if grep -qF 'batch requires a positive integer' "$SKILL"; then
  echo "PASS: --batch positive-integer error message found"
else
  fail "AC-004b — '[ERROR] --batch requires a positive integer count' not found in fix-bugs/SKILL.md"
fi

# The --batch validation regex must reject zero: ^[1-9][0-9]*$
if grep -qE '\^\[1-9\]\[0-9\]' "$SKILL"; then
  echo "PASS: --batch positive-integer regex ^[1-9][0-9]*$ found"
else
  fail "AC-004b — regex ^[1-9][0-9]*$ for --batch validation not found"
fi

# ---------------------------------------------------------------------------
# AC-005: No argument and no --batch → error with usage hint
# ---------------------------------------------------------------------------
echo "--- AC-005: No positional and no --batch → [ERROR] with usage hint ---"
if grep -qF 'Usage: /ceos-agents:fix-bugs' "$SKILL"; then
  echo "PASS: Usage hint '/ceos-agents:fix-bugs' found in error path"
else
  fail "AC-005 — '[ERROR] Usage: /ceos-agents:fix-bugs' not found in fix-bugs/SKILL.md"
fi

# ---------------------------------------------------------------------------
# AC-006: Missing tracker type → [WARN] and default to string-tracker semantics
# ---------------------------------------------------------------------------
echo "--- AC-006: Missing tracker type → [WARN] assuming string-tracker semantics ---"
if grep -qF 'Tracker type not detected' "$SKILL"; then
  echo "PASS: 'Tracker type not detected' warning text found"
else
  fail "AC-006 — '[WARN] Tracker type not detected; assuming string-tracker semantics' not found"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.3.0-fix-bugs-argument-dispatch — all argument dispatch checks passed"
fi
exit "$FAIL"
