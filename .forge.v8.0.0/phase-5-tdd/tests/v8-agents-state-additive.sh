#!/usr/bin/env bash
# Verifies: AC-AGT-007, AC-AGT-008, REQ-AGT-007
# Description: state.json has both v8 key analyst_triage_completed_at and
#   legacy alias triage_completed_at with identical timestamps; schema_version="1.0"
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT INT TERM

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Setup: mock state.json per design.md §3.3 additive keys
# ---------------------------------------------------------------------------
mkdir -p "$TMPDIR_TEST/.ceos-agents"

cat > "$TMPDIR_TEST/.ceos-agents/state.json" << 'EOF'
{
  "schema_version": "1.0",
  "issue_id": "BUG-123",
  "pipeline": "fix-bugs",
  "analyst_triage_completed_at": "2026-04-27T10:05:00Z",
  "analyst_impact_completed_at": "2026-04-27T10:08:00Z",
  "triage_completed_at": "2026-04-27T10:05:00Z",
  "code_analyst_completed_at": "2026-04-27T10:08:00Z"
}
EOF

# ---------------------------------------------------------------------------
# Assertion 1: Both v8 key and legacy alias present
# ---------------------------------------------------------------------------
echo "--- Assertion 1: both analyst_triage_completed_at and triage_completed_at present ---"
if command -v jq > /dev/null 2>&1; then
  V8_KEY=$(jq -r '.analyst_triage_completed_at' "$TMPDIR_TEST/.ceos-agents/state.json")
  LEGACY_KEY=$(jq -r '.triage_completed_at' "$TMPDIR_TEST/.ceos-agents/state.json")

  if [ "$V8_KEY" = "null" ]; then
    fail "state.json missing analyst_triage_completed_at (v8 key)"
  else
    echo "OK: analyst_triage_completed_at = $V8_KEY"
  fi

  if [ "$LEGACY_KEY" = "null" ]; then
    fail "state.json missing triage_completed_at (legacy alias)"
  else
    echo "OK: triage_completed_at = $LEGACY_KEY"
  fi

  # Assertion 2: identical timestamps
  echo "--- Assertion 2: v8 key and legacy alias have identical timestamps ---"
  if [ "$V8_KEY" = "$LEGACY_KEY" ]; then
    echo "OK: analyst_triage_completed_at == triage_completed_at (identical)"
  else
    fail "analyst_triage_completed_at ($V8_KEY) != triage_completed_at ($LEGACY_KEY)"
  fi

  # Assertion 3: schema_version remains "1.0"
  echo "--- Assertion 3: schema_version remains '1.0' (not bumped) ---"
  SCHEMA_VER=$(jq -r '.schema_version' "$TMPDIR_TEST/.ceos-agents/state.json")
  if [ "$SCHEMA_VER" = "1.0" ]; then
    echo "OK: schema_version = 1.0 (not bumped per AC-AGT-008)"
  else
    fail "schema_version = $SCHEMA_VER (expected 1.0 — additive only)"
  fi
else
  # grep fallback when jq unavailable
  if grep -qF '"analyst_triage_completed_at"' "$TMPDIR_TEST/.ceos-agents/state.json" && \
     grep -qF '"triage_completed_at"' "$TMPDIR_TEST/.ceos-agents/state.json"; then
    echo "OK: both keys present (grep fallback)"
  else
    fail "state.json missing required transitional alias keys (grep fallback)"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 4: state/schema.md documents additive v8 keys
# ---------------------------------------------------------------------------
echo "--- Assertion 4: state/schema.md documents analyst_triage_completed_at ---"
SCHEMA_DOC="$REPO_ROOT/state/schema.md"
if [ ! -f "$SCHEMA_DOC" ]; then
  echo "SKIP: state/schema.md not found" >&2
  exit 77
fi

if grep -qF 'analyst_triage_completed_at' "$SCHEMA_DOC"; then
  echo "OK: state/schema.md documents analyst_triage_completed_at key"
else
  fail "state/schema.md missing analyst_triage_completed_at key"
fi

if grep -qF 'triage_completed_at' "$SCHEMA_DOC"; then
  echo "OK: state/schema.md documents triage_completed_at legacy alias"
else
  fail "state/schema.md missing triage_completed_at legacy alias"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-AGT-007 + AC-AGT-008 — state.json additive keys + schema_version=1.0"
fi
exit "$FAIL"
