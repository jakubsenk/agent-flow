#!/usr/bin/env bash
# Regression: Structural markers in all modified files still exist
# Verifies no content loss in: 5 agent files, 2 skill files, 2 core files, 1 state file
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# ---------------------------------------------------------------------------
# Agent files: Goal, Expertise, Process, Constraints sections must survive
# ---------------------------------------------------------------------------

AGENTS_DIR="$REPO_ROOT/agents"
AGENTS_TO_CHECK=(
  "acceptance-gate"
  "architect"
  "priority-engine"
)

for agent in "${AGENTS_TO_CHECK[@]}"; do
  agent_file="$AGENTS_DIR/${agent}.md"
  if [ ! -f "$agent_file" ]; then
    fail "agents/${agent}.md missing — file deleted"
    continue
  fi
  for section in "## Goal" "## Expertise" "## Process" "## Constraints"; do
    if ! grep -q "$section" "$agent_file"; then
      fail "agents/${agent}.md: structural section '$section' missing after edits"
    fi
  done
  # Frontmatter keys must remain
  for key in "^name:" "^description:" "^model:" "^style:"; do
    if ! grep -q "$key" "$agent_file"; then
      fail "agents/${agent}.md: frontmatter key '$key' missing after edits"
    fi
  done
done

# ---------------------------------------------------------------------------
# core/external-input-sanitizer.md: original sections must survive
# ---------------------------------------------------------------------------

SANITIZER="$REPO_ROOT/core/external-input-sanitizer.md"
if [ ! -f "$SANITIZER" ]; then
  fail "core/external-input-sanitizer.md missing — file deleted"
else
  for section in "## Purpose" "## Applies To" "## Process" "## Output Contract" "## Constraints" "## Failure Mode"; do
    if ! grep -q "$section" "$SANITIZER"; then
      fail "core/external-input-sanitizer.md: section '$section' missing after edits"
    fi
  done
  # Original process steps 1 and 3 must still exist (step 2 is the escape step)
  if ! grep -q '^1\.' "$SANITIZER"; then
    fail "core/external-input-sanitizer.md: original step 1 missing after edits"
  fi
  if ! grep -q '^2\. Wrap each piece' "$SANITIZER"; then
    fail "core/external-input-sanitizer.md: original step 2 'Wrap each piece' missing after edits"
  fi
  # Original marker strings must remain in Output Contract
  if ! grep -q 'EXTERNAL INPUT START' "$SANITIZER"; then
    fail "core/external-input-sanitizer.md: marker 'EXTERNAL INPUT START' missing after edits"
  fi
  if ! grep -q 'EXTERNAL INPUT END' "$SANITIZER"; then
    fail "core/external-input-sanitizer.md: marker 'EXTERNAL INPUT END' missing after edits"
  fi
fi

# ---------------------------------------------------------------------------
# core/state-manager.md: existing steps and plugin_version write must survive
# ---------------------------------------------------------------------------

STATE_MGR="$REPO_ROOT/core/state-manager.md"
if [ ! -f "$STATE_MGR" ]; then
  fail "core/state-manager.md missing — file deleted"
else
  if ! grep -q '## Process' "$STATE_MGR"; then
    fail "core/state-manager.md: '## Process' section missing after edits"
  fi
  if ! grep -q 'plugin_version' "$STATE_MGR"; then
    fail "core/state-manager.md: 'plugin_version' reference missing after edits"
  fi
  if ! grep -q 'plugin.json' "$STATE_MGR"; then
    fail "core/state-manager.md: 'plugin.json' reference missing after edits"
  fi
  if ! grep -q '2a\.' "$STATE_MGR"; then
    fail "core/state-manager.md: step '2a.' missing after edits"
  fi
fi

# ---------------------------------------------------------------------------
# core/config-reader.md: existing Decomposition entry must survive
# ---------------------------------------------------------------------------

CONFIG_READER="$REPO_ROOT/core/config-reader.md"
if [ ! -f "$CONFIG_READER" ]; then
  fail "core/config-reader.md missing — file deleted"
