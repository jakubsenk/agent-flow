#!/usr/bin/env bash
set -euo pipefail

# AC-20: /resume-ticket tolerates v6.7.x state.json (backward compat)
# Traces: COST-R9
# Description: Verifies skills/resume-ticket/SKILL.md does NOT block on absence
#              of the six new per-stage usage fields

# Depends on Phase 7 implementation (resume-ticket SKILL.md is MODIFIED)

cd "$(dirname "$0")/../.."

FILE="core/resume-detection.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

FAIL=0

# Must NOT require schema_version check
if grep -qiE 'schema_version.*required|require.*schema_version' "$FILE"; then
  echo "FAIL: $FILE has schema_version as required — breaks backward compat" >&2
  FAIL=1
fi

# Must document tolerating missing/absent usage fields or corrupt/recoverable state
if ! grep -qiE 'tolerat|backward.?compat|absent.*field|missing.*field|v6\.7|legacy|corrupt|recoverable' "$FILE"; then
  echo "FAIL: $FILE does not document backward compat with v6.7.x state.json" >&2
  FAIL=1
fi

# Must NOT block on missing tokens_used
if grep -qiE 'tokens_used.*required|require.*tokens_used' "$FILE"; then
  echo "FAIL: $FILE treats tokens_used as required — breaks v6.7.x compat" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-20 — core/resume-detection.md tolerates v6.7.x state.json"
exit "$FAIL"
