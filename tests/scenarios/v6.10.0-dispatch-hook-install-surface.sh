#!/usr/bin/env bash
# AC: AC-T2-6-1, AC-T2-6-2, AC-T2-6-3
# Asserts hooks/validate-dispatch.sh exists at plugin root,
# skills/setup-mcp/SKILL.md has NO auto-install mention,
# and check-setup advisory line is present.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# AC-T2-6-1: hook script exists at plugin root
[ -f "$REPO_ROOT/hooks/validate-dispatch.sh" ] || fail "hooks/validate-dispatch.sh missing at plugin root"

# AC-T2-6-2: init/SKILL.md must NOT mention auto-install of PostToolUse/validate-dispatch
INIT="$REPO_ROOT/skills/setup-mcp/SKILL.md"
if [ -f "$INIT" ]; then
  if grep -qiE 'PostToolUse|validate-dispatch' "$INIT"; then
    fail "skills/setup-mcp/SKILL.md must NOT auto-install PostToolUse hook (forbidden per REQ-T2-6)"
  fi
fi

# AC-T2-6-3: check-setup advisory line
CHECK_SETUP="$REPO_ROOT/skills/check-setup/SKILL.md"
[ -f "$CHECK_SETUP" ] || { fail "skills/check-setup/SKILL.md not found"; exit 1; }
if ! grep -qF 'validate-dispatch' "$CHECK_SETUP"; then
  fail "skills/check-setup/SKILL.md missing advisory line for validate-dispatch hook"
fi
# Advisory context: should NOT contain blocking language
advisory_line=$(grep -n 'validate-dispatch' "$CHECK_SETUP" | head -3)
if echo "$advisory_line" | grep -qiE '\bblock\b|\berror\b|\bfail\b'; then
  fail "check-setup advisory for validate-dispatch must be non-blocking"
fi

echo "PASS: hook installation surface verified"
exit "$FAIL"
