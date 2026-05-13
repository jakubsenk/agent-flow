#!/usr/bin/env bash
# Test: core/tracker-subtask-creator.md exists with required structure
# AC-1: Core contract has Purpose/Input Contract/Process/Output Contract/Failure Handling sections,
#        Per-Tracker table, and Issue Description Template
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

FILE="$REPO_ROOT/core/tracker-subtask-creator.md"

# File must exist
if [ ! -f "$FILE" ]; then
  fail "core/tracker-subtask-creator.md does not exist — must be created as 15th core contract"
  exit 1
fi

# ---------------------------------------------------------------------------
# Required section headings — must all be present
# ---------------------------------------------------------------------------

for section in "## Purpose" "## Input Contract" "## Process" "## Output Contract" "## Failure Handling"; do
  if ! grep -q "^${section}$" "$FILE"; then
    fail "core/tracker-subtask-creator.md: required section '${section}' missing"
  fi
done

# ---------------------------------------------------------------------------
# Section order: Purpose < Input Contract < Process < Output Contract < Failure Handling
# ---------------------------------------------------------------------------

PURPOSE_LINE=$(grep -n "^## Purpose$" "$FILE" | head -1 | cut -d: -f1)
INPUT_LINE=$(grep -n "^## Input Contract$" "$FILE" | head -1 | cut -d: -f1)
PROCESS_LINE=$(grep -n "^## Process$" "$FILE" | head -1 | cut -d: -f1)
OUTPUT_LINE=$(grep -n "^## Output Contract$" "$FILE" | head -1 | cut -d: -f1)
FAILURE_LINE=$(grep -n "^## Failure Handling$" "$FILE" | head -1 | cut -d: -f1)

if [ -n "$PURPOSE_LINE" ] && [ -n "$INPUT_LINE" ] && [ "$PURPOSE_LINE" -ge "$INPUT_LINE" ]; then
  fail "core/tracker-subtask-creator.md: '## Purpose' must appear before '## Input Contract'"
fi
if [ -n "$INPUT_LINE" ] && [ -n "$PROCESS_LINE" ] && [ "$INPUT_LINE" -ge "$PROCESS_LINE" ]; then
  fail "core/tracker-subtask-creator.md: '## Input Contract' must appear before '## Process'"
fi
if [ -n "$PROCESS_LINE" ] && [ -n "$OUTPUT_LINE" ] && [ "$PROCESS_LINE" -ge "$OUTPUT_LINE" ]; then
  fail "core/tracker-subtask-creator.md: '## Process' must appear before '## Output Contract'"
fi
if [ -n "$OUTPUT_LINE" ] && [ -n "$FAILURE_LINE" ] && [ "$OUTPUT_LINE" -ge "$FAILURE_LINE" ]; then
  fail "core/tracker-subtask-creator.md: '## Output Contract' must appear before '## Failure Handling'"
fi

# ---------------------------------------------------------------------------
# Per-Tracker table must exist (covers 6 tracker types)
# ---------------------------------------------------------------------------

if ! grep -qi "per.tracker\|per tracker" "$FILE"; then
  fail "core/tracker-subtask-creator.md: Per-Tracker table heading missing"
fi

# ---------------------------------------------------------------------------
# Issue Description Template must exist
# ---------------------------------------------------------------------------

if ! grep -qi "issue description template" "$FILE"; then
  fail "core/tracker-subtask-creator.md: 'Issue Description Template' section missing"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: core/tracker-subtask-creator.md exists with correct section structure (Purpose/Input Contract/Process/Output Contract/Failure Handling), Per-Tracker table, and Issue Description Template"
exit "$FAIL"
