#!/usr/bin/env bash
# Test: v6.4.4 Connectivity Diagnostics Hardening — visible tests T1-T12
# Validates: bare path migration (AC-1..5), error_type in mcp-detection (AC-6..11),
#            Step 10 TLS treatment (AC-12..16)
# Coverage: 19 ACs across 12 test groups
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
SKILL="$REPO_ROOT/skills/check-setup/SKILL.md"
MCP_DETECTION="$REPO_ROOT/core/mcp-detection.md"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# Guard: verify key source files exist
for f in "$SKILL" "$MCP_DETECTION" \
          "$REPO_ROOT/skills/onboard/SKILL.md" \
          "$REPO_ROOT/skills/scaffold/SKILL.md" \
          "$REPO_ROOT/skills/setup-mcp/SKILL.md"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: required file not found: $f"
    exit 1
  fi
done

# -----------------------------------------------------------------------
# T1 (AC-2): No bare docs/reference/trackers.md as direct Read instruction
# -----------------------------------------------------------------------
echo "--- T1 (AC-2): No bare trackers.md direct Read in skills/core ---"

# Search onboard, scaffold, setup-mcp for bare path references that are not inside
# a resolution/path-note/Glob block.
bare_refs=$(grep -rn 'docs/reference/trackers\.md' \
    "$REPO_ROOT/skills/onboard/SKILL.md" \
    "$REPO_ROOT/skills/scaffold/SKILL.md" \
    "$REPO_ROOT/skills/setup-mcp/SKILL.md" \
  | grep -v '{trackers_md_path}' \
  | grep -v 'Path note' \
  | grep -v 'Glob' \
  | grep -v 'last resort' \
  | grep -v 'fallback' \
  || true)

if [ -z "$bare_refs" ]; then
  echo "OK (AC-2): No bare trackers.md references found in onboard/scaffold/setup-mcp"
else
  fail "AC-2: Bare trackers.md references remain in skill files:
$bare_refs"
fi

# core/mcp-detection.md must have exactly 1 occurrence (the inline table header, guarded)
mcp_count=$(grep -c 'docs/reference/trackers\.md' "$MCP_DETECTION" || true)
if [ "$mcp_count" -eq 1 ]; then
  echo "OK (AC-2): core/mcp-detection.md has exactly 1 trackers.md reference (inline table, guarded)"
else
  fail "AC-2: core/mcp-detection.md trackers.md references: expected 1, got $mcp_count"
fi

# -----------------------------------------------------------------------
# T2 (AC-1): Path-note blockquote in each of the 4 affected files
# -----------------------------------------------------------------------
echo "--- T2 (AC-1): Path-note blockquote in all 4 affected files ---"

PATH_NOTE_FILES=(
  "skills/onboard/SKILL.md"
  "skills/scaffold/SKILL.md"
  "skills/setup-mcp/SKILL.md"
  "core/mcp-detection.md"
)
for f in "${PATH_NOTE_FILES[@]}"; do
  if grep -q '> \*\*Path note:\*\*' "$REPO_ROOT/$f"; then
    echo "OK (AC-1): Path-note blockquote present in $f"
  else
    fail "AC-1: Missing '> **Path note:**' blockquote in $f"
  fi
done

# -----------------------------------------------------------------------
# T3 (AC-3): Resolve-once reuse pattern — 1 Glob block, multiple uses
# -----------------------------------------------------------------------
echo "--- T3 (AC-3): Resolve-once reuse in onboard and scaffold ---"

# onboard: exactly 1 Glob resolution block, at least 6 uses of {trackers_md_path}
onboard_globs=$(grep -c 'Glob.*\.claude/plugins.*trackers' "$REPO_ROOT/skills/onboard/SKILL.md" || true)
onboard_uses=$(grep -c '{trackers_md_path}' "$REPO_ROOT/skills/onboard/SKILL.md" || true)
if [ "$onboard_globs" -eq 1 ] && [ "$onboard_uses" -ge 6 ]; then
  echo "OK (AC-3): onboard — 1 Glob resolution block, $onboard_uses uses of {trackers_md_path} (>= 6)"
else
  fail "AC-3: onboard resolve-once pattern violation (glob_blocks=$onboard_globs expected 1, uses=$onboard_uses expected >=6)"
