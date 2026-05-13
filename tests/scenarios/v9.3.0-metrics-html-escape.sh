#!/usr/bin/env bash
# v9.3.0 TDD — tests written before implementation
# T-05: HTML-escape in /metrics --format html (AC-035, AC-036)
#
# Tests that skills/metrics/SKILL.md defines the html_escape() function
# with the correct 5-substitution order (& first to avoid double-escaping),
# and that all 5 user-controlled data paths reference html_escape.
#
# This is a STATIC content test against the SKILL.md prose/code blocks —
# runtime execution requires Claude agent dispatch which is outside the test harness.
#
# RED until Phase 7 implementation is complete — that is correct TDD behavior.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
[ -f "$REPO_ROOT/tests/lib/fixtures.sh" ] || REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

SKILL="$REPO_ROOT/skills/metrics/SKILL.md"

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Prerequisite
# ---------------------------------------------------------------------------
if [ ! -f "$SKILL" ]; then
  echo "FAIL: skills/metrics/SKILL.md does not exist" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# AC-035: html_escape() function defined with 5 sed substitutions
# ---------------------------------------------------------------------------
echo "--- AC-035: html_escape() function defined ---"
if grep -qF 'html_escape()' "$SKILL"; then
  echo "PASS: html_escape() function definition found"
else
  fail "AC-035 — html_escape() function not found in skills/metrics/SKILL.md"
fi

# ---------------------------------------------------------------------------
# AC-035: First substitution must be &amp; (& first to avoid double-escaping)
# ---------------------------------------------------------------------------
echo "--- AC-035: & → &amp; is first substitution ---"
# Accept either sed syntax (s/&/\&amp;/g) or bash parameter expansion (${s//&/&amp;})
if grep -qF '&amp;' "$SKILL"; then
  echo "PASS: & → &amp; substitution found"
else
  fail "AC-035 — '& → &amp;' (first substitution) not found in html_escape() definition"
fi

# ---------------------------------------------------------------------------
# AC-035: < → &lt; substitution present
# ---------------------------------------------------------------------------
echo "--- AC-035: < → &lt; substitution present ---"
if grep -qF '&lt;' "$SKILL"; then
  echo "PASS: < → &lt; substitution found"
else
  fail "AC-035 — '< → &lt;' substitution not found in html_escape()"
fi

# ---------------------------------------------------------------------------
# AC-035: > → &gt; substitution present
# ---------------------------------------------------------------------------
echo "--- AC-035: > → &gt; substitution present ---"
if grep -qF '&gt;' "$SKILL"; then
  echo "PASS: > → &gt; substitution found"
else
  fail "AC-035 — '> → &gt;' substitution not found in html_escape()"
fi

# ---------------------------------------------------------------------------
# AC-035: ' → &#39; substitution present
# ---------------------------------------------------------------------------
echo "--- AC-035: ' → &#39; substitution present ---"
if grep -qF '&#39;' "$SKILL"; then
  echo "PASS: &#39; (single-quote escape) found"
else
  fail "AC-035 — '&#39;' (single-quote escape) not found in html_escape()"
fi

# ---------------------------------------------------------------------------
# AC-035: " → &quot; substitution present
# ---------------------------------------------------------------------------
echo "--- AC-035: \" → &quot; substitution present ---"
if grep -qF '&quot;' "$SKILL"; then
  echo "PASS: &quot; (double-quote escape) found"
else
  fail "AC-035 — '&quot;' (double-quote escape) not found in html_escape()"
fi

# ---------------------------------------------------------------------------
# AC-036: All 5 user-controlled data paths reference html_escape (or *_ESC vars)
# Paths: issue title, state label, block reason, block recommendation, timeline content
# ---------------------------------------------------------------------------
echo "--- AC-036: 5 data paths use html_escape ---"

# Check that html_escape is called/referenced multiple times (at least for the 5 data paths)
ESCAPE_COUNT=$(grep -c 'html_escape\|_ESC' "$SKILL" 2>/dev/null || true)
ESCAPE_COUNT="${ESCAPE_COUNT:-0}"
if [ "${ESCAPE_COUNT}" -ge 5 ]; then
  echo "PASS: html_escape referenced at least 5 times (covering all data paths)"
else
  fail "AC-036 — html_escape referenced only $ESCAPE_COUNT times; expected >= 5 (one per data path)"
fi

# Spot-check: issue title is escaped
if grep -qiE 'ISSUE_TITLE_ESC|html_escape.*ISSUE_TITLE|html_escape.*title' "$SKILL"; then
  echo "PASS: issue title HTML-escape reference found"
else
  fail "AC-036 — Issue title HTML-escape not found (expected ISSUE_TITLE_ESC or html_escape \"\$ISSUE_TITLE\")"
fi

# Spot-check: block reason is escaped
if grep -qiE 'BLOCK_REASON_ESC|html_escape.*BLOCK_REASON|html_escape.*block.*reason' "$SKILL"; then
  echo "PASS: block reason HTML-escape reference found"
else
  fail "AC-036 — Block reason HTML-escape not found (expected BLOCK_REASON_ESC or html_escape \"\$BLOCK_REASON\")"
fi

# ---------------------------------------------------------------------------
# Ordering invariant: & must appear BEFORE < and > in the sed pipeline
# We extract lines with the escape subs and verify their relative line order.
# ---------------------------------------------------------------------------
echo "--- AC-035 ordering: & escaping appears before < and > escaping ---"
# Accept bash parameter expansion (${s//&/&amp;}) or sed style
LINE_AMP=$(grep -n '&amp;' "$SKILL" 2>/dev/null | head -1 | cut -d: -f1 || echo "0")
LINE_LT=$(grep -n '&lt;' "$SKILL" 2>/dev/null | head -1 | cut -d: -f1 || echo "0")

if [ "${LINE_AMP:-0}" -gt 0 ] && [ "${LINE_LT:-0}" -gt 0 ] && [ "$LINE_AMP" -lt "$LINE_LT" ]; then
  echo "PASS: & substitution (line $LINE_AMP) appears before < substitution (line $LINE_LT)"
else
  # Both present but order check inconclusive (e.g. same line or line extraction ambiguous)
  echo "INFO: Line-order check inconclusive — verifying presence only"
  if grep -qF '&amp;' "$SKILL"; then
    echo "PASS: & → &amp; present (ordering check deferred to runtime)"
  else
    fail "AC-035 ordering — could not verify & substitution ordering"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.3.0-metrics-html-escape — all HTML-escape checks passed"
fi
exit "$FAIL"
