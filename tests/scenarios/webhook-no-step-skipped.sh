#!/usr/bin/env bash
set -euo pipefail

# AC-33: No step-skipped webhook emission site in pipeline skills or core
# Traces: WEBHOOK-R7
# Description: Verifies 'step-skipped' is absent from all pipeline SKILL.md files and core hook

# NOTE: Negative absence test. Passes green pre-Phase 7 if no such text exists.

cd "$(dirname "$0")/../.."

FAIL=0

FILES=(
  "skills/fix-ticket/SKILL.md"
  "skills/fix-bugs/SKILL.md"
  "skills/implement-feature/SKILL.md"
  "skills/scaffold/SKILL.md"
  "core/post-publish-hook.md"
)

for f in "${FILES[@]}"; do
  if [ ! -f "$f" ]; then
    continue
  fi
  if grep -qF 'step-skipped' "$f"; then
    echo "FAIL: '$f' contains 'step-skipped' event (must be absent per WEBHOOK-R7)" >&2
    FAIL=1
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: webhook-no-step-skipped — 'step-skipped' absent from all checked files"
exit "$FAIL"
