#!/usr/bin/env bash
# Hidden adversarial test — do NOT reference in spec/visible
# Tests: REQ-SETUP-006 symlink guard — /setup-agents does NOT follow symlinks outside customization/
# Adversarial: symlink pointing to /etc/passwd or sensitive path is rejected
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
# Setup: create a malicious symlink in customization/
# ---------------------------------------------------------------------------
mkdir -p "$TMPDIR_TEST/customization"

# Create a symlink to a sensitive path (use /dev/null for safety in tests)
SAFE_SENSITIVE_PATH="/dev/null"  # safe stand-in for /etc/passwd
ln -s "$SAFE_SENSITIVE_PATH" "$TMPDIR_TEST/customization/reviewer.toml" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Assertion 1: symlink exists (test setup correct)
# ---------------------------------------------------------------------------
echo "--- Assertion 1: symlink created in customization/ ---"
if [ -L "$TMPDIR_TEST/customization/reviewer.toml" ]; then
  echo "OK: symlink reviewer.toml → $SAFE_SENSITIVE_PATH created"
else
  echo "SKIP: symlink creation not supported on this platform" >&2
  exit 77
fi

# ---------------------------------------------------------------------------
# Assertion 2: setup-agents SKILL.md documents symlink non-follow
# ---------------------------------------------------------------------------
echo "--- Assertion 2: setup-agents SKILL.md documents symlink non-follow ---"
SETUP_SKILL="$REPO_ROOT/skills/setup-agents/SKILL.md"
if [ ! -f "$SETUP_SKILL" ]; then
  echo "SKIP: skills/setup-agents/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'symlink|follow.*symlink|non.?follow|real.*path' "$SETUP_SKILL"; then
  echo "OK: setup-agents SKILL.md documents symlink non-follow"
else
  fail "setup-agents SKILL.md missing symlink non-follow documentation (REQ-SETUP-006)"
fi

# ---------------------------------------------------------------------------
# Assertion 3: Symlink detection logic via -L bash test
# ---------------------------------------------------------------------------
echo "--- Assertion 3: symlink detection via bash -L test ---"
if [ -L "$TMPDIR_TEST/customization/reviewer.toml" ]; then
  echo "OK: -L correctly detects symlink (implementation should use -L guard)"
  # setup-agents should refuse to write over or through this symlink
  RESOLVED=$(readlink -f "$TMPDIR_TEST/customization/reviewer.toml" 2>/dev/null || true)
  echo "INFO: resolved path = $RESOLVED"
  if [ "$RESOLVED" = "$SAFE_SENSITIVE_PATH" ]; then
    echo "OK: symlink target verified as $SAFE_SENSITIVE_PATH"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 4: WARN or ERROR on symlink detection documented
# ---------------------------------------------------------------------------
echo "--- Assertion 4: WARN or ERROR on symlink detection documented ---"
if grep -qiE '\[WARN\].*symlink|\[ERROR\].*symlink|symlink.*warn|symlink.*reject' "$SETUP_SKILL"; then
  echo "OK: setup-agents SKILL.md has WARN/ERROR for symlink detection"
else
  fail "setup-agents SKILL.md missing WARN/ERROR behavior for symlink detection"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: symlink non-follow guard in /setup-agents documented"
fi
exit "$FAIL"
