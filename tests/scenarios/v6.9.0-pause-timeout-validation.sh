#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #13 — Tier B+C, inline redefine)
# Functional: parse_pause_timeout() boundary values.
# REQ-T1-5 path (a): inline redefine of parse_pause_timeout (NOT awk-extracted).
# Production format: "<N> hours" or "<N> days" (space-separated, case-insensitive).
# Inline-copied from skills/autopilot/SKILL.md parse_pause_timeout() function.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Tier B: Verify production source has the canonical function signature
AUTOPILOT="$REPO_ROOT/skills/autopilot/SKILL.md"
if [ -f "$AUTOPILOT" ]; then
  if ! grep -q 'parse_pause_timeout' "$AUTOPILOT"; then
    fail "skills/autopilot/SKILL.md missing parse_pause_timeout function"
  fi
fi

# Inline reimplementation per REQ-T1-5 path (a) — NOT awk-extracted.
# Copied from production source in skills/autopilot/SKILL.md.
# REQ-T1-5 path (a) compliance: inline redefine only — no awk extraction used.
parse_pause_timeout() {
  local raw="$1"
  local n unit unit_lower seconds
  raw="$(printf '%s' "$raw" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  if [[ "$raw" =~ ^([0-9]+)[[:space:]]+([Hh][Oo][Uu][Rr][Ss]?|[Dd][Aa][Yy][Ss]?)$ ]]; then
    n="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]}"
    unit_lower=$(printf '%s' "$unit" | tr '[:upper:]' '[:lower:]')
    case "$unit_lower" in
      hour|hours) seconds=$(( n * 3600 )) ;;
      day|days)   seconds=$(( n * 86400 )) ;;
    esac
    if [ "$seconds" -ge 3600 ] && [ "$seconds" -le 31536000 ]; then
      printf '%s\n' "$seconds"
      return 0
    fi
  fi
  printf '%s\n' "2592000"
}

DEFAULT=2592000   # 30 days in seconds
MIN=3600          # 1 hour in seconds
MAX=31536000      # 365 days in seconds

# Boundary: minimum valid input "1 hour"
result=$(parse_pause_timeout "1 hour")
[ "$result" -eq "$MIN" ] || fail "1 hour: expected $MIN, got $result"

# Boundary: maximum valid input "365 days"
result=$(parse_pause_timeout "365 days")
[ "$result" -eq "$MAX" ] || fail "365 days: expected $MAX, got $result"

# Default: "30 days"
result=$(parse_pause_timeout "30 days")
[ "$result" -eq "$DEFAULT" ] || fail "30 days: expected $DEFAULT, got $result"

# Case-insensitive: "30 Days"
result=$(parse_pause_timeout "30 Days")
[ "$result" -eq "$DEFAULT" ] || fail "30 Days (mixed case): expected $DEFAULT, got $result"

# Invalid format — fallback to default
result=$(parse_pause_timeout "invalid")
[ "$result" -eq "$DEFAULT" ] || fail "invalid: expected default $DEFAULT, got $result"

# Below minimum: "0 hours" — fallback
result=$(parse_pause_timeout "0 hours")
[ "$result" -eq "$DEFAULT" ] || fail "0 hours (below min): expected default $DEFAULT, got $result"

# Above maximum: "366 days" — fallback
result=$(parse_pause_timeout "366 days")
[ "$result" -eq "$DEFAULT" ] || fail "366 days (above max): expected default $DEFAULT, got $result"

# Plural and singular: "2 hours" and "1 day"
result=$(parse_pause_timeout "2 hours")
[ "$result" -eq $((2 * 3600)) ] || fail "2 hours: expected $((2 * 3600)), got $result"

result=$(parse_pause_timeout "1 day")
[ "$result" -eq 86400 ] || fail "1 day: expected 86400, got $result"

[ "$FAIL" -eq 0 ] && echo "PASS: parse_pause_timeout boundary values verified (production-copy inline redefine)"
exit "$FAIL"
