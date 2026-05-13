#!/usr/bin/env bash
# Test: Webhook format alignment in implement-feature and fix-bugs
# AC-5: fix-bugs step 8b is a pointer only (no curl, no deviant keys)
# AC-6: fix-bugs step X delegates to core/block-handler.md with 4 skill-specific items
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

FIX_BUGS="$REPO_ROOT/skills/fix-bugs/SKILL.md"
IMPL_FEATURE="$REPO_ROOT/skills/implement-feature/SKILL.md"

for f in "$FIX_BUGS" "$IMPL_FEATURE"; do
  if [ ! -f "$f" ]; then
    fail "Missing file: $f"
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# AC-5: fix-bugs step 8b — must be a pointer, no inline webhook
# Extract text between "### 8b." and the next "###" heading
# ---------------------------------------------------------------------------

STEP_8B=$(awk '/^### 8b\./,/^###/' "$FIX_BUGS" | grep -v "^### 8b\." | grep -v "^###" || true)

if [ -z "$STEP_8B" ]; then
  fail "skills/fix-bugs/SKILL.md: step '### 8b.' not found — step may be missing or renamed"
else
  # Must reference core/post-publish-hook.md
  if ! echo "$STEP_8B" | grep -q "core/post-publish-hook.md"; then
    fail "skills/fix-bugs/SKILL.md step 8b: does not reference 'core/post-publish-hook.md' — must be a pointer to core contract"
  fi

  # Must NOT contain a curl command
  if echo "$STEP_8B" | grep -q "curl"; then
    fail "skills/fix-bugs/SKILL.md step 8b: still contains 'curl' — inline webhook must be removed"
  fi

  # Must NOT contain inline webhook JSON payload indicator
  if echo "$STEP_8B" | grep -q '"event"'; then
    fail "skills/fix-bugs/SKILL.md step 8b: still contains '\"event\"' JSON key — inline webhook payload must be removed"
  fi
fi

# ---------------------------------------------------------------------------
# AC-5: implement-feature must NOT use bare "issue" key (only "issue_id")
# The deviant key was `"issue"` instead of canonical `"issue_id"`
# ---------------------------------------------------------------------------

# Check for the deviant key pattern: "issue": (but not "issue_id":)
# We look for "issue": that is NOT followed by _id
if grep -qP '"issue"\s*:' "$IMPL_FEATURE" 2>/dev/null || grep -qE '"issue"[[:space:]]*:' "$IMPL_FEATURE"; then
  # Make sure it's not just "issue_id" being matched — use a stricter check
  # Exclude lines that also contain issue_id
  DEVIANT=$(grep -E '"issue"[[:space:]]*:' "$IMPL_FEATURE" | grep -v '"issue_id"' || true)
  if [ -n "$DEVIANT" ]; then
    fail "skills/implement-feature/SKILL.md: contains deviant key '\"issue\":' (not '\"issue_id\":') in webhook payload — must use canonical key"
  fi
fi

# ---------------------------------------------------------------------------
# AC-6: fix-bugs step X — block handler delegation
# Extract text between "### X." and the next "##" heading
# ---------------------------------------------------------------------------

STEP_X=$(awk '/^### X\./,/^##/' "$FIX_BUGS" | grep -v "^### X\." | grep -v "^##" || true)

if [ -z "$STEP_X" ]; then
  fail "skills/fix-bugs/SKILL.md: step '### X.' not found — block handler step may be missing or renamed"
else
  # Must reference core/block-handler.md
  if ! echo "$STEP_X" | grep -q "core/block-handler.md"; then
    fail "skills/fix-bugs/SKILL.md step X: does not reference 'core/block-handler.md' — must delegate to core contract"
  fi

  # Must contain "Skill-specific context" section
  if ! echo "$STEP_X" | grep -qi "Skill-specific context"; then
    fail "skills/fix-bugs/SKILL.md step X: 'Skill-specific context' section missing"
  fi

  # Must have exactly 4 top-level bullet points (lines starting with "- ")
  BULLET_COUNT=$(echo "$STEP_X" | grep -c "^- " || true)
  if [ "$BULLET_COUNT" -ne 4 ]; then
    fail "skills/fix-bugs/SKILL.md step X: expected exactly 4 top-level bullet points (^- ), found $BULLET_COUNT"
  fi

  # Must NOT contain the old inline numbered pattern (steps 1. through 6.)
  for n in 1 2 3 4 5 6; do
    if echo "$STEP_X" | grep -qE "^${n}\. "; then
      fail "skills/fix-bugs/SKILL.md step X: still contains old inline numbered step '${n}.' — must be fully delegated to core/block-handler.md"
    fi
  done

  # Must NOT contain a curl command (deviant inline webhook)
  if echo "$STEP_X" | grep -q "curl"; then
    fail "skills/fix-bugs/SKILL.md step X: still contains 'curl' — inline webhook must be removed"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: fix-bugs step 8b is a pointer-only to core/post-publish-hook.md; fix-bugs step X delegates to core/block-handler.md with exactly 4 skill-specific bullet points; implement-feature uses canonical 'issue_id' key (AC-5/AC-6)"
exit "$FAIL"