else
  if ! grep -q '## Process' "$CONFIG_READER"; then
    fail "core/config-reader.md: '## Process' section missing after edits"
  fi
  # All original decomposition keys must still be present
  for key in 'decomposition.max_subtasks' 'decomposition.fail_strategy' 'decomposition.commit_strategy'; do
    if ! grep -q "$key" "$CONFIG_READER"; then
      fail "core/config-reader.md: original key '$key' missing after edits"
    fi
  done
fi

# ---------------------------------------------------------------------------
# state/schema.md: original fields must survive
# ---------------------------------------------------------------------------

SCHEMA="$REPO_ROOT/state/schema.md"
if [ ! -f "$SCHEMA" ]; then
  fail "state/schema.md missing — file deleted"
else
  for field in 'plugin_version' 'fixer_iterations' 'test_attempts' 'build_retries'; do
    if ! grep -q "$field" "$SCHEMA"; then
      fail "state/schema.md: original field '$field' missing after edits"
    fi
  done
  # JSON example block must still exist
  if ! grep -q '"schema_version"' "$SCHEMA"; then
    fail "state/schema.md: JSON example block ('schema_version') missing after edits"
  fi
fi

# ---------------------------------------------------------------------------
# skills/fix-bugs/SKILL.md: existing pipeline structure must survive
# ---------------------------------------------------------------------------

FIX_BUGS="$REPO_ROOT/skills/fix-bugs/SKILL.md"
FIX_BUGS_DIR="$REPO_ROOT/skills/fix-bugs"
if [ ! -f "$FIX_BUGS" ]; then
  fail "skills/fix-bugs/SKILL.md missing — file deleted"
else
  # v10 thin-controller: search SKILL.md + steps/*.md aggregate.
  # Use a tmpfile to avoid SIGPIPE under `set -e` when piping large content into grep -q.
  FIX_BUGS_TMP=$(mktemp)
  cat "$FIX_BUGS" > "$FIX_BUGS_TMP"
  [ -d "$FIX_BUGS_DIR/steps" ] && cat "$FIX_BUGS_DIR/steps"/*.md >> "$FIX_BUGS_TMP"
  # Updated markers for v10 layout (pipeline → Step Dispatch table, MCP pre-flight → mcp-preflight reference)
  for marker in 'Step Dispatch|Single-ticket pipeline|single-ticket mode' 'mcp-preflight|MCP pre-flight'; do
    if ! grep -qE "$marker" "$FIX_BUGS_TMP"; then
      fail "skills/fix-bugs/SKILL.md: structural marker '$marker' missing after edits"
    fi
  done
  rm -f "$FIX_BUGS_TMP"
fi

# ---------------------------------------------------------------------------
# skills/implement-feature/SKILL.md: existing pipeline structure must survive
# ---------------------------------------------------------------------------

IMPL_FEATURE="$REPO_ROOT/skills/implement-feature/SKILL.md"
IMPL_FEATURE_DIR="$REPO_ROOT/skills/implement-feature"
if [ ! -f "$IMPL_FEATURE" ]; then
  fail "skills/implement-feature/SKILL.md missing — file deleted"
else
  IMPL_FEATURE_TMP=$(mktemp)
  cat "$IMPL_FEATURE" > "$IMPL_FEATURE_TMP"
  [ -d "$IMPL_FEATURE_DIR/steps" ] && cat "$IMPL_FEATURE_DIR/steps"/*.md >> "$IMPL_FEATURE_TMP"
  for marker in 'Step dispatch|Orchestration' 'mcp-preflight|MCP pre-flight' 'Config Validity Gate|0b.*Config' 'spec-analyst' 'architect'; do
    if ! grep -qE "$marker" "$IMPL_FEATURE_TMP"; then
      fail "skills/implement-feature/SKILL.md: structural marker '$marker' missing after edits"
    fi
  done
  rm -f "$IMPL_FEATURE_TMP"
fi

# ---------------------------------------------------------------------------

[ "$FAIL" -eq 0 ] && echo "PASS: No content loss — all structural markers in modified files survive"
exit "$FAIL"
