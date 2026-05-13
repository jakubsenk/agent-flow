#!/usr/bin/env bash
# Test: All 4 pipeline commands reference at least 3 core files after refactor
# Validates: AC-4.5 — fix-ticket, fix-bugs, implement-feature, scaffold each reference ≥3 core files
# PR 2-3: Core extraction and extension
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

PIPELINE_CMDS=(fix-ticket fix-bugs implement-feature scaffold)

for cmd in "${PIPELINE_CMDS[@]}"; do
  file="$REPO_ROOT/commands/$cmd.md"
  if [ ! -f "$file" ]; then
    fail "Missing pipeline command file: commands/$cmd.md"
    continue
  fi

  count=$(grep -c "core/" "$file" 2>/dev/null || echo 0)
  if [ "$count" -lt 3 ]; then
    fail "commands/$cmd.md references $count core/ file(s), expected at least 3"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: All 4 pipeline commands reference at least 3 core files"
exit "$FAIL"
