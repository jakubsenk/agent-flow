# Requirements Specification: v6.4.4 Connectivity Diagnostics Hardening

Version: v6.4.4 (PATCH)
Date: 2026-04-11
Scope: 3 work items, 19 acceptance criteria, 0 config contract changes

---

## Item 1: Bare Path Migration (trackers.md)

### REQ-1: Glob-first resolution in skills

When any skill (`onboard`, `scaffold`, `init`) references `docs/reference/trackers.md`, the system shall resolve the path via a three-layer Glob pattern: (1) `.claude/plugins/**/docs/reference/trackers.md`, (2) `**/docs/reference/trackers.md`, (3) bare CWD-relative `docs/reference/trackers.md` as last resort.

### REQ-2: Resolve-once reuse pattern

When a skill contains multiple references to `trackers.md`, the system shall resolve the path once at the earliest reference point and reuse the resolved `{trackers_md_path}` variable for all subsequent references within the same skill, consistent with the check-setup Step 3a/Step 7 precedent.

### REQ-3: Graceful degradation on missing file

When `trackers.md` cannot be found by any resolution layer, the system shall emit a `[WARN]` with a file-specific skip message and proceed with built-in defaults or skip the dependent operation, rather than emitting `[FAIL]` or blocking the pipeline.

### REQ-4: Path-note blockquote in each affected file

When a file contains Glob-based path resolution for `trackers.md`, the system shall include a path-note blockquote explaining that `trackers.md` lives in the plugin installation directory and that Glob handles the CWD-context mismatch.

### REQ-5: Core contract path-note for mcp-detection

When `core/mcp-detection.md` references `docs/reference/trackers.md` in its Process section, the system shall include a path-note blockquote clarifying that the calling skill must resolve the path via Glob, and that the inline table is a static built-in fallback for callers that cannot Glob.

---

## Item 2: Structured error_type in core/mcp-detection.md

### REQ-6: error_type Output Contract field

When MCP detection completes with `mcp_available: false`, the system shall include an `error_type` field in the Output Contract with one of: `"tls"`, `"auth"`, `"not_found"`, `"timeout"`, `"unknown"`. When `mcp_available` is true, `error_type` shall be `null`.

### REQ-7: Classification Reference table

When an error occurs during read connectivity, the system shall classify the error string using a priority-ordered Classification Reference table (first match wins): (1) `tls`, (2) `auth`, (3) `not_found`, (4) `timeout`, (5) `unknown`.

### REQ-8: TLS pattern parity with check-setup Step 9

When classifying an error as `tls`, the system shall use the same 8 string patterns as `skills/check-setup/SKILL.md` Step 9 lines 83-85: UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED, SELF_SIGNED_CERT, self signed certificate, certificate verify failed, ERR_TLS_, DEPTH_ZERO_SELF_SIGNED_CERT, unable to get local issuer certificate.

### REQ-9: Auth pattern parity with check-setup Step 9

When classifying an error as `auth`, the system shall use the same patterns as `skills/check-setup/SKILL.md` Step 9 line 94: 401, 403, unauthorized, forbidden, invalid token, authentication.

### REQ-10: Per-scenario error_type assignment

When a Failure Handling scenario occurs, the system shall assign the appropriate `error_type` value: `"unknown"` for no matching MCP tool, classified per Reference table for read connectivity failures, and `null` for write canary failures.

---

## Item 3: Step 10 TLS Treatment

### REQ-11: TLS error detection in Step 10

When the source control connectivity check (Step 10) encounters an error matching any of the 8 TLS string patterns, the system shall classify it as a TLS error before evaluating other error branches.

### REQ-12: Curl probe with env-var URL derivation

When a TLS error is detected in Step 10, the system shall derive `{sc_base_url}` by scanning the SC MCP server entry's `env` block in `.mcp.json` for a URL-like value, falling back to well-known host detection from the server command/package name, and run a curl probe against that URL.

### REQ-13: NODE_OPTIONS hint in Step 10 TLS messages

