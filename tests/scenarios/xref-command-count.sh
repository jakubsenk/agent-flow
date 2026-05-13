#!/usr/bin/env bash
# Test: Numeric count claims in CLAUDE.md match actual filesystem counts for agents/, skills/, core/
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

if [ ! -f "$CLAUDE_MD" ]; then
  fail "CLAUDE.md not found at $CLAUDE_MD"
  exit 1
fi

# Helper: count *.md files in a directory
count_md() {
  local dir="$1"
  ls "$dir"/*.md 2>/dev/null | wc -l
}

# Helper: extract the claimed count for a directory from CLAUDE.md
# Looks for lines like: `- \`agents/\` — 21 agent definitions`
# or: `- \`core/\` — 11 shared pipeline pattern contracts`
extract_claimed() {
  local dir_name="$1"
  # Match: `dir_name/` — N <anything>
  grep "\`${dir_name}/\`" "$CLAUDE_MD" | grep -oE '[0-9]+' | head -1
}

# ---- agents/ ----
AGENTS_FS=$(count_md "$REPO_ROOT/agents")
AGENTS_CLAIMED=$(extract_claimed "agents")

if [ -z "$AGENTS_CLAIMED" ]; then
  fail "Could not find a numeric count claim for agents/ in CLAUDE.md"
else
  if [ "$AGENTS_CLAIMED" -ne "$AGENTS_FS" ]; then
    fail "agents/: CLAUDE.md claims $AGENTS_CLAIMED but filesystem has $AGENTS_FS *.md files"
  fi
fi

# ---- skills/ ----
SKILLS_FS=$(find "$REPO_ROOT/skills" -name 'SKILL.md' 2>/dev/null | wc -l)
SKILLS_CLAIMED=$(extract_claimed "skills")

if [ -z "$SKILLS_CLAIMED" ]; then
  fail "Could not find a numeric count claim for skills/ in CLAUDE.md"
else
  if [ "$SKILLS_CLAIMED" -ne "$SKILLS_FS" ]; then
    fail "skills/: CLAUDE.md claims $SKILLS_CLAIMED but filesystem has $SKILLS_FS SKILL.md files"
  fi
fi

# ---- core/ ----
CORE_FS=$(count_md "$REPO_ROOT/core")
CORE_CLAIMED=$(extract_claimed "core")

if [ -z "$CORE_CLAIMED" ]; then
  fail "Could not find a numeric count claim for core/ in CLAUDE.md"
else
  if [ "$CORE_CLAIMED" -ne "$CORE_FS" ]; then
    fail "core/: CLAUDE.md claims $CORE_CLAIMED but filesystem has $CORE_FS *.md files"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: CLAUDE.md count claims match filesystem — agents: $AGENTS_FS, skills: $SKILLS_FS, core: $CORE_FS"
exit "$FAIL"
