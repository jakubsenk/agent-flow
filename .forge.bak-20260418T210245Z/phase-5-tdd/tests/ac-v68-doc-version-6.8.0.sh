#!/usr/bin/env bash
set -euo pipefail

# AC-27: Version bumped to 6.8.0 in plugin and marketplace manifests
# Traces: all
# Description: Verifies .claude-plugin/plugin.json and marketplace.json show version 6.8.0

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../../.."

FAIL=0

PLUGIN=".claude-plugin/plugin.json"
MARKET=".claude-plugin/marketplace.json"

for f in "$PLUGIN" "$MARKET"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: $f does not exist" >&2
    FAIL=1
    continue
  fi
  if ! grep -qF '"version": "6.8.0"' "$f"; then
    echo "FAIL: $f does not contain '\"version\": \"6.8.0\"'" >&2
    FAIL=1
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: AC-27 — plugin.json and marketplace.json show version 6.8.0"
exit "$FAIL"
