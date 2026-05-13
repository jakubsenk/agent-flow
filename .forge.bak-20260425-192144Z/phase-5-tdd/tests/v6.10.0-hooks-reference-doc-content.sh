#!/usr/bin/env bash
# AC: AC-T2-12-1
# Asserts docs/reference/hooks.md exists and contains all 6 required items.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
HOOKS_DOC="$REPO_ROOT/docs/reference/hooks.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

[ -f "$HOOKS_DOC" ] || { fail "docs/reference/hooks.md does not exist"; exit 1; }

# AC-T2-12-1: all 6 required items present
required_patterns=(
  'STAGES'           # STAGES whitelist
  'dispatched_at'    # dispatched_at schema
  'exit'             # exit code semantics
  'dispatch-audit'   # log format
  'settings.json'    # installation stanza
  'extensib\|extend\|future\|v6\.1[0-9]'  # extensibility note
)
for pattern in "${required_patterns[@]}"; do
  if ! grep -qiE "$pattern" "$HOOKS_DOC"; then
    fail "docs/reference/hooks.md missing required content for pattern: $pattern"
  fi
done

# Mutation guard: the file must be substantial (not an empty stub)
line_count=$(wc -l < "$HOOKS_DOC" | tr -d ' ')
[ "$line_count" -ge 20 ] || fail "docs/reference/hooks.md too short ($line_count lines); expected >= 20"

echo "PASS: docs/reference/hooks.md content verified"
exit "$FAIL"
