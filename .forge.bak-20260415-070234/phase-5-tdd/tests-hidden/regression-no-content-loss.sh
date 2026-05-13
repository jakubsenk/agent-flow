#!/usr/bin/env bash
# Test: All 6 modified files retain expected section structure after implementation
# Regression guard: Goal/Expertise/Process/Constraints for agents; key sections for SKILL.md
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# -----------------------------------------------------------------------
# Helper: check that a file contains a required section heading
# -----------------------------------------------------------------------
require_section() {
  local file="$1"
  local heading="$2"
  local label="$3"
  if ! grep -q "^## ${heading}" "$file"; then
    fail "${label}: missing section '## ${heading}'"
  fi
}

# -----------------------------------------------------------------------
# Helper: check that a frontmatter field is present in an agent file
# -----------------------------------------------------------------------
require_frontmatter() {
  local file="$1"
  local field="$2"
  local label="$3"
  if ! grep -q "^${field}:" "$file"; then
    fail "${label}: missing frontmatter field '${field}'"
  fi
}

# -----------------------------------------------------------------------
# 1. agents/scaffolder.md
# -----------------------------------------------------------------------
SCAFFOLDER="$REPO_ROOT/agents/scaffolder.md"
if [ ! -f "$SCAFFOLDER" ]; then
  fail "Missing file: agents/scaffolder.md"
else
  for field in name description model style; do
    require_frontmatter "$SCAFFOLDER" "$field" "agents/scaffolder.md"
  done
  for section in Goal Expertise Process Constraints; do
    require_section "$SCAFFOLDER" "$section" "agents/scaffolder.md"
  done
  # Section order: Goal before Expertise before Process before Constraints
  GOAL_LINE=$(grep -n "^## Goal" "$SCAFFOLDER" | head -1 | cut -d: -f1)
  EXP_LINE=$(grep -n "^## Expertise" "$SCAFFOLDER" | head -1 | cut -d: -f1)
  PROC_LINE=$(grep -n "^## Process" "$SCAFFOLDER" | head -1 | cut -d: -f1)
  CON_LINE=$(grep -n "^## Constraints" "$SCAFFOLDER" | head -1 | cut -d: -f1)
  if [ "$GOAL_LINE" -ge "$EXP_LINE" ] || [ "$EXP_LINE" -ge "$PROC_LINE" ] || [ "$PROC_LINE" -ge "$CON_LINE" ]; then
    fail "agents/scaffolder.md: section order violated (expected Goal < Expertise < Process < Constraints)"
  fi
fi

# -----------------------------------------------------------------------
# 2. agents/triage-analyst.md
# -----------------------------------------------------------------------
TRIAGE="$REPO_ROOT/agents/triage-analyst.md"
if [ ! -f "$TRIAGE" ]; then
  fail "Missing file: agents/triage-analyst.md"
else
  for field in name description model style; do
    require_frontmatter "$TRIAGE" "$field" "agents/triage-analyst.md"
  done
  for section in Goal Expertise Process Constraints; do
    require_section "$TRIAGE" "$section" "agents/triage-analyst.md"
  done
  GOAL_LINE=$(grep -n "^## Goal" "$TRIAGE" | head -1 | cut -d: -f1)
  EXP_LINE=$(grep -n "^## Expertise" "$TRIAGE" | head -1 | cut -d: -f1)
  PROC_LINE=$(grep -n "^## Process" "$TRIAGE" | head -1 | cut -d: -f1)
  CON_LINE=$(grep -n "^## Constraints" "$TRIAGE" | head -1 | cut -d: -f1)
  if [ "$GOAL_LINE" -ge "$EXP_LINE" ] || [ "$EXP_LINE" -ge "$PROC_LINE" ] || [ "$PROC_LINE" -ge "$CON_LINE" ]; then
    fail "agents/triage-analyst.md: section order violated (expected Goal < Expertise < Process < Constraints)"
  fi
fi

# -----------------------------------------------------------------------
# 3. agents/code-analyst.md
# -----------------------------------------------------------------------
CODE_ANALYST="$REPO_ROOT/agents/code-analyst.md"
if [ ! -f "$CODE_ANALYST" ]; then
  fail "Missing file: agents/code-analyst.md"
