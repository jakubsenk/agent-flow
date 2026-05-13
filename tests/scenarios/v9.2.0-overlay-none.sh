#!/usr/bin/env bash
# v9.2.0 — overlay_source=none runtime coverage
# Fulfils: AC-V902-TST-03, AC-V902-TST-06, AC-V902-TST-08
#
# RED now because:
#   1. tests/fixtures/v9-overlay/ does not exist in production tests/fixtures/ yet
#
# GREEN after Phase 7 stages tests/fixtures/v9-overlay/ directory.
#
# NOTE: SCRIPT_DIR/../.. from .forge/phase-5-tdd/scenarios/ resolves two levels up to repo root.
# After Phase 7 copies this file to tests/scenarios/, SCRIPT_DIR/../.. also resolves to repo root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# Fallback for running from forge staging (.forge/phase-5-tdd/scenarios/ is 3 levels below repo root)
[ -f "$REPO_ROOT/tests/lib/fixtures.sh" ] || REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

SCRATCH="$(setup_scratch)"
trap "rm -rf '$SCRATCH'" EXIT

# ---------------------------------------------------------------------------
# AC-V902-TST-06: tests/fixtures/v9-overlay/none/ directory must exist
# ---------------------------------------------------------------------------
FIXTURE_DIR="$REPO_ROOT/tests/fixtures/v9-overlay"

if [ ! -d "$FIXTURE_DIR/none" ]; then
  echo "FAIL: AC-V902-TST-06 — tests/fixtures/v9-overlay/none/ does not exist" >&2
  exit 1
fi
echo "PASS assertion 0: tests/fixtures/v9-overlay/none/ exists"

# ---------------------------------------------------------------------------
# AC-V902-TST-08: expected/none.log must exist and be non-empty
# ---------------------------------------------------------------------------
NONE_LOG="$FIXTURE_DIR/expected/none.log"
if [ ! -f "$NONE_LOG" ]; then
  echo "FAIL: AC-V902-TST-08 — tests/fixtures/v9-overlay/expected/none.log does not exist" >&2
  exit 1
fi
if [ ! -s "$NONE_LOG" ]; then
  echo "FAIL: AC-V902-TST-08 — tests/fixtures/v9-overlay/expected/none.log is empty" >&2
  exit 1
fi
echo "PASS assertion 0b: tests/fixtures/v9-overlay/expected/none.log exists and non-empty"

# ---------------------------------------------------------------------------
# AC-V902-TST-03 Assertion 1: resolve_overlay with no overlay file → OVERLAY_SOURCE=none
# ---------------------------------------------------------------------------

# Source the library
# shellcheck source=/dev/null
. "$REPO_ROOT/skills/setup-agents/lib/toml-merge.sh"

# Set up scratch customization dir with NO overlay files for the agent
CUSTOMIZATION_DIR="$SCRATCH/customization"
mkdir -p "$CUSTOMIZATION_DIR"
# Intentionally: no nonexistent-agent.toml, no nonexistent-agent.md

mkdir -p "$SCRATCH/.ceos-agents"
ORIG_DIR="$(pwd)"
cd "$SCRATCH"

OVERLAY_SOURCE=""
OVERLAY_PATH=""
resolve_overlay "nonexistent-agent" "$CUSTOMIZATION_DIR" '{}' >/dev/null 2>/dev/null || true

cd "$ORIG_DIR"

# Assertion 1: OVERLAY_SOURCE variable equals "none"
if [ "$OVERLAY_SOURCE" != "none" ]; then
  echo "FAIL: AC-V902-TST-03 — OVERLAY_SOURCE='$OVERLAY_SOURCE', expected 'none'" >&2
  exit 1
fi
echo "PASS assertion 1: OVERLAY_SOURCE=none"

# ---------------------------------------------------------------------------
# AC-V902-TST-03 Assertion 2: pipeline.log matches expected format
# Log line format: agent={name} overlay_source=none overlay_path=(none)
# ---------------------------------------------------------------------------
PIPELINE_LOG="$SCRATCH/.ceos-agents/pipeline.log"
if [ ! -f "$PIPELINE_LOG" ]; then
  echo "FAIL: AC-V902-TST-03 — pipeline.log not created at $PIPELINE_LOG" >&2
  exit 1
fi

if ! grep -qF "agent=nonexistent-agent overlay_source=none overlay_path=(none)" "$PIPELINE_LOG"; then
  echo "FAIL: AC-V902-TST-03 — pipeline.log does not contain expected provenance line" >&2
  echo "  Expected: agent=nonexistent-agent overlay_source=none overlay_path=(none)" >&2
  echo "  Actual log contents:" >&2
  cat "$PIPELINE_LOG" >&2
  exit 1
fi
echo "PASS assertion 2: pipeline.log contains agent=nonexistent-agent overlay_source=none overlay_path=(none)"

echo "PASS: v9.2.0-overlay-none — overlay_source=none verified"
exit 0
