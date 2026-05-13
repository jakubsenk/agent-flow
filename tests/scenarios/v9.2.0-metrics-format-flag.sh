#!/usr/bin/env bash
# v9.2.0 — /metrics --format flag extended to include html; /dashboard deleted
# Fulfils: AC-V902-MET-02, AC-V902-MET-04, AC-V902-MET-05, AC-V902-MET-06
#
# RED now because:
#   1. skills/metrics/SKILL.md --format regex is ^(md|json)$ — does NOT include html
#   2. skills/dashboard/ still exists
#   3. argument-hint does not include html yet
#
# GREEN after Phase 7 edits skills/metrics/SKILL.md with extended flag-parse block.
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

METRICS_SKILL="$REPO_ROOT/skills/metrics/SKILL.md"

if [ ! -f "$METRICS_SKILL" ]; then
  echo "FAIL: skills/metrics/SKILL.md does not exist" >&2
  exit 1
fi

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# AC-V902-MET-02 Assertion 1: SKILL.md contains the extended format regex ^(md|json|html)$
# ---------------------------------------------------------------------------
echo "--- Assertion 1: --format regex includes html ---"
if grep -qF '^(md|json|html)$' "$METRICS_SKILL"; then
  echo "PASS: regex '^(md|json|html)\$' found in metrics/SKILL.md"
else
  fail "AC-V902-MET-02 — skills/metrics/SKILL.md does not contain '^(md|json|html)\$' format regex (Phase 7 flag-parse update not applied)"
fi

# ---------------------------------------------------------------------------
# AC-V902-MET-02 Assertion 2: old restricted regex ^(md|json)$ must NOT be present
# ---------------------------------------------------------------------------
echo "--- Assertion 2: old regex ^(md|json)$ is NOT present ---"
if grep -qF '^(md|json)$' "$METRICS_SKILL"; then
  fail "AC-V902-MET-02 — skills/metrics/SKILL.md still contains old '^(md|json)\$' regex (must be replaced with html-extended version)"
else
  echo "PASS: old regex '^(md|json)\$' correctly absent"
fi

# ---------------------------------------------------------------------------
# AC-V902-MET-02 Assertion 3: error message text matches spec
# ---------------------------------------------------------------------------
echo "--- Assertion 3: error message text references html ---"
if grep -qF "Error: --format must be 'md', 'json', or 'html'" "$METRICS_SKILL"; then
  echo "PASS: error message references md, json, or html"
else
  fail "AC-V902-MET-02 — skills/metrics/SKILL.md missing error message \"Error: --format must be 'md', 'json', or 'html'\""
fi

# ---------------------------------------------------------------------------
# AC-V902-MET-04: --period flag still handled
# ---------------------------------------------------------------------------
echo "--- Assertion 4: --period flag still present ---"
if grep -qF -- '--period' "$METRICS_SKILL"; then
  echo "PASS: --period flag handling present"
else
  fail "AC-V902-MET-04 — skills/metrics/SKILL.md missing --period flag (regression)"
fi

# ---------------------------------------------------------------------------
# AC-V902-MET-05 Assertion 1: --output flag still handled
# ---------------------------------------------------------------------------
echo "--- Assertion 5: --output flag still present ---"
if grep -qF -- '--output' "$METRICS_SKILL"; then
  echo "PASS: --output flag handling present"
else
  fail "AC-V902-MET-05 — skills/metrics/SKILL.md missing --output flag (regression)"
fi

# ---------------------------------------------------------------------------
# AC-V902-MET-05 Assertion 2: when --format html without --output, default path is ./metrics.html
# ---------------------------------------------------------------------------
echo "--- Assertion 6: default HTML output path is ./metrics.html ---"
if grep -qF './metrics.html' "$METRICS_SKILL"; then
  echo "PASS: './metrics.html' default path present"
else
  fail "AC-V902-MET-05 — skills/metrics/SKILL.md missing './metrics.html' default output path"
fi

# ---------------------------------------------------------------------------
# AC-V902-MET-06: argument-hint frontmatter updated to include html
# Exact spec: "[--period <N>] [--output <path>] [--format <md|json|html>]"
# ---------------------------------------------------------------------------
echo "--- Assertion 7: argument-hint includes html ---"
if grep -qF '[--format <md|json|html>]' "$METRICS_SKILL"; then
  echo "PASS: argument-hint '[--format <md|json|html>]' found"
else
  fail "AC-V902-MET-06 — skills/metrics/SKILL.md argument-hint does not include html format option"
fi

# ---------------------------------------------------------------------------
# AC-V902-CAT-03: skills/dashboard/ must NOT exist
# ---------------------------------------------------------------------------
echo "--- Assertion 8: skills/dashboard/ does NOT exist ---"
if [ -d "$REPO_ROOT/skills/dashboard" ]; then
  fail "AC-V902-CAT-03 — skills/dashboard/ still exists (Phase 7 deletion not applied)"
else
  echo "PASS: skills/dashboard/ correctly absent"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.2.0-metrics-format-flag — --format html extension verified"
fi
exit "$FAIL"
