#!/usr/bin/env bash
# Scenario: REQ-006, REQ-007, REQ-008, REQ-009 — SECURITY.md content + softened SLA wording
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — SECURITY.md does not exist yet
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

SECURITY_MD="$REPO_ROOT/SECURITY.md"
CONTRIBUTING_MD="$REPO_ROOT/CONTRIBUTING.md"

# Guard: SECURITY.md must exist
if [ ! -f "$SECURITY_MD" ]; then
  echo "FAIL: SECURITY.md does not exist at repo root — required by REQ-006" >&2
  exit 1
fi

# Assertion 1 (AC-006): "Reporting a Vulnerability" section header
echo "--- Assertion 1 (AC-006): Reporting a Vulnerability section present ---"
if grep -q '## Reporting a Vulnerability' "$SECURITY_MD"; then
  echo "OK: SECURITY.md has 'Reporting a Vulnerability' section"
else
  fail "AC-006: SECURITY.md missing '## Reporting a Vulnerability' section"
fi

# Assertion 2 (AC-006): contact email present
echo "--- Assertion 2 (AC-006): contact email present ---"
if grep -q 'filip.sabacky@ceosdata.com' "$SECURITY_MD"; then
  echo "OK: SECURITY.md contains filip.sabacky@ceosdata.com"
else
  fail "AC-006: SECURITY.md missing 'filip.sabacky@ceosdata.com' contact"
fi

# Assertion 3 (AC-006): softened SLA — acknowledge within 5 business days
echo "--- Assertion 3 (AC-006): softened SLA 'acknowledge reports within 5 business days' ---"
if grep -q 'acknowledge reports within 5 business days' "$SECURITY_MD"; then
  echo "OK: SECURITY.md contains correct SLA wording"
else
  fail "AC-006: SECURITY.md missing 'acknowledge reports within 5 business days' (Agent-C-mandated softened SLA)"
fi

# Assertion 4 (AC-006): coordinated-disclosure timeline extension wording
echo "--- Assertion 4 (AC-006): coordinated-disclosure timeline wording ---"
if grep -q 'fix, public mitigation guidance, OR coordinated-disclosure timeline extension by mutual agreement' "$SECURITY_MD"; then
  echo "OK: SECURITY.md contains coordinated-disclosure language"
else
  fail "AC-006: SECURITY.md missing 'fix, public mitigation guidance, OR coordinated-disclosure timeline extension by mutual agreement'"
fi

# Assertion 5 (AC-006): Supported Versions section
echo "--- Assertion 5 (AC-006): Supported Versions section present ---"
if grep -q '## Supported Versions' "$SECURITY_MD"; then
  echo "OK: SECURITY.md has 'Supported Versions' section"
else
  fail "AC-006: SECURITY.md missing '## Supported Versions' section"
fi

# Assertion 6 (AC-007): CONTRIBUTING.md links to SECURITY.md
echo "--- Assertion 6 (AC-007): CONTRIBUTING.md links to SECURITY.md ---"
if [ ! -f "$CONTRIBUTING_MD" ]; then
  fail "AC-007: CONTRIBUTING.md not found"
else
  if grep -qF 'For security vulnerabilities, see [SECURITY.md](SECURITY.md) instead of opening a public issue.' "$CONTRIBUTING_MD"; then
    echo "OK (AC-007): CONTRIBUTING.md contains SECURITY.md pointer line"
  else
    fail "AC-007: CONTRIBUTING.md missing 'For security vulnerabilities, see [SECURITY.md](SECURITY.md) instead of opening a public issue.'"
  fi
fi

# Assertion 7 (AC-009): roadmap.md v6.9.1 entry for SECURITY.md secondary contact
echo "--- Assertion 7 (AC-009): roadmap.md v6.9.1 entry for SECURITY.md secondary contact ---"
ROADMAP="$REPO_ROOT/docs/plans/roadmap.md"
if [ ! -f "$ROADMAP" ]; then
  fail "AC-009: docs/plans/roadmap.md not found"
else
  if grep -qF 'SECURITY.md secondary contact channel' "$ROADMAP"; then
    echo "OK (AC-009): roadmap.md mentions SECURITY.md secondary contact channel for v6.9.1"
  else
    fail "AC-009: roadmap.md missing 'SECURITY.md secondary contact channel' v6.9.1 entry"
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 SECURITY.md exists with all required content + CONTRIBUTING.md pointer + roadmap deferral"
fi
exit "$FAIL"
