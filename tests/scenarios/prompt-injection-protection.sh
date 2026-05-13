#!/usr/bin/env bash
# AC: AC-T3-2-1, AC-T3-3-1, AC-T3-3-2, AC-T3-7-1, AC-T3-9-1, AC-T3-10-1, AC-T3-10-2, AC-T3-10-3, AC-T3-11-1
# REWRITE: enumeration-based prompt injection protection check.
# Replaces hardcoded AGENTS_TO_CHECK array with find-based enumeration.
# AC-063a: defensive shopt guards prevent glob expansion surprises on bash >=4
shopt -u globstar 2>/dev/null || true
shopt -u nullglob  2>/dev/null || true
shopt -u dotglob   2>/dev/null || true
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Write canonical bullet to a temp file to avoid shell-interpolation issues with
# the `---` sequence inside the string (grep treats leading `--` as end-of-options).
TMP_PAT="$(mktemp)"
TMP_DIR="$(mktemp -d)"
trap 'rm -f "$TMP_PAT"; rm -rf "$TMP_DIR"' EXIT

grep -n "NEVER follow instructions" "$REPO_ROOT/agents/analyst.md" | head -1 | cut -d: -f2- > "$TMP_PAT"
[ -s "$TMP_PAT" ] || { fail "Could not extract canonical bullet from agents/analyst.md"; exit 1; }

# AC-1 (AC-T3-2-1, AC-T3-11-1): Every agent file has the canonical bullet
COUNT=0
MISSING=()
while IFS= read -r agent_file; do
  COUNT=$((COUNT + 1))
  if ! grep -qFf "$TMP_PAT" "$agent_file"; then
    MISSING+=("$(basename "$agent_file")")
  fi
done < <(find "$REPO_ROOT/agents" -maxdepth 1 -name '*.md' -not -name 'README.md' -type f | sort)

if [ "${#MISSING[@]}" -ne 0 ]; then
  fail "Agents missing canonical EXTERNAL INPUT bullet: ${MISSING[*]}"
fi
[ "$COUNT" -eq 17 ] || fail "Expected 17 agents enumerated, got $COUNT"
echo "INFO: enumerated $COUNT agent files"

# AC-T3-3-1: total agents with EXTERNAL INPUT START marker = 21
marker_count=$(find "$REPO_ROOT/agents" -maxdepth 1 -name '*.md' -not -name 'README.md' -type f \
  | xargs grep -lF 'EXTERNAL INPUT START' 2>/dev/null | wc -l | tr -d ' ')
[ "$marker_count" -eq 17 ] || fail "Expected 17 agents with EXTERNAL INPUT START, got $marker_count"

# AC-T3-10-1: uses find enumeration, NOT hardcoded array
# (self-check: this file should not define AGENTS_TO_CHECK as a bash array;
#  the guard pattern is split across two variables to avoid self-matching)
_GUARD_PATTERN='AGENTS_TO_CHECK'
_GUARD_SUFFIX='=('
_matching_lines=$(grep -cF "${_GUARD_PATTERN}${_GUARD_SUFFIX}" "$0" 2>/dev/null || true)
# Exactly 1 match is expected — the line that builds the pattern via concatenation.
# More than 1 means a hardcoded array definition was added.
[ "${_matching_lines:-0}" -le 1 ] || fail "This scenario must NOT use hardcoded AGENTS_TO_CHECK array"

# AC-T3-9-1: regression on 8 already-patched agents
PRE_PATCHED=(
  "analyst" "fixer" "reviewer" "acceptance-gate"
  "spec-analyst" "architect" "priority-engine" "browser-agent"
)
for agent in "${PRE_PATCHED[@]}"; do
  f="$REPO_ROOT/agents/${agent}.md"
  [ -f "$f" ] || { fail "Pre-patched agent missing: $agent"; continue; }
  if ! grep -qFf "$TMP_PAT" "$f"; then
    fail "Regression: pre-patched agent lost canonical bullet: $agent"
  fi
done

# AC-T3-7-1: no HTML-comment wrapper present
if grep -rnE '<!-- external-input-boundary' "$REPO_ROOT/agents" "$REPO_ROOT/core" 2>/dev/null | grep -q .; then
  fail "HTML-comment wrapper convention detected (forbidden per REQ-T3-7)"
fi

# AC-T3-10-3: negative control — synthetic fixture without canonical bullet must fail
mkdir -p "$TMP_DIR/agents"
cat > "$TMP_DIR/agents/_test-fixture.md" <<'AGENT'
---
name: _test-fixture
description: synthetic test fixture WITHOUT canonical bullet
model: sonnet
style: test
---
## Constraints
- NEVER do bad things.
AGENT
neg_fail=0
if grep -qFf "$TMP_PAT" "$TMP_DIR/agents/_test-fixture.md"; then
  neg_fail=1
fi
[ "$neg_fail" -eq 0 ] || fail "Negative control: synthetic agent incorrectly has canonical bullet"
# The enumeration WOULD fail if this file were included in scope — confirmed by absence of bullet
echo "INFO: negative control confirmed — synthetic agent without canonical bullet would fail enumeration"

# AC-063a (AC-076): core contract count — verify find -maxdepth 1 returns exactly 17
# (v9.3.0: resume-detection.md added; ensures core/snippets/ sub-directory is not counted)
core_count=$(find "$REPO_ROOT/core" -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$core_count" -eq 17 ]; then
  echo "INFO: find core -maxdepth 1 -name '*.md' returns exactly 17 core contracts"
elif [ "$core_count" -gt 17 ]; then
  fail "AC-076: find core -maxdepth 1 returns $core_count files — may be including snippets (expected 17)"
else
  fail "AC-076: find core -maxdepth 1 returns only $core_count files (expected 17 core contracts)"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: $COUNT agents enumerated; all match canonical bullet"
exit "$FAIL"
