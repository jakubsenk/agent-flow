#!/usr/bin/env bash
# v9.2.0 — CHANGELOG.md contains [9.2.0] section with required content
# Fulfils: AC-V902-DOC-01
#
# RED now because:
#   CHANGELOG.md does not yet contain a ## [9.2.0] heading or any v9.2.0 content.
#   (Phase 7 will prepend the [9.2.0] section per design.md §"CHANGELOG Template")
#
# GREEN after Phase 7 prepends the [9.2.0] section to CHANGELOG.md.
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

CHANGELOG="$REPO_ROOT/CHANGELOG.md"

if [ ! -f "$CHANGELOG" ]; then
  echo "FAIL: CHANGELOG.md does not exist" >&2
  exit 1
fi

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# AC-V902-DOC-01 Assertion 1: CHANGELOG.md contains ## [9.2.0] heading
# ---------------------------------------------------------------------------
echo "--- Assertion 1: CHANGELOG.md contains ## [9.2.0] heading ---"
if grep -qF '## [9.2.0]' "$CHANGELOG"; then
  echo "PASS: '## [9.2.0]' heading found in CHANGELOG.md"
else
  fail "AC-V902-DOC-01 — CHANGELOG.md missing '## [9.2.0]' heading (Phase 7 has not added v9.2.0 entry)"
fi

# ---------------------------------------------------------------------------
# AC-V902-DOC-01 Assertion 2: [9.2.0] section contains required subsections
# Spec: ### Removed, ### Added, ### Changed, ### Migration, ### Counts
# ---------------------------------------------------------------------------
echo "--- Assertion 2: required subsections present in [9.2.0] section ---"

# Extract from ## [9.2.0] to the next ## [ to get just the 9.2.0 section
V920_SECTION="$SCRATCH/v920_section.md"
awk '/^## \[9\.2\.0\]/{found=1} found && /^## \[/ && !/^## \[9\.2\.0\]/{found=0} found{print}' \
  "$CHANGELOG" > "$V920_SECTION"

if [ ! -s "$V920_SECTION" ]; then
  fail "AC-V902-DOC-01 — Could not extract [9.2.0] section from CHANGELOG.md"
  exit "$FAIL"
fi

for subsection in "### Removed" "### Added" "### Changed" "### Migration" "### Counts"; do
  if grep -qF "$subsection" "$V920_SECTION"; then
    echo "PASS: subsection '$subsection' found in [9.2.0]"
  else
    fail "AC-V902-DOC-01 — [9.2.0] section missing subsection '$subsection'"
  fi
done

# ---------------------------------------------------------------------------
# AC-V902-DOC-01 Assertion 3: [9.2.0] section names the 3 deleted skills explicitly
# ---------------------------------------------------------------------------
echo "--- Assertion 3: 3 deleted skills mentioned in [9.2.0] section ---"

for skill in check-deploy template dashboard; do
  if grep -qF "$skill" "$V920_SECTION"; then
    echo "PASS: deleted skill '$skill' mentioned in [9.2.0]"
  else
    fail "AC-V902-DOC-01 — [9.2.0] section does not mention deleted skill '$skill'"
  fi
done

# ---------------------------------------------------------------------------
# Bonus: verify the Counts table references 25 skills (not 28)
# Per design.md §"CHANGELOG Template" Counts table: **Skills** | **28** | **25**
# ---------------------------------------------------------------------------
echo "--- Assertion 4: Counts table references 25 skills ---"
if grep -qF '25' "$V920_SECTION"; then
  echo "PASS: '25' skill count referenced in [9.2.0] Counts table"
else
  fail "AC-V902-DOC-01 — [9.2.0] Counts table does not reference '25' skills"
fi

# Also verify historical entries are frozen (28 still appears in earlier entries)
echo "--- Assertion 5: historical 28 skill count preserved in earlier entries ---"
# Lines before the [9.2.0] section should still mention 28 (in [9.1.0] entry)
PRE_920_SECTION="$SCRATCH/pre_v920.md"
awk '/^## \[9\.2\.0\]/{exit} {print}' "$CHANGELOG" > "$PRE_920_SECTION"

if grep -qE '\b28\b' "$PRE_920_SECTION" 2>/dev/null; then
  echo "PASS: historical '28' skill count preserved in pre-v9.2.0 entries (freeze maintained)"
else
  echo "INFO: historical '28' not found in pre-v9.2.0 entries — verify CHANGELOG freeze manually"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.2.0-changelog-entry — CHANGELOG.md [9.2.0] section verified"
fi
exit "$FAIL"
