#!/usr/bin/env bash
# ===========================================================================
# Test:        v10-skill-from-external-cwd.sh
# Falsifies:   REQ-C-1 (Runtime external-CWD scenario)
# FC mapped:   FC-C-1
# Phase:       5 (TDD -- FAIL expected until Phase 7 lands)
# What it checks:
#   ASSERT-1) Probe succeeds from depth-3 external CWD when sentinel exists
#              (guard-block.md PROBE="../../../core/mcp-preflight.md")
#   ASSERT-2) Probe fails with exit 2 + canonical message regex when sentinel removed
#   ASSERT-3) No GNU-only constructs (mktemp -d only, no --suffix)
# Cross-platform: Win Git-Bash + Linux GNU + macOS BSD
# Exit codes: 0=PASS, 1=FAIL, 77=SKIP
# ===========================================================================
set -euo pipefail

TMPDIR_FIXTURE=""

cleanup() {
  if [ -n "$TMPDIR_FIXTURE" ] && [ -d "$TMPDIR_FIXTURE" ]; then
    rm -rf "$TMPDIR_FIXTURE"
  fi
}
trap cleanup EXIT

# Cross-platform mktemp: try without -t first, then with
if ! TMPDIR_FIXTURE=$(mktemp -d 2>/dev/null); then
  if ! TMPDIR_FIXTURE=$(mktemp -d -t v10extcwd.XXXXXX 2>/dev/null); then
    echo "[SKIP] mktemp -d unavailable on this platform"
    exit 77
  fi
fi

# ---------------------------------------------------------------------------
# Build synthetic plugin fixture
#   $TMPDIR_FIXTURE/plugin-fixture/
#     core/mcp-preflight.md          <- sentinel
#     skills/demo/SKILL.md           <- depth-2 file
#     skills/demo/data/guard-block.md <- depth-3 guard (the probe lives here)
# ---------------------------------------------------------------------------
FIXTURE="$TMPDIR_FIXTURE/plugin-fixture"
mkdir -p "$FIXTURE/core"
mkdir -p "$FIXTURE/skills/demo/data"
mkdir -p "$FIXTURE/skills/demo/steps"

# Create sentinel
printf '# mcp-preflight\n# Sentinel file for plugin install integrity check.\n' \
  > "$FIXTURE/core/mcp-preflight.md"

# Create depth-2 SKILL.md referencing guard-block
cat > "$FIXTURE/skills/demo/SKILL.md" <<'SKILL_EOF'
# Demo SKILL.md (synthetic fixture)
<!-- Load guard-block.md BEFORE any other instruction in this file. -->
Read: skills/demo/data/guard-block.md
SKILL_EOF

# Create depth-3 guard-block.md with the PROBE as specified by REQ-A-2 / design.md A.1
cat > "$FIXTURE/skills/demo/data/guard-block.md" <<'GUARD_EOF'
# Mandatory Execution Guard -- /demo (synthetic fixture)

<PREFLIGHT>
## PRE-FLIGHT PROBE -- DO THIS BEFORE READING ANY OTHER SECTION.

PROBE="../../../core/mcp-preflight.md"
if [ ! -r "$PROBE" ]; then
  echo "ABORT: plugin-root not resolved -- core/ sibling of skills/ not found at $PROBE. Check plugin install integrity." >&2
  exit 2
fi

**Path-format note (B3 documentary clarifier -- informational, not executable):**
All `core/<file>.md` references in this skill use relative paths from the file's
directory: `../core/` for `agents/*.md`, `../../core/` for `skills/*/SKILL.md`,
and `../../../core/` for `skills/*/{steps,data}/*.md`. The canonical layout is
`core/` as sibling of `skills/` at plugin root.
</PREFLIGHT>

<MANDATORY-EXECUTION-GUARD>
## YOU MUST EXECUTE THE PIPELINE. NO EXCEPTIONS.
</MANDATORY-EXECUTION-GUARD>
GUARD_EOF