When Step 10 detects a TLS error, the system shall include `NODE_OPTIONS: --use-system-ca` remediation guidance in all TLS-related failure messages (curl-success, curl-failure, curl-absent, and no-URL-derivable variants).

### REQ-14: Preserved SC-specific error branches

When Step 10 encounters a non-TLS error, the system shall retain the existing auth (401/403 with per-platform scope names), not-found (404), tool-not-found ([WARN]), and catch-all branches with SC-specific messages.

### REQ-15: Private CA hint in catch-all

When Step 10 encounters an unclassified error (catch-all branch), the system shall include a soft private CA / NODE_OPTIONS hint in the failure message.

---

## Acceptance Criteria

### AC-1: Path-note blockquote in all 4 affected files

**Assertion:** Each of `skills/onboard/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/init/SKILL.md`, and `core/mcp-detection.md` contains a blockquote starting with `> **Path note:**` that explains Glob resolution for `trackers.md`.

**Verification:**
```bash
for f in skills/onboard/SKILL.md skills/scaffold/SKILL.md skills/init/SKILL.md core/mcp-detection.md; do
  grep -q '> \*\*Path note:\*\*' "$f" || echo "FAIL: $f missing path-note blockquote"
done
```

**Source files:** `skills/onboard/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/init/SKILL.md`, `core/mcp-detection.md`

---

### AC-2: No bare docs/reference/trackers.md as direct Read instruction

**Assertion:** No skill or core file (excluding docs/plans, tests, CHANGELOG, README, examples) contains a bare `docs/reference/trackers.md` as a direct Read instruction. All references use `{trackers_md_path}` or are inside a path-note/resolution block.

**Verification:**
```bash
# Search for bare "read from/read defaults from docs/reference/trackers.md" outside resolution blocks
grep -rn 'docs/reference/trackers\.md' skills/ core/ \
  | grep -v '{trackers_md_path}' \
  | grep -v 'Path note' \
  | grep -v 'Glob' \
  | grep -v 'last resort' \
  | grep -v 'check-setup' \
  | grep -v 'mcp-detection.md.*inline table'
# Expected: zero results for onboard, scaffold, init
# mcp-detection.md line 19 is allowed (inline table reference, guarded by path-note)
```

**Source files:** `skills/onboard/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/init/SKILL.md`

---

### AC-3: Resolve-once reuse pattern

**Assertion:** `skills/onboard/SKILL.md` resolves `{trackers_md_path}` once at Step 2 start and reuses it for all 6 subsequent references. `skills/scaffold/SKILL.md` resolves once at Step 0-INFRA and reuses for all 4 subsequent references. Each file contains exactly one Glob resolution block for `trackers.md`.

**Verification:**
```bash
# onboard: exactly 1 resolution block, 6+ uses of {trackers_md_path}
onboard_globs=$(grep -c 'Glob.*trackers\|Glob.*\.claude/plugins.*trackers' skills/onboard/SKILL.md || true)
onboard_uses=$(grep -c '{trackers_md_path}' skills/onboard/SKILL.md || true)
[ "$onboard_globs" -eq 1 ] && [ "$onboard_uses" -ge 6 ] || echo "FAIL: onboard resolve-once (globs=$onboard_globs, uses=$onboard_uses)"

# scaffold: exactly 1 resolution block, 4+ uses of {trackers_md_path}
scaffold_globs=$(grep -c 'Glob.*trackers\|Glob.*\.claude/plugins.*trackers' skills/scaffold/SKILL.md || true)
scaffold_uses=$(grep -c '{trackers_md_path}' skills/scaffold/SKILL.md || true)
[ "$scaffold_globs" -eq 1 ] && [ "$scaffold_uses" -ge 4 ] || echo "FAIL: scaffold resolve-once (globs=$scaffold_globs, uses=$scaffold_uses)"
```

**Source files:** `skills/onboard/SKILL.md`, `skills/scaffold/SKILL.md`

