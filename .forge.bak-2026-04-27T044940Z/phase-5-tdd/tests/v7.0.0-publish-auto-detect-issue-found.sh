#!/usr/bin/env bash
# AC-PUBLISH-AUTO-DETECT-1, AC-PUBLISH-AUTO-DETECT-2, AC-PUBLISH-AUTO-DETECT-8,
# AC-PUBLISH-AUTO-DETECT-9, AC-PUBLISH-AUTO-DETECT-10
# Verifies the "full-publish" mode prose in skills/publish/SKILL.md:
# Step 0 branch parse, tracker_needed gate, 3-way fork, core/mcp-detection.md citations,
# interactive-only operator note.
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

PUBLISH="skills/publish/SKILL.md"

# Functional check 1: publish skill file exists
if [ ! -f "$PUBLISH" ]; then
  echo "FAIL: $PUBLISH missing" >&2
  exit 1
fi

# Functional check 2: Step 0 branch-parse step exists and references git branch --show-current
if ! grep -E '^### Step 0' "$PUBLISH" >/dev/null 2>&1; then
  fail "$PUBLISH: no '### Step 0' step heading found"
fi
if ! grep -qE 'git branch --show-current|current_branch' "$PUBLISH"; then
  fail "$PUBLISH: Step 0 does not parse the current branch via git branch --show-current"
fi

# Functional check 3: tracker_needed gate is documented
if ! grep -q 'tracker_needed' "$PUBLISH"; then
  fail "$PUBLISH: tracker_needed gate not documented"
fi

# Functional check 4: 3-way mode fork prose present (full-publish, pr-only-no-id, pr-only-404)
if ! grep -q 'full-publish' "$PUBLISH"; then
  fail "$PUBLISH: 'full-publish' mode not mentioned"
fi
if ! grep -q 'pr-only-no-id' "$PUBLISH"; then
  fail "$PUBLISH: 'pr-only-no-id' mode not mentioned"
fi
if ! grep -q 'pr-only-404' "$PUBLISH"; then
  fail "$PUBLISH: 'pr-only-404' mode not mentioned"
fi

# Functional check 5: full-publish mode — tracker lookup prose (issue found path)
if ! grep -qE 'Issue.*found.*tracker|tracker.*updated|full.*publish.*mode|mode.*full-publish' "$PUBLISH"; then
  fail "$PUBLISH: full-publish mode path prose not found (issue found → full publish)"
fi

# Functional check 6: citations to core/mcp-detection.md preserved
if ! grep -q 'core/mcp-detection.md' "$PUBLISH"; then
  fail "$PUBLISH: missing citation to core/mcp-detection.md"
fi

# Functional check 7: interactive-only + autopilot operator note present
if ! (grep -E 'interactive-only|autopilot' "$PUBLISH" | grep -q autopilot); then
  fail "$PUBLISH: interactive-only / autopilot operator note not present"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-PUBLISH-AUTO-DETECT-1,2,8,9,10 — /publish full-publish mode prose present"
exit "$FAIL"
