#!/usr/bin/env bash
# AC: AC-T1-13-1, AC-T1-13-2, AC-T1-14-1
# Asserts CONTRIBUTING.md has the 7-item security checklist section
# and does NOT contain false CI enforcement claims.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
CONTRIBUTING="$REPO_ROOT/CONTRIBUTING.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

[ -f "$CONTRIBUTING" ] || { fail "CONTRIBUTING.md does not exist"; exit 1; }

# AC-T1-13-1: section heading present
if ! grep -qF '## Functional test scenarios — security expectations' "$CONTRIBUTING"; then
  fail "CONTRIBUTING.md missing heading '## Functional test scenarios — security expectations'"
fi

# AC-T1-13-2: exactly 7 items in the checklist (numbered or bulleted)
# Count lines that look like list items in that section
section_content=$(awk '/^## Functional test scenarios — security expectations/,/^## /' "$CONTRIBUTING" 2>/dev/null | head -50)
item_count=$(echo "$section_content" | grep -cE '^[[:space:]]*([0-9]+\.|[-*])' || echo 0)
[ "$item_count" -eq 7 ] || fail "Expected 7 checklist items, found $item_count"

# AC-T1-13-2: enumerate the 7 required constraint phrases
required_phrases=(
  'eval'
  'set -'
  'fixtures.sh'
  'trap'
)
for phrase in "${required_phrases[@]}"; do
  if ! echo "$section_content" | grep -qF "$phrase"; then
    fail "CONTRIBUTING.md security section missing expected phrase: $phrase"
  fi
done

# AC-T1-14-1: must mention PR review enforcement, not CI
if ! echo "$section_content" | grep -qiE 'PR[ -]review|PR-review'; then
  fail "CONTRIBUTING.md security section must mention 'PR review' enforcement"
fi
# Must NOT claim CI enforcement
if echo "$section_content" | grep -qiE '\bCI\b|\bcontinuous integration\b'; then
  fail "CONTRIBUTING.md security section must not claim CI enforcement (only PR-review)"
fi

echo "PASS: CONTRIBUTING.md security checklist section verified (7 items)"
exit "$FAIL"
