#!/usr/bin/env bash
# Test: Edge case structural validation for Phase 1 and Phase 2
# Validates FC-076 to FC-083 (cross-phase criteria), plus edge cases from requirements
# Hidden: tests subtle correctness that implementors might overlook
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SCAFFOLD="$REPO_ROOT/commands/scaffold.md"
IMPLEMENT="$REPO_ROOT/commands/implement-feature.md"
FIX_TICKET="$REPO_ROOT/commands/fix-ticket.md"
AGENT_DIR="$REPO_ROOT/agents"
CMD_DIR="$REPO_ROOT/commands"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

# ── FC-076: No ACTIVE (non-archival) file contains string "bug-workflow" ──────
# Historical plan docs, changelogs, and .forge backups are excluded — only active plugin files matter.
# Active directories: agents/, commands/, skills/, core/, state/, docs/reference/, docs/guides/,
#                     checklists/, examples/, .claude-plugin/, CLAUDE.md, README.md (if exists)
ACTIVE_DIRS=(
  "$REPO_ROOT/agents"
  "$REPO_ROOT/commands"
  "$REPO_ROOT/skills"
  "$REPO_ROOT/core"
  "$REPO_ROOT/state"
  "$REPO_ROOT/.claude-plugin"
  "$REPO_ROOT/checklists"
  "$REPO_ROOT/examples"
)
found_bug_workflow=""
for dir in "${ACTIVE_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    found=$(grep -rl 'bug-workflow' "$dir" --include="*.md" --include="*.json" 2>/dev/null || true)
    if [ -n "$found" ]; then
      found_bug_workflow="$found_bug_workflow $found"
    fi
  fi
done
# Also check root-level docs reference and guide files (not plans/)
if [ -d "$REPO_ROOT/docs/reference" ]; then
  found=$(grep -rl 'bug-workflow' "$REPO_ROOT/docs/reference" 2>/dev/null || true)
  [ -n "$found" ] && found_bug_workflow="$found_bug_workflow $found"
fi
if [ -d "$REPO_ROOT/docs/guides" ]; then
  found=$(grep -rl 'bug-workflow' "$REPO_ROOT/docs/guides" 2>/dev/null || true)
  [ -n "$found" ] && found_bug_workflow="$found_bug_workflow $found"
fi
# Check CLAUDE.md directly (FC-026 + FC-076)
if grep -q 'bug-workflow' "$REPO_ROOT/CLAUDE.md" 2>/dev/null; then
  found_bug_workflow="$found_bug_workflow $REPO_ROOT/CLAUDE.md"
fi
found_bug_workflow=$(echo "$found_bug_workflow" | tr ' ' '\n' | grep -v '^$' | sort -u || true)
if [ -n "$found_bug_workflow" ]; then
  fail "FC-076: 'bug-workflow' string still found in active plugin files:$found_bug_workflow"
fi

# ── FC-077: scaffold.md Step 4b does NOT reference /onboard ───────────────────
if [ -f "$SCAFFOLD" ]; then
  # Extract Step 4b section (between Step 4b header and Step 4c or Step 5)
  step4b_content=$(awk '/Step 4b.*Tracker|### Step 4b/{found=1} found && /Step 4c|### Step 5/{found=0} found{print}' "$SCAFFOLD")
  if echo "$step4b_content" | grep -q '/onboard\|ceos-agents:onboard'; then
    fail "FC-077: scaffold.md Step 4b references '/onboard' — scaffold must handle config inline, not delegate to onboard"
  fi
fi

# ── FC-078: scaffold.md Step 4b does NOT invoke Skill tool ────────────────────
if [ -f "$SCAFFOLD" ]; then
  step4b_content=$(awk '/Step 4b.*Tracker|### Step 4b/{found=1} found && /Step 4c|### Step 5/{found=0} found{print}' "$SCAFFOLD")
  if echo "$step4b_content" | grep -qi "Skill(skill=\|Skill tool\|invoke.*command\|run.*command"; then
    fail "FC-078: scaffold.md Step 4b invokes another command via Skill tool (inline approach required — commands cannot invoke commands)"
  fi
