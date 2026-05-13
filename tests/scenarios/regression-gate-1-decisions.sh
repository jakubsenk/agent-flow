#!/usr/bin/env bash
set -euo pipefail

# REGRESSION: Gate 1 decisions preserved in implementation
# Traces: requirements.md Section 7 (Gate 1 Ledger)
# Description: Verifies the 5 critical Gate 1 decisions are implemented correctly:
#   1. tokens_used (not tokens_estimated) in schema
#   2. schema_version stays "1.0" (not "1.1")
#   3. No new core/pipeline-events.md (extend post-publish-hook.md instead)
#   4. mkdir (not PowerShell) for lock mechanism
#   5. No step-skipped event

cd "$(dirname "$0")/../.."

FAIL=0

# Decision 1: tokens_used (not tokens_estimated) in schema
SCHEMA="state/schema.md"
if [ -f "$SCHEMA" ]; then
  if ! grep -qF 'tokens_used' "$SCHEMA"; then
    echo "FAIL: Gate1-D1: state/schema.md missing 'tokens_used' field (must use tokens_used not tokens_estimated)" >&2
    FAIL=1
  fi
  if grep -qF 'tokens_estimated' "$SCHEMA"; then
    echo "FAIL: Gate1-D1: state/schema.md contains 'tokens_estimated' — Gate 1 chose 'tokens_used'" >&2
    FAIL=1
  fi
fi

# Decision 2: schema_version stays "1.0"
if [ -f "$SCHEMA" ]; then
  if grep -qF '"1.1"' "$SCHEMA"; then
    echo "FAIL: Gate1-D2: state/schema.md has '1.1' schema_version — must stay '1.0'" >&2
    FAIL=1
  fi
fi

# Decision 3: No new core/pipeline-events.md file (extend post-publish-hook.md)
if [ -f "core/pipeline-events.md" ]; then
  echo "FAIL: Gate1-D4: core/pipeline-events.md exists — Gate 1 decided to EXTEND post-publish-hook.md instead" >&2
  FAIL=1
fi

# Decision 4: mkdir for lock (not PowerShell CreateNew)
AUTOPILOT="skills/autopilot/SKILL.md"
if [ -f "$AUTOPILOT" ]; then
  if grep -qiE 'CreateNew|New-Item.*Lock|PowerShell.*lock' "$AUTOPILOT"; then
    echo "FAIL: Gate1-D8: $AUTOPILOT uses PowerShell lock mechanism — Gate 1 chose mkdir-based bash" >&2
    FAIL=1
  fi
fi

# Decision 5: No step-skipped event (validated at runtime scope)
FILES=(
  "skills/fix-ticket/SKILL.md"
  "skills/fix-bugs/SKILL.md"
  "skills/implement-feature/SKILL.md"
  "core/post-publish-hook.md"
)
for f in "${FILES[@]}"; do
  if [ -f "$f" ] && grep -qF 'step-skipped' "$f"; then
    echo "FAIL: Gate1-NOT_IN_SCOPE: '$f' emits 'step-skipped' — this event is NOT_IN_SCOPE (§6.1)" >&2
    FAIL=1
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: REGRESSION — all 5 Gate 1 decisions preserved in implementation"
exit "$FAIL"
