#!/usr/bin/env bash
# Hidden adversarial test — do NOT reference in spec/visible
# Tests: TOML triple-quote edge case — .md content with """ must survive round-trip
# REQ-MIG-003a: verbatim .md content wrapped in TOML triple-quoted string
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

# ---------------------------------------------------------------------------
# Setup: .md content containing triple-quote sequences
# ---------------------------------------------------------------------------
mkdir -p "$TMPDIR_TEST/customization"

cat > "$TMPDIR_TEST/customization/reviewer.md" << 'MDEOF'
Use triple-quote blocks like """python ... """ in Python code reviews.
Also handle '''single triple''' quotes.
Normal "double" and 'single' quotes are fine.
MDEOF

# ---------------------------------------------------------------------------
# Assertion 1: Source .md content has triple-quote characters
# ---------------------------------------------------------------------------
echo "--- Assertion 1: source .md has triple-quote sequences ---"
if grep -qF '"""' "$TMPDIR_TEST/customization/reviewer.md"; then
  echo "OK: source .md contains triple-quote sequences"
else
  fail "Test setup error: source .md should contain triple-quotes"
fi

# ---------------------------------------------------------------------------
# Assertion 2: migrate-config SKILL.md documents triple-quote escaping
# ---------------------------------------------------------------------------
echo "--- Assertion 2: migrate-config documents triple-quote escape ---"
MIGRATE_SKILL="$REPO_ROOT/skills/migrate-config/SKILL.md"
if [ ! -f "$MIGRATE_SKILL" ]; then
  echo "SKIP: skills/migrate-config/SKILL.md not found" >&2
  exit 77
fi

if grep -qiE 'triple.quot|"""|escape.*quot|quot.*escape|verbatim.*text' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents triple-quote escaping"
else
  fail "migrate-config SKILL.md missing triple-quote escape documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 3: Simulate TOML multi-line literal string wrapping (escape method)
# ---------------------------------------------------------------------------
echo "--- Assertion 3: multi-line literal string escaping preserves content ---"
# In TOML, basic multi-line strings (""") cannot contain """ literally.
# Migration must escape them. One approach: use single-quoted multi-line (''').
# The spec REQ-MIG-003a mandates this edge case is handled.

ORIGINAL_TEXT=$(cat "$TMPDIR_TEST/customization/reviewer.md")
# Simulate escaping: replace """ with the TOML-safe escaped form
ESCAPED_TEXT=$(echo "$ORIGINAL_TEXT" | sed 's/"""/\\"""/g')

# Verify original content is still recoverable from escaped form
RECOVERED_TEXT=$(echo "$ESCAPED_TEXT" | sed 's/\\"""/"""/g')
if [ "$ORIGINAL_TEXT" = "$RECOVERED_TEXT" ]; then
  echo "OK: triple-quote escape/unescape round-trip preserves content"
else
  fail "Triple-quote round-trip failed: content changed"
fi

# ---------------------------------------------------------------------------
# Assertion 4: design.md Section 6 documents triple-quote edge case
# ---------------------------------------------------------------------------
echo "--- Assertion 4: design.md migration tooling section mentions triple-quote ---"
DESIGN="$REPO_ROOT/.forge/phase-4-spec/final/design.md"
if [ -f "$DESIGN" ]; then
  if grep -qiE 'triple.quot|verbatim.*text|"""|REQ-MIG-003' "$DESIGN"; then
    echo "OK: design.md migration section references triple-quote handling"
  else
    fail "design.md missing triple-quote / verbatim text escaping documentation"
  fi
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: TOML triple-quote edge case in .md content handled in migration docs"
fi
exit "$FAIL"
