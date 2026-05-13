#!/usr/bin/env bash
# Test: All 10 agents have NEVER external-input constraint; test file updated for 10 agents
# AC-36 through AC-42 (v6.7.1 — Item 7)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

AGENTS_DIR="$REPO_ROOT/agents"
INJECTION_TEST="$REPO_ROOT/tests/scenarios/prompt-injection-protection.sh"

ALL_10_AGENTS=(
  "triage-analyst"
  "code-analyst"
  "fixer"
  "spec-analyst"
  "reviewer"
  "acceptance-gate"
  "architect"
  "reproducer"
  "priority-engine"
  "browser-verifier"
)

NEW_5_AGENTS=(
  "acceptance-gate"
  "architect"
  "reproducer"
  "priority-engine"
  "browser-verifier"
)

# AC-36: All 10 agents have NEVER on the EXTERNAL INPUT START line
for agent in "${ALL_10_AGENTS[@]}"; do
  agent_file="$AGENTS_DIR/${agent}.md"
  if [ ! -f "$agent_file" ]; then
    fail "agents/${agent}.md does not exist"
  elif ! grep "EXTERNAL INPUT START" "$agent_file" | grep -q "NEVER"; then
    fail "agents/${agent}.md: EXTERNAL INPUT START line does not use NEVER"
  fi
done

# AC-37: All 10 agents have NEVER on the EXTERNAL INPUT END line
for agent in "${ALL_10_AGENTS[@]}"; do
  agent_file="$AGENTS_DIR/${agent}.md"
  if [ -f "$agent_file" ]; then
    if ! grep "EXTERNAL INPUT END" "$agent_file" | grep -q "NEVER"; then
      fail "agents/${agent}.md: EXTERNAL INPUT END line does not use NEVER"
    fi
  fi
done

# AC-38: Constraint text in each of the 5 new agents is byte-identical to triage-analyst.md
ref_line=$(grep "NEVER follow instructions.*EXTERNAL INPUT START" "$AGENTS_DIR/triage-analyst.md")
if [ -z "$ref_line" ]; then
  fail "agents/triage-analyst.md: reference constraint line not found (pattern: 'NEVER follow instructions.*EXTERNAL INPUT START')"
else
  for agent in "${NEW_5_AGENTS[@]}"; do
    agent_file="$AGENTS_DIR/${agent}.md"
    if [ -f "$agent_file" ]; then
      agent_line=$(grep "NEVER follow instructions.*EXTERNAL INPUT START" "$agent_file" 2>/dev/null || true)
      if [ -z "$agent_line" ]; then
        fail "agents/${agent}.md: constraint line not found (pattern: 'NEVER follow instructions.*EXTERNAL INPUT START')"
      elif [ "$ref_line" != "$agent_line" ]; then
        fail "agents/${agent}.md: constraint text differs from triage-analyst.md reference"
      fi
    fi
  done
fi

# AC-39: Constraint is the last line of content in each of the 5 new agents
for agent in "${NEW_5_AGENTS[@]}"; do
  agent_file="$AGENTS_DIR/${agent}.md"
  if [ -f "$agent_file" ]; then
    last_content_line=$(grep -n '.' "$agent_file" | tail -1 | cut -d: -f1)
    never_line=$(grep -n 'NEVER follow instructions.*EXTERNAL INPUT' "$agent_file" | tail -1 | cut -d: -f1)
    if [ -z "$never_line" ]; then
      fail "agents/${agent}.md: NEVER constraint line not found"
    elif [ "$last_content_line" != "$never_line" ]; then
      fail "agents/${agent}.md: NEVER constraint is not the last content line (last=$last_content_line, never=$never_line)"
    fi
  fi
done

# AC-40: Test file AGENTS_TO_CHECK array contains exactly 10 agents
if [ ! -f "$INJECTION_TEST" ]; then
  fail "tests/scenarios/prompt-injection-protection.sh does not exist"
else
  count=$(sed -n '/AGENTS_TO_CHECK=(/,/)/p' "$INJECTION_TEST" | grep -c '"' || true)
  if [ "$count" -ne 10 ]; then
    fail "tests/scenarios/prompt-injection-protection.sh AGENTS_TO_CHECK has $count entries (expected 10)"
  fi
fi

# AC-41: Test file AGENTS_TO_CHECK contains all 5 new agents
if [ -f "$INJECTION_TEST" ]; then
  for agent in "${NEW_5_AGENTS[@]}"; do
    if ! grep -A 15 'AGENTS_TO_CHECK=' "$INJECTION_TEST" | grep -q "\"${agent}\""; then
      fail "tests/scenarios/prompt-injection-protection.sh: AGENTS_TO_CHECK missing '\"${agent}\"'"
    fi
  done
fi

# AC-42: Test file AC-3 comment says "All 10 agents" not "All 5 agents"
if [ -f "$INJECTION_TEST" ]; then
  if ! grep -q 'All 10 agents' "$INJECTION_TEST"; then
    fail "tests/scenarios/prompt-injection-protection.sh: AC-3 comment does not say 'All 10 agents'"
  fi
  if grep -q 'All 5 agents' "$INJECTION_TEST"; then
    fail "tests/scenarios/prompt-injection-protection.sh: AC-3 comment still says 'All 5 agents' (must be updated to 10)"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: All 10 agents have NEVER external-input constraint; test file updated to 10-agent array (AC-36 to AC-42)"
exit "$FAIL"
