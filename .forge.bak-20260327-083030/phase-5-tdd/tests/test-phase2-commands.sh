#!/usr/bin/env bash
# Test: Phase 2 command structural tests — implement-feature --description, workflow-router routing
# Validates FC-034 to FC-046
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

IMPLEMENT="$REPO_ROOT/commands/implement-feature.md"
SKILL_FILE="$REPO_ROOT/skills/workflow-router/SKILL.md"

# ── FC-034: implement-feature.md Input includes --description flag ─────────────
if [ ! -f "$IMPLEMENT" ]; then
  fail "commands/implement-feature.md does not exist"
else
  if ! grep -q -- '--description\|--desc' "$IMPLEMENT"; then
    fail "FC-034: implement-feature.md Input line does not include '--description' flag"
  fi
fi

# ── FC-035: implement-feature.md flag parsing handles --description ────────────
if [ -f "$IMPLEMENT" ]; then
  if ! grep -qi 'description_mode\|desc.*mode\|--description.*true\|parse.*--description' "$IMPLEMENT"; then
    fail "FC-035: implement-feature.md flag parsing section does not handle '--description' or set description_mode"
  fi
fi

# ── FC-036: implement-feature.md rejects --description combined with Issue ID ──
if [ -f "$IMPLEMENT" ]; then
  if ! grep -qi 'mutually exclusive\|cannot.*combined\|--description.*Issue ID\|Issue ID.*--description\|not.*provided.*alongside\|provided.*alongside' "$IMPLEMENT"; then
    fail "FC-036: implement-feature.md missing explicit error for --description combined with Issue ID"
  fi
fi

# ── FC-037: implement-feature.md contains Step 0c: Feature card creation ───────
if [ -f "$IMPLEMENT" ]; then
  if ! grep -q "0c.*Feature card\|### 0c\.\|Step 0c" "$IMPLEMENT"; then
    fail "FC-037: implement-feature.md missing '### 0c. Feature card creation' section"
  fi
fi

# ── FC-038: implement-feature.md Step 0c creates issue via MCP ────────────────
if [ -f "$IMPLEMENT" ]; then
  if ! grep -qi 'create.*issue\|mcp.*create\|issue.*mcp\|create.*tracker\|tracker.*card' "$IMPLEMENT"; then
    fail "FC-038: implement-feature.md Step 0c does not reference creating an issue via MCP"
  fi
fi

# ── FC-039: implement-feature.md Step 0c displays "Created {ISSUE-ID}: {title}" ─
if [ -f "$IMPLEMENT" ]; then
  if ! grep -qi 'Created.*ISSUE\|Created.*{.*ID.*}\|Created.*issue.*title' "$IMPLEMENT"; then
    fail "FC-039: implement-feature.md Step 0c missing 'Created {ISSUE-ID}: {title}' confirmation display"
  fi
fi

# ── FC-040: implement-feature.md Step 0c has BLOCK handler for MCP failure ────
if [ -f "$IMPLEMENT" ]; then
  # Check in proximity to the 0c section for BLOCK language
  if ! grep -qi 'card.*fail\|mcp.*fail\|creation.*fail\|BLOCK.*card\|card.*BLOCK' "$IMPLEMENT"; then
    fail "FC-040: implement-feature.md Step 0c missing BLOCK handler for MCP card creation failure"
  fi
fi

# ── FC-041: implement-feature.md Step 0c shows preview without --yolo ─────────
if [ -f "$IMPLEMENT" ]; then
  if ! grep -qi 'preview\|confirm.*card\|card.*confirm\|--yolo.*confirm\|confirm.*--yolo' "$IMPLEMENT"; then
    fail "FC-041: implement-feature.md Step 0c missing card preview / confirmation flow when --yolo is NOT set"
  fi
fi

# ── FC-042: Step 0c is positioned AFTER Step 0b (order check) ──────────────────
if [ -f "$IMPLEMENT" ]; then
  step_0b_line=$(grep -n "0b.*Config validity\|### 0b\.\|Step 0b" "$IMPLEMENT" | head -1 | cut -d: -f1)
  step_0c_line=$(grep -n "0c.*Feature card\|### 0c\.\|Step 0c" "$IMPLEMENT" | head -1 | cut -d: -f1)
  if [ -n "$step_0b_line" ] && [ -n "$step_0c_line" ]; then
    if [ "$step_0b_line" -ge "$step_0c_line" ]; then
      fail "FC-042: implement-feature.md Step 0c appears before Step 0b (config gate must run first)"
    fi
  elif [ -z "$step_0b_line" ] && [ -n "$step_0c_line" ]; then
    fail "FC-042: implement-feature.md has Step 0c but missing Step 0b (config gate must exist before card creation)"
  fi
fi

# ── FC-043: workflow-router SKILL.md has row for feature-from-description ──────
if [ ! -f "$SKILL_FILE" ]; then
  fail "skills/workflow-router/SKILL.md does not exist"
else
  if ! grep -qi 'describe.*feature\|feature.*describe\|--description\|implement.*description' "$SKILL_FILE"; then
    fail "FC-043: workflow-router SKILL.md intent table missing row for describing a feature (--description route)"
  fi
fi

# ── FC-044: workflow-router SKILL.md has rows for check-deploy ────────────────
if [ -f "$SKILL_FILE" ]; then
  if ! grep -q 'check-deploy\|check.*deploy\|deploy.*check' "$SKILL_FILE"; then
    fail "FC-044: workflow-router SKILL.md intent table missing rows for check-deploy (check/start/stop)"
  fi
  # Verify at least --start and --stop are mentioned in context of deploy
  if ! grep -qi '\-\-start\|\-\-stop' "$SKILL_FILE"; then
    fail "FC-044: workflow-router SKILL.md missing --start/--stop flag mentions for check-deploy routing"
  fi
fi

# ── FC-045: workflow-router SKILL.md Process has disambiguation logic ──────────
if [ -f "$SKILL_FILE" ]; then
  if ! grep -qi 'disambig\|issue.*ID.*vs\|description.*vs.*issue\|Issue ID.*description\|distinguish' "$SKILL_FILE"; then
    fail "FC-045: workflow-router SKILL.md Process missing disambiguation logic for implement-feature (issue ID vs. description)"
  fi
fi

# ── FC-046: workflow-router marks feature-from-description as Destructive? Yes ─
if [ -f "$SKILL_FILE" ]; then
  # The --description row in the intent table should have Yes in the Destructive? column
  if ! grep -i 'description\|describe.*feature' "$SKILL_FILE" | grep -q 'Yes\|YES'; then
    fail "FC-046: workflow-router feature-from-description intent row not marked as 'Destructive? Yes'"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Phase 2 command structural tests passed (FC-034 to FC-046)"
exit "$FAIL"
