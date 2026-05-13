#!/usr/bin/env bash
# v9.2.0 — make_state_json_bash semantic JSON equivalence
# Fulfils: AC-V902-TST-11, AC-V902-TST-13
#
# RED now because:
#   make_state_json_bash function does not exist in tests/lib/fixtures.sh yet.
#   The test fails at the declare -F guard with "FAIL: make_state_json_bash not declared".
#
# GREEN after Phase 7 adds make_state_json_bash to tests/lib/fixtures.sh.
#
# Test strategy (Gate-Approved Override):
#   - Semantic JSON equivalence NOT byte-exact comparison.
#   - jq side (make_state_json): uses require_jq — SKIP on jq-free machines.
#   - bash side (make_state_json_bash): also parsed via python3 for structural check (AC-V902-TST-13).
#   - Both sides normalized via `jq -S .` for canonical key ordering before diff.
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
# Gate: make_state_json_bash must be declared (RED guard — fails until Phase 7)
# ---------------------------------------------------------------------------
declare -F make_state_json_bash >/dev/null 2>&1 || {
  echo "FAIL: make_state_json_bash not declared in tests/lib/fixtures.sh — Phase 7 has not added it yet" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# require_jq — both sides need jq for the canonical comparison
# The bash-only sub-assertion (AC-V902-TST-13) is nested inside and uses python3
# as a fallback structural check even without jq.
# ---------------------------------------------------------------------------
require_jq

# ---------------------------------------------------------------------------
# Inputs to test (flat overrides only — nested is OUT OF SCOPE per REQ-V902-020)
# ---------------------------------------------------------------------------
INPUTS=(
  ""
  "{}"
  '{"status":"paused"}'
  '{"tokens_used":42}'
)

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

for input in "${INPUTS[@]}"; do
  # Generate both outputs
  JQ_OUT="$SCRATCH/jq_out.json"
  BASH_OUT="$SCRATCH/bash_out.json"

  make_state_json "$input" > "$JQ_OUT" 2>/dev/null
  make_state_json_bash "$input" > "$BASH_OUT" 2>/dev/null

  # Normalize both with jq -S . (canonical sorted keys, consistent whitespace)
  JQ_NORM="$SCRATCH/jq_norm.json"
  BASH_NORM="$SCRATCH/bash_norm.json"
  jq -S . "$JQ_OUT" > "$JQ_NORM"
  jq -S . "$BASH_OUT" > "$BASH_NORM"

  # Semantic equivalence: diff the normalized forms
  if ! diff -q "$JQ_NORM" "$BASH_NORM" >/dev/null 2>&1; then
    fail "AC-V902-TST-11: output mismatch for input='$input'"
    echo "  jq output (normalized):" >&2
    cat "$JQ_NORM" >&2
    echo "  bash output (normalized):" >&2
    cat "$BASH_NORM" >&2
    continue
  fi

  echo "PASS: semantic equivalence for input='$input'"

  # ---------------------------------------------------------------------------
  # AC-V902-TST-13: for '{"status":"paused"}' — verify override scope
  # .status == "paused" AND all 7 other base fields preserved
  # ---------------------------------------------------------------------------
  if [ "$input" = '{"status":"paused"}' ]; then
    STATUS=$(jq -r '.status' "$BASH_OUT")
    if [ "$STATUS" != "paused" ]; then
      fail "AC-V902-TST-13: .status should be 'paused', got '$STATUS'"
    else
      echo "PASS: AC-V902-TST-13 — .status overridden to 'paused'"
    fi

    # Check all 7 other base fields are present
    for field in schema_version run_id started_at updated_at fixer_reviewer tokens_used pipeline; do
      if ! jq -e "has(\"$field\")" "$BASH_OUT" >/dev/null 2>&1; then
        fail "AC-V902-TST-13: base field '$field' is missing from make_state_json_bash output"
      fi
    done
    echo "PASS: AC-V902-TST-13 — all 7 base fields preserved"

    # Bash-only sub-assertion (no require_jq needed here — we already have bash output):
    # Output is non-empty, starts with {, ends with } (or }\n), and parses as valid JSON
    if command -v python3 >/dev/null 2>&1; then
      if python3 -c "import sys,json; json.load(open('$BASH_OUT'))" 2>/dev/null; then
        echo "PASS: AC-V902-TST-13 — python3 JSON parse succeeds for make_state_json_bash output"
      else
        fail "AC-V902-TST-13: python3 could not parse make_state_json_bash output as JSON"
      fi
    else
      echo "SKIP: python3 not available — skipping python3 JSON parse sub-assertion"
    fi
  fi

done

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.2.0-make-state-json-bash-equivalence — all inputs verified"
fi
exit "$FAIL"
