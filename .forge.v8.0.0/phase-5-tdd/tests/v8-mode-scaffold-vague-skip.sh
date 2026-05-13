#!/usr/bin/env bash
# Verifies: AC-MODE-009, REQ-MODE-009, REQ-MODE-009a
# Description: Long technical description (>=20 words + tech terms) → brainstorm SKIPPED
#   Short/vague description → brainstorm TRIGGERED
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

# ---------------------------------------------------------------------------
# Assertion 1: scaffold SKILL.md documents vague heuristic for brainstorm
# ---------------------------------------------------------------------------
echo "--- Assertion 1: scaffold SKILL.md documents vague heuristic ---"
SCAFFOLD_SKILL="$REPO_ROOT/skills/scaffold/SKILL.md"
if [ ! -f "$SCAFFOLD_SKILL" ]; then
  echo "SKIP: skills/scaffold/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'vague|heuristic|brainstorm.*trigger|trigger.*brainstorm' "$SCAFFOLD_SKILL"; then
  echo "OK: scaffold SKILL.md documents vague description detection"
else
  fail "scaffold SKILL.md missing vague description / brainstorm trigger documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 2: 01-mode-resolve.md step handles vague detection
# ---------------------------------------------------------------------------
echo "--- Assertion 2: scaffold step 01-mode-resolve.md handles vague detection ---"
MODE_RESOLVE="$REPO_ROOT/skills/scaffold/steps/01-mode-resolve.md"
if [ ! -f "$MODE_RESOLVE" ]; then
  echo "SKIP: skills/scaffold/steps/01-mode-resolve.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'vague|brainstorm|word.*count|heuristic' "$MODE_RESOLVE"; then
  echo "OK: 01-mode-resolve.md handles vague detection"
else
  fail "01-mode-resolve.md missing vague detection logic"
fi

# ---------------------------------------------------------------------------
# Assertion 3: "long technical description" boundary correctly defined
# ---------------------------------------------------------------------------
echo "--- Assertion 3: word-count threshold documented (>=20 words) ---"
if grep -qiE '20.*words|words.*20|>= 20|at least 20' "$SCAFFOLD_SKILL" || \
   grep -qiE '20.*words|words.*20|>= 20|at least 20' "$MODE_RESOLVE" 2>/dev/null; then
  echo "OK: >=20 word threshold documented"
else
  fail ">=20 word threshold not documented in scaffold SKILL.md or 01-mode-resolve.md"
fi

# ---------------------------------------------------------------------------
# Assertion 4: No interactive 3-mode prompt (old v7 behavior removed)
# ---------------------------------------------------------------------------
echo "--- Assertion 4: no interactive (a/b/c) 3-mode prompt in scaffold ---"
for f in "$SCAFFOLD_SKILL" "$MODE_RESOLVE"; do
  [ -f "$f" ] || continue
  if grep -qF '(a) Interactive' "$f" || \
     grep -qF '(b) YOLO with checkpoint' "$f" || \
     grep -qF '(c) Full YOLO' "$f"; then
    fail "$(basename "$f") contains v7 3-mode prompt strings (should be removed)"
  else
    echo "OK: $(basename "$f") has no v7 3-mode strings"
  fi
done

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-MODE-009 — vague heuristic: technical description skips brainstorm"
fi
exit "$FAIL"
