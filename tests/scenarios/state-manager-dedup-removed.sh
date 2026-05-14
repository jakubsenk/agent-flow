#!/bin/bash
# Covers: AC-24
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/core/state-manager.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-state-manager-dedup-removed — core/state-manager.md not found"
  exit 1
fi

FAIL=0
fail() { echo "FAIL: v9-5-state-manager-dedup-removed — $1"; FAIL=1; }

if grep -qF '### Deduplication contract' "$FILE"; then
  fail "'### Deduplication contract' section still present in core/state-manager.md"
else
  echo "PASS: section header absent from core/state-manager.md"
fi

if grep -qF 'WHEN `/pipeline-status` reads state.json' "$FILE"; then
  fail "pipeline-status dedup contract text still present in core/state-manager.md"
else
  echo "PASS: pipeline-status dedup contract text absent from core/state-manager.md"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-state-manager-dedup-removed dedup block fully removed"
fi
exit "$FAIL"
