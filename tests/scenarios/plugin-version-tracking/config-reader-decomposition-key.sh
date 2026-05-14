#!/usr/bin/env bash
# Test: config-reader.md Decomposition entry contains create_tracker_subtasks key
# AC-1 through AC-3
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

CONFIG_READER="$REPO_ROOT/core/config-reader.md"

if [ ! -f "$CONFIG_READER" ]; then
  fail "core/config-reader.md does not exist"
  exit "$FAIL"
fi

# AC-1: decomposition.create_tracker_subtasks key is present
if ! grep -q 'decomposition.create_tracker_subtasks' "$CONFIG_READER"; then
  fail "core/config-reader.md missing key: decomposition.create_tracker_subtasks"
fi

# AC-2: Key has default value of 'enabled'
if ! grep 'decomposition.create_tracker_subtasks' "$CONFIG_READER" | grep -q 'default: .enabled.'; then
  fail "core/config-reader.md: decomposition.create_tracker_subtasks does not have default: 'enabled'"
fi

# AC-3: Key appears on the same line as decomposition.max_subtasks (single-line format)
if ! grep 'Decomposition' "$CONFIG_READER" | grep 'decomposition.max_subtasks' | grep -q 'decomposition.create_tracker_subtasks'; then
  fail "core/config-reader.md: decomposition.create_tracker_subtasks is not on the same line as decomposition.max_subtasks (single-line format broken)"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: config-reader.md Decomposition entry contains decomposition.create_tracker_subtasks with default 'enabled' (AC-1 to AC-3)"
exit "$FAIL"
