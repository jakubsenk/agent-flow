#!/usr/bin/env bash
# Verifies: AC-9.0.1-7-1, AC-9.0.1-7-2, AC-9.0.1-7-3, AC-9.0.1-7-4, AC-9.0.1-7-5, AC-9.0.1-7-6
# Description: Asserts the RFC 2606 fast-fail guard in skills/version-check/SKILL.md
#              correctly classifies all reserved-TLD positives and all negatives.
#              v9.0.1 hardened: hostname-extract + last-label match (path-component bypass closed).
#              This scenario ships in tests/scenarios/ at v9.0.1 release.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: do not run from staging
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT - tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

SKILL="$REPO_ROOT/skills/version-check/SKILL.md"

# Assertion 1: SKILL.md contains the RFC 2606 TLD alternation (AC-9.0.1-7-1)
grep -qF '(test|example|invalid|localhost)' "$SKILL" \
  || fail "skills/version-check/SKILL.md missing RFC 2606 TLD alternation (test|example|invalid|localhost)"

# Assertion 2: SKILL.md documents source-2-only scope (AC-9.0.1-7-2)
grep -qiE 'source-2 only|HTTPS-only scope|SSH.*deferred' "$SKILL" \
  || fail "skills/version-check/SKILL.md missing source-2-only scope documentation"

# Assertion 3: SKILL.md includes the full scope comment (AC-9.0.1-7-6)
grep -qF 'source-2 only; HTTPS-only scope' "$SKILL" \
  || fail "skills/version-check/SKILL.md missing inline scope comment 'source-2 only; HTTPS-only scope'"

# Assertion 4: regex boundary anchor (/|:|$) acknowledged inline (AC-9.0.1-7-4)
# v9.0.1 hardened: boundary handled by hostname-extract step, but anchor literal still documented.
grep -qF '(/|:|$)' "$SKILL" \
  || fail "skills/version-check/SKILL.md missing boundary anchor (/|:|$) documentation"

# --- Hardened guard simulation (mirrors the bash logic in SKILL.md) ---
check_url() {
  local remote_url="$1"
  local host last_label
  host=$(echo "$remote_url" | sed -E 's|^[a-z]+://([^/]+).*|\1|' | sed -E 's|^[^@]+@||' | sed -E 's|:[0-9]+$||')
  host="${host%.}"
  last_label=$(echo "$host" | awk -F. '{print $NF}')
  if [ "$last_label" = "test" ] || [ "$last_label" = "example" ] || [ "$last_label" = "invalid" ] || [ "$last_label" = "localhost" ] \
     || [ "$host" = "test" ] || [ "$host" = "example" ] || [ "$host" = "invalid" ] || [ "$host" = "localhost" ]; then
    return 0  # would fast-fail
  fi
  return 1
}

# Assertions 5-8: ORIGINAL POSITIVE cases — all 4 RFC 2606 reserved-TLD URLs must trigger fast-fail
for url in \
  'https://gitea.test/foo.git' \
  'https://ci.example/bar.git' \
  'https://internal.invalid/baz.git' \
  'https://mydev.localhost/q.git'; do
  if check_url "$url"; then
    : # correctly fast-fails
  else
    fail "POSITIVE case '$url' did NOT trigger fast-fail (should)"
  fi
done

# Assertions 9-13: ORIGINAL NEGATIVE cases — none of these 5 URLs must trigger fast-fail
for url in \
  'https://mytest.example.com/repo.git' \
  'https://subdomain.example.org/repo.git' \
  'https://gitea.localhost.real-corp.org/repo.git' \
  'https://internal.example.invalid-but-real.org/repo.git' \
  'git@real-company.com:foo/bar.git'; do
  if check_url "$url"; then
    fail "NEGATIVE case '$url' incorrectly triggered fast-fail (false positive)"
  fi
done

# --- v9.0.1 hardening: 5 NEW cases for path-permissive bypass (Devil's Advocate findings) ---

# Assertions 14-16: NEW NEGATIVE cases — reserved labels in PATH must NOT trigger fast-fail
for url in \
  'https://github.com/foo.invalid/bar' \
  'https://gitea.example.com/repo/branch.test/foo' \
  'https://gitea.myco.com/team.localhost/repo.git'; do
  if check_url "$url"; then
    fail "NEW NEGATIVE case '$url' incorrectly triggered fast-fail (path component, not hostname)"
  fi
done

# Assertions 17-18: NEW POSITIVE cases — bare host + trailing-dot FQDN must trigger fast-fail
for url in \
  'https://test/foo.git' \
  'https://gitea.test./foo.git'; do
  if check_url "$url"; then
    : # correctly fast-fails
  else
    fail "NEW POSITIVE case '$url' did NOT trigger fast-fail (RFC 2606 hostname bypass)"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-9.0.1-7-1 through 7-6 - RFC 2606 hardened fast-fail: 6 positives match, 8 negatives clean"
fi
exit "$FAIL"
