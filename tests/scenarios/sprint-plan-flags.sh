#!/usr/bin/env bash
# Test: skills/sprint-plan/SKILL.md documents all required CLI flags
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL_FILE="$REPO_ROOT/skills/sprint-plan/SKILL.md"

# 1. File must exist
if [ ! -f "$SKILL_FILE" ]; then
  fail "skills/sprint-plan/SKILL.md does not exist"
  exit 1
fi

# 2. Documents --all flag (include all unassigned issues)
if ! grep -qi "\-\-all\b" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md missing --all flag documentation"
fi

# 3. Documents --apply flag (write assignments to tracker)
if ! grep -qi "\-\-apply" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md missing --apply flag documentation"
fi

# 4. Documents --dry-run flag
if ! grep -qi "\-\-dry-run\|--dry.run" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md missing --dry-run flag documentation"
fi

# 5. Documents --yolo flag (skip human gates, auto-apply)
if ! grep -qi "\-\-yolo" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md missing --yolo flag documentation"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: skills/sprint-plan/SKILL.md documents all required flags: --all, --apply, --dry-run, --yolo"
exit "$FAIL"