---

### AC-4: File-specific [WARN] fallback when trackers.md not found

**Assertion:** Each of the 3 skill files contains a `[WARN]` message specific to its context when `trackers.md` cannot be found. The message does NOT block the pipeline.

**Verification:**
```bash
grep -n '\[WARN\].*trackers\.md.*not found\|\[WARN\].*not found.*trackers' skills/onboard/SKILL.md || echo "FAIL: onboard missing [WARN] fallback"
grep -n '\[WARN\].*trackers\.md.*not found\|\[WARN\].*not found.*trackers' skills/scaffold/SKILL.md || echo "FAIL: scaffold missing [WARN] fallback"
grep -n '\[WARN\].*trackers\.md\|not found.*hardcoded\|not found.*default' skills/init/SKILL.md || echo "FAIL: init missing fallback message"
```

**Source files:** `skills/onboard/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/init/SKILL.md`

---

### AC-5: Glob resolution pattern matches check-setup v6.4.3 exactly

**Assertion:** The Glob resolution algorithm in each skill file uses the same 3 layers in the same order as `skills/check-setup/SKILL.md` Step 3a (lines 35-38): (1) `.claude/plugins/**/docs/reference/trackers.md`, (2) `**/docs/reference/trackers.md`, (3) bare CWD-relative fallback. Preference logic: prefer path containing `.claude/plugins/` or `ceos-agents/`.

**Verification:**
```bash
for f in skills/onboard/SKILL.md skills/scaffold/SKILL.md skills/init/SKILL.md; do
  grep -q '\.claude/plugins/\*\*/docs/reference/trackers\.md' "$f" || echo "FAIL: $f missing layer 1"
  grep -q '\*\*/docs/reference/trackers\.md' "$f" || echo "FAIL: $f missing layer 2"
done
```

**Source files:** `skills/onboard/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/init/SKILL.md`

---

### AC-6: error_type field in Output Contract

**Assertion:** `core/mcp-detection.md` Output Contract section contains an `error_type` field definition with enum values `"tls"`, `"auth"`, `"not_found"`, `"timeout"`, `"unknown"` and `null` for success case.

**Verification:**
```bash
grep -q 'error_type' core/mcp-detection.md || echo "FAIL: error_type not in mcp-detection"
grep -c '"tls"\|"auth"\|"not_found"\|"timeout"\|"unknown"' core/mcp-detection.md
# Expected: at least 5 (one per enum value in the definition)
```

**Source files:** `core/mcp-detection.md` (Output Contract section, after line 52)

---

### AC-7: Classification logic in Failure Handling

**Assertion:** `core/mcp-detection.md` contains a `### Classification Reference` sub-section within Failure Handling that maps error string patterns to `error_type` values using a priority-ordered table.

**Verification:**
```bash
grep -q '### Classification Reference' core/mcp-detection.md || echo "FAIL: Classification Reference section missing"
grep -q 'first match wins\|priority order' core/mcp-detection.md || echo "FAIL: priority-order semantics missing"
```

**Source files:** `core/mcp-detection.md` (Failure Handling section)

---

### AC-8: TLS patterns match check-setup Step 9 exactly

**Assertion:** The Classification Reference table's `tls` row contains all 8 patterns from `skills/check-setup/SKILL.md` lines 83-85: UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED, SELF_SIGNED_CERT, self signed certificate, certificate verify failed, ERR_TLS_, DEPTH_ZERO_SELF_SIGNED_CERT, unable to get local issuer certificate.

**Verification:**
```bash
for p in UNABLE_TO_VERIFY_LEAF_SIGNATURE CERT_UNTRUSTED SELF_SIGNED_CERT "self signed certificate" "certificate verify failed" ERR_TLS_ DEPTH_ZERO_SELF_SIGNED_CERT "unable to get local issuer certificate"; do
  grep -q "$p" core/mcp-detection.md || echo "FAIL: TLS pattern '$p' missing from mcp-detection"
done
```

