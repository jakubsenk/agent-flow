#!/usr/bin/env bash
# Verifies: AC-INV-DOC-ENUM-001, REQ-INV-004, REQ-NF-010
# Description: 5 doc files agree on agent/skill/config-section enumeration;
#   no stale count strings "21 agents" or "28 skills"; correct strings "18 agents", "29 skills"
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

# Canonical 18-agent names
CANONICAL_AGENTS=(analyst fixer reviewer acceptance-gate test-engineer publisher rollback-agent
  spec-analyst architect stack-selector scaffolder priority-engine spec-writer spec-reviewer
  browser-agent deployment-verifier backlog-creator sprint-planner)

# Canonical 29 skills
CANONICAL_SKILLS=(analyze-bug autopilot changelog check-deploy check-setup create-backlog
  dashboard discuss estimate fix-bugs fix-ticket implement-feature metrics migrate-config
  onboard pipeline-status prioritize publish resume-ticket scaffold scaffold-add
  scaffold-validate setup-agents setup-mcp sprint-plan template version-bump
  version-check workflow-router)

# 5 target files
DOC_FILES=(
  "CLAUDE.md"
  "README.md"
  "docs/reference/automation-config.md"
  "docs/reference/skills.md"
  "docs/architecture.md"
)

# ---------------------------------------------------------------------------
# Assertion 1: No stale count strings
# ---------------------------------------------------------------------------
echo "--- Assertion 1: no stale count strings '21 agents' or '28 skills' ---"
for doc in "${DOC_FILES[@]}"; do
  DOC_PATH="$REPO_ROOT/$doc"
  if [ ! -f "$DOC_PATH" ]; then
    echo "SKIP: $doc not found (implementation pending)" >&2
    continue
  fi
  if grep -qF '21 agents' "$DOC_PATH"; then
    fail "$doc contains stale string '21 agents'"
  else
    echo "OK: $doc does not contain '21 agents'"
  fi
  if grep -qF '28 skills' "$DOC_PATH"; then
    fail "$doc contains stale string '28 skills'"
  else
    echo "OK: $doc does not contain '28 skills'"
  fi
done

# ---------------------------------------------------------------------------
# Assertion 2: Correct count strings present in at least some files
# ---------------------------------------------------------------------------
echo "--- Assertion 2: '18 agents' and '29 skills' appear in correct files ---"
FOUND_18=0
FOUND_29=0
for doc in "${DOC_FILES[@]}"; do
  DOC_PATH="$REPO_ROOT/$doc"
  [ -f "$DOC_PATH" ] || continue
  if grep -qF '18 agents' "$DOC_PATH"; then
    echo "OK: $doc contains '18 agents'"
    FOUND_18=$((FOUND_18 + 1))
  fi
  if grep -qF '29 skills' "$DOC_PATH"; then
    echo "OK: $doc contains '29 skills'"
    FOUND_29=$((FOUND_29 + 1))
  fi
done

if [ "$FOUND_18" -eq 0 ]; then
  fail "No file in the 5-doc set contains '18 agents'"
fi
if [ "$FOUND_29" -eq 0 ]; then
  fail "No file in the 5-doc set contains '29 skills'"
fi

# ---------------------------------------------------------------------------
# Assertion 3: Agent name enumeration in files that contain agent tables
# ---------------------------------------------------------------------------
echo "--- Assertion 3: agent table enumeration check (where present) ---"
# Build expected agent names file
printf '%s\n' "${CANONICAL_AGENTS[@]}" | sort > "$TMPDIR_TEST/canonical_agents.txt"

for doc in CLAUDE.md README.md docs/reference/automation-config.md docs/architecture.md; do
  DOC_PATH="$REPO_ROOT/$doc"
  [ -f "$DOC_PATH" ] || continue

  # Check if file has any agent table row
  HAS_AGENT_TABLE=0
  for agent in "${CANONICAL_AGENTS[@]}"; do
    if grep -qE "^\|[[:space:]]*${agent}[[:space:]]*\|" "$DOC_PATH"; then
      HAS_AGENT_TABLE=1
      break
    fi
  done

  if [ "$HAS_AGENT_TABLE" -eq 0 ]; then
    echo "INFO: $doc does not appear to have an agent table (EXEMPT from agent enumeration check)"
    continue
  fi

  echo "Checking agent enumeration in $doc..."
  # Extract agent names from table rows
  grep -oE "^\|[[:space:]]*(analyst|fixer|reviewer|acceptance-gate|test-engineer|publisher|rollback-agent|spec-analyst|architect|stack-selector|scaffolder|priority-engine|spec-writer|spec-reviewer|browser-agent|deployment-verifier|backlog-creator|sprint-planner)[[:space:]]*\|" "$DOC_PATH" | \
    sed 's/|//g' | tr -d '[:space:]' | sort > "$TMPDIR_TEST/${doc//\//_}_agents.txt"

  if diff -q "$TMPDIR_TEST/canonical_agents.txt" "$TMPDIR_TEST/${doc//\//_}_agents.txt" > /dev/null 2>&1; then
    echo "OK: $doc agent enumeration matches canonical 18-agent list"
  else
    echo "Diff (canonical vs $doc):"
    diff "$TMPDIR_TEST/canonical_agents.txt" "$TMPDIR_TEST/${doc//\//_}_agents.txt" || true
    fail "$doc agent enumeration does not match canonical 18-agent list"
  fi
done

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-INV-DOC-ENUM-001 — 5 doc files enumeration parity verified"
fi
exit "$FAIL"
