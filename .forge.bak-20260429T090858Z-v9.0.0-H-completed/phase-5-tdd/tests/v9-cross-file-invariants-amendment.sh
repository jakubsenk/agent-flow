#!/bin/bash
# PURPOSE: Assert CLAUDE.md "Cross-File Invariants" subsection has been amended to list 4
#          invariants (was 3), and the 4th invariant contains the required phrase for Agent
#          Output Contract xref consistency (REQ-H-060, REQ-H-061, AC-H-062, AC-H-063, AC-H-064).
# AC-H-N covered: AC-H-062, AC-H-063, AC-H-064
# INVOKED BY: tests/harness/run-tests.sh
# EXPECTED ON v8.0.0: FAIL (only 3 invariants; 4th not present)
# EXPECTED ON v9.0.0: PASS (4 invariants, 4th has required text and verifier reference)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

if [ ! -f "$CLAUDE_MD" ]; then
  fail "CLAUDE.md not found at $CLAUDE_MD"
  exit 1
fi

# AC-H-062: count numbered invariants in Cross-File Invariants subsection
invariant_count=$(awk '/^## Cross-File Invariants$/{found=1; next} found && /^## /{exit} found' "$CLAUDE_MD" | grep -cE '^[0-9]+\.\s+\*\*' || true)
if [ "$invariant_count" -ne 4 ]; then
  fail "CLAUDE.md Cross-File Invariants has $invariant_count numbered invariants, expected 4 (was 3 in v8.0.0)"
  # Mutation catch: omitting the 4th invariant fails here
fi

# AC-H-063: 4th invariant contains "Agent Output Contract ↔ skill xref consistency"
if ! grep -qF 'Agent Output Contract ↔ skill xref consistency' "$CLAUDE_MD"; then
  fail "CLAUDE.md Cross-File Invariants 4th invariant missing phrase 'Agent Output Contract ↔ skill xref consistency'"
  # Mutation catch: using a different invariant name fails here
fi

# AC-H-064: 4th invariant references the verifier scenario
if ! grep -qF 'tests/scenarios/v9-xref-outputs-skill-references.sh' "$CLAUDE_MD"; then
  fail "CLAUDE.md Cross-File Invariants 4th invariant missing reference to 'tests/scenarios/v9-xref-outputs-skill-references.sh'"
  # Mutation catch: forgetting to add the scenario reference to the invariant fails here
fi

# Additional: verify existing 3 invariants are preserved (backward-compat guard)
if ! grep -qF 'License SPDX consistency' "$CLAUDE_MD"; then
  fail "CLAUDE.md Cross-File Invariants — invariant 1 (License SPDX consistency) missing or renamed"
fi
if ! grep -qF 'Maintainer email consistency' "$CLAUDE_MD"; then
  fail "CLAUDE.md Cross-File Invariants — invariant 2 (Maintainer email consistency) missing or renamed"
fi
if ! grep -qF 'Issue/PR template parity' "$CLAUDE_MD"; then
  fail "CLAUDE.md Cross-File Invariants — invariant 3 (Issue/PR template parity) missing or renamed"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-H-062, AC-H-063, AC-H-064 — CLAUDE.md Cross-File Invariants has 4 invariants; 4th correctly references xref scenario"
fi
exit "$FAIL"
