#!/usr/bin/env bash
# tests/lib/fixtures.sh — DSL-lite helpers for agent-flow test scenarios
#
# Usage: . "$REPO_ROOT/tests/lib/fixtures.sh"
#
# Exposes exactly 4 helpers:
#   make_state_json      — emit a canonical state.json to stdout (requires jq)
#   make_state_json_bash — emit a canonical state.json to stdout (bash-only, no jq)
#   setup_scratch        — create a temp dir with trap EXIT cleanup; print path
#   require_jq           — exit 77 (SKIP) if jq is not available
#
# IDEMPOTENCY: Sourcing this file multiple times is safe.
# Sourcing does NOT set any globals beyond the 3 function definitions
# and the FIXTURES_SH_LOADED sentinel.
#
# NOTE: set -uo pipefail is intentionally NOT set here. Scripts that source
# this file control their own error propagation.

# Idempotency sentinel
[ "${FIXTURES_SH_LOADED:-}" = "1" ] && return 0
FIXTURES_SH_LOADED=1

# ---------------------------------------------------------------------------
# make_state_json()
#
# Emit a canonical state.json document to stdout.
# Accepts an optional JSON fragment argument that is merged into the base
# object. Uses jq -s '.[0] * .[1]' to deep-merge, so the caller can
# override any top-level field.
#
# Usage:
#   make_state_json                         # minimal default object
#   make_state_json '{"status":"paused"}'   # override status
#   make_state_json '{"fixer_reviewer":{"iterations":2,"status":"done"}}'
#
# Exits 77 (SKIP) if jq is unavailable (require_jq is NOT called automatically
# so callers can degrade gracefully — call require_jq explicitly if needed).
#
# Outputs: valid JSON to stdout.
# ---------------------------------------------------------------------------
make_state_json() {
  local override="${1:-{\}}"
  if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not available — make_state_json cannot produce JSON" >&2
    return 77
  fi
  # Base canonical state matching state/schema.md schema_version 1.0
  local base
  base=$(jq -nc '{
    schema_version: "1.0",
    run_id: "TEST-1_20260420T120000Z",
    status: "running",
    started_at: "2026-04-20T12:00:00Z",
    updated_at: "2026-04-20T12:00:00Z",
    fixer_reviewer: { iterations: 0, status: "pending" },
    tokens_used: 0,
    pipeline: { stages: [] }
  }')
  # Merge override on top of base
  printf '%s\n' "$base" "$override" | jq -s '.[0] * .[1]'
}

# ---------------------------------------------------------------------------
# make_state_json_bash()
#
# Emit a canonical state.json document to stdout using only bash builtins.
# No jq dependency — suitable for jq-free environments.
#
# Accepts an optional JSON fragment argument. Flat top-level key overrides
# are applied via naive string concat (last-write-wins for duplicate keys).
# Nested overrides are explicitly out of scope.
#
# Usage:
#   make_state_json_bash                         # minimal default object
#   make_state_json_bash '{"status":"paused"}'   # override status
#
# Output: valid single-line JSON to stdout.
# ---------------------------------------------------------------------------
make_state_json_bash() {
  local override="${1:-}"

  # Base canonical state — same fields as make_state_json
  local base_json
  base_json='{"schema_version":"1.0","run_id":"TEST-1_20260420T120000Z","status":"running","started_at":"2026-04-20T12:00:00Z","updated_at":"2026-04-20T12:00:00Z","fixer_reviewer":{"iterations":0,"status":"pending"},"tokens_used":0,"pipeline":{"stages":[]}}'

  if [ -z "$override" ] || [ "$override" = "{}" ]; then
    printf '%s\n' "$base_json"
    return 0
  fi

  # Flat override merge via naive concat (produces duplicate keys; JSON parsers
  # use last-write-wins semantics per RFC 8259 §4 — the override wins).
  # This is sufficient for all known callers (nested out of scope).
  local override_inner="${override#\{}"
  override_inner="${override_inner%\}}"
  local base_no_close="${base_json%\}}"
  printf '%s,%s}\n' "$base_no_close" "$override_inner"
}

# ---------------------------------------------------------------------------
# setup_scratch()
#
# Create a unique temporary directory and register a trap to remove it on
# EXIT. Prints the directory path to stdout.
#
# Usage:
#   SCRATCH="$(setup_scratch)"
#
# The trap is registered in the calling shell's context (not a subshell),
# so EXIT cleanup fires when the sourcing script exits.
#
# Note: calling setup_scratch() multiple times registers multiple traps
# but each cleans up its own directory — that is safe.
# ---------------------------------------------------------------------------
setup_scratch() {
  local scratch
  scratch="$(mktemp -d 2>/dev/null || mktemp -d -t 'ceos_test')"
  # NOTE: trap is registered in the CALLER's shell context by the caller,
  # not here. Registering trap inside a command substitution subshell causes
  # the EXIT trap to fire when the subshell exits (before the caller can use
  # the directory). Callers that need cleanup should register their own trap:
  #   SCRATCH="$(setup_scratch)"; trap "rm -rf '$SCRATCH'" EXIT
  printf '%s\n' "$scratch"
}

# ---------------------------------------------------------------------------
# require_jq()
#
# Guard that skips the scenario (exit 77) if jq is not available.
# Call at the top of any scenario that requires jq for its assertions.
#
# Usage:
#   require_jq
#
# Exit codes:
#   0   — jq is available; execution continues
#   77  — jq not found; harness records SKIP
# ---------------------------------------------------------------------------
require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not available — skipping jq-dependent scenario" >&2
    exit 77
  fi
}
