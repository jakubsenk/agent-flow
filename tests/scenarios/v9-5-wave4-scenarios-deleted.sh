#!/bin/bash
# Covers: AC-27 (cost-resume-v6.7-state.sh deleted),
#         AC-28 (v8-migrate-config-md-to-toml.sh deleted),
#         AC-29 (v8-migrate-config-dryrun-noop.sh deleted),
#         AC-30 (v8-migrate-config-skip-stages.sh deleted),
#         AC-31 (v8-migrate-config-backup-failure.sh deleted),
#         AC-32 (v8-migrate-config-yolo-autoresolve.sh deleted),
#         AC-33 (v8-pipeline-status-dedup.sh deleted),
#         AC-34 (v8-overlay-md-legacy-only.sh deleted)
# These 8 are Wave-4 deletions (REQ-9.5-W4-S20)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: v9-5-wave4-scenarios-deleted — $1"; FAIL=1; }

for scenario in \
  "cost-resume-v6.7-state.sh" \
  "v8-migrate-config-md-to-toml.sh" \
  "v8-migrate-config-dryrun-noop.sh" \
  "v8-migrate-config-skip-stages.sh" \
  "v8-migrate-config-backup-failure.sh" \
  "v8-migrate-config-yolo-autoresolve.sh" \
  "v8-pipeline-status-dedup.sh" \
  "v8-overlay-md-legacy-only.sh"
do
  if [ -f "$REPO_ROOT/tests/scenarios/$scenario" ]; then
    fail "tests/scenarios/$scenario still exists — should be deleted in Wave-4 (v9.5.0)"
  else
    echo "PASS: tests/scenarios/$scenario correctly absent"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-wave4-scenarios-deleted — all 8 Wave-4 deleted scenarios absent"
fi
exit "$FAIL"
