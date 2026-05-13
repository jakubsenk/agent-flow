#!/usr/bin/env bash
# Test: v9.6.0 — No orphan references to removed MCP packages (REQ-052, REQ-027, REQ-073)
# Validates:
#   AC-052:  examples/, skills/, docs/guides/, core/ do NOT contain removed package names
#   AC-052b: REDMINE_HOST env var removed from examples/ and skills/ (renamed to REDMINE_URL)
#   AC-026:  skills/ does NOT contain modelcontextprotocol/server-{github,atlassian,linear}
#   AC-027:  docs/guides/ does NOT contain removed package names as active recommendations
#
# Exceptions: CHANGELOG.md MAY contain old names in migration notes (excluded from check).
# REQ mapping: REQ-027, REQ-052, REQ-073
# Phase 5 TDD — RED phase expected (implementation does not exist yet)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# === REQ-052 / AC-052: examples/ — no orphan references to removed packages ===

if grep -rFq 'modelcontextprotocol/server-github' "$REPO_ROOT/examples/"; then
  fail "AC-052 (REQ-052): examples/ still contains @modelcontextprotocol/server-github reference"
fi

if grep -rFq 'modelcontextprotocol/server-atlassian' "$REPO_ROOT/examples/"; then
  fail "AC-052 (REQ-052): examples/ still contains @modelcontextprotocol/server-atlassian reference"
fi

if grep -rFq 'modelcontextprotocol/server-linear' "$REPO_ROOT/examples/"; then
  fail "AC-052 (REQ-052): examples/ still contains @modelcontextprotocol/server-linear reference"
fi

if grep -rFq 'jesusr00/mcp-server-redmine' "$REPO_ROOT/examples/"; then
  fail "AC-052 (REQ-052): examples/ still contains jesusr00/mcp-server-redmine reference"
fi

# === REQ-073 / AC-052b: examples/ — REDMINE_HOST renamed to REDMINE_URL ===
if grep -rFq 'REDMINE_HOST' "$REPO_ROOT/examples/"; then
  fail "AC-052b (REQ-073 negative): examples/ still contains REDMINE_HOST (should be REDMINE_URL)"
fi

# === REQ-052 / REQ-026 / AC-052: skills/ — no orphan references to removed packages ===

if grep -rFq 'modelcontextprotocol/server-github' "$REPO_ROOT/skills/"; then
  fail "AC-052 (REQ-052): skills/ still contains @modelcontextprotocol/server-github reference"
fi

if grep -rFq 'modelcontextprotocol/server-atlassian' "$REPO_ROOT/skills/"; then
  fail "AC-052 (REQ-052): skills/ still contains @modelcontextprotocol/server-atlassian reference"
fi

if grep -rFq 'modelcontextprotocol/server-linear' "$REPO_ROOT/skills/"; then
  fail "AC-052 (REQ-052): skills/ still contains @modelcontextprotocol/server-linear reference"
fi

if grep -rFq 'jesusr00/mcp-server-redmine' "$REPO_ROOT/skills/"; then
  fail "AC-052 (REQ-052): skills/ still contains jesusr00/mcp-server-redmine reference"
fi

# === REQ-027 / AC-027: docs/guides/ — no active recommendations for removed packages ===
# (CHANGELOG.md is explicitly excluded per spec — it MAY contain old names in migration notes)

if grep -rFq 'modelcontextprotocol/server-github' "$REPO_ROOT/docs/guides/"; then
  fail "AC-027 (REQ-027): docs/guides/ still contains @modelcontextprotocol/server-github as active recommendation"
fi

if grep -rFq 'modelcontextprotocol/server-atlassian' "$REPO_ROOT/docs/guides/"; then
  fail "AC-027 (REQ-027): docs/guides/ still contains @modelcontextprotocol/server-atlassian as active recommendation"
fi

if grep -rFq 'modelcontextprotocol/server-linear' "$REPO_ROOT/docs/guides/"; then
  fail "AC-027 (REQ-027): docs/guides/ still contains @modelcontextprotocol/server-linear as active recommendation"
fi

if grep -rFq 'jesusr00/mcp-server-redmine' "$REPO_ROOT/docs/guides/"; then
  fail "AC-027 (REQ-027): docs/guides/ still contains jesusr00/mcp-server-redmine as active recommendation"
fi

# === REQ-073 / AC-052b: docs/guides/ — REDMINE_HOST renamed ===
if grep -rFq 'REDMINE_HOST' "$REPO_ROOT/docs/guides/"; then
  fail "AC-052b (REQ-073 negative): docs/guides/ still contains REDMINE_HOST (should be REDMINE_URL)"
fi

# === REQ-052: core/ — no orphan references to removed packages ===

if grep -rFq 'modelcontextprotocol/server-github' "$REPO_ROOT/core/"; then
  fail "AC-052 (REQ-052): core/ still contains @modelcontextprotocol/server-github reference"
fi

if grep -rFq 'modelcontextprotocol/server-atlassian' "$REPO_ROOT/core/"; then
  fail "AC-052 (REQ-052): core/ still contains @modelcontextprotocol/server-atlassian reference"
fi

if grep -rFq 'modelcontextprotocol/server-linear' "$REPO_ROOT/core/"; then
  fail "AC-052 (REQ-052): core/ still contains @modelcontextprotocol/server-linear reference"
fi

if grep -rFq 'jesusr00/mcp-server-redmine' "$REPO_ROOT/core/"; then
  fail "AC-052 (REQ-052): core/ still contains jesusr00/mcp-server-redmine reference"
fi

# Note: docs/reference/ is also checked to catch any stale documentation pages
if grep -rFq 'modelcontextprotocol/server-github' "$REPO_ROOT/docs/reference/"; then
  fail "AC-052 (REQ-052): docs/reference/ still contains @modelcontextprotocol/server-github reference"
fi

if grep -rFq 'modelcontextprotocol/server-atlassian' "$REPO_ROOT/docs/reference/"; then
  fail "AC-052 (REQ-052): docs/reference/ still contains @modelcontextprotocol/server-atlassian reference"
fi

if grep -rFq 'modelcontextprotocol/server-linear' "$REPO_ROOT/docs/reference/"; then
  fail "AC-052 (REQ-052): docs/reference/ still contains @modelcontextprotocol/server-linear reference"
fi

if grep -rFq 'jesusr00/mcp-server-redmine' "$REPO_ROOT/docs/reference/"; then
  fail "AC-052 (REQ-052): docs/reference/ still contains jesusr00/mcp-server-redmine reference"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v9.6.0 orphan reference check — all AC-052, AC-027, AC-052b assertions pass (no stale package names in examples/skills/docs/core/)"
exit "$FAIL"