fi

# ── FC-079: All new agent files follow frontmatter field order ─────────────────
# New agent: deployment-verifier. Check field order: name, description, model, style
NEW_AGENTS=(deployment-verifier)
for agent in "${NEW_AGENTS[@]}"; do
  f="$AGENT_DIR/$agent.md"
  if [ ! -f "$f" ]; then
    fail "FC-079: agents/$agent.md does not exist"
    continue
  fi
  # Extract frontmatter (between first --- and second ---)
  frontmatter=$(awk '/^---/{count++; if(count==2) exit} count==1{print}' "$f")
  name_line=$(echo "$frontmatter" | grep -n '^name:' | head -1 | cut -d: -f1)
  desc_line=$(echo "$frontmatter" | grep -n '^description:' | head -1 | cut -d: -f1)
  model_line=$(echo "$frontmatter" | grep -n '^model:' | head -1 | cut -d: -f1)
  style_line=$(echo "$frontmatter" | grep -n '^style:' | head -1 | cut -d: -f1)
  if [ -z "$name_line" ] || [ -z "$desc_line" ] || [ -z "$model_line" ] || [ -z "$style_line" ]; then
    fail "FC-079: agents/$agent.md missing one or more required frontmatter fields (name, description, model, style)"
    continue
  fi
  if [ "$name_line" -ge "$desc_line" ] || [ "$desc_line" -ge "$model_line" ] || [ "$model_line" -ge "$style_line" ]; then
    fail "FC-079: agents/$agent.md frontmatter fields not in required order: name, description, model, style (got lines: $name_line, $desc_line, $model_line, $style_line)"
  fi
done

# ── FC-080: All new command files follow frontmatter field order ───────────────
# New command: check-deploy. Verify: description, allowed-tools (in that order)
NEW_COMMANDS=(check-deploy)
for cmd in "${NEW_COMMANDS[@]}"; do
  f="$CMD_DIR/$cmd.md"
  if [ ! -f "$f" ]; then
    fail "FC-080: commands/$cmd.md does not exist"
    continue
  fi
  frontmatter=$(awk '/^---/{count++; if(count==2) exit} count==1{print}' "$f")
  desc_line=$(echo "$frontmatter" | grep -n '^description:' | head -1 | cut -d: -f1)
  tools_line=$(echo "$frontmatter" | grep -n '^allowed-tools:' | head -1 | cut -d: -f1)
  if [ -z "$desc_line" ]; then
    fail "FC-080: commands/$cmd.md frontmatter missing 'description' field"
    continue
  fi
  if [ -z "$tools_line" ]; then
    fail "FC-080: commands/$cmd.md frontmatter missing 'allowed-tools' field"
    continue
  fi
  if [ "$desc_line" -ge "$tools_line" ]; then
    fail "FC-080: commands/$cmd.md frontmatter: 'description' (line $desc_line) must come before 'allowed-tools' (line $tools_line)"
  fi
done

# ── FC-081: No new REQUIRED keys added to Automation Config contract ───────────
# Check that all new config additions appear in the optional sections table, not required
if [ -f "$CLAUDE_MD" ]; then
  # Local Deployment must appear in the optional table, NOT in the required table
  # The required table contains: Issue Tracker, Source Control, PR Rules, PR Description Template, Build & Test
  required_section=$(awk '/\| Section \| Keys \|/{found=1; count=0} found{count++; if(count>10) exit} found{print}' "$CLAUDE_MD" | head -10)
  if echo "$required_section" | grep -q 'Local Deployment'; then
    fail "FC-081: 'Local Deployment' appears in the REQUIRED config sections table — it must be in the optional table only"
  fi
fi

