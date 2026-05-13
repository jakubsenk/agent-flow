#!/usr/bin/env bash
# Test: FC-1, FC-2, FC-3 — New step exists in all 3 skill files at the correct position
# TDD red phase: expects FAIL on pre-implementation codebase
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

IF="$REPO_ROOT/skills/implement-feature/SKILL.md"
FT="$REPO_ROOT/skills/fix-ticket/SKILL.md"
FB="$REPO_ROOT/skills/fix-bugs/SKILL.md"

for f in "$IF" "$FT" "$FB"; do
  if [ ! -f "$f" ]; then
    fail "Required skill file not found: $f"
    exit 1
  fi
done

# -----------------------------------------------------------------------
# FC-1: implement-feature must have "### 5a." step heading
#   - Must appear AFTER the line containing "### 5." (Decomposition decision)
#   - Must appear BEFORE the line containing "### 6." (Subtask execution)
# -----------------------------------------------------------------------

STEP5_LINE=$(grep -n '^### 5\.' "$IF" | head -1 | cut -d: -f1 || true)
STEP5A_LINE=$(grep -n '^### 5a\.' "$IF" | head -1 | cut -d: -f1 || true)
STEP6_LINE=$(grep -n '^### 6\.' "$IF" | head -1 | cut -d: -f1 || true)

if [ -z "$STEP5A_LINE" ]; then
  fail "FC-1: implement-feature/SKILL.md missing '### 5a.' heading (Create tracker subtasks)"
else
  if [ -z "$STEP5_LINE" ]; then
    fail "FC-1: implement-feature/SKILL.md missing '### 5.' heading (Decomposition decision) — cannot verify order"
  elif [ "$STEP5A_LINE" -le "$STEP5_LINE" ]; then
    fail "FC-1: '### 5a.' (line $STEP5A_LINE) must appear AFTER '### 5.' (line $STEP5_LINE)"
  fi

  if [ -z "$STEP6_LINE" ]; then
    fail "FC-1: implement-feature/SKILL.md missing '### 6.' heading (Subtask execution) — cannot verify order"
  elif [ "$STEP5A_LINE" -ge "$STEP6_LINE" ]; then
    fail "FC-1: '### 5a.' (line $STEP5A_LINE) must appear BEFORE '### 6.' (line $STEP6_LINE)"
  fi
fi

# Verify heading text mentions tracker subtasks
if [ -n "$STEP5A_LINE" ]; then
  heading_text=$(grep -n '^### 5a\.' "$IF" | head -1 || true)
  if ! echo "$heading_text" | grep -qi "tracker subtask\|Create tracker"; then
    fail "FC-1: '### 5a.' heading in implement-feature does not mention 'tracker subtask' or 'Create tracker'"
  fi
fi

# -----------------------------------------------------------------------
# FC-2: fix-ticket must have "### 4b-tracker." step heading
#   - Must appear AFTER the line containing "### 4b." (Decomposition decision)
#   - Must appear BEFORE the line containing "### 4c." (Subtask execution)
# -----------------------------------------------------------------------

STEP4B_LINE=$(grep -n '^### 4b\.' "$FT" | head -1 | cut -d: -f1 || true)
STEP4BTRACKER_LINE=$(grep -n '### 4b-tracker' "$FT" | head -1 | cut -d: -f1 || true)
STEP4C_LINE=$(grep -n '^### 4c\.' "$FT" | head -1 | cut -d: -f1 || true)

if [ -z "$STEP4BTRACKER_LINE" ]; then
  fail "FC-2: fix-ticket/SKILL.md missing '### 4b-tracker' heading (Create tracker subtasks)"
else
  if [ -z "$STEP4B_LINE" ]; then
    fail "FC-2: fix-ticket/SKILL.md missing '### 4b.' heading — cannot verify order"
  elif [ "$STEP4BTRACKER_LINE" -le "$STEP4B_LINE" ]; then
    fail "FC-2: '### 4b-tracker' (line $STEP4BTRACKER_LINE) must appear AFTER '### 4b.' (line $STEP4B_LINE)"
  fi

  if [ -z "$STEP4C_LINE" ]; then
    fail "FC-2: fix-ticket/SKILL.md missing '### 4c.' heading — cannot verify order"
  elif [ "$STEP4BTRACKER_LINE" -ge "$STEP4C_LINE" ]; then
    fail "FC-2: '### 4b-tracker' (line $STEP4BTRACKER_LINE) must appear BEFORE '### 4c.' (line $STEP4C_LINE)"
  fi
fi

# -----------------------------------------------------------------------
# FC-3: fix-bugs must have "### 3b-tracker." step heading
#   - Must appear AFTER the line containing "### 3b." (Decomposition decision)
#   - Must appear BEFORE the line containing "### 3c." (Subtask execution)
# -----------------------------------------------------------------------

STEP3B_LINE=$(grep -n '^### 3b\.' "$FB" | head -1 | cut -d: -f1 || true)
STEP3BTRACKER_LINE=$(grep -n '### 3b-tracker' "$FB" | head -1 | cut -d: -f1 || true)
STEP3C_LINE=$(grep -n '^### 3c\.' "$FB" | head -1 | cut -d: -f1 || true)

if [ -z "$STEP3BTRACKER_LINE" ]; then
  fail "FC-3: fix-bugs/SKILL.md missing '### 3b-tracker' heading (Create tracker subtasks)"
else
  if [ -z "$STEP3B_LINE" ]; then
    fail "FC-3: fix-bugs/SKILL.md missing '### 3b.' heading — cannot verify order"
  elif [ "$STEP3BTRACKER_LINE" -le "$STEP3B_LINE" ]; then
    fail "FC-3: '### 3b-tracker' (line $STEP3BTRACKER_LINE) must appear AFTER '### 3b.' (line $STEP3B_LINE)"
  fi

  if [ -z "$STEP3C_LINE" ]; then
    fail "FC-3: fix-bugs/SKILL.md missing '### 3c.' heading — cannot verify order"
  elif [ "$STEP3BTRACKER_LINE" -ge "$STEP3C_LINE" ]; then
    fail "FC-3: '### 3b-tracker' (line $STEP3BTRACKER_LINE) must appear BEFORE '### 3c.' (line $STEP3C_LINE)"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: New tracker subtask creation step exists at correct position in all 3 skills (FC-1, FC-2, FC-3)"
exit "$FAIL"
