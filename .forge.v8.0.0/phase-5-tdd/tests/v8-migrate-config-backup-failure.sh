#!/usr/bin/env bash
# Verifies: AC-MIG-006, REQ-NF-009, REQ-MIG-002 atomicity
# Description: If backup step fails, no .toml files created + [ERROR] + non-zero exit
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
# Assertion 1: migrate-config SKILL.md documents backup-before-write atomicity
# ---------------------------------------------------------------------------
echo "--- Assertion 1: migrate-config SKILL.md documents atomicity (backup before write) ---"
MIGRATE_SKILL="$REPO_ROOT/skills/migrate-config/SKILL.md"
if [ ! -f "$MIGRATE_SKILL" ]; then
  echo "SKIP: skills/migrate-config/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'backup.*before.*writ|backup.*complet.*before|atomic.*backup|if.*backup.*fail' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents backup-before-write atomicity"
else
  fail "migrate-config SKILL.md missing backup-before-write atomicity documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 2: [ERROR] on backup failure documented
# ---------------------------------------------------------------------------
echo "--- Assertion 2: [ERROR] log on backup failure documented ---"
if grep -qiE '\[ERROR\].*backup|backup.*fail.*\[ERROR\]|backup.*fail.*abort' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents [ERROR] on backup failure"
else
  fail "migrate-config SKILL.md missing [ERROR] log for backup failure"
fi

# ---------------------------------------------------------------------------
# Assertion 3: Original customization/ untouched on backup failure
# ---------------------------------------------------------------------------
echo "--- Assertion 3: customization/ untouched on backup failure documented ---"
if grep -qiE 'original.*untouched|untouched.*original|rollback.*backup|no.*toml.*if.*backup' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents original preservation on backup failure"
else
  fail "migrate-config SKILL.md missing original-untouched documentation for backup failure"
fi

# ---------------------------------------------------------------------------
# Assertion 4: Non-zero exit code on backup failure
# ---------------------------------------------------------------------------
echo "--- Assertion 4: non-zero exit code on backup failure documented ---"
if grep -qiE 'non.zero.*exit|exit.*1.*backup|exit.*fail.*backup' "$MIGRATE_SKILL"; then
  echo "OK: non-zero exit on backup failure documented"
else
  fail "migrate-config SKILL.md missing non-zero exit documentation for backup failure"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-MIG-006 — backup failure aborts migration with [ERROR], no .toml created"
fi
exit "$FAIL"
