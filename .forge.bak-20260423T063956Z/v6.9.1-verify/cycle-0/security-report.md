# v6.9.1 Phase 8 Security Report

## Score: 0.97 (baseline v6.9.0: 0.95)

Verdict: **PASS**. All 6 focus areas pass. No CRITICAL or HIGH findings. One MEDIUM (resume-ticket not in webhook-proto test scope). Low findings are carry-overs or scope deferrals. v6.9.1 Commit E fixes are clean; Commit F pipeline-resumed webhook is fully hardened.

---

## Per-focus verdicts (6 areas)

### 1. `_iso_to_epoch_crossplatform()` — PASS

**Location:** `skills/autopilot/SKILL.md:327-335`

- `_ts="$1"` is passed via `$_ts` shell variable — NOT interpolated into the python3 `-c` string. `sys.argv[1]` receives it as a process argument. No shell injection vector.
- `.replace('Z', '+00:00')` present in the python3 one-liner — correctly handles the `Z` suffix for `datetime.fromisoformat()` on py3.7–py3.10 (py3.11+ accepts `Z` natively; the replace is a no-op harmlessly). PASS.
- Fallback when python3 absent: `date -d "$_ts" +%s 2>/dev/null` (GNU date, Linux only). On BSD/macOS with no python3, this produces empty output. Caller handles empty via `[ -n "$asked_epoch" ] && [ "$asked_epoch" -gt 0 ]` — falls back to `pause_age_seconds=0`, meaning the issue is skipped (not prematurely aborted). Safe fail-open for the paused-pipeline skip path.
- `asked_at` originates from `state.json` field written by the orchestrator via `date -u +%FT%TZ` — trusted operator-controlled file; not user/tracker input. Injection surface is nil.

**Subscore: 1.00**

---

### 2. `pipeline-resumed` webhook (Commit F) — PASS

**Location:** `skills/resume-ticket/SKILL.md:37-60`, `core/post-publish-hook.md:194-243`

- `--proto "=http,https"` present at the curl invocation (line 56). PASS.
- `--max-time 5 --retry 0` present. PASS.
- `CLARIFICATION_ANSWER` sanitized: `$(printf '%s' "${CLARIFICATION_ANSWER}" | sanitize_block_reason | cut -c1-100)` — sanitized THEN truncated to 100 chars. PASS.
- `CLARIFICATION_QUESTION` sanitized: `$(printf '%s' "${CLARIFICATION_QUESTION}" | sanitize_block_reason)` — 6/6 pattern from v6.9.0 cycle-1 preserved here. PASS.
- Both values are read from `state.json` via `jq -r` (not directly from tracker) and then passed via `--arg` to jq. No inline JSON interpolation. PASS.
- `jq -nc` compact form used. PASS.
- Advisory failure: `> /dev/null 2>&1 || echo "[WARN] Webhook delivery failed"` present. PASS.
- `ON_EVENTS` gate: `[[ ",${ON_EVENTS}," == *",pipeline-resumed,"* ]]` — opt-in only; does not fire by default. PASS.

**Note:** `WEBHOOK_URL="${Webhook_URL}"` assignment used at line 40 (jq-pipe style). This is the documented convention in `core/post-publish-hook.md:106` ("Variable naming convention v6.9.1") — consistent with pipeline-paused pattern. PASS.

**Subscore: 1.00**

---

### 3. `parse_pause_timeout()` tr-based downcase (Commit E, Fix 1) — PASS

**Location:** `skills/autopilot/SKILL.md:273-297`

- `tr '[:upper:]' '[:lower:]'` is POSIX-portable. PASS.
- The `$raw` value is **already validated** against `^([0-9]+)[[:space:]]+([Hh][Oo][Uu][Rr][Ss]?|[Dd][Aa][Yy][Ss]?)$` before `tr` is invoked — only the regex-captured unit token `$unit` (which is `[A-Za-z]+` only, never a shell metachar) reaches `tr`. A malicious config value (e.g., `30 days; rm -rf`) would fail the `[[ =~ ]]` regex guard and take the fallback-to-default path — never reaching `tr`. PASS.
- `printf '%s' "$unit" | tr ...` — printf prevents any leading `-` from being interpreted as a flag. PASS.
- Numeric multiplication via `$(( n * 3600 ))` — `$n` is digit-only (guaranteed by `[0-9]+` capture), no injection vector. PASS.

**Subscore: 1.00**

---

### 4. `sanitize_block_reason()` LOWER-VAR anchor fix (Commit E, Fix 4) — PASS WITH NOTE

**Location:** `core/post-publish-hook.md:325`

Pattern is: `(^|[[:space:]])([A-Za-z_][A-Za-z0-9_]*(...keyword...))=[^[:space:]]+` → `\1\2=[REDACTED-LOWER-VAR]`

- `(^|[[:space:]])` is the portable word-boundary substitute. PASS.
- **Verified in v6.9.0 cycle-1 report §B:** `db_password=hunter2 ok` → `db_password=[REDACTED-LOWER-VAR] ok`. PASS.