**Source files:** `core/mcp-detection.md`, `skills/check-setup/SKILL.md` (lines 83-85)

---

### AC-9: Auth patterns match check-setup Step 9 exactly

**Assertion:** The Classification Reference table's `auth` row contains patterns matching `skills/check-setup/SKILL.md` line 94: 401, 403, unauthorized, forbidden, invalid token, authentication.

**Verification:**
```bash
for p in 401 403 unauthorized forbidden "invalid token" authentication; do
  grep -q "$p" core/mcp-detection.md || echo "FAIL: auth pattern '$p' missing from mcp-detection"
done
```

**Source files:** `core/mcp-detection.md`, `skills/check-setup/SKILL.md` (line 94)

---

### AC-10: not_found and timeout patterns

**Assertion:** The Classification Reference table's `not_found` row covers 404, not_found, not found, ENOTFOUND, EAI_AGAIN. The `timeout` row covers timeout, ETIMEDOUT, ECONNREFUSED, ECONNRESET.

**Verification:**
```bash
grep -q 'ENOTFOUND' core/mcp-detection.md || echo "FAIL: ENOTFOUND missing from not_found"
grep -q 'EAI_AGAIN' core/mcp-detection.md || echo "FAIL: EAI_AGAIN missing from not_found"
grep -q 'ETIMEDOUT' core/mcp-detection.md || echo "FAIL: ETIMEDOUT missing from timeout"
grep -q 'ECONNREFUSED' core/mcp-detection.md || echo "FAIL: ECONNREFUSED missing from timeout"
grep -q 'ECONNRESET' core/mcp-detection.md || echo "FAIL: ECONNRESET missing from timeout"
```

**Source files:** `core/mcp-detection.md`

---

### AC-11: Callers can delegate to error_type

**Assertion:** The Classification Reference table and error_type Output Contract field are structured such that callers (`check-setup`, `init`) can use the `error_type` value for conditional logic instead of inline pattern matching. A cross-reference note links back to `skills/check-setup/SKILL.md` Step 9.

**Verification:**
```bash
grep -q 'check-setup.*Step 9\|Step 9.*check-setup' core/mcp-detection.md || echo "FAIL: cross-reference to check-setup Step 9 missing"
```

**Source files:** `core/mcp-detection.md`

---

### AC-12: Step 10 TLS error classification branch

**Assertion:** `skills/check-setup/SKILL.md` Step 10 contains a TLS error classification branch as the first error classification (before auth), with the same 8 TLS string patterns as Step 9.

**Verification:**
```bash
# Extract Step 10 region (line 98 to Block 4)
step10_start=$(grep -n '^10\.' skills/check-setup/SKILL.md | head -1 | cut -d: -f1)
block4_start=$(grep -n 'Block 4' skills/check-setup/SKILL.md | head -1 | cut -d: -f1)
step10_region=$(sed -n "${step10_start},${block4_start}p" skills/check-setup/SKILL.md)
echo "$step10_region" | grep -q 'UNABLE_TO_VERIFY_LEAF_SIGNATURE' || echo "FAIL: TLS patterns missing from Step 10"
echo "$step10_region" | grep -q 'TLS error' || echo "FAIL: TLS error branch label missing from Step 10"
# TLS must appear before Auth in Step 10
tls_line=$(echo "$step10_region" | grep -n 'TLS error' | head -1 | cut -d: -f1)
auth_line=$(echo "$step10_region" | grep -n 'Auth error' | head -1 | cut -d: -f1)
[ "$tls_line" -lt "$auth_line" ] || echo "FAIL: TLS branch not before auth branch in Step 10"
```

**Source files:** `skills/check-setup/SKILL.md`

---

### AC-13: Step 10 curl probe for SC URL

**Assertion:** Step 10 includes a curl probe that targets `{sc_base_url}` derived from the SC MCP server's `env` block in `.mcp.json`, with a well-known host fallback and graceful skip when URL cannot be derived.

