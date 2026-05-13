#!/usr/bin/env bash
# Test: Phase 2 deployment-verifier agent structural validation
# Validates FC-052 to FC-059, FC-071, FC-073, FC-074
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

AGENT="$REPO_ROOT/agents/deployment-verifier.md"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

# ── FC-052: agents/deployment-verifier.md exists ─────────────────────────────
if [ ! -f "$AGENT" ]; then
  fail "FC-052: agents/deployment-verifier.md does not exist"
fi

# ── FC-053: Frontmatter has exactly the required 4 fields ─────────────────────
if [ -f "$AGENT" ]; then
  if ! grep -q "^name: deployment-verifier$" "$AGENT"; then
    fail "FC-053: deployment-verifier.md frontmatter 'name' is not 'deployment-verifier'"
  fi
  description_value=$(grep "^description:" "$AGENT" | sed 's/^description://' | tr -d '[:space:]')
  if [ -z "$description_value" ]; then
    fail "FC-053: deployment-verifier.md frontmatter 'description' is empty"
  fi
  if ! grep -q "^model: sonnet$" "$AGENT"; then
    fail "FC-053: deployment-verifier.md frontmatter 'model' is not 'sonnet'"
  fi
  style_value=$(grep "^style:" "$AGENT" | sed 's/^style://' | tr -d '[:space:]')
  if [ -z "$style_value" ]; then
    fail "FC-053: deployment-verifier.md frontmatter 'style' is empty"
  fi
fi

# ── FC-054: Section order: Goal → Expertise → Process → Constraints ───────────
if [ -f "$AGENT" ]; then
  goal_line=$(grep -n "^## Goal" "$AGENT" | head -1 | cut -d: -f1)
  expertise_line=$(grep -n "^## Expertise" "$AGENT" | head -1 | cut -d: -f1)
  process_line=$(grep -n "^## Process" "$AGENT" | head -1 | cut -d: -f1)
  constraints_line=$(grep -n "^## Constraints" "$AGENT" | head -1 | cut -d: -f1)

  if [ -z "$goal_line" ]; then
    fail "FC-054: deployment-verifier.md missing ## Goal section"
  elif [ -z "$expertise_line" ]; then
    fail "FC-054: deployment-verifier.md missing ## Expertise section"
  elif [ -z "$process_line" ]; then
    fail "FC-054: deployment-verifier.md missing ## Process section"
  elif [ -z "$constraints_line" ]; then
    fail "FC-054: deployment-verifier.md missing ## Constraints section"
  else
    if [ "$goal_line" -ge "$expertise_line" ]; then
      fail "FC-054: deployment-verifier.md ## Goal must come before ## Expertise"
    fi
    if [ "$expertise_line" -ge "$process_line" ]; then
      fail "FC-054: deployment-verifier.md ## Expertise must come before ## Process"
    fi
    if [ "$process_line" -ge "$constraints_line" ]; then
      fail "FC-054: deployment-verifier.md ## Process must come before ## Constraints"
    fi
  fi
fi

# ── FC-055: Process contains at least 5 numbered steps covering key actions ────
if [ -f "$AGENT" ]; then
  process_section=$(awk '/^## Process/{found=1} found && /^## Constraints/{found=0} found{print}' "$AGENT")
  step_count=$(echo "$process_section" | grep -c '^[0-9]\+\.' || true)
  if [ "$step_count" -lt 5 ]; then
    fail "FC-055: deployment-verifier.md Process has only $step_count numbered steps (expected >= 5)"
  fi
  # Verify key coverage areas
  if ! echo "$process_section" | grep -qi 'read.*config\|config.*read\|Local Deployment'; then
    fail "FC-055: deployment-verifier.md Process missing step: read config"
  fi
  if ! echo "$process_section" | grep -qi 'port.*scan\|port.*check\|scan.*port\|check.*port'; then
    fail "FC-055: deployment-verifier.md Process missing step: port scan"
  fi
  if ! echo "$process_section" | grep -qi 'start.*app\|app.*start\|Start command\|launch'; then
    fail "FC-055: deployment-verifier.md Process missing step: start app"
  fi
  if ! echo "$process_section" | grep -qi 'health.*check\|health.*poll\|poll.*health'; then
    fail "FC-055: deployment-verifier.md Process missing step: health check"
  fi
  if ! echo "$process_section" | grep -qi 'verdict\|HEALTHY\|result'; then
    fail "FC-055: deployment-verifier.md Process missing step: determine verdict"
  fi
