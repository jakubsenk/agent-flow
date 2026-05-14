#!/bin/bash
# Covers: AC-1 (skill count = 18)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

ACTUAL=$(find "$REPO_ROOT/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
if [ "$ACTUAL" -eq 18 ]; then
  echo "PASS: v9-5-count-skills — skills/ directory count = 18"
  exit 0
else
  echo "FAIL: v9-5-count-skills — expected 18 skill directories, got $ACTUAL"
  exit 1
fi
