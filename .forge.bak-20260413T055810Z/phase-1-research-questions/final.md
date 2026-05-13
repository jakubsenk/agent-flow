# Phase 1 Research — Synthesis Final
# All 10 Research Questions

Synthesized from: agent-1.md (Q1–Q4), agent-2.md (Q5–Q8), agent-3.md (Q9–Q10)
Date: 2026-04-11

---

## Overview

Phase 1 covered three independent work items:

| Work Item | Questions | Status |
|-----------|-----------|--------|
| Bare path migration — `trackers.md` references | Q1–Q4 | Fully researched |
| `error_type` extension — mcp-detection output contract | Q5–Q8 | Fully researched |
| Step 10 TLS treatment — SC connectivity parity | Q9–Q10 | Fully researched |

---

## Work Item A: Bare Path Migration

### Q1 — Canonical Glob-first Resolution Pattern

**Source file:** `skills/check-setup/SKILL.md`, lines 30–45 (Step 3a, "Per-tracker validation" block)

The canonical 3-tier resolution algorithm is:

```
1. Glob(".claude/plugins/**/docs/reference/trackers.md")   ← plugin-install path, checked first
2. Glob("**/docs/reference/trackers.md")                    ← broad search fallback
3. "docs/reference/trackers.md"                             ← bare CWD-relative, last resort
```

**Disambiguation rule:** If multiple Glob results → prefer path containing `.claude/plugins/` or `ceos-agents/`; if still ambiguous → `[WARN] "Multiple trackers.md found — using {path}."`

**Not-found rule:** `[WARN] "trackers.md not found — per-tracker validation skipped. Verify plugin installation."` — never [FAIL], never block the pipeline.

**Exact text from check-setup lines 32–33 (the "Path note" pattern):**
```
> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming
> project. Glob is used to handle CWD-context mismatch.
```
This prose block is the template for path notes to be added in target files.

---

### Q2 & Q3 — All Runtime-Relevant Bare References

**Total: 12 bare references across 4 files.** No other skills or core files have bare `trackers.md` references.

#### `skills/onboard/SKILL.md` — 6 references

| Line | Step/Section | Usage Type |
|------|-------------|------------|
| 68 | Step 2, sub-step 2 | Instance & Project Defaults table |
| 70 | Step 2, sub-step 4 | Query Syntax table |
| 72 | Step 2, sub-step 5 | Query Syntax table (Feature query format column) |
| 75 | Step 2, sub-step 6 | State Transition Syntax table |
| 76 | Step 2, sub-step 7 | On Start Set Defaults table |
| 108 | Step 4b | PR Description Footer table |

All 6 are "look up in this table" style. Lines 68–76 are contiguous in Step 2 (tracker-selection wizard). Line 108 is in Step 4b. A single resolve-once at the top of Step 2 covers all 6 references. No Glob calls exist anywhere in this file today — adding one is a new tool usage pattern for onboard. `allowed-tools` includes `Glob`.

#### `skills/scaffold/SKILL.md` — 4 references

| Line | Step/Section | Usage Type |
|------|-------------|------------|
| 93 | Step 0-INFRA, "If tracker = ready" | Instance URL format example |
| 169 | Step 0-MCP, failure guidance | Required environment variables |
| 484 | Step 4b-replaced, Generate .mcp.json.example | MCP Server Detection table (package name) |
| 543 | Step 4e, native sub-issue creation | Sub-Issue Capabilities cross-reference |

References span lines 93–543 (~450 lines). The earliest use is at Step 0-INFRA (line 93), which is the correct resolve-once point. `allowed-tools` includes `Glob`. **Note:** This file exceeds the 10,000-token read limit and requires offset-based reads during implementation.

#### `skills/init/SKILL.md` — 1 reference

| Line | Step/Section | Usage Type |
|------|-------------|------------|
| 36 | Step 0, `--tracker-instance` default | Instance & Project Defaults table |

