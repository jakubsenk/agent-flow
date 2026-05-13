#!/usr/bin/env bash
# Test: v9.4.0 — Archive extraction step guards for cross-OS gitea-mcp install (T3)
# Validates:
#   AC-13: skills/setup-mcp/SKILL.md Step 5 contains download host gitea.com
#   AC-14: skills/setup-mcp/SKILL.md Step 5 does NOT contain codeberg.org/goern/forgejo-mcp
#   AC-15: skills/setup-mcp/SKILL.md Step 5 contains tar xf or tar -xf (Linux/macOS extract)
#   AC-16: skills/setup-mcp/SKILL.md Step 5 contains Expand-Archive or unzip,
#           AND that extraction command appears near a Windows OS-conditional marker
#   AC-44: tests/scenarios/v9-4-archive-extraction.sh exists
#   AC-45: this file greps skills/setup-mcp/SKILL.md for tar, Expand-Archive/unzip, gitea.com
#   AC-46: this file does NOT invoke jq
#
# REQ mapping: REQ-7, REQ-8, REQ-9, REQ-26
# Phase 4 advisory da2-f2 (AC-16 Windows-gate): Expand-Archive context checked via -B5 -A5 window,
#   matching (windows|mingw|msys) — .zip dropped per da2-f2 advisory.
# Phase 5 TDD — RED phase expected (scenario not yet in tests/scenarios/)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SETUP_MCP="$REPO_ROOT/skills/setup-mcp/SKILL.md"
T3_FINAL="$REPO_ROOT/tests/scenarios/v9-4-archive-extraction.sh"

# ============================================================
# REQ-7 / AC-13: Step 5 contains gitea.com/gitea/gitea-mcp download host
# ============================================================
if ! grep -q 'gitea.com/gitea/gitea-mcp' "$SETUP_MCP"; then
  fail "AC-13 (REQ-7): setup-mcp Step 5 does not contain download host gitea.com/gitea/gitea-mcp"
fi

# ============================================================
# REQ-7 / AC-14 (NEGATIVE): Step 5 must NOT contain codeberg.org/goern/forgejo-mcp
# ============================================================
if grep -q 'codeberg.org/goern/forgejo-mcp' "$SETUP_MCP"; then
  fail "AC-14 (REQ-7 negative): setup-mcp still contains codeberg.org/goern/forgejo-mcp download URL"
fi

# ============================================================
# REQ-8 / AC-15: Step 5 contains tar xf or tar -xf (Linux/macOS extract)
# ============================================================
if ! grep -qE 'tar (xf|-xf)' "$SETUP_MCP"; then
  fail "AC-15 (REQ-8): setup-mcp Step 5 does not contain 'tar xf' or 'tar -xf' (Linux/macOS extract)"
fi

# ============================================================
# REQ-9 / AC-16: Step 5 contains Expand-Archive or unzip, AND that command appears
#   near a Windows OS-conditional marker (within ±5 lines) matching (windows|mingw|msys)
#   Note: .zip proximity check dropped per Phase 4 advisory da2-f2 — keep (windows|mingw|msys)
# ============================================================
if ! grep -qE '(Expand-Archive|unzip)' "$SETUP_MCP"; then
  fail "AC-16a (REQ-9): setup-mcp Step 5 contains neither Expand-Archive nor unzip (Windows extract)"
else
  if ! grep -B 5 -A 5 -E '(Expand-Archive|unzip)' "$SETUP_MCP" | grep -qiE '(windows|mingw|msys)'; then
    fail "AC-16b (REQ-9): Expand-Archive/unzip in setup-mcp does not appear near a Windows OS-conditional marker (windows|mingw|msys) within ±5 lines"
  fi
fi

# ============================================================
# REQ-26 / AC-44: T3 scenario file exists at tests/scenarios/
# ============================================================
if [ ! -f "$T3_FINAL" ]; then
  fail "AC-44 (REQ-26): tests/scenarios/v9-4-archive-extraction.sh does not exist (Phase 7 not yet run)"
fi

# ============================================================
# REQ-26 / AC-45: T3 scenario greps skills/setup-mcp/SKILL.md for tar, Expand-Archive/unzip, gitea.com
# ============================================================
if [ -f "$T3_FINAL" ]; then
  if ! grep -q 'tar' "$T3_FINAL"; then
    fail "AC-45a (REQ-26): T3 scenario does not grep for 'tar'"
  fi
  if ! grep -qE '(Expand-Archive|unzip)' "$T3_FINAL"; then
    fail "AC-45b (REQ-26): T3 scenario does not grep for Expand-Archive or unzip"
  fi
  if ! grep -q 'gitea.com' "$T3_FINAL"; then
    fail "AC-45c (REQ-26): T3 scenario does not grep for 'gitea.com'"
  fi
  if ! grep -q 'skills/setup-mcp/SKILL.md' "$T3_FINAL"; then
    fail "AC-45d (REQ-26): T3 scenario does not reference skills/setup-mcp/SKILL.md"
  fi
fi

# ============================================================
# REQ-26 + NFR-1 / AC-46 (NEGATIVE): T3 scenario must NOT invoke jq
# ============================================================
if [ -f "$T3_FINAL" ]; then
  if grep -vE '^\s*#|^\s*fail ' "$T3_FINAL" | grep -qE '\bjq\b'; then
    fail "AC-46 (REQ-26 + NFR-1 negative): T3 scenario invokes jq (forbidden)"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v9.4.0 archive extraction guards — all T3 positive+negative assertions pass (AC-13..AC-16, AC-44..AC-46)"
exit "$FAIL"