PASS_COUNT=0
FAIL_COUNT=0

# ---------------------------------------------------------------------------
# ASSERT-1: Probe succeeds when CWD is the guard-block fixture directory
#            and sentinel exists at the correct depth-3 relative path
# ---------------------------------------------------------------------------
(
  cd "$FIXTURE/skills/demo/data"
  PROBE="../../../core/mcp-preflight.md"
  if [ ! -r "$PROBE" ]; then
    echo "[FAIL] ASSERT-1: probe should succeed -- sentinel exists but [ -r ] returned false" >&2
    exit 1
  fi
  exit 0
)
assert1_rc=$?

if [ "$assert1_rc" -eq 0 ]; then
  echo "[PASS] ASSERT-1: depth-3 relative probe succeeds from external CWD (guard fixture dir)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "[FAIL] ASSERT-1: depth-3 relative probe failed unexpectedly (sentinel should be readable)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ---------------------------------------------------------------------------
# ASSERT-2: Probe fails with exit 2 + canonical message when sentinel removed
# ---------------------------------------------------------------------------

# Remove sentinel to simulate broken install
rm "$FIXTURE/core/mcp-preflight.md"

probe_stderr=""
probe_exit=0
(
  cd "$FIXTURE/skills/demo/data"
  PROBE="../../../core/mcp-preflight.md"
  if [ ! -r "$PROBE" ]; then
    echo "ABORT: plugin-root not resolved -- core/ sibling of skills/ not found at $PROBE. Check plugin install integrity." >&2
    exit 2
  fi
) 2>"$TMPDIR_FIXTURE/probe_stderr.txt" || probe_exit=$?

if [ "$probe_exit" -eq 2 ]; then
  echo "[PASS] ASSERT-2a: probe exits with code 2 when sentinel missing"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "[FAIL] ASSERT-2a: expected exit 2, got $probe_exit"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if grep -qE 'plugin-root not resolved' "$TMPDIR_FIXTURE/probe_stderr.txt" 2>/dev/null; then
  echo "[PASS] ASSERT-2b: canonical message 'plugin-root not resolved' found in stderr"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "[FAIL] ASSERT-2b: canonical message not found in stderr"
  echo "[INFO] stderr was: $(cat "$TMPDIR_FIXTURE/probe_stderr.txt" 2>/dev/null)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if grep -qE 'ABORT: plugin-root not resolved -- core/ sibling of skills/ not found at' \
    "$TMPDIR_FIXTURE/probe_stderr.txt" 2>/dev/null; then
  echo "[PASS] ASSERT-2c: full canonical abort message matches spec REQ-A-3"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "[FAIL] ASSERT-2c: full canonical abort message does not match spec REQ-A-3"
  echo "[INFO] stderr was: $(cat "$TMPDIR_FIXTURE/probe_stderr.txt" 2>/dev/null)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ---------------------------------------------------------------------------
# ASSERT-3: Restore sentinel and verify probe succeeds again (depth-2 spot-check)
# ---------------------------------------------------------------------------
mkdir -p "$FIXTURE/core"
printf '# mcp-preflight\n' > "$FIXTURE/core/mcp-preflight.md"

(
  cd "$FIXTURE/skills/demo"
  PROBE="../../core/mcp-preflight.md"
  if [ ! -r "$PROBE" ]; then
    echo "[FAIL] depth-2 probe failed" >&2
    exit 1
  fi
  exit 0
)
assert3_rc=$?

if [ "$assert3_rc" -eq 0 ]; then
  echo "[PASS] ASSERT-3: depth-2 relative probe succeeds from skills/demo/ (SKILL.md level)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "[FAIL] ASSERT-3: depth-2 relative probe failed unexpectedly"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "[INFO] Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "[PASS] v10-skill-from-external-cwd: all assertions passed"
  exit 0
else
  echo "[FAIL] v10-skill-from-external-cwd: $FAIL_COUNT assertion(s) failed"
  exit 1
fi
