#!/usr/bin/env bash
# Test: Hooks appear in correct order in pipeline commands
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# Returns the first line number of a hook STEP HEADING in a file.
# Only matches markdown section headings (lines starting with #) that contain the hook name.
# This avoids matching config-listing lines or inline references inside other steps.
# Prints 0 if not found.
hook_step_line() {
  local file="$1"
  local hook="$2"   # e.g. "pre-fix", "post-fix", "pre-publish", "post-publish"
  # Match only lines starting with one or more # (section headings)
  grep -in "^#\+.*${hook}" "$file" | head -1 | cut -d: -f1 || echo 0
}

check_order() {
  local cmd="$1"
  local file="$REPO_ROOT/skills/$cmd/SKILL.md"

  [ -f "$file" ] || { fail "skills/$cmd/SKILL.md not found"; return; }

  # "fixer" dispatch: agent-flow:fixer OR "Run the fixer agent"
  # Use tail -1 to find the main-path fixer dispatch (not the decomposition sub-path
  # which appears earlier in the file inside the "Subtask execution" section).
  FIXER_LINE=$(grep -in "agent-flow:fixer\|Run the fixer agent" "$file" | tail -1 | cut -d: -f1 || echo 0)
  # "publisher" dispatch: agent-flow:publisher OR "Run the publisher agent"
  PUBLISHER_LINE=$(grep -in "agent-flow:publisher\|Run the publisher agent" "$file" | head -1 | cut -d: -f1 || echo 0)

  # ---- pre-fix must appear before fixer dispatch ----
  PRE_FIX_LINE=$(hook_step_line "$file" "pre-fix")

  if [ "$PRE_FIX_LINE" -gt 0 ] && [ "$FIXER_LINE" -gt 0 ]; then
    if [ "$PRE_FIX_LINE" -lt "$FIXER_LINE" ]; then
      echo "OK: $cmd — pre-fix (line $PRE_FIX_LINE) is before fixer dispatch (line $FIXER_LINE)"
    else
      fail "$cmd — pre-fix hook (line $PRE_FIX_LINE) appears AFTER fixer dispatch (line $FIXER_LINE)"
    fi
  elif [ "$PRE_FIX_LINE" -eq 0 ]; then
    echo "SKIP: $cmd — no pre-fix hook step found, skipping pre-fix order check"
  else
    echo "SKIP: $cmd — no fixer dispatch found, skipping pre-fix order check"
  fi

  # ---- post-fix must appear after fixer dispatch ----
  POST_FIX_LINE=$(hook_step_line "$file" "post-fix")

  if [ "$POST_FIX_LINE" -gt 0 ] && [ "$FIXER_LINE" -gt 0 ]; then
    if [ "$POST_FIX_LINE" -gt "$FIXER_LINE" ]; then
      echo "OK: $cmd — post-fix (line $POST_FIX_LINE) is after fixer dispatch (line $FIXER_LINE)"
    else
      fail "$cmd — post-fix hook (line $POST_FIX_LINE) appears BEFORE fixer dispatch (line $FIXER_LINE)"
    fi
  elif [ "$POST_FIX_LINE" -eq 0 ]; then
    echo "SKIP: $cmd — no post-fix hook step found, skipping post-fix order check"
  else
    echo "SKIP: $cmd — no fixer dispatch found, skipping post-fix order check"
  fi

  # ---- pre-publish must appear before publisher dispatch ----
  PRE_PUBLISH_LINE=$(hook_step_line "$file" "pre-publish")

  if [ "$PRE_PUBLISH_LINE" -gt 0 ] && [ "$PUBLISHER_LINE" -gt 0 ]; then
    if [ "$PRE_PUBLISH_LINE" -lt "$PUBLISHER_LINE" ]; then
      echo "OK: $cmd — pre-publish (line $PRE_PUBLISH_LINE) is before publisher dispatch (line $PUBLISHER_LINE)"
    else
      fail "$cmd — pre-publish hook (line $PRE_PUBLISH_LINE) appears AFTER publisher dispatch (line $PUBLISHER_LINE)"
    fi
  elif [ "$PRE_PUBLISH_LINE" -eq 0 ]; then
    echo "SKIP: $cmd — no pre-publish hook step found, skipping pre-publish order check"
  else
    echo "SKIP: $cmd — no publisher dispatch found, skipping pre-publish order check"
  fi

  # ---- post-publish must appear after publisher dispatch ----
  POST_PUBLISH_LINE=$(hook_step_line "$file" "post-publish")

  if [ "$POST_PUBLISH_LINE" -gt 0 ] && [ "$PUBLISHER_LINE" -gt 0 ]; then
    if [ "$POST_PUBLISH_LINE" -gt "$PUBLISHER_LINE" ]; then
      echo "OK: $cmd — post-publish (line $POST_PUBLISH_LINE) is after publisher dispatch (line $PUBLISHER_LINE)"
    else
      fail "$cmd — post-publish hook (line $POST_PUBLISH_LINE) appears BEFORE publisher dispatch (line $PUBLISHER_LINE)"
    fi
  elif [ "$POST_PUBLISH_LINE" -eq 0 ]; then
    echo "SKIP: $cmd — no post-publish hook step found, skipping post-publish order check"
  else
    echo "SKIP: $cmd — no publisher dispatch found, skipping post-publish order check"
  fi
}

for cmd in fix-bugs implement-feature; do
  echo "--- Checking $cmd ---"
  check_order "$cmd"
done

[ "$FAIL" -eq 0 ] && echo "PASS: all hooks appear in correct order relative to their pipeline anchors"
exit "$FAIL"
