#!/usr/bin/env bash
# Test: Prompt injection protection — external-input-sanitizer core contract, skill refs, agent constraints
# AC-1 through AC-4 (v6.7.0)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SANITIZER="$REPO_ROOT/core/external-input-sanitizer.md"
AGENTS_DIR="$REPO_ROOT/agents"
SKILLS_DIR="$REPO_ROOT/skills"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

# ---------------------------------------------------------------------------
# AC-1: core/external-input-sanitizer.md exists with complete contract
# ---------------------------------------------------------------------------

if [ ! -f "$SANITIZER" ]; then
  fail "core/external-input-sanitizer.md does not exist"
else
  # Required standard sections
  for section in "## Purpose" "## Applies To" "## Process" "## Constraints" "## Failure Mode"; do
    if ! grep -q "$section" "$SANITIZER"; then
      fail "core/external-input-sanitizer.md missing section: $section"
    fi
  done

  # Both marker strings must be documented
  if ! grep -q "EXTERNAL INPUT START" "$SANITIZER"; then
    fail "core/external-input-sanitizer.md missing marker: EXTERNAL INPUT START"
  fi
  if ! grep -q "EXTERNAL INPUT END" "$SANITIZER"; then
    fail "core/external-input-sanitizer.md missing marker: EXTERNAL INPUT END"
  fi

  # At least 3 NEVER constraints (defense-in-depth)
  NEVER_COUNT=$(grep -c "NEVER" "$SANITIZER" || true)
  if [ "$NEVER_COUNT" -lt 3 ]; then
    fail "core/external-input-sanitizer.md has only $NEVER_COUNT NEVER constraint(s) (expected >= 3)"
  fi
fi

# ---------------------------------------------------------------------------
# AC-2: All 5 pipeline skills reference core/external-input-sanitizer
# ---------------------------------------------------------------------------

SKILLS_TO_CHECK=(
  "fix-ticket"
  "fix-bugs"
  "implement-feature"
  "scaffold"
  "analyze-bug"
)

for skill in "${SKILLS_TO_CHECK[@]}"; do
  skill_file="$SKILLS_DIR/${skill}/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    fail "skills/${skill}/SKILL.md does not exist (cannot check sanitizer reference)"
  elif ! grep -q "core/external-input-sanitizer" "$skill_file"; then
    fail "skills/${skill}/SKILL.md does not reference core/external-input-sanitizer"
  fi
done

# ---------------------------------------------------------------------------
# AC-3: All 5 agents have the NEVER constraint with both marker texts
# ---------------------------------------------------------------------------

AGENTS_TO_CHECK=(
  "triage-analyst"
  "code-analyst"
  "fixer"
  "spec-analyst"
  "reviewer"
)

for agent in "${AGENTS_TO_CHECK[@]}"; do
  agent_file="$AGENTS_DIR/${agent}.md"
  if [ ! -f "$agent_file" ]; then
    fail "agents/${agent}.md does not exist (cannot check EXTERNAL INPUT constraint)"
  else
    # Must contain EXTERNAL INPUT START marker
    if ! grep -q "EXTERNAL INPUT START" "$agent_file"; then
      fail "agents/${agent}.md missing EXTERNAL INPUT START marker"
    fi

    # Must contain EXTERNAL INPUT END marker
    if ! grep -q "EXTERNAL INPUT END" "$agent_file"; then
      fail "agents/${agent}.md missing EXTERNAL INPUT END marker"
    fi

    # The line(s) referencing the start marker must use NEVER (imperative language)
    if ! grep "EXTERNAL INPUT START" "$agent_file" | grep -q "NEVER"; then
      fail "agents/${agent}.md: constraint referencing EXTERNAL INPUT START does not use NEVER"
    fi
  fi
done

# ---------------------------------------------------------------------------
# AC-4: CLAUDE.md core count = 14
# ---------------------------------------------------------------------------

# Count actual .md files in core/
ACTUAL_COUNT=$(ls "$REPO_ROOT/core/"*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$ACTUAL_COUNT" -ne 14 ]; then
  fail "core/ directory contains $ACTUAL_COUNT .md files (expected 14)"
fi

# CLAUDE.md must declare 14 shared core contracts
CLAIMED=$(grep '`core/`' "$CLAUDE_MD" | grep 'shared' | grep -oE '[0-9]+' | head -1)
if [ -z "$CLAIMED" ]; then
  fail "Could not find numeric count claim for core/ in CLAUDE.md (expected pattern: '14 shared pipeline pattern contracts')"
elif [ "$CLAIMED" -ne 14 ]; then
  fail "CLAUDE.md claims $CLAIMED core contracts but expected 14"
fi

# ---------------------------------------------------------------------------

[ "$FAIL" -eq 0 ] && echo "PASS: Prompt injection protection — external-input-sanitizer contract, skill refs, agent constraints, CLAUDE.md count all valid"
exit "$FAIL"
