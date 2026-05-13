#!/usr/bin/env bash
# Coverage note: tests inline bash snippet from core/agent-override-injector.md Step 2, not a callable library. Promote to callable library in v9.4.0 if extracted.
# v9.2.0 — overlay_source=md_rejected runtime coverage
# Fulfils: AC-V902-TST-04, AC-V902-TST-05 (negative), AC-V902-TST-07, AC-V902-TST-08
#
# RED now because:
#   1. tests/fixtures/v9-overlay/ does not exist in production tests/fixtures/ yet
#   2. The injector Step 2 short-circuit (md_rejected path) lives in core/agent-override-injector.md
#      which is a markdown prose doc — we test the BASH implementation that Phase 7 must ship.
#      The test drives the injector logic directly using the same bash snippet from the injector doc.
#
# GREEN after Phase 7:
#   - stages tests/fixtures/v9-overlay/
#   - ensures the md_rejected short-circuit is callable as a bash function / script
#
# Design note: Since agent-override-injector.md defines the injector as markdown prose (not a
# .sh library), this test inlines the injector Step 2 logic to keep it self-contained. The
# actual production path is exercised end-to-end only in Phase 9 manual verification. This test
# is a structural + provenance-format assertion against the bash idiom from the injector doc.
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
# AC-V902-TST-07: md-rejected fixture must exist; no .toml counterpart
# ---------------------------------------------------------------------------
FIXTURE_DIR="$REPO_ROOT/tests/fixtures/v9-overlay"

MD_FIXTURE="$FIXTURE_DIR/md-rejected/analyst.md"
TOML_COUNTERPART="$FIXTURE_DIR/md-rejected/analyst.toml"

if [ ! -f "$MD_FIXTURE" ]; then
  echo "FAIL: AC-V902-TST-07 — tests/fixtures/v9-overlay/md-rejected/analyst.md does not exist" >&2
  exit 1
fi
echo "PASS assertion 0a: tests/fixtures/v9-overlay/md-rejected/analyst.md exists"

if [ -f "$TOML_COUNTERPART" ]; then
  echo "FAIL: AC-V902-TST-07 — tests/fixtures/v9-overlay/md-rejected/analyst.toml MUST NOT exist (absence triggers md_rejected path)" >&2
  exit 1
fi
echo "PASS assertion 0b: tests/fixtures/v9-overlay/md-rejected/analyst.toml correctly absent"

# ---------------------------------------------------------------------------
# AC-V902-TST-08: expected/md-rejected.log must exist and be non-empty
# ---------------------------------------------------------------------------
MD_REJECTED_LOG="$FIXTURE_DIR/expected/md-rejected.log"
if [ ! -f "$MD_REJECTED_LOG" ]; then
  echo "FAIL: AC-V902-TST-08 — tests/fixtures/v9-overlay/expected/md-rejected.log does not exist" >&2
  exit 1
fi
if [ ! -s "$MD_REJECTED_LOG" ]; then
  echo "FAIL: AC-V902-TST-08 — tests/fixtures/v9-overlay/expected/md-rejected.log is empty" >&2
  exit 1
fi
echo "PASS assertion 0c: tests/fixtures/v9-overlay/expected/md-rejected.log exists and non-empty"

# ---------------------------------------------------------------------------
# Inline the injector Step 2 short-circuit logic (from core/agent-override-injector.md)
# to exercise the md_rejected path in a controlled manner.
# ---------------------------------------------------------------------------

# Source the library for log_overlay_provenance
# shellcheck source=/dev/null
. "$REPO_ROOT/skills/setup-agents/lib/toml-merge.sh"

# Set up scratch overlay dir: only .md present, no .toml
OVERRIDE_PATH="$SCRATCH/customization"
mkdir -p "$OVERRIDE_PATH"
cp "$MD_FIXTURE" "$OVERRIDE_PATH/analyst.md"
# Confirm: no .toml
[ ! -f "$OVERRIDE_PATH/analyst.toml" ] || { echo "FAIL: test setup error — toml should not exist" >&2; exit 1; }

mkdir -p "$SCRATCH/.ceos-agents"
ORIG_DIR="$(pwd)"
cd "$SCRATCH"

# Run the injector Step 2 logic inline (exact snippet from core/agent-override-injector.md)
AGENT_NAME="analyst"
additional_instructions=""
STDERR_OUTPUT=""

run_injector_step2() {
  local agent_name="$1"
  local override_path="$2"
  local toml_path="${override_path}/${agent_name}.toml"
  local md_path="${override_path}/${agent_name}.md"
  local _additional_instructions=""

  if [ ! -f "$toml_path" ] && [ -f "$md_path" ]; then
    # .md-only: v9.0.0 hard removal — emit [ERROR], log provenance, return empty
    echo "[ERROR] Legacy .md overlay format removed in v9.0.0; manual conversion required — see docs/guides/migration-v7-to-v8.md (the /migrate-config skill that previously automated this was removed in v9.5.0)." >&2
    log_overlay_provenance "$agent_name" "md_rejected" "$md_path"
    _additional_instructions=""
  fi
  printf '%s' "$_additional_instructions"
}

# Capture stderr to check for [ERROR] line
STDERR_FILE="$SCRATCH/stderr.txt"
additional_instructions="$(run_injector_step2 "$AGENT_NAME" "$OVERRIDE_PATH" 2>"$STDERR_FILE")"

cd "$ORIG_DIR"

# ---------------------------------------------------------------------------
# Assertion 1 (AC-V902-TST-05 negative): additional_instructions is empty after Step 2
# ---------------------------------------------------------------------------
if [ -n "$additional_instructions" ]; then
  echo "FAIL: AC-V902-TST-05 (negative) — additional_instructions should be empty after md_rejected, got: '$additional_instructions'" >&2
  exit 1
fi
echo "PASS assertion 1: additional_instructions is empty (injector Step 2 short-circuit fired)"

# ---------------------------------------------------------------------------
# Assertion 2: stderr contains [ERROR] line referencing "Legacy .md overlay format"
# ---------------------------------------------------------------------------
if ! grep -q "\[ERROR\] Legacy .md overlay format" "$STDERR_FILE"; then
  echo "FAIL: AC-V902-TST-04 — stderr does not contain expected [ERROR] line" >&2
  echo "  Expected: [ERROR] Legacy .md overlay format..." >&2
  echo "  Actual stderr:" >&2
  cat "$STDERR_FILE" >&2
  exit 1
fi
echo "PASS assertion 2: stderr contains [ERROR] Legacy .md overlay format"

# ---------------------------------------------------------------------------
# Assertion 3: pipeline.log contains md_rejected provenance line
# ---------------------------------------------------------------------------
PIPELINE_LOG="$SCRATCH/.ceos-agents/pipeline.log"
if [ ! -f "$PIPELINE_LOG" ]; then
  echo "FAIL: AC-V902-TST-08 — pipeline.log not created at $PIPELINE_LOG" >&2
  exit 1
fi

if ! grep -q "agent=analyst overlay_source=md_rejected overlay_path=" "$PIPELINE_LOG"; then
  echo "FAIL: AC-V902-TST-08 — pipeline.log does not contain md_rejected provenance line" >&2
  echo "  Expected pattern: agent=analyst overlay_source=md_rejected overlay_path=..." >&2
  echo "  Actual log contents:" >&2
  cat "$PIPELINE_LOG" >&2
  exit 1
fi
echo "PASS assertion 3: pipeline.log contains agent=analyst overlay_source=md_rejected overlay_path=..."

echo "PASS: v9.2.0-overlay-md-rejected — overlay_source=md_rejected verified"
exit 0
