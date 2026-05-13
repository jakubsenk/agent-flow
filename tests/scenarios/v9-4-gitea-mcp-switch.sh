#!/usr/bin/env bash
# Test: v9.4.0 — Gitea MCP binary switch (forgejo-mcp -> gitea-mcp) positive+negative assertions (T1)
# Validates:
#   AC-1:  examples/mcp-configs/gitea.json command field references gitea-mcp
#   AC-2:  examples/mcp-configs/gitea.json command field does NOT reference forgejo-mcp
#   AC-3:  examples/mcp-configs/gitea.json env block contains GITEA_ACCESS_TOKEN
#   AC-4:  examples/mcp-configs/gitea.json env block contains GITEA_HOST
#   AC-5:  examples/mcp-configs/gitea.json does NOT contain FORGEJO_TOKEN
#   AC-6:  examples/mcp-configs/gitea.json does NOT contain FORGEJO_URL
#   AC-7:  examples/mcp-configs/gitea.json does NOT contain forgejo-mcp anywhere (whole-file)
#   AC-8:  core/mcp-detection.md gitea row has gitea-mcp in package column, NOT forgejo-mcp
#   AC-9:  core/mcp-detection.md gitea row tool prefix is mcp__gitea__*
#   AC-10: core/mcp-detection.md gitea row exists AND does NOT contain mcp__forgejo__* alternation
#   AC-11: skills/setup-mcp/SKILL.md Step 3 gitea row lists GITEA_ACCESS_TOKEN
#   AC-12: skills/setup-mcp/SKILL.md Step 3 gitea row lists GITEA_HOST, not FORGEJO_(TOKEN|URL)
#   AC-17: skills/setup-mcp/SKILL.md go install fallback (if present) references gitea.com (not codeberg.org/goern/forgejo-mcp)
#   AC-18: skills/setup-mcp/SKILL.md Step 1b reverse-mapping has gitea-mcp->gitea, NOT forgejo-mcp->gitea
#   AC-19: skills/setup-mcp/SKILL.md Step 5 sub-heading contains gitea-mcp
#   AC-20: skills/setup-mcp/SKILL.md Step 5 has NO sub-heading containing forgejo-mcp
#   AC-21: docs/guides/mcp-configuration.md gitea block command references gitea-mcp
#   AC-22: docs/guides/mcp-configuration.md gitea block has GITEA_HOST, GITEA_ACCESS_TOKEN, NOT FORGEJO_(URL|TOKEN)
#   AC-23: docs/guides/mcp-configuration.md does NOT contain heading "## Gitea/Forgejo MCP server"
#   AC-24: docs/guides/mcp-configuration.md has exactly ONE "## Gitea" heading not containing Forgejo
#   AC-36: this file (tests/scenarios/v9-4-gitea-mcp-switch.sh) exists
#   AC-37: this file begins with #!/usr/bin/env bash shebang
#   AC-38: this file is executable (x-bit set; SKIP on Windows)
#   AC-39: this file does NOT invoke jq
#
# REQ mapping: REQ-1..6, REQ-10..14, REQ-24
# Phase 5 TDD — RED phase expected (file not yet in tests/scenarios/)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

GITEA_JSON="$REPO_ROOT/examples/mcp-configs/gitea.json"
MCP_DETECT="$REPO_ROOT/core/mcp-detection.md"
SETUP_MCP="$REPO_ROOT/skills/setup-mcp/SKILL.md"
MCP_DOCS="$REPO_ROOT/docs/guides/mcp-configuration.md"
T1_FINAL="$REPO_ROOT/tests/scenarios/v9-4-gitea-mcp-switch.sh"

# ============================================================
# REQ-1 / AC-1: gitea.json command field references gitea-mcp
# ============================================================
if ! grep -q '"command".*gitea-mcp' "$GITEA_JSON"; then
  fail "AC-1 (REQ-1): gitea.json command field does not reference gitea-mcp"
fi

