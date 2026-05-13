#!/usr/bin/env bash
set -euo pipefail

# AC-21 (config-reader aspect): core/config-reader.md lists all 7 Autopilot keys
# Traces: AUTOPILOT-R6, AUTOPILOT-R10, AUTOPILOT-R11
# Description: Verifies core/config-reader.md has a ### Autopilot parse block with 7 keys

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../../.."

FILE="core/config-reader.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

FAIL=0

# Must have Autopilot section
if ! grep -qiE '### Autopilot|Autopilot.*parse|autopilot.*keys' "$FILE"; then
  echo "FAIL: $FILE missing ### Autopilot parse block" >&2
  FAIL=1
fi

# Must list all 7 dot-notation keys
KEYS=(
  "autopilot.max_issues_per_run"
  "autopilot.lock_timeout"
  "autopilot.log_file"
  "autopilot.bug_limit"
  "autopilot.feature_limit"
  "autopilot.on_error"
  "autopilot.dry_run"
)

for key in "${KEYS[@]}"; do
  if ! grep -qF "$key" "$FILE"; then
    echo "FAIL: $FILE missing Autopilot key '$key'" >&2
    FAIL=1
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: core/config-reader.md documents all 7 Autopilot keys"
exit "$FAIL"