Single reference, no "resolve once, reuse" complexity. Glob-first pattern applied inline at point of use. `allowed-tools` includes `Glob`.

#### `core/mcp-detection.md` — 1 reference

| Line | Step/Section | Usage Type |
|------|-------------|------------|
| 19 | Process step 1 — MCP package lookup | MCP Server Detection table |

**Critical complication (see Surprises section):** `core/mcp-detection.md` is not a skill — it has no `allowed-tools` frontmatter and cannot execute Glob. This file is passively read by callers. Active Glob-first logic cannot be added here. The correct fix is: (a) add a path note (like check-setup lines 32–33) instructing the calling skill to resolve the path, and (b) note that lines 20–29 already inline the full MCP lookup table as a static fallback, so this reference is lower priority.

---

### Q4 — "Resolve Once, Reuse Later" Pattern

**Explicitly enforced in check-setup.** The pattern is documented in Step 7 (lines 65–69) with the exact phrase:

```
"reuse the trackers.md path resolved in Step 3a (do not Glob again)"
```

Step 7 explicitly forbids re-Glob-ing. This is also verified by a test: `tests/scenarios/check-setup-edge-cases.sh` lines 66–89 check that Glob appears exactly once in the skill file (in Step 3a only).

**Replication guidance per target file:**

| File | Resolve Point | Variable Name | Reuse Points |
|------|--------------|---------------|-------------|
| `skills/onboard/SKILL.md` | Top of Step 2 (before line 68) | `trackers_md_path` | Lines 68, 70, 72, 75, 76, 108 |
| `skills/scaffold/SKILL.md` | Top of Step 0-INFRA (before line 93) | `trackers_md_path` | Lines 93, 169, 484, 543 |
| `skills/init/SKILL.md` | Inline at line 36 (Step 0) | (inline only) | None — single use |
| `core/mcp-detection.md` | Cannot resolve — path note only | N/A | N/A |

---

## Work Item B: `error_type` Extension

### Q5 — `core/mcp-detection.md` Full Analysis

**File:** `core/mcp-detection.md`

#### Current Structure (5 sections)

1. **Purpose** (lines 3–7) — lists referencing files: `skills/scaffold/SKILL.md` (Step 0-MCP) and `skills/init/SKILL.md` (Steps 3, 7). **Gap:** `skills/check-setup/SKILL.md` is NOT listed, even though it runs its own inline connectivity check (Step 9). This is a documentation gap.

2. **Input Contract** (lines 9–15):

| Field | Type | Required | Default |
|-------|------|----------|---------|
| `tracker_type` | string | yes | — |
| `tracker_instance` | string | optional | — |
| `tracker_project` | string | optional | — |
| `service_type` | string | yes | — |
| `check_write` | boolean | optional | false |

3. **Process** (lines 17–44) — 4 numbered steps. Steps 3–4 capture raw errors with no classification.

4. **Output Contract** (lines 46–53):

| Field | Type | Description |
|-------|------|-------------|
| `mcp_available` | boolean | true if MCP tool accessible and read connectivity succeeds |
| `write_available` | boolean or null | true if canary-write succeeded |
| `write_cleanup_failed` | boolean | true if canary created but not deleted |
| `package_name` | string | Expected MCP package name |
| `tool_prefix` | string | Expected tool prefix pattern |
| `error` | string or null | Raw error message (no classification) |
| `write_error` | string or null | Raw write error message |

**Current state: No `error_type` field exists.** The `error` field is always a plain string or null. Classification is entirely deferred to callers.

5. **Failure Handling** (lines 55–61) — 4 named scenarios, all raw strings, none classified.

---

### Q6 — check-setup Step 9 Error Classification Logic

**File:** `skills/check-setup/SKILL.md`, lines 80–104

Classification happens **inline in check-setup** (not in mcp-detection.md). The logic is a priority-ordered cascade: first match wins.