# ============================================================
# REQ-1 / AC-2 (NEGATIVE): command field must NOT reference forgejo-mcp
# ============================================================
if grep -q '"command".*forgejo-mcp' "$GITEA_JSON"; then
  fail "AC-2 (REQ-1 negative): gitea.json command field still references forgejo-mcp"
fi

# ============================================================
# REQ-2 / AC-3: env block contains GITEA_ACCESS_TOKEN
# ============================================================
if ! grep -q 'GITEA_ACCESS_TOKEN' "$GITEA_JSON"; then
  fail "AC-3 (REQ-2): gitea.json env block missing GITEA_ACCESS_TOKEN"
fi

# ============================================================
# REQ-2 / AC-4: env block contains GITEA_HOST
# ============================================================
if ! grep -q 'GITEA_HOST' "$GITEA_JSON"; then
  fail "AC-4 (REQ-2): gitea.json env block missing GITEA_HOST"
fi

# ============================================================
# REQ-3 / AC-5 (NEGATIVE): file must NOT contain FORGEJO_TOKEN
# ============================================================
if grep -q 'FORGEJO_TOKEN' "$GITEA_JSON"; then
  fail "AC-5 (REQ-3 negative): gitea.json still contains FORGEJO_TOKEN"
fi

# ============================================================
# REQ-3 / AC-6 (NEGATIVE): file must NOT contain FORGEJO_URL
# ============================================================
if grep -q 'FORGEJO_URL' "$GITEA_JSON"; then
  fail "AC-6 (REQ-3 negative): gitea.json still contains FORGEJO_URL"
fi

# ============================================================
# REQ-3 / AC-7 (NEGATIVE): whole-file — must NOT contain forgejo-mcp anywhere
# ============================================================
if grep -q 'forgejo-mcp' "$GITEA_JSON"; then
  fail "AC-7 (REQ-3 negative): gitea.json still contains forgejo-mcp (whole-file invariant)"
fi

# ============================================================
# REQ-4 / AC-8: mcp-detection.md gitea row has gitea-mcp, NOT forgejo-mcp
# Two-stage: find row then assert no forgejo-mcp on same row
# ============================================================
if ! grep -E '^\| gitea \|.*gitea-mcp' "$MCP_DETECT" | grep -qv 'forgejo-mcp'; then
  fail "AC-8 (REQ-4): mcp-detection.md gitea row does not contain gitea-mcp OR still contains forgejo-mcp"
fi

# ============================================================
# REQ-5 / AC-9: gitea row tool prefix is mcp__gitea__*
# ============================================================
if ! grep -E '^\| gitea \|' "$MCP_DETECT" | grep -q 'mcp__gitea__\*'; then
  fail "AC-9 (REQ-5): mcp-detection.md gitea row tool prefix does not contain mcp__gitea__*"
fi

# ============================================================
# REQ-5 / AC-10 (NEGATIVE): gitea row exists AND does NOT contain mcp__forgejo__* alternation
# Two-step: capture row -> assert non-empty -> assert no forgejo alternation
# ============================================================
_mcp_detect_row=$(grep -E '^\| gitea \|' "$MCP_DETECT" 2>/dev/null || true)
if [ -z "$_mcp_detect_row" ]; then
  fail "AC-10 (REQ-5): mcp-detection.md gitea row is missing entirely"
elif echo "$_mcp_detect_row" | grep -q 'mcp__forgejo__\*'; then
  fail "AC-10 (REQ-5 negative): mcp-detection.md gitea row still contains mcp__forgejo__* alternation"
fi

# ============================================================
# REQ-6 / AC-11: setup-mcp Step 3 gitea row lists GITEA_ACCESS_TOKEN
# ============================================================
if ! grep -E '^\| gitea \|' "$SETUP_MCP" | grep -q 'GITEA_ACCESS_TOKEN'; then
  fail "AC-11 (REQ-6): setup-mcp Step 3 gitea row does not list GITEA_ACCESS_TOKEN"
fi

# ============================================================
# REQ-6 / AC-12: gitea row lists GITEA_HOST AND does NOT list FORGEJO_(TOKEN|URL)
# ============================================================
if ! grep -E '^\| gitea \|' "$SETUP_MCP" | grep -q 'GITEA_HOST'; then
  fail "AC-12a (REQ-6): setup-mcp Step 3 gitea row does not list GITEA_HOST"
