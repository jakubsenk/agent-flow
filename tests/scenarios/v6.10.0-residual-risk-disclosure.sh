#!/usr/bin/env bash
# AC: AC-T3-12-1, AC-T3-12-2
# Asserts residual risk T3-ADV-1/2/3 disclosed in core/agent-states.md
# and roadmap.md v6.11.0 section.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

AGENT_STATES="$REPO_ROOT/core/agent-states.md"
ROADMAP="$REPO_ROOT/docs/plans/roadmap.md"

[ -f "$AGENT_STATES" ] || { fail "core/agent-states.md not found"; exit 1; }
[ -f "$ROADMAP" ] || { fail "docs/plans/roadmap.md not found"; exit 1; }

# AC-T3-12-1: core/agent-states.md has deferred subsection
if ! grep -qiE 'Tracker content normalization.*deferred|deferred.*tracker content normalization' "$AGENT_STATES"; then
  fail "core/agent-states.md missing 'Tracker content normalization — deferred' subsection"
fi
# All 3 adversarial IDs present
for adv in 'T3-ADV-1' 'T3-ADV-2' 'T3-ADV-3'; do
  if ! grep -qF "$adv" "$AGENT_STATES"; then
    fail "core/agent-states.md missing adversarial ID: $adv"
  fi
done
# "NOT CLOSED" disclosure present
if ! grep -qiE 'NOT CLOSED|not closed' "$AGENT_STATES"; then
  fail "core/agent-states.md missing NOT CLOSED disclosure"
fi

# AC-T3-12-2: roadmap.md v6.11.0 section has "Prompt-injection defense-in-depth" item
v6110_section=$(awk '/6\.11\.0/,/6\.12\.0/' "$ROADMAP" 2>/dev/null | head -60)
if ! echo "$v6110_section" | grep -qiE 'Prompt.injection defense.in.depth'; then
  fail "roadmap.md v6.11.0 missing 'Prompt-injection defense-in-depth' item"
fi
for adv in 'T3-ADV-1' 'T3-ADV-2' 'T3-ADV-3'; do
  if ! echo "$v6110_section" | grep -qF "$adv"; then
    fail "roadmap.md v6.11.0 'Prompt-injection defense-in-depth' missing adversarial ID: $adv"
  fi
done

echo "PASS: residual risk T3-ADV-1/2/3 disclosure verified"
exit "$FAIL"
