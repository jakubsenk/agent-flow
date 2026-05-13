#!/bin/bash
# PURPOSE: Cross-file invariant enforcement (REQ-H-034, REQ-H-060). For every backtick-quoted
#          ## Heading declared in any agent's Outputs table, assert it appears literally (modulo
#          backticks) in at least one skills/**/SKILL.md or skills/**/steps/*.md file.
#          Handles parameterized headings (e.g., ## Sprint Plan: {sprint_name}) per review f-1f9b7a:
#          strips {…} placeholder tokens and greps by the literal prefix portion.
#          Excludes: ## NEEDS_* sentinels and ## Output Contract itself.
# AC-H-N covered: AC-H-033
# INVOKED BY: tests/harness/run-tests.sh
# EXPECTED ON v8.0.0: PASS with 0 declarations (no ## Output Contract sections exist yet; scenario
#          reports "0 declarations, 0 xrefs checked" and exits 0 per design.md §3.5)
# EXPECTED ON v9.0.0: PASS (every declared heading is referenced in at least one skill)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

AGENTS_DIR="$REPO_ROOT/agents"
SKILLS_DIR="$REPO_ROOT/skills"

if [ ! -d "$AGENTS_DIR" ]; then
  fail "agents/ directory not found"
  exit 1
fi
if [ ! -d "$SKILLS_DIR" ]; then
  fail "skills/ directory not found"
  exit 1
fi

declaration_count=0
checked_count=0
skipped_count=0

for agent_file in "$AGENTS_DIR"/*.md; do
  agent_name=$(basename "$agent_file" .md)

  # Skip agents without ## Output Contract (not all agents may have it yet)
  if ! grep -qE '^## Output Contract$' "$agent_file"; then
    continue
  fi

  # Extract the ## Output Contract section content
  oc_section=$(awk '/^## Output Contract$/{found=1; next} found && /^## [A-Z][^#]/{exit} found{print}' "$agent_file")

  # Extract all backtick-quoted ## Headings from the Outputs table(s)
  # Pattern: `## SomeName` — may contain spaces, hyphens, colons, underscores
  while IFS= read -r raw_heading; do
    # Strip surrounding backticks: `## Heading` -> ## Heading
    heading="${raw_heading//\`/}"
    declaration_count=$((declaration_count + 1))

    # Exclusion 1: sentinels starting with ## NEEDS_ (agent-internal signal, not a markdown section)
    if echo "$heading" | grep -qE '^## NEEDS_'; then
      skipped_count=$((skipped_count + 1))
      continue
    fi

    # Exclusion 2: ## Output Contract itself (metadata heading, not an emitted section)
    if [ "$heading" = "## Output Contract" ]; then
      skipped_count=$((skipped_count + 1))
      continue
    fi

    # Handle parameterized headings per review finding f-1f9b7a:
    # e.g., "## Sprint Plan: {sprint_name}" -> grep for prefix "## Sprint Plan:"
    # Strip everything from first { onwards to get the stable prefix
    grep_target="$heading"
    if echo "$heading" | grep -qF '{'; then
      grep_target=$(echo "$heading" | sed 's/{.*//' | sed 's/[[:space:]]*$//')
      # If prefix is just "## " or empty after stripping, skip (variable-only heading)
      if [ "${#grep_target}" -le 3 ]; then
        skipped_count=$((skipped_count + 1))
        continue
      fi
    fi

    # Also exclude ## {Epic Title} style (entire heading is a placeholder)
    if echo "$heading" | grep -qE '^## \{'; then
      skipped_count=$((skipped_count + 1))
      continue
    fi

    checked_count=$((checked_count + 1))

    # Search for the heading (without ## prefix markdown syntax — search for the literal text)
    # Skills grep against the heading text that the agent emits, not the markdown source
    # We search for the full heading string in skill files
    found=0

    # Search in SKILL.md files
    if grep -rl -F "$grep_target" "$SKILLS_DIR" --include="SKILL.md" 2>/dev/null | grep -q .; then
      found=1
    fi

    # Search in steps/*.md files
    if [ "$found" -eq 0 ]; then
      if find "$SKILLS_DIR" -name "*.md" -path "*/steps/*" 2>/dev/null | xargs grep -l -F "$grep_target" 2>/dev/null | grep -q .; then
        found=1
      fi
    fi

    if [ "$found" -eq 0 ]; then
      fail "$agent_name: declared '$heading' in Outputs table but not referenced in any skills/**/SKILL.md or skills/**/steps/*.md"
      # Mutation catch: removing a skill grep reference for a heading while keeping it in the contract fails here
    fi
  done < <(echo "$oc_section" | grep -oE '\`## [A-Za-z][A-Za-z0-9 _:{}-]*\`')
done

# If zero declarations found, scenario passes (design.md §3.5: "reports 0 declarations, exits 0")
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-H-033 — $declaration_count total declarations, $checked_count xref-checked, $skipped_count excluded (NEEDS_* / parameterized / metadata)"
fi
exit "$FAIL"
