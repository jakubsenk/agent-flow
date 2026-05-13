#!/usr/bin/env bash
# v9.2.0 — /metrics absorbs /dashboard HTML capability
# Fulfils: AC-V902-CAT-06, AC-V902-MET-03
#
# RED now because:
#   1. skills/metrics/SKILL.md does not contain HTML output step (no <!DOCTYPE, no <html,
#      no self-contained markers, no structural section labels ported from /dashboard)
#   2. This is a static content test — we check the SKILL.md prose, NOT runtime execution
#      (runtime execution requires Claude agent dispatch; static check is sufficient for TDD)
#
# GREEN after Phase 7 edits skills/metrics/SKILL.md to add Steps 7a and 8 per design.md.
#
# Test strategy:
#   Static content assertions on skills/metrics/SKILL.md. We check that the SKILL.md
#   describes HTML generation with the required structural sections. The spec says the
#   test asserts the SKILL.md "contains HTML output step" — we check the design markers.
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
# AC-V902-MET-03 / AC-V902-CAT-06 Assertion 1:
# SKILL.md describes HTML output (contains DOCTYPE or <html reference in prose)
# ---------------------------------------------------------------------------
echo "--- Assertion 1: SKILL.md references <!DOCTYPE html> or <html output ---"
if grep -qE '<!DOCTYPE|<html|self.contained' "$METRICS_SKILL"; then
  echo "PASS: HTML output reference found in metrics/SKILL.md"
else
  fail "AC-V902-MET-03 — skills/metrics/SKILL.md does not reference HTML output (<!DOCTYPE, <html, or self-contained)"
fi

# ---------------------------------------------------------------------------
# AC-V902-MET-03 Assertion 2: SKILL.md references CSS/style (self-contained)
# Per design.md: "no external <link> to CSS, no external <script src="...">"
# ---------------------------------------------------------------------------
echo "--- Assertion 2: SKILL.md references inline CSS or style block ---"
if grep -qiE 'inline.*(css|style)|<style|CSS.*inline|style.*block' "$METRICS_SKILL"; then
  echo "PASS: inline CSS/style reference found"
else
  fail "AC-V902-MET-03 — skills/metrics/SKILL.md does not mention inline CSS or <style> block (self-contained HTML requirement)"
fi

# ---------------------------------------------------------------------------
# AC-V902-CAT-06 Assertion sub: structural section markers ported from /dashboard
# Required: Pipeline Overview, Issue Table, Blocked Issues Panel, Recent Activity Timeline
# ---------------------------------------------------------------------------
echo "--- Assertion 3: structural section markers present ---"
REQUIRED_SECTIONS=(
  "Pipeline Overview"
  "Issue Table"
  "Blocked Issues Panel"
  "Recent Activity Timeline"
)

for section in "${REQUIRED_SECTIONS[@]}"; do
  if grep -qF "$section" "$METRICS_SKILL"; then
    echo "PASS: section '$section' found"
  else
    fail "AC-V902-CAT-06 — skills/metrics/SKILL.md missing structural section '$section' (ported from /dashboard)"
  fi
done

# ---------------------------------------------------------------------------
# AC-V902-MET-03 Assertion 3: self-contained (no external link/script references in prose)
# We check that the SKILL.md contains the word "self-contained" (the spec requirement term)
# ---------------------------------------------------------------------------
echo "--- Assertion 4: 'self-contained' requirement mentioned ---"
# Note: use -F without -i to avoid grep crash on multibyte UTF-8 chars in the file
if grep -qF 'self-contained' "$METRICS_SKILL"; then
  echo "PASS: 'self-contained' requirement present"
else
  fail "AC-V902-MET-03 — skills/metrics/SKILL.md missing 'self-contained' HTML requirement clause"
fi

# ---------------------------------------------------------------------------
# AC-V902-CAT-03: skills/dashboard/ must NOT exist
# ---------------------------------------------------------------------------
echo "--- Assertion 5: skills/dashboard/ does NOT exist ---"
if [ -d "$REPO_ROOT/skills/dashboard" ]; then
  fail "AC-V902-CAT-03 — skills/dashboard/ still exists (Phase 7 deletion not applied)"
else
  echo "PASS: skills/dashboard/ correctly absent"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.2.0-metrics-html-output — HTML output capability verified in skills/metrics/SKILL.md"
fi
exit "$FAIL"
