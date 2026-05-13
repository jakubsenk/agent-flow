#!/usr/bin/env bash
# Test: v9.6.0 — docs/reference/mcp-server-versions.md created with required content (REQ-031, REQ-054)
# Validates:
#   AC-031:  docs/reference/mcp-server-versions.md exists
#   AC-031b: file contains rows for all 7 trackers: github, jira, linear, youtrack, redmine, codegraph, gitea
#   AC-031c: file contains Status column with OFFICIAL or COMMUNITY markers
#   AC-031d: file contains an audit cadence section mentioning "quarterly" or "90-day"
#   AC-031e: file contains Atlassian SSE deprecation hard deadline 2026-06-30
#   AC-031f: file contains last-verified date 2026-05-09 (Phase 2 evidence collection date)
#
# REQ mapping: REQ-031, REQ-054
# Phase 5 TDD — RED phase expected (implementation does not exist yet)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

MCP_VERSIONS_DOC="$REPO_ROOT/docs/reference/mcp-server-versions.md"

# === REQ-031 / REQ-054 / AC-031: file exists ===
if [ ! -f "$MCP_VERSIONS_DOC" ]; then
  fail "AC-031 (REQ-031): docs/reference/mcp-server-versions.md does not exist (Phase 7 not yet run)"
  # Cannot test further content checks if file is absent; exit with collected FAIL count
  exit "$FAIL"
fi

# === REQ-031 / AC-031b: all 7 tracker rows present ===

if ! grep -Fq 'github' "$MCP_VERSIONS_DOC"; then
  fail "AC-031b (REQ-031): mcp-server-versions.md missing row/entry for 'github' tracker"
fi

if ! grep -Fq 'jira' "$MCP_VERSIONS_DOC"; then
  fail "AC-031b (REQ-031): mcp-server-versions.md missing row/entry for 'jira' tracker"
fi

if ! grep -Fq 'linear' "$MCP_VERSIONS_DOC"; then
  fail "AC-031b (REQ-031): mcp-server-versions.md missing row/entry for 'linear' tracker"
fi

if ! grep -Fq 'youtrack' "$MCP_VERSIONS_DOC"; then
  fail "AC-031b (REQ-031): mcp-server-versions.md missing row/entry for 'youtrack' tracker"
fi

if ! grep -Fq 'redmine' "$MCP_VERSIONS_DOC"; then
  fail "AC-031b (REQ-031): mcp-server-versions.md missing row/entry for 'redmine' tracker"
fi

if ! grep -Fq 'codegraph' "$MCP_VERSIONS_DOC"; then
  fail "AC-031b (REQ-031): mcp-server-versions.md missing row/entry for 'codegraph' tracker"
fi

if ! grep -Fq 'gitea' "$MCP_VERSIONS_DOC"; then
  fail "AC-031b (REQ-031): mcp-server-versions.md missing row/entry for 'gitea' tracker"
fi

# === REQ-031 / AC-031c: Status column with OFFICIAL or COMMUNITY markers ===
if ! grep -qE 'OFFICIAL|COMMUNITY' "$MCP_VERSIONS_DOC"; then
  fail "AC-031c (REQ-031): mcp-server-versions.md missing Status column markers (OFFICIAL or COMMUNITY)"
fi

# === REQ-031 / AC-031d: audit cadence section mentioning "quarterly" or "90-day" ===
# The audit cadence section must specify the default cadence (90 days / quarterly)
if ! grep -iqE 'quarterly|90.day' "$MCP_VERSIONS_DOC"; then
  fail "AC-031d (REQ-031): mcp-server-versions.md audit cadence section missing 'quarterly' or '90-day' mention"
fi

# "audit cadence" heading or section must be present
if ! grep -iq 'audit cadence' "$MCP_VERSIONS_DOC"; then
  fail "AC-031d (REQ-031): mcp-server-versions.md missing 'audit cadence' section heading"
fi

# === REQ-031 / AC-031e: Atlassian SSE deprecation hard deadline 2026-06-30 ===
if ! grep -Fq '2026-06-30' "$MCP_VERSIONS_DOC"; then
  fail "AC-031e (REQ-031): mcp-server-versions.md missing Atlassian SSE deprecation hard deadline 2026-06-30"
fi

# === REQ-031 / AC-031f: last-verified date 2026-05-09 ===
if ! grep -Fq '2026-05-09' "$MCP_VERSIONS_DOC"; then
  fail "AC-031f (REQ-031): mcp-server-versions.md missing Last-Verified date 2026-05-09 (Phase 2 evidence collection date)"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v9.6.0 mcp-server-versions.md — all AC-031, AC-031b..f assertions pass (file exists, 7 trackers, Status markers, audit cadence, SSE deadline, last-verified date)"
exit "$FAIL"
