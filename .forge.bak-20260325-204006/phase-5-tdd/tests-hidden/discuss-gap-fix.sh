#!/usr/bin/env bash
# Test: skills/bug-workflow SKILL.md has ≥24 routing entries (discuss command was missing)
# Validates: PR 0 discuss gap fix — /discuss command is routed in the bug-workflow skill
# PR 0: Bug fixes — discuss command routing gap
# NOTE: This test verifies that the discuss gap fix lands ≥24 routing entries.
#       The current pre-PR-0 count is 26 table rows but /discuss routing may be absent.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL_FILE="$REPO_ROOT/skills/bug-workflow/SKILL.md"

if [ ! -f "$SKILL_FILE" ]; then
  fail "Missing file: skills/bug-workflow/SKILL.md"
  exit 1
fi

# Count table rows that reference a ceos-agents: command (routing entries)
routing_count=$(grep -c "ceos-agents:" "$SKILL_FILE" || echo 0)
if [ "$routing_count" -lt 24 ]; then
  fail "skills/bug-workflow/SKILL.md has only $routing_count ceos-agents: references, expected ≥24"
fi

# Specifically verify /discuss is routed
if ! grep -q "ceos-agents:discuss" "$SKILL_FILE"; then
  fail "skills/bug-workflow/SKILL.md missing ceos-agents:discuss routing entry"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: skills/bug-workflow/SKILL.md has ≥24 routing entries including ceos-agents:discuss"
exit "$FAIL"
