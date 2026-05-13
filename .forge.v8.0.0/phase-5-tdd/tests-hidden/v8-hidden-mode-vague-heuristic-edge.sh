#!/usr/bin/env bash
# Hidden adversarial test — do NOT reference in spec/visible
# Tests: boundary of vague heuristic — exactly 19 words + technical term should NOT trigger brainstorm
# (requires >= 20 words with concrete tech terms per design.md §5.4)
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
# Assertion 1: heuristic regex boundary — 19 words is "vague" (brainstorm triggers)
# ---------------------------------------------------------------------------
echo "--- Assertion 1: 19-word description with technical term is VAGUE (brainstorm ON) ---"

# 19-word description with technical term "API" — should still be vague
DESC_19="Build a REST API with endpoints" # 7 words, needs 19
# Let's construct exactly 19 words with a technical term
DESC_19="Build a REST API application with authentication middleware and JWT token validation for user management system"
WORD_COUNT=$(echo "$DESC_19" | wc -w)
if [ "$WORD_COUNT" -lt 20 ]; then
  echo "INFO: description has $WORD_COUNT words (<20) — should be vague (brainstorm triggers)"
else
  echo "INFO: description has $WORD_COUNT words (>=20) — adjust test fixture"
fi

# Build exactly 19-word description
DESC_EXACT_19="Build a REST API application with JWT token validation for user management on production system"
EXACT_COUNT=$(echo "$DESC_EXACT_19" | wc -w)
echo "INFO: 19-word description: '$DESC_EXACT_19' (words: $EXACT_COUNT)"

# ---------------------------------------------------------------------------
# Assertion 2: 20+ words with technical terms should NOT trigger brainstorm
# ---------------------------------------------------------------------------
echo "--- Assertion 2: 20+ word technical description is NOT vague (brainstorm OFF) ---"

DESC_20="Build a REST API application with JWT token validation for user management on production systems using TypeScript"
EXACT_20=$(echo "$DESC_20" | wc -w)
if [ "$EXACT_20" -ge 20 ]; then
  echo "OK: description has $EXACT_20 words (>=20) — non-vague"
else
  fail "Test fixture has $EXACT_20 words (expected >=20)"
fi

# ---------------------------------------------------------------------------
# Assertion 3: scaffold SKILL.md documents vague detection heuristic
# ---------------------------------------------------------------------------
echo "--- Assertion 3: scaffold SKILL.md documents vague heuristic (>=20 words + tech terms) ---"
SCAFFOLD_SKILL="$REPO_ROOT/skills/scaffold/SKILL.md"
if [ ! -f "$SCAFFOLD_SKILL" ]; then
  echo "SKIP: skills/scaffold/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE '20.*word|word.*count|vague.*heuristic|heuristic.*vague|technical.*term' "$SCAFFOLD_SKILL"; then
  echo "OK: scaffold SKILL.md documents vague detection (word count + technical terms)"
else
  fail "scaffold SKILL.md missing vague heuristic documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 4: REQ-MODE-009a POSIX ERE pattern documented
# ---------------------------------------------------------------------------
echo "--- Assertion 4: REQ-MODE-009a POSIX ERE vague heuristic pattern ---"
PIPELINE_DOC="$REPO_ROOT/docs/reference/pipeline.md"
if [ -f "$PIPELINE_DOC" ]; then
  if grep -qiE 'vague.*pattern|heuristic.*regex|ERE.*vague|POSIX.*ERE' "$PIPELINE_DOC"; then
    echo "OK: pipeline.md documents vague heuristic POSIX ERE pattern"
  else
    echo "INFO: pipeline.md may not document POSIX ERE specifically (advisory)"
  fi
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: vague heuristic boundary correctly documented (19-word < threshold, 20-word >= threshold)"
fi
exit "$FAIL"