fi

# scaffold: exactly 1 Glob resolution block, at least 4 uses of {trackers_md_path}
scaffold_globs=$(grep -c 'Glob.*\.claude/plugins.*trackers' "$REPO_ROOT/skills/scaffold/SKILL.md" || true)
scaffold_uses=$(grep -c '{trackers_md_path}' "$REPO_ROOT/skills/scaffold/SKILL.md" || true)
if [ "$scaffold_globs" -eq 1 ] && [ "$scaffold_uses" -ge 4 ]; then
  echo "OK (AC-3): scaffold — 1 Glob resolution block, $scaffold_uses uses of {trackers_md_path} (>= 4)"
else
  fail "AC-3: scaffold resolve-once pattern violation (glob_blocks=$scaffold_globs expected 1, uses=$scaffold_uses expected >=4)"
fi

# -----------------------------------------------------------------------
# T4 (AC-5): 3-layer Glob resolution pattern in each affected skill file
# -----------------------------------------------------------------------
echo "--- T4 (AC-5): 3-layer Glob resolution in onboard/scaffold/setup-mcp ---"

GLOB_FILES=(
  "skills/onboard/SKILL.md"
  "skills/scaffold/SKILL.md"
  "skills/setup-mcp/SKILL.md"
)
for f in "${GLOB_FILES[@]}"; do
  # Layer 1: .claude/plugins/** (plugin install path)
  if grep -q '\.claude/plugins/\*\*/docs/reference/trackers\.md' "$REPO_ROOT/$f"; then
    echo "OK (AC-5): $f — Layer 1 (.claude/plugins/**) present"
  else
    fail "AC-5: $f missing Layer 1 Glob pattern (.claude/plugins/**/docs/reference/trackers.md)"
  fi
  # Layer 2: **/ wildcard (broader search)
  if grep -q '\*\*/docs/reference/trackers\.md' "$REPO_ROOT/$f"; then
    echo "OK (AC-5): $f — Layer 2 (**/) present"
  else
    fail "AC-5: $f missing Layer 2 Glob pattern (**/docs/reference/trackers.md)"
  fi
done

# -----------------------------------------------------------------------
# T5 (AC-6): error_type field in mcp-detection.md Output Contract
# -----------------------------------------------------------------------
echo "--- T5 (AC-6): error_type field in core/mcp-detection.md Output Contract ---"

if grep -q 'error_type' "$MCP_DETECTION"; then
  echo "OK (AC-6): error_type field present in mcp-detection.md"
else
  fail "AC-6: error_type field missing from core/mcp-detection.md"
fi

# All 5 enum values must be mentioned
for v in '"tls"' '"auth"' '"not_found"' '"timeout"' '"unknown"'; do
  if grep -q "$v" "$MCP_DETECTION"; then
    echo "OK (AC-6): enum value $v present in mcp-detection.md"
  else
    fail "AC-6: enum value $v missing from core/mcp-detection.md"
  fi
done

# null case for success (mcp_available: true)
if grep -qE 'null.*mcp_available|mcp_available.*true.*null|error_type.*null' "$MCP_DETECTION"; then
  echo "OK (AC-6): null case for mcp_available=true documented in mcp-detection.md"
else
  fail "AC-6: null case for error_type when mcp_available is true not documented in mcp-detection.md"
fi

# -----------------------------------------------------------------------
# T6 (AC-7): Classification Reference section with priority ordering
# -----------------------------------------------------------------------
echo "--- T6 (AC-7): Classification Reference section in mcp-detection.md ---"

if grep -q '### Classification Reference' "$MCP_DETECTION"; then
  echo "OK (AC-7): '### Classification Reference' section present in mcp-detection.md"
else
  fail "AC-7: '### Classification Reference' section missing from core/mcp-detection.md"
fi

if grep -qE 'first match wins|priority order' "$MCP_DETECTION"; then
  echo "OK (AC-7): Priority-order semantics documented in mcp-detection.md"
else
  fail "AC-7: 'first match wins' / 'priority order' semantics missing from core/mcp-detection.md"
fi

if grep -q '| Priority | error_type | Trigger patterns |' "$MCP_DETECTION"; then
  echo "OK (AC-7): Classification Reference table header present"
