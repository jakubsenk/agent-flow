#!/usr/bin/env bash
# Test: implement-feature SKILL.md has code-analyst step 3a before architect step 4
# AC-16 through AC-25 (v6.7.1 — Item 4)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL="$REPO_ROOT/skills/implement-feature/SKILL.md"

if [ ! -f "$SKILL" ]; then
  fail "skills/implement-feature/SKILL.md does not exist"
  exit "$FAIL"
fi

# AC-16: Step 3a heading exists
if ! grep -q '### 3a\. Code-analyst' "$SKILL"; then
  fail "skills/implement-feature/SKILL.md missing heading: '### 3a. Code-analyst'"
fi

# AC-17: Step 3a dispatches ceos-agents:code-analyst via Task tool
if ! grep -A 10 '### 3a' "$SKILL" | grep -q 'ceos-agents:code-analyst'; then
  fail "skills/implement-feature/SKILL.md Step 3a does not dispatch 'ceos-agents:code-analyst'"
fi

# AC-18: Step 3a is unconditional — only Pipeline Profiles can skip it, not keyword heuristics
if ! grep -A 3 '### 3a' "$SKILL" | grep -q 'Skip stages'; then
  fail "skills/implement-feature/SKILL.md Step 3a missing Pipeline Profiles skip guard"
fi
if grep -A 20 '### 3a' "$SKILL" | grep -qiE 'keyword|heuristic|if.*modification|if.*refactor'; then
  fail "skills/implement-feature/SKILL.md Step 3a has keyword/heuristic gate (should be unconditional)"
fi

# AC-19: Step 3a includes non-fatal blocking behavior
if ! grep -A 20 '### 3a' "$SKILL" | grep -q 'Code-analyst blocked.*continuing without impact analysis'; then
  fail "skills/implement-feature/SKILL.md Step 3a missing non-fatal block text: 'Code-analyst blocked.*continuing without impact analysis'"
fi

# AC-20: Stage map entry updated from N/A to step 3a
if ! grep 'code-analyst.*=.*step 3a' "$SKILL" | grep -qv 'N/A'; then
  fail "skills/implement-feature/SKILL.md stage map: code-analyst entry not updated to 'step 3a' (still N/A)"
fi

# AC-21: Old N/A entry for code-analyst is gone
if grep -q 'code-analyst.*N/A.*feature pipeline does not have code-analyst' "$SKILL"; then
  fail "skills/implement-feature/SKILL.md still contains old N/A entry for code-analyst"
fi

# AC-22: Architect context includes code-analyst impact report
if ! grep -A 5 '### 4\. Architect' "$SKILL" | grep -q 'code-analyst impact report'; then
  fail "skills/implement-feature/SKILL.md Step 4 (Architect) context missing 'code-analyst impact report'"
fi

# AC-23: Step 3a context includes Mode: feature and Pipeline: implement-feature on same line
if ! grep -A 10 '### 3a' "$SKILL" | grep 'Mode: feature' | grep -q 'Pipeline: implement-feature'; then
  fail "skills/implement-feature/SKILL.md Step 3a context missing 'Mode: feature' and 'Pipeline: implement-feature' together"
fi

# AC-24: Step 3a includes state.json update with code_analysis.status
if ! grep -A 20 '### 3a' "$SKILL" | grep -q 'code_analysis.status'; then
  fail "skills/implement-feature/SKILL.md Step 3a missing state.json update for 'code_analysis.status'"
fi

# AC-25: Step 3a appears between Step 3 (Spec-analyst) and Step 4 (Architect) in file order
spec_line=$(grep -n '### 3\. Spec-analyst' "$SKILL" | head -1 | cut -d: -f1)
ca_line=$(grep -n '### 3a\. Code-analyst' "$SKILL" | head -1 | cut -d: -f1)
arch_line=$(grep -n '### 4\. Architect' "$SKILL" | head -1 | cut -d: -f1)

if [ -z "$spec_line" ] || [ -z "$ca_line" ] || [ -z "$arch_line" ]; then
  fail "skills/implement-feature/SKILL.md: Could not find all step markers (Step 3 Spec-analyst, Step 3a Code-analyst, Step 4 Architect)"
else
  if [ "$ca_line" -le "$spec_line" ]; then
    fail "skills/implement-feature/SKILL.md: Step 3a (line $ca_line) must appear after Step 3 Spec-analyst (line $spec_line)"
  fi
  if [ "$ca_line" -ge "$arch_line" ]; then
    fail "skills/implement-feature/SKILL.md: Step 3a (line $ca_line) must appear before Step 4 Architect (line $arch_line)"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: implement-feature SKILL.md has unconditional code-analyst step 3a before architect, with correct context and state writes (AC-16 to AC-25)"
exit "$FAIL"
