#!/usr/bin/env bash
set -euo pipefail

# REGRESSION: Key files that existed in v6.7.2 are not truncated/emptied
# Traces: all (change safety)
# Description: Verifies sentinel lines from v6.7.2 still present in modified files

cd "$(dirname "$0")/../../.."

FAIL=0

# core/post-publish-hook.md: existing content preserved
HOOK="core/post-publish-hook.md"
if [ -f "$HOOK" ]; then
  # v6.7.2 sentinel: pr-created event (present before v6.8.0)
  if ! grep -qF 'pr-created' "$HOOK"; then
    echo "FAIL: $HOOK sentinel 'pr-created' missing — possible content truncation" >&2
    FAIL=1
  fi
  # curl pattern must still be in Section 3
  if ! grep -qiE 'max-time 5|max.time.*5' "$HOOK"; then
    echo "FAIL: $HOOK 'max-time 5' curl pattern missing — possible content loss" >&2
    FAIL=1
  fi
fi

# state/schema.md: schema_version and existing fields preserved
SCHEMA="state/schema.md"
if [ -f "$SCHEMA" ]; then
  if ! grep -qF 'schema_version' "$SCHEMA"; then
    echo "FAIL: $SCHEMA 'schema_version' sentinel missing — possible content truncation" >&2
    FAIL=1
  fi
  # status field must still be documented (was in v6.7.2)
  if ! grep -qF '"status"' "$SCHEMA"; then
    echo "FAIL: $SCHEMA '\"status\"' sentinel missing — possible content loss" >&2
    FAIL=1
  fi
fi

# core/state-manager.md: atomic write pattern preserved
STATE_MGR="core/state-manager.md"
if [ -f "$STATE_MGR" ]; then
  if ! grep -qF '.tmp' "$STATE_MGR"; then
    echo "FAIL: $STATE_MGR '.tmp' atomic write sentinel missing — possible content loss" >&2
    FAIL=1
  fi
fi

# CLAUDE.md: architecture section preserved
if ! grep -qF 'Bug-Fix Pipeline' CLAUDE.md; then
  echo "FAIL: CLAUDE.md 'Bug-Fix Pipeline' sentinel missing — possible content truncation" >&2
  FAIL=1
fi

# skills/resume-ticket/SKILL.md preserved
RESUME="skills/resume-ticket/SKILL.md"
if [ -f "$RESUME" ]; then
  if ! grep -qiE 'state\.json|resume' "$RESUME"; then
    echo "FAIL: $RESUME content seems truncated (state.json/resume references missing)" >&2
    FAIL=1
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: REGRESSION — all v6.7.2 sentinel lines preserved in modified files"
exit "$FAIL"
