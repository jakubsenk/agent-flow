# Formal Verification Criteria: v6.4.4 Connectivity Diagnostics Hardening

Version: v6.4.4 (PATCH)
Date: 2026-04-11

Machine-verifiable pass/fail criteria for all 19 acceptance criteria.

---

## Test Execution Environment

- **REPO_ROOT:** `$(cd "$(dirname "$0")/../../" && pwd)` (from any test in `tests/scenarios/`)
- **All file paths** are relative to REPO_ROOT unless noted otherwise
- **Exit code convention:** 0 = all pass, 1 = any fail

---

## AC-1: Path-note blockquote in all 4 files

**Check type:** grep presence

```bash
FILES=(
  "skills/onboard/SKILL.md"
  "skills/scaffold/SKILL.md"
  "skills/init/SKILL.md"
  "core/mcp-detection.md"
)
for f in "${FILES[@]}"; do
  grep -q '> \*\*Path note:\*\*' "$REPO_ROOT/$f"
done
```

**Pass:** All 4 files contain `> **Path note:**`
**Fail:** Any file missing the blockquote

---

## AC-2: No bare trackers.md as direct Read instruction

**Check type:** negative grep (expect zero matches)

```bash
# Search in skill and core files only (exclude docs, tests, examples, CHANGELOG, README, check-setup)
grep -rn 'docs/reference/trackers\.md' \
  "$REPO_ROOT/skills/onboard/" \
  "$REPO_ROOT/skills/scaffold/" \
  "$REPO_ROOT/skills/init/" \
  | grep -v '{trackers_md_path}' \
  | grep -v 'Path note' \
  | grep -v 'Glob' \
  | grep -v 'last resort' \
  | grep -v 'fallback'
```

**Pass:** Zero output lines (no bare references remain in onboard, scaffold, init)
**Fail:** Any output line indicates a remaining bare reference

**Exception:** `core/mcp-detection.md` line 19 is allowed because the inline table reference is guarded by the path-note blockquote. Verify separately:

```bash
grep -c 'docs/reference/trackers\.md' "$REPO_ROOT/core/mcp-detection.md"
```

**Pass:** Exactly 1 occurrence (the inline table header in Process step 1)
**Fail:** More than 1 occurrence or 0 occurrences

---

## AC-3: Resolve-once reuse pattern

**Check type:** count-based grep

```bash
# onboard: exactly 1 Glob resolution block, at least 6 uses of {trackers_md_path}
onboard_globs=$(grep -c 'Glob.*\.claude/plugins.*trackers' "$REPO_ROOT/skills/onboard/SKILL.md" || true)
onboard_uses=$(grep -c '{trackers_md_path}' "$REPO_ROOT/skills/onboard/SKILL.md" || true)

# scaffold: exactly 1 Glob resolution block, at least 4 uses of {trackers_md_path}
scaffold_globs=$(grep -c 'Glob.*\.claude/plugins.*trackers' "$REPO_ROOT/skills/scaffold/SKILL.md" || true)
scaffold_uses=$(grep -c '{trackers_md_path}' "$REPO_ROOT/skills/scaffold/SKILL.md" || true)
```

**Pass:** `onboard_globs == 1 && onboard_uses >= 6 && scaffold_globs == 1 && scaffold_uses >= 4`
**Fail:** Any count outside expected range

---

## AC-4: File-specific [WARN] fallback

**Check type:** grep presence per file

```bash
grep -q '\[WARN\].*trackers\.md.*not found\|trackers\.md not found.*\[WARN\]\|not found.*built-in defaults' "$REPO_ROOT/skills/onboard/SKILL.md"
grep -q '\[WARN\].*trackers\.md.*not found\|trackers\.md not found.*\[WARN\]\|not found.*built-in defaults' "$REPO_ROOT/skills/scaffold/SKILL.md"
grep -q 'not found.*hardcoded\|not found.*default\|If not found' "$REPO_ROOT/skills/init/SKILL.md"
```

**Pass:** All 3 files contain a fallback message
**Fail:** Any file missing the fallback

---

## AC-5: Glob resolution pattern matches check-setup

**Check type:** pattern presence per file

```bash
for f in skills/onboard/SKILL.md skills/scaffold/SKILL.md skills/init/SKILL.md; do
  # Layer 1: .claude/plugins/**
  grep -q '\.claude/plugins/\*\*/docs/reference/trackers\.md' "$REPO_ROOT/$f"
  # Layer 2: **/docs/reference/trackers.md
  grep -q '\*\*/docs/reference/trackers\.md' "$REPO_ROOT/$f"
done
```

