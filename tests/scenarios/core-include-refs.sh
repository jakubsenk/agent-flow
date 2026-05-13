#!/usr/bin/env bash
# Test: Core pattern files exist with contracts, pipeline commands reference them
# PR 2-3: Core extraction
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# 1. All 10 core files exist
CORE_FILES=(
  config-reader
  mcp-preflight
  mcp-detection
  fixer-reviewer-loop
  block-handler
  agent-override-injector
  decomposition-heuristics
  profile-parser
  post-publish-hook
  fix-verification
  state-manager
)

for name in "${CORE_FILES[@]}"; do
  if [ ! -f "$REPO_ROOT/core/${name}.md" ]; then
    fail "core/${name}.md does not exist"
  fi
done

# 2. Each core file has 4 standard sections
for name in "${CORE_FILES[@]}"; do
  f="$REPO_ROOT/core/${name}.md"
  [ ! -f "$f" ] && continue
  for section in "## Purpose" "## Input" "## Output" "## Failure"; do
    if ! grep -q "$section" "$f"; then
      fail "core/${name}.md missing section: $section"
    fi
  done
done

# 3. Pipeline commands reference core/ files
check_refs() {
  local cmd="$1"
  local min="$2"
  local f="$REPO_ROOT/skills/${cmd}/SKILL.md"
  if [ ! -f "$f" ]; then
    fail "skills/${cmd}/SKILL.md does not exist"
    return
  fi
  local count
  count=$(grep -c 'core/' "$f" || true)
  if [ "$count" -lt "$min" ]; then
    fail "skills/${cmd}/SKILL.md has $count core/ references (expected >= $min)"
  fi
}

# All 3 pipeline commands reference core (fix-ticket removed in v9.3.0)
check_refs "fix-bugs" 7
check_refs "implement-feature" 6
check_refs "scaffold" 3

[ "$FAIL" -eq 0 ] && echo "PASS: Core pattern files exist with contracts, all 4 pipeline commands reference core/"
exit "$FAIL"
