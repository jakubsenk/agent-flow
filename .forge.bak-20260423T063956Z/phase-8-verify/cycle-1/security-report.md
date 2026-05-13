# Phase 8 Security Report — v6.9.0 (cycle-1)

## Overall security score: 0.95

This is the cycle-1 adversarial security audit of the v6.9.0 implementation after the cycle-1 revision (8 bug-fixes from `T-revision-cycle-1-status.json`). Verdict: **PASS**. Cycle-1 fixes did NOT introduce new security defects, and previously-passing security scores either hold or improve. No CRITICAL or HIGH findings. One MEDIUM doc-drift finding (sanitize_block_reason 14→17 pattern count not propagated to 3 doc-only locations) and four LOW findings (3 carry-over from cycle-0 + 1 minor regex corner-case).

---

## Targeted cycle-1 recheck (NEW changes)

### A. NEW: pipeline-paused webhook firing wired into 6 orchestrator sites — VERIFIED

**Cycle-0 posture:** the firing snippet was documented in `core/agent-states.md` Section 2 but NOT inlined into the orchestrator skills (HIGH-5 in cycle-1 status JSON).

**Cycle-1 fix:** firing block inlined at all 6 NEEDS_CLARIFICATION detection sites:
- `skills/fix-ticket/SKILL.md:229` (triage) and `:453` (fixer) — both `| curl --proto "=http,https" --max-time 5 --retry 0`
- `skills/fix-bugs/SKILL.md:251` (triage) and `:508` (fixer)
- `skills/implement-feature/SKILL.md:416` (fixer)
- `skills/scaffold/SKILL.md:822` (scaffold-fixer)

**Discipline check (file:line of curl invocation):**
| Site | curl --proto | --max-time 5 | --retry 0 | Verdict |
|------|--------------|--------------|-----------|---------|
| fix-ticket triage `:249` | YES | YES | YES | PASS |
| fix-ticket fixer `:472` | YES | YES | YES | PASS |
| fix-bugs triage `:270` | YES | YES | YES | PASS |
| fix-bugs fixer `:527` | YES | YES | YES | PASS |
| implement-feature fixer `:435` | YES | YES | YES | PASS |
| scaffold-fixer `:841` | YES | YES | YES | PASS |

All 6 sites pipe through `jq -nc --arg` for safe JSON encoding (no inline interpolation into JSON literals — F-04-cycle-0 contract holds). Each site gates on `Webhook URL` configured AND `pipeline-paused` in `On events`. Variable provenance documented at `core/agent-states.md:78-86` for each site.

`RAW_QUESTION` is sanitized via `sanitize_block_reason()` BEFORE being passed to `jq --arg question` at every site (verified by grep — 6/6 sites contain `--arg question "$(printf '%s' "$RAW_QUESTION" | sanitize_block_reason)"`). Newline-injection vector closed because sed-line redaction strips and `jq --arg` handles remaining special chars structurally.

Webhook delivery failure remains advisory (`> /dev/null 2>&1 || echo "[WARN] Webhook delivery failed"`) — SSRF-failure-during-NEEDS_CLARIFICATION cannot brick a pipeline.

**Subscore:** 1.00 (improved from cycle-0 0.97, since all 6 sites are now actually wired with full SSRF + timeout discipline).

---

### B. NEW: sanitize_block_reason() expanded 14 → 17 patterns — VERIFIED

**Implementation:** `core/post-publish-hook.md:243-272` — function header documents "POSIX-portable, 17 patterns". Function body contains 17 sed -E pipelines.

