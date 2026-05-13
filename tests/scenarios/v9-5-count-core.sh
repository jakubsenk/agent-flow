#!/bin/bash
# Covers: AC-2 (core-contract count = 17, UNCHANGED; maxdepth-1 only, excludes core/aliases/)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

ACTUAL=$(find "$REPO_ROOT/core" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')
if [ "$ACTUAL" -eq 17 ]; then
  echo "PASS: v9-5-count-core — core/ top-level .md count = 17 (unchanged)"
  exit 0
else
  echo "FAIL: v9-5-count-core — expected 17 core/*.md files, got $ACTUAL"
  exit 1
fi
