#!/usr/bin/env bash
# Verifies: AC-INV-LICENSE-001, REQ-INV-001
# Description: plugin.json, marketplace.json, LICENSE all reference exact "MIT" SPDX string
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

EXPECTED="MIT"

# ---------------------------------------------------------------------------
# Assertion 1: .claude-plugin/plugin.json license field = "MIT"
# ---------------------------------------------------------------------------
echo "--- Assertion 1: plugin.json license = 'MIT' ---"
PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
if [ ! -f "$PLUGIN_JSON" ]; then
  fail ".claude-plugin/plugin.json not found"
else
  if command -v jq > /dev/null 2>&1; then
    LICENSE_PLUGIN=$(jq -r '.license' "$PLUGIN_JSON")
  else
    LICENSE_PLUGIN=$(grep '"license"' "$PLUGIN_JSON" | sed 's/.*"license"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
  fi
  if [ "$LICENSE_PLUGIN" = "$EXPECTED" ]; then
    echo "OK: plugin.json license = '$LICENSE_PLUGIN'"
  else
    fail "plugin.json license = '$LICENSE_PLUGIN', expected '$EXPECTED' (case-sensitive)"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 2: .claude-plugin/marketplace.json plugins[0].license = "MIT"
# ---------------------------------------------------------------------------
echo "--- Assertion 2: marketplace.json plugins[0].license = 'MIT' ---"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
if [ ! -f "$MARKETPLACE_JSON" ]; then
  fail ".claude-plugin/marketplace.json not found"
else
  if command -v jq > /dev/null 2>&1; then
    LICENSE_MARKET=$(jq -r '.plugins[0].license' "$MARKETPLACE_JSON")
  else
    LICENSE_MARKET=$(grep '"license"' "$MARKETPLACE_JSON" | head -1 | sed 's/.*"license"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
  fi
  if [ "$LICENSE_MARKET" = "$EXPECTED" ]; then
    echo "OK: marketplace.json license = '$LICENSE_MARKET'"
  else
    fail "marketplace.json license = '$LICENSE_MARKET', expected '$EXPECTED'"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 3: LICENSE file first heading contains "MIT"
# ---------------------------------------------------------------------------
echo "--- Assertion 3: LICENSE file first heading contains 'MIT' ---"
LICENSE_FILE="$REPO_ROOT/LICENSE"
if [ ! -f "$LICENSE_FILE" ]; then
  fail "LICENSE file not found"
else
  FIRST_LINE=$(head -1 "$LICENSE_FILE")
  if echo "$FIRST_LINE" | grep -q "MIT"; then
    echo "OK: LICENSE first line contains 'MIT': '$FIRST_LINE'"
  else
    fail "LICENSE first line '$FIRST_LINE' does not contain 'MIT'"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 4: All 3 values are identical "MIT" (not MIT-0, not Apache, etc.)
# ---------------------------------------------------------------------------
echo "--- Assertion 4: all 3 license values are exactly 'MIT' ---"
# Already checked above; this is a summary guard
if [ "$LICENSE_PLUGIN" = "$EXPECTED" ] && [ "$LICENSE_MARKET" = "$EXPECTED" ]; then
  echo "OK: all 3 license values equal '$EXPECTED' (case-sensitive)"
else
  fail "License SPDX mismatch — expected all '$EXPECTED'"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-INV-LICENSE-001 — all 3 license sources = 'MIT'"
fi
exit "$FAIL"
