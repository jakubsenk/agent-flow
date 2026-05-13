#!/usr/bin/env bash
# AC-PUBLISH-AUTO-DETECT-13, AC-PUBLISH-AUTO-DETECT-14, AC-PUBLISH-AUTO-DETECT-15,
# AC-PUBLISH-AUTO-DETECT-ZERO-COMMITS
# Verifies the "pr-only-no-id" (no issue ID extractable from branch) mode prose,
# the missing Branch naming config fallback, the detached HEAD FAIL guard,
# and the zero-commits early-stop in skills/publish/SKILL.md.
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

# Functional check 2: SC-8 no-issue-id INFO message on a single line with required tokens
# Branch does not match Branch naming pattern → Creating PR without tracker contact
if ! grep -qE '\[ceos-agents\]\[INFO\].*does not match the configured Branch naming pattern.*Creating PR without tracker contact' "$PUBLISH"; then
  fail "$PUBLISH: SC-8 no-issue-id INFO message missing or tokens not on a single line"
fi

# Functional check 3: SC-10 missing Branch naming config INFO message present
# No Branch naming pattern configured; PR-only mode
if ! grep -qE '\[ceos-agents\]\[INFO\].*No Branch naming pattern configured.*PR-only mode' "$PUBLISH"; then
  fail "$PUBLISH: SC-10 missing Branch naming pattern INFO message absent"
fi

# Functional check 4: SC-12 detached HEAD FAIL guard present
if ! grep -qE 'detached HEAD' "$PUBLISH"; then
  fail "$PUBLISH: detached HEAD guard not mentioned"
fi
if ! grep -qE 'Cannot determine branch.*detached HEAD' "$PUBLISH"; then
  fail "$PUBLISH: SC-12 detached HEAD diagnostic message missing"
fi

# Functional check 5: zero-commits early-stop documented (Step 3a)
if ! grep -qE 'No changes to publish|zero commits|no commits above' "$PUBLISH"; then
  fail "$PUBLISH: zero-commits early-stop prose not found"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-PUBLISH-AUTO-DETECT-13,14,15,ZERO-COMMITS — /publish pr-only-no-id + edge case prose present"
exit "$FAIL"