**Pass:** All 3 files contain both layer 1 and layer 2 patterns
**Fail:** Any file missing either layer

---

## AC-6: error_type field in Output Contract

**Check type:** grep presence + content

```bash
grep -q 'error_type' "$REPO_ROOT/core/mcp-detection.md"

# Verify all 5 enum values are mentioned
for v in '"tls"' '"auth"' '"not_found"' '"timeout"' '"unknown"'; do
  grep -q "$v" "$REPO_ROOT/core/mcp-detection.md"
done

# Verify null case
grep -q 'null.*when.*mcp_available.*true\|null when mcp_available is true' "$REPO_ROOT/core/mcp-detection.md"
```

**Pass:** `error_type` present, all 5 values present, null case documented
**Fail:** Any missing element

---

## AC-7: Classification Reference section

**Check type:** section heading presence + semantics keyword

```bash
grep -q '### Classification Reference' "$REPO_ROOT/core/mcp-detection.md"
grep -q 'first match wins\|priority order' "$REPO_ROOT/core/mcp-detection.md"
grep -q '| Priority | error_type | Trigger patterns |' "$REPO_ROOT/core/mcp-detection.md"
```

**Pass:** Section heading, priority semantics, and table header all present
**Fail:** Any missing

---

## AC-8: TLS patterns match check-setup Step 9

**Check type:** pattern-by-pattern grep in mcp-detection.md

```bash
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
  grep -q "$p" "$REPO_ROOT/core/mcp-detection.md"
done
```

**Pass:** All 8 TLS patterns present in `core/mcp-detection.md`
**Fail:** Any pattern missing

---

## AC-9: Auth patterns match check-setup Step 9

**Check type:** pattern-by-pattern grep

```bash
AUTH_PATTERNS=("401" "403" "unauthorized" "forbidden" "invalid token" "authentication")
for p in "${AUTH_PATTERNS[@]}"; do
  grep -q "$p" "$REPO_ROOT/core/mcp-detection.md"
done
```

**Pass:** All 6 auth patterns present
**Fail:** Any pattern missing

---

## AC-10: not_found and timeout patterns

**Check type:** pattern presence

```bash
NOT_FOUND_PATTERNS=("404" "ENOTFOUND" "EAI_AGAIN")
TIMEOUT_PATTERNS=("ETIMEDOUT" "ECONNREFUSED" "ECONNRESET")

for p in "${NOT_FOUND_PATTERNS[@]}"; do
  grep -q "$p" "$REPO_ROOT/core/mcp-detection.md"
done
for p in "${TIMEOUT_PATTERNS[@]}"; do
  grep -q "$p" "$REPO_ROOT/core/mcp-detection.md"
done
```

**Pass:** All 6 patterns present
**Fail:** Any pattern missing

---

## AC-11: Callers can delegate to error_type

**Check type:** cross-reference note presence

```bash
grep -q 'check-setup.*Step 9\|Step 9.*check-setup\|skills/check-setup/SKILL\.md.*Step 9' "$REPO_ROOT/core/mcp-detection.md"
```

**Pass:** Cross-reference note to check-setup Step 9 exists in mcp-detection.md
**Fail:** No cross-reference found

---

## AC-12: Step 10 TLS error classification branch

**Check type:** region extraction + pattern presence + ordering

```bash
SKILL="$REPO_ROOT/skills/check-setup/SKILL.md"
step10_start=$(grep -n '^10\.' "$SKILL" | head -1 | cut -d: -f1)
block4_start=$(grep -n 'Block 4' "$SKILL" | head -1 | cut -d: -f1)
step10_region=$(sed -n "${step10_start},${block4_start}p" "$SKILL")

# TLS patterns present in Step 10
echo "$step10_region" | grep -q 'UNABLE_TO_VERIFY_LEAF_SIGNATURE'
echo "$step10_region" | grep -q 'TLS error'

# TLS before Auth ordering
tls_line=$(echo "$step10_region" | grep -n 'TLS error' | head -1 | cut -d: -f1)
auth_line=$(echo "$step10_region" | grep -n 'Auth error' | head -1 | cut -d: -f1)
[ "$tls_line" -lt "$auth_line" ]
```

**Pass:** TLS patterns present in Step 10, TLS branch appears before auth branch
**Fail:** Missing patterns or wrong ordering

---

## AC-13: Step 10 curl probe for SC URL

