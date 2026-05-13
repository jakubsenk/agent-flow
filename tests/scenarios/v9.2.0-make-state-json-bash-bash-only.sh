#!/usr/bin/env bash
# v9.2.0 — make_state_json_bash contains zero jq/python/node/perl/awk calls
# Fulfils: AC-V902-TST-12
#
# RED now because:
#   make_state_json_bash function does not exist in tests/lib/fixtures.sh yet.
#   The test fails at the declare -F guard with "FAIL: make_state_json_bash not declared".
#
# GREEN after Phase 7 adds make_state_json_bash to tests/lib/fixtures.sh with
#   a pure-bash implementation (no external interpreter calls).
#
# Assertion strategy:
#   1. declare -F make_state_json_bash — function must exist (RED guard)
#   2. Extract the function body from tests/lib/fixtures.sh using sed
#   3. grep for forbidden interpreter calls (\bjq\b|\bpython\b|\bnode\b|\bperl\b|\bawk\b)
#   4. Assert zero matches
#
# NOTE: SCRIPT_DIR/../.. from .forge/phase-5-tdd/scenarios/ resolves two levels up to repo root.
# After Phase 7 copies this file to tests/scenarios/, SCRIPT_DIR/../.. also resolves to repo root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# Fallback for running from forge staging (.forge/phase-5-tdd/scenarios/ is 3 levels below repo root)
[ -f "$REPO_ROOT/tests/lib/fixtures.sh" ] || REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

SCRATCH="$(setup_scratch)"
trap "rm -rf '$SCRATCH'" EXIT

FIXTURES_SH="$REPO_ROOT/tests/lib/fixtures.sh"

# ---------------------------------------------------------------------------
# Gate: make_state_json_bash must be declared (RED guard — fails until Phase 7)
# ---------------------------------------------------------------------------
declare -F make_state_json_bash >/dev/null 2>&1 || {
  echo "FAIL: make_state_json_bash not declared in tests/lib/fixtures.sh — Phase 7 has not added it yet" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Extract the function body from fixtures.sh between "make_state_json_bash() {"
# and the matching closing "}" at the same indentation level.
# We use awk to capture all lines from the function start to the first
# closing "^}" (line starting with } at column 0).
# ---------------------------------------------------------------------------
FUNC_BODY="$SCRATCH/make_state_json_bash_body.sh"

awk '/^make_state_json_bash\(\)[ ]*\{/,/^\}/' "$FIXTURES_SH" > "$FUNC_BODY"

if [ ! -s "$FUNC_BODY" ]; then
  echo "FAIL: AC-V902-TST-12 — could not extract make_state_json_bash function body from $FIXTURES_SH" >&2
  exit 1
fi

echo "Extracted function body ($(wc -l < "$FUNC_BODY") lines):"
cat "$FUNC_BODY"
echo "---"

# ---------------------------------------------------------------------------
# Grep for forbidden external interpreter calls within the function body
# Pattern: word-boundary \b matches: jq, python, python3, node, nodejs, perl, awk, ruby
# Also check for 'command -v jq' style checks that indicate jq is used
# ---------------------------------------------------------------------------
FORBIDDEN_PATTERN='\b(jq|python[0-9]?|node(js)?|perl|awk|ruby)\b'

MATCHES=$(grep -E "$FORBIDDEN_PATTERN" "$FUNC_BODY" || true)

if [ -n "$MATCHES" ]; then
  echo "FAIL: AC-V902-TST-12 — make_state_json_bash contains forbidden external interpreter calls:" >&2
  echo "$MATCHES" >&2
  exit 1
fi

echo "PASS: AC-V902-TST-12 — make_state_json_bash contains zero forbidden external interpreter calls"
echo "PASS: v9.2.0-make-state-json-bash-bash-only — bash-only implementation verified"
exit 0