#### TLS Error (lines 83–93)

Triggered when the error string contains **any** of these 8 patterns:

```
UNABLE_TO_VERIFY_LEAF_SIGNATURE
CERT_UNTRUSTED
SELF_SIGNED_CERT
self signed certificate
certificate verify failed
ERR_TLS_
DEPTH_ZERO_SELF_SIGNED_CERT
unable to get local issuer certificate
```

After match, runs a curl probe:
- `which curl` → if unavailable: `[FAIL] "Issue tracker — TLS error detected. Add NODE_OPTIONS: --use-system-ca to .mcp.json env block. (curl not available for confirmation probe)"`
- curl exits 0, HTTP code != 000: `[FAIL] "Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json"`
- curl exits non-zero or HTTP code 000: `[FAIL] "Issue tracker — connection failed (TLS or network). If using a private CA, try NODE_OPTIONS: --use-system-ca. If server is remote, verify URL."`

#### Auth Error (lines 94–95)

Triggered when the error string contains **any** of these 6 patterns:

```
401
403
unauthorized
forbidden
invalid token
authentication
```

Message: `[FAIL] "Issue tracker — authentication failed — check your token in .mcp.json"`

#### Catch-all (lines 96–97)

Any error not matching TLS or Auth patterns:
`[FAIL] "Issue tracker — server not reachable — verify the server is running and URL is correct. If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca."`

**Note:** No separate timeout-specific or DNS-specific classification exists anywhere in the codebase. These fall into the catch-all.

#### Proposed `error_type` Enum (derived from check-setup Step 9 as canonical source)

| Category | Proposed enum value | Trigger |
|---------|-------------------|---------|
| TLS certificate error | `tls` | 8 string patterns above |
| Authentication failure | `auth` | 6 string patterns above |
| Tool/prefix not found | `tool_not_found` | structural (no MCP tool matches prefix) |
| Other / unknown | `unknown` | all remaining errors |
| No error | `null` | `mcp_available: true` |

---

### Q7 — `skills/init/SKILL.md` — mcp-detection Usage

init references `core/mcp-detection.md` in three modes:

| Reference location | Mode | Classification? |
|-------------------|------|----------------|
| Step 0 (line 33–34) | Static lookup — validate `--tracker-type` against enum | None |
| Step 1b (lines 59–61) | Static reverse lookup — package_name → tracker_type | None |
| Step 3 (line 93, comment) | Documentation reference for lookup table | None |
| **Step 7 (lines 251–263)** | **Active connectivity check (`check_write: false`)** | **None — raw passthrough** |

**Key finding:** init Step 7 is the **only place** init actively invokes mcp-detection for connectivity. Error handling is:
```
"[FAIL] {server_name}: {error}. Check your token and URL."
```
The raw `{error}` string from mcp-detection is displayed verbatim. No pattern matching, no TLS/auth distinction. Adding `error_type` to mcp-detection output would make richer messages possible here without any additional logic in init.

---

### Q8 — fix-bugs and fix-ticket — MCP Detection Calls

**Key finding: neither fix-bugs nor fix-ticket calls `core/mcp-detection.md` directly.**

Both delegate to `core/mcp-preflight.md` (a different core file) at Step 0:

- `skills/fix-ticket/SKILL.md` line 83: `Follow \`core/mcp-preflight.md\` to verify MCP server availability.`
- `skills/fix-bugs/SKILL.md` line 82: `Follow \`core/mcp-preflight.md\` to verify MCP server availability.`

fix-bugs has additional inline logic (lines 83–86) — a binary accessible/not-accessible check with a single fixed message: `"Cannot connect to your {Type} issue tracker. Is the {Type} integration configured? Run \`/ceos-agents:check-setup\` for diagnostics."` — no pattern matching, no error_type categories.

#### Full Caller Inventory for mcp-detection

