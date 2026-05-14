#!/usr/bin/env bash
set -euo pipefail

# AC-38: Task-tool usage-field discovery test exists, emits DISCOVERED_FIELD, asserts known field-name set
# Traces: COST-R12
# Description: This test VERIFIES that the discovery test file exists and contains the required
#              structural elements: result.usage reference, DISCOVERED_FIELD= emission,
#              and the known field-name allowlist.
#
# NOTE: The actual discovery test at tests/scenarios/cost-task-tool-usage-field-discovery.sh
# requires a live Claude CLI to run. THIS test only verifies the file's structural correctness
# (no network dependency) — the live dispatch test is in the scenario file itself.

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

DISCOVERY="tests/scenarios/cost-task-tool-usage-field-discovery.sh"

# File must exist (AC-38 first check)
if [ ! -f "$DISCOVERY" ]; then
  echo "FAIL: $DISCOVERY does not exist — create it in Phase 7 (AC-38, COST-R12)" >&2
  exit 1
fi

FAIL=0

# Must reference result.usage (the Task-tool response field)
if ! grep -qF 'result.usage' "$DISCOVERY"; then
  echo "FAIL: $DISCOVERY does not reference 'result.usage'" >&2
  FAIL=1
fi

# Must emit DISCOVERED_FIELD= structured summary line
if ! grep -qE 'DISCOVERED_FIELD=' "$DISCOVERY"; then
  echo "FAIL: $DISCOVERY does not emit 'DISCOVERED_FIELD=...' structured summary" >&2
  FAIL=1
fi

# Must check against the known field-name allowlist
if ! grep -qE 'total_tokens|input_tokens\+output_tokens|tokens_estimated' "$DISCOVERY"; then
  echo "FAIL: $DISCOVERY missing the known token-field allowlist check" >&2
  FAIL=1
fi

# Must exit non-zero on unknown/absent field (negative case documented)
if ! grep -qiE 'UNKNOWN|ABSENT' "$DISCOVERY"; then
  echo "FAIL: $DISCOVERY does not handle UNKNOWN/ABSENT field case" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-38 — cost-task-tool-usage-field-discovery.sh exists with required structure"
exit "$FAIL"
