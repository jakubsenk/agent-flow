#!/usr/bin/env bash
# Scenario: REQ-003, REQ-005 — marketplace.json mirrors plugin.json license; README link
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — marketplace.json missing license field
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"

# Assertion 1 (AC-003): marketplace.json plugins[0].license present
echo "--- Assertion 1 (AC-003): marketplace.json plugins[0].license present ---"
mp_license=$(python -c "import json,sys; d=json.load(open(sys.argv[1])); print(d['plugins'][0].get('license',''))" "$MARKETPLACE_JSON" 2>/dev/null || true)
if [ -z "$mp_license" ]; then
  fail "AC-003: marketplace.json plugins[0].license field is absent (additive add required per REQ-003)"
else
  echo "OK: marketplace.json plugins[0].license = '$mp_license'"
fi

# Assertion 2 (AC-003): marketplace mirrors plugin.json license exactly
echo "--- Assertion 2 (AC-003): marketplace.json mirrors plugin.json license ---"
plugin_license=$(python -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('license',''))" "$PLUGIN_JSON" 2>/dev/null || true)
if [ "$mp_license" = "$plugin_license" ]; then
  echo "OK: marketplace.json license ('$mp_license') mirrors plugin.json license ('$plugin_license')"
else
  fail "AC-003: marketplace.json license '$mp_license' does NOT mirror plugin.json license '$plugin_license'"
fi

# Assertion 3 (AC-003): value is "MIT" not empty or variant
echo "--- Assertion 3 (AC-003): value is exact 'MIT' ---"
if [ "$mp_license" = "MIT" ]; then
  echo "OK: marketplace.json plugins[0].license == 'MIT' exact match"
else
  fail "AC-003: marketplace.json plugins[0].license == '$mp_license' (must be exact 'MIT')"
fi

# Assertion 4 (AC-005): README.md near-Author-section link to SECURITY.md (REQ-008 companion check)
echo "--- Assertion 4 (AC-008): README.md links to SECURITY.md ---"
README="$REPO_ROOT/README.md"
if grep -qF '[SECURITY.md](SECURITY.md)' "$README"; then
  echo "OK (AC-008): README.md links to SECURITY.md"
else
  fail "AC-008: README.md missing '[SECURITY.md](SECURITY.md)' link near Author & License section"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 marketplace.json mirrors plugin.json MIT license; README.md links to SECURITY.md"
fi
exit "$FAIL"
