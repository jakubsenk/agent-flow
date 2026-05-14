#!/bin/bash
# Covers: AC-57 — v9.5.0-block-handler-analyst.sh deletion check
# Cleanup deleted this scenario (it was a forge-staging-orphan testing
# transient .forge/ spec content, not stable production behavior).
# This meta-test now asserts the file is ABSENT (deletion was intentional).
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/tests/scenarios/v9.5.0-block-handler-analyst.sh"

if [ -f "$FILE" ]; then
  echo "FAIL: v9-5-block-handler-analyst-scenario — tests/scenarios/v9.5.0-block-handler-analyst.sh unexpectedly exists (should have been deleted in cleanup)"
  exit 1
fi

echo "PASS: v9-5-block-handler-analyst-scenario — v9.5.0-block-handler-analyst.sh correctly absent (deleted in cleanup)"
exit 0
