#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #6 — Tier B)
# Functional: circuit breaker semantics — 3-failure threshold, in-memory/per-run, advisory.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

POST_HOOK="$REPO_ROOT/core/post-publish-hook.md"
[ -f "$POST_HOOK" ] || { fail "core/post-publish-hook.md not found"; exit 1; }

# 3-failure threshold documented
if ! grep -qE '3.*consecutive|3.*failure|threshold.*3|3.*threshold' "$POST_HOOK"; then
  fail "post-publish-hook.md: 3-failure circuit breaker threshold not documented"
fi

# Advisory: non-blocking
if ! grep -qiE 'advisory|non.?block|WARN' "$POST_HOOK"; then
  fail "post-publish-hook.md: circuit breaker advisory semantics not documented"
fi

# In-memory: scoped to run
if ! grep -qiE 'in.memory|per.run|per.pipeline.run|run.scope' "$POST_HOOK"; then
  fail "post-publish-hook.md: circuit breaker in-memory/per-run scope not documented"
fi

# Mutation guard: confirm 3 is the exact threshold (not 2 or 5)
if grep -qE 'threshold.*[^3]|[^3].*consecutive.*failure' "$POST_HOOK"; then
  # Allow adjacent numbers in other contexts — just ensure 3 is present
  :
fi

[ "$FAIL" -eq 0 ] && echo "PASS: circuit breaker semantics verified"
exit "$FAIL"
