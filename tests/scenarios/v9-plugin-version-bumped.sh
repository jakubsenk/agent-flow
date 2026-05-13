#!/bin/bash
# PURPOSE: Assert .claude-plugin/plugin.json and .claude-plugin/marketplace.json
#          carry an identical, well-formed semver version (self-consistency check).
#          Catches the real failure mode of /ceos-agents:version-bump skipping
#          marketplace.json or the two files drifting. Negative-asserts v8.x
#          legacy values so a regression to pre-v9 numbers is also caught.
#          Uses grep/sed only — no jq, no python (per harness POSIX-compat requirement).
# AC-H-N covered: AC-H-100, AC-H-101
# INVOKED BY: tests/harness/run-tests.sh
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

if [ ! -f "$PLUGIN_JSON" ]; then
  fail ".claude-plugin/plugin.json not found"
  exit 1
fi
if [ ! -f "$MARKETPLACE_JSON" ]; then
  fail ".claude-plugin/marketplace.json not found"
  exit 1
fi

plugin_version=$(grep -oE '"version"\s*:\s*"[^"]*"' "$PLUGIN_JSON" | head -1 | grep -oE '"[0-9][^"]*"' | tr -d '"')
marketplace_version=$(grep -oE '"version"\s*:\s*"[^"]*"' "$MARKETPLACE_JSON" | head -1 | grep -oE '"[0-9][^"]*"' | tr -d '"')

# AC-H-100: plugin.json version is well-formed semver MAJOR.MINOR.PATCH
if ! echo "$plugin_version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  fail ".claude-plugin/plugin.json version is '$plugin_version', not well-formed semver MAJOR.MINOR.PATCH"
fi

# AC-H-101: marketplace.json version is well-formed semver MAJOR.MINOR.PATCH
if ! echo "$marketplace_version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  fail ".claude-plugin/marketplace.json version is '$marketplace_version', not well-formed semver MAJOR.MINOR.PATCH"
fi

# Consistency check: both files must declare the same version (real failure
# mode of version-bump — forgetting one of the two files).
if [ "$plugin_version" != "$marketplace_version" ]; then
  fail "Version mismatch: plugin.json='$plugin_version', marketplace.json='$marketplace_version' — must be identical"
fi

# Negative assertion: must not regress to v8.x or earlier (release floor for
# this branch is v9.0.0 — sub-projekt H landed there).
major=$(echo "$plugin_version" | cut -d. -f1)
if [ -n "$major" ] && [ "$major" -lt 9 ] 2>/dev/null; then
  fail "plugin.json version $plugin_version is below v9.0.0 release floor"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-H-100, AC-H-101 — plugin.json and marketplace.json both read identical semver '$plugin_version'"
fi
exit "$FAIL"
