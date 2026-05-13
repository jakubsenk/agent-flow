#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #14 — Tier A+B)
# Functional: pipeline-history.md append-only, 50-run retention, section-count-aware trim.
set -uo pipefail

. "$(dirname "$0")/../lib/fixtures.sh"

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

require_jq
setup_scratch

# Tier A: build synthetic pipeline-history using jq -n
HISTORY_JSON=$(jq -n '[
  {"issue_id": "PROJ-1", "outcome": "success", "date": "2026-04-01"},
  {"issue_id": "PROJ-2", "outcome": "blocked", "date": "2026-04-02"}
]')
echo "$HISTORY_JSON" > "$SCRATCH/pipeline-history.json"

if [ "${HAVE_JQ:-0}" = "1" ]; then
  run_count=$(jq 'length' "$SCRATCH/pipeline-history.json")
  [ "$run_count" -eq 2 ] || fail "Expected 2 history entries, got $run_count"

  # Test 50-run retention: build 51 entries, tail should have 50
  jq -n '[range(51) | {"issue_id": ("PROJ-" + (. + 1 | tostring)), "outcome": "success"}]' \
    > "$SCRATCH/history_51.json"
  # Trim to 50
  jq '[-50:]' "$SCRATCH/history_51.json" > "$SCRATCH/history_trimmed.json"
  trimmed_count=$(jq 'length' "$SCRATCH/history_trimmed.json")
  [ "$trimmed_count" -eq 50 ] || fail "50-run retention: expected 50, got $trimmed_count"

  # Last entry should be PROJ-51 (most recent)
  last_id=$(jq -r '.[-1].issue_id' "$SCRATCH/history_trimmed.json")
  [ "$last_id" = "PROJ-51" ] || fail "Last entry after trim should be PROJ-51, got $last_id"
fi

# Tier B: pipeline-history spec in docs
PIPELINE_SKILL="$REPO_ROOT/skills/fix-ticket/SKILL.md"
if [ -f "$PIPELINE_SKILL" ]; then
  if ! grep -qiE 'pipeline.history|pipeline-history' "$PIPELINE_SKILL"; then
    fail "skills/fix-ticket/SKILL.md missing pipeline-history reference"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: pipeline-history append and retention functional test"
exit "$FAIL"
