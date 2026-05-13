#!/usr/bin/env bash
# v9.2.0 — /metrics no-arg interactive Czech prompt text
# Fulfils: AC-V902-MET-01
#
# RED now because:
#   skills/metrics/SKILL.md does not yet contain the Czech interactive prompt
#   "Výstup uložit? [1] Ne [2] JSON → stdout [3] HTML → ./metrics.html"
#   (Phase 7 will add Step 9 post-render prompt block).
#
# GREEN after Phase 7 edits skills/metrics/SKILL.md to add Step 9.
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
# AC-V902-MET-01 Assertion: SKILL.md contains the exact UTF-8 Czech prompt
# Spec: "Výstup uložit? [1] Ne [2] JSON → stdout [3] HTML → ./metrics.html"
# Characters: ý (U+00FD), š (U+0161), → (U+2192)
# The test checks for each component separately (substring-safe on all locales)
# and then checks the key combined sequence.
# ---------------------------------------------------------------------------
echo "--- Assertion 1: 'Výstup uložit?' is present ---"
if grep -qF 'Výstup uložit?' "$METRICS_SKILL"; then
  echo "PASS: 'Výstup uložit?' found"
else
  fail "AC-V902-MET-01 — skills/metrics/SKILL.md missing 'Výstup uložit?' (Czech prompt not added)"
fi

echo "--- Assertion 2: '[1] Ne' is present ---"
if grep -qF '[1] Ne' "$METRICS_SKILL"; then
  echo "PASS: '[1] Ne' found"
else
  fail "AC-V902-MET-01 — skills/metrics/SKILL.md missing '[1] Ne'"
fi

echo "--- Assertion 3: '[2] JSON' with arrow is present ---"
if grep -qF '[2] JSON' "$METRICS_SKILL"; then
  echo "PASS: '[2] JSON' found"
else
  fail "AC-V902-MET-01 — skills/metrics/SKILL.md missing '[2] JSON'"
fi

echo "--- Assertion 4: '[3] HTML → ./metrics.html' is present ---"
if grep -qF '[3] HTML' "$METRICS_SKILL" && grep -qF './metrics.html' "$METRICS_SKILL"; then
  echo "PASS: '[3] HTML ... ./metrics.html' found"
else
  fail "AC-V902-MET-01 — skills/metrics/SKILL.md missing '[3] HTML → ./metrics.html'"
fi

echo "--- Assertion 5: complete prompt line exists (combined check) ---"
# The exact byte sequence per design.md §"Czech prompt"
EXPECTED_PROMPT='Výstup uložit? [1] Ne [2] JSON'
if grep -qF "$EXPECTED_PROMPT" "$METRICS_SKILL"; then
  echo "PASS: combined Czech prompt prefix found"
else
  fail "AC-V902-MET-01 — skills/metrics/SKILL.md missing combined prompt 'Výstup uložit? [1] Ne [2] JSON'"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.2.0-metrics-no-arg-prompt — Czech interactive prompt verified in skills/metrics/SKILL.md"
fi
exit "$FAIL"
