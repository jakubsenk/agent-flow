#!/usr/bin/env bash
set -euo pipefail

# REGRESSION: pr-created and agent-flow-block events still referenced
# Traces: WEBHOOK-R8
# Description: Verifies that adding new pipeline events did not remove or rename
#              the existing pr-created and issue-blocked (agent-flow-block) events

cd "$(dirname "$0")/../.."

FAIL=0

# core/post-publish-hook.md must still reference pr-created
HOOK="core/post-publish-hook.md"
if [ -f "$HOOK" ]; then
  if ! grep -qF 'pr-created' "$HOOK"; then
    echo "FAIL: $HOOK no longer references 'pr-created' event (regression)" >&2
    FAIL=1
  fi
fi

# core/block-handler.md must still reference issue-blocked (agent-flow-block)
BLOCK="core/block-handler.md"
if [ -f "$BLOCK" ]; then
  if ! grep -qE 'issue-blocked|agent-flow-block' "$BLOCK"; then
    echo "FAIL: $BLOCK no longer references 'issue-blocked' or 'agent-flow-block' event (regression)" >&2
    FAIL=1
  fi
fi

# docs/reference/config.md should still reference pr-created and issue-blocked events
# (CLAUDE.md may list only new events; canonical event list is in core/ and docs/reference/)
CONFIG_REF="docs/reference/config.md"
if [ -f "$CONFIG_REF" ]; then
  if ! grep -qiE 'pr-created|issue-blocked|agent-flow-block' "$CONFIG_REF"; then
    echo "FAIL: $CONFIG_REF no longer references 'pr-created' or 'issue-blocked' events (regression)" >&2
    FAIL=1
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: REGRESSION — pr-created and issue-blocked events still present"
exit "$FAIL"
