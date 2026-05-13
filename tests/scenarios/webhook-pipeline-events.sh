#!/usr/bin/env bash
set -euo pipefail

# AC-10: Three new webhook events fire with correct payloads and compact run_id format
# Traces: WEBHOOK-R2, WEBHOOK-R3, WEBHOOK-R4
# Description: Verifies core/post-publish-hook.md Section 4 documents all three events
#              with correct payload fields and run_id compact format
#
# NOTE: This is a STRUCTURAL test (no live HTTP listener required).
# Payload capture verification would require Claude CLI integration.
# Runtime verification is out of scope for CI (design.md §3.7 intent preserved).

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FILE="core/post-publish-hook.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist — create it in Phase 7" >&2
  exit 1
fi

FAIL=0

# All three event names must be documented
for event in pipeline-started step-completed pipeline-completed; do
  if ! grep -qF "\"$event\"" "$FILE"; then
    echo "FAIL: $FILE missing '\"$event\"' event documentation" >&2
    FAIL=1
  fi
done

# pipeline-started payload: run_id, issue_id, pipeline, timestamp
for field in run_id issue_id pipeline timestamp; do
  if ! grep -qF "\"$field\"" "$FILE"; then
    echo "FAIL: $FILE missing '\"$field\"' payload field" >&2
    FAIL=1
  fi
done

# step-completed payload: step_name, duration, iteration_count
for field in step_name duration iteration_count; do
  if ! grep -qF "\"$field\"" "$FILE"; then
    echo "FAIL: $FILE missing '\"$field\"' in step-completed payload" >&2
    FAIL=1
  fi
done

# pipeline-completed: outcome field
if ! grep -qF '"outcome"' "$FILE"; then
  echo "FAIL: $FILE missing '\"outcome\"' field in pipeline-completed payload" >&2
  FAIL=1
fi

# run_id compact format (no colons, YYYYMMDDTHHMMSSZ)
if ! grep -qE 'YYYYMMDD|[0-9]{8}T[0-9]{6}Z|compact.*ISO|no colons' "$FILE"; then
  echo "FAIL: $FILE missing compact run_id format documentation (no colons, YYYYMMDDTHHMMSSZ)" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: webhook-pipeline-events — post-publish-hook.md documents all 3 events + payloads"
exit "$FAIL"
