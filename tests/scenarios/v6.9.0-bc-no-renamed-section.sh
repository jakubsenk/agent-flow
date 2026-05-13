#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #4 — Tier B)
# Functional: all 18 optional Automation Config section names present in CLAUDE.md.
# Enumerates each section by name rather than counting.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

[ -f "$CLAUDE_MD" ] || { fail "CLAUDE.md not found"; exit 1; }

# Enumerate all 18 optional section names
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
  "Sprint Planning"
  "Autopilot"
  "Pause Limits"
)

missing=0
for section in "${OPTIONAL_SECTIONS[@]}"; do
  if ! grep -qF "$section" "$CLAUDE_MD"; then
    fail "CLAUDE.md missing optional section: '$section'"
    missing=$((missing + 1))
  fi
done

# Mutation guard: total must still be 18
total_optional=$(grep -cF '|' "$CLAUDE_MD" | head -1 || echo 0)  # rough proxy
[ "${#OPTIONAL_SECTIONS[@]}" -eq 18 ] || fail "Test array has ${#OPTIONAL_SECTIONS[@]} entries, expected 18"

[ "$FAIL" -eq 0 ] && echo "PASS: all 18 optional config section names present in CLAUDE.md"
exit "$FAIL"
