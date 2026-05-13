#!/usr/bin/env bash
# Test: Phase 1 command modifications — scaffold auto-finalize, config validity gate, status readiness
# Validates FC-001 to FC-020 (Phase 1 structural criteria)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SCAFFOLD="$REPO_ROOT/commands/scaffold.md"
IMPLEMENT="$REPO_ROOT/commands/implement-feature.md"
FIX_TICKET="$REPO_ROOT/commands/fix-ticket.md"
STATUS="$REPO_ROOT/commands/status.md"

# ── FC-001: scaffold.md contains Step 4b: Tracker Configuration ────────────────
if [ ! -f "$SCAFFOLD" ]; then
  fail "commands/scaffold.md does not exist"
else
  if ! grep -q "Step 4b.*Tracker Configuration\|### Step 4b.*Tracker" "$SCAFFOLD"; then
    fail "FC-001: scaffold.md missing '### Step 4b: Tracker Configuration' section"
  fi
fi

# ── FC-002: Step 4b scans for TODO markers ────────────────────────────────────
if [ -f "$SCAFFOLD" ]; then
  if ! grep -q '<!-- TODO:' "$SCAFFOLD"; then
    fail "FC-002: scaffold.md Step 4b does not reference '<!-- TODO:' marker scanning"
  fi
fi

# ── FC-003: Step 4b has Full YOLO skip conditional ────────────────────────────
if [ -f "$SCAFFOLD" ]; then
  if ! grep -qi 'Full YOLO.*skip\|YOLO.*skip.*tracker\|skip.*tracker.*YOLO' "$SCAFFOLD"; then
    fail "FC-003: scaffold.md Step 4b missing Full YOLO skip condition for tracker configuration"
  fi
fi

# ── FC-004: Step 4b has git commit with "configure Automation Config" ─────────
if [ -f "$SCAFFOLD" ]; then
  if ! grep -qi 'configure Automation Config\|configure automation config' "$SCAFFOLD"; then
    fail "FC-004: scaffold.md Step 4b missing git commit message containing 'configure Automation Config'"
  fi
fi

# ── FC-005: scaffold.md contains Step 4c: MCP Guidance ───────────────────────
if [ -f "$SCAFFOLD" ]; then
  if ! grep -q "Step 4c.*MCP Guidance\|### Step 4c.*MCP" "$SCAFFOLD"; then
    fail "FC-005: scaffold.md missing '### Step 4c: MCP Guidance' section"
  fi
fi

# ── FC-006: Step 4c mentions /ceos-agents:init ───────────────────────────────
if [ -f "$SCAFFOLD" ]; then
  if ! grep -q 'ceos-agents:init' "$SCAFFOLD"; then
    fail "FC-006: scaffold.md Step 4c does not mention '/ceos-agents:init'"
  fi
fi

# ── FC-007: Step 10 Final Report has conditional TODO listing ─────────────────
if [ -f "$SCAFFOLD" ]; then
  if ! grep -q 'none.*all configuration\|all configuration.*set\|(none' "$SCAFFOLD"; then
    fail "FC-007: scaffold.md Step 10 missing conditional '(none — all configuration values set)' path"
  fi
fi

# ── FC-008: Step 10 does NOT have unconditional "fill in TODO sections" ───────
if [ -f "$SCAFFOLD" ]; then
  if grep -q 'fill in TODO sections' "$SCAFFOLD"; then
    fail "FC-008: scaffold.md Step 10 still contains unconditional 'fill in TODO sections' (old behavior not replaced)"
  fi
fi

# ── FC-009: implement-feature.md contains Step 0b: Config validity gate ───────
if [ ! -f "$IMPLEMENT" ]; then
  fail "commands/implement-feature.md does not exist"
else
  if ! grep -q "0b.*Config validity\|### 0b.*config\|Step 0b" "$IMPLEMENT"; then
    fail "FC-009: implement-feature.md missing '### 0b. Config validity gate' section"
  fi
fi

# ── FC-010: implement-feature.md Step 0b checks TODO and placeholder markers ──
if [ -f "$IMPLEMENT" ]; then
  if ! grep -q '<!-- TODO:\|<\.\.\.' "$IMPLEMENT"; then
    fail "FC-010: implement-feature.md Step 0b does not check for '<!-- TODO:' AND '<...>' placeholders"
  fi
  if ! grep -q '<\.\.\.\|placeholder' "$IMPLEMENT"; then
    fail "FC-010: implement-feature.md Step 0b missing placeholder '<...>' check"
  fi
fi

# ── FC-011: implement-feature.md Step 0b produces [ceos-agents] BLOCK ─────────
if [ -f "$IMPLEMENT" ]; then
  if ! grep -q '\[ceos-agents\]' "$IMPLEMENT"; then
    fail "FC-011: implement-feature.md Step 0b missing [ceos-agents] prefixed BLOCK output"
  fi