**Residual gap (LOW, carry-over):** bare `password=value` at line start (no compound prefix) still not caught — noted as F-PATTERN-1 in cycle-1. NOT a v6.9.1 regression.

**Subscore: 1.00**

---

### 5. Anti-regression spot-checks (v6.9.0 baseline dimensions) — PASS

**SSRF defense (Dim 1):** `pipeline-resumed` is a new webhook firing site. It correctly carries `--proto "=http,https" --max-time 5 --retry 0`. Total hardened sites increases by 1 (resume-ticket). No site regressed.

**Note — test coverage gap (MEDIUM):** `tests/scenarios/v6.9.0-webhook-proto-coverage.sh` Assertion 1 checks `fix-ticket`, `fix-bugs`, `implement-feature` only (SKILL_FILES array). `skills/resume-ticket/SKILL.md` is NOT in scope. The new curl invocation at line 56 of resume-ticket is hardened but NOT verified by the existing test. This is a test-coverage gap, not an implementation defect, but it means future regressions at this site would not be caught by CI.

**block.detail HARD CONTRACT (Dim 4):** The pipeline-resumed payload spec (`core/post-publish-hook.md:202-215`) emits only `clarification.question` (sanitized) and `clarification.answer` (first 100 chars, sanitized) — never `block.detail`. Contract preserved. PASS.

**Credential redaction 17 patterns (Dim 5):** Doc-drift finding F-DOC-1 from cycle-1 is FIXED in v6.9.1 — all 3 stale "14-pattern" references updated to "17-pattern" in `state/schema.md:363`, `docs/guides/installation.md:84`, `docs/plans/roadmap.md:763`. Verified. This closes the cycle-1 MEDIUM finding. Score improvement on Dim 5.

---

### 6. Doc-only commits (A–D) security implications — PASS

- Commits A–D update automation-config docs, skills.md, agents.md, troubleshooting, pipelines, architecture, CHANGELOG, and spec amendments.
- CHANGELOG `## [6.9.0]` "Known Issues" section references deferred items (circuit breaker cross-run persistence, multi-host lock, prompt-injection for 8 agents, SSRF allowlist). These are already public roadmap items; no new exploit path revealed.
- No internal hostnames added to user-facing docs (grep confirms `docs/guides/` and `docs/reference/` are clean).
- No credentials, tokens, or internal infra details added.

**Subscore: 1.00**

---

## Findings

### MEDIUM

**F-RESUME-PROTO-TEST (NEW in v6.9.1):**
- Severity: MEDIUM (test coverage gap — implementation is hardened, CI cannot catch future regression)
- Location: `tests/scenarios/v6.9.0-webhook-proto-coverage.sh:13-24` (SKILL_FILES scope)
- Evidence: `skills/resume-ticket/SKILL.md` is NOT listed in `SKILL_FILES`. The new `pipeline-resumed` curl invocation (line 56, `--proto "=http,https"` present) is not verified by any test in `v6.9.0-webhook-proto-coverage.sh`. A future regression removing `--proto` from resume-ticket would not be caught.
- Fix: Add `"$REPO_ROOT/skills/resume-ticket/SKILL.md"` to `SKILL_FILES` array and update the `>= 18` threshold to `>= 19` in Assertion 1.
- Impact: Implementation correct; gap is in test coverage only.

### LOW (carry-overs, unchanged)

- **F-PATTERN-1** (cycle-1 carry-over): bare `password=value` at line start not caught by LOWER-VAR pattern.
- **F-01** (cycle-0 carry-over): jq missing on verifier host — environmental, no implementation impact.
- **F-02** (cycle-0 carry-over): SECURITY.md single-contact SPOF.
- **F-03** (cycle-0 carry-over): `parse_pause_timeout` whitespace-separated unit requirement documented.

---

## Score delta vs v6.9.0 baseline (0.95)

| Change | Direction |
|--------|-----------|
| F-DOC-1 MEDIUM fixed (14-pattern doc-drift → 17-pattern) | +0.02 |
| F-RESUME-PROTO-TEST MEDIUM introduced (new test scope gap) | −0.00 (impl correct; test gap only, partial credit) |
| All 6 focus areas PASS | neutral |

**Net: 0.97** (improved from 0.95; 1 new MEDIUM introduced but 1 old MEDIUM closed; new MEDIUM is test-only gap not impl defect)

---

## JSON verdict

```json
{
  "dimension": "security",
  "score": 0.97,
  "verdict": "PASS",
  "critical_findings": 0,
  "high_findings": 0,
  "medium_findings": 1,
  "low_findings": 4,
  "medium_notes": "F-RESUME-PROTO-TEST: resume-ticket not in webhook-proto CI test scope (impl correct, test gap only)",
  "baseline_score": 0.95,
  "completed_at": "2026-04-19T00:00:00Z"
}
```
