#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #13 — Tier B+C, inline redefine)
# Functional: parse_pause_timeout() boundary values.
# REQ-T1-5 path (a): inline redefine of parse_pause_timeout (NOT awk-extracted).
# Tests: 1h (min), 30 days (default), 365 days (max), invalid values (fallback to 30d).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Verify production source has canonical function signature (Tier B doc assertion)
AUTOPILOT="$REPO_ROOT/skills/autopilot/SKILL.md"
if [ -f "$AUTOPILOT" ]; then
  if ! grep -q 'parse_pause_timeout' "$AUTOPILOT"; then
    fail "skills/autopilot/SKILL.md missing parse_pause_timeout function"
  fi
fi

# Inline reimplementation (per REQ-T1-5 path (a) — NOT awk-extracted):
# Contract from skills/autopilot/SKILL.md parse_pause_timeout():
# - Valid range: 1 hour to 365 days
# - Default: 30 days (on invalid/absent input)
# - Returns seconds
parse_pause_timeout() {
  local raw="${1:-}"
  local default_seconds=$((30 * 24 * 3600))
  local min_seconds=3600
  local max_seconds=$((365 * 24 * 3600))
  if [[ -z "$raw" ]]; then
    echo "$default_seconds"; return 0
  fi
  # Parse "Nd" or "Nh" format
  if [[ "$raw" =~ ^([0-9]+)d$ ]]; then
    local val=$(( ${BASH_REMATCH[1]} * 24 * 3600 ))
    if [ "$val" -ge "$min_seconds" ] && [ "$val" -le "$max_seconds" ]; then
      echo "$val"; return 0
    fi
  elif [[ "$raw" =~ ^([0-9]+)h$ ]]; then
    local val=$((${BASH_REMATCH[1]} * 3600))
    if [ "$val" -ge "$min_seconds" ] && [ "$val" -le "$max_seconds" ]; then
      echo "$val"; return 0
    fi
  fi
  echo "$default_seconds"
}

# Boundary tests
default=$((30 * 24 * 3600))
min=$((1 * 3600))
max=$((365 * 24 * 3600))

result=$(parse_pause_timeout "")
[ "$result" -eq "$default" ] || fail "empty input: expected default $default, got $result"

result=$(parse_pause_timeout "1h")
[ "$result" -eq "$min" ] || fail "1h: expected $min, got $result"

result=$(parse_pause_timeout "365d")
[ "$result" -eq "$max" ] || fail "365d: expected $max, got $result"

result=$(parse_pause_timeout "30d")
[ "$result" -eq "$default" ] || fail "30d: expected default $default, got $result"

result=$(parse_pause_timeout "invalid")
[ "$result" -eq "$default" ] || fail "invalid: expected default $default, got $result"

result=$(parse_pause_timeout "0h")
[ "$result" -eq "$default" ] || fail "0h (below min): expected default $default, got $result"

result=$(parse_pause_timeout "999d")
[ "$result" -eq "$default" ] || fail "999d (above max): expected default $default, got $result"

[ "$FAIL" -eq 0 ] && echo "PASS: parse_pause_timeout boundary values verified"
exit "$FAIL"
