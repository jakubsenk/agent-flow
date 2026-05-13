#!/usr/bin/env bash
# Scenario: NEW-5 (v6.9.1 carry-over Robustness) — pipeline-resumed webhook event documented and wired
# Expected v6.9.1 outcome: PASS once Commit F implements
# Pre-implementation outcome: FAIL (TDD) — pipeline-resumed event not yet defined
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

POST_HOOK="$REPO_ROOT/core/post-publish-hook.md"
RESUME_SKILL="$REPO_ROOT/core/resume-detection.md"

if [ ! -f "$POST_HOOK" ]; then
  echo "FAIL: core/post-publish-hook.md not found" >&2; exit 1
fi
if [ ! -f "$RESUME_SKILL" ]; then
  echo "FAIL: core/resume-detection.md not found" >&2; exit 1
fi

# Assertion 1 (NEW-5): pipeline-resumed event in enumerated event list in Section 4
echo "--- Assertion 1 (NEW-5): 'pipeline-resumed' event in core/post-publish-hook.md Section 4 ---"
if grep -qF '"pipeline-resumed"' "$POST_HOOK"; then
  echo "OK (NEW-5): pipeline-resumed event listed in core/post-publish-hook.md"
else
  fail "NEW-5: core/post-publish-hook.md missing '\"pipeline-resumed\"' in Section 4 event list"
fi

# Assertion 2 (NEW-5): resumed_at field in payload spec
echo "--- Assertion 2 (NEW-5): resumed_at field in pipeline-resumed payload ---"
if grep -qF 'resumed_at' "$POST_HOOK"; then
  echo "OK (NEW-5): resumed_at field in pipeline-resumed payload"
else
  fail "NEW-5: core/post-publish-hook.md missing 'resumed_at' field in pipeline-resumed payload spec"
fi

# Assertion 3 (NEW-5): clarification.answer in payload (first 100 chars, sanitized)
echo "--- Assertion 3 (NEW-5): clarification.answer in pipeline-resumed payload ---"
if grep -qF 'clarification.answer' "$POST_HOOK"; then
  echo "OK (NEW-5): clarification.answer included in pipeline-resumed payload"
else
  fail "NEW-5: core/post-publish-hook.md missing 'clarification.answer' in pipeline-resumed payload"
fi

# Assertion 4 (NEW-5): webhook-curl pattern in core/resume-detection.md
# (resume-detection.md inlines the curl call rather than citing the snippet; accept either)
echo "--- Assertion 4 (NEW-5): webhook-curl pattern in core/resume-detection.md ---"
if grep -qF '@snippet:webhook-curl' "$RESUME_SKILL" || grep -qE '\-\-proto.*http.*https' "$RESUME_SKILL"; then
  echo "OK (NEW-5): core/resume-detection.md has webhook-curl pattern (inline curl or snippet citation)"
else
  fail "NEW-5: core/resume-detection.md missing webhook-curl pattern"
fi

# Assertion 5 (NEW-5): --proto "=http,https" on pipeline-resumed curl in resume-detection
echo "--- Assertion 5 (NEW-5): --proto '=http,https' on pipeline-resumed curl in core/resume-detection.md ---"
if grep -qE '\-\-proto.*http.*https' "$RESUME_SKILL"; then
  echo "OK (NEW-5): --proto '=http,https' on pipeline-resumed webhook curl"
else
  fail "NEW-5: core/resume-detection.md missing '--proto \"=http,https\"' on pipeline-resumed webhook curl"
fi

# Assertion 6 (NEW-5): pipeline-resumed gated on On events config
echo "--- Assertion 6 (NEW-5): pipeline-resumed gated on On events in core/resume-detection.md ---"
if grep -qF 'pipeline-resumed' "$RESUME_SKILL"; then
  echo "OK (NEW-5): pipeline-resumed gate present in core/resume-detection.md"
else
  fail "NEW-5: core/resume-detection.md missing 'pipeline-resumed' gating expression"
fi

# Assertion 7 (REQ-049 NEGATIVE): pipeline-completed MUST NOT fire on resume transition
echo "--- Assertion 7 (REQ-049): pipeline-completed MUST NOT fire on pause/resume transition ---"
FOUND=0
for f in "$POST_HOOK" "$RESUME_SKILL"; do
  if [ -f "$f" ] && grep -qE 'pipeline-completed.*MUST NOT.*paused|MUST NOT.*pipeline-completed.*pause|REQ-049' "$f"; then
    echo "OK (REQ-049): pipeline-completed-on-pause/resume prohibition found in $f"
    FOUND=1; break
  fi
done
if [ "$FOUND" -eq 0 ]; then
  fail "REQ-049: pipeline-completed-on-pause/resume prohibition not documented"
fi

# Assertion 8 (BC invariant): existing events still present in core/post-publish-hook.md
echo "--- Assertion 8 (BC): existing webhook events NOT removed ---"
existing_events=("pipeline-started" "step-completed" "pipeline-completed" "pr-created" "pipeline-paused")
for event in "${existing_events[@]}"; do
  if grep -qF "\"$event\"" "$POST_HOOK"; then
    echo "OK (BC): existing event '$event' still present"
  else
    fail "BC: existing webhook event '$event' removed from core/post-publish-hook.md — BC violation"
  fi
done

# Assertion 9 (NEW-5): docs/reference/config.md Event Tokens table has pipeline-resumed row
echo "--- Assertion 9 (NEW-5): pipeline-resumed in docs/reference/config.md Event Tokens table ---"
CONFIG_REF="$REPO_ROOT/docs/reference/config.md"
if [ -f "$CONFIG_REF" ] && grep -qF 'pipeline-resumed' "$CONFIG_REF"; then
  echo "OK (NEW-5): pipeline-resumed row present in docs/reference/config.md"
else
  fail "NEW-5: docs/reference/config.md missing pipeline-resumed row in Event Tokens table"
fi

# Assertion 10 (NEW-5): docs/reference/automation-config.md On events enum has pipeline-resumed
echo "--- Assertion 10 (NEW-5): pipeline-resumed in docs/reference/automation-config.md On events ---"
AUTO_CONFIG_REF="$REPO_ROOT/docs/reference/automation-config.md"
if [ -f "$AUTO_CONFIG_REF" ] && grep -qF 'pipeline-resumed' "$AUTO_CONFIG_REF"; then
  echo "OK (NEW-5): pipeline-resumed present in docs/reference/automation-config.md On events enum"
else
  fail "NEW-5: docs/reference/automation-config.md missing pipeline-resumed in On events enum"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.1 pipeline-resumed webhook event with payload spec + --proto + snippet citation + REQ-049 invariant"
fi
exit "$FAIL"
