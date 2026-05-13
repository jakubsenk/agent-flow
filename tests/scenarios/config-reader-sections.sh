#!/usr/bin/env bash
# Test: Optional sections in CLAUDE.md match sections in core/config-reader.md
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
CONFIG_READER="$REPO_ROOT/core/config-reader.md"

[ -f "$CLAUDE_MD" ]      || { echo "FAIL: CLAUDE.md not found"; exit 1; }
[ -f "$CONFIG_READER" ]  || { echo "FAIL: core/config-reader.md not found"; exit 1; }

# Optional section names from CLAUDE.md (table under "Optional sections:")
OPTIONAL_SECTIONS=(
  "Retry Limits"
  "Module Docs"
  "Hooks"
  "Custom Agents"
  "Notifications"
  "Worktrees"
  "E2E Test"
  "Browser Verification"
  "Error Handling"
  "Feature Workflow"
  "Decomposition"
  "Pipeline Profiles"
  "Metrics"
  "Agent Overrides"
  "Local Deployment"
)

# Verify each optional section is present in CLAUDE.md's optional sections table
for section in "${OPTIONAL_SECTIONS[@]}"; do
  if grep -q "$section" "$CLAUDE_MD"; then
    echo "OK: '$section' present in CLAUDE.md"
  else
    fail "'$section' not found in CLAUDE.md"
  fi
done

# Verify each optional section is mentioned in core/config-reader.md
# (either as ### heading or as plain text reference)
missing_in_reader=()
for section in "${OPTIONAL_SECTIONS[@]}"; do
  if grep -qi "$section" "$CONFIG_READER"; then
    echo "OK: '$section' present in core/config-reader.md"
  else
    fail "'$section' found in CLAUDE.md optional sections but NOT in core/config-reader.md"
    missing_in_reader+=("$section")
  fi
done

if [ ${#missing_in_reader[@]} -gt 0 ]; then
  echo ""
  echo "Sections in CLAUDE.md but missing from core/config-reader.md:"
  for s in "${missing_in_reader[@]}"; do
    echo "  - $s"
  done
fi

[ "$FAIL" -eq 0 ] && echo "PASS: all optional sections in CLAUDE.md are covered by core/config-reader.md"
exit "$FAIL"
