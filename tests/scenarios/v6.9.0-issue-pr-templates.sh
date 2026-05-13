#!/usr/bin/env bash
# Scenario: REQ-017, REQ-018, REQ-019, REQ-020 — .gitea/ and .github/ templates + PII warning + no-secrets checkbox
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — template dirs do not exist yet
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

GITEA_BUG="$REPO_ROOT/.gitea/issue_template/bug_report.md"
GITEA_FEAT="$REPO_ROOT/.gitea/issue_template/feature_request.md"
GITEA_PR="$REPO_ROOT/.gitea/pull_request_template.md"
GITHUB_BUG="$REPO_ROOT/.github/ISSUE_TEMPLATE/bug_report.md"
GITHUB_FEAT="$REPO_ROOT/.github/ISSUE_TEMPLATE/feature_request.md"
GITHUB_PR="$REPO_ROOT/.github/PULL_REQUEST_TEMPLATE.md"

# Assertion 1 (AC-017): all 3 .gitea/ files exist
echo "--- Assertion 1 (AC-017): .gitea/ template files exist ---"
for f in "$GITEA_BUG" "$GITEA_FEAT" "$GITEA_PR"; do
  if [ -f "$f" ]; then
    echo "OK: $f exists"
  else
    fail "AC-017: $f does NOT exist (required .gitea/ template)"
  fi
done

# Assertion 2 (AC-018): all 3 .github/ files exist
echo "--- Assertion 2 (AC-018): .github/ template files exist ---"
for f in "$GITHUB_BUG" "$GITHUB_FEAT" "$GITHUB_PR"; do
  if [ -f "$f" ]; then
    echo "OK: $f exists"
  else
    fail "AC-018: $f does NOT exist (required .github/ template)"
  fi
done

# Assertion 3 (AC-018): .github/ files are byte-identical to .gitea/ counterparts
echo "--- Assertion 3 (AC-018): .github/ files byte-identical to .gitea/ counterparts ---"
if [ -f "$GITEA_BUG" ] && [ -f "$GITHUB_BUG" ]; then
  if diff -q "$GITEA_BUG" "$GITHUB_BUG" >/dev/null 2>&1; then
    echo "OK: bug_report.md files are byte-identical"
  else
    fail "AC-018: .gitea/issue_template/bug_report.md and .github/ISSUE_TEMPLATE/bug_report.md differ"
  fi
fi
if [ -f "$GITEA_FEAT" ] && [ -f "$GITHUB_FEAT" ]; then
  if diff -q "$GITEA_FEAT" "$GITHUB_FEAT" >/dev/null 2>&1; then
    echo "OK: feature_request.md files are byte-identical"
  else
    fail "AC-018: .gitea/issue_template/feature_request.md and .github/ISSUE_TEMPLATE/feature_request.md differ"
  fi
fi
if [ -f "$GITEA_PR" ] && [ -f "$GITHUB_PR" ]; then
  if diff -q "$GITEA_PR" "$GITHUB_PR" >/dev/null 2>&1; then
    echo "OK: pull_request_template files are byte-identical"
  else
    fail "AC-018: .gitea/pull_request_template.md and .github/PULL_REQUEST_TEMPLATE.md differ"
  fi
fi

# Assertion 4 (AC-019): PII warning in BOTH bug_report.md files
echo "--- Assertion 4 (AC-019): PII warning in bug_report templates ---"
for f in "$GITEA_BUG" "$GITHUB_BUG"; do
  if [ -f "$f" ] && grep -qF 'DO NOT include API keys, tokens, internal URLs, or PII' "$f"; then
    echo "OK (AC-019): PII warning present in $f"
  elif [ -f "$f" ]; then
    fail "AC-019: PII warning missing from $f (must contain 'DO NOT include API keys, tokens, internal URLs, or PII')"
  fi
done

# Assertion 5 (AC-020): no-secrets checkbox in BOTH PR template files
echo "--- Assertion 5 (AC-020): no-secrets checkbox in PR templates ---"
for f in "$GITEA_PR" "$GITHUB_PR"; do
  if [ -f "$f" ] && grep -qF -- '- [ ] No secrets committed' "$f"; then
    echo "OK (AC-020): no-secrets checkbox present in $f"
  elif [ -f "$f" ]; then
    fail "AC-020: no-secrets checkbox missing from $f (must contain '- [ ] No secrets committed')"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 .gitea/ + .github/ templates exist, byte-identical, with PII warning and no-secrets checkbox"
fi
exit "$FAIL"
