#!/usr/bin/env bash
# tests/lib/fixtures.sh — DSL-lite shared helpers for v6.10.0+ functional test scenarios.
# Phase 7 fixer copies this file to tests/lib/fixtures.sh.
# See CONTRIBUTING.md "Functional test scenarios — security expectations".
# REQ-T1-4 API surface: exactly 3 functions (make_state_json, setup_scratch, require_jq).

set -uo pipefail

# ---------------------------------------------------------------------------
# make_state_json <json-fragment>
#
# Build a canonical state.json synthesis using jq -n.
# Input: a json fragment (string). Output: valid JSON on stdout.
# Returns 0 on success; 2 if jq missing; non-zero if fragment malformed.
#
make_state_json() {
  command -v jq >/dev/null 2>&1 || return 2
  local overlay="${1:-\{\}}"
  jq -n --argjson overlay "$overlay" '
    {
      schema_version: "1.0",
      run_id: "TEST-0_20260423T120000Z",
      status: "running"
    } + $overlay
  '
}

# ---------------------------------------------------------------------------
# setup_scratch
#
# Create a temp directory and register cleanup. Exports SCRATCH.
#
setup_scratch() {
  SCRATCH="$(mktemp -d 2>/dev/null || mktemp -d -t 'v6100fx')"
  export SCRATCH
  trap 'rm -rf "$SCRATCH"' EXIT
}

# ---------------------------------------------------------------------------
# require_jq
#
# If jq missing AND FIXTURES_REQUIRE_JQ=1, exit 77 (SKIP).
# Otherwise set HAVE_JQ=0/1 and return.
#
require_jq() {
  if command -v jq >/dev/null 2>&1; then
    HAVE_JQ=1
    export HAVE_JQ
    return 0
  fi
  HAVE_JQ=0
  export HAVE_JQ
  if [ "${FIXTURES_REQUIRE_JQ:-0}" = "1" ]; then
    echo "SKIP: jq not available (FIXTURES_REQUIRE_JQ=1)" >&2
    exit 77
  fi
  return 0
}
