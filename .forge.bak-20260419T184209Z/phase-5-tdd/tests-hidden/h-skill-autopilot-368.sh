#!/usr/bin/env bash
# Hidden test: AC-ITEM-4.1a, AC-ITEM-4.1b
# Verifies skills/autopilot/SKILL.md line ~368 troubleshooting entry:
#   - Contains corrected "effective stale threshold" phrasing (AC-ITEM-4.1a)
#   - Names 125 min primary path + 121 min BusyBox fallback (AC-ITEM-4.1a)
#   - Does NOT contain the original '<120min old' phrase (AC-ITEM-4.1b)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
AUTOPILOT_SKILL="$REPO_ROOT/skills/autopilot/SKILL.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

echo "--- h-skill-autopilot-368 (AC-ITEM-4.1a, 4.1b): lock-timeout phrasing alignment ---"

if [ ! -f "$AUTOPILOT_SKILL" ]; then
  echo "FAIL: skills/autopilot/SKILL.md not found at $AUTOPILOT_SKILL"
  exit 1
fi

# -----------------------------------------------------------------------
# AC-ITEM-4.1a: Corrected phrasing present (3 required patterns)
# -----------------------------------------------------------------------
echo "--- AC-ITEM-4.1a: 'effective stale threshold' present ---"
if grep -qE 'effective stale threshold' "$AUTOPILOT_SKILL"; then
  echo "OK (AC-ITEM-4.1a): 'effective stale threshold' present in skills/autopilot/SKILL.md"
else
  fail "AC-ITEM-4.1a: 'effective stale threshold' missing from skills/autopilot/SKILL.md:368 troubleshooting entry"
fi

echo "--- AC-ITEM-4.1a: '125 min' primary path reference present ---"
if grep -qE '125 min.*primary path|primary path.*125' "$AUTOPILOT_SKILL"; then
  echo "OK (AC-ITEM-4.1a): 125 min primary path reference present"
else
  fail "AC-ITEM-4.1a: '125 min ... primary path' or 'primary path ... 125' missing from skills/autopilot/SKILL.md"
fi

echo "--- AC-ITEM-4.1a: '121 min' BusyBox fallback reference present ---"
if grep -qE '121 min.*BusyBox|BusyBox.*121' "$AUTOPILOT_SKILL"; then
  echo "OK (AC-ITEM-4.1a): 121 min BusyBox fallback reference present"
else
  fail "AC-ITEM-4.1a: '121 min ... BusyBox' or 'BusyBox ... 121' missing from skills/autopilot/SKILL.md"
fi

# -----------------------------------------------------------------------
# AC-ITEM-4.1b: Original incorrect phrase '<120min old' is absent
# -----------------------------------------------------------------------
echo "--- AC-ITEM-4.1b: '<120min old' phrase is absent ---"
if grep -qF '<120min old' "$AUTOPILOT_SKILL"; then
  fail "AC-ITEM-4.1b: skills/autopilot/SKILL.md still contains '<120min old' phrase — must be replaced with effective stale threshold reference"
else
  echo "OK (AC-ITEM-4.1b): '<120min old' phrase is absent from skills/autopilot/SKILL.md"
fi

# -----------------------------------------------------------------------
# Cross-check: confirm the troubleshooting entry still contains the
#   lock/owner.json reference (structural regression guard — we didn't
#   accidentally delete the whole troubleshooting entry)
# -----------------------------------------------------------------------
echo "--- Structural regression: troubleshooting entry still present ---"
if grep -qF 'autopilot.lock/owner.json' "$AUTOPILOT_SKILL"; then
  echo "OK: troubleshooting entry (references autopilot.lock/owner.json) still present in SKILL.md"
else
  fail "Structural regression: autopilot.lock/owner.json reference missing — troubleshooting entry may have been accidentally removed"
fi

# -----------------------------------------------------------------------
# Cross-check: docs/guides/autopilot.md already has the correct phrasing
#   (should remain unchanged — regression guard)
# -----------------------------------------------------------------------
GUIDE="$REPO_ROOT/docs/guides/autopilot.md"
if [ -f "$GUIDE" ]; then
  echo "--- Regression guard: docs/guides/autopilot.md still has correct phrasing ---"
  if grep -qE '120 minutes.*5.minute.*NFS|5.minute.*NFS.*120 minutes' "$GUIDE"; then
    echo "OK: docs/guides/autopilot.md:350 already-correct phrasing unchanged"
  else
    fail "Regression: docs/guides/autopilot.md lost its '120 minutes plus a 5-minute NFS/CIFS' phrasing"
  fi
fi

# -----------------------------------------------------------------------
# Final result
# -----------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: h-skill-autopilot-368 — effective stale threshold phrasing correct; '<120min old' absent; 125+121 named"
fi
exit "$FAIL"
