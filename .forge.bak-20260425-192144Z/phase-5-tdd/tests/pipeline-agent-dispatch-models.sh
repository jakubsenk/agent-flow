#!/usr/bin/env bash
# AC: AC-T2-1-1, AC-T2-1-2
# Test: Every agent dispatched via Task tool in pipeline commands uses the correct model.
# v6.10.0 MODIFY: Updated grep pattern at line 92 to match both old and new Layer 1 prose.
# Pattern matches: "Task tool, model:" (old) OR "Task(subagent_type='ceos-agents:" (new imperative)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Map: agent name → expected model (from CLAUDE.md model table)
declare -A EXPECTED_MODEL
EXPECTED_MODEL[triage-analyst]=sonnet
EXPECTED_MODEL[code-analyst]=sonnet
EXPECTED_MODEL[fixer]=opus
EXPECTED_MODEL[reviewer]=opus
EXPECTED_MODEL[acceptance-gate]=sonnet
EXPECTED_MODEL[test-engineer]=sonnet
EXPECTED_MODEL[e2e-test-engineer]=sonnet
EXPECTED_MODEL[publisher]=haiku
EXPECTED_MODEL[rollback-agent]=haiku
EXPECTED_MODEL[spec-analyst]=sonnet
EXPECTED_MODEL[architect]=opus
EXPECTED_MODEL[stack-selector]=sonnet
EXPECTED_MODEL[scaffolder]=sonnet
EXPECTED_MODEL[priority-engine]=opus
EXPECTED_MODEL[spec-writer]=opus
EXPECTED_MODEL[spec-reviewer]=opus
EXPECTED_MODEL[reproducer]=sonnet
EXPECTED_MODEL[browser-verifier]=sonnet
EXPECTED_MODEL[deployment-verifier]=sonnet
EXPECTED_MODEL[backlog-creator]=sonnet
EXPECTED_MODEL[sprint-planner]=sonnet

# Scan each pipeline skill for agent dispatch lines (old or new imperative form)
for cmd_file in \
  "$REPO_ROOT/skills/fix-ticket/SKILL.md" \
  "$REPO_ROOT/skills/fix-bugs/SKILL.md" \
  "$REPO_ROOT/skills/implement-feature/SKILL.md" \
  "$REPO_ROOT/skills/scaffold/SKILL.md" \
  "$REPO_ROOT/core/fixer-reviewer-loop.md"
do
  [ -f "$cmd_file" ] || { fail "Missing skill file: $cmd_file"; continue; }

  # AC-T2-1-1: grep pattern must match at least one dispatch site per skill
  # Defensive pattern: matches both old prose and new imperative template
  match_count=$(grep -cE "Task tool, model:|Task\(subagent_type='ceos-agents:" "$cmd_file" 2>/dev/null || echo 0)
  [ "$match_count" -ge 1 ] || fail "No dispatch sites found in $cmd_file (neither old nor new form)"

  # For each dispatch line found (both patterns), extract agent name and model
  while IFS= read -r line; do
    agent_name=""
    model_in_line=""
    # Old form: "Task tool, model: opus" + nearby agent name
    if echo "$line" | grep -qF 'Task tool, model:'; then
      model_in_line=$(echo "$line" | grep -oE 'model: (opus|sonnet|haiku)' | cut -d' ' -f2)
      agent_name=$(echo "$line" | grep -oE "ceos-agents:[a-z-]+" | cut -d: -f2)
    fi
    # New imperative form: Task(subagent_type='ceos-agents:AGENTNAME')
    if echo "$line" | grep -qE "Task\(subagent_type='ceos-agents:"; then
      agent_name=$(echo "$line" | grep -oE "subagent_type='ceos-agents:[a-z-]+" | cut -d: -f2)
      # Model may be on a separate model= param
      model_in_line=$(echo "$line" | grep -oE "model='?(opus|sonnet|haiku)" | grep -oE 'opus|sonnet|haiku' | head -1)
    fi
    [ -z "$agent_name" ] && continue
    [ -z "$model_in_line" ] && continue
    expected="${EXPECTED_MODEL[$agent_name]:-}"
    [ -z "$expected" ] && continue
    if [ "$model_in_line" != "$expected" ]; then
      fail "$(basename "$cmd_file"): $agent_name dispatched with model $model_in_line (expected $expected)"
    fi
  done < <(grep -E "Task tool, model:|Task\(subagent_type='ceos-agents:" "$cmd_file" 2>/dev/null || true)
done

[ "$FAIL" -eq 0 ] && echo "PASS: All pipeline dispatch sites use correct agent models"
exit "$FAIL"
