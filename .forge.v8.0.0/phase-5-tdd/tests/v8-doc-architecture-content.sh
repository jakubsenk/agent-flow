#!/usr/bin/env bash
# Verifies: AC-DOC-008, REQ-DOC-008
# Description: docs/architecture.md has "18 agents", "29 skills", named-phase identifiers,
#   and step-count annotations for all 3 pipelines
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

ARCH_DOC="$REPO_ROOT/docs/architecture.md"
if [ ! -f "$ARCH_DOC" ]; then
  fail "docs/architecture.md not found"
  exit 1
fi

# ---------------------------------------------------------------------------
# Assertion 1: "18 agents" and "29 skills" present
# ---------------------------------------------------------------------------
echo "--- Assertion 1: '18 agents' and '29 skills' in architecture.md ---"
if grep -qF '18 agents' "$ARCH_DOC"; then
  echo "OK: architecture.md contains '18 agents'"
else
  fail "architecture.md missing '18 agents'"
fi

if grep -qF '29 skills' "$ARCH_DOC"; then
  echo "OK: architecture.md contains '29 skills'"
else
  fail "architecture.md missing '29 skills'"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Named-phase identifiers in diagram
# ---------------------------------------------------------------------------
echo "--- Assertion 2: named-phase identifiers in architecture.md ---"
NAMED_PHASES=(analyst-triage analyst-impact browser-agent-reproduce browser-agent-verify)
for phase in "${NAMED_PHASES[@]}"; do
  if grep -qF "$phase" "$ARCH_DOC"; then
    echo "OK: '$phase' identifier present"
  else
    fail "architecture.md missing named-phase identifier '$phase'"
  fi
done

# ---------------------------------------------------------------------------
# Assertion 3: Step-count annotations (regex-tolerant per AC-DOC-008)
# ---------------------------------------------------------------------------
echo "--- Assertion 3: step-count annotations for all 3 pipelines ---"
# fix-bugs: 7 steps
if grep -qiE 'fix-bugs[[:space:]:(]+7[[:space:]]*steps|fix-bugs.*7 steps' "$ARCH_DOC"; then
  echo "OK: fix-bugs 7 steps annotation"
else
  fail "architecture.md missing 'fix-bugs: 7 steps' annotation"
fi

# implement-feature: 7 steps
if grep -qiE 'implement-feature[[:space:]:(]+7[[:space:]]*steps|implement-feature.*7 steps' "$ARCH_DOC"; then
  echo "OK: implement-feature 7 steps annotation"
else
  fail "architecture.md missing 'implement-feature: 7 steps' annotation"
fi

# scaffold: 8 steps
if grep -qiE 'scaffold[[:space:]:(]+8[[:space:]]*steps|scaffold.*8 steps' "$ARCH_DOC"; then
  echo "OK: scaffold 8 steps annotation"
else
  fail "architecture.md missing 'scaffold: 8 steps' annotation"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-DOC-008 — architecture.md counts, phase identifiers, step annotations correct"
fi
exit "$FAIL"
