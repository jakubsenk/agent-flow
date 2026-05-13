#!/usr/bin/env bash
# AC-CHANGELOG-MIGRATION-1, AC-CHANGELOG-MIGRATION-2, AC-CHANGELOG-MIGRATION-3,
# AC-CHANGELOG-MIGRATION-4, AC-CHANGELOG-MIGRATION-5, AC-CHANGELOG-MIGRATION-6,
# AC-CHANGELOG-MIGRATION-7
# Asserts CHANGELOG.md has the [7.0.0] section with Migration subsection containing
# all 5 bullets plus 3 required disclosures, and check-setup has deprecated-config detector.
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Functional check 1: ## [7.0.0] section exists
if ! grep -qE '^## \[7\.0\.0\]' CHANGELOG.md 2>/dev/null; then
  fail "CHANGELOG.md: '## [7.0.0]' section header not found"
fi

# Functional check 2: Migration subsection present
if ! grep -qE '^### Migration from v6\.10\.x to v7\.0\.0' CHANGELOG.md 2>/dev/null; then
  fail "CHANGELOG.md: '### Migration from v6.10.x to v7.0.0' subsection not found"
fi

# Functional check 3a: Bullet 1 — Extra labels removal
if ! grep -qE 'Extra labels.*PR Rules' CHANGELOG.md 2>/dev/null; then
  fail "CHANGELOG.md: migration bullet 1 (Extra labels → PR Rules) not found"
fi

# Functional check 3b: Bullet 2 — pipeline-status rename
if ! grep -qE 'pipeline-status' CHANGELOG.md 2>/dev/null; then
  fail "CHANGELOG.md: migration bullet 2 (pipeline-status) not found"
fi

# Functional check 3c: Bullet 3 — setup-mcp rename
if ! grep -qE 'setup-mcp' CHANGELOG.md 2>/dev/null; then
  fail "CHANGELOG.md: migration bullet 3 (setup-mcp) not found"
fi

# Functional check 3d: Bullet 4 — /create-pr removed
if ! grep -qE '/create-pr.*removed' CHANGELOG.md 2>/dev/null; then
  fail "CHANGELOG.md: migration bullet 4 (/create-pr removed) not found"
fi

# Functional check 3e: Bullet 5 — Pause Limits doc fix
if ! grep -qE 'Pause Limits.*pipeline skills' CHANGELOG.md 2>/dev/null; then
  fail "CHANGELOG.md: migration bullet 5 (Pause Limits doc fix) not found"
fi

# Functional check 4: Lost-agency disclosure present
if ! grep -qE 'Lost agency|opt out.*tracker|branch-rename workaround|non-matching branch' CHANGELOG.md 2>/dev/null; then
  fail "CHANGELOG.md: lost-agency disclosure not found"
fi

# Functional check 5: Skill-not-found disclosure present
if ! grep -qE 'skill-not-found|standard skill-not-found|no aliasing' CHANGELOG.md 2>/dev/null; then
  fail "CHANGELOG.md: skill-not-found disclosure not found"
fi

# Functional check 6: State.json forward-compat note present
if ! grep -qE 'state\.json.*unchanged|forward-compat|in-flight pipelines' CHANGELOG.md 2>/dev/null; then
  fail "CHANGELOG.md: state.json forward-compat note not found"
fi

# Functional check 7: /check-setup deprecated-config detector present in skills/check-setup/SKILL.md
# Must have WARN for Extra labels AND must NOT tie it to exit 1
if ! grep -qE 'Deprecated.*config|deprecated v6\.x|deprecated.*Extra labels' skills/check-setup/SKILL.md 2>/dev/null; then
  fail "skills/check-setup/SKILL.md: deprecated-config detector not present"
fi
if ! grep -qE '\[WARN\].*Extra labels' skills/check-setup/SKILL.md 2>/dev/null; then
  fail "skills/check-setup/SKILL.md: [WARN] Extra labels message not present"
fi
# Exit-neutral check: [WARN] line must NOT be followed by exit 1 / FAIL
if grep -E '\[WARN\].*Extra labels' skills/check-setup/SKILL.md | grep -qE 'exit 1|FAIL|fail\(\)|return 1' 2>/dev/null; then
  fail "skills/check-setup/SKILL.md: [WARN] Extra labels is incorrectly wired to exit 1 / FAIL"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-CHANGELOG-MIGRATION-1..7 — CHANGELOG [7.0.0] with migration guide + 5 bullets + 3 disclosures"
exit "$FAIL"
