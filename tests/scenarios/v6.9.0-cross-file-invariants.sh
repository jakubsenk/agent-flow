#!/usr/bin/env bash
# Scenario: REQ-065, REQ-066 — CLAUDE.md Cross-File Invariants subsection + Webhook Payloads operator note
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — Cross-File Invariants subsection not yet added
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

if [ ! -f "$CLAUDE_MD" ]; then
  echo "FAIL: CLAUDE.md not found" >&2; exit 1
fi

# Assertion 1 (AC-065): ## Cross-File Invariants subsection exists
echo "--- Assertion 1 (AC-065): '## Cross-File Invariants' subsection in CLAUDE.md ---"
if grep -qF '## Cross-File Invariants' "$CLAUDE_MD"; then
  echo "OK (AC-065): ## Cross-File Invariants subsection present"
else
  fail "AC-065: CLAUDE.md missing '## Cross-File Invariants' subsection (must be placed after ## Versioning Policy)"
fi

# Assertion 2 (AC-065): exactly 3 numbered invariants
# Note: awk range /^## X/,/^## / includes the start line; use NR>1 to skip heading itself
echo "--- Assertion 2 (AC-065): exactly 3 numbered invariants ---"
invariant_count=$(awk '/^## Cross-File Invariants/{found=1; next} found && /^## /{exit} found{print}' "$CLAUDE_MD" 2>/dev/null | grep -cE '^[0-9]+\.' || true)
if [ "$invariant_count" -eq 3 ]; then
  echo "OK (AC-065): exactly 3 numbered invariants in Cross-File Invariants section"
else
  fail "AC-065: Cross-File Invariants section has $invariant_count numbered invariants (expected exactly 3)"
fi

# Assertion 3 (AC-065): invariant 1 — SPDX license match
echo "--- Assertion 3 (AC-065): Invariant 1 — SPDX MIT match ---"
cross_file_section=$(awk '/^## Cross-File Invariants/{found=1; next} found && /^## /{exit} found{print}' "$CLAUDE_MD" 2>/dev/null)
if echo "$cross_file_section" | grep -qE '"MIT"'; then
  echo "OK (AC-065): Invariant 1 references MIT SPDX exact-match"
else
  fail "AC-065: Cross-File Invariants Invariant 1 does not mention '\"MIT\"' SPDX match constraint"
fi

# Assertion 4 (AC-065): invariant 2 — maintainer email match
echo "--- Assertion 4 (AC-065): Invariant 2 — maintainer email match ---"
if echo "$cross_file_section" | grep -qF 'filip.sabacky@ceosdata.com'; then
  echo "OK (AC-065): Invariant 2 references filip.sabacky@ceosdata.com email match"
else
  fail "AC-065: Cross-File Invariants Invariant 2 does not mention 'filip.sabacky@ceosdata.com'"
fi

# Assertion 5 (AC-065): invariant 3 — .gitea + .github byte-identical
echo "--- Assertion 5 (AC-065): Invariant 3 — .gitea + .github byte-identical ---"
if echo "$cross_file_section" | grep -qE '\.gitea.*\.github|\.github.*\.gitea|byte.identical'; then
  echo "OK (AC-065): Invariant 3 references .gitea/.github byte-identical constraint"
else
  fail "AC-065: Cross-File Invariants Invariant 3 does not mention .gitea + .github byte-identical constraint"
fi

# Assertion 6 (AC-065): pointer line present (Phase 2 V-3 or feedback_doc_completeness)
echo "--- Assertion 6 (AC-065): pointer to Phase 2 V-3 or doc completeness reference ---"
if echo "$cross_file_section" | grep -qE 'Phase 2 V-3|feedback_doc_completeness'; then
  echo "OK (AC-065): pointer line to doc-count drift audit present"
else
  fail "AC-065: Cross-File Invariants missing pointer to 'Phase 2 V-3' or 'feedback_doc_completeness'"
fi

# Assertion 7 (AC-066): Webhook Payloads operator-awareness note
echo "--- Assertion 7 (AC-066): operator-awareness note in ## Webhook Payloads ---"
webhook_section=$(awk '/^## Webhook Payloads/{found=1; next} found && /^## /{exit} found{print}' "$CLAUDE_MD" 2>/dev/null)
if echo "$webhook_section" | grep -qE 'covert.?channel DoS|covert channel'; then
  echo "OK (AC-066): covert-channel DoS Scenario 3 documented in Webhook Payloads section"
else
  fail "AC-066: CLAUDE.md Webhook Payloads missing 'covert-channel DoS' operator-awareness note"
fi
if echo "$webhook_section" | grep -qF 'multi-contributor environments'; then
  echo "OK (AC-066): 'multi-contributor environments' warning present"
else
  fail "AC-066: CLAUDE.md Webhook Payloads missing 'multi-contributor environments' deferral note"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 CLAUDE.md has Cross-File Invariants (3 invariants) + Webhook Payloads operator-awareness note"
fi
exit "$FAIL"
