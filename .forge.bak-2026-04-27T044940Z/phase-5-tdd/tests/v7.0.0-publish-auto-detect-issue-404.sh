#!/usr/bin/env bash
# AC-PUBLISH-AUTO-DETECT-12, AC-PUBLISH-AUTO-DETECT-4
# Verifies the "pr-only-404" (404 WARN) mode prose in skills/publish/SKILL.md.
# The [ceos-agents][WARN] message must be on a single logical line with all
# required tokens per REQ-PUBLISH-AUTO-DETECT SC-7.
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

# Functional check 2: 404 WARN message present with all required tokens on single line
# Must include: [ceos-agents][WARN], "contains issue ID pattern", "no matching ticket was found",
# "Creating PR without tracker update"
if ! grep -qE '\[ceos-agents\]\[WARN\].*contains issue ID pattern.*no matching ticket was found.*Creating PR without tracker update' "$PUBLISH"; then
  fail "$PUBLISH: SC-7 404 WARN message missing or not on a single line with all required tokens"
fi

# Functional check 3: error_type "not_found" bucket present
if ! grep -q '"not_found"' "$PUBLISH"; then
  fail "$PUBLISH: 'not_found' error_type bucket not enumerated"
fi

# Functional check 4: 5-error_type enum complete (all 5 buckets)
if ! grep -q '"tls"' "$PUBLISH"; then
  fail "$PUBLISH: error_type bucket 'tls' missing"
fi
if ! grep -q '"auth"' "$PUBLISH"; then
  fail "$PUBLISH: error_type bucket 'auth' missing"
fi
if ! grep -q '"timeout"' "$PUBLISH"; then
  fail "$PUBLISH: error_type bucket 'timeout' missing"
fi
if ! grep -q '"unknown"' "$PUBLISH"; then
  fail "$PUBLISH: error_type bucket 'unknown' missing"
fi

# Functional check 5: 404 mode does NOT result in FAIL (pipeline continues)
# Presence of "pr-only-404" mode implies continuation rather than abort
if ! grep -q 'pr-only-404' "$PUBLISH"; then
  fail "$PUBLISH: pr-only-404 mode label absent (pipeline-continues semantics not documented)"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-PUBLISH-AUTO-DETECT-12,4 — /publish pr-only-404 WARN mode prose present"
exit "$FAIL"
