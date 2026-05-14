#!/usr/bin/env bash
# Verifies: AC-DOC-012, REQ-DOC-012
# Description: README.md has "17 agents", "18 skills", and link to migration guide
# Post-cleanup baseline: skills reduced from 22 to 18.
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

README="$REPO_ROOT/README.md"
if [ ! -f "$README" ]; then
  fail "README.md not found"
  exit 1
fi

# ---------------------------------------------------------------------------
# Assertion 1: "17 agents" in README
# ---------------------------------------------------------------------------
echo "--- Assertion 1: README.md contains '17 agents' ---"
if grep -qF '17 agents' "$README"; then
  echo "OK: README.md contains '17 agents'"
else
  fail "README.md missing '17 agents'"
fi

# ---------------------------------------------------------------------------
# Assertion 2: "18 skills" in README
# ---------------------------------------------------------------------------
echo "--- Assertion 2: README.md contains '18 skills' ---"
if grep -qF '18 skills' "$README"; then
  echo "OK: README.md contains '18 skills'"
else
  fail "README.md missing '18 skills'"
fi

# ---------------------------------------------------------------------------
# Assertion 3: v8 migration reference in README (relaxed — presence-only check)
# ---------------------------------------------------------------------------
echo "--- Assertion 3: README.md references v8 migration content ---"
if grep -qE 'v7-to-v8|to-v8|v8[._]' "$README"; then
  echo "OK: README.md references v8 migration content"
else
  fail "README.md missing any v8 migration reference"
fi

# ---------------------------------------------------------------------------
# Assertion 4: Link to migration guide
# ---------------------------------------------------------------------------
echo "--- Assertion 4: README.md links to migration-v7-to-v8.md ---"
if grep -qF 'migration-v7-to-v8' "$README"; then
  echo "OK: README.md references migration-v7-to-v8.md"
else
  fail "README.md missing link to docs/guides/migration-v7-to-v8.md"
fi

# ---------------------------------------------------------------------------
# Assertion 5: No stale "21 agents" in README
# ---------------------------------------------------------------------------
echo "--- Assertion 5: README.md has no stale '21 agents' ---"
if grep -qF '21 agents' "$README"; then
  fail "README.md still contains stale '21 agents'"
else
  echo "OK: README.md does not contain '21 agents'"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-DOC-012 — README.md content verified (17 agents, 18 skills, migration link)"
fi
exit "$FAIL"
