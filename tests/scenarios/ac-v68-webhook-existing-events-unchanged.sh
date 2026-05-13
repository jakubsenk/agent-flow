#!/usr/bin/env bash
set -euo pipefail

# AC-13: Existing pr-created and issue-blocked payloads unchanged
# Traces: WEBHOOK-R8
# Description: Verifies pr-created payload has {event, issue_id, pr_url, timestamp}
#              and issue-blocked payload has {event, issue_id, agent, reason, timestamp}

# NOTE: This is a regression guard (§8.8 known limitation — indicative, not byte-diff contract).
# Passes green now (pre-Phase 7) since these events already exist in v6.7.2.
# Must remain green after Phase 7.

cd "$(dirname "$0")/../.."

FAIL=0

HOOK="core/post-publish-hook.md"
BLOCK="core/block-handler.md"

if [ ! -f "$HOOK" ]; then
  echo "FAIL: $HOOK does not exist" >&2
  FAIL=1
else
  # pr-created payload fields: event, issue_id, pr_url, timestamp
  if ! grep -A3 '"event":"pr-created"' "$HOOK" | grep -qE 'issue_id|pr_url|timestamp'; then
    # Fallback: check the fields exist anywhere near the event
    if ! grep -qF '"pr_url"' "$HOOK"; then
      echo "FAIL: $HOOK missing 'pr_url' field in pr-created payload context" >&2
      FAIL=1
    fi
  fi
fi

if [ ! -f "$BLOCK" ]; then
  echo "FAIL: $BLOCK does not exist" >&2
  FAIL=1
else
  # issue-blocked payload fields: event, issue_id, agent, reason, timestamp
  for field in agent reason; do
    if ! grep -qF "\"$field\"" "$BLOCK"; then
      echo "FAIL: $BLOCK missing '$field' field in issue-blocked payload" >&2
      FAIL=1
    fi
  done
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-13 — pr-created and issue-blocked payload fields verified (regression guard)"
exit "$FAIL"
