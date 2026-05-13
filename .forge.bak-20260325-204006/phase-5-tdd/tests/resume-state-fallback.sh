#!/usr/bin/env bash
# Test: resume-ticket.md references both state.json AND heuristic detection fallback
# Validates: PR 1 update to resume-ticket — dual path (state file first, heuristic fallback)
# PR 1: State management
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

RESUME="$REPO_ROOT/commands/resume-ticket.md"

if [ ! -f "$RESUME" ]; then
  fail "commands/resume-ticket.md does not exist"
  exit 1
fi

# Must reference state.json for primary resume path
if ! grep -q "state\.json" "$RESUME"; then
  fail "commands/resume-ticket.md must reference state.json for state-based resume"
fi

# Must reference .ceos-agents/ runtime directory
if ! grep -q "\.ceos-agents/" "$RESUME"; then
  fail "commands/resume-ticket.md must reference .ceos-agents/ runtime directory"
fi

# Must retain heuristic detection fallback (7-level priority or equivalent)
# The heuristic approach uses git log / comment scanning — check for fallback language
if ! grep -qi "heuristic\|fallback\|fall back\|if.*state.*not.*exist\|no state\|absent" "$RESUME"; then
  fail "commands/resume-ticket.md must describe heuristic fallback when state.json is absent"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: resume-ticket.md references both state.json and heuristic detection fallback"
exit "$FAIL"
