#!/usr/bin/env bash
# Test: v9.6.0 — MCP detection table consistency (REQ-020, REQ-021, REQ-024, REQ-025, REQ-026)
# Validates:
#   AC-020:  core/mcp-detection.md updated with new endpoint identifiers for all 5 replaced trackers
#   AC-021:  skills/setup-mcp/SKILL.md Step 3 reflects new transport/invocation for each tracker
#   AC-024:  setup-mcp Step 3 prose contains vitalyostanin fallback for YouTrack pre-2026.1
#   AC-025:  setup-mcp Step 2b does NOT introduce upfront uvx prereq check
#   AC-026:  setup-mcp Step 2b npx prereq list pruned (no github/jira/linear/redmine packages)
#
# REQ mapping: REQ-020, REQ-021, REQ-024, REQ-025, REQ-026
# Phase 5 TDD — RED phase expected (implementation does not exist yet)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

MCP_DETECT="$REPO_ROOT/core/mcp-detection.md"
SETUP_MCP="$REPO_ROOT/skills/setup-mcp/SKILL.md"

# === REQ-020 / AC-020: core/mcp-detection.md updated with new endpoint identifiers ===

if ! grep -Fq 'api.githubcopilot.com/mcp' "$MCP_DETECT"; then
  fail "AC-020 (REQ-020): core/mcp-detection.md missing GitHub Copilot endpoint api.githubcopilot.com/mcp"
fi

if ! grep -Fq 'mcp.atlassian.com/v1/mcp' "$MCP_DETECT"; then
  fail "AC-020 (REQ-020): core/mcp-detection.md missing Atlassian endpoint mcp.atlassian.com/v1/mcp"
fi

if ! grep -Fq 'mcp.linear.app/mcp' "$MCP_DETECT"; then
  fail "AC-020 (REQ-020): core/mcp-detection.md missing Linear endpoint mcp.linear.app/mcp"
fi

if ! grep -Fq 'youtrack.cloud/mcp' "$MCP_DETECT"; then
  fail "AC-020 (REQ-020): core/mcp-detection.md missing YouTrack endpoint youtrack.cloud/mcp"
fi

if ! grep -Fq 'mcp-redmine==2026.01.13.152335' "$MCP_DETECT"; then
  fail "AC-020 (REQ-020): core/mcp-detection.md missing pinned redmine version mcp-redmine==2026.01.13.152335"
fi

# === REQ-021 / AC-021: setup-mcp Step 3 detection table reflects new transports ===

if ! grep -Fq 'api.githubcopilot.com/mcp' "$SETUP_MCP"; then
  fail "AC-021 (REQ-021): setup-mcp SKILL.md Step 3 missing GitHub Copilot endpoint api.githubcopilot.com/mcp"
fi

if ! grep -Fq 'mcp.atlassian.com/v1/mcp' "$SETUP_MCP"; then
  fail "AC-021 (REQ-021): setup-mcp SKILL.md Step 3 missing Atlassian endpoint mcp.atlassian.com/v1/mcp"
fi

if ! grep -Fq 'mcp.linear.app/mcp' "$SETUP_MCP"; then
  fail "AC-021 (REQ-021): setup-mcp SKILL.md Step 3 missing Linear endpoint mcp.linear.app/mcp"
fi

if ! grep -Fq 'youtrack.cloud/mcp' "$SETUP_MCP"; then
  fail "AC-021 (REQ-021): setup-mcp SKILL.md Step 3 missing YouTrack endpoint youtrack.cloud/mcp"
fi

# Redmine: must use uvx (stdio transport via uvx), not npx
if ! grep -Fq 'mcp-redmine==2026.01.13.152335' "$SETUP_MCP"; then
  fail "AC-021 (REQ-021): setup-mcp SKILL.md missing pinned redmine uvx invocation mcp-redmine==2026.01.13.152335"
fi

# === REQ-024 / AC-024: setup-mcp Step 3 vitalyostanin fallback prose for YouTrack on-prem ===

if ! grep -Fq 'vitalyostanin' "$SETUP_MCP"; then
  fail "AC-024 (REQ-024): setup-mcp SKILL.md missing vitalyostanin fallback reference for YouTrack pre-2026.1"
fi

if ! grep -Fq 'YOUTRACK_URL' "$SETUP_MCP"; then
  fail "AC-024 (REQ-024): setup-mcp SKILL.md missing YOUTRACK_URL env var (required by vitalyostanin fallback)"
fi

if ! grep -Fq 'YOUTRACK_TOKEN' "$SETUP_MCP"; then
  fail "AC-024 (REQ-024): setup-mcp SKILL.md missing YOUTRACK_TOKEN env var (required by vitalyostanin fallback)"
fi

# === REQ-025 / AC-025 (NEGATIVE): setup-mcp Step 2b no upfront uvx prereq check ===
# The uvx check must only appear lazily in Step 3 when redmine is selected, NOT upfront in Step 2b
if grep -Eq 'Step 2b.*uvx|uvx.*Step 2b|upfront.*uvx' "$SETUP_MCP"; then
  fail "AC-025 (REQ-025 negative): setup-mcp SKILL.md Step 2b contains upfront uvx prereq check (must be lazy in Step 3 only)"
fi

# === REQ-026 / AC-026 (NEGATIVE): setup-mcp Step 2b npx prereq list pruned of migrated packages ===
# github, jira, linear have migrated to HTTP transport — no npx needed
# redmine has migrated to uvx — no npx needed
# Only vitalyostanin YouTrack fallback retains npx (and only when that path is selected)

if grep -Fq 'modelcontextprotocol/server-github' "$SETUP_MCP"; then
  fail "AC-026 (REQ-026 negative): setup-mcp SKILL.md still references @modelcontextprotocol/server-github in npx prereqs"
fi

if grep -Fq 'modelcontextprotocol/server-atlassian' "$SETUP_MCP"; then
  fail "AC-026 (REQ-026 negative): setup-mcp SKILL.md still references @modelcontextprotocol/server-atlassian in npx prereqs"
fi

if grep -Fq 'modelcontextprotocol/server-linear' "$SETUP_MCP"; then
  fail "AC-026 (REQ-026 negative): setup-mcp SKILL.md still references @modelcontextprotocol/server-linear in npx prereqs"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v9.6.0 MCP detection table consistency — all AC-020, AC-021, AC-024, AC-025, AC-026 assertions pass"
exit "$FAIL"
