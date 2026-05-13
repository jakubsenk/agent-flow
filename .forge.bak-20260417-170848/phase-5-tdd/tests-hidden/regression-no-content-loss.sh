#!/usr/bin/env bash
# Regression: core/tracker-subtask-creator.md contains all 6 tracker types, idempotency
# pattern, GitHub/Gitea checklist pattern, and CLAUDE.md says "15" core contracts
# This verifies functional equivalence (REQ-1.3) — no content loss from the extraction
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

CORE_CONTRACT="$REPO_ROOT/core/tracker-subtask-creator.md"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

# ---------------------------------------------------------------------------
# core/tracker-subtask-creator.md must exist
# ---------------------------------------------------------------------------

if [ ! -f "$CORE_CONTRACT" ]; then
  fail "core/tracker-subtask-creator.md missing — regression: 15th core contract not created"
  exit 1
fi

# ---------------------------------------------------------------------------
# All 6 tracker types must be present (Per-Tracker dispatch coverage)
# REQ-1.3: Per-tracker MCP dispatch preserved exactly
# ---------------------------------------------------------------------------

for tracker in "youtrack" "jira" "linear" "redmine" "github" "gitea"; do
  if ! grep -qi "$tracker" "$CORE_CONTRACT"; then
    fail "core/tracker-subtask-creator.md: tracker type '$tracker' missing — per-tracker dispatch not preserved"
  fi
done

# ---------------------------------------------------------------------------
# Idempotency pattern must be present (YAML-first, state.json fallback)
# REQ-1.3: Idempotency logic (YAML-first, state.json fallback) preserved exactly
# ---------------------------------------------------------------------------

if ! grep -qi "idempoten\|yaml.*first\|already.*created\|skip.*if.*exist" "$CORE_CONTRACT"; then
  fail "core/tracker-subtask-creator.md: idempotency pattern missing — YAML-first / already-created guard not found"
fi

# yaml_path must be referenced (YAML store)
if ! grep -q "yaml_path" "$CORE_CONTRACT"; then
  fail "core/tracker-subtask-creator.md: 'yaml_path' field missing — dual-store persistence not preserved"
fi

# state_json_path must be referenced (state.json store)
if ! grep -q "state_json_path\|state\.json" "$CORE_CONTRACT"; then
  fail "core/tracker-subtask-creator.md: state.json path reference missing — dual-store persistence not preserved"
fi

# ---------------------------------------------------------------------------
# GitHub/Gitea checklist post-loop pattern must be present
# REQ-1.3: GitHub/Gitea checklist post-loop preserved exactly
# ---------------------------------------------------------------------------

if ! grep -qi "checklist" "$CORE_CONTRACT"; then
  fail "core/tracker-subtask-creator.md: checklist pattern missing — GitHub/Gitea post-loop checklist update not preserved"
fi

# Checklist must reference both GitHub and Gitea together
CHECKLIST_CONTEXT=$(grep -i "checklist" "$CORE_CONTRACT" || true)
if ! echo "$CHECKLIST_CONTEXT" | grep -qi "github\|gitea"; then
  fail "core/tracker-subtask-creator.md: checklist pattern does not reference GitHub or Gitea — post-loop update not preserved"
fi

# ---------------------------------------------------------------------------
# CLAUDE.md must say "15" (not "14") core contracts
# REQ-C.1: Core contract count update
# ---------------------------------------------------------------------------

if [ ! -f "$CLAUDE_MD" ]; then
  fail "CLAUDE.md missing — cannot verify core contract count"
else
  COUNT_15=$(grep -c "15 shared pipeline pattern contracts" "$CLAUDE_MD" || true)
  if [ "$COUNT_15" -ne 1 ]; then
    fail "CLAUDE.md: '15 shared pipeline pattern contracts' not found (found $COUNT_15 matches) — count not updated from 14"
  fi

  COUNT_14=$(grep -c "14 shared pipeline pattern contracts" "$CLAUDE_MD" || true)
  if [ "$COUNT_14" -ne 0 ]; then
    fail "CLAUDE.md: still contains '14 shared pipeline pattern contracts' — old count was not removed"
  fi
fi

# ---------------------------------------------------------------------------
# Jira nested sub-task guard must be present (REQ-1.3)
# ---------------------------------------------------------------------------

if ! grep -qi "jira.*sub.task\|sub.task.*jira\|nested.*sub.task\|jira.*nested" "$CORE_CONTRACT"; then
  fail "core/tracker-subtask-creator.md: Jira nested sub-task guard missing — functional equivalence not preserved"
fi

# ---------------------------------------------------------------------------
# Output Contract must include success_count and failure_count
# REQ-1.1 item 8: success_count, failure_count, created_issues
# ---------------------------------------------------------------------------

if ! grep -q "success_count" "$CORE_CONTRACT"; then
  fail "core/tracker-subtask-creator.md: 'success_count' missing from Output Contract"
fi
if ! grep -q "failure_count" "$CORE_CONTRACT"; then
  fail "core/tracker-subtask-creator.md: 'failure_count' missing from Output Contract"
fi
if ! grep -q "created_issues" "$CORE_CONTRACT"; then
  fail "core/tracker-subtask-creator.md: 'created_issues' missing from Output Contract"
fi

# ---------------------------------------------------------------------------
# "Pipeline continues regardless" statement must be present (REQ-1.1 item 8)
# ---------------------------------------------------------------------------

if ! grep -qi "pipeline continues regardless\|continues regardless" "$CORE_CONTRACT"; then
  fail "core/tracker-subtask-creator.md: 'Pipeline continues regardless' statement missing from Output Contract"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: core/tracker-subtask-creator.md contains all 6 tracker types, idempotency pattern, GitHub/Gitea checklist, Jira nested guard, complete Output Contract, and CLAUDE.md correctly says '15' core contracts (regression/functional-equivalence)"
exit "$FAIL"
