#!/usr/bin/env bash
# Test: Each core file has Purpose, Input Contract, Output Contract, Failure Handling sections
# Validates: AC-2.2 — all core files have required section headings
# PR 2-3: Core extraction
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

if [ ! -d "$REPO_ROOT/core" ]; then
  fail "core/ directory does not exist"
  exit 1
fi

REQUIRED_SECTIONS=(
  "## Purpose"
  "## Input"
  "## Output"
  "## Failure"
)

for f in "$REPO_ROOT/core/"*.md; do
  name=$(basename "$f")
  for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "$section" "$f"; then
      fail "core/$name missing required section: $section"
    fi
  done
done

# Specific contract checks from formal criteria:

# AC-4.1: config-reader.md lists all required config sections
CONFIG_READER="$REPO_ROOT/core/config-reader.md"
if [ -f "$CONFIG_READER" ]; then
  for section in "Issue Tracker" "Source Control" "PR Rules" "Build & Test"; do
    if ! grep -q "$section" "$CONFIG_READER"; then
      fail "core/config-reader.md missing config section reference: $section"
    fi
  done
fi

# AC-4.2: fixer-reviewer-loop.md specifies iteration limit (default 5)
LOOP_FILE="$REPO_ROOT/core/fixer-reviewer-loop.md"
if [ -f "$LOOP_FILE" ]; then
  if ! grep -qi "iteration" "$LOOP_FILE"; then
    fail "core/fixer-reviewer-loop.md missing iteration limit reference"
  fi
  if ! grep -q "5" "$LOOP_FILE"; then
    fail "core/fixer-reviewer-loop.md missing default iteration count (5)"
  fi
fi

# AC-4.3: block-handler.md uses correct block comment prefix with emoji
BLOCK_FILE="$REPO_ROOT/core/block-handler.md"
if [ -f "$BLOCK_FILE" ]; then
  if ! grep -q '\[ceos-agents\].*Pipeline Block' "$BLOCK_FILE"; then
    fail "core/block-handler.md missing [ceos-agents] Pipeline Block comment template"
  fi
  if ! grep -q '🔴' "$BLOCK_FILE"; then
    fail "core/block-handler.md block comment template missing 🔴 emoji"
  fi
fi

# AC-4.6: decomposition-heuristics.md contains threshold values (HIGH, 4, 60)
DECOMP_FILE="$REPO_ROOT/core/decomposition-heuristics.md"
if [ -f "$DECOMP_FILE" ]; then
  if ! grep -q "HIGH" "$DECOMP_FILE"; then
    fail "core/decomposition-heuristics.md missing HIGH risk threshold"
  fi
  if ! grep -q "4" "$DECOMP_FILE"; then
    fail "core/decomposition-heuristics.md missing affected_files_count >= 4 threshold"
  fi
  if ! grep -q "60" "$DECOMP_FILE"; then
    fail "core/decomposition-heuristics.md missing diff > 60 lines threshold"
  fi
fi

# AC-4.7: profile-parser.md states fixer, reviewer, publisher cannot be skipped
PROFILE_FILE="$REPO_ROOT/core/profile-parser.md"
if [ -f "$PROFILE_FILE" ]; then
  for agent in fixer reviewer publisher; do
    if ! grep -q "$agent" "$PROFILE_FILE"; then
      fail "core/profile-parser.md missing reference to non-skippable stage: $agent"
    fi
  done
  if ! grep -qi "cannot.*skip\|NEVER.*skip\|not.*skip" "$PROFILE_FILE"; then
    fail "core/profile-parser.md must state that fixer/reviewer/publisher cannot be skipped"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: All core files have required sections and specific contract content"
exit "$FAIL"
