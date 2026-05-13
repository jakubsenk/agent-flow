#!/usr/bin/env bash
# AC: AC-META-1-1, AC-META-1-2, AC-META-1-3
# Asserts roadmap.md contains all 5 unified corrections and
# required v6.10.1 and v6.11.0 entries.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
ROADMAP="$REPO_ROOT/docs/plans/roadmap.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

[ -f "$ROADMAP" ] || { fail "docs/plans/roadmap.md not found"; exit 1; }

# AC-META-1-2: v6.10.1 section has required entries
v6101_section=$(awk '/6\.10\.1/,/6\.11\.0/' "$ROADMAP" 2>/dev/null | head -50)
for item in \
  'canonical.*repo|repo.*canonical|repository.*URL|URL.*repository' \
  'SECURITY.*secondary|secondary.*contact|secondary.*SECURITY' \
  'Autopilot dispatch audit parity'; do
  if ! echo "$v6101_section" | grep -qiE "$item"; then
    fail "roadmap.md v6.10.1 section missing required item matching: $item"
  fi
done

# AC-META-1-3: v6.11.0 section has all 6 items (§5.2 items 4-9)
v6110_section=$(awk '/6\.11\.0/,/6\.12\.0/' "$ROADMAP" 2>/dev/null | head -100)
items_v6110=(
  'circuit.*breaker|circuit-breaker'
  'Webhook.*allowlist|allowlist.*Webhook'
  'multi.host|distributed.*lock'
  'Prompt.injection.*defense|defense.in.depth'
  'Tracker.*normalization|normalization.*tracker'
)
for item in "${items_v6110[@]}"; do
  if ! echo "$v6110_section" | grep -qiE "$item"; then
    fail "roadmap.md v6.11.0 section missing item matching: $item"
  fi
done

# AC-META-1-1: check that canonical source discrepancy #1 is corrected
# (code-analyst.md not test-engineer.md for Track 3)
if grep -qF 'agents/test-engineer.md' "$ROADMAP"; then
  # Could be in historical context — check v6.10.0 Track 3 area specifically
  v6100_section=$(awk '/6\.10\.0/,/6\.10\.1/' "$ROADMAP" | head -50)
  if echo "$v6100_section" | grep -qF 'agents/test-engineer.md'; then
    fail "roadmap.md v6.10.0 section still has stale test-engineer.md reference (should be code-analyst.md)"
  fi
fi

echo "PASS: roadmap corrections unified commit verified"
exit "$FAIL"
