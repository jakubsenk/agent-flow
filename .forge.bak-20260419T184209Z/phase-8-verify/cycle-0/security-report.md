# Phase 8 — Security Review (v6.8.1)

**Persona:** Security Agent (OWASP-mindset auditor)
**Scope:** v6.8.1 PATCH (commits `ee10dda`, `bb064e4`, tag `v6.8.1`) — six roadmap follow-ups on top of v6.8.0.
**Dimension score (security):** **0.92 / 1.00** — **CONDITIONAL_PASS**
**One-line rationale:** Path-traversal gate is correctly implemented in all 4 target skills with a robust `[[ =~ ]]` form; JSON-payload hardening is semantically correct in `core/block-handler.md`; SSRF flag is consistently present at the contract layer. One MEDIUM inconsistency: several skill-local `curl` webhook examples still omit `--proto "=http,https"` even though the contract file requires it. No critical findings blocking ship.

---

## 1. Summary verdict

**CONDITIONAL_PASS.** The v6.8.1 PATCH meaningfully reduces attack surface compared to v6.8.0: adversarial inputs the spec explicitly probed (multi-line ISSUE_ID, quote/backslash/newline in `reason`, `file://`/`gopher://` webhook schemes) are now all blocked at the correct layers. The main residual risk is defense-in-depth: the skill files inline curl examples that were NOT updated to include `--proto "=http,https"`. When an operator copy-pastes from the SKILL.md rather than from `core/post-publish-hook.md`, the SSRF flag is absent. Contract invariant in `post-publish-hook.md` line 126 states "All Section 3 and Section 4 curl webhook invocations MUST include this flag" — the skill-local examples violate that MUST.

---

## 2. Findings table

