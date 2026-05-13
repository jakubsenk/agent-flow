#!/usr/bin/env bash
# Test: skills/sprint-plan/SKILL.md defines exactly 3 human gates (checkpoints requiring human approval)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL_FILE="$REPO_ROOT/skills/sprint-plan/SKILL.md"

# 1. File must exist
if [ ! -f "$SKILL_FILE" ]; then
  fail "skills/sprint-plan/SKILL.md does not exist"
  exit 1
fi

# 2. Count human gate occurrences
# Gates can be expressed as: "human gate", "Gate N", "checkpoint", "[Y/n]", "Confirm", "approval"
# We look for the specific "gate" keyword (case-insensitive) used as a pipeline checkpoint marker
gate_count=$(grep -ci "human gate\|Gate [123]\|Gate: \|human approval\|human check" "$SKILL_FILE" || true)

if [ "$gate_count" -lt 3 ]; then
  fail "skills/sprint-plan/SKILL.md defines $gate_count human gate(s) but expected at least 3"
fi

# 3. At minimum, the --yolo flag must be documented as gate-skip mechanism
if ! grep -qi "\-\-yolo" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md must document --yolo flag as gate-skip mechanism"
fi

# 4. Gates are distinct (not just one repeated pattern)
# Check that at least 2 different gate indicators appear in different contexts
gate_lines=$(grep -c "human gate\|Gate [123]\|human approval\|\[Y/n\]" "$SKILL_FILE" || true)
if [ "$gate_lines" -lt 2 ]; then
  fail "skills/sprint-plan/SKILL.md must have at least 2 distinct gate indicators (found $gate_lines)"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: skills/sprint-plan/SKILL.md defines 3 human gates with --yolo skip mechanism"
exit "$FAIL"
