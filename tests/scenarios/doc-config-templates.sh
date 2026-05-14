#!/usr/bin/env bash
# Verifies: AC-DOC-010
# Description: All 8 config templates have "Migration note: v7 → v8" callout + reference
#   customization/*.toml not legacy .md
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

TEMPLATES=(
  "examples/configs/github-nextjs.md"
  "examples/configs/github-python-fastapi.md"
  "examples/configs/github-dotnet.md"
  "examples/configs/gitea-spring-boot.md"
  "examples/configs/jira-react.md"
  "examples/configs/youtrack-python.md"
  "examples/configs/redmine-rails.md"
  "examples/configs/redmine-oracle-plsql.md"
)

for template in "${TEMPLATES[@]}"; do
  TEMPLATE_PATH="$REPO_ROOT/$template"
  echo "--- Checking $template ---"

  if [ ! -f "$TEMPLATE_PATH" ]; then
    fail "$template not found"
    continue
  fi

  # Migration note callout
  if grep -qiE 'Migration note.*v7.*v8|v7.*v8.*migration' "$TEMPLATE_PATH"; then
    echo "OK: $template has Migration note: v7 → v8"
  else
    fail "$template missing 'Migration note: v7 → v8' callout"
  fi

  # TOML overlay reference (.toml not .md)
  if grep -qiE 'customization/.*\.toml|\.toml.*overlay' "$TEMPLATE_PATH"; then
    echo "OK: $template references customization/*.toml"
  else
    fail "$template does not reference customization/*.toml (should use TOML overlay)"
  fi
done

# ---------------------------------------------------------------------------
# Assertion: Count 8 templates
# ---------------------------------------------------------------------------
echo "--- Assertion: exactly 8 config templates (excluding README.md) ---"
TEMPLATE_COUNT=$(find "$REPO_ROOT/examples/configs" -maxdepth 1 -name '*.md' -type f 2>/dev/null | grep -v 'README.md' | wc -l)
if [ "$TEMPLATE_COUNT" -eq 8 ]; then
  echo "OK: examples/configs/ has 8 templates"
else
  fail "examples/configs/ has $TEMPLATE_COUNT templates (expected 8)"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-DOC-010 — all 8 config templates have v7→v8 migration note + TOML reference"
fi
exit "$FAIL"