| Caller | References mcp-detection | Invokes connectivity | Error classification | Via |
|--------|--------------------------|---------------------|---------------------|-----|
| `check-setup/SKILL.md` | No direct reference | Yes (inline, Step 9) | Full (TLS / Auth / Other) | Inline |
| `init/SKILL.md` | Yes (Steps 0, 1b, 3, 7) | Yes (Step 7) | None — raw passthrough | `core/mcp-detection.md` directly |
| `fix-ticket/SKILL.md` | No | Via mcp-preflight | None | `core/mcp-preflight.md` |
| `fix-bugs/SKILL.md` | No | Via mcp-preflight | None — single fixed message | `core/mcp-preflight.md` |
| `scaffold/SKILL.md` | Yes (Steps 0-MCP, 4b-replaced, 4e) | Yes (Step 0-MCP) | Unknown (not fully read) | `core/mcp-detection.md` |

**Implication:** Classification extension for fix-ticket/fix-bugs pipelines requires updating `core/mcp-preflight.md`, not `core/mcp-detection.md` alone. This is out of scope for the `error_type` addition but worth noting.

---

## Work Item C: Step 10 TLS Parity

### Q9 — Step 10 Full Analysis

**File:** `skills/check-setup/SKILL.md`, lines 98–104

#### Complete Step 10 Text (verbatim)

```markdown
10. Verify source control connectivity: fetch metadata for the configured Remote (owner/repo) via MCP
    - Use MCP to fetch repository metadata for the Remote value from Automation Config
    - Success → [OK] "Source control — {owner/repo} reachable"
    - Auth error (401/403) → [FAIL] "Source control — authentication failed. Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)."
    - Not found (404) → [FAIL] "Source control — repository {owner/repo} not found. Verify Remote in Automation Config."
    - Tool not found (MCP server lacks repository metadata method) → [WARN] "Source control MCP: repository existence check not supported — skipping."
    - Timeout/unreachable → [FAIL] "Source control — MCP server not reachable. Verify server URL and token in .mcp.json."
```

#### Step 10 Current Failure Coverage

| Error Case | Trigger | Message Level |
|------------|---------|---------------|
| Auth | 401/403 | [FAIL] — includes scope names per platform |
| Not found | 404 | [FAIL] |
| Tool not found | MCP lacks repository metadata method | [WARN] |
| Timeout/unreachable | catch-all | [FAIL] — no TLS hint |

**TLS errors are entirely unhandled.** Any TLS certificate failure silently falls into "Timeout/unreachable" and produces: `"Source control — MCP server not reachable. Verify server URL and token in .mcp.json."` — actively misleading (the token is fine; the TLS cert is the problem).

---

### Q10 — Side-by-Side Comparison: Step 9 vs Step 10

#### Step 9 Full Text (verbatim, lines 80–97)

```markdown
9. Run the Bug query from Automation Config via MCP (limit 1 result):
   - Success → [OK] with the number of bugs found
   - On failure, classify the error in this order:
     1. **TLS error** (error contains any of: UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED,
        SELF_SIGNED_CERT, self signed certificate, certificate verify failed, ERR_TLS_,
        DEPTH_ZERO_SELF_SIGNED_CERT, unable to get local issuer certificate):
        Run a curl probe to confirm network reachability:
        - Check `which curl` — if curl is not available, skip probe and emit:
          [FAIL] "Issue tracker — TLS error detected. Add NODE_OPTIONS: --use-system-ca to .mcp.json env block. (curl not available for confirmation probe)"
        - Run: `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {Instance}`
        - curl exit 0 and HTTP code != 000 →
          [FAIL] "Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json"
        - curl exit non-zero or HTTP code 000 →
          [FAIL] "Issue tracker — connection failed (TLS or network). If using a private CA, try NODE_OPTIONS: --use-system-ca. If server is remote, verify URL."
     2. **Auth error** (error contains: 401, 403, unauthorized, forbidden, invalid token, authentication) →
        [FAIL] "Issue tracker — authentication failed — check your token in .mcp.json"
     3. **Any other error** →
        [FAIL] "Issue tracker — server not reachable — verify the server is running and URL is correct. If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca."
```

