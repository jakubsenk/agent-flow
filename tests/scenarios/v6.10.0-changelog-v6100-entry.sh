#!/usr/bin/env bash
# AC: AC-T1-15-1, AC-META-3-1
# Asserts CHANGELOG.md has a v6.10.0 section with required sub-sections
# and an effort annotation for Track 1.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

[ -f "$CHANGELOG" ] || { fail "CHANGELOG.md does not exist"; exit 1; }

# AC-META-3-1: v6.10.0 heading present
if ! grep -qF '## [6.10.0]' "$CHANGELOG"; then
  fail "CHANGELOG.md missing '## [6.10.0]' section"
fi

# Extract v6.10.0 section content (between [6.10.0] heading and next ## [ heading or EOF).
# Uses a state variable instead of range pattern to avoid the awk range self-match problem
# (range /A/,/B/ closes on the same line when A and B both match the opening line).
section=$(awk 'BEGIN{in_sec=0} /^## \[6\.10\.0\]/{in_sec=1; print; next} in_sec && /^## \[/{exit} in_sec{print}' "$CHANGELOG" | head -100)

# AC-META-3-1: sub-sections for Track 1, Track 2, Track 3
for track in "Track 1" "Track 2" "Track 3"; do
  if ! echo "$section" | grep -qi "$track"; then
    fail "CHANGELOG.md v6.10.0 section missing: $track"
  fi
done

# AC-META-3-1: residual-risk disclosure present
if ! echo "$section" | grep -qiE 'residual.risk|T3-ADV'; then
  fail "CHANGELOG.md v6.10.0 section missing residual-risk disclosure"
fi

# AC-T1-15-1: effort annotation for Track 1 (e.g. "~30h", "30 person-hours")
if ! echo "$section" | grep -qiE '~[0-9]+h|[0-9]+ (person-)?hours?'; then
  fail "CHANGELOG.md v6.10.0 section missing effort annotation (e.g. '~30h')"
fi

echo "PASS: CHANGELOG.md v6.10.0 entry verified"
exit "$FAIL"
