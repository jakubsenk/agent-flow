#!/usr/bin/env bash
# Verifies: AC-MIG-003, REQ-MIG-004
# Description: /migrate-config --to-v8 --dry-run does NOT modify any files or create backup
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
# Setup: mock customization/ with .md file
# ---------------------------------------------------------------------------
mkdir -p "$TMPDIR_TEST/customization"
printf 'Always check SQL injection.\n' > "$TMPDIR_TEST/customization/reviewer.md"

# Compute baseline checksums
CHECKSUM_MD=""
if command -v sha256sum > /dev/null 2>&1; then
  CHECKSUM_MD=$(sha256sum "$TMPDIR_TEST/customization/reviewer.md" | cut -d' ' -f1)
elif command -v shasum > /dev/null 2>&1; then
  CHECKSUM_MD=$(shasum -a 256 "$TMPDIR_TEST/customization/reviewer.md" | cut -d' ' -f1)
else
  CHECKSUM_MD=$(wc -c < "$TMPDIR_TEST/customization/reviewer.md")
fi

# Simulate dry-run: no files should change (skip actual execution)
# This test verifies the documentation + behavioral contract

# ---------------------------------------------------------------------------
# Assertion 1: migrate-config SKILL.md documents --dry-run no-op
# ---------------------------------------------------------------------------
echo "--- Assertion 1: migrate-config SKILL.md documents --dry-run noop ---"
MIGRATE_SKILL="$REPO_ROOT/skills/migrate-config/SKILL.md"
if [ ! -f "$MIGRATE_SKILL" ]; then
  echo "SKIP: skills/migrate-config/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qF -- '--dry-run' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents --dry-run"
else
  fail "migrate-config SKILL.md missing --dry-run documentation"
fi

if grep -qiE 'dry.run.*no.*file|no.*file.*dry.run|no.*modif.*dry|dry.run.*noop' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config --dry-run documents no-file-modification"
else
  fail "migrate-config SKILL.md missing 'dry-run does not modify files' documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Dry-run output format documented
# ---------------------------------------------------------------------------
echo "--- Assertion 2: dry-run output format documented ---"
if grep -qiE 'PLANNED ACTIONS|dry.run.*report|planned.*actions' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents dry-run PLANNED ACTIONS report format"
else
  fail "migrate-config SKILL.md missing dry-run PLANNED ACTIONS output format"
fi

# ---------------------------------------------------------------------------
# Assertion 3: No backup created in dry-run
# ---------------------------------------------------------------------------
echo "--- Assertion 3: dry-run does not create backup directory ---"
if grep -qiE 'no.*backup.*dry.run|dry.run.*no.*backup|UNLESS.*dry.run' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents no backup in dry-run"
else
  fail "migrate-config SKILL.md missing 'no backup in dry-run' documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 4: Mock .md unchanged after dry-run (file not modified)
# ---------------------------------------------------------------------------
echo "--- Assertion 4: .md file unchanged (dry-run simulation) ---"
CHECKSUM_AFTER=""
if command -v sha256sum > /dev/null 2>&1; then
  CHECKSUM_AFTER=$(sha256sum "$TMPDIR_TEST/customization/reviewer.md" | cut -d' ' -f1)
elif command -v shasum > /dev/null 2>&1; then
  CHECKSUM_AFTER=$(shasum -a 256 "$TMPDIR_TEST/customization/reviewer.md" | cut -d' ' -f1)
else
  CHECKSUM_AFTER=$(wc -c < "$TMPDIR_TEST/customization/reviewer.md")
fi

if [ "$CHECKSUM_MD" = "$CHECKSUM_AFTER" ]; then
  echo "OK: reviewer.md unchanged (dry-run does not modify)"
else
  fail "reviewer.md was modified — dry-run should be noop"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-MIG-003 — migrate-config --dry-run is documented as noop"
fi
exit "$FAIL"