#### Feature Comparison Table

| Feature | Step 9 (Issue Tracker) | Step 10 (Source Control) |
|---------|----------------------|------------------------|
| TLS error string matching (8 patterns) | YES | NO — **Gap 1** |
| `which curl` availability check | YES | NO — **Gap 2** |
| `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {url}` probe | YES | NO — **Gap 3** |
| Differentiated curl result messages | YES (2 messages: reachable vs not) | NO — **Gap 3** |
| `NODE_OPTIONS: --use-system-ca` hint in TLS branch | YES | NO — **Gap 4** |
| `NODE_OPTIONS` hint in catch-all | YES | NO — **Gap 5** |
| Auth handling | Generic (401, 403, unauthorized, forbidden, invalid token, authentication) | Better — names per-platform scopes |
| Not found (404) | NO | YES |
| Tool not found | NO | YES ([WARN]) |
| Error classification order (priority cascade) | YES — TLS first → Auth → catch-all | NO — flat list |

#### The 5 Missing Patterns (Gaps to Fix in Step 10)

**Gap 1 — No TLS error classification.**
The same 8 string patterns used in Step 9 must be added as the first failure branch in Step 10:
`UNABLE_TO_VERIFY_LEAF_SIGNATURE`, `CERT_UNTRUSTED`, `SELF_SIGNED_CERT`, `self signed certificate`, `certificate verify failed`, `ERR_TLS_`, `DEPTH_ZERO_SELF_SIGNED_CERT`, `unable to get local issuer certificate`.

**Gap 2 — No `which curl` availability check.**
Step 9 gracefully handles the case where curl is not installed. Step 10 needs the same guard.

**Gap 3 — No curl network reachability probe.**
Step 9 runs `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {Instance}` to distinguish "TLS fail but server reachable" from "server completely unreachable." Step 10 needs the equivalent — using the base URL derived from Remote (e.g., `https://gitea.example.com` extracted from `owner/repo` + SC instance config, or the SC MCP server base URL).

**Gap 4 — No `NODE_OPTIONS: --use-system-ca` hint in TLS messages.**
Step 10's TLS messages must include the `NODE_OPTIONS: --use-system-ca` fix in both differentiated curl-result branches.

**Gap 5 — No TLS/private CA hint in catch-all.**
Step 9's catch-all already includes `"If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca."` Step 10's `Timeout/unreachable` catch-all must add the same safety net.

#### What Does NOT Need to Change in Step 10

The auth handling in Step 10 is **better** than Step 9 (names the required scope per platform: `repository:read` for Gitea, `repo` for GitHub, `read_repository` for GitLab). The 404/not-found and tool-not-found cases are SC-specific and architecturally correct as-is.

---

## Key Findings and Surprises

### Surprises

1. **`core/mcp-detection.md` cannot execute Glob.** It is a passive markdown reference with no `allowed-tools` frontmatter. Adding active Glob-first resolution logic there would be architecturally incorrect. The correct fix is a path note directing callers to resolve the path. The inline MCP lookup table already at lines 20–29 serves as a built-in fallback for the trackers.md reference.

2. **`skills/scaffold/SKILL.md` exceeds the 10,000-token read limit.** It must be read in chunks using offset-based reads during implementation. The 4 references span lines 93–543.

3. **`skills/onboard/SKILL.md` has never used Glob.** Although `allowed-tools` includes `Glob`, no Glob calls exist in the file. Adding the Glob-first resolution introduces the first Glob call in this skill.

4. **fix-bugs and fix-ticket do not call `core/mcp-detection.md` directly.** They go through `core/mcp-preflight.md`. The `error_type` extension in mcp-detection would not benefit these pipelines unless mcp-preflight is also updated (out of scope for Phase 2).

