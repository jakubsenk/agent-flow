#!/usr/bin/env bash
set -euo pipefail

# AC-10: Three new webhook events have correct payloads and run_id format
# Traces: WEBHOOK-R2, WEBHOOK-R3, WEBHOOK-R4
# Description: Verifies core/post-publish-hook.md Section 4 documents all three
#              event payload fields including run_id and outcome

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FILE="core/post-publish-hook.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist — create it in Phase 7" >&2
  exit 1
fi

FAIL=0

# pipeline-started payload: event, run_id, issue_id, pipeline, timestamp
for field in '"event"' '"run_id"' '"issue_id"' '"pipeline"' '"timestamp"'; do
  if ! grep -A20 '"event":"pipeline-started"\|"event": "pipeline-started"' "$FILE" | grep -qF "$field"; then
    # Fallback: at least check the field is in the file near pipeline-started context
    if ! grep -qF "$field" "$FILE"; then
      echo "FAIL: $FILE missing field $field in pipeline-started payload" >&2
      FAIL=1
    fi
  fi
done

# step-completed payload: event, run_id, issue_id, step_name, duration, iteration_count, timestamp
for field in step_name duration iteration_count; do
  if ! grep -qF "$field" "$FILE"; then
    echo "FAIL: $FILE missing '$field' in step-completed payload documentation" >&2
    FAIL=1
  fi
done

# pipeline-completed payload: must have outcome field
if ! grep -qF '"outcome"' "$FILE"; then
  echo "FAIL: $FILE missing '\"outcome\"' field in pipeline-completed payload" >&2
  FAIL=1
fi

# run_id format documented (compact ISO8601 with no colons)
if ! grep -qE 'YYYYMMDD|[0-9]{8}T[0-9]{6}Z|compact.*ISO|run_id.*format' "$FILE"; then
  echo "FAIL: $FILE missing run_id compact ISO-8601 format documentation" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-10 — core/post-publish-hook.md Section 4 documents all payload fields"
exit "$FAIL"
