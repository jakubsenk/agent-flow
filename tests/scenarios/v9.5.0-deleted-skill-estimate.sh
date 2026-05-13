#!/usr/bin/env bash
# v9.5.0 — AC-53: skills/estimate/ must not exist (deleted in v9.5.0 Wave 3).
# The /estimate skill (110 lines) was removed as it provided rough story-point
# estimates that overlapped with the analyst triage complexity output.
# Created 2026-05-09 as part of v9.5.0 post-cleanup test polish.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if test ! -d "$REPO_ROOT/skills/estimate"; then
  echo "PASS: skills/estimate directory correctly absent (deleted in v9.5.0)"
  exit 0
else
  echo "FAIL: v9.5.0-deleted-skill-estimate — skills/estimate/ still exists (must be deleted per v9.5.0 Wave 3)"
  exit 1
fi