**POSIX purity:** verified by `grep -E '\\b|\\S|\\d|\\w' core/post-publish-hook.md` — ZERO matches. The 3 new patterns (lowercase env-var, JSON-style, PGP END) all use POSIX-portable constructs only:
- Pattern 15 (`[REDACTED-LOWER-VAR]`): `(^|[[:space:]])([A-Za-z_][A-Za-z0-9_]*([Pp][Aa][Ss][Ss]([Ww][Oo][Rr][Dd])?|[Ss][Ee][Cc][Rr][Ee][Tt]|[Tt][Oo][Kk][Ee][Nn]|[Kk][Ee][Yy]))=[^[:space:]]+` — uses `(^|[[:space:]])` portable word-boundary substitute, `[A-Za-z_]` and `[A-Za-z0-9_]` portable char classes, `[Pp]` per-char case-insensitive (BSD `sed -E` lacks `(?i)`).
- Pattern 16 (`[REDACTED-PRIVATE-KEY-END]`): `-----END [A-Z ]*PRIVATE KEY[A-Z ]*-----` — pure literal + bracket class.
- Pattern 17 (`[REDACTED-JSON-FIELD]`): `"([Pp]assword|[Ss]ecret|[Tt]oken|[Aa]pi_?[Kk]ey|[Aa]ccess_?[Kk]ey|[Cc]redential)"[[:space:]]*:[[:space:]]*"[^"]+"` — `[^"]+` portable negated class, `[[:space:]]*` permits both `:"v"` and `: "v"` forms.

**Functional verification (live shell tests on GNU sed in Git-Bash on Windows):**
- `db_password=hunter2 ok` → `db_password=[REDACTED-LOWER-VAR] ok` PASS
- `my_secret=abc123 ok` → `my_secret=[REDACTED-LOWER-VAR] ok` PASS
- `api_token=ghp_xyz ok` → `api_token=[REDACTED-LOWER-VAR] ok` PASS
- `{"password": "secret123"}` → `{"password": "[REDACTED-JSON-FIELD]"}` PASS
- `{"token":"abc"}` (no whitespace after colon) → `{"token": "[REDACTED-JSON-FIELD]"}` PASS
- `-----END RSA PRIVATE KEY-----` → `[REDACTED-PRIVATE-KEY-END]` PASS

**Regression hold (cycle-0 14 patterns):**
- `PASSWORD=hunter2` → `PASSWORD=[REDACTED-VAR]` PASS (UPPER-VAR pattern)
- `https://user:pwd@example.com/path` → `[REDACTED-URL]` PASS (URL pattern)
- 12 other cycle-0 redaction tags grepped present in body.

**Injection-vector analysis:** the new patterns use only `\1` and `\2` backrefs (captured input groups already pre-filtered by bracket character classes that exclude shell metachars from match boundaries). No backtick / `$()` / `eval` execution at the sed layer — input is pure text-replace, output is the same text with redactions. `LC_ALL=C` set inside the function body for byte-locale stability across BSD/GNU sed.

**Multi-line credential body limitation:** documented at `core/post-publish-hook.md:275`. The cycle-1 fix adds the `-----END […]-----` sentinel pattern so both delimiters are now captured (cycle-0 only captured BEGIN). Body lines between BEGIN/END still leak through `sed -E` line-by-line — explicitly documented as v6.9.1+ enhancement; operators MUST treat `block.detail` multi-line PGP/SSH body as out of scope (only `block.reason` reaches webhook/history channels per HARD CONTRACT).

**Pattern coverage gap (LOW):** the LOWER-VAR pattern requires at least 1 char prefix before the credential keyword (e.g., `db_password`, `my_token`). Bare `password=value` / `token=abc` (no prefix, lowercase, at start-of-line) is NOT redacted by either UPPER-VAR or LOWER-VAR. This matches the documented spec intent (cycle-1 targeted "compound-key" forms like `db_password`); however, a bare lowercase `password=secret` at start-of-line slips through. Not a regression (cycle-0 had the same gap for lowercase entirely); see F-06 below.

**Subscore:** 1.00.

---

### C. NEW: `clarification.asked_at` field added to state.json — VERIFIED no PII

**Schema:** `state/schema.md:332` — `"asked_at": "ISO 8601 string (UTC, written at detection)"`.

**Field content:** UTC ISO-8601 timestamp (`YYYY-MM-DDTHH:MM:SSZ`) generated by `date -u +%FT%TZ` at the orchestrator detection site. ZERO PII content — pure timestamp. Used by autopilot pause-state detection (REQ-050b) to compute `pause_age_seconds = now − asked_at`.

