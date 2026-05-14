#!/usr/bin/env bash
# Test: fix-bugs SKILL.md contains Config Validity Gate (Step 0b)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

FIX_BUGS="$REPO_ROOT/skills/fix-bugs/SKILL.md"

if [ ! -f "$FIX_BUGS" ]; then
  fail "skills/fix-bugs/SKILL.md does not exist"
  exit "$FAIL"
fi

# Step 0b heading exists
if ! grep -q '### Step 0b: Config Validity Gate' "$FIX_BUGS"; then
  fail "skills/fix-bugs/SKILL.md missing heading: '### Step 0b: Config Validity Gate'"
fi

# Step 0b references implement-feature.md Step 0b as canonical source
if ! grep -q 'implement-feature.md Step 0b' "$FIX_BUGS"; then
  fail "skills/fix-bugs/SKILL.md Step 0b does not reference 'implement-feature.md Step 0b' as canonical source"
fi

# Step 0b checks all 4 required config sections on one line/block
if ! grep 'Issue Tracker' "$FIX_BUGS" | grep 'Source Control' | grep 'PR Rules' | grep -q 'Build & Test'; then
  fail "skills/fix-bugs/SKILL.md Step 0b does not check all 4 required sections (Issue Tracker, Source Control, PR Rules, Build & Test) together"
fi

# Block comment template with [agent-flow] prefix and rocket/red emoji
if ! grep -q '\[agent-flow\].*Pipeline Block' "$FIX_BUGS"; then
  fail "skills/fix-bugs/SKILL.md missing block comment template with '[agent-flow]' prefix and 'Pipeline Block'"
fi

# Step 0b appears between MCP pre-flight check and Orchestration heading (structural position)
mcp_line=$(grep -n 'MCP pre-flight check' "$FIX_BUGS" | head -1 | cut -d: -f1)
gate_line=$(grep -n 'Step 0b: Config Validity Gate' "$FIX_BUGS" | head -1 | cut -d: -f1)
orch_line=$(grep -n '## Orchestration' "$FIX_BUGS" | head -1 | cut -d: -f1)

if [ -z "$mcp_line" ] || [ -z "$gate_line" ] || [ -z "$orch_line" ]; then
  fail "skills/fix-bugs/SKILL.md: Could not find all required structural markers (MCP pre-flight check, Step 0b, Orchestration heading)"
else
  if [ "$gate_line" -le "$mcp_line" ]; then
    fail "skills/fix-bugs/SKILL.md: Step 0b (line $gate_line) must appear after MCP pre-flight check (line $mcp_line)"
  fi
  if [ "$gate_line" -ge "$orch_line" ]; then
    fail "skills/fix-bugs/SKILL.md: Step 0b (line $gate_line) must appear before Orchestration heading (line $orch_line)"
  fi
fi

# Step 0b says "proceed to Step 1" (matching fix-bugs Step 1 = Fetch bugs)
if ! grep -A 50 'Step 0b: Config Validity Gate' "$FIX_BUGS" | grep -q 'proceed to Step 1'; then
  fail "skills/fix-bugs/SKILL.md Step 0b missing terminal instruction 'proceed to Step 1'"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: fix-bugs SKILL.md Config Validity Gate (Step 0b) is present and correctly structured"
exit "$FAIL"
