#!/usr/bin/env bash
# v9.2.0 — overlay_source=toml runtime coverage
# Fulfils: AC-V902-TST-01, AC-V902-TST-02, AC-V902-TST-04, AC-V902-TST-05, AC-V902-TST-08, AC-V902-TST-09
#
# RED now because:
#   1. tests/fixtures/v9-overlay/ does not exist in production tests/fixtures/ yet
#   2. resolve_overlay() in toml-merge.sh doesn't yet emit md_rejected (Phase 7 will fix)
#
# GREEN after Phase 7 stages:
#   - tests/fixtures/v9-overlay/ (from .forge/phase-5-tdd/fixtures/v9-overlay/)
#   - resolve_overlay() change is NOT required for toml branch — this test uses the existing path
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
# AC-V902-TST-09: fixture README must exist
# ---------------------------------------------------------------------------
FIXTURE_DIR="$REPO_ROOT/tests/fixtures/v9-overlay"

if [ ! -f "$FIXTURE_DIR/README.md" ]; then
  echo "FAIL: AC-V902-TST-09 — tests/fixtures/v9-overlay/README.md does not exist" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# AC-V902-TST-04: fixture directory structure must exist
# ---------------------------------------------------------------------------
for subdir in toml none md-rejected expected; do
  if [ ! -d "$FIXTURE_DIR/$subdir" ]; then
    echo "FAIL: AC-V902-TST-04 — tests/fixtures/v9-overlay/$subdir/ does not exist" >&2
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# AC-V902-TST-05: TOML fixture must exist and be non-empty
# ---------------------------------------------------------------------------
TOML_FIXTURE="$FIXTURE_DIR/toml/analyst.toml"
if [ ! -f "$TOML_FIXTURE" ]; then
  echo "FAIL: AC-V902-TST-05 — tests/fixtures/v9-overlay/toml/analyst.toml does not exist" >&2
  exit 1
fi
if [ ! -s "$TOML_FIXTURE" ]; then
  echo "FAIL: AC-V902-TST-05 — tests/fixtures/v9-overlay/toml/analyst.toml is empty" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# AC-V902-TST-08: expected log files must exist and be non-empty
# ---------------------------------------------------------------------------
for logfile in toml.log none.log md-rejected.log; do
  if [ ! -f "$FIXTURE_DIR/expected/$logfile" ]; then
    echo "FAIL: AC-V902-TST-08 — tests/fixtures/v9-overlay/expected/$logfile does not exist" >&2
    exit 1
  fi
  if [ ! -s "$FIXTURE_DIR/expected/$logfile" ]; then
    echo "FAIL: AC-V902-TST-08 — tests/fixtures/v9-overlay/expected/$logfile is empty" >&2
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# AC-V902-TST-01: resolve_overlay with a toml file → OVERLAY_SOURCE=toml
# ---------------------------------------------------------------------------

# Source the library
# shellcheck source=/dev/null
. "$REPO_ROOT/skills/setup-agents/lib/toml-merge.sh"

# Set up scratch customization dir with the toml fixture
CUSTOMIZATION_DIR="$SCRATCH/customization"
mkdir -p "$CUSTOMIZATION_DIR"
cp "$TOML_FIXTURE" "$CUSTOMIZATION_DIR/analyst.toml"

# Set PIPELINE_LOG to scratch dir so log_overlay_provenance writes there
mkdir -p "$SCRATCH/.ceos-agents"
ORIG_DIR="$(pwd)"
cd "$SCRATCH"

# Call resolve_overlay — it writes provenance to .ceos-agents/pipeline.log (relative to CWD)
OVERLAY_SOURCE=""
OVERLAY_PATH=""
resolve_overlay "analyst" "$CUSTOMIZATION_DIR" '{}' >/dev/null 2>/dev/null || true

cd "$ORIG_DIR"

# Assertion 1: OVERLAY_SOURCE variable equals "toml"
if [ "$OVERLAY_SOURCE" != "toml" ]; then
  echo "FAIL: AC-V902-TST-01 — OVERLAY_SOURCE='$OVERLAY_SOURCE', expected 'toml'" >&2
  exit 1
fi
echo "PASS assertion 1: OVERLAY_SOURCE=toml"

# ---------------------------------------------------------------------------
# AC-V902-TST-02 (AC-V902-TST-01 Assertion 2): pipeline.log must contain the provenance line
# ---------------------------------------------------------------------------
PIPELINE_LOG="$SCRATCH/.ceos-agents/pipeline.log"
if [ ! -f "$PIPELINE_LOG" ]; then
  echo "FAIL: AC-V902-TST-02 — pipeline.log not created at $PIPELINE_LOG" >&2
  exit 1
fi

# The log line format is: agent={name} overlay_source={source} overlay_path={path}
# Path is dynamic (scratch dir), so we grep for the stable prefix
if ! grep -q "agent=analyst overlay_source=toml overlay_path=" "$PIPELINE_LOG"; then
  echo "FAIL: AC-V902-TST-02 — pipeline.log does not contain expected provenance line" >&2
  echo "  Expected pattern: agent=analyst overlay_source=toml overlay_path=..." >&2
  echo "  Actual log contents:" >&2
  cat "$PIPELINE_LOG" >&2
  exit 1
fi
echo "PASS assertion 2: pipeline.log contains agent=analyst overlay_source=toml overlay_path=..."

echo "PASS: v9.2.0-overlay-toml — overlay_source=toml verified"
exit 0
