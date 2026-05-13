#!/usr/bin/env bash
# v9.1.0-skills-self-describing.sh — REQ-V910-010:
# Every skills/*/SKILL.md file must have a non-empty description: value
# in its YAML frontmatter (between the opening --- and closing ---).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

echo "--- REQ-V910-010: all SKILL.md files have non-empty description ---"

skills_dir="$REPO_ROOT/skills"
if [ ! -d "$skills_dir" ]; then
  fail "skills/ directory not found at $skills_dir"
  exit 1
fi

checked=0
failed=0

# Iterate over all SKILL.md files. Using glob expansion (bash 3.2 compatible,
# no mapfile, no declare -A).
for skill_md in "$skills_dir"/*/SKILL.md; do
  # Skip glob that did not match (no SKILL.md files at all).
  [ -f "$skill_md" ] || continue

  skill_name=$(basename "$(dirname "$skill_md")")
  checked=$((checked + 1))

  # Extract YAML frontmatter: awk captures lines between first and second ---
  # delimiters. The first --- (line 1) opens the block; the second --- closes it.
  # We look for a "description:" line with a non-whitespace value after the colon.
  #
  # awk logic:
  #   in_front==0 and line=="---" → enter frontmatter (in_front=1), skip printing
  #   in_front==1 and line=="---" → exit frontmatter (in_front=2), skip printing
  #   in_front==1                 → print frontmatter line
  #   in_front==2                 → stop processing (exit after second ---)
  has_description=$(awk '
    /^---$/ && in_front == 0 { in_front = 1; next }
    /^---$/ && in_front == 1 { in_front = 2; exit }
    in_front == 1 { print }
  ' "$skill_md" | grep -cE '^description:[[:space:]]*[^[:space:]]' 2>/dev/null || echo 0)

  if [ "$has_description" -ge 1 ]; then
    echo "OK: skills/$skill_name/SKILL.md has non-empty description"
  else
    fail "skills/$skill_name/SKILL.md — missing or empty description: field in frontmatter"
    failed=$((failed + 1))
  fi
done

if [ "$checked" -eq 0 ]; then
  fail "No SKILL.md files found under skills/ — cannot verify (possible directory restructure)"
else
  echo "Checked $checked SKILL.md file(s), $failed failed"
fi

# ---------------------------------------------------------------------------
# Final verdict.
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.1.0-skills-self-describing — all $checked SKILL.md files have non-empty description"
fi
exit "$FAIL"
