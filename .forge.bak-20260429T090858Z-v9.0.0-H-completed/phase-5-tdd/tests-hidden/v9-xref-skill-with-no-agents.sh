#!/bin/bash
# PURPOSE: (HIDDEN) Adversarial edge case for the xref scenario. A skill file that references
#          output headings should pass (it's allowed to reference headings); an agent that declares
#          a heading that NO skill references should fail. This scenario explicitly tests the
#          direction of the invariant: agent → skill (not skill → agent).
# AC-H-N covered: AC-H-033 (adversarial direction test)
# INVOKED BY: tests/harness/run-tests.sh (hidden)
# EXPECTED ON v8.0.0: PASS (no ## Output Contract declarations → 0 xrefs checked → trivially passes)
# EXPECTED ON v9.0.0: PASS (every declared heading has ≥1 skill reference)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

AGENTS_DIR="$REPO_ROOT/agents"
SKILLS_DIR="$REPO_ROOT/skills"

# Known headings from the spec (design.md §2) that MUST appear in skills
# This is an adversarial whitelist check: if Phase 7 adds an Output Contract but forgets to
# ensure the heading is in a skill, these specific high-value headings should be caught.
# This tests a stronger assertion than the generic xref loop in the visible scenario.
CRITICAL_HEADINGS=(
  "## Fix Report"
  "## Code Review"
  "## Triage Analysis"
  "## Impact Report"
  "## Test Report"
  "## Publish Report"
  "## Spec Review"
  "## Architecture Design"
)

xref_failed=0
for heading in "${CRITICAL_HEADINGS[@]}"; do
  # Only run this check if at least one agent has ## Output Contract (otherwise trivially pass)
  has_contract=$(find "$AGENTS_DIR" -name "*.md" 2>/dev/null | xargs grep -l '^## Output Contract$' 2>/dev/null | wc -l || true)
  if [ "$has_contract" -eq 0 ]; then
    # No contracts yet — trivially passes (v8.0.0 baseline)
    break
  fi

  found=0
  if grep -rl -F "$heading" "$SKILLS_DIR" --include="*.md" 2>/dev/null | grep -q .; then
    found=1
  fi
  if find "$SKILLS_DIR" -name "*.md" -path "*/steps/*" 2>/dev/null | xargs grep -l -F "$heading" 2>/dev/null | grep -q .; then
    found=1
  fi

  if [ "$found" -eq 0 ]; then
    fail "Critical heading '$heading' is not referenced in any skills/**/*.md — xref invariant violation"
    xref_failed=$((xref_failed + 1))
    # Mutation catch: removing skill grep for a critical heading fails here
  fi
done

# Direction test: verify no skill file is REQUIRED to have ## Output Contract references
# (skills reference agent OUTPUT headings — they don't need to know about Output Contract metadata)
# This is a negative test: no skill should grep for '## Output Contract' as if it were a signal
# (## Output Contract is a metadata section, not a runtime output — REQ-H-001 is author-time only)
output_contract_in_skills=$(grep -rl '^## Output Contract$' "$SKILLS_DIR" --include="*.md" 2>/dev/null | wc -l || true)
if [ "$output_contract_in_skills" -gt 0 ]; then
  fail "Some skill file(s) contain '## Output Contract' heading — this is an author-time-only metadata section; skills should not reference it as a runtime signal"
  # Mutation catch: accidentally adding ## Output Contract to a skill file fails here
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-H-033 (adversarial) — all ${#CRITICAL_HEADINGS[@]} critical agent output headings referenced in skills; no skill incorrectly references ## Output Contract as a runtime signal"
fi
exit "$FAIL"
