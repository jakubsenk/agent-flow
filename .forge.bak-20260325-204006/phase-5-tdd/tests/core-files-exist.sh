#!/usr/bin/env bash
# Test: core/ directory exists with all 10 expected files
# Validates: AC-2.1 — core/ contains exactly 10 .md files
# PR 2-3: Core extraction
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# core/ directory must exist
if [ ! -d "$REPO_ROOT/core" ]; then
  fail "core/ directory does not exist"
  exit 1
fi

# All 10 expected core files must be present (from requirements.md section 2.1)
CORE_FILES=(
  config-reader.md
  mcp-preflight.md
  fixer-reviewer-loop.md
  block-handler.md
  agent-override-injector.md
  decomposition-heuristics.md
  profile-parser.md
  post-publish-hook.md
  fix-verification.md
  state-manager.md
)

for f in "${CORE_FILES[@]}"; do
  if [ ! -f "$REPO_ROOT/core/$f" ]; then
    fail "Missing core file: core/$f"
  fi
done

# Verify total count is exactly 10
actual_count=$(ls "$REPO_ROOT/core/"*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$actual_count" -ne 10 ]; then
  fail "core/ contains $actual_count .md files, expected exactly 10"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: core/ directory exists with all 10 expected files"
exit "$FAIL"
