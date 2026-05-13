#!/usr/bin/env bash
# Test: Every core/*.md file is referenced by at least one command, and CLAUDE.md declares correct count
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
CORE_DIR="$REPO_ROOT/core"
SKILLS_DIR="$REPO_ROOT/skills"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# Verify prerequisites
if [ ! -d "$CORE_DIR" ]; then
  fail "core/ directory not found at $CORE_DIR"
  exit 1
fi
if [ ! -d "$SKILLS_DIR" ]; then
  fail "skills/ directory not found at $SKILLS_DIR"
  exit 1
fi
if [ ! -f "$CLAUDE_MD" ]; then
  fail "CLAUDE.md not found at $CLAUDE_MD"
  exit 1
fi

# 1. List all core/*.md files dynamically
mapfile -t CORE_FILES < <(ls "$CORE_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | sort)

if [ "${#CORE_FILES[@]}" -eq 0 ]; then
  fail "No core files found in core/"
  exit 1
fi

# 2. For each core file: verify at least one command references it as core/{name}
# v10 thin-controller: detail moved to skills/<pipeline>/steps/*.md, so we also
# search those files.
for name in "${CORE_FILES[@]}"; do
  ref="core/${name}"
  # Search SKILL.md + steps/*.md across all skills
  match_count=$(find "$SKILLS_DIR" \( -name 'SKILL.md' -o -path '*/steps/*.md' \) -exec grep -l "$ref" {} \; 2>/dev/null | wc -l)
  if [ "$match_count" -eq 0 ]; then
    fail "core/$name.md is not referenced by any skill in skills/ (searched for '$ref')"
  fi
done

# 3. Verify CLAUDE.md claims match the actual count
#    CLAUDE.md says: "core/ — 11 shared pipeline pattern contracts" (or similar)
FS_COUNT="${#CORE_FILES[@]}"

# Extract the claimed number from the line mentioning core/ in the Repository Structure section
CLAIMED=$(grep '`core/`' "$CLAUDE_MD" | grep 'shared' | grep -oE '[0-9]+' | head -1)

if [ -z "$CLAIMED" ]; then
  fail "Could not find a numeric count claim for core/ in CLAUDE.md (expected pattern: 'core/ — N shared pipeline pattern contracts')"
else
  if [ "$CLAIMED" -ne "$FS_COUNT" ]; then
    fail "CLAUDE.md claims $CLAIMED core files but core/ contains $FS_COUNT files (${CORE_FILES[*]})"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: All $FS_COUNT core files are referenced by at least one skill, and CLAUDE.md count matches"
exit "$FAIL"