5. **check-setup is absent from mcp-detection's Purpose section.** The Purpose section (lines 3–7) lists `scaffold/SKILL.md` and `init/SKILL.md` as referencing files, but NOT `check-setup/SKILL.md`. This is because check-setup runs its own inline connectivity check (Step 9) rather than delegating to `core/mcp-detection.md`. The documentation gap should be noted but may not need correction (check-setup intentionally does not use the core contract).

6. **Step 10's auth handling is already superior to Step 9's.** The per-platform scope names in Step 10 are more actionable. No changes needed in that branch.

7. **The roadmap already tracks the bare path migration.** `docs/plans/roadmap.md` line 461–462 references this work with the correct count estimate.

---

## Inventory: Files to Edit and Required Changes

### File 1: `skills/check-setup/SKILL.md`

**Work item:** Step 10 TLS parity (Work Item C)
**Lines to modify:** 98–104 (Step 10)
**Required changes:**

1. Convert the flat error list into a priority-ordered cascade (TLS first → Auth → Not found → Tool not found → catch-all).
2. Add TLS branch before the existing Auth case — check for all 8 TLS patterns, run `which curl` guard, run `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {base_url}` probe, emit two differentiated [FAIL] messages both including `NODE_OPTIONS: --use-system-ca`.
3. Add `NODE_OPTIONS: --use-system-ca` hint to the catch-all `Timeout/unreachable` message.
4. The base URL for the curl probe: derive from the SC MCP server configuration (the base hostname, not the `owner/repo` string). This detail needs resolution in Phase 2 design.
5. Keep auth (401/403 + per-platform scope names), 404, and tool-not-found branches unchanged.

---

### File 2: `core/mcp-detection.md`

**Work items:** Bare path migration (Work Item A) + `error_type` extension (Work Item B)
**Lines to modify:**
- Line 19 (bare `trackers.md` reference) → add path note
- Lines 46–53 (Output Contract) → add `error_type` field
- Lines 55–61 (Failure Handling) → add `error_type` assignment to each scenario

**Required changes:**

**A — Bare path (line 19):**
Add a path note prose block (mirroring check-setup lines 32–33) before Process step 1, instructing calling skills to resolve `trackers.md` via Glob-first before invoking this contract.

**B — error_type in Output Contract (lines 46–53):**
Add new row:
```
| `error_type` | string or null | `"tls"`, `"auth"`, `"tool_not_found"`, `"unknown"`, or `null` if `mcp_available: true` |
```

**B — error_type in Failure Handling (lines 55–61):**
- "No matching MCP tool found" → set `error_type: "tool_not_found"`
- "Read connectivity fails" → classify error string against TLS patterns (8) → `"tls"` if match, else auth patterns (6) → `"auth"` if match, else `"unknown"`
- "Write canary create fails" / "Write canary delete fails" → `error_type` does not apply to write errors (leave `null` or omit — write errors are separate from `mcp_available`)
- Add a note that pattern-matching for classification reuses the same patterns as check-setup Step 9

---

### File 3: `skills/onboard/SKILL.md`

**Work item:** Bare path migration (Work Item A)
**Lines to add:** Resolve block at the top of Step 2 (before line 68)
**Lines to modify:** 68, 70, 72, 75, 76, 108 (replace bare `docs/reference/trackers.md` with `{trackers_md_path}`)

**Required changes:**

1. Add path note and 3-tier Glob-first resolution block at the start of Step 2:
   ```
   > **Path note:** `trackers.md` lives in the plugin installation directory.
   > Resolve once: Glob `.claude/plugins/**/docs/reference/trackers.md` first;
   > if no results, Glob `**/docs/reference/trackers.md`; if still none, use
   > `docs/reference/trackers.md`. Prefer path containing `.claude/plugins/` or
   > `ceos-agents/` if multiple results. If not found → [WARN] and skip table lookups
   > (use built-in defaults). Store resolved path as `trackers_md_path`.
   ```
