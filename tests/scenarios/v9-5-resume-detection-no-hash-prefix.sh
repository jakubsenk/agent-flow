#!/bin/bash
# Covers: AC-17 (core/resume-detection.md # -prefix normalization removed)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/core/resume-detection.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-resume-detection-no-hash-prefix — core/resume-detection.md not found"
  exit 1
fi

FAIL=0
fail() { echo "FAIL: v9-5-resume-detection-no-hash-prefix — $1"; FAIL=1; }

if grep -qF '#ISSUE_ID' "$FILE"; then
  fail "'#ISSUE_ID' still present in core/resume-detection.md (v6 hash-prefix normalization not removed)"
else
  echo "PASS: '#ISSUE_ID' absent from core/resume-detection.md"
fi

if grep -qE 'leading.*#.*prefix' "$FILE"; then
  fail "'leading.*#.*prefix' pattern still present in core/resume-detection.md"
else
  echo "PASS: leading-hash-prefix text absent from core/resume-detection.md"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-resume-detection-no-hash-prefix — v6 #-prefix normalization removed"
fi
exit "$FAIL"
