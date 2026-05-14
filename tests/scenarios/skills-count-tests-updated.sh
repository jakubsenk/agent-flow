#!/bin/bash
# Covers: AC-40 (skills-directory-structure.sh enumerates 18 skills, not 4 deleted),
#         AC-41 (skills-frontmatter-check.sh removes 4 deleted skills),
#         AC-42 (v9.3.0-skill-count.sh count = 18),
#         AC-43 (no-mcp-jargon-errors.sh STANDARD_ERROR_FILES no longer has deleted skills),
#         AC-44 (v8-count-skills.sh count = 18)
# Post-cleanup baseline: skills reduced from 22 to 18.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: v9-5-skills-count-tests-updated — $1"; FAIL=1; }

DELETED_SKILLS="migrate-config estimate pipeline-status scaffold-validate"

# AC-40: skills-directory-structure.sh
FILE40="$REPO_ROOT/tests/scenarios/skills-directory-structure.sh"
if [ ! -f "$FILE40" ]; then
  fail "tests/scenarios/skills-directory-structure.sh not found"
else
  for skill in $DELETED_SKILLS; do
    if grep -qE "^[[:space:]]*\"$skill\"" "$FILE40"; then
      fail "skills-directory-structure.sh still lists deleted skill '$skill'"
    fi
  done
  if grep -qE '\b18\b' "$FILE40"; then
    echo "PASS: skills-directory-structure.sh references count 18"
  else
    fail "skills-directory-structure.sh does not reference count 18"
  fi
fi

# AC-41: skills-frontmatter-check.sh
FILE41="$REPO_ROOT/tests/scenarios/skills-frontmatter-check.sh"
if [ ! -f "$FILE41" ]; then
  fail "tests/scenarios/skills-frontmatter-check.sh not found"
else
  for skill in $DELETED_SKILLS; do
    if grep -qF "\"$skill\"" "$FILE41"; then
      fail "skills-frontmatter-check.sh still references deleted skill '$skill'"
    fi
  done
  echo "PASS: skills-frontmatter-check.sh does not reference deleted skills"
fi

# AC-42: v9.3.0-skill-count.sh
FILE42="$REPO_ROOT/tests/scenarios/v9.3.0-skill-count.sh"
if [ ! -f "$FILE42" ]; then
  fail "tests/scenarios/v9.3.0-skill-count.sh not found"
else
  if grep -qE 'EXPECTED_SKILL_COUNT=18|SKILL_COUNT.*-eq 18|-eq 18.*SKILL|expected 18' "$FILE42"; then
    echo "PASS: v9.3.0-skill-count.sh expects 18 skills"
  else
    fail "v9.3.0-skill-count.sh does not expect 18 skills"
  fi
  if grep -qE 'EXPECTED_SKILL_COUNT=22|-eq 22.*SKILL|expected 22 skill' "$FILE42"; then
    fail "v9.3.0-skill-count.sh still has 22-skill expectation"
  else
    echo "PASS: 22-skill expectation absent from v9.3.0-skill-count.sh"
  fi
fi

# AC-43: no-mcp-jargon-errors.sh
FILE43="$REPO_ROOT/tests/scenarios/no-mcp-jargon-errors.sh"
if [ ! -f "$FILE43" ]; then
  fail "tests/scenarios/no-mcp-jargon-errors.sh not found"
else
  if grep -qF 'skills/estimate/SKILL.md' "$FILE43"; then
    fail "no-mcp-jargon-errors.sh still references skills/estimate/SKILL.md"
  else
    echo "PASS: skills/estimate/SKILL.md absent from no-mcp-jargon-errors.sh"
  fi
  if grep -qF 'skills/pipeline-status/SKILL.md' "$FILE43"; then
    fail "no-mcp-jargon-errors.sh still references skills/pipeline-status/SKILL.md"
  else
    echo "PASS: skills/pipeline-status/SKILL.md absent from no-mcp-jargon-errors.sh"
  fi
fi

# AC-44: v8-count-skills.sh
FILE44="$REPO_ROOT/tests/scenarios/v8-count-skills.sh"
if [ ! -f "$FILE44" ]; then
  fail "tests/scenarios/v8-count-skills.sh not found"
else
  if grep -qF 'EXPECTED_SKILL_COUNT=18' "$FILE44"; then
    echo "PASS: v8-count-skills.sh expects 18 skills"
  else
    fail "v8-count-skills.sh does not have EXPECTED_SKILL_COUNT=18"
  fi
  if grep -qF 'EXPECTED_SKILL_COUNT=22' "$FILE44"; then
    fail "v8-count-skills.sh still has EXPECTED_SKILL_COUNT=22"
  else
    echo "PASS: EXPECTED_SKILL_COUNT=22 absent from v8-count-skills.sh"
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-skills-count-tests-updated — all 5 count-related test scenarios updated for 18 skills"
fi
exit "$FAIL"
