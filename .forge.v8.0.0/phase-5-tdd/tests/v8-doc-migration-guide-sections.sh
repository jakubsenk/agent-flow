#!/usr/bin/env bash
# Verifies: AC-DOC-001, REQ-DOC-001
# Description: docs/guides/migration-v7-to-v8.md exists with all required section headings
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

MIG_GUIDE="$REPO_ROOT/docs/guides/migration-v7-to-v8.md"

if [ ! -f "$MIG_GUIDE" ]; then
  fail "docs/guides/migration-v7-to-v8.md not found"
  exit 1
fi

# Required section headings (case-insensitive ## match per AC-DOC-001)
REQUIRED_SECTIONS=(
  "TOML overlay conversion"
  "Agent rename mapping"
  "SKILL decomposition"
  "Plugin permission constraint"
  "Scaffold mode harmonization"
  "Skip stages syntax migration"
  "Deprecation timeline"
  "/migrate-config --to-v8"
)

echo "--- Checking required section headings in migration guide ---"
for section in "${REQUIRED_SECTIONS[@]}"; do
  if grep -qiE "^## .*$section" "$MIG_GUIDE"; then
    echo "OK: section '$section' found"
  else
    fail "migration guide missing section: '$section'"
  fi
done

# ---------------------------------------------------------------------------
# Assertion: file has Migration: paragraphs (per AC-DOC-013)
# ---------------------------------------------------------------------------
echo "--- Assertion: migration guide has 'Migration:' paragraphs ---"
if grep -qF 'Migration:' "$MIG_GUIDE"; then
  echo "OK: migration guide contains Migration: paragraphs"
else
  fail "migration guide missing 'Migration:' paragraphs"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-DOC-001 — migration guide has all 8 required sections"
fi
exit "$FAIL"
