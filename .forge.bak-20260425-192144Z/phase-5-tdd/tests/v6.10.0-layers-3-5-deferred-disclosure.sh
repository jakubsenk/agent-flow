#!/usr/bin/env bash
# AC: AC-T2-10-1
# Asserts Layer 3 and Layer 5 are labeled deferred/not-in-scope
# in spec files and roadmap.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

ROADMAP="$REPO_ROOT/docs/plans/roadmap.md"
[ -f "$ROADMAP" ] || { fail "docs/plans/roadmap.md not found"; exit 1; }

# AC-T2-10-1: Layer 3 and Layer 5 labeled deferred or not-in-scope
# Check roadmap and spec directory
search_targets=("$ROADMAP")
spec_dir="$REPO_ROOT/.forge/phase-4-spec/final/"
if [ -d "$spec_dir" ]; then
  while IFS= read -r f; do
    search_targets+=("$f")
  done < <(find "$spec_dir" -name '*.md' -type f)
fi

layer3_deferred=0
layer5_deferred=0
for f in "${search_targets[@]}"; do
  [ -f "$f" ] || continue
  if grep -qiE 'Layer 3.*defer|Layer 3.*not.in.scope|deferred.*Layer 3|not-in-scope.*Layer 3' "$f"; then
    layer3_deferred=1
  fi
  if grep -qiE 'Layer 5.*defer|Layer 5.*not.in.scope|deferred.*Layer 5|not-in-scope.*Layer 5' "$f"; then
    layer5_deferred=1
  fi
done
[ "$layer3_deferred" -eq 1 ] || fail "Layer 3 not labeled as deferred/not-in-scope in roadmap or spec"
[ "$layer5_deferred" -eq 1 ] || fail "Layer 5 not labeled as deferred/not-in-scope in roadmap or spec"

# Verify no Layer 3 or Layer 5 CONTENT shipped in the implementation area
for pattern in 'Layer 3' 'Layer 5'; do
  if grep -rnlE "$pattern" \
    "$REPO_ROOT/skills/" "$REPO_ROOT/hooks/" "$REPO_ROOT/agents/" \
    "$REPO_ROOT/core/" 2>/dev/null | grep -v '.forge' | grep -qE '.'; then
    # Found references — check they are not implementation content
    hits=$(grep -rnE "$pattern" "$REPO_ROOT/skills/" "$REPO_ROOT/hooks/" "$REPO_ROOT/agents/" \
      "$REPO_ROOT/core/" 2>/dev/null | grep -v 'defer\|deferred\|not.in.scope\|future\|roadmap' | wc -l)
    [ "${hits:-0}" -eq 0 ] || fail "$pattern content appears to be shipped (not just deferred-label)"
  fi
done

echo "PASS: Layer 3 and Layer 5 deferred disclosure verified"
exit "$FAIL"
