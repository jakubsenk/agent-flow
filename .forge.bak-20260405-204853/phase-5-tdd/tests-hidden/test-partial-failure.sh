#!/usr/bin/env bash
# Test: FC-12 — Partial failure accumulator pattern and pipeline-never-blocks guarantee in all 3 skills
# TDD red phase: expects FAIL on pre-implementation codebase
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

IF="$REPO_ROOT/skills/implement-feature/SKILL.md"
FT="$REPO_ROOT/skills/fix-ticket/SKILL.md"
FB="$REPO_ROOT/skills/fix-bugs/SKILL.md"

SKILL_FILES=("$IF" "$FT" "$FB")
SKILL_NAMES=("implement-feature" "fix-ticket" "fix-bugs")

for i in "${!SKILL_FILES[@]}"; do
  f="${SKILL_FILES[$i]}"
  name="${SKILL_NAMES[$i]}"

  if [ ! -f "$f" ]; then
    fail "$name: skill file not found"
    continue
  fi

  # -----------------------------------------------------------------------
  # FC-12: Pipeline NEVER blocks on tracker creation failure
  # REQ-6.4: the step must explicitly state pipeline continues regardless
  # -----------------------------------------------------------------------
  if ! grep -qE 'NEVER block|never block|Pipeline continues|pipeline continues|pipeline.*never.*block' "$f" 2>/dev/null; then
    fail "FC-12 ($name): missing 'NEVER block' or 'Pipeline continues' guarantee for tracker creation failure (REQ-6.4)"
  fi

  # -----------------------------------------------------------------------
  # FC-12: Result display format: "Created {N}/{M} tracker sub-issues"
  # REQ-6.2: after loop, display Created N/M tracker sub-issues ({F} failures)
  # -----------------------------------------------------------------------
  if ! grep -qE 'Created.*tracker sub-issues|tracker sub-issues.*Created' "$f" 2>/dev/null; then
    fail "FC-12 ($name): missing result display 'Created {N}/{M} tracker sub-issues' after creation loop (REQ-6.2)"
  fi

  # -----------------------------------------------------------------------
  # FC-12: Per-subtask WARN on failure (accumulator pattern)
  # REQ-6.1: on individual failure, WARN and continue (not block)
  # -----------------------------------------------------------------------
  if ! grep -qE 'WARN.*Could not create|Could not create.*WARN|Could not create tracker sub-issue' "$f" 2>/dev/null; then
    fail "FC-12 ($name): missing per-subtask WARN for individual tracker creation failure (REQ-6.1)"
  fi

  # -----------------------------------------------------------------------
  # FC-12: 100% failure escalation WARN
  # REQ-6.3: if all fail (N==0), elevated WARN about MCP connectivity
  # -----------------------------------------------------------------------
  if ! grep -qE 'All.*tracker.*sub-issue.*fail|all.*tracker.*fail|Check MCP|tracker.*connectivity|MCP.*connect' "$f" 2>/dev/null; then
    fail "FC-12 ($name): missing 100% failure escalation WARN mentioning connectivity or MCP (REQ-6.3)"
  fi

  # -----------------------------------------------------------------------
  # FC-12: GitHub/Gitea parent body update failure handling
  # REQ-6.5: if checklist append fails, WARN and continue
  # -----------------------------------------------------------------------
  if ! grep -qE 'Could not update.*parent issue body|parent issue body.*fail|checklist.*fail.*continue|Could not update.*checklist' "$f" 2>/dev/null; then
    fail "FC-12 ($name): missing GitHub/Gitea parent body update failure WARN (REQ-6.5)"
  fi

done

[ "$FAIL" -eq 0 ] && echo "PASS: Partial failure accumulator pattern (per-subtask WARN, result display, 100% failure escalation, pipeline-never-blocks, checklist failure handling) in all 3 skills (FC-12)"
exit "$FAIL"
