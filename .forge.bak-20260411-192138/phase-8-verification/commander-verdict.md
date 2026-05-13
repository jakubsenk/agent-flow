# Commander Verdict -- check-setup SKILL.md Fixes

**Date:** 2026-04-11
**Verifier:** Adversarial Verification Commander
**Target:** `skills/check-setup/SKILL.md`
**Spec:** `.forge/phase-4-spec/final/formal-criteria.md` (14 ACs)

---

## Per-AC Verdicts

| AC | Verdict | Evidence |
|----|---------|----------|
| AC-1 | PASS | All three TLS sub-branches in Step 9 include `NODE_OPTIONS: --use-system-ca`: curl-absent (line 88), curl-success (line 91), curl-failure (line 93). Additionally, the generic-unreachable branch (line 97) also includes it. |
| AC-2 | PASS | Curl-success branch (line 90-91) states "server reachable but MCP connection failed (likely TLS)" -- confirms reachability and identifies TLS as the problem. |
| AC-3 | PASS | Curl-failure branch (line 92-93): includes `NODE_OPTIONS: --use-system-ca`. Curl-absent branch (line 87-88): includes `NODE_OPTIONS: --use-system-ca`. Neither falls back to a pure "not reachable" message without TLS guidance. |
| AC-4 | PASS | Generic unreachable branch (line 96-97) includes soft hint: "If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca." |
| AC-5 | PASS | Classification order in Step 9 (lines 82-97): item 1 is **TLS error**, item 2 is **Auth error**, item 3 is **Any other error**. TLS is evaluated before auth. |
| AC-6 | PASS | Step 10 (line 98) says "fetch metadata for the configured Remote (owner/repo) via MCP". Line 99: "fetch repository metadata for the Remote value from Automation Config". No mention of "list repositories". Grep confirmed zero matches for "list repositories". |
| AC-7 | PASS | Auth-failure branch (line 101) includes `repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)` -- covers Gitea specifically and is generic enough for other providers. |
| AC-8 | PASS | 404 branch (line 102) is a separate, distinct branch: `[FAIL] "Source control -- repository {owner/repo} not found. Verify Remote in Automation Config."` -- mentions "not found" and references Remote/Automation Config. |
| AC-9 | PASS | Tool-not-found branch (line 103) emits `[WARN]` (not `[FAIL]`): `[WARN] "Source control MCP: repository existence check not supported -- skipping."` |
| AC-10 | PASS | Step 3a (lines 35-38) implements three-layer resolution: (1) Glob `.claude/plugins/**/docs/reference/trackers.md`, (2) Glob `**/docs/reference/trackers.md`, (3) CWD fallback `docs/reference/trackers.md`. Plugin directory preference with `.claude/plugins/` or `ceos-agents/`. |
| AC-11 | PASS | Line 38: `If the file cannot be found -> [WARN] "trackers.md not found -- per-tracker validation skipped. Verify plugin installation." and skip the rest of Step 3a.` Emits [WARN], mentions skipping, instructs to skip the rest of Step 3a. |
| AC-12 | PASS | Step 7 (line 66): "reuse the trackers.md path resolved in Step 3a (do not Glob again)." References Step 3a. Line 69: `If trackers.md was unavailable in Step 3a -> [WARN] "trackers.md not found -- MCP server keyword match skipped."` Skip branch with [WARN] present. |
| AC-13 | PASS | Output format Connectivity block (line 132): `[FAIL] Issue tracker -- server reachable but MCP connection failed (likely TLS) -- add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json` -- TLS-specific failure example with NODE_OPTIONS recommendation. |
| AC-14 | PASS | Git diff shows exactly 5 edit regions: (1) Step 3a path resolution, (2) Step 7 trackers.md reuse, (3) Step 9 TLS diagnostic, (4) Step 10 SC connectivity, (5) Output Connectivity block. No changes to frontmatter, Block 1 steps 1-3/4-5, Block 2 steps 6/8, Block 4, Block 5, Rules, Verdict, or other Output format sections. All changes are within the specified edit regions only. |

---

## Dimension Scores

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Security | 1.0 | `NODE_TLS_REJECT_UNAUTHORIZED` is completely absent from the file (verified via grep -- zero matches). All TLS guidance uses the safe `NODE_OPTIONS: --use-system-ca` recommendation exclusively. No insecure workarounds suggested anywhere. |
| Correctness | 1.0 | All 14 ACs pass. The diagnostic flow in Step 9 follows a logically correct classification order (TLS before auth before generic). Curl probe correctly differentiates reachable-but-TLS-broken from network-down scenarios. Step 10 correctly separates 401/403, 404, tool-not-found, and timeout into distinct branches. Path resolution in Step 3a handles all edge cases (multiple results, no results, plugin directory preference). |
| Spec alignment | 1.0 | Implementation matches the formal criteria precisely. Every pattern listed in AC-1 is present. Every sub-branch in AC-2/AC-3 exists. The classification order in AC-5 is correct. Step 10 uses "fetch metadata" (not "list repositories") per AC-6. The three-layer Glob resolution in AC-10 matches exactly. The output format in AC-13 includes the required TLS example. |
| Robustness | 1.0 | Edge cases explicitly handled: (1) curl absent -- skip probe, still emit TLS hint (line 87-88). (2) trackers.md missing -- [WARN] with graceful skip in both Step 3a (line 38) and Step 7 (line 69). (3) Tool not found in Step 10 -- degrades to [WARN] (line 103). (4) Multiple trackers.md results -- preference logic with [WARN] for ambiguous case (line 37). (5) Unknown tracker type -- [WARN] with skip (line 44). |

---

## Aggregate Score

| Dimension | Weight | Score | Weighted |
|-----------|--------|-------|----------|
| Security | 0.1 | 1.0 | 0.10 |
| Correctness | 0.4 | 1.0 | 0.40 |
| Spec alignment | 0.3 | 1.0 | 0.30 |
| Robustness | 0.2 | 1.0 | 0.20 |
| **Total** | **1.0** | | **1.00** |

---

## Commander Verdict

**PASS** (aggregate 1.00 >= 0.70 threshold)

---

## Issues Found

None. The implementation is clean and precisely matches all 14 acceptance criteria.

Minor observations (informational, not issues):
- The generic unreachable branch (AC-4, Step 9 item 3) provides a richer hint than strictly required ("self-signed or corporate PKI" context) -- this is a positive embellishment, not a deviation.
- The Output format section added both a TLS failure line and an updated SC auth failure line. The spec only required the TLS example (AC-13), but the SC line update is consistent with the Step 10 changes and does not constitute a regression.

---

## Test Results

Full test harness run: **53/53 PASS, 0 FAIL, 0 SKIP**

All tests passed including:
- `check-setup-edge-cases` -- PASS
- `check-setup-improvements` -- PASS
- `test-step-placement` -- PASS
- `skills-frontmatter-check` -- PASS
- `skills-directory-structure` -- PASS
- `section-order` -- PASS
- All 47 other tests -- PASS

No regressions detected anywhere in the test suite.