else
  fail "AC-7: Classification Reference table header '| Priority | error_type | Trigger patterns |' missing from core/mcp-detection.md"
fi

# -----------------------------------------------------------------------
# T7 (AC-8, AC-9): TLS and auth pattern parity with check-setup Step 9
# -----------------------------------------------------------------------
echo "--- T7 (AC-8, AC-9): TLS and auth patterns match check-setup Step 9 ---"

# AC-8: 8 TLS patterns
TLS_PATTERNS=(
  "UNABLE_TO_VERIFY_LEAF_SIGNATURE"
  "CERT_UNTRUSTED"
  "SELF_SIGNED_CERT"
  "self signed certificate"
  "certificate verify failed"
  "ERR_TLS_"
  "DEPTH_ZERO_SELF_SIGNED_CERT"
  "unable to get local issuer certificate"
)
for p in "${TLS_PATTERNS[@]}"; do
  if grep -q "$p" "$MCP_DETECTION"; then
    echo "OK (AC-8): TLS pattern '$p' present in mcp-detection.md"
  else
    fail "AC-8: TLS pattern '$p' missing from core/mcp-detection.md (must match check-setup Step 9)"
  fi
done

# AC-9: 6 auth patterns
AUTH_PATTERNS=("401" "403" "unauthorized" "forbidden" "invalid token" "authentication")
for p in "${AUTH_PATTERNS[@]}"; do
  if grep -q "$p" "$MCP_DETECTION"; then
    echo "OK (AC-9): Auth pattern '$p' present in mcp-detection.md"
  else
    fail "AC-9: Auth pattern '$p' missing from core/mcp-detection.md (must match check-setup Step 9)"
  fi
done

# -----------------------------------------------------------------------
# T8 (AC-10): not_found and timeout patterns in Classification Reference
# -----------------------------------------------------------------------
echo "--- T8 (AC-10): not_found and timeout patterns in mcp-detection.md ---"

NOT_FOUND_PATTERNS=("404" "ENOTFOUND" "EAI_AGAIN")
for p in "${NOT_FOUND_PATTERNS[@]}"; do
  if grep -q "$p" "$MCP_DETECTION"; then
    echo "OK (AC-10): not_found pattern '$p' present in mcp-detection.md"
  else
    fail "AC-10: not_found pattern '$p' missing from core/mcp-detection.md"
  fi
done

TIMEOUT_PATTERNS=("ETIMEDOUT" "ECONNREFUSED" "ECONNRESET")
for p in "${TIMEOUT_PATTERNS[@]}"; do
  if grep -q "$p" "$MCP_DETECTION"; then
    echo "OK (AC-10): timeout pattern '$p' present in mcp-detection.md"
  else
    fail "AC-10: timeout pattern '$p' missing from core/mcp-detection.md"
  fi
done

# -----------------------------------------------------------------------
# Implicit T (AC-11): Cross-reference to check-setup Step 9 in mcp-detection
# -----------------------------------------------------------------------
echo "--- T (AC-11): Cross-reference to check-setup Step 9 in mcp-detection.md ---"

if grep -qE 'check-setup.*Step 9|Step 9.*check-setup|skills/check-setup/SKILL\.md.*Step 9' "$MCP_DETECTION"; then
  echo "OK (AC-11): Cross-reference to check-setup Step 9 present in mcp-detection.md"
else
  fail "AC-11: Cross-reference to 'check-setup Step 9' missing from core/mcp-detection.md"
fi

# -----------------------------------------------------------------------
# Helper: extract Step 10 region (used by T9-T12)
# -----------------------------------------------------------------------
step10_start=$(grep -n '^10\.' "$SKILL" | head -1 | cut -d: -f1 || true)
block4_start=$(grep -n 'Block 4' "$SKILL" | head -1 | cut -d: -f1 || true)

if [ -z "$step10_start" ] || [ -z "$block4_start" ]; then
  fail "T9-T12 setup: Cannot locate Step 10 or Block 4 boundary in $SKILL (step10_start=$step10_start, block4_start=$block4_start)"
  echo "FAIL: skipping T9-T12 region checks due to missing markers"
  exit "$FAIL"
