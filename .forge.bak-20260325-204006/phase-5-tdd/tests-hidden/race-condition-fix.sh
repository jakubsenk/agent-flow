#!/usr/bin/env bash
# Test: Race condition fix — reproducer and browser-verifier use per-issue .ceos-agents/ paths
# Validates: AC-2.8 — agents reference .ceos-agents/{issue-id}/ not shared .claude/ paths
# PR 0: Bug fixes — race condition in concurrent pipeline runs
# NOTE: This test FAILS before PR 0 is merged (TDD — red phase)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

REPRODUCER="$REPO_ROOT/agents/reproducer.md"
BROWSER_VFR="$REPO_ROOT/agents/browser-verifier.md"

if [ ! -f "$REPRODUCER" ]; then
  fail "Missing agent file: agents/reproducer.md"
fi
if [ ! -f "$BROWSER_VFR" ]; then
  fail "Missing agent file: agents/browser-verifier.md"
fi

# Must NOT reference shared .claude/ paths for result artifacts
if grep -q '\.claude/reproduction-result\.json' "$REPRODUCER"; then
  fail "agents/reproducer.md still uses shared .claude/reproduction-result.json (race condition)"
fi
if grep -q '\.claude/reproducer-script\.js' "$REPRODUCER"; then
  fail "agents/reproducer.md still uses shared .claude/reproducer-script.js (race condition)"
fi
if grep -q '\.claude/verification-result\.json' "$BROWSER_VFR"; then
  fail "agents/browser-verifier.md still uses shared .claude/verification-result.json (race condition)"
fi
if grep -q '\.claude/reproducer-script\.js' "$BROWSER_VFR"; then
  fail "agents/browser-verifier.md still uses shared .claude/reproducer-script.js (race condition)"
fi

# Must reference per-issue .ceos-agents/ paths
if ! grep -q '\.ceos-agents/' "$REPRODUCER"; then
  fail "agents/reproducer.md must reference .ceos-agents/ per-issue directory"
fi
if ! grep -q '\.ceos-agents/' "$BROWSER_VFR"; then
  fail "agents/browser-verifier.md must reference .ceos-agents/ per-issue directory"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Race condition fix — both agents use per-issue .ceos-agents/ paths"
exit "$FAIL"
