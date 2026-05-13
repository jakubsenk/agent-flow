#!/usr/bin/env bash
# Verifies: AC-OVR-007, REQ-OVR-006
# Description: Legacy-only .md overlay (no .toml) parsed as raw append-text per v7 semantics,
#   [WARN] contains "migrate via /migrate-config --to-v8"
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

EXPECTED_WARN_FRAGMENT="migrate via /migrate-config --to-v8"

# ---------------------------------------------------------------------------
# Setup: only .md overlay present (legacy v7 format)
# ---------------------------------------------------------------------------
mkdir -p "$TMPDIR_TEST/customization"

cat > "$TMPDIR_TEST/customization/reviewer.md" << 'EOF'
Always check for SQL injection in all database queries.
Always require unit tests for bug fixes.
EOF

# ---------------------------------------------------------------------------
# Assertion 1: TOML syntax doc documents legacy .md fallback with [WARN]
# ---------------------------------------------------------------------------
echo "--- Assertion 1: toml-overlay-syntax.md documents legacy .md [WARN] ---"
TOML_DOC="$REPO_ROOT/docs/guides/toml-overlay-syntax.md"
if [ ! -f "$TOML_DOC" ]; then
  echo "SKIP: docs/guides/toml-overlay-syntax.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'legacy.*\.md|\.md.*legacy|v7.*fallback|fallback.*v7' "$TOML_DOC"; then
  echo "OK: toml-overlay-syntax.md documents legacy .md fallback"
else
  fail "toml-overlay-syntax.md missing legacy .md fallback documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Exact [WARN] fragment documented
# ---------------------------------------------------------------------------
echo "--- Assertion 2: exact [WARN] fragment '$EXPECTED_WARN_FRAGMENT' documented ---"
if grep -qF "$EXPECTED_WARN_FRAGMENT" "$TOML_DOC" || \
   grep -qF "$EXPECTED_WARN_FRAGMENT" "$REPO_ROOT/docs/guides/migration-v7-to-v8.md" 2>/dev/null || \
   grep -qF "$EXPECTED_WARN_FRAGMENT" "$REPO_ROOT/skills/setup-agents/SKILL.md" 2>/dev/null; then
  echo "OK: '$EXPECTED_WARN_FRAGMENT' found in documentation/skill"
else
  fail "WARN fragment '$EXPECTED_WARN_FRAGMENT' not found in any documentation file"
fi

# ---------------------------------------------------------------------------
# Assertion 3: v7 backward compat — .md still works without running migrate-config
# ---------------------------------------------------------------------------
echo "--- Assertion 3: migration guide documents .md backward compat in v8 ---"
MIG_GUIDE="$REPO_ROOT/docs/guides/migration-v7-to-v8.md"
if [ ! -f "$MIG_GUIDE" ]; then
  echo "SKIP: migration guide not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'backward.*compat|\.md.*still.*works|v7.*project.*work|without.*migrate' "$MIG_GUIDE"; then
  echo "OK: migration guide documents .md backward compat"
else
  fail "migration guide does not document .md backward compat in v8"
fi

# ---------------------------------------------------------------------------
# Assertion 4: setup-agents/SKILL.md handles legacy-only .md overlay
# ---------------------------------------------------------------------------
echo "--- Assertion 4: setup-agents SKILL.md handles .md-only overlay ---"
SETUP_SKILL="$REPO_ROOT/skills/setup-agents/SKILL.md"
if [ ! -f "$SETUP_SKILL" ]; then
  echo "SKIP: skills/setup-agents/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'legacy.*\.md|\.md.*legacy|v7.*overlay' "$SETUP_SKILL"; then
  echo "OK: setup-agents handles .md-only legacy overlay"
else
  fail "setup-agents SKILL.md does not handle legacy .md-only overlay"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-OVR-007 — legacy .md overlay accepted with deprecation WARN documented"
fi
exit "$FAIL"