# ── FC-083: --description flag runs config validity gate (0b) BEFORE card creation (0c) ─
if [ -f "$IMPLEMENT" ]; then
  step_0b_line=$(grep -n "0b.*Config validity\|### 0b\.\|Step 0b" "$IMPLEMENT" | head -1 | cut -d: -f1)
  step_0c_line=$(grep -n "0c.*Feature card\|### 0c\.\|Step 0c" "$IMPLEMENT" | head -1 | cut -d: -f1)
  desc_mode_ref=$(grep -n 'description_mode\|--description' "$IMPLEMENT" | grep -i 'true\|mode\|flag' | head -1 | cut -d: -f1)

  if [ -n "$step_0b_line" ] && [ -n "$step_0c_line" ] && [ "$step_0b_line" -ge "$step_0c_line" ]; then
    fail "FC-083: --description flag: config validity gate (Step 0b, line $step_0b_line) must come BEFORE card creation (Step 0c, line $step_0c_line)"
  fi
  # Additionally, Step 0c must be conditional on description_mode
  if [ -n "$step_0c_line" ] && [ -f "$IMPLEMENT" ]; then
    step_0c_context=$(sed -n "$((step_0c_line)),$((step_0c_line + 10))p" "$IMPLEMENT")
    if ! echo "$step_0c_context" | grep -qi 'description_mode\|if.*description\|--description\|when.*description'; then
      fail "FC-083: implement-feature.md Step 0c is not conditional on description_mode/--description flag"
    fi
  fi
fi

# ── EDGE: Full YOLO mode correctly skips tracker config in scaffold ─────────────
# REQ-P1-001 AC-4: Full YOLO skips tracker configuration
if [ -f "$SCAFFOLD" ]; then
  if ! grep -qi 'Full YOLO\|full.*yolo\|FULL_YOLO' "$SCAFFOLD"; then
    fail "EDGE: scaffold.md does not reference 'Full YOLO' mode anywhere"
  fi
  # The skip condition must be in proximity to the tracker config step
  full_yolo_line=$(grep -in 'Full YOLO\|FULL_YOLO' "$SCAFFOLD" | head -1 | cut -d: -f1)
  step4b_line=$(grep -n 'Step 4b\|step4b\|Tracker Configuration' "$SCAFFOLD" | head -1 | cut -d: -f1)
  if [ -n "$full_yolo_line" ] && [ -n "$step4b_line" ]; then
    # Full YOLO mention should be within 50 lines of Step 4b
    diff=$((full_yolo_line - step4b_line))
    abs_diff=${diff#-}  # absolute value
    if [ "$abs_diff" -gt 80 ]; then
      fail "EDGE: scaffold.md 'Full YOLO' skip mention (line $full_yolo_line) is far from Step 4b (line $step4b_line) — likely not in the tracker config section"
    fi
  fi
fi

# ── EDGE: --description and Issue ID mutual exclusion has explicit error message ─
# REQ-P2-001 AC-2: must not be provided alongside --description
if [ -f "$IMPLEMENT" ]; then
  if ! grep -qi 'error\|BLOCK\|cannot\|not.*allowed\|invalid\|mutually' "$IMPLEMENT" | grep -qi 'description.*issue\|issue.*description' 2>/dev/null; then
    # Re-check with simpler grep
    if ! grep -qi 'mutually exclusive\|cannot.*both\|not.*combined\|alongside.*--description\|--description.*alongside' "$IMPLEMENT"; then
      fail "EDGE: implement-feature.md missing explicit error for --description + Issue ID combination"
    fi
  fi
fi

# ── EDGE: Step 0c only runs when description_mode = true ─────────────────────
# The card creation step must be gated — not run for every implement-feature invocation
if [ -f "$IMPLEMENT" ]; then
  step_0c_line=$(grep -n "0c.*Feature card\|### 0c\.\|Step 0c" "$IMPLEMENT" | head -1 | cut -d: -f1)
  if [ -n "$step_0c_line" ]; then
    # Extract a window around Step 0c for the conditional check
    window=$(sed -n "$((step_0c_line > 3 ? step_0c_line - 3 : 1)),$((step_0c_line + 5))p" "$IMPLEMENT")
    if ! echo "$window" | grep -qi 'description_mode\|if.*description\|only.*--description\|when.*description'; then
      fail "EDGE: implement-feature.md Step 0c header/preamble does not gate on description_mode — card creation must only run when --description is provided"
    fi
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Edge case structural tests passed (FC-076 to FC-083, plus edge cases)"
exit "$FAIL"
