#!/bin/bash
# Covers: AC-INV-1 (license SPDX triple-match),
#         AC-INV-2 (maintainer email triple-match),
#         AC-INV-3 (issue/PR template gitea/github byte-parity)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: v9-5-cross-file-invariants — $1"; FAIL=1; }

# AC-INV-1: License SPDX triple-match
if grep -qF '"license": "MIT"' "$REPO_ROOT/.claude-plugin/plugin.json" || \
   grep -qE '"license":[[:space:]]*"MIT"' "$REPO_ROOT/.claude-plugin/plugin.json"; then
  echo "PASS: plugin.json has MIT license"
else
  fail "plugin.json does not have MIT license"
fi

if grep -qE '"license":[[:space:]]*"MIT"' "$REPO_ROOT/.claude-plugin/marketplace.json"; then
  echo "PASS: marketplace.json has MIT license"
else
  fail "marketplace.json does not have MIT license"
fi

if head -3 "$REPO_ROOT/LICENSE" | grep -qF 'MIT'; then
  echo "PASS: LICENSE file mentions MIT in first 3 lines"
else
  fail "LICENSE file does not mention MIT in first 3 lines"
fi

# AC-INV-2: Maintainer email triple-match
for doc in SECURITY.md CODE_OF_CONDUCT.md CONTRIBUTING.md; do
  if grep -qF 'filip.sabacky@ceosdata.com' "$REPO_ROOT/$doc"; then
    echo "PASS: $doc contains maintainer email"
  else
    fail "$doc does not contain filip.sabacky@ceosdata.com"
  fi
done

# AC-INV-3: Template byte-parity
if diff -q "$REPO_ROOT/.gitea/issue_template/bug_report.md" \
           "$REPO_ROOT/.github/ISSUE_TEMPLATE/bug_report.md" > /dev/null 2>&1; then
  echo "PASS: bug_report.md templates are byte-identical"
else
  fail ".gitea/issue_template/bug_report.md and .github/ISSUE_TEMPLATE/bug_report.md differ"
fi

if diff -q "$REPO_ROOT/.gitea/issue_template/feature_request.md" \
           "$REPO_ROOT/.github/ISSUE_TEMPLATE/feature_request.md" > /dev/null 2>&1; then
  echo "PASS: feature_request.md templates are byte-identical"
else
  fail ".gitea/issue_template/feature_request.md and .github/ISSUE_TEMPLATE/feature_request.md differ"
fi

if diff -q "$REPO_ROOT/.gitea/pull_request_template.md" \
           "$REPO_ROOT/.github/PULL_REQUEST_TEMPLATE.md" > /dev/null 2>&1; then
  echo "PASS: pull_request_template.md templates are byte-identical"
else
  fail ".gitea/pull_request_template.md and .github/PULL_REQUEST_TEMPLATE.md differ"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-cross-file-invariants — all cross-file invariants hold"
fi
exit "$FAIL"
