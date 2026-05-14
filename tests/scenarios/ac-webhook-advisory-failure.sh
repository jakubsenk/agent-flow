#!/usr/bin/env bash
set -euo pipefail

# Webhook failure is advisory (WARN + continue, pipeline not blocked)
# Description: Verifies core/post-publish-hook.md documents advisory failure semantics
#              for new pipeline events

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FILE="core/post-publish-hook.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist — create it in Phase 7" >&2
  exit 1
fi

FAIL=0

# Must document [WARN] Webhook delivery failed message
if ! grep -qF '[WARN] Webhook delivery failed' "$FILE"; then
  echo "FAIL: $FILE missing '[WARN] Webhook delivery failed' advisory message" >&2
  FAIL=1
fi

# Must document advisory/continue semantics (pipeline not blocked)
if ! grep -qiE 'advisory|not block|pipeline.*continue|continue.*pipeline' "$FILE"; then
  echo "FAIL: $FILE does not document advisory failure semantics for webhooks" >&2
  FAIL=1
fi

# Forward-compat guarantee paragraph in CLAUDE.md
if ! grep -qF 'Webhook payloads are forward-compatible' CLAUDE.md; then
  echo "FAIL: CLAUDE.md missing 'Webhook payloads are forward-compatible' paragraph" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Webhook advisory failure semantics documented"
exit "$FAIL"
