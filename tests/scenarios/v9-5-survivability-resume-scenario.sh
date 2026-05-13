#!/bin/bash
# Covers: AC-56 — v9.5.0-survivability-resume.sh deletion check
# v9.5.0 cleanup deleted this scenario. Resume detection behavior is
# covered by stable tests including v9-5-resume-detection-no-hash-prefix.sh
# and the core/resume-detection.md contract tests.
# This meta-test now asserts the file is ABSENT (deletion was intentional).
# Updated 2026-05-09: inverted check per v9.5.0 cleanup audit.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/tests/scenarios/v9.5.0-survivability-resume.sh"

if [ -f "$FILE" ]; then
  echo "FAIL: v9-5-survivability-resume-scenario — tests/scenarios/v9.5.0-survivability-resume.sh unexpectedly exists (should have been deleted in v9.5.0 cleanup)"
  exit 1
fi

echo "PASS: v9-5-survivability-resume-scenario — v9.5.0-survivability-resume.sh correctly absent (deleted in v9.5.0 cleanup)"
exit 0