2. Replace all 6 bare `docs/reference/trackers.md` references with `{trackers_md_path}`.
3. Do NOT add a second Glob in Step 4 — reuse the path resolved in Step 2.

---

### File 4: `skills/scaffold/SKILL.md`

**Work item:** Bare path migration (Work Item A)
**Lines to add:** Resolve block at the top of Step 0-INFRA (before line 93)
**Lines to modify:** 93, 169, 484, 543

**Required changes:**

1. Add path note and 3-tier Glob-first resolution block at the start of Step 0-INFRA.
2. Replace all 4 bare `docs/reference/trackers.md` references with `{trackers_md_path}`.
3. **Implementation note:** File requires offset-based reads. Read in at least two chunks (e.g., lines 1–300 and 301–600) to cover all 4 references.

---

### File 5: `skills/init/SKILL.md`

**Work item:** Bare path migration (Work Item A)
**Lines to modify:** 36 (Step 0 — single reference)

**Required changes:**

1. Add inline Glob-first resolution at the point of use (Step 0, before/at line 36).
2. No "resolve once, reuse later" needed — single reference only.
3. Pattern: resolve inline when `--tracker-instance` is not provided and the default Instance URL lookup is needed.

---

### Files Excluded from Changes

| File | Reason |
|------|--------|
| `docs/plans/roadmap.md` | Documentation only — no runtime logic |
| `docs/plans/brainstorm/IMPLEMENTATION-PLAN.md` | Historical planning document |
| `docs/plans/2026-03-03-redmine-tracker-support-*.md` | Historical design documents |
| `tests/` | Test scenarios — not modified in Phase 2 (new tests may be added) |
| `core/mcp-preflight.md` | Callers of mcp-preflight (fix-bugs, fix-ticket) out of scope for error_type work |
| `skills/check-setup/SKILL.md` Step 3a | Canonical pattern — already correct, no changes needed |

---

## Cross-Cutting Concerns

### Dependency Chain

```
Work Item A (bare path):
  core/mcp-detection.md ← callers must resolve before invoking
  skills/init/SKILL.md  ← calls mcp-detection; also has bare trackers.md ref
  skills/onboard/SKILL.md ← bare refs only
  skills/scaffold/SKILL.md ← bare refs + calls mcp-detection

Work Item B (error_type):
  core/mcp-detection.md output contract ← add error_type field + classification logic
  skills/init/SKILL.md Step 7 ← immediately usable with error_type (no logic change needed)
  skills/check-setup/SKILL.md Step 9 ← may be simplified if it delegates to mcp-detection;
                                        OR kept as-is (inline classification stays, error_type
                                        is additive in mcp-detection for other callers)

Work Item C (Step 10 TLS):
  skills/check-setup/SKILL.md lines 98-104 ← only file to change
```

### Order of Implementation (suggested)

1. `core/mcp-detection.md` — both Work Items A (path note) and B (error_type) touch this file; do together.
2. `skills/check-setup/SKILL.md` Step 10 — independent, only Work Item C.
3. `skills/init/SKILL.md` — Work Item A (bare path), can also adopt error_type display.
4. `skills/onboard/SKILL.md` — Work Item A only.
5. `skills/scaffold/SKILL.md` — Work Item A only (requires chunked reads).

### Open Question for Phase 2 Design

**Step 10 curl probe base URL:** The curl probe in Step 9 uses `{Instance}` (the full tracker instance URL from Automation Config). For Step 10, the Source Control Remote is `owner/repo` (not a URL). The base URL for the curl probe must be derived from the SC MCP server configuration (the server's base URL, e.g., `https://gitea.example.com`). The exact derivation logic needs to be specified in the Phase 2 design — it is not currently documented anywhere in the codebase.
