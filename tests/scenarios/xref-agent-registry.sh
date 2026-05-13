#!/usr/bin/env bash
# Test: Every agents/*.md file appears in CLAUDE.md Model Selection table, and vice versa
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
AGENTS_DIR="$REPO_ROOT/agents"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# Verify prerequisites
if [ ! -f "$CLAUDE_MD" ]; then
  fail "CLAUDE.md not found at $CLAUDE_MD"
  exit 1
fi
if [ ! -d "$AGENTS_DIR" ]; then
  fail "agents/ directory not found at $AGENTS_DIR"
  exit 1
fi

# 1. Collect agent basenames from filesystem
mapfile -t FS_AGENTS < <(ls "$AGENTS_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | sort)

if [ "${#FS_AGENTS[@]}" -eq 0 ]; then
  fail "No agent files found in agents/"
  exit 1
fi

# 2. Extract agent names from the Model Selection table in CLAUDE.md
#    The table lives after "### Model Selection" and has rows: | Model | Used For | Agents |
#    We extract the third column (Agents) from non-header, non-separator rows.
TABLE_AGENTS_RAW=$(awk '
  /^### Model Selection/ { in_table=1; next }
  in_table && /^\|[-|]+\|/ { next }
  in_table && /^\|/ {
    # Extract first column (model) and third column (agents list)
    n = split($0, cols, "|")
    if (n >= 4) {
      model_col = cols[2]
      agents_col = cols[4]
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", model_col)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", agents_col)
      # Skip header row (first column is "Model")
      if (model_col != "Model") {
        print agents_col
      }
    }
  }
  in_table && /^###/ && !/^### Model Selection/ { in_table=0 }
' "$CLAUDE_MD")

if [ -z "$TABLE_AGENTS_RAW" ]; then
  fail "Could not extract any agents from the ### Model Selection table in CLAUDE.md"
  exit 1
fi

# Split comma-separated names from each row into a sorted array.
# Strip parenthetical annotations such as "(incl. `--e2e` flag)" before matching filenames.
mapfile -t TABLE_AGENTS < <(
  echo "$TABLE_AGENTS_RAW" \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | sed -E 's/[[:space:]]*\([^)]*\)[[:space:]]*//g' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | grep -v '^$' \
    | sort
)

# 3. For each filesystem agent: verify it appears in the table
for agent in "${FS_AGENTS[@]}"; do
  found=0
  for t in "${TABLE_AGENTS[@]}"; do
    if [ "$t" = "$agent" ]; then
      found=1
      break
    fi
  done
  if [ "$found" -eq 0 ]; then
    fail "agents/$agent.md exists on disk but '$agent' is not listed in CLAUDE.md ### Model Selection table"
  fi
done

# 4. For each table agent: verify agents/{name}.md exists on disk
for agent in "${TABLE_AGENTS[@]}"; do
  if [ ! -f "$AGENTS_DIR/$agent.md" ]; then
    fail "'$agent' is listed in CLAUDE.md ### Model Selection table but agents/$agent.md does not exist"
  fi
done

# 5. Verify counts match
FS_COUNT="${#FS_AGENTS[@]}"
TABLE_COUNT="${#TABLE_AGENTS[@]}"
if [ "$FS_COUNT" -ne "$TABLE_COUNT" ]; then
  fail "Count mismatch: agents/ has $FS_COUNT files, CLAUDE.md table lists $TABLE_COUNT agents"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: All $FS_COUNT agents are registered in CLAUDE.md Model Selection table (bidirectional, count matches)"
exit "$FAIL"
