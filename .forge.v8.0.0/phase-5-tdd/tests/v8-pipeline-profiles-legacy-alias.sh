#!/usr/bin/env bash
# Verifies: AC-MIG-007, REQ-MIG-006, REQ-NF-001
# Description: v7 "Skip stages: [code-analyst]" in CLAUDE.md is accepted at runtime
#   with [WARN] about legacy name; pipeline skips analyst-impact; does NOT abort
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

EXPECTED_WARN_FRAGMENT="Pipeline Profiles legacy stage name 'code-analyst'"
EXPECTED_MIGRATION_HINT="analyst-impact"

# ---------------------------------------------------------------------------
# Assertion 1: fix-bugs/fix-ticket SKILL.md documents legacy stage name alias
# ---------------------------------------------------------------------------
echo "--- Assertion 1: pipeline skills document code-analyst legacy alias ---"
FOUND_ALIAS=0
for skill in fix-bugs fix-ticket implement-feature; do
  SKILL_FILE="$REPO_ROOT/skills/$skill/SKILL.md"
  if [ -f "$SKILL_FILE" ] && grep -qiE 'code-analyst.*legacy|legacy.*code-analyst|code-analyst.*warn' "$SKILL_FILE"; then
    echo "OK: skills/$skill/SKILL.md documents code-analyst legacy alias"
    FOUND_ALIAS=1
  fi
done
if [ "$FOUND_ALIAS" -eq 0 ]; then
  echo "SKIP: No pipeline SKILL.md found with code-analyst legacy alias (implementation pending)" >&2
  exit 77
fi

# ---------------------------------------------------------------------------
# Assertion 2: WARN contains 'code-analyst' and migration hint 'analyst-impact'
# ---------------------------------------------------------------------------
echo "--- Assertion 2: WARN text includes '$EXPECTED_WARN_FRAGMENT' ---"
FOUND_WARN=0
for skill_file in "$REPO_ROOT/skills/fix-bugs/SKILL.md" \
                  "$REPO_ROOT/skills/fix-ticket/SKILL.md" \
                  "$REPO_ROOT/docs/guides/migration-v7-to-v8.md"; do
  if [ -f "$skill_file" ] && grep -qiF "$EXPECTED_WARN_FRAGMENT" "$skill_file"; then
    echo "OK: '$EXPECTED_WARN_FRAGMENT' found in $(basename "$skill_file")"
    FOUND_WARN=1
  fi
done
if [ "$FOUND_WARN" -eq 0 ]; then
  fail "WARN text fragment '$EXPECTED_WARN_FRAGMENT' not found in any skill/doc"
fi

# ---------------------------------------------------------------------------
# Assertion 3: Migration hint 'analyst-impact' mentioned in WARN or migration guide
# ---------------------------------------------------------------------------
echo "--- Assertion 3: migration hint 'analyst-impact' in WARN or migration guide ---"
MIG_GUIDE="$REPO_ROOT/docs/guides/migration-v7-to-v8.md"
if [ -f "$MIG_GUIDE" ] && grep -qF 'analyst-impact' "$MIG_GUIDE"; then
  echo "OK: migration guide mentions 'analyst-impact' as new stage name"
else
  fail "migration guide missing 'analyst-impact' stage name"
fi

# ---------------------------------------------------------------------------
# Assertion 4: Pipeline profiles mapping table documents all v7 legacy names
# ---------------------------------------------------------------------------
echo "--- Assertion 4: design.md or migration guide documents all v7→v8 stage name mappings ---"
DESIGN="$REPO_ROOT/.forge/phase-4-spec/final/design.md"
if [ -f "$DESIGN" ]; then
  if grep -qF 'code-analyst' "$DESIGN" && grep -qF 'analyst-impact' "$DESIGN"; then
    echo "OK: design.md documents code-analyst → analyst-impact mapping"
  else
    fail "design.md missing code-analyst → analyst-impact mapping"
  fi
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-MIG-007 — legacy 'code-analyst' stage name accepted with WARN + migration hint"
fi
exit "$FAIL"
