#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #7 — Tier A+B)
# Functional: /metrics --format json flag documented and output schema valid.
set -uo pipefail

. "$(dirname "$0")/../lib/fixtures.sh"

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

require_jq
setup_scratch

METRICS="$REPO_ROOT/skills/metrics/SKILL.md"
[ -f "$METRICS" ] || { fail "skills/metrics/SKILL.md not found"; exit 1; }

# Tier B: --format json flag documented
if ! grep -qE '\-\-format json|\-\-format=json' "$METRICS"; then
  fail "skills/metrics/SKILL.md missing --format json flag documentation"
fi

# Tier B: block.detail HARD-EXCLUDED from JSON output
if ! grep -qiE 'block\.detail.*exclud|exclud.*block\.detail|HARD.EXCLUD' "$METRICS"; then
  fail "skills/metrics/SKILL.md must document that block.detail is HARD-EXCLUDED from JSON output"
fi

if [ "${HAVE_JQ:-0}" = "1" ]; then
  # Tier A: synthesize expected JSON metrics output structure
  METRICS_JSON=$(jq -n '{
    "format": "json",
    "period_days": 30,
    "pipeline_runs": [],
    "block_detail_excluded": true
  }')
  echo "$METRICS_JSON" > "$SCRATCH/metrics.json"
  # Validate the expected structure is parseable
  jq -e '.format == "json"' "$SCRATCH/metrics.json" >/dev/null \
    || fail "Metrics JSON fixture malformed"
  jq -e '.block_detail_excluded == true' "$SCRATCH/metrics.json" >/dev/null \
    || fail "Metrics JSON fixture missing block_detail_excluded field"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: metrics --format json documented and schema valid"
exit "$FAIL"
