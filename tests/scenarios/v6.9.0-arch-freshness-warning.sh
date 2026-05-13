#!/usr/bin/env bash
# Scenario: REQ-056, REQ-057, REQ-058, REQ-059 — architecture.md freshness warning (soft, non-blocking)
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — freshness check not yet inserted in skills
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

ARCH_FRESHNESS_SNIPPET="$REPO_ROOT/core/snippets/architecture-freshness.md"
FIX_TICKET="$REPO_ROOT/skills/fix-bugs/SKILL.md"
IMPLEMENT_FEATURE="$REPO_ROOT/skills/implement-feature/SKILL.md"

for f in "$FIX_TICKET" "$IMPLEMENT_FEATURE"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: required skill not found: $f" >&2; exit 1
  fi
done

# Assertion 1 (AC-056): freshness check canonical snippet exists
echo "--- Assertion 1 (AC-056): core/snippets/architecture-freshness.md exists ---"
if [ -f "$ARCH_FRESHNESS_SNIPPET" ]; then
  echo "OK (AC-056): core/snippets/architecture-freshness.md exists"
else
  fail "AC-056: core/snippets/architecture-freshness.md does not exist — freshness check snippet required"
fi

# Assertion 2 (AC-056): freshness check referenced in fix-bugs SKILL.md (citation or inline)
echo "--- Assertion 2 (AC-056): freshness check in skills/fix-bugs/SKILL.md ---"
FIX_TICKET_OK=0
if grep -qF 'docs/architecture.md has not been updated' "$FIX_TICKET" 2>/dev/null; then
  echo "OK: freshness warning prose in fix-bugs/SKILL.md"
  FIX_TICKET_OK=1
elif [ -f "$ARCH_FRESHNESS_SNIPPET" ] && grep -qF '@snippet:architecture-freshness' "$FIX_TICKET" 2>/dev/null; then
  echo "OK: architecture-freshness snippet cited in fix-bugs/SKILL.md"
  FIX_TICKET_OK=1
fi
if [ "$FIX_TICKET_OK" -eq 0 ]; then
  fail "AC-056: skills/fix-bugs/SKILL.md missing freshness check (neither warning prose nor @snippet:architecture-freshness citation)"
fi

# Assertion 3 (AC-056): freshness check referenced in implement-feature SKILL.md
echo "--- Assertion 3 (AC-056): freshness check in skills/implement-feature/SKILL.md ---"
IMPL_FEAT_OK=0
if grep -qF 'docs/architecture.md has not been updated' "$IMPLEMENT_FEATURE" 2>/dev/null; then
  echo "OK: freshness warning prose in implement-feature/SKILL.md"
  IMPL_FEAT_OK=1
elif [ -f "$ARCH_FRESHNESS_SNIPPET" ] && grep -qF '@snippet:architecture-freshness' "$IMPLEMENT_FEATURE" 2>/dev/null; then
  echo "OK: architecture-freshness snippet cited in implement-feature/SKILL.md"
  IMPL_FEAT_OK=1
fi
if [ "$IMPL_FEAT_OK" -eq 0 ]; then
  fail "AC-056: skills/implement-feature/SKILL.md missing freshness check"
fi

# Assertion 4 (AC-056): threshold N=25 in canonical snippet
echo "--- Assertion 4 (AC-056): threshold 25 in architecture-freshness snippet ---"
if [ -f "$ARCH_FRESHNESS_SNIPPET" ]; then
  if grep -qF 'threshold: 25' "$ARCH_FRESHNESS_SNIPPET" || grep -qE 'commits.*>.*25|25.*commits|threshold.*25' "$ARCH_FRESHNESS_SNIPPET"; then
    echo "OK (AC-056): threshold N=25 in architecture-freshness snippet"
  else
    fail "AC-056: core/snippets/architecture-freshness.md missing threshold N=25"
  fi
fi

# Assertion 5 (AC-057): lowercase docs/architecture.md path
echo "--- Assertion 5 (AC-057): lowercase path 'docs/architecture.md' used ---"
if [ -f "$ARCH_FRESHNESS_SNIPPET" ]; then
  if grep -qE 'docs/architecture\.md' "$ARCH_FRESHNESS_SNIPPET"; then
    echo "OK (AC-057): lowercase 'docs/architecture.md' path used"
  else
    fail "AC-057: core/snippets/architecture-freshness.md does not use lowercase 'docs/architecture.md'"
  fi
  if grep -qF 'docs/ARCHITECTURE.md' "$ARCH_FRESHNESS_SNIPPET"; then
    fail "AC-057: uppercase 'docs/ARCHITECTURE.md' found — must use lowercase path only"
  else
    echo "OK (AC-057): no uppercase ARCHITECTURE.md path in snippet"
  fi
fi

# Assertion 6 (AC-057): 2>/dev/null error redirect on git invocations
echo "--- Assertion 6 (AC-057): 2>/dev/null on git invocations ---"
if [ -f "$ARCH_FRESHNESS_SNIPPET" ]; then
  redir_count=$(grep -c '2>/dev/null' "$ARCH_FRESHNESS_SNIPPET" 2>/dev/null || true)
  if [ "$redir_count" -ge 2 ]; then
    echo "OK (AC-057): $redir_count x 2>/dev/null error redirects on git invocations"
  else
    fail "AC-057: only $redir_count 2>/dev/null redirect(s) — need >=2 (one per git invocation)"
  fi
fi

# Assertion 7 (AC-058): fallback INFO log when file untracked
echo "--- Assertion 7 (AC-058): fallback [INFO] log when file untracked ---"
if [ -f "$ARCH_FRESHNESS_SNIPPET" ]; then
  if grep -qF '[INFO] docs/architecture.md not tracked or absent' "$ARCH_FRESHNESS_SNIPPET"; then
    echo "OK (AC-058): fallback INFO log present for untracked/absent case"
  else
    fail "AC-058: core/snippets/architecture-freshness.md missing '[INFO] docs/architecture.md not tracked or absent' fallback"
  fi
fi

# Assertion 8 (AC-059 NEGATIVE): freshness check is non-blocking (exit 0)
echo "--- Assertion 8 (AC-059): freshness check is non-blocking ---"
if [ -f "$ARCH_FRESHNESS_SNIPPET" ]; then
  if grep -qE 'exit 1|abort|block|BLOCK' "$ARCH_FRESHNESS_SNIPPET"; then
    # Check if the exit 1 or block is in a non-freshness-check context
    exit1_count=$(grep -cE 'exit 1|BLOCK the pipeline' "$ARCH_FRESHNESS_SNIPPET" 2>/dev/null || true)
    if [ "$exit1_count" -gt 0 ]; then
      fail "AC-059: core/snippets/architecture-freshness.md contains 'exit 1' or 'BLOCK' — freshness check must be non-blocking"
    fi
  else
    echo "OK (AC-059): no exit 1 / BLOCK in freshness check (non-blocking confirmed)"
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 architecture freshness check in both skills; lowercase path; 2>/dev/null; fallback INFO; non-blocking"
fi
exit "$FAIL"
