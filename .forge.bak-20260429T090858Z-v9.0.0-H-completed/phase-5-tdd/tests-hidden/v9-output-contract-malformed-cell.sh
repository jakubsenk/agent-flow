#!/bin/bash
# PURPOSE: (HIDDEN) Edge-case adversarial test. If an agent's ## Output Contract Outputs table
#          has empty cells or wrong column count, the scenario must FAIL. Tests that the shape
#          check is strict enough to catch malformed tables (not just header presence).
# AC-H-N covered: AC-H-003 (adversarial edge case)
# INVOKED BY: tests/harness/run-tests.sh (hidden — held back from Phase 7 fixers)
# EXPECTED ON v8.0.0: SKIP (no ## Output Contract sections exist)
# EXPECTED ON v9.0.0: PASS (all tables are well-formed; no empty required cells)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

AGENTS_DIR="$REPO_ROOT/agents"

if [ ! -d "$AGENTS_DIR" ]; then
  echo "SKIP: agents/ directory not found" >&2
  exit 77
fi

checked=0
skipped=0

for agent_file in "$AGENTS_DIR"/*.md; do
  agent_name=$(basename "$agent_file" .md)

  if ! grep -qE '^## Output Contract$' "$agent_file"; then
    skipped=$((skipped + 1))
    continue
  fi

  checked=$((checked + 1))

  # Extract the ## Output Contract section
  oc_section=$(awk '/^## Output Contract$/{found=1; next} found && /^## [A-Z][^#]/{exit} found{print}' "$agent_file")

  # Check Outputs table rows: every data row (not header, not separator) must have exactly 3 cells
  # Pattern: lines starting with | that are not the header row or separator row
  while IFS= read -r table_row; do
    # Skip separator rows (| --- | --- | --- |)
    if echo "$table_row" | grep -qE '^\|[-: ]+\|'; then
      continue
    fi
    # Skip header rows
    if echo "$table_row" | grep -qF 'Section produced'; then
      continue
    fi
    if echo "$table_row" | grep -qF 'Section | Source'; then
      continue
    fi

    # Count pipe characters to determine column count
    pipe_count=$(echo "$table_row" | tr -cd '|' | wc -c)
    # A 3-column row has 4 pipes: | col1 | col2 | col3 |
    if [ "$pipe_count" -lt 4 ]; then
      fail "$agent_name: Outputs table row has fewer than 3 columns (pipe count: $pipe_count): $table_row"
      # Mutation catch: a row with missing columns fails here
    fi

    # Check for empty required cells: a cell that is just whitespace
    # Extract cell 1 (Section produced): between first and second pipe
    cell1=$(echo "$table_row" | awk -F'|' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -z "$cell1" ]; then
      fail "$agent_name: Outputs table row has empty 'Section produced' cell: $table_row"
    fi

    # Extract cell 2 (When): between second and third pipe
    cell2=$(echo "$table_row" | awk -F'|' '{print $3}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -z "$cell2" ]; then
      fail "$agent_name: Outputs table row has empty 'When' cell: $table_row"
    fi

    # Extract cell 3 (Required fields): between third and fourth pipe
    cell3=$(echo "$table_row" | awk -F'|' '{print $4}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -z "$cell3" ]; then
      fail "$agent_name: Outputs table row has empty 'Required fields' cell: $table_row"
    fi

  done < <(echo "$oc_section" | grep -E '^\|')
done

if [ "$checked" -eq 0 ] && [ "$skipped" -gt 0 ]; then
  echo "SKIP: all $skipped agents lack ## Output Contract (v8.0.0 baseline)" >&2
  exit 77
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-H-003 (adversarial) — $checked agents have well-formed Outputs table rows with no empty cells"
fi
exit "$FAIL"