fi
if grep -E '^\| gitea \|' "$SETUP_MCP" | grep -qE 'FORGEJO_(TOKEN|URL)'; then
  fail "AC-12b (REQ-6 negative): setup-mcp Step 3 gitea row still references FORGEJO_TOKEN or FORGEJO_URL"
fi

# ============================================================
# REQ-10 / AC-17: if go install present, must reference gitea.com, NOT codeberg.org/goern/forgejo-mcp
# Conditional AC — passes if go install is absent
# ============================================================
if grep -q 'go install' "$SETUP_MCP"; then
  if ! grep -q 'go install.*gitea.com/gitea/gitea-mcp' "$SETUP_MCP"; then
    fail "AC-17 (REQ-10): go install present but does not reference gitea.com/gitea/gitea-mcp"
  fi
  if grep -q 'go install.*codeberg.org/goern/forgejo-mcp' "$SETUP_MCP"; then
    fail "AC-17 (REQ-10 negative): go install references old codeberg.org/goern/forgejo-mcp path"
  fi
fi
# If go install is absent, AC-17 passes silently (REQ-10 is OPTIONAL)

# ============================================================
# REQ-11 / AC-18: Step 1b reverse-mapping has gitea-mcp->gitea, NOT forgejo-mcp->gitea
# ============================================================
if ! grep -q 'gitea-mcp.*gitea' "$SETUP_MCP"; then
  fail "AC-18 (REQ-11): setup-mcp missing gitea-mcp->gitea reverse-mapping in Step 1b"
fi
if grep -q 'forgejo-mcp.*gitea' "$SETUP_MCP"; then
  fail "AC-18 (REQ-11 negative): setup-mcp Step 1b still has forgejo-mcp->gitea reverse-mapping"
fi

# ============================================================
# REQ-12 / AC-19: Step 5 sub-heading contains gitea-mcp
# ============================================================
if ! grep -qE '^### .*gitea-mcp' "$SETUP_MCP"; then
  fail "AC-19 (REQ-12): setup-mcp Step 5 has no sub-heading containing gitea-mcp"
fi

# ============================================================
# REQ-12 / AC-20 (NEGATIVE): Step 5 has NO sub-heading containing forgejo-mcp
# ============================================================
if grep -qE '^### .*forgejo-mcp' "$SETUP_MCP"; then
  fail "AC-20 (REQ-12 negative): setup-mcp Step 5 still has sub-heading containing forgejo-mcp"
fi

# ============================================================
# REQ-13 / AC-21: mcp-configuration.md gitea block command references gitea-mcp
# Use -A 8 to capture the gitea block following "gitea": JSON key
# ============================================================
if ! grep -A 8 '"gitea":' "$MCP_DOCS" | grep -q 'gitea-mcp'; then
  fail "AC-21 (REQ-13): mcp-configuration.md gitea block command does not reference gitea-mcp"
fi

# ============================================================
# REQ-13 / AC-22: gitea block has GITEA_HOST, GITEA_ACCESS_TOKEN, NOT FORGEJO_(URL|TOKEN)
# ============================================================
if ! grep -A 8 '"gitea":' "$MCP_DOCS" | grep -q 'GITEA_HOST'; then
  fail "AC-22a (REQ-13): mcp-configuration.md gitea block missing GITEA_HOST"
fi
if ! grep -A 8 '"gitea":' "$MCP_DOCS" | grep -q 'GITEA_ACCESS_TOKEN'; then
  fail "AC-22b (REQ-13): mcp-configuration.md gitea block missing GITEA_ACCESS_TOKEN"
fi
if grep -A 8 '"gitea":' "$MCP_DOCS" | grep -qE 'FORGEJO_(URL|TOKEN)'; then
  fail "AC-22c (REQ-13 negative): mcp-configuration.md gitea block still contains FORGEJO_URL or FORGEJO_TOKEN"
fi

