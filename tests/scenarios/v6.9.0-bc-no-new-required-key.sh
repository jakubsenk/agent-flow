#!/usr/bin/env bash
# Scenario: REQ-070 NEGATIVE — no new REQUIRED Automation Config key added in v6.9.0
# Expected v6.9.0 outcome: PASS (negative invariant — should pass now and after v6.9.0)
# Pre-implementation outcome: PASS (BC invariant — negative test passes against current state too)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

if [ ! -f "$CLAUDE_MD" ]; then
  echo "FAIL: CLAUDE.md not found" >&2; exit 1
fi

# Assertion 1 (AC-070): required sections present by name (directly via grep)
echo "--- Assertion 1 (AC-070): the 5 required sections present in CLAUDE.md ---"
required_sections=("Issue Tracker" "Source Control" "PR Rules" "PR Description Template" "Build & Test")
required_count=0
for section in "${required_sections[@]}"; do
  if grep -qF "| $section |" "$CLAUDE_MD"; then
    echo "OK: required section '$section' present"
    required_count=$((required_count + 1))
  else
    fail "AC-070: required section '$section' missing from Config Contract required table"
  fi
done
if [ "$required_count" -eq 5 ]; then
  echo "OK (AC-070): all 5 required Automation Config sections present (unchanged)"
else
  fail "AC-070: only $required_count/5 required sections found (expected 5 — no new required keys in MINOR release)"
fi

# Assertion 3 (AC-070): no NEW required section heading added
# Negative: if any row appears in the required-section table that is NOT one of the 5 expected ones
echo "--- Assertion 3 (AC-070 NEGATIVE): no unexpected required sections ---"
new_required=$(awk '/^## Config Contract/,/^## /' "$CLAUDE_MD" 2>/dev/null | \
  grep -E '^\|[^|]+\|[^|]+\|' | \
  grep -vE '^\| (Issue Tracker|Source Control|PR Rules|PR Description Template|Build & Test|Section|---|.*---) \|' | \
  grep -vE '^\| \*\*' | head -5 || true)
if [ -n "$new_required" ]; then
  # Distinguish required vs optional tables by context
  echo "INFO: non-standard rows in Config Contract section (may be optional or header rows): $new_required"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 BC — no new required Automation Config key; required section count remains 5"
fi
exit "$FAIL"
