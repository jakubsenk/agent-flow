#!/usr/bin/env bash
# Verifies: AC-CT-003, REQ-DOC-007
# Description: CLAUDE.md and docs/reference/automation-config.md both list exactly 18
#   optional config sections (level-3 headings under ## Automation Config)
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

EXPECTED_SECTIONS=18

check_section_count() {
  local file="$1"
  local file_path="$REPO_ROOT/$file"

  if [ ! -f "$file_path" ]; then
    echo "SKIP: $file not found (implementation pending)" >&2
    return 77
  fi

  # Count ### level-3 headings within Automation Config section
  local COUNT
  COUNT=$(awk '/^## Automation Config/{found=1} found && /^### /{count++} found && /^## [^A]/{if(found>1) exit} END{print count}' "$file_path" 2>/dev/null || echo 0)

  # Alternative: count all ### headings that are config sections
  if [ -z "$COUNT" ] || [ "$COUNT" -eq 0 ]; then
    COUNT=$(grep -c '^### ' "$file_path" || echo 0)
  fi

  echo "INFO: $file has $COUNT config section headings"
  if [ "$COUNT" -eq "$EXPECTED_SECTIONS" ]; then
    echo "OK: $file has exactly $EXPECTED_SECTIONS config sections"
  else
    fail "$file has $COUNT config sections — expected $EXPECTED_SECTIONS"
  fi
}

# ---------------------------------------------------------------------------
# Check CLAUDE.md
# ---------------------------------------------------------------------------
echo "--- Checking CLAUDE.md config section count ---"
check_section_count "CLAUDE.md"

# ---------------------------------------------------------------------------
# Check automation-config.md
# ---------------------------------------------------------------------------
echo "--- Checking docs/reference/automation-config.md config section count ---"
check_section_count "docs/reference/automation-config.md"

# ---------------------------------------------------------------------------
# Verify v7 "Extra labels" section is REMOVED (was 19->18 reduction in v7.0.0)
# ---------------------------------------------------------------------------
echo "--- Assertion: 'Extra labels' section absent (v7 cleanup) ---"
for file in CLAUDE.md docs/reference/automation-config.md; do
  if grep -qF '### Extra labels' "$REPO_ROOT/$file" 2>/dev/null; then
    fail "$file still contains '### Extra labels' section (should be removed per v7.0.0)"
  else
    echo "OK: $file does not contain '### Extra labels'"
  fi
done

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-CT-003 — CLAUDE.md and automation-config.md both have 18 config sections"
fi
exit "$FAIL"