**Channel exposure:**
- state.json on disk: INCLUDE (operator-controlled local file).
- `pipeline-paused` webhook payload `paused_at` field uses `${ASKED_AT}` directly (line `"--arg paused_at "${ASKED_AT}"` in 6 webhook firing sites). EXCLUDE risk: zero — same timestamp value, same exposure as `paused_at` field that already exists in payload schema.
- `/metrics` JSON output: not exposed (clarification fields not enumerated in metrics schema).
- pipeline-history.md: not exposed.

**Risk:** a UTC timestamp is not sensitive PII. The only side-channel concern would be if `asked_at` revealed operator workpattern (e.g., 24/7 vs business-hours), but this is ALREADY revealed by `pipeline.started_at`, `triage.started_at`, etc. No NEW exposure surface.

All 6 orchestrator sites correctly produce `ASKED_AT="$(date -u +%FT%TZ)"` immediately before the jq `--arg asked_at` write. Verified by grep — 6/6 matches at `skills/{fix-ticket:222,446, fix-bugs:244,501, implement-feature:409, scaffold:815}`.

**Subscore:** 1.00.

---

## Anti-regression check (10 cycle-0 dimensions)

### 1. SSRF defense (--proto webhook discipline) — score 1.00 (improved from 0.98)

**Cycle-0:** 0.98 — all 18 spec-enumerated webhook sites had `--proto`, but pipeline-paused webhook was documented-only (not inlined).

**Cycle-1:** improvement — pipeline-paused now inlined at all 6 sites WITH full `--proto "=http,https" --max-time 5 --retry 0` discipline. Total in-scope production curl invocations now: 27 (24 in skills/ scope-files + 3 in core/ inline examples). All 27 carry `--proto`.

`skills/scaffold/SKILL.md` non-pipeline-paused webhook calls (12 total) and `skills/publish/SKILL.md:31` (1) remain out-of-`--proto` scope per REQ-022 enumeration. Cycle-1 introduced 1 NEW scaffold webhook call (line 841) — and it correctly uses `--proto`. Net: cycle-1 only added hardened sites; never relaxed the discipline.

**Findings:** None.

---

### 2. Path traversal defense (Jira regex extension) — score 1.00 (held)

All 4 cycle-0 sites still in place: `[[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#._-]+$ || "${ISSUE_ID}" =~ ^\.+$ ]]`. Cycle-1 made no changes to issue-id validation. `core/agent-states.md:80` documents the snippet as gating prerequisite for the pipeline-paused firing site (defense-in-depth — the firing site uses `${ISSUE_ID}` only AFTER it has already passed validation).

**Findings:** None.

---

### 3. NEEDS_CLARIFICATION DoS caps + EXTERNAL INPUT defense — score 0.98 (improved from 0.97)

**Cycle-1 fixes that affect this dimension:**
- HIGH-3 fix: 6 jq reads of iteration counter changed from `.iteration // 0` (wrong path) to `.fixer_reviewer.iterations // 0` (correct path). Side benefit: per-iteration cap (REQ-045) now actually enforces because the iteration value is correctly read.
- HIGH-4 fix: `clarifications_consumed` double-increment closed. `skills/resume-ticket/SKILL.md:32` now explicitly forbids increment, deferring exclusively to orchestrator detection sites. Verified — only the negative comment "DO NOT increment" remains in resume-ticket. The 6 orchestrator sites contain `clarifications_consumed: ((.clarification.clarifications_consumed // 0) + 1)` (verified at fix-ticket:226,450 + analogous in other 4 sites). REQ-045 (max-3 cap) now fires at the documented rate (after 3 round-trips, not 1.5).
- CRITICAL-2 fix: case-insensitive `^[Qq]uestion:` regex closes a smuggling path where an attacker controlling agent output text could bypass clarification extraction by capitalizing the marker. While the prior bug was a denial-of-clarification rather than a security escape, the case-insensitive form is robustness.

