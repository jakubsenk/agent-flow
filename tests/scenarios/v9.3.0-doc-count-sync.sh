#!/usr/bin/env bash
# v9.3.0 TDD — tests written before implementation (refactored 2026-05-08 for post-v9.5.0 baseline)
# T-10: Skill count = 18 in all 4 documentation files (AC-037 through AC-040)
#
# Tests that the skill count of 18 is reflected consistently across:
#   1. CLAUDE.md
#   2. README.md
#   3. docs/reference/skills.md
#   4. docs/architecture.md
#
# Also verifies that deleted skills are absent from all docs
# and that docs/architecture.md shows core file count = 17.
#
# Historic file from v9.3.0 ship; refactored after v9.5.0 deleted 4 more skills (22 -> 18).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
[ -f "$REPO_ROOT/tests/lib/fixtures.sh" ] || REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
README_MD="$REPO_ROOT/README.md"
SKILLS_REF="$REPO_ROOT/docs/reference/skills.md"
ARCH_MD="$REPO_ROOT/docs/architecture.md"

# ---------------------------------------------------------------------------
# AC-037: CLAUDE.md skill count = 18
# ---------------------------------------------------------------------------
echo "--- AC-037: CLAUDE.md skill count = 18 ---"
if [ ! -f "$CLAUDE_MD" ]; then
  fail "CLAUDE.md does not exist"
else
  if grep -qF '18 skills' "$CLAUDE_MD" || grep -qF '**18 skills**' "$CLAUDE_MD" || grep -qE '\b18\b.*[Ss]kill' "$CLAUDE_MD"; then
    echo "PASS: CLAUDE.md contains skill count reference of 18"
  else
    fail "AC-037 — CLAUDE.md does not contain skill count '18'"
  fi
fi

# AC-037: Deleted skills absent from CLAUDE.md skill list (v9.3.0 + v9.5.0 deletions)
echo "--- AC-037: Deleted skills absent from CLAUDE.md skill list ---"
for deleted in "fix-ticket" "scaffold-add" "resume-ticket" "migrate-config" "estimate" "pipeline-status" "scaffold-validate"; do
  # Check the skill list section specifically (not CHANGELOG or history references)
  if grep -qE "^.*\`/${deleted}\`|, /${deleted}[, $]|/${deleted}," "$CLAUDE_MD" 2>/dev/null; then
    fail "AC-037 — CLAUDE.md skill list still contains '/$deleted'"
  else
    echo "PASS: '/$deleted' not in CLAUDE.md skill list"
  fi
done

# AC-037: CLAUDE.md skill list contains canonical v9.5.0+ skills
for required_skill in "fix-bugs" "check-setup"; do
  if grep -qF "/$required_skill" "$CLAUDE_MD"; then
    echo "PASS: '/$required_skill' present in CLAUDE.md"
  else
    fail "AC-037 — '/$required_skill' not found in CLAUDE.md skill list"
  fi
done

# ---------------------------------------------------------------------------
# AC-038: README.md skill count = 18
# ---------------------------------------------------------------------------
echo "--- AC-038: README.md skill count = 18 ---"
if [ ! -f "$README_MD" ]; then
  echo "SKIP: README.md does not exist — skipping README count check"
else
  if grep -qE '\b18\b.*[Ss]kill|[Ss]kill.*\b18\b' "$README_MD"; then
    echo "PASS: README.md contains skill count reference of 18"
  else
    fail "AC-038 — README.md does not contain skill count '18'"
  fi

  # Deleted skills absent from README skill list (v9.3.0 + v9.5.0 deletions)
  for deleted in "fix-ticket" "scaffold-add" "resume-ticket" "migrate-config" "estimate" "pipeline-status" "scaffold-validate"; do
    # Look for the skill as an invocation token in the list (not historical CHANGELOG text)
    if grep -qE "^\s*[|*-].*/${deleted}\b|^\`/${deleted}\`" "$README_MD" 2>/dev/null; then
      fail "AC-038 — README.md skill list still contains '/$deleted'"
    else
      echo "PASS: '/$deleted' not in README.md skill list section"
    fi
  done
fi

# ---------------------------------------------------------------------------
# AC-039: docs/reference/skills.md skill count = 18, deleted skills absent
# ---------------------------------------------------------------------------
echo "--- AC-039: docs/reference/skills.md updated ---"
if [ ! -f "$SKILLS_REF" ]; then
  fail "AC-039 — docs/reference/skills.md does not exist"
else
  # Deleted skills must not appear as table rows in the skills reference (v9.3.0 + v9.5.0 deletions)
  for deleted in "fix-ticket" "scaffold-add" "resume-ticket" "migrate-config" "estimate" "pipeline-status" "scaffold-validate"; do
    if grep -qE "^\|.*${deleted}.*\|" "$SKILLS_REF"; then
      fail "AC-039 — docs/reference/skills.md still has table row for '$deleted'"
    else
      echo "PASS: '$deleted' not in skills.md reference table"
    fi
  done

  # Skill count reference
  if grep -qE '\b18\b' "$SKILLS_REF"; then
    echo "PASS: docs/reference/skills.md contains count reference '18'"
  else
    fail "AC-039 — docs/reference/skills.md does not contain '18' count"
  fi
fi

# ---------------------------------------------------------------------------
# AC-040: docs/architecture.md skill count = 18, core count = 17
# ---------------------------------------------------------------------------
echo "--- AC-040: docs/architecture.md counts = 18 skills, 17 core ---"
if [ ! -f "$ARCH_MD" ]; then
  fail "AC-040 — docs/architecture.md does not exist"
else
  if grep -qE '\b18\b.*[Ss]kill|[Ss]kill.*\b18\b' "$ARCH_MD"; then
    echo "PASS: docs/architecture.md contains skill count '18'"
  else
    fail "AC-040 — docs/architecture.md does not contain skill count '18'"
  fi

  # Core file count must be 17 (added core/resume-detection.md in v9.3.0; unchanged in v9.5.0)
  if grep -qE '\b17\b.*core|core.*\b17\b' "$ARCH_MD"; then
    echo "PASS: docs/architecture.md contains core file count '17'"
  else
    fail "AC-040 — docs/architecture.md does not contain core file count '17'"
  fi
fi

# ---------------------------------------------------------------------------
# AC-041 (partial): CHANGELOG.md has v9.3.0 section
# ---------------------------------------------------------------------------
echo "--- AC-041: CHANGELOG.md has v9.3.0 section ---"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"
if [ ! -f "$CHANGELOG" ]; then
  fail "AC-041 — CHANGELOG.md does not exist"
else
  if grep -qE '^## v9\.3\.0|^## \[9\.3\.0\]' "$CHANGELOG"; then
    echo "PASS: CHANGELOG.md has v9.3.0 section heading"
  else
    fail "AC-041 — CHANGELOG.md missing '## v9.3.0' or '## [9.3.0]' heading"
  fi

  # Must have ### Removed section
  if grep -qE '^### Removed' "$CHANGELOG"; then
    echo "PASS: CHANGELOG.md has '### Removed' subsection"
  else
    fail "AC-041 — CHANGELOG.md missing '### Removed' subsection"
  fi

  # Must mention fix-ticket removal in CHANGELOG
  if grep -qF 'fix-ticket' "$CHANGELOG"; then
    echo "PASS: CHANGELOG.md mentions fix-ticket (migration reference)"
  else
    fail "AC-041 — CHANGELOG.md does not mention fix-ticket deletion/migration"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.3.0-doc-count-sync — all doc count sync checks passed"
fi
exit "$FAIL"
