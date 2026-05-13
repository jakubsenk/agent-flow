#!/usr/bin/env bash
# Scenario: REQ-002, REQ-003, REQ-004 — plugin.json + marketplace.json SPDX exact-match "MIT"
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — plugin.json currently "UNLICENSED", marketplace.json missing field
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"

for f in "$PLUGIN_JSON" "$MARKETPLACE_JSON"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: required file not found: $f" >&2
    exit 1
  fi
done

# Assertion 1 (AC-002): plugin.json license == "MIT" exact string (case-sensitive)
echo "--- Assertion 1 (AC-002): plugin.json license exact 'MIT' ---"
plugin_license=$(python -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('license',''))" "$PLUGIN_JSON" 2>/dev/null || true)
if [ "$plugin_license" = "MIT" ]; then
  echo "OK (AC-002): plugin.json license == 'MIT'"
else
  fail "AC-002: plugin.json license == '$plugin_license' (expected exact 'MIT'; case-sensitive SPDX canonical form)"
fi

# Assertion 2 (AC-003): marketplace.json plugins[0].license == "MIT" exact string
echo "--- Assertion 2 (AC-003): marketplace.json plugins[0].license exact 'MIT' ---"
mp_license=$(python -c "import json,sys; d=json.load(open(sys.argv[1])); print(d['plugins'][0].get('license',''))" "$MARKETPLACE_JSON" 2>/dev/null || true)
if [ "$mp_license" = "MIT" ]; then
  echo "OK (AC-003): marketplace.json plugins[0].license == 'MIT'"
else
  fail "AC-003: marketplace.json plugins[0].license == '$mp_license' (expected exact 'MIT'; field was previously absent)"
fi

# Assertion 3 (AC-004 NEGATIVE): no non-canonical SPDX variant in either file
echo "--- Assertion 3 (AC-004 NEGATIVE): no variant SPDX strings ---"
if grep -E '"license"\s*:\s*"(MIT-License|mit|MIT-1\.0|MIT License)"' "$PLUGIN_JSON" "$MARKETPLACE_JSON" >/dev/null 2>&1; then
  fail "AC-004: non-canonical SPDX variant found in plugin.json or marketplace.json (allowed: only 'MIT')"
else
  echo "OK (AC-004): no non-canonical SPDX variant strings in plugin metadata"
fi

# Assertion 4 (AC-005): README.md uses new format, not old plugin.json pointer
echo "--- Assertion 4 (AC-005): README.md license link updated ---"
README="$REPO_ROOT/README.md"
if [ ! -f "$README" ]; then
  fail "AC-005: README.md not found"
else
  if grep -qF '**Filip Sabacky** — [MIT License](LICENSE)' "$README"; then
    echo "OK (AC-005): README.md contains new MIT License link format"
  else
    fail "AC-005: README.md does not contain '**Filip Sabacky** — [MIT License](LICENSE)'"
  fi
  if grep -qF 'See [plugin.json](.claude-plugin/plugin.json) for license details.' "$README"; then
    fail "AC-005 NEGATIVE: README.md still contains old 'See plugin.json for license details' text (should be removed)"
  else
    echo "OK (AC-005): old plugin.json license pointer removed from README.md"
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 SPDX canonical 'MIT' in plugin.json + marketplace.json; README.md updated"
fi
exit "$FAIL"
