#!/usr/bin/env bash
# Scenario: REQ-060, REQ-060a — docs/architecture.md skill-count fix + v6.9.0 substantive refresh
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — architecture.md not yet refreshed
# v9.5.0 reduced skills 22→18; this test updated 2026-05-09 to reflect post-cleanup baseline.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

ARCH="$REPO_ROOT/docs/architecture.md"

if [ ! -f "$ARCH" ]; then
  echo "FAIL: docs/architecture.md not found" >&2; exit 1
fi

# Assertion 1 (AC-060): SKL[18 Skills] present (v9.5.0: 18 skills after skills cleanup)
echo "--- Assertion 1 (AC-060): SKL[18 Skills] in docs/architecture.md ---"
if grep -qF 'SKL[18 Skills]' "$ARCH" || grep -qF '18 Skills' "$ARCH" || grep -qE '18 skills' "$ARCH"; then
  echo "OK (AC-060): docs/architecture.md has '18 Skills'"
else
  fail "AC-060: docs/architecture.md missing '18 Skills' — still uses stale count"
fi
if grep -qF 'SKL[25 Skills]' "$ARCH" || grep -qF '25 Skills' "$ARCH"; then
  fail "AC-060 NEGATIVE: docs/architecture.md still contains '25 Skills' (must be updated to 18 for v9.5)"
else
  echo "OK (AC-060): no stale '25 Skills' in docs/architecture.md"
fi

# Assertion 2 (AC-060a): NEEDS_CLARIFICATION substantive content in architecture.md
echo "--- Assertion 2 (AC-060a): NEEDS_CLARIFICATION in docs/architecture.md ---"
if grep -qE 'NEEDS_CLARIFICATION' "$ARCH"; then
  echo "OK (AC-060a): NEEDS_CLARIFICATION mentioned in docs/architecture.md"
else
  fail "AC-060a: docs/architecture.md missing NEEDS_CLARIFICATION (substantive v6.9.0 refresh required)"
fi

# Assertion 3 (AC-060a): pipeline-history feedback-loop in architecture.md
echo "--- Assertion 3 (AC-060a): pipeline-history feedback loop in docs/architecture.md ---"
if grep -qE 'pipeline-history|pipeline_history' "$ARCH"; then
  echo "OK (AC-060a): pipeline-history feedback loop present in docs/architecture.md"
else
  fail "AC-060a: docs/architecture.md missing pipeline-history feedback-loop node/arrow"
fi

# Assertion 4 (AC-060a): circuit-breaker in architecture.md
echo "--- Assertion 4 (AC-060a): circuit breaker in docs/architecture.md ---"
if grep -qiE 'circuit' "$ARCH"; then
  echo "OK (AC-060a): circuit-breaker label present in docs/architecture.md"
else
  fail "AC-060a: docs/architecture.md missing circuit-breaker label on webhook curl edge"
fi

# Assertion 5 (AC-060a): snippets sub-namespace in architecture.md
echo "--- Assertion 5 (AC-060a): snippets sub-cluster in docs/architecture.md ---"
if grep -qE 'snippets' "$ARCH"; then
  echo "OK (AC-060a): snippets sub-namespace mentioned in docs/architecture.md"
else
  fail "AC-060a: docs/architecture.md missing snippets sub-namespace sub-cluster"
fi

# Assertion 6 (AC-060a): 17 core contracts count in architecture.md (v9.3.0: resume-detection.md added)
echo "--- Assertion 6 (AC-060a): 17 core contracts count in docs/architecture.md ---"
if grep -qE '17 (Core|core)|CORE\[17|17.*core' "$ARCH"; then
  echo "OK (AC-060a): 17 core contracts count in docs/architecture.md"
else
  fail "AC-060a: docs/architecture.md missing updated core-contract count (16 -> 17)"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 docs/architecture.md refreshed: 18 skills (v9.5.0), NEEDS_CLARIFICATION, pipeline-history, circuit-breaker, snippets, 17 core contracts"
fi
exit "$FAIL"