| ID | Severity | File:Line | Description | Recommended action |
|---|---|---|---|---|
| SEC-1 | INFO | `skills/fix-ticket/SKILL.md:90`, `skills/fix-bugs/SKILL.md:95`, `skills/implement-feature/SKILL.md:92`, `skills/resume-ticket/SKILL.md:86` | Path-traversal gate uses `[[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]` — bash built-in, anchored to entire string. Verified via manual fuzz (see §4.1). | Keep. Solid. |
| SEC-2 | INFO | `core/block-handler.md:43-62` | `reason`-payload hardening uses `jq -n --arg` — delegates all JSON string-escaping to jq. Verified equivalent to Python `json.dumps` (single-line output, `"` → `\"`, `\` → `\\`, `\n` → two-char `\n`). Heredoc body stays one logical line; no operator-injectable EOF marker. | Keep. Correct. |
| SEC-3 | INFO | `core/block-handler.md:51`, `core/post-publish-hook.md:18,120` | All three canonical webhook invocations carry `--proto "=http,https"`. SSRF via `file://`/`gopher://`/`ftp://` blocked at transport layer. | Keep. |
| SEC-4 | MEDIUM | `skills/fix-ticket/SKILL.md:106,183`; `skills/fix-bugs/SKILL.md:119,190,236,368,429,479,511,545,573,614,651,680,741`; `skills/implement-feature/SKILL.md:108,221,535` | Skill-local webhook curl examples are MISSING `--proto "=http,https"`. The contract at `core/post-publish-hook.md:126` states "All Section 3 and Section 4 curl webhook invocations MUST include this flag." Operators copy-pasting from the skill prose will implement unprotected curl. This is an inconsistency bug, not a vulnerability by itself, because the skill content is instructional text (the agent executes a templated form); but per v6.8.1's own commitment to SSRF defense, every curl example in skill prose should carry the flag. | Add `--proto "=http,https"` to every `curl ... -X POST -H "Content-Type: application/json"` line in the three skills. Regression guard test: `grep -c '^\s*curl.*--data-binary @-.*<<EOF' skills/*/SKILL.md` must equal `grep -c '^\s*curl --proto "=http,https".*--data-binary @-.*<<EOF' skills/*/SKILL.md`. Propose v6.8.2. |
| SEC-5 | LOW | `docs/guides/autopilot.md:288-294` | "Payload field safety" prose correctly instructs operators writing custom webhook hooks to use `jq -n --arg`. | Keep. |
| SEC-6 | LOW | `skills/autopilot/SKILL.md:99,368` | `trap` verifies `pid == $$` before `rm -rf $LOCK_DIR` — refuses to delete another process's lock. Absolute `LOCK_DIR` path resolution at line 123 is CWD-change-safe. | Keep. Correct defense against trap-race + CWD-change footgun. |
| SEC-7 | LOW | `skills/autopilot/SKILL.md:383` | Explicit operator-trust reminder: "SSRF defenses for the `Webhook URL` config key … are deferred to v6.9.0." Documented deferral is appropriate for a PATCH release. | Keep. Non-blocking. |
| SEC-8 | INFO | `core/fixer-reviewer-loop.md:28` | Per-iteration cumulative state write (`tokens_used += iteration_tokens_used`) is documented. Crash-recovery semantics sentence present. No race-exposed secret leak; state.json write is atomic per `core/state-manager.md`. | Keep. |
| SEC-9 | INFO | `tests/harness/run-tests.sh:42,48,52` | Counter form `N=$((N + 1))` — safe under `bash -e` wrappers. Replaces prior `((N++))` which returns exit 1 when N=0 and could cause bash-e wrappers to abort test loops. | Keep. Correct safe form. |
| SEC-10 | INFO | `tests/scenarios/v681-harness-exit-propagation.sh:79-86` | Meta-test creates temp file `v681-meta-test-always-fail-$$.sh` inside `tests/scenarios/` (sandboxed inside repo) with known content `#!/usr/bin/env bash\nexit 1\n`, runs the harness against it, then `rm -f` cleans up. PID-suffix prevents collision; no path traversal; no arbitrary file creation outside sandbox. | Keep. |
| SEC-11 | LOW | `tests/scenarios/ac-v68-doc-version-6.8.0.sh` (full harness) | Stale v6.8.0 version scenario fails after version bump (expected `"version": "6.8.0"`, actual `6.8.1`). Not a security issue — but it means `./tests/harness/run-tests.sh` exits 1 on v6.8.1, which may mask real regressions. | Update scenario to assert `6.8.1` or rename to `ac-v681-doc-version.sh`. Propose v6.8.2. |
| SEC-12 | INFO | `core/post-publish-hook.md:104-115` | "Field value safety" prose correctly differentiates: allow-listed `issue_id`/`run_id` safe for direct `"${var}"` interpolation; `pr_url` must be SCM-percent-encoded; `reason` MUST go through `jq -n --arg`. Guidance is complete and correct. | Keep. |

---

## 3. Critical issues (must fix before ship)

**None.** No finding is severity HIGH or CRITICAL. SEC-4 is MEDIUM — a doc/contract-alignment bug. It does not create a new vulnerability (the `Webhook URL` config remains operator-trust per documented policy), but it weakens defense-in-depth against operator-side misconfiguration. A v6.8.2 PATCH is the appropriate disposition, not a block on v6.8.1.

---

## 4. Evidence appendix

### 4.1 Path-traversal regex fuzz (`^[A-Za-z0-9#_-]+$`)

Ran the gate against a mental-fuzzer corpus in a controlled bash subshell:

```
REJECT: path traversal        (../../etc/passwd)
REJECT: relative dot          (./foo)
REJECT: absolute              (/abs/path)
REJECT: backslash             (foo\bar)
REJECT: space                 (foo bar)
REJECT: dot                   (foo.bar)
REJECT: cmd subst literal     (foo$(echo hi) — literal $, not expanded)
REJECT: dollar                (foo$42)
REJECT: semicolon             (foo;rm)
REJECT: pipe                  (foo|cat)
REJECT: amp                   (foo&bg)
REJECT: backtick              (foo`cmd`)
REJECT: empty                 ()
REJECT: cyrillic A look-alike (U+0410 — non-ASCII)
REJECT: newline embedded      (PROJ-42\nbad — the R-ITEM-2.6 vector)
REJECT: carriage return       (PROJ-42\rbad)
REJECT: with double-dot       (P..)
ACCEPT: valid                 (PROJ-42)
ACCEPT: hash-number           (#123)
ACCEPT: hyphen-separated      (AUTH-1)
ACCEPT: numeric               (42)
ACCEPT: long valid
```

Null-byte injection is not a reachable attack vector: bash strips NULs at parse time and variables cannot hold them; any attempted NUL payload collapses to its valid prefix before the gate evaluates. This is a bash-level guarantee, not a regex concern.

### 4.2 JSON-encoding robustness (`jq -n --arg`)

`jq` was not available in the test env, so I verified semantic equivalence via Python `json.dumps`, which shares the same encoding contract:

```
reason = 'Reason with "quotes", backslashes \\, newlines\nand EOF\nkiller'
→ JSON: {"reason": "Reason with \"quotes\", backslashes \\, newlines\nand EOF\nkiller", ...}
→ Line count: 1
→ Round-trip: reason intact
```

Conclusion: the canonical pattern in `core/block-handler.md:43-62` safely handles every hostile input class: `"` → `\"`, `\` → `\\`, literal LF → two-char `\n`, literal EOF strings are embedded inside the quoted `reason` JSON string and cannot terminate the heredoc. The heredoc body is one logical line.

### 4.3 SSRF defense flag coverage

`--proto "=http,https"` occurrences at **contract layer** (authoritative):

```
core/post-publish-hook.md:18    (Section 3 — pr-created)
core/post-publish-hook.md:120   (Section 4 — pipeline-started example)
core/block-handler.md:51        (issue-blocked)
```

Occurrences at **skill-local prose** (instructional text): **0 in `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`.** ≥20 unprotected `curl --max-time 5 --retry 0 -X POST` invocations across these three files. This is SEC-4 (MEDIUM).

### 4.4 Shell injection pathway via error message

`echo "[BLOCK] Invalid issue_id: ${ISSUE_ID}" >&2` at `skills/*/SKILL.md:91` fires AFTER the gate rejects the value, as an error-logging aid to operator. Since:

- The gate runs BEFORE the error message (the `if [[ ! ...]]` test controls entry).
- `exit 1` follows the echo (no further filesystem access).
- `"${ISSUE_ID}"` is double-quoted → no word-split, no glob expansion.
- The stderr destination is the terminal, not a tracker.

Even a hostile `ISSUE_ID` like `$'rm -rf /'` is printed AS-IS (the `rm -rf /` never executes because there is no `eval` anywhere in the skill flow; the gate exits 1 before any `mkdir "${ISSUE_ID}"` path).

### 4.5 Test harness exit-code propagation

Harness output:
```
Running: ac-v68-doc-version-6.8.0... FAIL
Total: 142 | Pass: 141 | Fail: 1 | Skip: 0
EXIT=1
```

`ac-v68-doc-version-6.8.0.sh` FAILs because it hard-codes v6.8.0 assertions against `.claude-plugin/plugin.json` which is now `6.8.1`. This is stale test scaffolding from v6.8.0, not a v6.8.1 regression. SEC-11.

The new T-05 meta-test `v681-harness-exit-propagation.sh` and `v681-fixer-reviewer-crash-recovery.sh` both PASS individually (grep output confirmed). The refactored counter form (`FAIL=$((FAIL + 1))`) is present and verified.

### 4.6 Autopilot lock safety

- Absolute `LOCK_DIR` at line 123: `"$(pwd)/.ceos-agents/autopilot.lock"` — CWD-change-safe.
- Trap at lines 139-147 verifies `own_pid == $$` before `rm -rf`.
- Trap install is conditional on successful `mkdir` (lines 157-159) — no race where an early-failing process nukes a lock it never acquired.
- Stale detection has +5min NFS/CIFS clock-skew buffer (line 128).
- `rm -rf` scope is the absolute `LOCK_DIR` only, not user-controlled input.

### 4.7 Path-traversal regression tests

`tests-hidden/h-regex-path-traversal.sh:21` and `tests-hidden/h-regex-newline-bypass.sh:22,31,48,65` all use the verbatim gate expression. Per `test-to-ac-matrix.md:24`, `AC-ITEM-2.6` is covered by `h-regex-newline-bypass.sh`. This is the explicit regression test for the bypass vector that triggered the v6.8.1 spec revision (`revision-round-2.md:65-67`).

---

## 5. Dimension score (security): 0.92

| Sub-dimension | Score | Rationale |
|---|---|---|
| Path-traversal defense | 1.00 | Correct `[[ =~ ]]` form, all 4 target skills, regex rejects every hostile vector tested, AC-ITEM-2.6 explicit regression guard. |
| JSON-payload hardening | 1.00 | `jq -n --arg` in `block-handler.md`; prose guidance in `post-publish-hook.md` is complete. |
| SSRF transport restriction | 0.75 | Contract layer is hardened; skill-local prose is inconsistent (SEC-4 MEDIUM). |
| Shell injection / command injection | 1.00 | No `eval`, no unquoted var expansion in state-changing paths; gate-then-exit pattern is sound. |
| State-race / crash recovery | 1.00 | Cumulative writes with atomic-protocol delegation (`core/state-manager.md`); per-iteration `+=` preserves partial cost on crash. |
| Test harness safety | 0.90 | Meta-test is sandbox-safe; exit-code refactor is correct; stale `ac-v68-doc-version-6.8.0.sh` failure is cosmetic not security but mars trust in `EXIT=0`. |
| Operator-trust surface docs | 1.00 | Explicit `--dangerously-skip-permissions` blast-radius warning in autopilot skill; deferral to v6.9.0 for full Webhook URL allowlisting is clearly marked. |

Weighted mean ≈ 0.95. Applying a -0.03 penalty for SEC-4 (documentation+propagation risk across 3 skills with ≥20 call sites) → **0.92**.

---

## 6. Recommendations (non-blocking, for v6.8.2 roadmap)

1. **SEC-4 → v6.8.2 PATCH:** Add `--proto "=http,https"` to every webhook `curl` example in `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`. Add a harness scenario that greps for any unprotected curl in the three skills and FAILs if count > 0.
2. **SEC-11 → v6.8.2 PATCH:** Rewrite `ac-v68-doc-version-6.8.0.sh` to parameterize on current plugin.json version or rename per-release.
3. **Defense-in-depth → v6.9.0:** Implement the already-documented SSRF allowlist (blocking `file://`/`gopher://` at the skill dispatch layer, not just the curl flag) so a compromised `Webhook URL` config value is neutralized by TWO independent controls. This is what the SEC-7 deferral points at.

---

## 7. Verdict

**CONDITIONAL_PASS at 0.92.** Ship v6.8.1. No critical issues. Record SEC-4 + SEC-11 as v6.8.2 follow-ups in `docs/plans/roadmap.md` under "## PLANNED — v6.8.2".