**Check type:** region extraction + keyword presence

```bash
SKILL="$REPO_ROOT/skills/check-setup/SKILL.md"
step10_start=$(grep -n '^10\.' "$SKILL" | head -1 | cut -d: -f1)
block4_start=$(grep -n 'Block 4' "$SKILL" | head -1 | cut -d: -f1)
step10_region=$(sed -n "${step10_start},${block4_start}p" "$SKILL")

echo "$step10_region" | grep -q 'curl'
echo "$step10_region" | grep -q 'which curl'
echo "$step10_region" | grep -qE 'sc_base_url|env.*block|env block'
echo "$step10_region" | grep -qE 'well-known|server-github|https://github\.com'
echo "$step10_region" | grep -q 'skip.*probe\|skip the curl probe\|skip probe'
```

**Pass:** curl command, curl availability check, env-var derivation, well-known host fallback, and skip-probe path all present
**Fail:** Any missing element

---

## AC-14: Step 10 NODE_OPTIONS hint

**Check type:** count in Step 10 region

```bash
SKILL="$REPO_ROOT/skills/check-setup/SKILL.md"
step10_start=$(grep -n '^10\.' "$SKILL" | head -1 | cut -d: -f1)
block4_start=$(grep -n 'Block 4' "$SKILL" | head -1 | cut -d: -f1)
step10_node_opts=$(sed -n "${step10_start},${block4_start}p" "$SKILL" | grep -c 'NODE_OPTIONS' || true)

[ "$step10_node_opts" -ge 4 ]
```

**Pass:** NODE_OPTIONS appears at least 4 times within Step 10 (curl-absent, curl-success, curl-failure, no-URL-derivable variants). The 5th occurrence in catch-all is a bonus.
**Fail:** Fewer than 4 occurrences

---

## AC-15: Step 10 retains existing error branches

**Check type:** keyword presence in Step 10 region

```bash
SKILL="$REPO_ROOT/skills/check-setup/SKILL.md"
step10_start=$(grep -n '^10\.' "$SKILL" | head -1 | cut -d: -f1)
block4_start=$(grep -n 'Block 4' "$SKILL" | head -1 | cut -d: -f1)
step10_region=$(sed -n "${step10_start},${block4_start}p" "$SKILL")

echo "$step10_region" | grep -qE '401/403|Auth error'
echo "$step10_region" | grep -qE '404|Not found'
echo "$step10_region" | grep -q '\[WARN\]'
echo "$step10_region" | grep -q 'repository:read'
echo "$step10_region" | grep -q 'Any other error'
```

**Pass:** Auth (401/403), not-found (404), tool-not-found ([WARN]), per-platform scope (repository:read), and catch-all all present
**Fail:** Any branch missing

---

## AC-16: Step 10 messages reference "Source control"

**Check type:** positive + negative grep in Step 10 region

```bash
SKILL="$REPO_ROOT/skills/check-setup/SKILL.md"
step10_start=$(grep -n '^10\.' "$SKILL" | head -1 | cut -d: -f1)
block4_start=$(grep -n 'Block 4' "$SKILL" | head -1 | cut -d: -f1)
step10_region=$(sed -n "${step10_start},${block4_start}p" "$SKILL")

# Must contain "Source control"
echo "$step10_region" | grep -q 'Source control'

# Must NOT contain "Issue tracker" in message text (output lines starting with [FAIL] or [WARN])
! echo "$step10_region" | grep -E '\[FAIL\]|\[WARN\]' | grep -qi 'issue tracker'
```

**Pass:** "Source control" present and no "Issue tracker" in Step 10 output messages
**Fail:** Missing "Source control" or presence of "Issue tracker" in messages

---

## AC-17: Backward compatibility

**Check type:** diff inspection (post-implementation)

```bash
# CLAUDE.md must not be modified
! git diff --name-only HEAD | grep -q '^CLAUDE\.md$'

# No new required keys in any Input Contract
! git diff HEAD -- core/ | grep -A5 '## Input Contract' | grep '^+' | grep -v '+++' | grep -v '^+$' | grep -q .
```

**Pass:** CLAUDE.md not in diff, no Input Contract additions
**Fail:** CLAUDE.md modified or Input Contract has additions

---

## AC-18: Existing test check-setup-improvements.sh passes

**Check type:** test execution

```bash
bash "$REPO_ROOT/tests/scenarios/check-setup-improvements.sh"
```

**Pass:** Exit code 0, output contains "PASS"
**Fail:** Non-zero exit code

