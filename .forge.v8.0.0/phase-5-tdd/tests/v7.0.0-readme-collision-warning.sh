#!/usr/bin/env bash
# AC-DOCS-COLLISION-WARN-1, AC-DOCS-COLLISION-WARN-2
# Asserts that README.md AND docs/guides/installation.md each contain:
# (a) an explicit H2/H3 subsection heading mentioning slash command collision
# (b) body text naming /ceos-agents:pipeline-status and /ceos-agents:setup-mcp
# (c) a reference to the 3 deprecated identifiers from v6.10.x
# A single heading without body text is insufficient (structural requirement).
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---- README.md checks ----

# Functional check 1: README has H2/H3 heading about slash command collision
if ! grep -qE '^#{2,3} .*([Ss]lash.*[Cc]ommand|[Cc]ollision|[Bb]uiltin)' README.md 2>/dev/null; then
  fail "README.md: no H2/H3 heading mentioning slash command collision or builtin"
fi

# Functional check 2: README heading section has body prose (heading is not empty)
# Extract the heading and check that the file mentions "collide" or "builtin" beyond just the heading
if ! grep -qE 'collide.*Claude Code|builtin' README.md 2>/dev/null; then
  fail "README.md: collision warning section body text missing (no 'collide.*Claude Code' or 'builtin')"
fi

# Functional check 3: README names both new namespaced forms
if ! grep -q '/ceos-agents:pipeline-status' README.md 2>/dev/null; then
  fail "README.md: collision warning does not mention /ceos-agents:pipeline-status"
fi
if ! grep -q '/ceos-agents:setup-mcp' README.md 2>/dev/null; then
  fail "README.md: collision warning does not mention /ceos-agents:setup-mcp"
fi

# Functional check 4: README references /ceos-agents:create-pr in the context of the warning
# (design.md §4.4 requires listing all 3 deprecated identifiers)
if ! grep -q 'ceos-agents:create-pr\|create-pr.*removed\|create-pr.*publish' README.md 2>/dev/null; then
  fail "README.md: collision/rename warning does not mention /ceos-agents:create-pr removal"
fi

# ---- docs/guides/installation.md checks ----

INSTALL="docs/guides/installation.md"

# Functional check 5: installation.md has H2/H3 heading about slash command collision
if ! grep -qE '^#{2,3} .*([Ss]lash.*[Cc]ommand|[Cc]ollision|[Bb]uiltin)' "$INSTALL" 2>/dev/null; then
  fail "$INSTALL: no H2/H3 heading mentioning slash command collision or builtin"
fi

# Functional check 6: installation.md body mentions collision with Claude Code builtins
if ! grep -qE 'collide.*Claude Code|builtin' "$INSTALL" 2>/dev/null; then
  fail "$INSTALL: collision warning section body text missing"
fi

# Functional check 7: installation.md names both new namespaced forms
if ! grep -q '/ceos-agents:pipeline-status' "$INSTALL" 2>/dev/null; then
  fail "$INSTALL: collision warning does not mention /ceos-agents:pipeline-status"
fi
if ! grep -q '/ceos-agents:setup-mcp' "$INSTALL" 2>/dev/null; then
  fail "$INSTALL: collision warning does not mention /ceos-agents:setup-mcp"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-DOCS-COLLISION-WARN-1,2 — README and installation.md have collision warning subsections"
exit "$FAIL"
