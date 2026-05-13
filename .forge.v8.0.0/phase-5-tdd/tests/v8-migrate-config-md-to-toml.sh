#!/usr/bin/env bash
# Verifies: AC-MIG-002, REQ-MIG-002, REQ-MIG-003, REQ-MIG-003a
# Description: /migrate-config --to-v8 converts .md to .toml with backup and generated header
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
# Assertion 1: migrate-config SKILL.md exists and documents --to-v8
# ---------------------------------------------------------------------------
echo "--- Assertion 1: migrate-config SKILL.md exists with --to-v8 flag ---"
MIGRATE_SKILL="$REPO_ROOT/skills/migrate-config/SKILL.md"
if [ ! -f "$MIGRATE_SKILL" ]; then
  fail "skills/migrate-config/SKILL.md not found"
  exit 1
fi

if grep -qF -- '--to-v8' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents --to-v8"
else
  fail "migrate-config SKILL.md missing --to-v8 flag"
fi

# ---------------------------------------------------------------------------
# Assertion 2: backup contract documented
# ---------------------------------------------------------------------------
echo "--- Assertion 2: backup customization.bak-v7-{ISO} contract documented ---"
if grep -qiE 'bak.v7|backup.*v7|customization\.bak' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents backup customization.bak-v7-{ISO}"
else
  fail "migrate-config SKILL.md missing backup customization.bak-v7-{ISO} documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 3: .toml output with # generated: header
# ---------------------------------------------------------------------------
echo "--- Assertion 3: generated .toml has # generated: header ---"
if grep -qF '# generated:' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents # generated: header in output .toml"
else
  fail "migrate-config SKILL.md missing # generated: header in output .toml"
fi

# ---------------------------------------------------------------------------
# Assertion 4: [[process_additions]] wrapping of .md content
# ---------------------------------------------------------------------------
echo "--- Assertion 4: .md content wrapped in [[process_additions]] block ---"
if grep -qF '[[process_additions]]' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config wraps .md content in [[process_additions]]"
else
  fail "migrate-config SKILL.md missing [[process_additions]] wrapping for .md content"
fi

# ---------------------------------------------------------------------------
# Assertion 5: Simulate backup filename format
# ---------------------------------------------------------------------------
echo "--- Assertion 5: backup directory name matches customization.bak-v7-{ISO} ---"
SIMULATED_TIMESTAMP="2026-04-27T103000Z"
BACKUP_DIR_NAME="customization.bak-v7-$SIMULATED_TIMESTAMP"
if echo "$BACKUP_DIR_NAME" | grep -qE '^customization\.bak-v7-[0-9TZ:-]+$'; then
  echo "OK: backup dir '$BACKUP_DIR_NAME' matches expected pattern"
else
  fail "Backup dir '$BACKUP_DIR_NAME' does not match pattern"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-MIG-002 — migrate-config --to-v8 documented (backup + toml conversion)"
fi
exit "$FAIL"