**Specific sub-check for AC-11 of the existing test (most likely to be affected):**
The test at lines 183-195 checks:
1. `[WARN]` + `skip` present in check-setup/SKILL.md
2. No bare `Read docs/reference/trackers.md` in check-setup/SKILL.md

These assertions must still hold because the v6.4.4 changes to check-setup only modify Step 10 (lines 98-104), not Step 3a (lines 32-38) where the path resolution lives.

---

## AC-19: No new required config keys

**Check type:** negative diff check on config-related sections

```bash
# No changes to CLAUDE.md "Config Contract" section
! git diff HEAD -- CLAUDE.md | grep -q .

# No new required key in core/mcp-detection.md Input Contract
! git diff HEAD -- core/mcp-detection.md | sed -n '/## Input Contract/,/## Process/p' | grep '^+' | grep -v '+++' | grep -q .

# Verify error_type is in OUTPUT (not input) contract
git diff HEAD -- core/mcp-detection.md | grep '^+.*error_type' | head -1 | grep -q 'Output Contract\|Classification\|error_type.*string or null'
```

**Pass:** No Input Contract changes, error_type only in Output Contract / Failure Handling
**Fail:** Input Contract modified or error_type in wrong section

---

## Test File Expectations

### New test file: `tests/scenarios/connectivity-diagnostics-hardening.sh`

This test should validate all 19 ACs. Recommended structure:

```
T1: Bare path migration (AC-1 through AC-5)
T2: error_type classification (AC-6 through AC-11)
T3: Step 10 TLS treatment (AC-12 through AC-16)
T4: Cross-cutting (AC-17 through AC-19)
```

### Existing test file: `tests/scenarios/check-setup-improvements.sh`

**Expected result:** All existing assertions pass unchanged. The Step 10 replacement does not affect any of the Step 3a/Step 7/Step 9 regions that existing tests validate.

**Potential regression point:** The NODE_OPTIONS count test (AC-3, line 47-51) expects `>= 3` occurrences. After v6.4.4, Step 10 adds 5 more NODE_OPTIONS occurrences (4 in TLS sub-branches + 1 in catch-all), bringing the total from ~4 to ~9. The `>= 3` assertion will still pass.

### Existing test file: `tests/scenarios/check-setup-edge-cases.sh`

**Expected result:** All assertions pass unchanged.

**Potential regression point:** Edge case 4 (lines 69-91) checks that Step 7 does not re-Glob for trackers.md. The v6.4.4 changes do not add any Glob to Steps 7-10, so the count remains at 1 (Step 3a only). The assertion will still pass.

---

## Summary Matrix

| AC | Check type | Target file(s) | Expected result |
|----|-----------|----------------|-----------------|
| AC-1 | grep presence | onboard, scaffold, init, mcp-detection | `> **Path note:**` in all 4 |
| AC-2 | negative grep | onboard, scaffold, init | zero bare refs |
| AC-3 | count grep | onboard (1 glob, 6+ uses), scaffold (1 glob, 4+ uses) | exact counts |
| AC-4 | grep presence | onboard, scaffold, init | `[WARN]` fallback in all 3 |
| AC-5 | grep presence | onboard, scaffold, init | 3-layer Glob in all 3 |
| AC-6 | grep presence + content | mcp-detection | error_type + 5 enum values |
| AC-7 | section heading grep | mcp-detection | Classification Reference present |
| AC-8 | pattern grep | mcp-detection | 8 TLS patterns |
| AC-9 | pattern grep | mcp-detection | 6 auth patterns |
| AC-10 | pattern grep | mcp-detection | not_found + timeout patterns |
| AC-11 | cross-ref grep | mcp-detection | Step 9 cross-reference |
| AC-12 | region extraction + ordering | check-setup | TLS branch in Step 10, before auth |
| AC-13 | region extraction + keywords | check-setup | curl + env-var + well-known + skip |
| AC-14 | count in region | check-setup | NODE_OPTIONS >= 4 in Step 10 |
| AC-15 | keyword presence | check-setup | auth + 404 + [WARN] + catch-all in Step 10 |
| AC-16 | positive + negative grep | check-setup | "Source control" yes, "Issue tracker" no |
| AC-17 | diff inspection | CLAUDE.md, core/ Input Contracts | no modifications |
| AC-18 | test execution | check-setup-improvements.sh | exit 0 |
| AC-19 | diff inspection | mcp-detection Input Contract | no input changes |
