#!/usr/bin/env bash
# Test: v9.6.0 — MCP template replacements (REQ-001..006, REQ-010)
# Validates:
#   AC-001:  github.json contains "type": "http", GitHub Copilot MCP URL, and Bearer header
#   AC-001b: github.json does NOT contain modelcontextprotocol/server-github or npx
#   AC-002:  jira.json contains "type": "http" and Atlassian MCP URL
#   AC-002b: jira.json does NOT contain ATLASSIAN_API_TOKEN or modelcontextprotocol/server-atlassian
#   AC-003:  linear.json contains "type": "http" and Linear MCP URL
#   AC-003b: linear.json does NOT contain LINEAR_API_KEY or modelcontextprotocol/server-linear
#   AC-004:  youtrack.json contains "type": "http", youtrack.cloud/mcp URL, and Bearer header
#   AC-004b: youtrack.json does NOT contain vitalyostanin
#   AC-005:  redmine.json contains "command": "uvx", pinned version, REDMINE_URL, REDMINE_API_KEY
#   AC-005b: redmine.json does NOT contain jesusr00, REDMINE_HOST, or --prefix
#   AC-006:  codegraph.json contains "type": "http" (NOT "type": "https")
#   AC-010:  gitea.json preserves "command": "gitea-mcp", GITEA_HOST, GITEA_ACCESS_TOKEN (UNCHANGED)
#
# REQ mapping: REQ-001, REQ-002, REQ-003, REQ-004, REQ-005, REQ-006, REQ-010, REQ-073
# Phase 5 TDD — RED phase expected (implementation does not exist yet)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

GITHUB_JSON="$REPO_ROOT/examples/mcp-configs/github.json"
JIRA_JSON="$REPO_ROOT/examples/mcp-configs/jira.json"
LINEAR_JSON="$REPO_ROOT/examples/mcp-configs/linear.json"
YOUTRACK_JSON="$REPO_ROOT/examples/mcp-configs/youtrack.json"
REDMINE_JSON="$REPO_ROOT/examples/mcp-configs/redmine.json"
CODEGRAPH_JSON="$REPO_ROOT/examples/mcp-configs/codegraph.json"
GITEA_JSON="$REPO_ROOT/examples/mcp-configs/gitea.json"

# === REQ-001 / AC-001: github.json HTTP transport, URL, and Bearer header ===
if ! grep -Fq '"type": "http"' "$GITHUB_JSON"; then
  fail "AC-001 (REQ-001): github.json missing \"type\": \"http\""
fi
if ! grep -Fq '"url": "https://api.githubcopilot.com/mcp/"' "$GITHUB_JSON"; then
  fail "AC-001 (REQ-001): github.json missing GitHub Copilot MCP URL https://api.githubcopilot.com/mcp/"
fi
if ! grep -Fq '"Authorization": "Bearer' "$GITHUB_JSON"; then
  fail "AC-001 (REQ-001): github.json missing Bearer Authorization header"
fi

# === REQ-001 / AC-001b (NEGATIVE): github.json no legacy package or npx ===
if grep -Fq 'modelcontextprotocol/server-github' "$GITHUB_JSON"; then
  fail "AC-001b (REQ-001 negative): github.json still contains @modelcontextprotocol/server-github"
fi
if grep -Fq 'npx' "$GITHUB_JSON"; then
  fail "AC-001b (REQ-001 negative): github.json still contains npx invocation"
fi

# === REQ-002 / AC-002: jira.json HTTP transport and Atlassian MCP URL ===
if ! grep -Fq '"type": "http"' "$JIRA_JSON"; then
  fail "AC-002 (REQ-002): jira.json missing \"type\": \"http\""
fi
if ! grep -Fq '"url": "https://mcp.atlassian.com/v1/mcp"' "$JIRA_JSON"; then
  fail "AC-002 (REQ-002): jira.json missing Atlassian MCP URL https://mcp.atlassian.com/v1/mcp"
fi

# === REQ-002 / AC-002b (NEGATIVE): jira.json no env block and no old package ===
if grep -Fq 'ATLASSIAN_API_TOKEN' "$JIRA_JSON"; then
  fail "AC-002b (REQ-002 negative): jira.json still contains ATLASSIAN_API_TOKEN (old env block)"
fi
if grep -Fq 'modelcontextprotocol/server-atlassian' "$JIRA_JSON"; then
  fail "AC-002b (REQ-002 negative): jira.json still contains @modelcontextprotocol/server-atlassian"
fi

# === REQ-003 / AC-003: linear.json HTTP transport and Linear MCP URL ===
if ! grep -Fq '"type": "http"' "$LINEAR_JSON"; then
  fail "AC-003 (REQ-003): linear.json missing \"type\": \"http\""
