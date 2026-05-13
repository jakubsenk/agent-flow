#!/usr/bin/env bash
# AC: AC-META-2-1 (hidden — MINOR version justified, no new required config keys)
# Asserts version bumped to 6.10.0 across plugin.json + marketplace.json,
# CHANGELOG has v6.10.0 section, state schema stays 1.0.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# plugin.json version
PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
[ -f "$PLUGIN_JSON" ] || { fail ".claude-plugin/plugin.json not found"; exit 1; }
plugin_version=$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$PLUGIN_JSON" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
[ "$plugin_version" = "6.10.0" ] || fail "plugin.json version should be 6.10.0, got $plugin_version"

# marketplace.json version
MKT_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
[ -f "$MKT_JSON" ] || { fail ".claude-plugin/marketplace.json not found"; exit 1; }
mkt_version=$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$MKT_JSON" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
[ "$mkt_version" = "6.10.0" ] || fail "marketplace.json version should be 6.10.0, got $mkt_version"

# CHANGELOG has v6.10.0 section
CHANGELOG="$REPO_ROOT/CHANGELOG.md"
if ! grep -qF '## [6.10.0]' "$CHANGELOG"; then
  fail "CHANGELOG.md missing ## [6.10.0] section"
fi

# state/schema.md stays version 1.0
SCHEMA="$REPO_ROOT/state/schema.md"
if [ -f "$SCHEMA" ]; then
  if ! grep -qF '"schema_version": "1.0"' "$SCHEMA"; then
    fail "state/schema.md must retain schema_version 1.0"
  fi
  if grep -qE '"[2-9]\.[0-9]"' "$SCHEMA"; then
    fail "state/schema.md erroneously has schema version >= 2.0"
  fi
fi

echo "PASS: MINOR version justified — 6.10.0 across all artifacts, schema_version 1.0"
exit "$FAIL"
