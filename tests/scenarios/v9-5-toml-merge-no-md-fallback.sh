#!/bin/bash
# Covers: AC-16 (skills/setup-agents/lib/toml-merge.sh .md fallback removed)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/skills/setup-agents/lib/toml-merge.sh"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-toml-merge-no-md-fallback — skills/setup-agents/lib/toml-merge.sh not found"
  exit 1
fi

FAIL=0
fail() { echo "FAIL: v9-5-toml-merge-no-md-fallback — $1"; FAIL=1; }

# overlay_source=md (without underscore suffix) must be gone
if grep -qE 'overlay_source=md[^_]' "$FILE"; then
  fail "overlay_source=md (md-fallback branch) still present in toml-merge.sh"
else
  echo "PASS: overlay_source=md fallback absent from toml-merge.sh"
fi

# migrate-config reference must be gone
if grep -qF 'migrate-config' "$FILE"; then
  fail "'migrate-config' reference still present in toml-merge.sh"
else
  echo "PASS: 'migrate-config' reference absent from toml-merge.sh"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-toml-merge-no-md-fallback — .md fallback fully removed from toml-merge.sh"
fi
exit "$FAIL"
