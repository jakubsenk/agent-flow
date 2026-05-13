#!/bin/bash
# PURPOSE: (HIDDEN) Assert REQ-H-101 hard-error behavior: no skill file or core file still uses
#          [WARN] for deprecated agent names (triage-analyst, code-analyst, e2e-test-engineer,
#          reproducer, browser-verifier). Per REQ-H-101, v9.0.0 emits [ERROR] not [WARN].
#          Also addresses review finding f-602b8e: there must be SOME hard-error reference for these
#          deprecated names in the codebase (not just migration guide prose).
# AC-H-N covered: (REQ-H-101 behavioral assertion; review finding f-602b8e)
# INVOKED BY: tests/harness/run-tests.sh (hidden)
# EXPECTED ON v8.0.0: FAIL (skills/core emit [WARN] for deprecated names, not [ERROR])
# EXPECTED ON v9.0.0: PASS ([WARN] for deprecated names replaced with [ERROR])
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

DEPRECATED_NAMES="triage-analyst|code-analyst|e2e-test-engineer|reproducer|browser-verifier"

# Assert: no [WARN] string remains adjacent to deprecated agent names in core/ or skills/
# These should now be [ERROR] per REQ-H-101
warn_with_deprecated=$(grep -rnE "\[WARN\].*(${DEPRECATED_NAMES})" "$REPO_ROOT/core/" "$REPO_ROOT/skills/" --include="*.md" 2>/dev/null || true)
if [ -n "$warn_with_deprecated" ]; then
  echo "FAIL: Found [WARN] for deprecated agent names (should be [ERROR] in v9.0.0):" >&2
  echo "$warn_with_deprecated" >&2
  fail "[WARN] still used for deprecated agent names — must be [ERROR] per REQ-H-101"
  # Mutation catch: keeping [WARN] instead of upgrading to [ERROR] fails here
fi

# Assert: no [WARN] for .md overlay detection in core/ or skills/
# Per REQ-H-100, .md overlays now emit [ERROR] not [WARN]
warn_with_md_overlay=$(grep -rnE '\[WARN\].*\.md.*(overlay|customization)|\[WARN\].*customization.*\.md' "$REPO_ROOT/core/" "$REPO_ROOT/skills/" --include="*.md" 2>/dev/null || true)
if [ -n "$warn_with_md_overlay" ]; then
  echo "FAIL: Found [WARN] for .md overlay detection (should be [ERROR] in v9.0.0):" >&2
  echo "$warn_with_md_overlay" >&2
  fail "[WARN] still used for .md overlay detection — must be [ERROR] per REQ-H-100"
fi

# Positive assertion: at least one [ERROR] reference for deprecated names should exist
# (confirms the hard-error was actually added, not just WARN removed)
error_with_deprecated=$(grep -rnE "\[ERROR\].*(${DEPRECATED_NAMES})|(${DEPRECATED_NAMES}).*\[ERROR\]" "$REPO_ROOT/core/" "$REPO_ROOT/skills/" --include="*.md" 2>/dev/null || true)
if [ -z "$error_with_deprecated" ]; then
  fail "No [ERROR] reference for deprecated agent names found in core/ or skills/ — REQ-H-101 requires hard-error behavior to be documented"
  # Mutation catch: removing [ERROR] handling without replacing it fails here
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: REQ-H-100/H-101 (f-602b8e) — no [WARN] for deprecated names or .md overlays; [ERROR] hard-error behavior confirmed"
fi
exit "$FAIL"
