#!/usr/bin/env bash
set -euo pipefail

# AC-33: No step-skipped webhook emission site exists in pipeline skills or core
# Traces: WEBHOOK-R7
# Description: Verifies 'step-skipped' does not appear in pipeline SKILL.md files or post-publish-hook

# NOTE: This test checks negative absence — passes green before Phase 7 IF no such string exists.
# Must remain green after Phase 7 (NOT_IN_SCOPE per requirements.md Section 6).

cd "$(dirname "$0")/../../.."

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
    continue  # file may not exist yet; skip
  fi
  if grep -qF 'step-skipped' "$f"; then
    echo "FAIL: AC-33 — '$f' contains 'step-skipped' (must be absent per WEBHOOK-R7)" >&2
    FAIL=1
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: AC-33 — no step-skipped event emission site found in pipeline skills/core"
exit "$FAIL"
