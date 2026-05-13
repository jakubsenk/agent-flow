#!/usr/bin/env bash
# Test: FC-9, FC-10 — 'Create tracker subtasks' config key in CLAUDE.md and docs/reference/automation-config.md
# TDD red phase: expects FAIL on pre-implementation codebase
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
AUTOCONFIG="$REPO_ROOT/docs/reference/automation-config.md"

# -----------------------------------------------------------------------
# FC-9: 'Create tracker subtasks' key present in CLAUDE.md config contract
# REQ-5.1: new optional key in Decomposition section
# -----------------------------------------------------------------------
if [ ! -f "$CLAUDE_MD" ]; then
  fail "FC-9: CLAUDE.md not found"
else
  if ! grep -q 'Create tracker subtasks' "$CLAUDE_MD" 2>/dev/null; then
    fail "FC-9: 'Create tracker subtasks' key not found in CLAUDE.md"
  fi

  # -----------------------------------------------------------------------
  # FC-9: The key must appear in or after the Decomposition section
  # -----------------------------------------------------------------------
  DECOMP_LINE=$(grep -n 'Decomposition' "$CLAUDE_MD" | grep -v '#\|---' | head -1 | cut -d: -f1 || true)
  KEY_LINE=$(grep -n 'Create tracker subtasks' "$CLAUDE_MD" | head -1 | cut -d: -f1 || true)

  if [ -z "$DECOMP_LINE" ]; then
    fail "FC-9: Decomposition section not found in CLAUDE.md config contract"
  elif [ -n "$KEY_LINE" ] && [ "$KEY_LINE" -lt "$DECOMP_LINE" ]; then
    fail "FC-9: 'Create tracker subtasks' (line $KEY_LINE) appears before Decomposition section (line $DECOMP_LINE)"
  fi

  # -----------------------------------------------------------------------
  # FC-9: Default must be 'enabled' (REQ-5.3)
  # -----------------------------------------------------------------------
  key_line=$(grep 'Create tracker subtasks' "$CLAUDE_MD" | head -1 || true)
  if ! echo "$key_line" | grep -q 'enabled'; then
    fail "FC-9: 'Create tracker subtasks' entry in CLAUDE.md does not show default value 'enabled'"
  fi
fi

# -----------------------------------------------------------------------
# FC-10: 'Create tracker subtasks' key present in docs/reference/automation-config.md
# REQ-5.1: new key documented in reference
# -----------------------------------------------------------------------
if [ ! -f "$AUTOCONFIG" ]; then
  fail "FC-10: docs/reference/automation-config.md not found"
else
  if ! grep -q 'Create tracker subtasks' "$AUTOCONFIG" 2>/dev/null; then
    fail "FC-10: 'Create tracker subtasks' key not found in docs/reference/automation-config.md"
  fi

  # -----------------------------------------------------------------------
  # FC-10: Must mention both 'enabled' and 'disabled' values (REQ-5.2)
  # -----------------------------------------------------------------------
  key_context=$(grep -A5 'Create tracker subtasks' "$AUTOCONFIG" 2>/dev/null | head -6 || true)
  if ! echo "$key_context" | grep -q 'enabled'; then
    fail "FC-10: 'Create tracker subtasks' in automation-config.md does not document 'enabled' value"
  fi
  if ! echo "$key_context" | grep -q 'disabled'; then
    fail "FC-10: 'Create tracker subtasks' in automation-config.md does not document 'disabled' value"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: 'Create tracker subtasks' config key present with correct defaults in CLAUDE.md and docs/reference/automation-config.md (FC-9, FC-10)"
exit "$FAIL"