fi

step10_region=$(sed -n "${step10_start},${block4_start}p" "$SKILL")

# -----------------------------------------------------------------------
# T9 (AC-12): Step 10 TLS error classification — branch present, before auth
# -----------------------------------------------------------------------
echo "--- T9 (AC-12): TLS error classification branch in Step 10 ---"

if echo "$step10_region" | grep -q 'UNABLE_TO_VERIFY_LEAF_SIGNATURE'; then
  echo "OK (AC-12): TLS pattern UNABLE_TO_VERIFY_LEAF_SIGNATURE present in Step 10"
else
  fail "AC-12: TLS pattern UNABLE_TO_VERIFY_LEAF_SIGNATURE missing from Step 10"
fi

if echo "$step10_region" | grep -q 'TLS error'; then
  echo "OK (AC-12): 'TLS error' branch label present in Step 10"
else
  fail "AC-12: 'TLS error' branch label missing from Step 10"
fi

# TLS branch must appear before auth branch in Step 10
tls_line=$(echo "$step10_region" | grep -n 'TLS error' | head -1 | cut -d: -f1 || true)
auth_line=$(echo "$step10_region" | grep -n 'Auth error' | head -1 | cut -d: -f1 || true)
if [ -n "$tls_line" ] && [ -n "$auth_line" ]; then
  if [ "$tls_line" -lt "$auth_line" ]; then
    echo "OK (AC-12): TLS branch (line $tls_line in region) appears before auth branch (line $auth_line in region)"
  else
    fail "AC-12: Auth branch (line $auth_line) appears before TLS branch (line $tls_line) in Step 10 — TLS must be classified first"
  fi
else
  fail "AC-12: Could not determine branch ordering (tls_line='$tls_line', auth_line='$auth_line') in Step 10"
fi

# -----------------------------------------------------------------------
# T10 (AC-13): Step 10 curl probe logic with env-var URL derivation
# -----------------------------------------------------------------------
echo "--- T10 (AC-13): Step 10 curl probe with env-var URL derivation ---"

if echo "$step10_region" | grep -q 'curl'; then
  echo "OK (AC-13): curl command present in Step 10"
else
  fail "AC-13: curl command missing from Step 10"
fi

if echo "$step10_region" | grep -q 'which curl'; then
  echo "OK (AC-13): curl availability guard (which curl) present in Step 10"
else
  fail "AC-13: curl availability guard (which curl) missing from Step 10"
fi

if echo "$step10_region" | grep -qE 'sc_base_url|env.*block|env block'; then
  echo "OK (AC-13): env-var URL derivation (sc_base_url / env block) present in Step 10"
else
  fail "AC-13: env-var URL derivation (sc_base_url or env block reference) missing from Step 10"
fi

if echo "$step10_region" | grep -qE 'well-known|server-github|https://github\.com'; then
  echo "OK (AC-13): Well-known host fallback (e.g. github.com) present in Step 10"
else
  fail "AC-13: Well-known host fallback missing from Step 10 (expected well-known / github.com reference)"
fi

if echo "$step10_region" | grep -qE 'skip.*probe|skip the curl probe|skip probe'; then
  echo "OK (AC-13): Skip-probe path present for when URL cannot be derived"
else
  fail "AC-13: Skip-probe graceful degradation missing from Step 10 (needed when no URL derivable)"
fi

# -----------------------------------------------------------------------
# T11 (AC-14): Step 10 NODE_OPTIONS hint — at least 4 occurrences
# -----------------------------------------------------------------------
echo "--- T11 (AC-14): NODE_OPTIONS hint in Step 10 (>= 4 occurrences) ---"

step10_node_opts=$(echo "$step10_region" | grep -c 'NODE_OPTIONS' || true)
if [ "$step10_node_opts" -ge 4 ]; then
  echo "OK (AC-14): NODE_OPTIONS appears $step10_node_opts times in Step 10 (>= 4; covers curl-success, curl-failure, curl-absent, no-URL-derivable)"
else
  fail "AC-14: NODE_OPTIONS appears only $step10_node_opts time(s) in Step 10 — expected >= 4 (curl-success, curl-failure, curl-absent, no-URL variants)"
fi