fi
if ! grep -Fq '"url": "https://mcp.linear.app/mcp"' "$LINEAR_JSON"; then
  fail "AC-003 (REQ-003): linear.json missing Linear MCP URL https://mcp.linear.app/mcp"
fi

# === REQ-003 / AC-003b (NEGATIVE): linear.json no env block and no old package ===
if grep -Fq 'LINEAR_API_KEY' "$LINEAR_JSON"; then
  fail "AC-003b (REQ-003 negative): linear.json still contains LINEAR_API_KEY (old env block)"
fi
if grep -Fq 'modelcontextprotocol/server-linear' "$LINEAR_JSON"; then
  fail "AC-003b (REQ-003 negative): linear.json still contains @modelcontextprotocol/server-linear"
fi

# === REQ-004 / AC-004: youtrack.json HTTP transport, youtrack.cloud/mcp URL, and Bearer header ===
if ! grep -Fq '"type": "http"' "$YOUTRACK_JSON"; then
  fail "AC-004 (REQ-004): youtrack.json missing \"type\": \"http\""
fi
if ! grep -Fq 'youtrack.cloud/mcp' "$YOUTRACK_JSON"; then
  fail "AC-004 (REQ-004): youtrack.json missing youtrack.cloud/mcp URL pattern"
fi
if ! grep -Fq '"Authorization": "Bearer' "$YOUTRACK_JSON"; then
  fail "AC-004 (REQ-004): youtrack.json missing Bearer Authorization header"
fi

# === REQ-004 / AC-004b (NEGATIVE): youtrack.json no vitalyostanin package in template ===
if grep -Fq 'vitalyostanin' "$YOUTRACK_JSON"; then
  fail "AC-004b (REQ-004 negative): youtrack.json contains vitalyostanin (community fallback must be prose-only in setup-mcp)"
fi

# === REQ-005 / AC-005: redmine.json uvx command and pinned version ===
if ! grep -Fq '"command": "uvx"' "$REDMINE_JSON"; then
  fail "AC-005 (REQ-005): redmine.json missing \"command\": \"uvx\""
fi
if ! grep -Fq 'mcp-redmine==2026.01.13.152335' "$REDMINE_JSON"; then
  fail "AC-005 (REQ-005): redmine.json missing pinned version mcp-redmine==2026.01.13.152335"
fi
if ! grep -Fq '"REDMINE_URL"' "$REDMINE_JSON"; then
  fail "AC-005 (REQ-005): redmine.json missing REDMINE_URL env var"
fi
if ! grep -Fq '"REDMINE_API_KEY"' "$REDMINE_JSON"; then
  fail "AC-005 (REQ-005): redmine.json missing REDMINE_API_KEY env var"
fi

# === REQ-005 / REQ-073 / AC-005b (NEGATIVE): redmine.json no old pattern and no REDMINE_HOST ===
if grep -Fq 'jesusr00' "$REDMINE_JSON"; then
  fail "AC-005b (REQ-005 negative): redmine.json still contains jesusr00 (old package)"
fi
if grep -Fq 'REDMINE_HOST' "$REDMINE_JSON"; then
  fail "AC-005b (REQ-073 negative): redmine.json still contains REDMINE_HOST (renamed to REDMINE_URL)"
fi
if grep -Fq -- '--prefix' "$REDMINE_JSON"; then
  fail "AC-005b (REQ-005 negative): redmine.json still contains --prefix (old npx local-clone pattern)"
fi

# === REQ-006 / AC-006: codegraph.json type field corrected to "http" ===
if ! grep -Fq '"type": "http"' "$CODEGRAPH_JSON"; then
  fail "AC-006 (REQ-006): codegraph.json missing \"type\": \"http\""
fi
if grep -Fq '"type": "https"' "$CODEGRAPH_JSON"; then
  fail "AC-006 (REQ-006 negative): codegraph.json still contains invalid \"type\": \"https\""
fi

# === REQ-010 / AC-010: gitea.json preserved unchanged (key fields check) ===
if ! grep -Fq '"command": "gitea-mcp"' "$GITEA_JSON"; then
  fail "AC-010 (REQ-010): gitea.json missing \"command\": \"gitea-mcp\" (should be UNCHANGED from v9.5.0)"
fi
if ! grep -Fq '"GITEA_HOST"' "$GITEA_JSON"; then
  fail "AC-010 (REQ-010): gitea.json missing GITEA_HOST env var (should be UNCHANGED)"
fi
if ! grep -Fq '"GITEA_ACCESS_TOKEN"' "$GITEA_JSON"; then
  fail "AC-010 (REQ-010): gitea.json missing GITEA_ACCESS_TOKEN env var (should be UNCHANGED)"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v9.6.0 MCP template replacements — all AC-001..006b + AC-010 assertions pass"
exit "$FAIL"