fi

# ── FC-012: implement-feature.md Step 0b lists incomplete keys in Detail ──────
if [ -f "$IMPLEMENT" ]; then
  if ! grep -qi 'Detail.*incomplete\|incomplete.*keys\|Detail.*key' "$IMPLEMENT"; then
    fail "FC-012: implement-feature.md Step 0b missing Detail field listing incomplete keys"
  fi
fi

# ── FC-013: implement-feature.md Step 0b Recommendation mentions onboard --update
if [ -f "$IMPLEMENT" ]; then
  if ! grep -q 'onboard.*--update\|--update.*onboard' "$IMPLEMENT"; then
    fail "FC-013: implement-feature.md Step 0b Recommendation does not mention '/ceos-agents:onboard --update'"
  fi
fi

# ── FC-014: fix-ticket.md contains Step 0b: Config validity gate ──────────────
if [ ! -f "$FIX_TICKET" ]; then
  fail "commands/fix-ticket.md does not exist"
else
  if ! grep -q "0b.*Config validity\|### 0b.*config\|Step 0b" "$FIX_TICKET"; then
    fail "FC-014: fix-ticket.md missing '### 0b. Config validity gate' section"
  fi
fi

# ── FC-015: Both commands treat optional-section TODOs as WARN not BLOCK ──────
for cmd_file in "$IMPLEMENT" "$FIX_TICKET"; do
  cmd_name=$(basename "$cmd_file")
  if [ -f "$cmd_file" ]; then
    if ! grep -qi 'optional.*warn\|WARN.*optional\|warn.*not.*block\|WARN.*not BLOCK' "$cmd_file"; then
      fail "FC-015: $cmd_name does not distinguish optional section TODO markers as WARN (not BLOCK)"
    fi
  fi
done

# ── FC-016: status.md contains Configuration Readiness section ────────────────
if [ ! -f "$STATUS" ]; then
  fail "commands/status.md does not exist"
else
  if ! grep -q "Configuration Readiness\|### 6b\." "$STATUS"; then
    fail "FC-016: status.md missing '### Configuration Readiness' or '### 6b.' section"
  fi
fi

# ── FC-017: status.md Step 6b checks 4 readiness items ───────────────────────
if [ -f "$STATUS" ]; then
  if ! grep -q 'CLAUDE\.md' "$STATUS"; then
    fail "FC-017: status.md Configuration Readiness missing CLAUDE.md presence check"
  fi
  if ! grep -q '<!-- TODO:\|TODO.*marker\|required.*section' "$STATUS"; then
    fail "FC-017: status.md Configuration Readiness missing TODO marker check in required sections"
  fi
  if ! grep -qi 'mcp.*avail\|mcp.*server\|\.mcp\.json' "$STATUS"; then
    fail "FC-017: status.md Configuration Readiness missing MCP availability check"
  fi
  if ! grep -qi 'build.*tool\|tooling\|build command' "$STATUS"; then
    fail "FC-017: status.md Configuration Readiness missing build tooling check"
  fi
fi

# ── FC-018: status.md Step 6b displays Check/Status/Detail table ──────────────
if [ -f "$STATUS" ]; then
  if ! grep -q '| Check\|Check.*Status\|Status.*Detail' "$STATUS"; then
    fail "FC-018: status.md Configuration Readiness missing table with Check/Status/Detail columns"
  fi
fi

# ── FC-019: status.md Step 0 uses soft MCP mode (mcp_available not STOP) ──────
if [ -f "$STATUS" ]; then
  if ! grep -qi 'mcp_available.*false\|mcp_available = false\|set.*mcp_available' "$STATUS"; then
    fail "FC-019: status.md Step 0 must set mcp_available = false (soft mode), not STOP on MCP failure"
  fi
fi

# ── FC-020: status.md Step 7 references readiness failures first ───────────────
if [ -f "$STATUS" ]; then
  # Find line numbers for Configuration Readiness and Recommended Next Steps
  readiness_line=$(grep -n 'Configuration Readiness\|6b\.' "$STATUS" | head -1 | cut -d: -f1)
  nextsteps_line=$(grep -n 'Recommended Next Steps\|Step 7\b' "$STATUS" | head -1 | cut -d: -f1)
  if [ -n "$readiness_line" ] && [ -n "$nextsteps_line" ] && [ "$readiness_line" -ge "$nextsteps_line" ]; then
    fail "FC-020: status.md Configuration Readiness section must appear before Recommended Next Steps"
  fi
  if ! grep -qi 'config.*incomplete\|incomplete.*config\|fix.*config\|readiness' "$STATUS"; then
    fail "FC-020: status.md Step 7 does not reference readiness failures as first recommendation"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Phase 1 command structural tests passed (FC-001 to FC-020)"
exit "$FAIL"