EXTERNAL INPUT wrapping at `skills/resume-ticket/SKILL.md:25-31` unchanged. Receiver-side defense at `agents/fixer.md` and `agents/triage-analyst.md` unchanged.

**Subscore:** 0.98 (small improvement: rate-limit cap now actually enforces, was de-facto half-rate in cycle-0 due to double-increment).

---

### 4. block.detail HARD CONTRACT (4-channel exclusion) — score 1.00 (held)

8-row INCLUDE/EXCLUDE table at `state/schema.md:360-369` unchanged. `pipeline-paused` row (NEW v6.9.0) explicitly EXCLUDE — the cycle-1 webhook payload schema (`core/post-publish-hook.md:148-159`) confirms the firing-site jq filter only emits `clarification.question` (sanitized), `asked_by_agent`, `asked_at_step` — NEVER `block.detail`. NEGATIVE invariant preserved.

**Findings:** None.

---

### 5. Credential redaction (sanitize_block_reason POSIX-portable) — score 0.97 (slightly down from 1.00 due to MEDIUM doc-drift)

Cycle-1 expanded patterns 14→17 (verified above in §B). POSIX purity holds (no `\b`/`\S`/`\d`/`\w`). 17 redaction tags all present in function body and verifiable by `grep -F`.

**Doc-drift finding (MEDIUM — F-DOC-1):** 3 production doc files still cite "14 patterns" / "14-pattern":
- `state/schema.md:363` — `"sanitize_block_reason() (14-pattern POSIX-portable redaction; ..."` — should be `17-pattern`
- `docs/guides/installation.md:84` — `"(14-pattern credential scrubbing)"` — should be `17-pattern`
- `docs/plans/roadmap.md:763` — `"sanitize_block_reason() credential redaction (14 patterns)"` — should be `17 patterns`

These are doc-staleness issues with NO security impact (the function body is the authoritative implementation). Operator may be misled about coverage breadth. Recommend cycle-2 fix or v6.9.1 polish.

**Test coverage:** `tests/scenarios/v6.9.0-pipeline-history-credential-redaction.sh` (line 27 `--- Assertion 2 (AC-052): all 14 redaction tag strings present ---`) only checks the original 14 tags by name. The 3 NEW tags (`[REDACTED-PRIVATE-KEY-END]`, `[REDACTED-LOWER-VAR]`, `[REDACTED-JSON-FIELD]`) are NOT explicitly verified by the visible test — but they ARE present in the function (manually verified). The new e2e scenario `tests/scenarios/v6.9.0-needs-clarification-e2e.sh` (added cycle-1) covers them indirectly via Bug 6 verification. Recommend cycle-2: extend `v6.9.0-pipeline-history-credential-redaction.sh` to assert all 17 tags.

**Findings:** F-DOC-1 (MEDIUM — doc-only, 3 stale "14-pattern" mentions).

---

### 6. SPDX exact-match canonical — score 1.00 (held)

`.claude-plugin/plugin.json:9` and `marketplace.json:12` both `"license": "MIT"`. `.claude-plugin/plugin.json:8` `"repository": "https://example.invalid/ceos-agents.git"` (RFC 2606 reserved). LICENSE file present. No non-canonical variants. Cycle-1 made zero changes to plugin.json/marketplace.json.

**Findings:** F-01 (cycle-0 carryover — environmental jq missing). Implementation correct.

---

### 7. Issue/PR template PII warnings — score 1.00 (held)

`.gitea/issue_template/bug_report.md:7`, `.github/ISSUE_TEMPLATE/bug_report.md:7`: byte-identical PII warning. `.gitea/pull_request_template.md:10`, `.github/PULL_REQUEST_TEMPLATE.md:10`: byte-identical no-secrets checkbox. Cycle-1 made zero changes to templates.

**Findings:** None.

---

### 8. SECURITY.md viability — score 0.85 (held)

SECURITY.md unchanged. SLA softened-form "5 business days … OR coordinated-disclosure timeline extension by mutual agreement" preserved. `filip.sabacky@ceosdata.com` reporting channel preserved. Supported Versions section preserved.

