#!/usr/bin/env bash
# AC: AC-T2-9-1, AC-T2-9-2, AC-T2-10-2
# Asserts autopilot-hook-interaction research artifact is present,
# and T2-ADV-3 disclosure is unconditional in dispatch-enforcement.md + roadmap.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# AC-T2-9-1: research artifact exists and records resolution
RESEARCH="$REPO_ROOT/.forge/phase-4-spec/research/autopilot-hook-interaction.md"
[ -f "$RESEARCH" ] || { fail "autopilot-hook-interaction.md research artifact missing"; exit 1; }
if ! grep -qiE 'hooks fire|hooks suppressed|indeterminate' "$RESEARCH"; then
  fail "autopilot-hook-interaction.md missing resolution statement"
fi

# AC-T2-9-2: if hooks suppressed, guide must contain "Autopilot dispatch audit parity"
# Since research resolved "hooks fire", this is vacuous — but we check guide anyway
GUIDE="$REPO_ROOT/docs/guides/dispatch-enforcement.md"
[ -f "$GUIDE" ] || { fail "docs/guides/dispatch-enforcement.md missing"; exit 1; }

# AC-T2-10-2: T2-ADV-3 disclosure is UNCONDITIONAL
# dispatch-enforcement.md must have Known limitation section
if ! grep -qiE '^## Known limitation.*autopilot subprocess dispatch audit gap' "$GUIDE"; then
  fail "dispatch-enforcement.md missing '## Known limitation...Autopilot subprocess dispatch audit gap' section"
fi
for phrase in '--dangerously-skip-permissions' 'v6.10.1' 'Autopilot dispatch audit parity'; do
  if ! grep -qF "$phrase" "$GUIDE"; then
    fail "dispatch-enforcement.md Known limitation section missing: $phrase"
  fi
done

# roadmap v6.10.1 must contain "Autopilot dispatch audit parity" item
ROADMAP="$REPO_ROOT/docs/plans/roadmap.md"
if ! grep -qF 'Autopilot dispatch audit parity' "$ROADMAP"; then
  fail "roadmap.md v6.10.1 section missing 'Autopilot dispatch audit parity' item"
fi

echo "PASS: T2-ADV-3 autopilot audit disclosure verified"
exit "$FAIL"
