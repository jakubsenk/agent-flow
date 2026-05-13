#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #3 — Tier B)
# Functional: all required webhook events still documented.
# Iterates all 5 required event names across docs.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Required webhook events (backward-compat contract per v6.8.0+)
REQUIRED_EVENTS=(
  "pr-created"
  "issue-blocked"
  "pipeline-started"
  "step-completed"
  "pipeline-completed"
)

# Check docs + core for each event name
search_dirs=("$REPO_ROOT/docs" "$REPO_ROOT/core" "$REPO_ROOT/skills")
for event in "${REQUIRED_EVENTS[@]}"; do
  found=0
  for d in "${search_dirs[@]}"; do
    if grep -rlqF "$event" "$d" 2>/dev/null; then
      found=1
      break
    fi
  done
  [ "$found" -eq 1 ] || fail "Webhook event '$event' not found in docs/core/skills"
done

# Mutation guard: check event names are NOT removed — negative test
# If 'pr-created' were removed from all docs, this would fail
# Verify at least CLAUDE.md lists them
if ! grep -qF 'pr-created' "$REPO_ROOT/CLAUDE.md"; then
  fail "CLAUDE.md missing 'pr-created' webhook event"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: all 5 webhook events present"
exit "$FAIL"
