#!/usr/bin/env bash
# v9.3.0 TDD — tests written before implementation
# T-03: Scaffold add subcommand (AC-021 through AC-024)
#
# Tests that /scaffold add <component> is properly wired in skills/scaffold/SKILL.md
# and that the original new-project flow is unaffected.
#
# RED until Phase 7 implementation is complete — that is correct TDD behavior.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
[ -f "$REPO_ROOT/tests/lib/fixtures.sh" ] || REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

SCRATCH="$(setup_scratch)"
trap "rm -rf '$SCRATCH'" EXIT

SKILL="$REPO_ROOT/skills/scaffold/SKILL.md"

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Prerequisite: scaffold skill must exist
# ---------------------------------------------------------------------------
if [ ! -f "$SKILL" ]; then
  echo "FAIL: skills/scaffold/SKILL.md does not exist" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# AC-021: /scaffold add <component> subcommand dispatch present
# Verify: FIRST_TOKEN = "add" detection block exists in skill body
# ---------------------------------------------------------------------------
echo "--- AC-021: 'add' subcommand dispatch block present ---"
if grep -qF 'FIRST_TOKEN' "$SKILL"; then
  echo "PASS: FIRST_TOKEN variable found in scaffold/SKILL.md"
else
  fail "AC-021 — FIRST_TOKEN subcommand detection not found in skills/scaffold/SKILL.md"
fi

if grep -qF '"add"' "$SKILL" || grep -qF "\"add\"" "$SKILL"; then
  echo "PASS: 'add' subcommand check found"
else
  fail "AC-021 — 'add' subcommand check not found in skills/scaffold/SKILL.md"
fi

# ---------------------------------------------------------------------------
# AC-021: Supported components are all present in the dispatch
# Components: claude-md, ci, docker, tests
# ---------------------------------------------------------------------------
echo "--- AC-021: All 4 supported components present ---"
for component in "claude-md" "ci" "docker" "tests"; do
  if grep -qF "$component" "$SKILL"; then
    echo "PASS: component '$component' found in scaffold/SKILL.md"
  else
    fail "AC-021 — component '$component' not found in skills/scaffold/SKILL.md"
  fi
done

# ---------------------------------------------------------------------------
# AC-021: Dispatches scaffolder agent with component
# The subcommand body must reference the scaffolder agent (or COMPONENT variable)
# ---------------------------------------------------------------------------
echo "--- AC-021: Subcommand body references scaffolder dispatch ---"
if grep -qF 'COMPONENT' "$SKILL"; then
  echo "PASS: COMPONENT variable found in scaffold/SKILL.md"
else
  fail "AC-021 — COMPONENT variable not found (scaffolder dispatch via component)"
fi

# ---------------------------------------------------------------------------
# AC-022: /scaffold add (no component) → [ERROR] with usage hint
# ---------------------------------------------------------------------------
echo "--- AC-022: Missing component → [ERROR] with usage hint ---"
if grep -qF 'Usage: /ceos-agents:scaffold add' "$SKILL"; then
  echo "PASS: 'Usage: /ceos-agents:scaffold add <component>' error text found"
else
  fail "AC-022 — '[ERROR] Usage: /ceos-agents:scaffold add <component>' not found"
fi

if grep -qF 'Supported components' "$SKILL"; then
  echo "PASS: 'Supported components' list reference found"
else
  fail "AC-022 — 'Supported components' list not found in error output"
fi

# ---------------------------------------------------------------------------
# AC-023: Unknown component → [ERROR] Unknown component
# ---------------------------------------------------------------------------
echo "--- AC-023: Unknown component → [ERROR] ---"
if grep -qF 'Unknown component' "$SKILL"; then
  echo "PASS: 'Unknown component' error message found"
else
  fail "AC-023 — '[ERROR] Unknown component: {COMPONENT}' not found in scaffold/SKILL.md"
fi

# ---------------------------------------------------------------------------
# AC-024: Without 'add' keyword → original new-project flow runs
# Verify that the subcommand block short-circuits (exits) before flag parsing
# and does NOT pollute the new-project flow.
# Check that the Step 0 — Subcommand dispatch heading exists.
# ---------------------------------------------------------------------------
echo "--- AC-024: Subcommand dispatch is a distinct Step 0 ---"
if grep -qF 'Subcommand dispatch' "$SKILL"; then
  echo "PASS: 'Subcommand dispatch' step heading found (dispatch is separate section)"
else
  fail "AC-024 — 'Subcommand dispatch' step heading not found; subcommand may bleed into new-project flow"
fi

# The dispatch block must exit after the add branch — look for explicit exit or break
if grep -qE 'exit [01]|exit \$' "$SKILL"; then
  echo "PASS: exit statement found (ensures subcommand does not fall through)"
else
  fail "AC-024 — No exit statement found after subcommand branch — may bleed into new-project flow"
fi

# ---------------------------------------------------------------------------
# AC-024: Frontmatter description updated to mention 'add <component>'
# ---------------------------------------------------------------------------
echo "--- AC-024: Frontmatter description updated to mention add subcommand ---"
if grep -qF "add <component>" "$SKILL" || grep -qF "add '<component>'" "$SKILL"; then
  echo "PASS: 'add <component>' mentioned in scaffold/SKILL.md (description or body)"
else
  fail "AC-024 — 'add <component>' not mentioned in scaffold/SKILL.md frontmatter or body"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.3.0-scaffold-subcommand — all scaffold add subcommand checks passed"
fi
exit "$FAIL"
