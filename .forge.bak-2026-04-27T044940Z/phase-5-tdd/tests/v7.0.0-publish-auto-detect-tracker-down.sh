#!/usr/bin/env bash
# AC-PUBLISH-AUTO-DETECT-5, AC-PUBLISH-AUTO-DETECT-7, AC-PUBLISH-AUTO-DETECT-11
# Verifies the FAIL tier (tracker down / unreachable) prose in skills/publish/SKILL.md.
# Checks: [ceos-agents] 🔴 Pipeline Block format, unknown→FAIL default,
# branch-rename escape hatch documented.
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

PUBLISH="skills/publish/SKILL.md"

# Functional check 1: skill file exists
if [ ! -f "$PUBLISH" ]; then
  echo "FAIL: $PUBLISH missing" >&2
  exit 1
fi

# Functional check 2: FAIL tier uses [ceos-agents] 🔴 Pipeline Block format
# (per CLAUDE.md Block Comment Template)
if ! grep -q '\[ceos-agents\] 🔴 Pipeline Block' "$PUBLISH"; then
  fail "$PUBLISH: FAIL tier missing '[ceos-agents] 🔴 Pipeline Block' header"
fi

# Functional check 3: Skill: field used (not Agent:), per convention for skill-level blocks
if ! grep -E 'Skill: /ceos-agents:publish' "$PUBLISH" >/dev/null 2>&1; then
  fail "$PUBLISH: FAIL tier missing 'Skill: /ceos-agents:publish' field"
fi

# Functional check 4: unknown→FAIL defensive default documented
if ! grep -E 'unknown.*FAIL|unknown".*FAIL' "$PUBLISH" >/dev/null 2>&1; then
  fail "$PUBLISH: unknown→FAIL defensive default not documented"
fi

# Functional check 5: branch-rename escape hatch documented in FAIL tier Recommendation
if ! (grep -E 'rename.*branch|chore/' "$PUBLISH" | grep -q rename); then
  fail "$PUBLISH: FAIL tier Recommendation missing branch-rename escape hatch"
fi

# Functional check 6: /ceos-agents:check-setup referenced in Recommendation
if ! grep -qE 'check-setup' "$PUBLISH"; then
  fail "$PUBLISH: FAIL tier Recommendation does not reference /ceos-agents:check-setup"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-PUBLISH-AUTO-DETECT-5,7,11 — /publish FAIL tier (tracker-down) prose present"
exit "$FAIL"
