#!/usr/bin/env bash
# Test: Plugin version tracking — state schema field, state-manager write, resume-ticket comparison
# AC-6 through AC-9
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SCHEMA="$REPO_ROOT/state/schema.md"
STATE_MGR="$REPO_ROOT/core/state-manager.md"
RESUME="$REPO_ROOT/core/resume-detection.md"

# ---------------------------------------------------------------------------
# AC-6: state/schema.md documents plugin_version field
# ---------------------------------------------------------------------------

if [ ! -f "$SCHEMA" ]; then
  fail "state/schema.md does not exist"
else
  # Field must appear in the Top-Level Field Definitions table
  if ! grep -q "plugin_version" "$SCHEMA"; then
    fail "state/schema.md does not contain 'plugin_version' field"
  fi

  # Field type must be documented as string (or null)
  if ! grep "plugin_version" "$SCHEMA" | grep -qi "string"; then
    fail "state/schema.md: plugin_version field type is not documented as 'string' (or 'string or null')"
  fi

  # Field must appear in the Full Schema Example JSON block
  if ! grep -q '"plugin_version"' "$SCHEMA"; then
    fail "state/schema.md: plugin_version is not present in the Full Schema Example JSON block (expected \"plugin_version\")"
  fi
fi

# ---------------------------------------------------------------------------
# AC-7: core/state-manager.md includes version read and write
# ---------------------------------------------------------------------------

if [ ! -f "$STATE_MGR" ]; then
  fail "core/state-manager.md does not exist"
else
  # Write Process must reference plugin_version
  if ! grep -q "plugin_version" "$STATE_MGR"; then
    fail "core/state-manager.md does not reference 'plugin_version'"
  fi

  # Must reference plugin.json as the authoritative source
  if ! grep -q "plugin.json" "$STATE_MGR"; then
    fail "core/state-manager.md does not reference 'plugin.json' (version source)"
  fi
fi

# ---------------------------------------------------------------------------
# AC-8: resume-ticket includes version comparison with WARN on major mismatch
# ---------------------------------------------------------------------------

if [ ! -f "$RESUME" ]; then
  fail "core/resume-detection.md does not exist"
else
  # Must reference plugin_version field
  if ! grep -q "plugin_version" "$RESUME"; then
    fail "core/resume-detection.md does not reference 'plugin_version'"
  fi

  # Must contain the exact WARN text for major version mismatch
  if ! grep -q "major version mismatch" "$RESUME"; then
    fail "core/resume-detection.md does not contain 'major version mismatch' warning text"
  fi

  # Must reference plugin.json for reading the current installed version
  if ! grep -q "plugin.json" "$RESUME"; then
    fail "core/resume-detection.md does not reference 'plugin.json' (current version source)"
  fi

  # The mismatch must be advisory (WARN), not a blocking action
  if ! grep "major version mismatch" "$RESUME" | grep -qi "warn"; then
    fail "core/resume-detection.md: 'major version mismatch' message does not use WARN (must be advisory, not a block)"
  fi
fi

# ---------------------------------------------------------------------------
# AC-9: No WARN emitted when plugin_version field is absent (backwards compat)
# ---------------------------------------------------------------------------

if [ -f "$RESUME" ]; then
  # The skill must handle the absent/null case — either explicitly or via guard pattern
  # Accept: explicit "absent|null" prose OR guard pattern "[ -n "$PLUGIN_VERSION" ]"
  if ! grep -qiE 'absent|null|\[ -n.*PLUGIN_VERSION' "$RESUME"; then
    fail "core/resume-detection.md does not handle absent/null plugin_version case (backwards compatibility guard missing)"
  fi

  # The handling must be silent: skip, not warn
  # Accept: explicit silent-skip prose OR guard pattern that skips when empty
  if ! grep -qiE 'plugin_version.*(absent|null)|(absent|null).*plugin_version|field is absent|field.*missing|field.*not present|\[ -n.*PLUGIN_VERSION' "$RESUME"; then
    fail "core/resume-detection.md: absent/null plugin_version case does not describe silent skip (expected: skip silently / no WARN)"
  fi
fi

# ---------------------------------------------------------------------------

[ "$FAIL" -eq 0 ] && echo "PASS: Plugin version tracking — state schema, state-manager contract, resume-ticket comparison and backwards compat all valid"
exit "$FAIL"
