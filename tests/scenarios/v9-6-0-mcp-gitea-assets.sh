#!/usr/bin/env bash
# Test: v9.6.0 — setup-mcp Step 5 gitea binary asset names pinned to v1.1.0 (REQ-022)
# Validates:
#   AC-022:  skills/setup-mcp/SKILL.md Step 5 contains all 8 gitea v1.1.0 asset names
#            (PascalCase OS, lowercase ARCH, correct extensions per platform)
#   AC-022b: download URL uses pinned /releases/download/v1.1.0/ (NOT /releases/latest/)
#   AC-022c: no references to old lowercase naming pattern (gitea-mcp-linux-amd64 style)
#
# REQ mapping: REQ-022
# Phase 5 TDD — RED phase expected (implementation does not exist yet)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SETUP_MCP="$REPO_ROOT/skills/setup-mcp/SKILL.md"

# === REQ-022 / AC-022: all 8 gitea v1.1.0 asset names present in setup-mcp ===
# Naming convention: gitea-mcp_{VERSION}_{OS}_{ARCH}.{EXT}
# VERSION = 1.1.0, OS = PascalCase (Darwin/Linux/Windows), ARCH = lowercase (arm64/x86_64/i386)
# EXT = .tar.gz for Unix, .zip for Windows

if ! grep -Fq 'gitea-mcp_1.1.0_Darwin_arm64.tar.gz' "$SETUP_MCP"; then
  fail "AC-022 (REQ-022): setup-mcp SKILL.md missing asset gitea-mcp_1.1.0_Darwin_arm64.tar.gz"
fi

if ! grep -Fq 'gitea-mcp_1.1.0_Darwin_x86_64.tar.gz' "$SETUP_MCP"; then
  fail "AC-022 (REQ-022): setup-mcp SKILL.md missing asset gitea-mcp_1.1.0_Darwin_x86_64.tar.gz"
fi

if ! grep -Fq 'gitea-mcp_1.1.0_Linux_arm64.tar.gz' "$SETUP_MCP"; then
  fail "AC-022 (REQ-022): setup-mcp SKILL.md missing asset gitea-mcp_1.1.0_Linux_arm64.tar.gz"
fi

if ! grep -Fq 'gitea-mcp_1.1.0_Linux_i386.tar.gz' "$SETUP_MCP"; then
  fail "AC-022 (REQ-022): setup-mcp SKILL.md missing asset gitea-mcp_1.1.0_Linux_i386.tar.gz"
fi

if ! grep -Fq 'gitea-mcp_1.1.0_Linux_x86_64.tar.gz' "$SETUP_MCP"; then
  fail "AC-022 (REQ-022): setup-mcp SKILL.md missing asset gitea-mcp_1.1.0_Linux_x86_64.tar.gz"
fi

if ! grep -Fq 'gitea-mcp_1.1.0_Windows_arm64.zip' "$SETUP_MCP"; then
  fail "AC-022 (REQ-022): setup-mcp SKILL.md missing asset gitea-mcp_1.1.0_Windows_arm64.zip"
fi

if ! grep -Fq 'gitea-mcp_1.1.0_Windows_i386.zip' "$SETUP_MCP"; then
  fail "AC-022 (REQ-022): setup-mcp SKILL.md missing asset gitea-mcp_1.1.0_Windows_i386.zip"
fi

if ! grep -Fq 'gitea-mcp_1.1.0_Windows_x86_64.zip' "$SETUP_MCP"; then
  fail "AC-022 (REQ-022): setup-mcp SKILL.md missing asset gitea-mcp_1.1.0_Windows_x86_64.zip"
fi

# === REQ-022 / AC-022: pinned download base URL present (not latest redirect) ===
if ! grep -Fq 'releases/download/v1.1.0/' "$SETUP_MCP"; then
  fail "AC-022 (REQ-022): setup-mcp SKILL.md missing pinned download URL releases/download/v1.1.0/"
fi

# === REQ-022 / AC-022b (NEGATIVE): no /releases/latest redirect ===
if grep -Fq '/releases/latest' "$SETUP_MCP"; then
  fail "AC-022b (REQ-022 negative): setup-mcp SKILL.md still contains /releases/latest redirect (must be pinned to v1.1.0)"
fi

# === REQ-022 / AC-022c (NEGATIVE): no old lowercase naming pattern ===
# Old style was gitea-mcp-{lowercase-os}-amd64 (e.g., gitea-mcp-linux-amd64)
# New style is PascalCase OS with underscore separator
if grep -Eq 'gitea-mcp-(linux|darwin|windows)-' "$SETUP_MCP"; then
  fail "AC-022c (REQ-022 negative): setup-mcp SKILL.md still contains old lowercase OS naming pattern (e.g. gitea-mcp-linux-amd64)"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v9.6.0 gitea asset names — all AC-022, AC-022b, AC-022c assertions pass (all 8 v1.1.0 assets present, URL pinned, old pattern absent)"
exit "$FAIL"
