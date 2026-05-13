#!/usr/bin/env bash
set -euo pipefail

# AC-28: CHANGELOG.md contains v6.8.0 entry with three items and Migration notes
# Traces: all
# Description: Verifies CHANGELOG.md has 6.8.0 heading, feature keywords, date, Migration notes

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../../.."

FILE="CHANGELOG.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

FAIL=0

# Heading: ## 6.8.0 or ## [6.8.0]
if ! grep -nE "^## \[?6\.8\.0\]?" "$FILE" | grep -q .; then
  echo "FAIL: $FILE missing '## 6.8.0' or '## [6.8.0]' heading" >&2
  FAIL=1
fi

# Three feature keywords
for keyword in Autopilot Observability "Cost Visibility"; do
  if ! grep -qE "$keyword" "$FILE"; then
    echo "FAIL: $FILE missing feature keyword '$keyword' in changelog" >&2
    FAIL=1
  fi
done

# Date 2026-04-17
if ! grep -qF '2026-04-17' "$FILE"; then
  echo "FAIL: $FILE missing date '2026-04-17' in v6.8.0 entry" >&2
  FAIL=1
fi

# Migration notes subsection
if ! grep -qiF 'Migration notes' "$FILE"; then
  echo "FAIL: $FILE missing 'Migration notes' subsection in v6.8.0 entry" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-28 — CHANGELOG.md has complete v6.8.0 entry"
exit "$FAIL"
