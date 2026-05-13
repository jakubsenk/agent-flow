#!/usr/bin/env bash
# Test: core/config-reader.md includes Sprint Planning as optional section with required keys
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

CONFIG_READER="$REPO_ROOT/core/config-reader.md"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

# 1. core/config-reader.md must exist
if [ ! -f "$CONFIG_READER" ]; then
  fail "core/config-reader.md does not exist"
  exit 1
fi

# 2. Sprint Planning section exists in config-reader.md
if ! grep -qi "Sprint Planning" "$CONFIG_READER"; then
  fail "core/config-reader.md missing 'Sprint Planning' optional section"
fi

# 3. Sprint duration key
if ! grep -qi "Sprint duration\|sprint.duration" "$CONFIG_READER"; then
  fail "core/config-reader.md Sprint Planning section missing 'Sprint duration' key"
fi

# 4. Capacity unit key
if ! grep -qi "Capacity unit\|capacity.unit" "$CONFIG_READER"; then
  fail "core/config-reader.md Sprint Planning section missing 'Capacity unit' key"
fi

# 5. Team capacity key
if ! grep -qi "Team capacity\|team.capacity" "$CONFIG_READER"; then
  fail "core/config-reader.md Sprint Planning section missing 'Team capacity' key"
fi

# 6. Sprint Planning also in CLAUDE.md optional sections table
if ! grep -qi "Sprint Planning" "$CLAUDE_MD"; then
  fail "CLAUDE.md optional sections table missing 'Sprint Planning' section"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: core/config-reader.md includes Sprint Planning optional section with Sprint duration, Capacity unit, Team capacity keys; CLAUDE.md also lists it"
exit "$FAIL"
