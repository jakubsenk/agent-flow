#!/usr/bin/env bash
# AC: AC-T3-1-1, AC-T3-1-2
# Asserts roadmap.md has canonical-source correction:
# code-analyst.md cited instead of test-engineer.md for Track 3.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
ROADMAP="$REPO_ROOT/docs/plans/roadmap.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

[ -f "$ROADMAP" ] || { fail "docs/plans/roadmap.md not found"; exit 1; }

# AC-T3-1-1: test-engineer.md NOT cited in v6.10.0 Track 3 context
# Extract v6.10.0 section
v6100_section=$(awk '/6\.10\.0/,/6\.11\.0/' "$ROADMAP" 2>/dev/null | head -100)
if echo "$v6100_section" | grep -qF 'agents/test-engineer.md'; then
  fail "roadmap.md v6.10.0 section still references agents/test-engineer.md as canonical source (must be code-analyst.md)"
fi

# AC-T3-1-2: code-analyst.md IS cited in v6.10.0 context
if ! grep -qF 'agents/code-analyst.md' "$ROADMAP"; then
  fail "roadmap.md missing agents/code-analyst.md reference"
fi
# Must appear in v6.10.0 Track 3 area
if ! echo "$v6100_section" | grep -qF 'agents/code-analyst.md'; then
  fail "agents/code-analyst.md not cited in the v6.10.0 section of roadmap.md"
fi

echo "PASS: roadmap canonical source correction verified"
exit "$FAIL"
