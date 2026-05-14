#!/usr/bin/env bash
# Scenario: hostname neutralization in user-facing files
# Expected outcome: PASS — all internal hostnames neutralized in user-facing files
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

INSTALLATION="$REPO_ROOT/docs/guides/installation.md"
PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
MOCK_CLAUDE="$REPO_ROOT/tests/mock-project/CLAUDE.md"
ONBOARD_SKILL="$REPO_ROOT/skills/onboard/SKILL.md"
ROADMAP="$REPO_ROOT/docs/roadmap.md"

# Assertion 1 (NEGATIVE): no internal hostname in any user-facing file
# Note: plugin.json intentionally contains the internal URL — see Item 8
echo "--- Assertion 1 (NEGATIVE): no github.com/asysta-act/agent-flow in user-facing files ---"
for f in "$INSTALLATION" "$MOCK_CLAUDE" "$ONBOARD_SKILL"; do
  if [ ! -f "$f" ]; then
    fail "file does not exist: $f"
    continue
  fi
  if grep -qE 'github\.com/asysta-act/agent-flow' "$f"; then
    fail "internal hostname 'github.com/asysta-act/agent-flow' found in $f (must be replaced with placeholder)"
  else
    echo "OK: no internal hostname in $f"
  fi
done

# Assertion 2: installation.md uses <your-git-host> placeholder (>=5 occurrences)
echo "--- Assertion 2: installation.md has >=5 <your-git-host> placeholders ---"
if [ -f "$INSTALLATION" ]; then
  count=$(grep -c '<your-git-host>' "$INSTALLATION" 2>/dev/null || true)
  if [ "$count" -ge 5 ]; then
    echo "OK: installation.md has $count '<your-git-host>' placeholders (>=5 required)"
  else
    fail "installation.md has only $count '<your-git-host>' placeholder(s) — need >=5"
  fi
  if grep -qF '<owner>/<repo>' "$INSTALLATION"; then
    echo "OK: installation.md has '<owner>/<repo>' placeholder"
  else
    fail "installation.md missing '<owner>/<repo>' placeholder"
  fi
fi

# Assertion 3: onboard SKILL.md uses <your-gitea-host>/org/repo placeholder
echo "--- Assertion 3: onboard SKILL.md placeholder neutralized ---"
if [ -f "$ONBOARD_SKILL" ]; then
  if grep -qF '<your-gitea-host>/org/repo' "$ONBOARD_SKILL"; then
    echo "OK: skills/onboard/SKILL.md uses '<your-gitea-host>/org/repo' placeholder"
  else
    fail "skills/onboard/SKILL.md missing '<your-gitea-host>/org/repo' placeholder"
  fi
fi

# Assertion 4: mock-project CLAUDE.md uses <your-gitea-host>/test/mock-project
echo "--- Assertion 4: tests/mock-project/CLAUDE.md placeholder neutralized ---"
if [ -f "$MOCK_CLAUDE" ]; then
  if grep -qF '<your-gitea-host>/test/mock-project' "$MOCK_CLAUDE"; then
    echo "OK: tests/mock-project/CLAUDE.md uses '<your-gitea-host>/test/mock-project' placeholder"
  else
    fail "tests/mock-project/CLAUDE.md missing '<your-gitea-host>/test/mock-project' placeholder"
  fi
fi

# Assertion 5: roadmap.md entry for canonical URL replacement
echo "--- Assertion 5: roadmap.md entry for example.invalid placeholder ---"
if [ -f "$ROADMAP" ]; then
  if grep -qF 'Replace https://example.invalid/agent-flow.git placeholder' "$ROADMAP"; then
    echo "OK: roadmap.md has canonical URL replacement entry"
  elif grep -qF 'example.invalid' "$ROADMAP"; then
    echo "OK: roadmap.md mentions example.invalid"
  else
    fail "roadmap.md missing 'Replace https://example.invalid/agent-flow.git placeholder' entry"
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: all internal hostnames neutralized + placeholder tokens in user-facing files"
fi
exit "$FAIL"
