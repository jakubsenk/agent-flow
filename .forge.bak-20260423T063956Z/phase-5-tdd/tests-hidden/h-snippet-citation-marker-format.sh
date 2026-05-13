#!/usr/bin/env bash
# Hidden scenario: REQ-063b, REQ-063c — all 5 snippets use <!-- @snippet:NAME --> marker format consistently
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — snippet files don't exist yet
set -uo pipefail

# CRITICAL: 3 levels up from .forge/phase-5-tdd/tests-hidden/ to repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"

if [ ! -f "$REPO_ROOT/.claude-plugin/plugin.json" ]; then
  echo "FAIL: REPO_ROOT path resolution bug" >&2; exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

SNIPPETS_DIR="$REPO_ROOT/core/snippets"

# Assertion 1: all 5 snippet files exist
echo "--- Assertion 1: all 5 snippet files exist ---"
declare -A expected_counts
# Counts scoped to skills/ + core/ only (excludes .forge/ artifacts to prevent drift).
# Updated for v6.9.1: cycle-1 added 8 new webhook-curl firing sites (pipeline-paused);
# issue-id-validation gained 1 site in v6.9.0. These are the authoritative post-cycle-1 counts.
expected_counts["webhook-curl"]=31
expected_counts["issue-id-validation"]=5
expected_counts["metrics-json-schema"]=1
expected_counts["pipeline-completion"]=3
expected_counts["architecture-freshness"]=2

for name in webhook-curl issue-id-validation metrics-json-schema pipeline-completion architecture-freshness; do
  f="$SNIPPETS_DIR/${name}.md"
  if [ -f "$f" ]; then
    echo "OK: $f exists"
  else
    fail "AC-061: $f does not exist"
  fi
done

# Assertion 2 (AC-063b): each snippet's ## Used by: heading lists citation sites
echo "--- Assertion 2 (AC-063b): ## Used by: heading in each snippet ---"
for name in webhook-curl issue-id-validation metrics-json-schema pipeline-completion architecture-freshness; do
  f="$SNIPPETS_DIR/${name}.md"
  if [ -f "$f" ]; then
    if grep -qF '## Used by:' "$f"; then
      echo "OK (AC-063b): $name.md has '## Used by:' heading"
    else
      fail "AC-063b: $name.md missing '## Used by:' heading"
    fi
  fi
done

# Assertion 3 (AC-063b): citation marker format is <!-- @snippet:NAME --> (with correct name)
echo "--- Assertion 3 (AC-063b): citation markers in citing files use correct format ---"
for name in webhook-curl issue-id-validation metrics-json-schema pipeline-completion architecture-freshness; do
  marker="<!-- @snippet:${name} -->"
  # Search only in skills/ and core/ — exclude .forge/ artifacts which inflate counts (v6.9.1 fix)
  actual_count=$(grep -rF "$marker" "$REPO_ROOT/skills" "$REPO_ROOT/core" --include="*.md" --include="*.sh" 2>/dev/null | \
    grep -v "${SNIPPETS_DIR}/${name}.md" | wc -l || true)
  echo "INFO: '$marker' found $actual_count times in skills/ + core/ (excluding self-reference)"
  if [ "$actual_count" -ge 1 ]; then
    echo "OK (AC-063b): at least 1 citation of @snippet:${name} found"
  else
    fail "AC-063b: no citations of '@snippet:${name}' found in skills/ + core/ — citation markers required per REQ-063b"
  fi
done

# Assertion 4 (AC-063c): citation counts match expected values from ## Used by: headings
echo "--- Assertion 4 (AC-063c): citation counts match ## Used by: expectations ---"
for name in "${!expected_counts[@]}"; do
  expected="${expected_counts[$name]}"
  marker="<!-- @snippet:${name} -->"
  # Count markers in skills/ + core/ only (exclude .forge/ to prevent artifact inflation — v6.9.1 fix)
  actual_count=$(grep -rF "$marker" "$REPO_ROOT/skills" "$REPO_ROOT/core" --include="*.md" --include="*.sh" 2>/dev/null | \
    grep -v "${SNIPPETS_DIR}/${name}.md" | wc -l || true)
  if [ "$actual_count" -eq "$expected" ]; then
    echo "OK (AC-063c): @snippet:${name} cited $actual_count times (expected $expected)"
  else
    fail "AC-063c: @snippet:${name} cited $actual_count times but expected $expected — drift detected"
  fi
done

# Assertion 5 (AC-063d): core/snippets/README.md exists with rollback procedure
echo "--- Assertion 5 (AC-063d): core/snippets/README.md rollback procedure ---"
SNIPPETS_README="$SNIPPETS_DIR/README.md"
if [ -f "$SNIPPETS_README" ]; then
  if grep -qF 'Rollback' "$SNIPPETS_README"; then
    echo "OK (AC-063d): Rollback section present in core/snippets/README.md"
  else
    fail "AC-063d: core/snippets/README.md missing Rollback procedure"
  fi
  if grep -qF 'git show v6.9.0:core/snippets/' "$SNIPPETS_README"; then
    echo "OK (AC-063d): canonical-content recovery procedure present"
  else
    fail "AC-063d: core/snippets/README.md missing 'git show v6.9.0:core/snippets/' recovery procedure"
  fi
else
  fail "AC-063d: core/snippets/README.md does not exist"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: h-snippet-citation-marker-format — all 5 snippets use <!-- @snippet:NAME --> format; citation counts match; README rollback present"
fi
exit "$FAIL"