else
  for field in name description model style; do
    require_frontmatter "$CODE_ANALYST" "$field" "agents/code-analyst.md"
  done
  for section in Goal Expertise Process Constraints; do
    require_section "$CODE_ANALYST" "$section" "agents/code-analyst.md"
  done
  GOAL_LINE=$(grep -n "^## Goal" "$CODE_ANALYST" | head -1 | cut -d: -f1)
  EXP_LINE=$(grep -n "^## Expertise" "$CODE_ANALYST" | head -1 | cut -d: -f1)
  PROC_LINE=$(grep -n "^## Process" "$CODE_ANALYST" | head -1 | cut -d: -f1)
  CON_LINE=$(grep -n "^## Constraints" "$CODE_ANALYST" | head -1 | cut -d: -f1)
  if [ "$GOAL_LINE" -ge "$EXP_LINE" ] || [ "$EXP_LINE" -ge "$PROC_LINE" ] || [ "$PROC_LINE" -ge "$CON_LINE" ]; then
    fail "agents/code-analyst.md: section order violated (expected Goal < Expertise < Process < Constraints)"
  fi
fi

# -----------------------------------------------------------------------
# 4. agents/fixer.md
# -----------------------------------------------------------------------
FIXER="$REPO_ROOT/agents/fixer.md"
if [ ! -f "$FIXER" ]; then
  fail "Missing file: agents/fixer.md"
else
  for field in name description model style; do
    require_frontmatter "$FIXER" "$field" "agents/fixer.md"
  done
  for section in Goal Expertise Process Constraints; do
    require_section "$FIXER" "$section" "agents/fixer.md"
  done
  GOAL_LINE=$(grep -n "^## Goal" "$FIXER" | head -1 | cut -d: -f1)
  EXP_LINE=$(grep -n "^## Expertise" "$FIXER" | head -1 | cut -d: -f1)
  PROC_LINE=$(grep -n "^## Process" "$FIXER" | head -1 | cut -d: -f1)
  CON_LINE=$(grep -n "^## Constraints" "$FIXER" | head -1 | cut -d: -f1)
  if [ "$GOAL_LINE" -ge "$EXP_LINE" ] || [ "$EXP_LINE" -ge "$PROC_LINE" ] || [ "$PROC_LINE" -ge "$CON_LINE" ]; then
    fail "agents/fixer.md: section order violated (expected Goal < Expertise < Process < Constraints)"
  fi
fi

# -----------------------------------------------------------------------
# 5. agents/reviewer.md
# -----------------------------------------------------------------------
REVIEWER="$REPO_ROOT/agents/reviewer.md"
if [ ! -f "$REVIEWER" ]; then
  fail "Missing file: agents/reviewer.md"
else
  for field in name description model style; do
    require_frontmatter "$REVIEWER" "$field" "agents/reviewer.md"
  done
  for section in Goal Expertise Process Constraints; do
    require_section "$REVIEWER" "$section" "agents/reviewer.md"
  done
  GOAL_LINE=$(grep -n "^## Goal" "$REVIEWER" | head -1 | cut -d: -f1)
  EXP_LINE=$(grep -n "^## Expertise" "$REVIEWER" | head -1 | cut -d: -f1)
  PROC_LINE=$(grep -n "^## Process" "$REVIEWER" | head -1 | cut -d: -f1)
  CON_LINE=$(grep -n "^## Constraints" "$REVIEWER" | head -1 | cut -d: -f1)
  if [ "$GOAL_LINE" -ge "$EXP_LINE" ] || [ "$EXP_LINE" -ge "$PROC_LINE" ] || [ "$PROC_LINE" -ge "$CON_LINE" ]; then
    fail "agents/reviewer.md: section order violated (expected Goal < Expertise < Process < Constraints)"
  fi
fi

# -----------------------------------------------------------------------
# 6. skills/fix-bugs/SKILL.md
# -----------------------------------------------------------------------
SKILL="$REPO_ROOT/skills/fix-bugs/SKILL.md"
if [ ! -f "$SKILL" ]; then
  fail "Missing file: skills/fix-bugs/SKILL.md"
else
  # Frontmatter fields
  for field in name description allowed-tools disable-model-invocation argument-hint; do
    if ! grep -q "^${field}:" "$SKILL"; then
      fail "skills/fix-bugs/SKILL.md: missing frontmatter field '${field}'"
    fi
  done
  # Key sections: Fix Bugs Pipeline heading, Orchestration, and blocking section
  if ! grep -q "^# Fix Bugs Pipeline" "$SKILL"; then
    fail "skills/fix-bugs/SKILL.md: missing '# Fix Bugs Pipeline' heading"
  fi
  if ! grep -q "^## Orchestration" "$SKILL"; then
    fail "skills/fix-bugs/SKILL.md: missing '## Orchestration' section"
  fi
  # Blocking section or equivalent
  if ! grep -q "Pipeline Block" "$SKILL"; then
    fail "skills/fix-bugs/SKILL.md: missing Pipeline Block template reference"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: All 6 modified files retain expected section structure (frontmatter, section order, key headings)"
exit "$FAIL"
