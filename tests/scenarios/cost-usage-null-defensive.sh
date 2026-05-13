#!/usr/bin/env bash
set -euo pipefail

# AC-16: Defensive read writes zeros when Task usage is null
# Traces: COST-R3
# Description: Verifies state-manager.md documents defensive fallback to 0 for missing usage

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FILE="core/state-manager.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

FAIL=0

# result.usage null check documented
if ! grep -qiE 'result\.usage|usage.*null|null.*usage' "$FILE"; then
  echo "FAIL: $FILE does not document result.usage null check" >&2
  FAIL=1
fi

# Defensive fallback to 0
if ! grep -qiE 'fallback.*0|default.*0|0.*fallback|write.*0|0.*missing' "$FILE"; then
  echo "FAIL: $FILE does not document writing 0 as defensive fallback for null usage" >&2
  FAIL=1
fi

# Must not retry or block on null usage (check without negation context)
# Pattern: "retry on null" or "block on null" — but NOT "do not retry" or "do not block"
if grep -iE 'retry.*null|null.*retry' "$FILE" | grep -qivE 'do not retry|not.*retry|never retry'; then
  echo "FAIL: $FILE documents retry on null usage — must be defensive 0 only (no retry)" >&2
  FAIL=1
fi
if grep -iE 'block.*null|null.*block' "$FILE" | grep -qivE 'do not block|not.*block|never block'; then
  echo "FAIL: $FILE documents block on null usage — must be defensive 0 only (no block)" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: cost-usage-null-defensive — state-manager.md documents defensive 0 fallback"
exit "$FAIL"