**Findings:** F-02 (cycle-0 carryover — deferred secondary contact not in-file acknowledged; per-Gate-1 user-accepted SPOF).

---

### 9. Pause-state lifecycle DoS — score 1.00 (improved from 0.97)

**Cycle-1 fixes that affect this dimension:**
- CRITICAL-1 fix: `asked_at` now actually written by orchestrators. Cycle-0 noted `aborted_by_system` transition uses `pause_age_seconds = now − asked_at`; if `asked_at` was missing, the autopilot would compute `now − 0 = full-epoch-seconds` and ALWAYS exceed the timeout, prematurely aborting EVERY paused issue on first autopilot scan. Cycle-1 closes this CRITICAL by ensuring all 6 orchestrator detection sites write `asked_at` BEFORE transitioning to `paused`. **This is a security improvement** — the prior behavior was effectively a 100%-rate DoS on every paused pipeline.
- HIGH-4 fix: clarifications_consumed double-increment closed. The cap fires at the documented rate (3 round-trips), not the prematurely-tight rate of 1.5 round-trips. Reduces operator surprise.

`parse_pause_timeout()` unchanged. `aborted_by_system` + `abort_reason: "clarification_timeout"` mechanics unchanged.

**Subscore:** 1.00 (improved — the CRITICAL `asked_at` fix removes a real, exploitable DoS vector that cycle-0 had not detected).

**Findings:** F-03 (cycle-0 carryover — `parse_pause_timeout` regex requires whitespace separator; documented limitation).

---

### 10. Cross-cutting security — score 0.92 (held)

**4 BC negative invariants REQ-070..073:** unchanged. `pipeline-paused` webhook event remains additive (REQ-072 satisfied — no rename/removal of existing events). `### Pause Limits` remains OPTIONAL (REQ-070 satisfied). Triage-analyst Acceptance Criteria + reviewer AC Fulfillment sections preserved.

**Internal hostname removal:** production `skills/`, `docs/guides/`, `docs/reference/`, `tests/mock-project/` all clean of `gitea.internal.ceosdata.com`. The 9 hits in `docs/plans/*` are historical planning docs (archive). The 39 hits in `.forge/phase-{1,2,3,4}` are research/spec/plan artifacts (acceptable — research narrative, not user-facing).

**Cycle-1 added one NEW orchestrator-side test scenario** (`tests/scenarios/v6.9.0-needs-clarification-e2e.sh`) which references `${RAW_QUESTION}` from the orchestrator path — does not introduce any external host or credential-leakage vector.

**Findings:** F-05 (cycle-0 carryover — h-snippet-citation-marker-format.sh test-scope over-broad).

---

## Critical findings (CRITICAL/HIGH only)

**None.** No CRITICAL or HIGH findings introduced in cycle-1. Cycle-1 fixes (CRITICAL-1, CRITICAL-2, HIGH-3, HIGH-4, HIGH-5, MEDIUM-6, MEDIUM-7, MEDIUM-8) all closed correctly with no security regression.

Notably, the cycle-1 CRITICAL-1 fix (`asked_at` field now actually written) closes what was effectively an unidentified-by-cycle-0 100%-rate DoS on paused pipelines. Score improved from 0.97 → 1.00 on dimension 9.

---

## Other findings (MEDIUM/LOW)

### F-DOC-1. sanitize_block_reason() pattern count doc-drift (NEW in cycle-1)
- Severity: MEDIUM (doc-staleness; no security impact)
- Locations:
  - `state/schema.md:363` — cites "14-pattern POSIX-portable redaction"
  - `docs/guides/installation.md:84` — cites "14-pattern credential scrubbing"
  - `docs/plans/roadmap.md:763` — cites "credential redaction (14 patterns)"
