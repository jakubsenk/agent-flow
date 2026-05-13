#!/usr/bin/env bash
# Scenario: REQ-010, REQ-011, REQ-012, REQ-013, REQ-014 — hostname neutralization in user-facing files
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — gitea.internal.ceosdata.com still present in multiple files
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

INSTALLATION="$REPO_ROOT/docs/guides/installation.md"
PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
MOCK_CLAUDE="$REPO_ROOT/tests/mock-project/CLAUDE.md"
ONBOARD_SKILL="$REPO_ROOT/skills/onboard/SKILL.md"
ROADMAP="$REPO_ROOT/docs/plans/roadmap.md"

# Assertion 1 (AC-011 NEGATIVE): no internal hostname in any user-facing file
# v9.0.1: plugin.json intentionally contains the internal URL — see Item 8
echo "--- Assertion 1 (AC-011 NEGATIVE): no gitea.internal.ceosdata.com in user-facing files ---"
for f in "$INSTALLATION" "$MOCK_CLAUDE" "$ONBOARD_SKILL"; do
  if [ ! -f "$f" ]; then
    fail "AC-011: file does not exist: $f"
    continue
  fi
  if grep -qE 'gitea\.internal\.ceosdata\.com' "$f"; then
    fail "AC-011: internal hostname 'gitea.internal.ceosdata.com' found in $f (must be replaced with placeholder)"
  else
    echo "OK (AC-011): no internal hostname in $f"
  fi
done

# Assertion 2 (AC-012): installation.md uses <your-git-host> placeholder (>=5 occurrences)
echo "--- Assertion 2 (AC-012): installation.md has >=5 <your-git-host> placeholders ---"
if [ -f "$INSTALLATION" ]; then
  count=$(grep -c '<your-git-host>' "$INSTALLATION" 2>/dev/null || true)
  if [ "$count" -ge 5 ]; then
    echo "OK (AC-012): installation.md has $count '<your-git-host>' placeholders (>=5 required)"
  else
    fail "AC-012: installation.md has only $count '<your-git-host>' placeholder(s) — need >=5 (5 sites enumerated in REQ-012)"
  fi
  if grep -qF '<owner>/<repo>' "$INSTALLATION"; then
    echo "OK (AC-012): installation.md has '<owner>/<repo>' placeholder"
  else
    fail "AC-012: installation.md missing '<owner>/<repo>' placeholder"
  fi
fi

# Assertion 3 (AC-013): onboard SKILL.md uses <your-gitea-host>/org/repo placeholder
echo "--- Assertion 3 (AC-013): onboard SKILL.md placeholder neutralized ---"
if [ -f "$ONBOARD_SKILL" ]; then
  if grep -qF '<your-gitea-host>/org/repo' "$ONBOARD_SKILL"; then
    echo "OK (AC-013): skills/onboard/SKILL.md uses '<your-gitea-host>/org/repo' placeholder"
  else
    fail "AC-013: skills/onboard/SKILL.md missing '<your-gitea-host>/org/repo' placeholder"
  fi
fi

# Assertion 4 (AC-013): mock-project CLAUDE.md uses <your-gitea-host>/test/mock-project
echo "--- Assertion 4 (AC-013): tests/mock-project/CLAUDE.md placeholder neutralized ---"
if [ -f "$MOCK_CLAUDE" ]; then
  if grep -qF '<your-gitea-host>/test/mock-project' "$MOCK_CLAUDE"; then
    echo "OK (AC-013): tests/mock-project/CLAUDE.md uses '<your-gitea-host>/test/mock-project' placeholder"
  else
    fail "AC-013: tests/mock-project/CLAUDE.md missing '<your-gitea-host>/test/mock-project' placeholder"
  fi
fi

# Assertion 5 (AC-014): roadmap.md v6.9.1 entry for canonical URL replacement
echo "--- Assertion 5 (AC-014): roadmap.md v6.9.1 entry for example.invalid placeholder ---"
if [ -f "$ROADMAP" ]; then
  if grep -qF 'Replace https://example.invalid/ceos-agents.git placeholder' "$ROADMAP"; then
    echo "OK (AC-014): roadmap.md has canonical URL replacement entry"
  elif grep -qF 'example.invalid' "$ROADMAP"; then
    echo "OK (AC-014): roadmap.md mentions example.invalid (acceptable per AC-014 OR clause)"
  else
    fail "AC-014: roadmap.md missing 'Replace https://example.invalid/ceos-agents.git placeholder' v6.9.1 entry"
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 all internal hostnames neutralized + placeholder tokens in user-facing files"
fi
exit "$FAIL"