fi

# ── FC-056: Port conflict detection runs BEFORE any start attempt ──────────────
if [ -f "$AGENT" ]; then
  process_section=$(awk '/^## Process/{found=1} found && /^## Constraints/{found=0} found{print}' "$AGENT")
  port_line=$(echo "$process_section" | grep -n 'port.*conflict\|port.*check\|port.*scan\|check.*port' | head -1 | cut -d: -f1)
  start_line=$(echo "$process_section" | grep -n 'start.*app\|Start command\|launch\|start.*process' | head -1 | cut -d: -f1)
  if [ -n "$port_line" ] && [ -n "$start_line" ]; then
    if [ "$port_line" -ge "$start_line" ]; then
      fail "FC-056: deployment-verifier.md port conflict detection (line $port_line) does not appear before start attempt (line $start_line)"
    fi
  else
    fail "FC-056: deployment-verifier.md Process missing either port conflict detection or start step"
  fi
fi

# ── FC-057: Constraints section contains at least 5 NEVER rules ───────────────
if [ -f "$AGENT" ]; then
  constraints_section=$(awk '/^## Constraints/{found=1} found{print}' "$AGENT")
  never_count=$(echo "$constraints_section" | grep -c '^- NEVER\|^NEVER\|^\* NEVER' || true)
  if [ "$never_count" -lt 5 ]; then
    fail "FC-057: deployment-verifier.md Constraints has only $never_count NEVER rules (expected >= 5)"
  fi
fi

# ── FC-058: Agent defines all 5 verdict states ────────────────────────────────
if [ -f "$AGENT" ]; then
  for verdict in HEALTHY UNHEALTHY PORT_CONFLICT START_FAILED SKIPPED; do
    if ! grep -q "$verdict" "$AGENT"; then
      fail "FC-058: deployment-verifier.md missing verdict definition: $verdict"
    fi
  done
fi

# ── FC-059: Agent Output section has structured report template ────────────────
if [ -f "$AGENT" ]; then
  if ! grep -q "## Output\|### Output\|Output.*template\|Report.*template" "$AGENT"; then
    fail "FC-059: deployment-verifier.md missing Output section with structured report template"
  fi
fi

# ── FC-071: CLAUDE.md Architecture lists deployment-verifier in agents list ────
if [ -f "$CLAUDE_MD" ]; then
  if ! grep -q 'deployment-verifier' "$CLAUDE_MD"; then
    fail "FC-071: CLAUDE.md Architecture section does not list 'deployment-verifier' in agents list"
  fi
fi

# ── FC-073: CLAUDE.md Model Selection table has deployment-verifier = sonnet ──
if [ -f "$CLAUDE_MD" ]; then
  if ! grep -q 'deployment-verifier.*sonnet\|sonnet.*deployment-verifier' "$CLAUDE_MD"; then
    fail "FC-073: CLAUDE.md Model Selection table missing deployment-verifier with model sonnet"
  fi
fi

# ── FC-074: CLAUDE.md states 19 agents and 25 commands ───────────────────────
if [ -f "$CLAUDE_MD" ]; then
  if ! grep -q '19 agent\|19 agents' "$CLAUDE_MD"; then
    fail "FC-074: CLAUDE.md does not state 19 agents (still shows 18 or other count)"
  fi
  if ! grep -q '25 command\|25 commands' "$CLAUDE_MD"; then
    fail "FC-074: CLAUDE.md does not state 25 commands (still shows 24 or other count)"
  fi
fi

# ── FC-082: deployment-verifier does NOT contain code-modification instructions ─
if [ -f "$AGENT" ]; then
  if grep -qi 'edit.*source\|modify.*source\|write.*source\|change.*code\|Write tool\|Edit tool' "$AGENT"; then
    fail "FC-082: deployment-verifier.md contains code-modification instructions (agent must be read-only for source code)"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Phase 2 deployment-verifier agent structural tests passed (FC-052 to FC-059, FC-071, FC-073, FC-074, FC-082)"
exit "$FAIL"
