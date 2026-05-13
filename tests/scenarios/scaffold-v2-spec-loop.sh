#!/bin/bash
# Test: Scaffold v2 spec-writer/spec-reviewer iteration loop
# Validates: loop mechanics are defined, max iterations referenced, APPROVE/REVISE verdicts
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"
SPEC_WRITER="$REPO_ROOT/agents/spec-writer.md"
SPEC_REVIEWER="$REPO_ROOT/agents/spec-reviewer.md"

# Verify spec-writer has Block Comment Template
if ! grep -q "Pipeline Block" "$SPEC_WRITER"; then
  echo "FAIL: spec-writer.md missing Block Comment Template"
  exit 1
fi

# Verify spec-reviewer has APPROVE/REVISE verdict
if ! grep -q "APPROVE" "$SPEC_REVIEWER"; then
  echo "FAIL: spec-reviewer.md missing APPROVE verdict"
  exit 1
fi
if ! grep -q "REVISE" "$SPEC_REVIEWER"; then
  echo "FAIL: spec-reviewer.md missing REVISE verdict"
  exit 1
fi

# Verify scaffold command references Spec iterations
if ! grep -q "Spec iterations" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Spec iterations reference"
  exit 1
fi

# Verify scaffold command defines the loop: spec-writer -> spec-reviewer -> iterate
if ! grep -q "spec-writer.*spec-reviewer loop" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing spec-writer/spec-reviewer loop definition"
  exit 1
fi

# Verify max_iterations exhaustion handling
if ! grep -q "max_iterations exhausted" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing max iterations exhaustion handling"
  exit 1
fi

# Verify CLAUDE.md has Spec iterations in Retry Limits
if ! grep -q "Spec iterations" "$REPO_ROOT/CLAUDE.md"; then
  echo "FAIL: CLAUDE.md missing Spec iterations in Retry Limits"
  exit 1
fi

echo "PASS: Scaffold v2 spec-writer/spec-reviewer loop mechanics verified"