# -----------------------------------------------------------------------
# T12 (AC-16): Step 10 error messages say "Source control", not "Issue tracker"
# -----------------------------------------------------------------------
echo "--- T12 (AC-16): Step 10 references 'Source control', not 'Issue tracker' ---"

if echo "$step10_region" | grep -q 'Source control'; then
  echo "OK (AC-16): 'Source control' found in Step 10 messages"
else
  fail "AC-16: 'Source control' not found in Step 10 — messages must reference source control, not issue tracker"
fi

# No [FAIL] or [WARN] output lines should mention "Issue tracker" inside Step 10
issue_tracker_in_messages=$(echo "$step10_region" | grep -E '\[FAIL\]|\[WARN\]' | grep -i 'issue tracker' || true)
if [ -z "$issue_tracker_in_messages" ]; then
  echo "OK (AC-16): No 'Issue tracker' phrase found in Step 10 output messages"
else
  fail "AC-16: 'Issue tracker' found in Step 10 output messages (should say 'Source control'):
$issue_tracker_in_messages"
fi

# -----------------------------------------------------------------------
# Additional coverage: AC-4 — file-specific [WARN] fallback for missing trackers.md
# -----------------------------------------------------------------------
echo "--- T (AC-4): [WARN] fallback when trackers.md not found in each skill ---"

if grep -qE '\[WARN\].*trackers\.md.*not found|trackers\.md not found.*\[WARN\]|not found.*built-in defaults' \
    "$REPO_ROOT/skills/onboard/SKILL.md"; then
  echo "OK (AC-4): onboard — [WARN] fallback for missing trackers.md present"
else
  fail "AC-4: onboard/SKILL.md missing [WARN] fallback for trackers.md not found"
fi

if grep -qE '\[WARN\].*trackers\.md.*not found|trackers\.md not found.*\[WARN\]|not found.*built-in defaults' \
    "$REPO_ROOT/skills/scaffold/SKILL.md"; then
  echo "OK (AC-4): scaffold — [WARN] fallback for missing trackers.md present"
else
  fail "AC-4: skills/scaffold/SKILL.md missing [WARN] fallback for trackers.md not found"
fi

if grep -qE 'not found.*hardcoded|not found.*default|If not found' \
    "$REPO_ROOT/skills/setup-mcp/SKILL.md"; then
  echo "OK (AC-4): setup-mcp — fallback message for missing trackers.md present"
else
  fail "AC-4: skills/setup-mcp/SKILL.md missing fallback message when trackers.md not found"
fi

# -----------------------------------------------------------------------
# Additional coverage: AC-15 — Step 10 retains existing error branches
# -----------------------------------------------------------------------
echo "--- T (AC-15): Step 10 retains auth/404/WARN/catch-all branches ---"

if echo "$step10_region" | grep -qE '401/403|Auth error'; then
  echo "OK (AC-15): Auth (401/403) branch present in Step 10"
else
  fail "AC-15: Auth (401/403 / Auth error) branch missing from Step 10"
fi

if echo "$step10_region" | grep -qE '404|Not found'; then
  echo "OK (AC-15): Not-found (404) branch present in Step 10"
else
  fail "AC-15: Not-found (404) branch missing from Step 10"
fi

if echo "$step10_region" | grep -q '\[WARN\]'; then
  echo "OK (AC-15): [WARN] tool-not-found branch present in Step 10"
else
  fail "AC-15: [WARN] tool-not-found branch missing from Step 10"
fi

if echo "$step10_region" | grep -q 'repository:read'; then
  echo "OK (AC-15): Per-platform scope name 'repository:read' present in Step 10"
else
  fail "AC-15: Per-platform scope name 'repository:read' missing from Step 10"
fi

if echo "$step10_region" | grep -q 'Any other error'; then
  echo "OK (AC-15): Catch-all 'Any other error' branch present in Step 10"
else
  fail "AC-15: Catch-all 'Any other error' branch missing from Step 10"
fi

# -----------------------------------------------------------------------
# Final result
# -----------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.4.4 diagnostics hardening — bare path migration (AC-1..5), error_type classification (AC-6..11), Step 10 TLS treatment (AC-12..16)"
fi
exit "$FAIL"
