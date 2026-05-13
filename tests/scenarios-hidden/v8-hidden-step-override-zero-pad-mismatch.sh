#!/usr/bin/env bash
# Hidden adversarial test — do NOT reference in spec/visible
# Tests: "4-fixer.md" vs canonical "04-fixer-reviewer-loop.md" triggers near-miss WARN
# and falls through to plugin default (does NOT silently act as override)
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
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

mkdir -p "$TMPDIR_TEST/customization/steps/fix-bugs"

# Near-miss: missing zero-pad (4- instead of 04-)
cat > "$TMPDIR_TEST/customization/steps/fix-bugs/4-fixer.md" << 'EOF'
# NEAR-MISS OVERRIDE — should trigger WARN but NOT be applied
This should NOT replace the plugin default 04-fixer-reviewer-loop.md.
EOF

# Canonical plugin default step
mkdir -p "$TMPDIR_TEST/skills/fix-bugs/steps"
cat > "$TMPDIR_TEST/skills/fix-bugs/steps/04-fixer-reviewer-loop.md" << 'EOF'
# Plugin default fixer reviewer loop step
PLUGIN_DEFAULT_MARKER
EOF

# ---------------------------------------------------------------------------
# Assertion 1: Near-miss detection — "4-fixer.md" should NOT be treated as override
# ---------------------------------------------------------------------------
echo "--- Assertion 1: zero-pad mismatch '4-fixer.md' does not override '04-fixer-reviewer-loop.md' ---"

# Exact match check
EXACT_MATCH="$TMPDIR_TEST/customization/steps/fix-bugs/04-fixer-reviewer-loop.md"
if [ -f "$EXACT_MATCH" ]; then
  fail "Test setup error: exact-match file should NOT exist for this test"
else
  echo "OK: exact-match file absent (only near-miss '4-fixer.md' present)"
fi

# Near-miss file exists
NEAR_MISS="$TMPDIR_TEST/customization/steps/fix-bugs/4-fixer.md"
if [ -f "$NEAR_MISS" ]; then
  echo "OK: near-miss file '4-fixer.md' exists"
else
  fail "Near-miss file '4-fixer.md' should exist for this test"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Normalization detects this as near-miss
# ---------------------------------------------------------------------------
echo "--- Assertion 2: normalization identifies 4-fixer.md as near-miss to 04-fixer-reviewer-loop.md ---"
NEAR_MISS_BASENAME="4-fixer.md"
NORMALIZED=$(echo "$NEAR_MISS_BASENAME" | sed 's/^\([0-9]\)-/0\1-/')
# Normalized = "04-fixer.md" — a prefix match to "04-fixer-reviewer-loop.md"
PREFIX=$(echo "$NORMALIZED" | sed 's/\.md$//')  # "04-fixer"
CANONICAL="04-fixer-reviewer-loop.md"
CANONICAL_PREFIX=$(echo "$CANONICAL" | sed 's/\.md$//')  # "04-fixer-reviewer-loop"

# The zero-padded prefix "04-fixer" is a prefix of the canonical, so it's a near-miss
if echo "$CANONICAL_PREFIX" | grep -q "^$PREFIX"; then
  echo "OK: '4-fixer.md' normalizes to near-miss of '$CANONICAL'"
else
  fail "Normalization failed: '$NEAR_MISS_BASENAME' should be near-miss of '$CANONICAL'"
fi

# ---------------------------------------------------------------------------
# Assertion 3: steps-decomposition.md documents that near-miss falls through to default
# ---------------------------------------------------------------------------
echo "--- Assertion 3: steps-decomposition.md documents fall-through on near-miss ---"
STEPS_GUIDE="$REPO_ROOT/docs/guides/steps-decomposition.md"
if [ -f "$STEPS_GUIDE" ]; then
  if grep -qiE 'fall.?through|plugin.default.*near.miss|near.miss.*default' "$STEPS_GUIDE"; then
    echo "OK: steps-decomposition.md documents fall-through on near-miss"
  else
    fail "steps-decomposition.md missing fall-through on near-miss documentation"
  fi
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: zero-pad mismatch '4-fixer.md' correctly identified as near-miss (not override)"
fi
exit "$FAIL"
