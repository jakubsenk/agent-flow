#!/usr/bin/env bash
# Test: Every required config key from CLAUDE.md is consumed by at least one command
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILLS_DIR="$REPO_ROOT/skills"
[ -d "$SKILLS_DIR" ] || { echo "FAIL: skills/ directory not found"; exit 1; }

# Required keys from CLAUDE.md Config Contract:
# Issue Tracker: Type, Instance, Project, Bug query, State transitions, On start set
# Source Control: Remote, Base branch, Branch naming
# PR Rules: Labels
# Build & Test: Build command, Test command
# (PR Description Template is a subsection, not a key — excluded from key search)
REQUIRED_KEYS=(
  "Type"
  "Instance"
  "Project"
  "Bug query"
  "State transitions"
  "On start set"
  "Remote"
  "Base branch"
  "Branch naming"
  "Labels"
  "Build command"
  "Test command"
)

for key in "${REQUIRED_KEYS[@]}"; do
  # Search all skills/*/SKILL.md for the key (case-insensitive)
  matches=$(find "$SKILLS_DIR" -name 'SKILL.md' -exec grep -il "$key" {} \; 2>/dev/null || true)
  if [ -n "$matches" ]; then
    skill_names=$(echo "$matches" | sed 's|.*/skills/\([^/]*\)/SKILL.md|\1|g' | tr '\n' ' ')
    echo "OK: required key '$key' referenced in: $skill_names"
  else
    fail "required key '$key' not found in any skill"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: all required config keys are consumed by at least one command"
exit "$FAIL"
