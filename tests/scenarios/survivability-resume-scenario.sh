#!/bin/bash
# Covers: AC-56 — v9.5.0-survivability-resume.sh deletion check
# Cleanup deleted this scenario. Resume detection behavior is
# covered by stable tests including resume-detection contract tests.
# This meta-test asserts the file is ABSENT (deletion was intentional).
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/tests/scenarios/v9.5.0-survivability-resume.sh"

if [ -f "$FILE" ]; then
  echo "FAIL: v9-5-survivability-resume-scenario — tests/scenarios/v9.5.0-survivability-resume.sh unexpectedly exists (should have been deleted in cleanup)"
  exit 1
fi

echo "PASS: v9-5-survivability-resume-scenario — v9.5.0-survivability-resume.sh correctly absent (deleted in cleanup)"
exit 0
