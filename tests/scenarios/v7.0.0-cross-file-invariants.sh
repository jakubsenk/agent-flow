#!/usr/bin/env bash
# AC-INVARIANTS-1, AC-INVARIANTS-2, AC-INVARIANTS-3
# Asserts the 3 CLAUDE.md cross-file invariants remain intact after v7.0.0 changes:
# 1. License SPDX "MIT" consistent across plugin.json, marketplace.json, LICENSE
# 2. Maintainer email filip.sabacky@ceosdata.com in SECURITY.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md
# 3. Issue/PR template files byte-identical between .gitea/ and .github/
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Functional check 1a: plugin.json has "license": "MIT"
if ! grep -q '"license": "MIT"' .claude-plugin/plugin.json 2>/dev/null; then
  fail ".claude-plugin/plugin.json: license != MIT"
fi

# Functional check 1b: marketplace.json has "license": "MIT"
if ! grep -q '"license": "MIT"' .claude-plugin/marketplace.json 2>/dev/null; then
  fail ".claude-plugin/marketplace.json: license != MIT"
fi

# Functional check 1c: LICENSE first line contains "MIT License"
if ! head -1 LICENSE | grep -qF 'MIT License' 2>/dev/null; then
  fail "LICENSE: first line does not contain 'MIT License'"
fi

# Functional check 2a-c: maintainer email in all 3 community files
for f in SECURITY.md CODE_OF_CONDUCT.md CONTRIBUTING.md; do
  if ! grep -q 'filip\.sabacky@ceosdata\.com' "$f" 2>/dev/null; then
    fail "$f: maintainer email 'filip.sabacky@ceosdata.com' not found"
  fi
done

# Functional check 3a: .gitea/issue_template/ files byte-identical with .github/ISSUE_TEMPLATE/
for gtea in .gitea/issue_template/*.md; do
  [ -f "$gtea" ] || continue
  base=$(basename "$gtea")
  ghub=".github/ISSUE_TEMPLATE/$base"
  if [ ! -f "$ghub" ]; then
    fail "$ghub missing (counterpart of $gtea)"
    continue
  fi
  if ! diff -q "$gtea" "$ghub" >/dev/null 2>&1; then
    fail "$gtea and $ghub differ (must be byte-identical)"
  fi
done

# Functional check 3b: PR templates byte-identical
if [ ! -f .gitea/pull_request_template.md ] || [ ! -f .github/PULL_REQUEST_TEMPLATE.md ]; then
  fail "PR template file(s) missing (.gitea/pull_request_template.md or .github/PULL_REQUEST_TEMPLATE.md)"
else
  if ! diff -q .gitea/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md >/dev/null 2>&1; then
    fail ".gitea/pull_request_template.md and .github/PULL_REQUEST_TEMPLATE.md differ"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-INVARIANTS-1..3 — cross-file invariants preserved (license SPDX, maintainer email, template parity)"
exit "$FAIL"
