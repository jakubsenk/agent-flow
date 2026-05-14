#!/usr/bin/env bash
set -euo pipefail

# core/post-publish-hook.md Purpose line updated and Section 4 added
# Description: Verifies post-publish-hook.md has updated Purpose and Section 4 for pipeline events

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FILE="core/post-publish-hook.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

# Updated Purpose line
if ! grep -qF 'Execute pipeline hooks and fire webhooks at stage boundaries' "$FILE"; then
  echo "FAIL: $FILE Purpose line not updated to 'Execute pipeline hooks and fire webhooks at stage boundaries'" >&2
  exit 1
fi

# Section 4 must exist with Pipeline lifecycle events
if ! grep -nE '^## (4|Section 4)\b.*Pipeline lifecycle events' "$FILE" | grep -q .; then
  echo "FAIL: $FILE missing Section 4 'Pipeline lifecycle events' heading" >&2
  exit 1
fi

echo "PASS: core/post-publish-hook.md has updated Purpose and Section 4"
exit 0
