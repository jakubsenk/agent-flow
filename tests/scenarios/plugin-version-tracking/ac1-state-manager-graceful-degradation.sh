#!/usr/bin/env bash
# Test: State-manager graceful degradation for missing/malformed plugin.json
# AC-32 through AC-35
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

STATE_MGR="$REPO_ROOT/core/state-manager.md"

if [ ! -f "$STATE_MGR" ]; then
  fail "core/state-manager.md does not exist"
  exit "$FAIL"
fi

# AC-32: Step 2a contains graceful degradation clause covering unreadable/malformed/lacks cases
if ! grep '2a\.' "$STATE_MGR" | grep -q 'unreadable, malformed, or lacks'; then
  fail "core/state-manager.md Step 2a missing graceful degradation clause (expected: 'unreadable, malformed, or lacks')"
fi

# AC-33: Degradation sets plugin_version to null
if ! grep '2a\.' "$STATE_MGR" | grep -q 'plugin_version.*null'; then
  fail "core/state-manager.md Step 2a does not set plugin_version to null on degradation"
fi

# AC-34: Degradation is silent — no error, no warning
if ! grep '2a\.' "$STATE_MGR" | grep -q 'no error, no warning'; then
  fail "core/state-manager.md Step 2a degradation is not documented as silent (expected: 'no error, no warning')"
fi

# AC-35: Degradation clause is inline on Step 2a (references plugin.json + null together)
if ! grep '2a\.' "$STATE_MGR" | grep 'plugin.json' | grep -q 'null'; then
  fail "core/state-manager.md Step 2a degradation clause is not inline on the 2a line (plugin.json + null not on same line)"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: state-manager graceful degradation for plugin.json failures is documented correctly (AC-32 to AC-35)"
exit "$FAIL"
