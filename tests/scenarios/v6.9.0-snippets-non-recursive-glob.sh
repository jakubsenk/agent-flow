#!/usr/bin/env bash
# Scenario: REQ-063, REQ-063a, REQ-063b — shopt guards + find -maxdepth + 5 snippet files + citation markers
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — snippet files and shopt guards not yet added
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

PROMPT_INJ="$REPO_ROOT/tests/scenarios/prompt-injection-protection.sh"
SNIPPETS_DIR="$REPO_ROOT/core/snippets"

# Assertion 1 (AC-061): all 5 snippet files exist
echo "--- Assertion 1 (AC-061): all 5 snippet files exist under core/snippets/ ---"
snippet_files=(
  "webhook-curl.md"
  "issue-id-validation.md"
  "metrics-json-schema.md"
  "pipeline-completion.md"
  "architecture-freshness.md"
)
for snip in "${snippet_files[@]}"; do
  if [ -f "$SNIPPETS_DIR/$snip" ]; then
    echo "OK (AC-061): $SNIPPETS_DIR/$snip exists"
  else
    fail "AC-061: $SNIPPETS_DIR/$snip does not exist — required by REQ-061"
  fi
done

# Assertion 2 (AC-079): each snippet is non-empty, >= 10 lines, has H1 heading
echo "--- Assertion 2 (AC-079): each snippet is non-empty, >=10 lines, has H1 ---"
for snip in "${snippet_files[@]}"; do
  f="$SNIPPETS_DIR/$snip"
  if [ ! -f "$f" ]; then continue; fi
  if [ -s "$f" ]; then
    echo "OK: $snip is non-empty"
  else
    fail "AC-079: $snip is empty"
  fi
  line_count=$(wc -l < "$f" 2>/dev/null || echo 0)
  if [ "$line_count" -ge 10 ]; then
    echo "OK: $snip has $line_count lines (>=10)"
  else
    fail "AC-079: $snip has only $line_count lines (need >=10)"
  fi
  if grep -qE '^# ' "$f"; then
    echo "OK: $snip has H1 heading"
  else
    fail "AC-079: $snip missing H1 heading (grep '^# ')"
  fi
done

# Assertion 3 (AC-063b): each snippet file has ## Used by: heading
echo "--- Assertion 3 (AC-063b): each snippet file has '## Used by:' heading ---"
for snip in "${snippet_files[@]}"; do
  f="$SNIPPETS_DIR/$snip"
  if [ -f "$f" ]; then
    if grep -qF '## Used by:' "$f"; then
      echo "OK (AC-063b): $snip has '## Used by:' heading"
    else
      fail "AC-063b: $snip missing '## Used by:' heading (per REQ-063b — self-documents citation sites)"
    fi
  fi
done

# Assertion 4 (AC-063a): shopt guards present in prompt-injection-protection.sh
echo "--- Assertion 4 (AC-063a): shopt guards in prompt-injection-protection.sh ---"
if [ -f "$PROMPT_INJ" ]; then
  for guard in 'shopt -u globstar' 'shopt -u nullglob' 'shopt -u dotglob'; do
    if grep -qF "$guard" "$PROMPT_INJ"; then
      echo "OK (AC-063a): '$guard' present"
    else
      fail "AC-063a: prompt-injection-protection.sh missing '$guard' defensive shopt guard"
    fi
  done
else
  fail "AC-063a: tests/scenarios/prompt-injection-protection.sh not found"
fi

# Assertion 5 (AC-063a): find -maxdepth 1 used, not ls core/*.md
echo "--- Assertion 5 (AC-063a): 'find core -maxdepth 1' used instead of 'ls core/*.md' ---"
if [ -f "$PROMPT_INJ" ]; then
  if grep -qE 'find.*core.*-maxdepth 1.*-name' "$PROMPT_INJ"; then
    echo "OK (AC-063a): portable 'find core -maxdepth 1' used"
  else
    fail "AC-063a: prompt-injection-protection.sh missing 'find ... core ... -maxdepth 1 -name' (replace ls core/*.md)"
  fi
  if grep -qF 'ls core/*.md' "$PROMPT_INJ"; then
    fail "AC-063a: old fragile 'ls core/*.md' glob still present (should be replaced with find -maxdepth 1)"
  else
    echo "OK (AC-063a): 'ls core/*.md' removed from prompt-injection-protection.sh"
  fi
fi

# Assertion 6 (AC-063 NEGATIVE): top-level core glob does NOT recurse into core/snippets/
echo "--- Assertion 6 (AC-063 NEGATIVE): core/*.md glob does NOT count snippet files ---"
# Verify: find -maxdepth 1 returns exactly 17 files (v9.3.0: resume-detection.md added)
top_level_count=$(find "$REPO_ROOT/core" -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l)
if [ "$top_level_count" -eq 17 ]; then
  echo "OK (AC-063/AC-076): find core -maxdepth 1 returns exactly 17 .md files (not 21+ with snippets)"
elif [ "$top_level_count" -gt 17 ]; then
  fail "AC-063: find core -maxdepth 1 returns $top_level_count files — may be including snippets (expected exactly 17)"
else
  fail "AC-076: find core -maxdepth 1 returns only $top_level_count files (expected exactly 17 core contracts)"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 all 5 snippets exist with ## Used by:; shopt guards in prompt-injection-protection.sh; find -maxdepth 1; 17 core contracts"
fi
exit "$FAIL"