- Evidence: `core/post-publish-hook.md:243` correctly says "17 patterns" and the function body has 17 patterns. The 3 doc references were not updated in cycle-1.
- Fix: simple find-replace `14-pattern → 17-pattern` and `14 patterns → 17 patterns` in the 3 docs. Recommend cycle-2 or v6.9.1 polish.
- Impact: NONE on security posture. Reporters / operators reading these docs are slightly under-informed about credential coverage breadth.

### F-PATTERN-1. sanitize_block_reason() bare-lowercase coverage gap (NEW finding, applies to cycle-0 patterns too)
- Severity: LOW
- Location: `core/post-publish-hook.md:270` (LOWER-VAR pattern)
- Evidence: pattern `[A-Za-z_][A-Za-z0-9_]*([Pp][Aa]…` requires at least 1 char prefix before keyword. Inputs like `password=hunter2` (lowercase, no prefix, start-of-line) match neither UPPER-VAR (line 256, requires `[A-Z_][A-Z0-9_]*`) nor LOWER-VAR (line 270, requires prefix). Only `db_password=`, `my_secret=`, etc. are caught.
- Fix (optional): change LOWER-VAR pattern to `(^|[[:space:]])([A-Za-z_][A-Za-z0-9_]*)?([Pp][Aa][Ss][Ss]([Ww][Oo][Rr][Dd])?|…)=…` so the prefix becomes optional.
- Impact: low — bare-lowercase form is unusual in software stack-trace `block.detail` (typical leaks are env-vars `ENV_PASSWORD=…` or compound-key configuration `db.password=…`). Roadmap candidate.

### F-01. h-license-spdx-roundtrip.sh fails locally due to missing jq — environmental (cycle-0 carryover)
- Severity: LOW. Unchanged from cycle-0 — verifier host lacks jq; implementation correct.

### F-02. SECURITY.md does not in-file acknowledge deferred secondary contact (cycle-0 carryover)
- Severity: LOW. Unchanged — per-Gate-1 user accepted SPOF + roadmap deferral.

### F-03. parse_pause_timeout requires whitespace-separated unit (cycle-0 carryover)
- Severity: LOW. Unchanged — fail-open to safe default.

### F-05. h-snippet-citation-marker-format.sh test-scope over-broad (cycle-0 carryover)
- Severity: LOW (downgraded from cycle-0 MEDIUM since not a security issue at all). Test-fragility, not implementation.

---

## Verdict

**PASS** (overall score 0.95 — improved from cycle-0 0.94)

All 10 security dimensions score ≥ 0.85. No CRITICAL or HIGH findings. Cycle-1 fixes closed 8 documented bugs (3 of which had security implications: CRITICAL-1 prior-undetected DoS-on-asked_at, HIGH-4 rate-limit-bypass, HIGH-5 webhook-not-firing) without introducing any regression. Score improvement comes from:
- Dim 1 SSRF: 0.98 → 1.00 (pipeline-paused now actually fires with full discipline)
- Dim 3 NEEDS_CLARIFICATION DoS: 0.97 → 0.98 (rate-limit now correctly enforces)
- Dim 9 Pause-state lifecycle: 0.97 → 1.00 (asked_at DoS closed)

Offset by:
- Dim 5 Credential redaction: 1.00 → 0.97 (3 doc-drift mentions of "14-pattern")

Net: +0.01 (0.94 → 0.95). MEDIUM finding F-DOC-1 (doc-drift) is non-blocking; recommend fix in cycle-2 or v6.9.1 polish bundle. Cycle-1 implementation matches the Phase 4 spec, all Agent C non-negotiables hold, all 4 BC negative invariants (REQ-070..073) satisfied.

Recommend: PASS Phase 8 cycle-1 security review; address F-DOC-1 in next polish pass; address F-PATTERN-1 (bare-lowercase) in v6.9.1 if telemetry shows real-world exposure.

## JSON verdict (REQUIRED at end)

```json
{
  "dimension": "security",
  "score": 0.95,
  "verdict": "PASS",
  "critical_findings": 0,
  "high_findings": 0,
  "medium_findings": 1,
  "low_findings": 5,
  "completed_at": "2026-04-20T13:30:00Z"
}
```

DONE
