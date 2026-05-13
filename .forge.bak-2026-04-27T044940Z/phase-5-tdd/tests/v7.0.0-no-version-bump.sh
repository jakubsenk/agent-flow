#!/usr/bin/env bash
# AC-NO-VERSION-BUMP-1, AC-NO-VERSION-BUMP-2, AC-NO-VERSION-BUMP-3
# Asserts the forge pipeline did NOT modify the "version" field in plugin.json
# or marketplace.json, and did NOT create a v7.0.0 git tag.
# Compares against main branch (the prior released state, tag v6.10.0).
# SKIP (exit 77) if git is unavailable or no 'main' branch exists.
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Guard: require git
if ! command -v git >/dev/null 2>&1; then
  echo "SKIP: git not available" >&2
  exit 77
fi

# Guard: require main branch reference to exist
if ! git rev-parse --verify main >/dev/null 2>&1; then
  echo "SKIP: 'main' branch not found in this git repo — cannot compare" >&2
  exit 77
fi

# Functional check 1: plugin.json version field not modified relative to main
plugin_version_diffs=$(git diff main -- .claude-plugin/plugin.json | grep -E '^[+-].*"version"' | wc -l | tr -d ' ')
if [ "$plugin_version_diffs" != "0" ]; then
  fail ".claude-plugin/plugin.json: version field modified by pipeline ($plugin_version_diffs diff lines found)"
  git diff main -- .claude-plugin/plugin.json | grep -E '^[+-].*"version"' >&2 || true
fi

# Functional check 2: marketplace.json version field not modified relative to main
marketplace_version_diffs=$(git diff main -- .claude-plugin/marketplace.json | grep -E '^[+-].*"version"' | wc -l | tr -d ' ')
if [ "$marketplace_version_diffs" != "0" ]; then
  fail ".claude-plugin/marketplace.json: version field modified by pipeline ($marketplace_version_diffs diff lines found)"
  git diff main -- .claude-plugin/marketplace.json | grep -E '^[+-].*"version"' >&2 || true
fi

# Functional check 3: no v7.0.0 git tag created
v700_tags=$(git tag -l v7.0.0 | wc -l | tr -d ' ')
if [ "$v700_tags" != "0" ]; then
  fail "git tag v7.0.0 was created by the pipeline — this is prohibited (user must run /version-bump manually)"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-NO-VERSION-BUMP-1..3 — pipeline did not modify version fields or create v7.0.0 tag"
exit "$FAIL"
