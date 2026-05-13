#!/usr/bin/env bash
# Regression: Structural markers in all modified files still exist after v6.7.1 changes
# Verifies no content loss in: 5 agent files, 2 skill files, 2 core files, 1 state file
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# ---------------------------------------------------------------------------
# Agent files: Goal, Expertise, Process, Constraints sections must survive
# ---------------------------------------------------------------------------

AGENTS_DIR="$REPO_ROOT/agents"
AGENTS_TO_CHECK=(
  "acceptance-gate"
  "architect"
  "reproducer"
  "priority-engine"
  "browser-verifier"
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
  # Original process steps 1 and 2 must still exist
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
if [ ! -f "$FIX_BUGS" ]; then
  fail "skills/fix-bugs/SKILL.md missing — file deleted"
else
  for marker in '## Orchestration' 'MCP pre-flight check'; do
    if ! grep -q "$marker" "$FIX_BUGS"; then
      fail "skills/fix-bugs/SKILL.md: structural marker '$marker' missing after edits"
    fi
  done
fi

# ---------------------------------------------------------------------------
# skills/implement-feature/SKILL.md: existing pipeline structure must survive
# ---------------------------------------------------------------------------

IMPL_FEATURE="$REPO_ROOT/skills/implement-feature/SKILL.md"
if [ ! -f "$IMPL_FEATURE" ]; then
  fail "skills/implement-feature/SKILL.md missing — file deleted"
else
  for marker in '## Orchestration' 'MCP pre-flight check' '### Step 0b: Config Validity Gate' '### 3\. Spec-analyst' '### 4\. Architect'; do
    if ! grep -q "$marker" "$IMPL_FEATURE"; then
      fail "skills/implement-feature/SKILL.md: structural marker '$marker' missing after edits"
    fi
  done
fi

# ---------------------------------------------------------------------------

[ "$FAIL" -eq 0 ] && echo "PASS: No content loss — all structural markers in modified files survive v6.7.1 changes"
exit "$FAIL"
