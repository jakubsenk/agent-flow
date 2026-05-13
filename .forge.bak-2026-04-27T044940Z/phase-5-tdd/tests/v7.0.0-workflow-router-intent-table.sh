#!/usr/bin/env bash
# AC-RENAME-STATUS-5, AC-RENAME-STATUS-6, AC-DEL-CREATE-PR-7, AC-DEL-CREATE-PR-8,
# AC-DOCS-COLLISION-WARN-3, AC-DOCS-COLLISION-WARN-WORKFLOW-1
# Asserts the workflow-router intent table and Step prose are updated:
# - /status row replaced with /pipeline-status
# - /init row replaced with /setup-mcp
# - /create-pr row deleted from intent table and Step 4 destructive list
# PLUS positive check: "Did you mean...?" prose with all 3 deprecated names present
# (design.md §5.3 — the workflow-router INTENTIONALLY keeps the deprecated names
#  in this section for user disambiguation).
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

WR="skills/workflow-router/SKILL.md"

# Functional check 1: workflow-router file exists
if [ ! -f "$WR" ]; then
  echo "FAIL: $WR missing" >&2
  exit 1
fi

# Functional check 2: intent table has pipeline-status row
if ! grep -q '`ceos-agents:pipeline-status`' "$WR"; then
  fail "$WR: intent table does not have ceos-agents:pipeline-status row"
fi

# Functional check 3: old intent table row with bare status must be gone
if grep -qE '^\| .*Show status.*\| `ceos-agents:status`' "$WR" 2>/dev/null; then
  fail "$WR: intent table still has old 'ceos-agents:status' row"
fi

# Functional check 4: intent table has setup-mcp row
if ! grep -q '`ceos-agents:setup-mcp`' "$WR"; then
  fail "$WR: intent table does not have ceos-agents:setup-mcp row"
fi

# Functional check 5: create-pr intent table row must be deleted
if grep -qE '^\| .*Create a pull request.*\| `ceos-agents:create-pr`' "$WR" 2>/dev/null; then
  fail "$WR: create-pr intent table row not deleted"
fi

# Functional check 6: Step 3 non-destructive list updated to pipeline-status
if ! grep -E 'NOT destructive.*pipeline-status' "$WR" >/dev/null 2>&1; then
  fail "$WR: Step 3 non-destructive list not updated to pipeline-status"
fi

# Functional check 7: Step 4 destructive list no longer has create-pr,
if grep -E 'IS destructive.*create-pr,' "$WR" >/dev/null 2>&1; then
  fail "$WR: Step 4 destructive list still has create-pr,"
fi

# Functional check 8 (POSITIVE): "Did you mean...?" prose with all 3 deprecated names
# The workflow-router MUST intentionally reference these deprecated identifiers
# for user disambiguation (design.md §5.3). This is the exception to the global ban.
if ! grep -q 'ceos-agents:status' "$WR"; then
  fail "$WR: 'Did you mean?' prose missing 'ceos-agents:status' deprecated name"
fi
if ! grep -q 'ceos-agents:init' "$WR"; then
  fail "$WR: 'Did you mean?' prose missing 'ceos-agents:init' deprecated name"
fi
if ! grep -q 'ceos-agents:create-pr' "$WR"; then
  fail "$WR: 'Did you mean?' prose missing 'ceos-agents:create-pr' deprecated name"
fi

# Functional check 9: at least 3 deprecated-identifier hits (one per deprecated name)
deprecated_hits=$(grep -E '(ceos-agents:status|ceos-agents:init|ceos-agents:create-pr)' "$WR" | wc -l | tr -d ' ')
if [ "$deprecated_hits" -lt 3 ]; then
  fail "$WR: expected >= 3 deprecated-identifier hits, found $deprecated_hits"
fi

# Functional check 10: "did you mean" or "deprecated" prose keyword present
if ! grep -E 'did you mean|deprecated' "$WR" >/dev/null 2>&1; then
  fail "$WR: 'Did you mean...?' or 'deprecated' prose keyword not found"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-RENAME-STATUS-5,6/AC-DEL-CREATE-PR-7,8/AC-DOCS-COLLISION-WARN-3,WORKFLOW-1 — workflow-router intent table updated + Did you mean? prose present"
exit "$FAIL"
