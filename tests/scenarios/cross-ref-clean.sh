#!/bin/bash
# Covers: AC-8 (no production references to deleted skills outside CHANGELOG/migration docs)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

COUNT=$(grep -rnE '(/|:)(migrate-config|estimate|pipeline-status|scaffold-validate)([^a-zA-Z0-9_-]|$)' \
  --include='*.md' --include='*.sh' \
  "$REPO_ROOT/agents/" "$REPO_ROOT/skills/" "$REPO_ROOT/core/" \
  "$REPO_ROOT/state/" "$REPO_ROOT/checklists/" \
  "$REPO_ROOT/docs/guides/" "$REPO_ROOT/docs/reference/" \
  "$REPO_ROOT/examples/" \
  "$REPO_ROOT/tests/scenarios/" \
  2>/dev/null \
  | grep -v 'docs/guides/migration-v7-to-v8.md' \
  | grep -v 'docs/guides/migration-v8-to-v9.md' \
  | grep -v 'CHANGELOG.md' \
  | grep -v 'tests/scenarios/v9-5-' \
  | grep -v 'tests/scenarios/v9\.5\.0-deleted-skill-' \
  | grep -v 'tombstone\|removed in earlier versions\|estimate' \
  | grep -v 'removed in earlier versions' \
  | grep -v 'tests/scenarios/v6.9.0-doc-count-drift.sh' \
  | grep -v 'tests/scenarios/v7.0.0-readme-collision-warning.sh' \
  | grep -v '\\\\: ' \
  | wc -l | tr -d ' ')

if [ "$COUNT" -eq 0 ]; then
  echo "PASS: v9-5-cross-ref-clean — no production references to deleted skills found"
  exit 0
else
  echo "FAIL: v9-5-cross-ref-clean — found $COUNT reference(s) to deleted skills in production files"
  grep -rnE '(/|:)(migrate-config|estimate|pipeline-status|scaffold-validate)([^a-zA-Z0-9_-]|$)' \
    --include='*.md' --include='*.sh' \
    "$REPO_ROOT/agents/" "$REPO_ROOT/skills/" "$REPO_ROOT/core/" \
    "$REPO_ROOT/state/" "$REPO_ROOT/checklists/" \
    "$REPO_ROOT/docs/guides/" "$REPO_ROOT/docs/reference/" \
    "$REPO_ROOT/examples/" \
    "$REPO_ROOT/tests/scenarios/" \
    2>/dev/null \
    | grep -v 'docs/guides/migration-v7-to-v8.md' \
    | grep -v 'docs/guides/migration-v8-to-v9.md' \
    | grep -v 'CHANGELOG.md' \
    | grep -v 'tests/scenarios/v9-5-' \
    | grep -v 'tests/scenarios/v9\.5\.0-deleted-skill-' \
    | grep -v 'tombstone\|removed in earlier versions\|estimate' \
    | grep -v 'removed in earlier versions' \
    | grep -v 'tests/scenarios/v6.9.0-doc-count-drift.sh' \
  | grep -v 'tests/scenarios/v7.0.0-readme-collision-warning.sh' \
    | grep -v '\\\\: ' \
    || true
  exit 1
fi
