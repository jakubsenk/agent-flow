#!/usr/bin/env bash
# Hidden test: AC-RELEASE-1a, AC-RELEASE-1b, AC-RELEASE-1c
# Verifies the CHANGELOG.md v6.8.1 block:
#   - heading present
#   - ### Fixed lists all 6 items referencing correct file paths
#   - ### Internal subsection present (NOT ### Added)
#   - Two new scenario files listed under ### Internal
#   - Corrected path examples/configs/ used (NOT erroneous examples/config-templates/)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

echo "--- h-changelog-internal-section (AC-RELEASE-1a/b/c): v6.8.1 CHANGELOG block ---"

if [ ! -f "$CHANGELOG" ]; then
  echo "FAIL: CHANGELOG.md not found at $CHANGELOG"
  exit 1
fi

# -----------------------------------------------------------------------
# AC-RELEASE-1a: heading present
# -----------------------------------------------------------------------
echo "--- AC-RELEASE-1a: ## [6.8.1] heading present ---"
if grep -qE '^## \[6\.8\.1\] — 2026-04-18' "$CHANGELOG"; then
  echo "OK (AC-RELEASE-1a): ## [6.8.1] — 2026-04-18 heading found in CHANGELOG.md"
else
  fail "AC-RELEASE-1a: ## [6.8.1] — 2026-04-18 heading missing from CHANGELOG.md"
fi

# Extract v6.8.1 block (from ## [6.8.1] to ## [6.8.0])
TMPBLOCK="$(mktemp /tmp/v681_block.XXXXXX)"
awk '/^## \[6\.8\.1\]/{flag=1} /^## \[6\.8\.0\]/{flag=0} flag' "$CHANGELOG" > "$TMPBLOCK"

# -----------------------------------------------------------------------
# AC-RELEASE-1b: ### Internal subsection with both new scenarios
# -----------------------------------------------------------------------
echo "--- AC-RELEASE-1b: ### Internal subsection present ---"
if grep -qE '^### Internal$' "$TMPBLOCK"; then
  echo "OK (AC-RELEASE-1b): ### Internal section present in v6.8.1 CHANGELOG block"
else
  fail "AC-RELEASE-1b: ### Internal section missing from v6.8.1 CHANGELOG block (must NOT use ### Added for test scenarios)"
fi

echo "--- AC-RELEASE-1b: v681-fixer-reviewer-crash-recovery.sh listed under ### Internal ---"
if grep -qF 'v681-fixer-reviewer-crash-recovery.sh' "$TMPBLOCK"; then
  echo "OK (AC-RELEASE-1b): v681-fixer-reviewer-crash-recovery.sh listed in v6.8.1 block"
else
  fail "AC-RELEASE-1b: v681-fixer-reviewer-crash-recovery.sh missing from v6.8.1 CHANGELOG block"
fi

echo "--- AC-RELEASE-1b: v681-harness-exit-propagation.sh listed under ### Internal ---"
if grep -qF 'v681-harness-exit-propagation.sh' "$TMPBLOCK"; then
  echo "OK (AC-RELEASE-1b): v681-harness-exit-propagation.sh listed in v6.8.1 block"
else
  fail "AC-RELEASE-1b: v681-harness-exit-propagation.sh missing from v6.8.1 CHANGELOG block"
fi

echo "--- AC-RELEASE-1b: ### Added must NOT appear in v6.8.1 block ---"
if grep -qE '^### Added$' "$TMPBLOCK"; then
  fail "AC-RELEASE-1b: ### Added found inside v6.8.1 CHANGELOG block — test scenarios must go under ### Internal, not ### Added"
else
  echo "OK (AC-RELEASE-1b): ### Added is absent from v6.8.1 block (scenarios correctly under ### Internal)"
fi

echo "--- AC-RELEASE-1b: ### Fixed lists all 6 items ---"
for ref in 'examples/configs/' 'skills/autopilot/SKILL.md' 'skills/fix-ticket/SKILL.md' 'core/post-publish-hook.md' 'core/fixer-reviewer-loop.md' 'tests/harness/run-tests.sh'; do
  if grep -qF "$ref" "$TMPBLOCK"; then
    echo "OK (AC-RELEASE-1b): ### Fixed references '$ref'"
  else
    fail "AC-RELEASE-1b: ### Fixed in v6.8.1 CHANGELOG block is missing reference to '$ref'"
  fi
done

# -----------------------------------------------------------------------
# AC-RELEASE-1c: corrected path examples/configs/ used; erroneous path absent
# -----------------------------------------------------------------------
echo "--- AC-RELEASE-1c: corrected path examples/configs/ present ---"
if grep -qF 'examples/configs/' "$TMPBLOCK"; then
  echo "OK (AC-RELEASE-1c): v6.8.1 CHANGELOG block references corrected path examples/configs/"
else
  fail "AC-RELEASE-1c: v6.8.1 CHANGELOG block does not reference examples/configs/ (corrected path)"
fi

echo "--- AC-RELEASE-1c: erroneous path examples/config-templates/ absent ---"
if grep -qF 'examples/config-templates/' "$TMPBLOCK"; then
  fail "AC-RELEASE-1c: v6.8.1 CHANGELOG block still references erroneous path examples/config-templates/ — must use examples/configs/"
else
  echo "OK (AC-RELEASE-1c): erroneous path examples/config-templates/ is absent from v6.8.1 CHANGELOG block"
fi

rm -f "$TMPBLOCK"

# -----------------------------------------------------------------------
# Final result
# -----------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: h-changelog-internal-section — v6.8.1 CHANGELOG block correct (heading, ### Fixed, ### Internal, corrected path)"
fi
exit "$FAIL"
