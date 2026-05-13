#!/usr/bin/env bash
# Hidden scenario: REQ-001, REQ-002, REQ-003 — SPDX ID "MIT" validated against approved-list
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — plugin.json license is "UNLICENSED"
set -uo pipefail

# CRITICAL: 3 levels up from .forge/phase-5-tdd/tests-hidden/ to repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"

# Verify REPO_ROOT resolves correctly (contains plugin.json)
if [ ! -f "$REPO_ROOT/.claude-plugin/plugin.json" ]; then
  echo "FAIL: REPO_ROOT path resolution bug — .claude-plugin/plugin.json not found at $REPO_ROOT" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"

# Offline SPDX approved-list (common OSI-approved identifiers acceptable for Claude Code plugins)
# This is not exhaustive but covers the set most likely to be used.
APPROVED_SPDX=(
  "MIT"
  "Apache-2.0"
  "BSD-2-Clause"
  "BSD-3-Clause"
  "ISC"
  "GPL-2.0-only"
  "GPL-3.0-only"
  "LGPL-2.1-only"
  "LGPL-3.0-only"
  "MPL-2.0"
  "AGPL-3.0-only"
  "CC0-1.0"
)

# Assertion 1 (AC-002): plugin.json license is in the approved SPDX list
echo "--- Assertion 1: plugin.json license in approved SPDX list ---"
plugin_license=$(jq -r '.license // empty' "$PLUGIN_JSON" 2>/dev/null)
if [ -z "$plugin_license" ]; then
  fail "plugin.json missing 'license' field (SPDX ID required)"
else
  found=0
  for spdx in "${APPROVED_SPDX[@]}"; do
    if [ "$plugin_license" = "$spdx" ]; then
      found=1; break
    fi
  done
  if [ "$found" -eq 1 ]; then
    echo "OK: plugin.json license='$plugin_license' is an approved SPDX identifier"
  else
    fail "plugin.json license='$plugin_license' is NOT in the approved SPDX list (or is a non-canonical variant)"
  fi
fi

# Assertion 2: plugin.json license is exactly "MIT" (the committed choice per REQ-002)
echo "--- Assertion 2: plugin.json license == exact 'MIT' ---"
if [ "$plugin_license" = "MIT" ]; then
  echo "OK: plugin.json license == 'MIT' exact canonical form"
else
  fail "plugin.json license='$plugin_license' (expected exactly 'MIT' — committed choice per REQ-002)"
fi

# Assertion 3 (AC-003): marketplace.json mirrors plugin.json
echo "--- Assertion 3: marketplace.json license mirrors plugin.json ---"
mp_license=$(jq -r '.plugins[0].license // empty' "$MARKETPLACE_JSON" 2>/dev/null)
if [ "$mp_license" = "$plugin_license" ]; then
  echo "OK: marketplace.json license='$mp_license' mirrors plugin.json"
else
  fail "marketplace.json license='$mp_license' does not mirror plugin.json license='$plugin_license'"
fi

# Assertion 4 (AC-004 NEGATIVE): no non-canonical forms anywhere
echo "--- Assertion 4 NEGATIVE: no non-canonical SPDX variants ---"
bad_variants=("MIT-License" "mit" "MIT-1.0" "MIT License" "UNLICENSED")
for variant in "${bad_variants[@]}"; do
  if grep -qF "\"$variant\"" "$PLUGIN_JSON" 2>/dev/null; then
    fail "Non-canonical SPDX variant '$variant' found in plugin.json"
  fi
  if grep -qF "\"$variant\"" "$MARKETPLACE_JSON" 2>/dev/null; then
    fail "Non-canonical SPDX variant '$variant' found in marketplace.json"
  fi
done
echo "OK: no non-canonical SPDX variants in plugin.json or marketplace.json"

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: h-license-spdx-roundtrip — MIT is approved SPDX; exact canonical form; marketplace mirrors; no variants"
fi
exit "$FAIL"
