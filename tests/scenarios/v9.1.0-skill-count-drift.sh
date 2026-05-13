#!/usr/bin/env bash
# v9.1.0-skill-count-drift.sh — REQ-V910-005 (updated for v9.5.0):
# All four count-bearing doc files must contain "18 skills" and must NOT
# contain "22 skills", "25 skills", "28 skills", or "29 skills".
# docs/reference/automation-config.md is verified as a non-skill-count file (A-8 negative check).
# v9.5.0 reduced skills 22→18; this test updated 2026-05-09 to reflect post-cleanup baseline.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# REQ-V910-005 (v9.5.0): four count-bearing doc files must reflect 18 skills.
# ---------------------------------------------------------------------------
echo "--- REQ-V910-005: skill count 18 in count-bearing docs ---"

COUNT_DOCS="CLAUDE.md README.md docs/reference/skills.md docs/architecture.md"

for f in $COUNT_DOCS; do
  fpath="$REPO_ROOT/$f"
  if [ ! -f "$fpath" ]; then
    fail "$f: file not found"
    continue
  fi

  # Must contain "18 skills" or "18-skill" at least once.
  has_18=$(grep -cE '18[- ]skill' "$fpath" 2>/dev/null | tr -d '[:space:]' || echo 0)
  if [ "$has_18" -ge 1 ]; then
    echo "OK $f: contains '18 skill' reference ($has_18 occurrence(s))"
  else
    fail "$f: does not contain '18 skills' or '18-skill' — update required"
  fi

  # Must NOT contain "22 skills".
  has_22=$(grep -c '22 skills' "$fpath" 2>/dev/null | tr -d '[:space:]' || echo 0)
  if [ "$has_22" -eq 0 ]; then
    echo "OK $f: does not contain '22 skills'"
  else
    fail "$f: still contains '22 skills' ($has_22 occurrence(s)) — stale reference"
  fi

  # Must NOT contain "25 skills".
  has_25=$(grep -c '25 skills' "$fpath" 2>/dev/null | tr -d '[:space:]' || echo 0)
  if [ "$has_25" -eq 0 ]; then
    echo "OK $f: does not contain '25 skills'"
  else
    fail "$f: still contains '25 skills' ($has_25 occurrence(s)) — stale reference"
  fi

  # Must NOT contain "28 skills".
  has_28=$(grep -c '28 skills' "$fpath" 2>/dev/null | tr -d '[:space:]' || echo 0)
  if [ "$has_28" -eq 0 ]; then
    echo "OK $f: does not contain '28 skills'"
  else
    fail "$f: still contains '28 skills' ($has_28 occurrence(s)) — stale reference"
  fi

  # Must NOT contain "29 skills".
  has_29=$(grep -c '29 skills' "$fpath" 2>/dev/null | tr -d '[:space:]' || echo 0)
  if [ "$has_29" -eq 0 ]; then
    echo "OK $f: does not contain '29 skills'"
  else
    fail "$f: still contains '29 skills' ($has_29 occurrence(s)) — stale reference"
  fi

  # Must NOT contain "30 skills" (forward drift guard).
  has_30=$(grep -c '30 skills' "$fpath" 2>/dev/null | tr -d '[:space:]' || echo 0)
  if [ "$has_30" -eq 0 ]; then
    echo "OK $f: does not contain '30 skills'"
  else
    fail "$f: contains '30 skills' ($has_30 occurrence(s)) — unexpected forward drift"
  fi
done

# ---------------------------------------------------------------------------
# A-8 negative check: docs/reference/automation-config.md must NOT contain
# stale skill counts ("22 skills", "28 skills", "29 skills") — it primarily
# counts agents/sections, not skills.
# Note: v9.5.0 added an informational "18 skills" mention in the intro text;
# the 4-doc exhaustiveness property is preserved because the count is current.
# ---------------------------------------------------------------------------
echo "--- A-8 negative check: automation-config.md has no stale skill counts ---"
AUTOCONF="$REPO_ROOT/docs/reference/automation-config.md"
if [ ! -f "$AUTOCONF" ]; then
  echo "WARN: docs/reference/automation-config.md not found — skipping A-8 check"
else
  for stale in "22 skills" "25 skills" "28 skills" "29 skills"; do
    stale_refs=$(grep -cF "$stale" "$AUTOCONF" 2>/dev/null | tr -d '[:space:]' || echo 0)
    if [ "$stale_refs" -eq 0 ]; then
      echo "OK: docs/reference/automation-config.md contains no '$stale' reference"
    else
      fail "docs/reference/automation-config.md contains $stale_refs '$stale' reference(s) — stale count"
    fi
  done
fi

# ---------------------------------------------------------------------------
# Final verdict.
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.1.0-skill-count-drift — all four docs report 18 skills, automation-config.md clean"
fi
exit "$FAIL"
