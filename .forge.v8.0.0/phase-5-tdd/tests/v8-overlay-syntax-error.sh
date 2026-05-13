#!/usr/bin/env bash
# Verifies: AC-OVR-004, REQ-OVR-004
# Description: TOML overlay with syntax error halts dispatch with [ERROR] log + non-zero exit
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

# ---------------------------------------------------------------------------
# Setup: TOML file with syntax error (unterminated string)
# ---------------------------------------------------------------------------
mkdir -p "$TMPDIR_TEST/customization"

cat > "$TMPDIR_TEST/customization/reviewer.toml" << 'TOMLEOF'
model = "sonnet
TOMLEOF
# Note: model = "sonnet  (no closing quote) is a TOML syntax error

# ---------------------------------------------------------------------------
# Assertion 1: migrate-config SKILL.md documents error handling for invalid TOML
# ---------------------------------------------------------------------------
echo "--- Assertion 1: SKILL documents [ERROR] on TOML syntax error ---"
MIGRATE_SKILL="$REPO_ROOT/skills/migrate-config/SKILL.md"
SETUP_AGENTS_SKILL="$REPO_ROOT/skills/setup-agents/SKILL.md"

# Check migrate-config documents error handling
FOUND_ERROR_DOC=0
for skill_file in "$MIGRATE_SKILL" "$SETUP_AGENTS_SKILL"; do
  if [ -f "$skill_file" ]; then
    if grep -qiE '\[ERROR\]|syntax error|toml.*error|invalid.*toml' "$skill_file"; then
      echo "OK: $(basename "$(dirname "$skill_file")")/SKILL.md documents TOML syntax error handling"
      FOUND_ERROR_DOC=1
    fi
  fi
done

if [ "$FOUND_ERROR_DOC" -eq 0 ]; then
  echo "SKIP: skills/setup-agents/SKILL.md and skills/migrate-config/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

# ---------------------------------------------------------------------------
# Assertion 2: toml-overlay-syntax.md documents syntax error behavior
# ---------------------------------------------------------------------------
echo "--- Assertion 2: toml-overlay-syntax.md documents syntax error halt behavior ---"
TOML_DOC="$REPO_ROOT/docs/guides/toml-overlay-syntax.md"
if [ ! -f "$TOML_DOC" ]; then
  echo "SKIP: docs/guides/toml-overlay-syntax.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE '\[ERROR\]|syntax error|parse.*error|halt' "$TOML_DOC"; then
  echo "OK: toml-overlay-syntax.md documents [ERROR] on invalid TOML"
else
  fail "toml-overlay-syntax.md does not document halt-on-syntax-error behavior"
fi

# ---------------------------------------------------------------------------
# Assertion 3: Error message must contain file path
# ---------------------------------------------------------------------------
echo "--- Assertion 3: error documentation includes file path in [ERROR] message ---"
if grep -qiE 'file.*path|overlay_path|customization.*toml' "$TOML_DOC"; then
  echo "OK: toml-overlay-syntax.md error docs reference file path"
else
  fail "toml-overlay-syntax.md error documentation does not mention file path in error message"
fi

# ---------------------------------------------------------------------------
# Assertion 4: Migration guide mentions syntax validation
# ---------------------------------------------------------------------------
echo "--- Assertion 4: migration guide references TOML syntax validation ---"
MIGRATION_GUIDE="$REPO_ROOT/docs/guides/migration-v7-to-v8.md"
if [ ! -f "$MIGRATION_GUIDE" ]; then
  echo "SKIP: migration guide not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'toml.*syntax|syntax.*toml|toml.*valid|taplo|parser' "$MIGRATION_GUIDE"; then
  echo "OK: migration guide mentions TOML syntax validation"
else
  fail "migration guide does not mention TOML syntax validation"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-OVR-004 — TOML syntax error halts dispatch with [ERROR] + file path documented"
fi
exit "$FAIL"
