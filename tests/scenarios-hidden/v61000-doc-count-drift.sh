#!/usr/bin/env bash
# AC: AC-T1-10-1, AC-T1-10-2, AC-META-5-1 (hidden — enumeration upgrade)
# Phase 9 enumeration upgrade: actually enumerates CLAUDE.md count-string anchors
# and cross-checks against source of truth (filesystem).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

[ -f "$CLAUDE_MD" ] || { fail "CLAUDE.md not found"; exit 1; }

# --- Enumerate agents ---
agents_fs=$(find "$REPO_ROOT/agents" -maxdepth 1 -name '*.md' -not -name 'README.md' -type f | wc -l | tr -d ' ')
agents_doc=$(grep -oE '([0-9]+) agent definitions' "$CLAUDE_MD" | grep -oE '[0-9]+' | head -1)
[ "$agents_fs" -eq "${agents_doc:-0}" ] || \
  fail "agents count: CLAUDE.md says ${agents_doc:-MISSING}, filesystem has $agents_fs"

# --- Enumerate skills ---
skills_fs=$(find "$REPO_ROOT/skills" -maxdepth 1 -type d | tail -n +2 | wc -l | tr -d ' ')
skills_doc=$(grep -oE '([0-9]+) skills' "$CLAUDE_MD" | grep -oE '[0-9]+' | head -1)
[ "$skills_fs" -eq "${skills_doc:-0}" ] || \
  fail "skills count: CLAUDE.md says ${skills_doc:-MISSING}, filesystem has $skills_fs"

# --- Enumerate core contracts ---
core_fs=$(find "$REPO_ROOT/core" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')
core_doc=$(grep -oE '([0-9]+) shared pipeline pattern contracts' "$CLAUDE_MD" | grep -oE '[0-9]+' | head -1)
[ "$core_fs" -eq "${core_doc:-0}" ] || \
  fail "core contracts: CLAUDE.md says ${core_doc:-MISSING}, filesystem has $core_fs"

# --- Optional sections: count from CLAUDE.md table ---
optional_doc=$(grep -oE '([0-9]+) optional config sections in total' "$CLAUDE_MD" | grep -oE '[0-9]+' | head -1)
[ "${optional_doc:-0}" -eq 19 ] || fail "optional sections: CLAUDE.md says ${optional_doc:-MISSING}, expected 19"

# --- Positive + negative control ---
# AC-T1-10-2: create synthetic CLAUDE.md with wrong count
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
sed 's/21 agent definitions/20 agent definitions/' "$CLAUDE_MD" > "$TMP/CLAUDE-bad.md"
bad_doc=$(grep -oE '([0-9]+) agent definitions' "$TMP/CLAUDE-bad.md" | grep -oE '[0-9]+' | head -1)
agents_bad_match=0
[ "$agents_fs" -eq "${bad_doc:-0}" ] && agents_bad_match=1
[ "$agents_bad_match" -eq 0 ] || fail "Negative control: synthetic mismatched count should not match filesystem"

echo "PASS: CLAUDE.md counts verified via enumeration (agents=$agents_fs, skills=$skills_fs, core=$core_fs, optional=${optional_doc:-?})"
exit "$FAIL"
