#!/usr/bin/env bash
# AC: AC-T2-13-1
# Asserts docs/guides/dispatch-enforcement.md exists and contains all 6 required items.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
GUIDE="$REPO_ROOT/docs/guides/dispatch-enforcement.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

[ -f "$GUIDE" ] || { fail "docs/guides/dispatch-enforcement.md does not exist"; exit 1; }

# AC-T2-13-1: all 6 required documentation items
checks=(
  'what it does:validates\|audits\|tracks\|dispatch'
  '3-layer\|three.layer\|Layer 1\|Layer 2'
  'installation\|install'
  'troubleshoot\|debug\|diagnose'
  'advisory\|exit 0\|non-blocking'
  'Autopilot.*limitation\|limitation.*Autopilot'
)
for check in "${checks[@]}"; do
  if ! grep -qiE "$check" "$GUIDE"; then
    fail "docs/guides/dispatch-enforcement.md missing required section matching: $check"
  fi
done

# Mutation guard: file must be substantial
line_count=$(wc -l < "$GUIDE" | tr -d ' ')
[ "$line_count" -ge 30 ] || fail "dispatch-enforcement.md too short ($line_count lines); expected >= 30"

echo "PASS: docs/guides/dispatch-enforcement.md content verified"
exit "$FAIL"
