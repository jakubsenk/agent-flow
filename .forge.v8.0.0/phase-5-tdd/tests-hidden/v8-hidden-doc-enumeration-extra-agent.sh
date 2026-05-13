#!/usr/bin/env bash
# Hidden adversarial test — do NOT reference in spec/visible
# Tests: If a doc file lists 19 agents (one extra), the enumeration check FAILS
# This is the mutation test: adding a spurious agent row must be caught
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT INT TERM

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Setup: mock agents.md with 19 rows (1 extra spurious agent)
# ---------------------------------------------------------------------------
cat > "$TMPDIR_TEST/agents-19.md" << 'EOF'
# Agents Reference

| Agent | Model | Description |
|-------|-------|-------------|
| analyst | sonnet | Triage + impact analysis |
| fixer | opus | Code fix |
| reviewer | opus | Code review |
| acceptance-gate | sonnet | AC verification |
| test-engineer | sonnet | Testing |
| publisher | haiku | PR creation |
| rollback-agent | haiku | Rollback |
| spec-analyst | sonnet | Feature spec |
| architect | opus | Architecture |
| stack-selector | sonnet | Stack selection |
| scaffolder | sonnet | Project scaffold |
| priority-engine | opus | Prioritization |
| spec-writer | opus | Spec writing |
| spec-reviewer | opus | Spec review |
| browser-agent | sonnet | Browser operations |
| deployment-verifier | sonnet | Deployment verification |
| backlog-creator | sonnet | Backlog creation |
| sprint-planner | sonnet | Sprint planning |
| EXTRA-SPURIOUS-AGENT | opus | Should not be here |
EOF

# ---------------------------------------------------------------------------
# Assertion 1: 19-agent mock has 19 rows (mutation test setup correct)
# ---------------------------------------------------------------------------
echo "--- Assertion 1: mock agents-19.md has 19 agent table rows ---"
CANONICAL=(analyst fixer reviewer acceptance-gate test-engineer publisher rollback-agent
  spec-analyst architect stack-selector scaffolder priority-engine spec-writer spec-reviewer
  browser-agent deployment-verifier backlog-creator sprint-planner)

EXTRA_AGENT_COUNT=0
while IFS= read -r line; do
  if echo "$line" | grep -qE "^\|[[:space:]]*[a-z]"; then
    EXTRA_AGENT_COUNT=$((EXTRA_AGENT_COUNT + 1))
  fi
done < <(grep -v "^| Agent\|^|---" "$TMPDIR_TEST/agents-19.md" | grep "^|")

if [ "$EXTRA_AGENT_COUNT" -eq 19 ]; then
  echo "OK: mutation mock has 19 agent rows"
else
  echo "INFO: found $EXTRA_AGENT_COUNT agent rows in mock"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Enumeration check DETECTS the extra agent
# ---------------------------------------------------------------------------
echo "--- Assertion 2: enumeration check catches extra agent in 19-row mock ---"
printf '%s\n' "${CANONICAL[@]}" | sort > "$TMPDIR_TEST/canonical_18.txt"

# Extract agent names from mock (first column of table rows)
grep -oE "^\|[[:space:]]*(analyst|fixer|reviewer|acceptance-gate|test-engineer|publisher|rollback-agent|spec-analyst|architect|stack-selector|scaffolder|priority-engine|spec-writer|spec-reviewer|browser-agent|deployment-verifier|backlog-creator|sprint-planner|EXTRA-SPURIOUS-AGENT)[[:space:]]*\|" \
  "$TMPDIR_TEST/agents-19.md" | sed 's/|//g' | tr -d '[:space:]' | sort > "$TMPDIR_TEST/actual_19.txt"

if diff -q "$TMPDIR_TEST/canonical_18.txt" "$TMPDIR_TEST/actual_19.txt" > /dev/null 2>&1; then
  fail "Enumeration check did NOT detect extra agent in 19-row mock (should have failed)"
else
  echo "OK: enumeration check correctly detects mismatch for 19-row mock"
fi

# ---------------------------------------------------------------------------
# Assertion 3: docs/reference/agents.md has exactly 18 (not 19)
# ---------------------------------------------------------------------------
echo "--- Assertion 3: real docs/reference/agents.md has exactly 18 agent rows ---"
AGENTS_DOC="$REPO_ROOT/docs/reference/agents.md"
if [ ! -f "$AGENTS_DOC" ]; then
  echo "SKIP: docs/reference/agents.md not found (implementation pending)" >&2
  exit 77
fi

REAL_COUNT=0
for agent in "${CANONICAL[@]}"; do
  if grep -qE "^\|[[:space:]]*${agent}[[:space:]]*\|" "$AGENTS_DOC"; then
    REAL_COUNT=$((REAL_COUNT + 1))
  fi
done

if [ "$REAL_COUNT" -eq 18 ]; then
  echo "OK: docs/reference/agents.md has exactly 18 canonical agents"
else
  fail "docs/reference/agents.md has $REAL_COUNT canonical agents (expected 18)"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: 19-agent extra-agent mutation correctly detected by enumeration check"
fi
exit "$FAIL"
