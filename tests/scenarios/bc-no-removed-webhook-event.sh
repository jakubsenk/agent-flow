#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #3 — Tier B)
# Functional: all required webhook events still documented.
# Iterates all 5 required event names across docs.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Required webhook events (backward-compat contract)
# CLAUDE.md §Webhook Payloads: "pr-created" and "agent-flow-block" are never renamed or removed.
# "issue-blocked" is the On events config alias; "agent-flow-block" is the payload event name.
REQUIRED_EVENTS=(
  "pr-created"
  "agent-flow-block"
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

# Mutation guard: CLAUDE.md explicitly contracts pr-created + agent-flow-block as never-removed
if ! grep -qF 'pr-created' "$REPO_ROOT/CLAUDE.md"; then
  fail "CLAUDE.md missing 'pr-created' webhook event"
fi
if ! grep -qF 'agent-flow-block' "$REPO_ROOT/CLAUDE.md"; then
  fail "CLAUDE.md missing 'agent-flow-block' webhook event (backward-compat contract)"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: all 5 webhook events present"
exit "$FAIL"