# ============================================================
# REQ-14 / AC-23 (NEGATIVE): must NOT contain heading "## Gitea/Forgejo MCP server"
# ============================================================
if grep -qE '^## Gitea/Forgejo MCP server' "$MCP_DOCS"; then
  fail "AC-23 (REQ-14 negative): mcp-configuration.md still has old heading '## Gitea/Forgejo MCP server'"
fi

# ============================================================
# REQ-14 / AC-24: exactly ONE heading starting "## Gitea" that does NOT contain Forgejo
# Using && to ensure both count AND absence checks must pass (not ;)
# grep -c exits 0 even when count=0, so no fallback needed
# ============================================================
_gitea_heading_count=$(grep -cE '^## Gitea[^/]' "$MCP_DOCS" 2>/dev/null)
if [ "$_gitea_heading_count" != "1" ]; then
  fail "AC-24a (REQ-14): mcp-configuration.md does not have exactly one '## Gitea' heading (found: $_gitea_heading_count)"
fi
if grep -E '^## Gitea' "$MCP_DOCS" | grep -q 'Forgejo'; then
  fail "AC-24b (REQ-14 negative): the '## Gitea' heading in mcp-configuration.md still contains 'Forgejo'"
fi

# ============================================================
# REQ-24 / AC-36: this test file exists at tests/scenarios/
# ============================================================
if [ ! -f "$T1_FINAL" ]; then
  fail "AC-36 (REQ-24): tests/scenarios/v9-4-gitea-mcp-switch.sh does not exist (Phase 7 not yet run)"
fi

# ============================================================
# REQ-24 / AC-37: file begins with #!/usr/bin/env bash shebang
# ============================================================
if [ -f "$T1_FINAL" ]; then
  if ! head -1 "$T1_FINAL" | grep -q '^#!/usr/bin/env bash'; then
    fail "AC-37 (REQ-24): tests/scenarios/v9-4-gitea-mcp-switch.sh missing shebang #!/usr/bin/env bash"
  fi
fi

# ============================================================
# REQ-24 / AC-38: file is executable (x-bit set)
# SKIP semantics: on Windows filesystems x-bit is informational
# ============================================================
if [ -f "$T1_FINAL" ]; then
  if [ ! -x "$T1_FINAL" ]; then
    # On Windows, x-bit may not be set; emit SKIP signal via exit 77
    if uname -s 2>/dev/null | grep -qiE '(MINGW|MSYS|CYGWIN)'; then
      echo "SKIP: AC-38 — Windows filesystem, executable bit not enforced"
      exit 77
    fi
    fail "AC-38 (REQ-24): tests/scenarios/v9-4-gitea-mcp-switch.sh is not executable"
  fi
fi

# ============================================================
# REQ-24 + NFR-1 / AC-39 (NEGATIVE): this file must NOT invoke jq
# ============================================================
if [ -f "$T1_FINAL" ]; then
  if grep -vE '^\s*#|^\s*fail ' "$T1_FINAL" | grep -qE '\bjq\b'; then
    fail "AC-39 (REQ-24 + NFR-1 negative): tests/scenarios/v9-4-gitea-mcp-switch.sh invokes jq (forbidden)"
  fi
fi

# ============================================================
# REQ-20 / AC-31 (VISIBLE PRESENCE CHECK): CHANGELOG.md contains a v9.4.0 entry heading
# Simple jq-free heading-presence check (catches M3 mutation in visible scenarios).
# Full AC-31..AC-35 structure/content checks (line ordering, signal numbers, etc.)
# remain delegated to Phase 8 manual verification per formal-criteria.md §3.
# ============================================================
if ! grep -qE '^## (\[9\.4\.0\]|v9\.4\.0)' "$REPO_ROOT/CHANGELOG.md"; then
  fail "CHANGELOG.md is missing a v9.4.0 entry heading (catches M3) — full format check deferred to Phase 8"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v9.4.0 gitea-mcp switch — all T1 positive+negative assertions pass (AC-1..AC-24, AC-31 visible, AC-36..AC-39)"
exit "$FAIL"