**Verification:**
```bash
step10_start=$(grep -n '^10\.' skills/check-setup/SKILL.md | head -1 | cut -d: -f1)
block4_start=$(grep -n 'Block 4' skills/check-setup/SKILL.md | head -1 | cut -d: -f1)
step10_region=$(sed -n "${step10_start},${block4_start}p" skills/check-setup/SKILL.md)
echo "$step10_region" | grep -q 'curl' || echo "FAIL: curl probe missing from Step 10"
echo "$step10_region" | grep -q 'sc_base_url\|env.*block\|env block' || echo "FAIL: env-var URL derivation missing from Step 10"
echo "$step10_region" | grep -q 'which curl' || echo "FAIL: curl availability check missing from Step 10"
```

**Source files:** `skills/check-setup/SKILL.md`

---

### AC-14: Step 10 NODE_OPTIONS hint

**Assertion:** Step 10 emits `NODE_OPTIONS: --use-system-ca` or `NODE_OPTIONS.*--use-system-ca` in all TLS-related failure messages (at least 4 occurrences within Step 10: curl-success, curl-failure, curl-absent, and no-URL-derivable variants).

**Verification:**
```bash
step10_start=$(grep -n '^10\.' skills/check-setup/SKILL.md | head -1 | cut -d: -f1)
block4_start=$(grep -n 'Block 4' skills/check-setup/SKILL.md | head -1 | cut -d: -f1)
step10_node_opts=$(sed -n "${step10_start},${block4_start}p" skills/check-setup/SKILL.md | grep -c 'NODE_OPTIONS' || true)
[ "$step10_node_opts" -ge 4 ] || echo "FAIL: NODE_OPTIONS appears $step10_node_opts times in Step 10 (expected >= 4)"
```

**Source files:** `skills/check-setup/SKILL.md`

---

### AC-15: Step 10 retains existing error branches

**Assertion:** Step 10 retains auth (401/403), not-found (404), tool-not-found ([WARN]), and catch-all error branches with SC-specific messages.

**Verification:**
```bash
step10_start=$(grep -n '^10\.' skills/check-setup/SKILL.md | head -1 | cut -d: -f1)
block4_start=$(grep -n 'Block 4' skills/check-setup/SKILL.md | head -1 | cut -d: -f1)
step10_region=$(sed -n "${step10_start},${block4_start}p" skills/check-setup/SKILL.md)
echo "$step10_region" | grep -q '401/403\|Auth error' || echo "FAIL: auth branch missing from Step 10"
echo "$step10_region" | grep -q '404\|Not found' || echo "FAIL: not-found branch missing from Step 10"
echo "$step10_region" | grep -q '\[WARN\]' || echo "FAIL: [WARN] tool-not-found branch missing from Step 10"
echo "$step10_region" | grep -q 'repository:read' || echo "FAIL: per-platform scope names missing from Step 10"
```

**Source files:** `skills/check-setup/SKILL.md`

---

### AC-16: Step 10 error messages reference "Source control"

**Assertion:** All failure messages in Step 10 reference "Source control" (not "Issue tracker"). No Step 10 message text contains the phrase "Issue tracker".

**Verification:**
```bash
step10_start=$(grep -n '^10\.' skills/check-setup/SKILL.md | head -1 | cut -d: -f1)
block4_start=$(grep -n 'Block 4' skills/check-setup/SKILL.md | head -1 | cut -d: -f1)
step10_region=$(sed -n "${step10_start},${block4_start}p" skills/check-setup/SKILL.md)
echo "$step10_region" | grep -q 'Source control' || echo "FAIL: 'Source control' not found in Step 10"
echo "$step10_region" | grep -qi 'Issue tracker' && echo "FAIL: 'Issue tracker' found in Step 10 messages" || true
```

**Source files:** `skills/check-setup/SKILL.md`

---

### AC-17: Backward compatibility (no config contract changes)

