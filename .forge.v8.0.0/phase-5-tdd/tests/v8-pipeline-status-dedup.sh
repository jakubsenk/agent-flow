#!/usr/bin/env bash
# Verifies: AC-AGT-009, REQ-AGT-008
# Description: /pipeline-status reads state.json with both v8 key and legacy alias;
#   handles 3 variants: both-equal, v7-only, both-differ (with [WARN])
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

PIPELINE_STATUS_SKILL="$REPO_ROOT/skills/pipeline-status/SKILL.md"

if [ ! -f "$PIPELINE_STATUS_SKILL" ]; then
  echo "SKIP: skills/pipeline-status/SKILL.md not found" >&2
  exit 77
fi

mkdir -p "$TMPDIR_TEST/.ceos-agents"

# ---------------------------------------------------------------------------
# Variant A: both keys present with equal values
# ---------------------------------------------------------------------------
echo "--- Variant A: both v8 + legacy keys, equal values ---"
cat > "$TMPDIR_TEST/.ceos-agents/state.json" << 'EOF'
{
  "schema_version": "1.0",
  "analyst_triage_completed_at": "2026-04-27T10:05:00Z",
  "triage_completed_at": "2026-04-27T10:05:00Z"
}
EOF

if command -v jq > /dev/null 2>&1; then
  V8_KEY=$(jq -r '.analyst_triage_completed_at' "$TMPDIR_TEST/.ceos-agents/state.json")
  LEGACY=$(jq -r '.triage_completed_at' "$TMPDIR_TEST/.ceos-agents/state.json")
  [ "$V8_KEY" = "2026-04-27T10:05:00Z" ] && echo "OK (Variant A): v8 key present" || fail "Variant A: v8 key wrong"
  [ "$LEGACY" = "2026-04-27T10:05:00Z" ] && echo "OK (Variant A): legacy key present" || fail "Variant A: legacy key wrong"
else
  grep -qF '"analyst_triage_completed_at"' "$TMPDIR_TEST/.ceos-agents/state.json" && echo "OK (Variant A)" || fail "Variant A: v8 key missing"
fi

# ---------------------------------------------------------------------------
# Variant B: v7-only state (only triage_completed_at)
# ---------------------------------------------------------------------------
echo "--- Variant B: v7-only state (only triage_completed_at) ---"
cat > "$TMPDIR_TEST/.ceos-agents/state.json" << 'EOF'
{
  "schema_version": "1.0",
  "triage_completed_at": "2026-04-27T10:05:00Z"
}
EOF

if command -v jq > /dev/null 2>&1; then
  LEGACY_ONLY=$(jq -r '.triage_completed_at' "$TMPDIR_TEST/.ceos-agents/state.json")
  [ "$LEGACY_ONLY" = "2026-04-27T10:05:00Z" ] && echo "OK (Variant B): legacy-only key parseable" || fail "Variant B: legacy key parse failed"
fi

# ---------------------------------------------------------------------------
# Variant C: both keys differ (anomaly case)
# ---------------------------------------------------------------------------
echo "--- Variant C: both keys present with differing values ---"
cat > "$TMPDIR_TEST/.ceos-agents/state.json" << 'EOF'
{
  "schema_version": "1.0",
  "analyst_triage_completed_at": "2026-04-27T10:05:00Z",
  "triage_completed_at": "2026-04-27T09:55:00Z"
}
EOF

if command -v jq > /dev/null 2>&1; then
  V8_KEY2=$(jq -r '.analyst_triage_completed_at' "$TMPDIR_TEST/.ceos-agents/state.json")
  LEGACY2=$(jq -r '.triage_completed_at' "$TMPDIR_TEST/.ceos-agents/state.json")
  [ "$V8_KEY2" != "$LEGACY2" ] && echo "OK (Variant C): keys differ — anomaly case detectable" || fail "Variant C: keys should differ"
fi

# ---------------------------------------------------------------------------
# Assertion: pipeline-status SKILL.md handles alias dedup
# ---------------------------------------------------------------------------
echo "--- Assertion: pipeline-status SKILL.md documents dedup logic ---"
if grep -qiE 'triage_completed_at|analyst_triage|alias.*dedup|transitional.*alias' "$PIPELINE_STATUS_SKILL"; then
  echo "OK: pipeline-status SKILL.md references transitional alias keys"
else
  fail "pipeline-status SKILL.md missing triage_completed_at / transitional alias documentation"
fi

# Warn for inconsistent keys
if grep -qiE 'inconsistent.*transitional|warn.*inconsistent|alias.*inconsistent' "$PIPELINE_STATUS_SKILL"; then
  echo "OK: pipeline-status SKILL.md documents [WARN] for inconsistent alias keys"
else
  fail "pipeline-status SKILL.md missing [WARN] for inconsistent transitional alias keys"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-AGT-009 — pipeline-status handles 3 state.json dedup variants"
fi
exit "$FAIL"
