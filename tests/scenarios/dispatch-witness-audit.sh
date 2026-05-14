#!/usr/bin/env bash
# ===========================================================================
# Test:        v10-dispatch-witness-audit.sh
# FC mapped:   FC-2 (witness audit emission)
# What it checks:
#   1) core/lib/stage-invariant.sh exists
#   2) The library defines the 3 mandatory functions: compute_dispatch_witness,
#      check_dispatch_witness, emit_witness_audit
#   3) The witness algorithm uses sha256 and concatenates
#      subagent_type|model|prompt_head_128
#   4) The library is jq-free ("jq-free implementation")
#   5) The library is ≤140 lines (raised from
#      120 to accommodate POL-2 helpers __regex_escape_stage + __validate_witness_format)
# Expected RED phase: FAIL — core/lib/stage-invariant.sh does not yet exist
# Expected GREEN phase (post-impl): PASS
# Notes:
#   - We do NOT exercise the hook end-to-end with fixtures here (that requires
#     fixtures files outside .forge/phase-5-tdd/ and would violate scope guard).
#     Phase 7 implementation will land the canonical FC-2 fixture-driven test.
# ===========================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT" || { echo "FAIL: cannot cd to REPO_ROOT=$REPO_ROOT" >&2; exit 1; }

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

count_lines() { tr -d '\r' < "$1" | wc -l | tr -d ' '; }

LIB="core/lib/stage-invariant.sh"

# 1) File exists
if [ ! -f "$LIB" ]; then
  fail "FC-2.lib-missing: $LIB does not exist"
  exit 1
fi

# 2) Three mandatory function signatures present
# Accept either `funcname() {` or `function funcname` style.
for fn in compute_dispatch_witness check_dispatch_witness emit_witness_audit; do
  if ! grep -qE "(^|[[:space:]])(function[[:space:]]+)?${fn}[[:space:]]*\(" "$LIB"; then
    fail "FC-2.fn: $LIB missing function definition '${fn}'"
  fi
done

# 3) Algorithm references sha256 (any of the common spellings the impl might use)
if ! grep -qiE 'sha256|sha-256' "$LIB"; then
  fail "FC-2.algo-sha256: $LIB does not reference sha256 hashing"
fi

# 3b) Algorithm concatenates subagent_type|model|prompt_head_128.
# Look for the literal pipe-separated canonical form documented
if ! grep -qE 'subagent_type.*\|.*model.*\|.*prompt_head_128|\$\{subagent_type\}\|\$\{model\}\|\$\{prompt_head_128\}' "$LIB"; then
  # Slightly more permissive fallback: require all three tokens within close range (<= 5 lines).
  if ! awk '/subagent_type/{a=NR} /model/{b=NR} /prompt_head_128/{c=NR} END{if(a&&b&&c){m=a; if(b>m)m=b; if(c>m)m=c; n=a; if(b<n)n=b; if(c<n)n=c; exit (m-n<=5)?0:1} else exit 1}' "$LIB"; then
    fail "FC-2.algo-canon: $LIB witness algorithm does not concatenate subagent_type|model|prompt_head_128"
  fi
fi

# 4) jq-free — no `jq` invocations.
if grep -qE '(^|[[:space:]])jq([[:space:]]|$)' "$LIB"; then
  fail "FC-2.no-jq: $LIB invokes 'jq' but the contract mandates jq-free implementation"
fi

# 5) Line ceiling: ≤140 (raised ceiling of 120 to accommodate POL-2 helpers)
LIB_LINES=$(count_lines "$LIB")
if [ "$LIB_LINES" -gt 140 ]; then
  fail "FC-2.lib-size: $LIB = ${LIB_LINES}L (ceiling 140)"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v10-dispatch-witness-audit — $LIB ${LIB_LINES}L, 3 fns, sha256, jq-free, canonical pipe form"
  exit 0
fi
exit 1
