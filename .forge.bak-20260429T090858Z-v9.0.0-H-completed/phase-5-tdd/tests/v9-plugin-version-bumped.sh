#!/bin/bash
# PURPOSE: Assert .claude-plugin/plugin.json version reads "9.0.0" and
#          .claude-plugin/marketplace.json plugins[0].version also reads "9.0.0" (REQ-H-040).
#          Uses grep/sed only — no jq, no python (per harness POSIX-compat requirement).
# AC-H-N covered: AC-H-100, AC-H-101
# INVOKED BY: tests/harness/run-tests.sh
# EXPECTED ON v8.0.0: FAIL (version is 8.0.0)
# EXPECTED ON v9.0.0: PASS (version is 9.0.0 in both files)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"

# AC-H-100: plugin.json version = "9.0.0"
if [ ! -f "$PLUGIN_JSON" ]; then
  fail ".claude-plugin/plugin.json not found"
  exit 1
fi

plugin_version=$(grep -oE '"version"\s*:\s*"[^"]*"' "$PLUGIN_JSON" | head -1 | grep -oE '"[0-9][^"]*"' | tr -d '"')
if [ "$plugin_version" != "9.0.0" ]; then
  fail ".claude-plugin/plugin.json version is '$plugin_version', expected '9.0.0'"
  # Mutation catch: version bump to wrong number (e.g., 8.1.0 or 8.0.1) fails here
fi

# AC-H-101: marketplace.json plugins[0].version = "9.0.0"
if [ ! -f "$MARKETPLACE_JSON" ]; then
  fail ".claude-plugin/marketplace.json not found"
  exit 1
fi

marketplace_version=$(grep -oE '"version"\s*:\s*"[^"]*"' "$MARKETPLACE_JSON" | head -1 | grep -oE '"[0-9][^"]*"' | tr -d '"')
if [ "$marketplace_version" != "9.0.0" ]; then
  fail ".claude-plugin/marketplace.json version is '$marketplace_version', expected '9.0.0'"
  # Mutation catch: forgetting to update marketplace.json fails here
fi

# Consistency check: both files must have the same version
if [ "$plugin_version" != "$marketplace_version" ]; then
  fail "Version mismatch: plugin.json='$plugin_version', marketplace.json='$marketplace_version' — must be identical"
fi

# Negative assertion: must not be v8.x
if echo "$plugin_version" | grep -qE '^8\.'; then
  fail "plugin.json version $plugin_version is still v8.x — not bumped to v9.0.0"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-H-100, AC-H-101 — plugin.json and marketplace.json both read version '9.0.0'"
fi
exit "$FAIL"