**Assertion:** No new required keys are introduced in the Automation Config contract. No existing required key is renamed or removed. No existing section is restructured.

**Verification:**
```bash
# Verify CLAUDE.md Config Contract section is unchanged
# (this is verified by inspecting the diff: no changes to CLAUDE.md)
git diff --name-only | grep -q 'CLAUDE.md' && echo "FAIL: CLAUDE.md modified" || echo "OK: CLAUDE.md not modified"
```

**Source files:** `CLAUDE.md` (should NOT be modified)

---

### AC-18: Existing test check-setup-improvements.sh AC-11 still passes

**Assertion:** `tests/scenarios/check-setup-improvements.sh` passes all existing assertions (AC-1 through AC-14) after the v6.4.4 changes. Specifically, AC-11 (which checks for `[WARN]` + skip for missing trackers.md in check-setup) must still pass.

**Verification:**
```bash
bash tests/scenarios/check-setup-improvements.sh
# Expected: exit 0, "PASS" output
```

**Source files:** `tests/scenarios/check-setup-improvements.sh`, `skills/check-setup/SKILL.md`

---

### AC-19: No new required config keys

**Assertion:** No new required keys are added to any `## Input Contract` section in core files or any new required parameter in skills. The PATCH introduces zero breaking changes.

**Verification:**
```bash
# Verify no new required keys in mcp-detection Input Contract
# The only addition is error_type in OUTPUT Contract (not input)
git diff core/mcp-detection.md | grep -A2 '## Input Contract' | grep '+' | grep -v '+++' && echo "FAIL: Input Contract modified" || echo "OK: Input Contract unchanged"
```

**Source files:** `core/mcp-detection.md` (Input Contract must be unchanged)

---

## Boundary Conditions

### Edge Cases for Item 1 (Bare Path Migration)

| Edge case | Expected behavior |
|-----------|-------------------|
| `trackers.md` not found by any Glob layer | `[WARN]` + proceed with defaults/skip |
| Multiple `trackers.md` matches from Glob layer 1 | `[WARN]` + use first match preferring `ceos-agents/` path |
| Scaffold with tracker = "later" | `{trackers_md_path}` never resolved; lines 484, 543 are guarded no-ops |
| `core/mcp-detection.md` callers via `mcp-preflight.md` | Path-note clarifies inline table is the operative source for non-Glob callers |

### Edge Cases for Item 2 (error_type)

| Edge case | Expected behavior |
|-----------|-------------------|
| Write canary failures | `error_type` = `null` (write errors are separate from read errors) |
| Unknown tracker type MCP tool not found | `error_type` = `"unknown"` |
| ECONNREFUSED error | `error_type` = `"timeout"` (server resolved but connection refused) |
| ENOTFOUND / EAI_AGAIN error | `error_type` = `"not_found"` (DNS resolution failure) |
| Error matches both TLS and auth patterns | `error_type` = `"tls"` (priority 1 wins over priority 2) |

### Edge Cases for Item 3 (Step 10 TLS)

| Edge case | Expected behavior |
|-----------|-------------------|
| SC MCP server has no URL-like env value (e.g., GitHub) | Well-known host fallback (`https://github.com`) |
| SC MCP server is unknown type, no URL derivable | Skip curl probe; emit no-URL-derivable TLS message with NODE_OPTIONS hint |
| `curl` not installed | Skip probe; emit curl-absent variant with NODE_OPTIONS hint |
| curl succeeds but MCP fails (proxy MITM) | Message says "likely TLS" (not "confirmed TLS") |

---

## Follow-up Items (out of PATCH scope)

1. **Inline table sync-check test:** Add a test in `tests/scenarios/` comparing the inline table in `core/mcp-detection.md` against `docs/reference/trackers.md`.
2. **mcp-preflight error_type forwarding:** Update `core/mcp-preflight.md` to forward `error_type` from mcp-detection output. File as roadmap item for v6.5.0.
3. **error_type exhaustiveness test:** Add a test verifying all enum values are handled by callers.
