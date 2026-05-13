# Phase 5 TDD: Final Summary — v6.4.4 Connectivity Diagnostics Hardening

Date: 2026-04-11
Version: v6.4.4 (PATCH)

---

## Test Files

| File | Tests | ACs covered |
|------|-------|-------------|
| `.forge/phase-5-tdd/tests/v644-diagnostics-hardening.sh` | T1–T12 + AC-4, AC-11, AC-15 inline | AC-1..AC-16 |
| `.forge/phase-5-tdd/tests-hidden/v644-regression.sh` | T13–T14 | AC-17, AC-18, AC-19 |

---

## Test-to-AC Coverage Matrix

| Test | Description | ACs covered |
|------|-------------|-------------|
| T1 | No bare trackers.md direct Read in skill/core files | AC-2 |
| T2 | Path-note blockquote `> **Path note:**` in all 4 files | AC-1 |
| T3 | Resolve-once reuse: 1 Glob block, 6+ uses in onboard, 4+ uses in scaffold | AC-3 |
| T4 | 3-layer Glob pattern (layer 1: .claude/plugins/**, layer 2: **/) in onboard/scaffold/init | AC-5 |
| T5 | error_type field in mcp-detection.md Output Contract; all 5 enum values; null case | AC-6 |
| T6 | Classification Reference section with priority-order semantics and table header | AC-7 |
| T7 | TLS (8) and auth (6) patterns in mcp-detection match check-setup Step 9 | AC-8, AC-9 |
| T8 | not_found (ENOTFOUND, EAI_AGAIN, 404) and timeout (ETIMEDOUT, ECONNREFUSED, ECONNRESET) patterns | AC-10 |
| inline | Cross-reference to check-setup Step 9 in mcp-detection.md | AC-11 |
| T9 | TLS branch in Step 10; UNABLE_TO_VERIFY_LEAF_SIGNATURE present; TLS before auth ordering | AC-12 |
| T10 | curl probe, which curl guard, sc_base_url/env-block, well-known fallback, skip-probe path | AC-13 |
| T11 | NODE_OPTIONS count >= 4 in Step 10 region | AC-14 |
| inline | Step 10 retains auth/404/WARN/repository:read/catch-all branches | AC-15 |
| T12 | "Source control" in Step 10 messages; no "Issue tracker" in [FAIL]/[WARN] lines | AC-16 |
| inline | File-specific [WARN] fallback for missing trackers.md in onboard, scaffold, init | AC-4 |
| T13 | Existing check-setup-improvements.sh + check-setup-edge-cases.sh pass unchanged | AC-18 |
| T14 | CLAUDE.md not in diff; Input Contracts in core/ not modified; error_type not in Input Contract | AC-17, AC-19 |

**All 19 ACs covered.**

---

## AC Coverage Completeness

| AC | Covered by | Check type |
|----|-----------|------------|
| AC-1 | T2 | grep presence — `> **Path note:**` in 4 files |
| AC-2 | T1 | negative grep — zero bare trackers.md refs in onboard/scaffold/init; count=1 in mcp-detection |
| AC-3 | T3 | count grep — 1 Glob block, >=6 uses (onboard), >=4 uses (scaffold) |
| AC-4 | inline after T12 | grep presence — `[WARN]` fallback in all 3 skill files |
| AC-5 | T4 | pattern grep — layer 1 + layer 2 in all 3 files |
| AC-6 | T5 | grep presence + content — error_type + 5 enum values + null case |
| AC-7 | T6 | section heading grep — `### Classification Reference` + priority semantics + table header |
| AC-8 | T7 | pattern-by-pattern grep — 8 TLS patterns in mcp-detection.md |
| AC-9 | T7 | pattern-by-pattern grep — 6 auth patterns in mcp-detection.md |
| AC-10 | T8 | pattern grep — 3 not_found + 3 timeout patterns |
| AC-11 | inline after T8 | cross-ref grep — `check-setup.*Step 9` in mcp-detection.md |
| AC-12 | T9 | region extraction + pattern presence + ordering (tls_line < auth_line) |
| AC-13 | T10 | region extraction + 5 keyword checks (curl, which curl, sc_base_url, well-known, skip) |
| AC-14 | T11 | count in region — NODE_OPTIONS >= 4 in Step 10 |
| AC-15 | inline after T11 | keyword presence — auth/404/WARN/repository:read/catch-all in Step 10 |
| AC-16 | T12 | positive + negative grep — "Source control" yes, "Issue tracker" no in [FAIL]/[WARN] lines |
| AC-17 | T14 | git diff — CLAUDE.md not in diff |
| AC-18 | T13 | test execution — existing scenario files exit 0 |
| AC-19 | T14 | git diff — no Input Contract additions; error_type not in Input Contract section |

---

## Design Decisions

### Step 10 Region Extraction
Tests T9-T12 and the AC-15 inline check all derive the Step 10 region using the same helper pattern:
```bash
step10_start=$(grep -n '^10\.' "$SKILL" | head -1 | cut -d: -f1)
block4_start=$(grep -n 'Block 4' "$SKILL" | head -1 | cut -d: -f1)
step10_region=$(sed -n "${step10_start},${block4_start}p" "$SKILL")
```
This is consistent with the formal-criteria.md specification and avoids hardcoded line numbers.

### Hidden vs Visible Split
- **Visible (T1-T12):** Guide implementors — every pattern they must introduce is named explicitly.
- **Hidden (T13-T14):** Regression guard — runs existing test suite and verifies diff compliance. These are the "no surprises" safety net.

### Idempotency and Read-Only
All assertions use grep/sed/git-diff against the working tree. No files are created or modified. Tests can run in any order.

### Baseline Compatibility
T13 explicitly shells out to `check-setup-improvements.sh` and `check-setup-edge-cases.sh`. Per formal-criteria.md analysis, neither file is broken by the v6.4.4 Step 10 replacement because:
- check-setup-improvements.sh AC-3 checks NODE_OPTIONS `>= 3` — after v6.4.4 the count rises (4+ in Step 10 alone), so the `>= 3` assertion still passes.
- check-setup-edge-cases.sh edge case 4 checks that Step 7 does not re-Glob; v6.4.4 changes only Steps 9-10, so the count is unaffected.

---

## Files Referenced by Tests

| File | Role |
|------|------|
| `skills/check-setup/SKILL.md` | Step 9 (pattern parity reference), Step 10 (TLS treatment target) |
| `core/mcp-detection.md` | error_type Output Contract, Classification Reference table |
| `skills/onboard/SKILL.md` | Bare path migration, resolve-once (6+ uses) |
| `skills/scaffold/SKILL.md` | Bare path migration, resolve-once (4+ uses) |
| `skills/init/SKILL.md` | Bare path migration, 3-layer Glob |
| `CLAUDE.md` | Config contract stability (must not change) |
| `tests/scenarios/check-setup-improvements.sh` | Existing regression baseline |
| `tests/scenarios/check-setup-edge-cases.sh` | Existing regression baseline |
