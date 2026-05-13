#!/usr/bin/env bash
# Scenario: REQ-038, REQ-039 — multi-host lock deferred; deferral note in autopilot SKILL + roadmap entry
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — deferral note not yet added
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

AUTOPILOT_SKILL="$REPO_ROOT/skills/autopilot/SKILL.md"
AUTOPILOT_GUIDE="$REPO_ROOT/docs/guides/autopilot.md"
ROADMAP="$REPO_ROOT/docs/plans/roadmap.md"

for f in "$AUTOPILOT_SKILL" "$ROADMAP"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: required file not found: $f" >&2
    exit 1
  fi
done

# Assertion 1 (AC-038): deferral note in autopilot SKILL.md
echo "--- Assertion 1 (AC-038): multi-host deferral note in skills/autopilot/SKILL.md ---"
if grep -qF 'Multi-host coordination via disjoint queries is the v6.9.0-supported pattern' "$AUTOPILOT_SKILL"; then
  echo "OK (AC-038): deferral note present in skills/autopilot/SKILL.md"
else
  fail "AC-038: skills/autopilot/SKILL.md missing 'Multi-host coordination via disjoint queries is the v6.9.0-supported pattern'"
fi

# Assertion 2 (AC-038): deferred to v6.9.1 in the note
echo "--- Assertion 2 (AC-038): deferral targets v6.9.1 ---"
if grep -qE 'deferred to v6\.9\.1|distributed lock.*v6\.9\.1' "$AUTOPILOT_SKILL"; then
  echo "OK (AC-038): multi-host distributed lock explicitly deferred to v6.9.1"
else
  fail "AC-038: skills/autopilot/SKILL.md does not mention v6.9.1 as the deferred target for distributed lock"
fi

# Assertion 3 (AC-038): docs/guides/autopilot.md has Multi-Host Coordination section
echo "--- Assertion 3 (AC-038): docs/guides/autopilot.md has Multi-Host Coordination section ---"
if [ ! -f "$AUTOPILOT_GUIDE" ]; then
  fail "AC-038: docs/guides/autopilot.md not found"
else
  if grep -qE 'Multi-Host Coordination|Multi-host coordination' "$AUTOPILOT_GUIDE"; then
    echo "OK (AC-038): Multi-Host Coordination section present in docs/guides/autopilot.md"
  else
    fail "AC-038: docs/guides/autopilot.md missing 'Multi-Host Coordination' section (with 2-cron disjoint-query example)"
  fi
  if grep -qF 'operator is responsible for query disjointness' "$AUTOPILOT_GUIDE"; then
    echo "OK (AC-038): query disjointness operator warning present"
  else
    fail "AC-038: docs/guides/autopilot.md missing 'operator is responsible for query disjointness'"
  fi
fi

# Assertion 4 (AC-039): roadmap.md v6.9.1 entry for distributed lock options
echo "--- Assertion 4 (AC-039): roadmap.md v6.9.1 entry for distributed lock options ---"
if grep -qE 'flock.*NFS|external coordinator|formalized.*disjoint' "$ROADMAP"; then
  echo "OK (AC-039): roadmap.md mentions distributed lock options (flock-NFS, external coordinator, formalized-disjoint)"
else
  fail "AC-039: roadmap.md missing distributed lock options in v6.9.1 entry (expected: flock-NFS, external coordinator, formalized-disjoint)"
fi
if grep -qE 'portability test matrix' "$ROADMAP"; then
  echo "OK (AC-039): roadmap.md mentions portability test matrix requirement"
else
  fail "AC-039: roadmap.md missing 'portability test matrix' requirement in v6.9.1 distributed-lock entry"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 multi-host lock deferral documented in autopilot SKILL.md + guide + roadmap.md v6.9.1 entry"
fi
exit "$FAIL"
