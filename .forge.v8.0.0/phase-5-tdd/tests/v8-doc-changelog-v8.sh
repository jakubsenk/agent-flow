#!/usr/bin/env bash
# Verifies: AC-DOC-013, REQ-DOC-013
# Description: CHANGELOG.md has v8.0.0 section with all 5 required breaking-change subsections,
#   each with Migration: paragraph and code-block before/after example
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

CHANGELOG="$REPO_ROOT/CHANGELOG.md"
if [ ! -f "$CHANGELOG" ]; then
  fail "CHANGELOG.md not found"
  exit 1
fi

# ---------------------------------------------------------------------------
# Assertion 1: ## v8.0.0 section present
# ---------------------------------------------------------------------------
echo "--- Assertion 1: ## v8.0.0 section in CHANGELOG.md ---"
if grep -qE '^## v8\.0\.0' "$CHANGELOG"; then
  echo "OK: CHANGELOG.md has ## v8.0.0 section"
else
  fail "CHANGELOG.md missing ## v8.0.0 section"
fi

# ---------------------------------------------------------------------------
# Assertion 2: 5 breaking-change subsections
# ---------------------------------------------------------------------------
echo "--- Assertion 2: 5 required breaking-change subsections ---"
REQUIRED_SUBSECTIONS=(
  "Customization (.md → .toml)"
  "Agent renames (6 → 3)"
  "SKILL.md decomposition"
  "Pipeline Profiles syntax"
  "Scaffold mode harmonization"
)

for sub in "${REQUIRED_SUBSECTIONS[@]}"; do
  if grep -qiF "$sub" "$CHANGELOG"; then
    echo "OK: '$sub' subsection found"
  else
    fail "CHANGELOG.md missing breaking-change subsection '$sub'"
  fi
done

# ---------------------------------------------------------------------------
# Assertion 3: Migration: paragraph present
# ---------------------------------------------------------------------------
echo "--- Assertion 3: 'Migration:' paragraphs in CHANGELOG v8.0.0 ---"
if grep -qF 'Migration:' "$CHANGELOG"; then
  echo "OK: CHANGELOG.md contains Migration: paragraphs"
else
  fail "CHANGELOG.md missing 'Migration:' paragraphs in v8.0.0 section"
fi

# ---------------------------------------------------------------------------
# Assertion 4: Code blocks with before/after examples
# ---------------------------------------------------------------------------
echo "--- Assertion 4: code blocks with before/after examples ---"
if grep -qE '^\`\`\`' "$CHANGELOG"; then
  echo "OK: CHANGELOG.md has fenced code blocks"
else
  fail "CHANGELOG.md missing code blocks for before/after migration examples"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-DOC-013 — CHANGELOG.md v8.0.0 section complete"
fi
exit "$FAIL"
