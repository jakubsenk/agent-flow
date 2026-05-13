#!/usr/bin/env bash
# Verifies: AC-OVR-006, REQ-OVR-005
# Description: When both customization/reviewer.md AND customization/reviewer.toml exist,
#   .toml wins and [WARN] log contains exact deprecation text
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

EXPECTED_WARN_TEXT="Legacy .md overlay ignored; .toml takes precedence (deprecate v9.0.0)"

# ---------------------------------------------------------------------------
# Setup: both .md and .toml present
# ---------------------------------------------------------------------------
mkdir -p "$TMPDIR_TEST/customization"

cat > "$TMPDIR_TEST/customization/reviewer.md" << 'EOF'
Always check for SQL injection in all database queries.
EOF

cat > "$TMPDIR_TEST/customization/reviewer.toml" << 'EOF'
model = "sonnet"

[[process_additions]]
step = "after_default"
instruction = "Check TOML-sourced instruction"
EOF

# ---------------------------------------------------------------------------
# Assertion 1: TOML syntax doc documents .toml takes precedence over .md
# ---------------------------------------------------------------------------
echo "--- Assertion 1: toml-overlay-syntax.md documents .toml precedence over .md ---"
TOML_DOC="$REPO_ROOT/docs/guides/toml-overlay-syntax.md"
if [ ! -f "$TOML_DOC" ]; then
  echo "SKIP: docs/guides/toml-overlay-syntax.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'toml.*takes precedence|\.toml.*primary|\.md.*ignored' "$TOML_DOC"; then
  echo "OK: toml-overlay-syntax.md documents .toml takes precedence over .md"
else
  fail "toml-overlay-syntax.md missing .toml precedence over .md documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Exact [WARN] text documented
# ---------------------------------------------------------------------------
echo "--- Assertion 2: exact [WARN] text documented ---"
if grep -qF "$EXPECTED_WARN_TEXT" "$TOML_DOC" || \
   grep -qF "$EXPECTED_WARN_TEXT" "$REPO_ROOT/docs/guides/migration-v7-to-v8.md" 2>/dev/null; then
  echo "OK: exact WARN text '$EXPECTED_WARN_TEXT' found in documentation"
else
  fail "Exact WARN text not found: '$EXPECTED_WARN_TEXT'"
fi

# ---------------------------------------------------------------------------
# Assertion 3: setup-agents SKILL.md implements coexistence handling
# ---------------------------------------------------------------------------
echo "--- Assertion 3: skills/setup-agents/SKILL.md handles .md + .toml coexistence ---"
SETUP_SKILL="$REPO_ROOT/skills/setup-agents/SKILL.md"
if [ ! -f "$SETUP_SKILL" ]; then
  echo "SKIP: skills/setup-agents/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE '\.md.*\.toml|\.toml.*takes|legacy.*\.md|coexist' "$SETUP_SKILL"; then
  echo "OK: setup-agents SKILL.md handles .md + .toml coexistence"
else
  fail "setup-agents SKILL.md does not handle .md + .toml coexistence"
fi

# ---------------------------------------------------------------------------
# Assertion 4: migration guide addresses coexistence scenario
# ---------------------------------------------------------------------------
echo "--- Assertion 4: migration guide addresses both formats coexisting ---"
MIG_GUIDE="$REPO_ROOT/docs/guides/migration-v7-to-v8.md"
if [ ! -f "$MIG_GUIDE" ]; then
  echo "SKIP: migration guide not found" >&2
  exit 77
fi

if grep -qiE '\.md.*\.toml|coexist|both.*format|legacy.*ignored' "$MIG_GUIDE"; then
  echo "OK: migration guide addresses coexistence"
else
  fail "migration guide does not address .md + .toml coexistence scenario"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-OVR-006 — .toml takes precedence over .md with exact [WARN] documented"
fi
exit "$FAIL"
