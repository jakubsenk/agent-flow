#!/usr/bin/env bash
# v9.1.0-no-router-references.sh — REQ-V910-006:
# No *.md or *.sh file in the production tree (outside designated exclusion
# paths) contains the substring "workflow-router".
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

echo "--- REQ-V910-006: no workflow-router references in production docs ---"

# ---------------------------------------------------------------------------
# Exclusion rationale:
#   docs/plans/              — historical planning docs intentionally retained
#                              (roadmap.md, spec docs, review docs, alternatives)
#   CHANGELOG.md             — changelog [Removed] section records the deletion
#   docs/superpowers/specs/  — historical WIP spec documents
#   .forge/                  — transient forge pipeline artifacts (current run)
#   .forge.bak-*             — forge backup directories (e.g. .forge.bak-2026-04-29T210550Z)
#   .forge.v[0-9]*           — version-tagged forge backup dirs (e.g. .forge.v8.0.0/)
#                             NOTE: Q-003 fix — this segment is mandatory; without it
#                             the grep returns 38+ stale router refs from historical backups.
#   v9.1.0-no-router-references.sh — self-exclusion (this file's grep pattern would
#                             match the literal string "workflow-router" in the --exclude arg)
#   v9.1.0-workflow-router-removed.sh — self-reference: asserts router absence, must contain
#                             the string by definition
#   v7.0.0-no-create-pr-skill.sh — vacuous-pass test: references workflow-router in
#                             absence-context prose (design.md §6.4)
#   v7.0.0-skill-rename-init.sh  — vacuous-pass test: same rationale (design.md §6.4)
# ---------------------------------------------------------------------------

# Run grep from REPO_ROOT to get paths relative to repo root.
cd "$REPO_ROOT" || { fail "Cannot cd to REPO_ROOT=$REPO_ROOT"; exit 1; }

# Collect matching files, excluding all designated paths.
# Uses grep -rln for file-level matching (one line per file, not per match).
# The post-filter grep -vE strips the exclusion paths.
matches=$(
  grep -rln 'workflow-router' \
    --include='*.md' \
    --include='*.sh' \
    --exclude='v9.1.0-no-router-references.sh' \
    --exclude='v9.1.0-workflow-router-removed.sh' \
    --exclude='v7.0.0-no-create-pr-skill.sh' \
    --exclude='v7.0.0-skill-rename-init.sh' \
    . 2>/dev/null \
  | grep -vE '^\./(\.|forge\.bak-|forge\.v[0-9])' \
  | grep -vE '^\.\/(docs\/plans\/|CHANGELOG\.md|docs\/superpowers\/specs\/)' \
  | grep -vE '^\.\/(\.forge\/)' \
  || true
)

if [ -z "$matches" ]; then
  echo "OK: zero production files contain workflow-router (outside exclusion list)"
else
  echo "Files still containing workflow-router:" >&2
  echo "$matches" >&2
  match_count=$(echo "$matches" | grep -c . || echo 0)
  fail "Found $match_count file(s) with workflow-router references outside exclusion list"
fi

# ---------------------------------------------------------------------------
# Final verdict.
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.1.0-no-router-references — production tree is workflow-router free"
fi
exit "$FAIL"
