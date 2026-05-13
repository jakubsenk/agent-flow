# Phase 8 Robustness Report — v6.9.0 cycle-1 (Devil's Advocate)

**Reviewer:** Phase 8 Devil's Advocate / Robustness Reviewer (cycle 1)
**Implementation under review:** working tree at `C:/gitea_ceos-agents/` after cycle-1 revision (per `.forge/phase-7-exec/T-revision-cycle-1-status.json`)
**Spec reference:** `.forge/phase-4-spec/final/{requirements,design}.md`
**Method:** Source-walk + adversarial execution of bash snippets (parse_pause_timeout, sanitize_block_reason, awk trim, grep extraction, ISO 8601 round-trip) on Git-Bash on Windows; functional run of `tests/scenarios/v6.9.0-needs-clarification-e2e.sh`; full harness `tests/harness/run-tests.sh`.

## Overall robustness score: 0.88

All 8 bug-fix verifications confirmed via direct grep + execution against the cycle-1 tree. The headline NEEDS_CLARIFICATION feature is now functionally end-to-end correct: orchestrators write `asked_at`, autopilot's `date -d` round-trip succeeds on the current platform, case-insensitive grep extracts agent-emitted `Question:`, the iteration cap reads the correct schema field, the resume-side double-increment is removed, the pipeline-paused webhook fires from all 6 dispatch sites with explicitly-scoped variables, and `sanitize_block_reason()` redacts the 3 previously-leaking pattern classes (lowercase env-var, JSON-style field, PGP END line). The history trim is now section-count-aware. Harness 183/183 PASS (was 140/140 in v6.8.0 baseline → 182/182 in v6.9.0 cycle-0 → 183/183 in cycle-1 with the new e2e scenario added). One MEDIUM cycle-0 scenario (parse_pause_timeout case-insensitivity) was NOT addressed in cycle-1 — still falls back gracefully to default 30 days, so impact is silent-config-loss not pipeline-break. Three pre-existing MEDIUM items from cycle-0 (snippet citation count, race condition, circuit breaker, multi-line context) remain deferred per the cycle-0 fast-follow list — these are explicitly out of cycle-1 scope.

---

## Cycle-0 scenario verification (8 in-scope + 4 deferred)

### Scenario 1 (CRITICAL): `clarification.asked_at` never written → autopilot auto-aborts

- **Status: FIXED**
- **Evidence:**
  - `grep -F 'asked_at: $asked_at' skills/*/SKILL.md` → **6 matches** (fix-bugs:248, fix-bugs:505, implement-feature:413, fix-ticket:226, fix-ticket:450, scaffold:819) — exactly 6 expected.
  - `grep -F 'ASKED_AT="$(date' skills/*/SKILL.md` → **6 matches** (fix-ticket:222, fix-ticket:446, fix-bugs:244, fix-bugs:501, implement-feature:409, scaffold:815). All use `date -u +%FT%TZ`.
  - state/schema.md line 332 documents `clarification.asked_at` as `"ISO 8601 string (UTC, written at detection)"` with explicit text "MUST be written at every detection site; absence causes autopilot to compute the full epoch as the pause age and prematurely abort the issue."
  - **Cross-platform date round-trip test (Git-Bash Windows, current platform):** `date -d "2026-04-20T11:09:26Z" +%s` → `1776683366` (success). The ISO 8601 `+%FT%TZ` format is GNU-`date -d` compatible. Note for ops: BSD/macOS `date` uses `-j -f "%Y-%m-%dT%H:%M:%SZ"` instead — autopilot at `skills/autopilot/SKILL.md:322` uses GNU syntax `date -d "$asked_at" +%s 2>/dev/null || echo 0` with graceful fallback (BSD systems return 0 → triggers spurious abort, but only on macOS hosts; documented as v6.9.1 portability item).

### Scenario 6 (CRITICAL): `Question:` (capital) vs `^question:` (lowercase) → empty extraction

- **Status: FIXED**
- **Evidence:**
  - `grep -iE 'grep.*-i.*[Qq]uestion:' skills/*/SKILL.md` → **6 matches** at all 6 detection sites. All use the exact form `grep -iE -A1 "^question:" "$..." | head -1 | sed -E 's/^[Qq]uestion: //'`.
  - Functional execution from e2e scenario (no jq required): agent output containing `Question: Should I use the legacy auth flow or the new OAuth2 PKCE flow?` is correctly extracted to the variable. Lowercase variant `question: lowercase variant test` also extracted (no regression).
  - Same fix applied to `context:` extraction (6 sites).

### Scenario 3 (HIGH): `.iteration` field path doesn't exist

- **Status: FIXED**
- **Evidence:**
  - `grep -F 'jq -r' skills/*/SKILL.md | grep -F 'iteration'` returned ZERO matches for the broken `.iteration` path; **6 matches** for the corrected `.fixer_reviewer.iterations` path (fix-ticket:214, fix-ticket:438, implement-feature:401, fix-bugs:236, fix-bugs:493, scaffold:807). Each is preceded by an inline comment `# Schema field is fixer_reviewer.iterations (NOT top-level .iteration)`. `state.iteration` no longer referenced anywhere.

### Scenario 2 (HIGH): `clarifications_consumed` double-incremented

- **Status: FIXED**
- **Evidence:**
  - `skills/resume-ticket/SKILL.md:32` Step 4 now reads: "**DO NOT increment `clarification.clarifications_consumed`** — the increment-side-of-truth lives in skill orchestrators ... at the NEEDS_CLARIFICATION detection site, BEFORE the transition to `paused`. Resume-ticket MUST NOT also increment, or the per-run cap (REQ-045, max 3) would fire at half the documented rate (after 1.5 round-trips instead of 3). Also: do NOT modify `clarification.last_clarification_iteration` here — it was already set by the orchestrator at detection time."
  - The negative-regression check `grep -qE '^4\. Increment .clarification\.clarifications_consumed' resume-ticket/SKILL.md` returns nothing.

### Scenarios 11+12 (HIGH/MEDIUM): pipeline-paused webhook never fires

- **Status: FIXED** (Scenario 11 — webhook firing) **/ DEFERRED** (Scenario 12 — circuit breaker, per cycle-1 scope: still doc-only, fast-follow v6.9.1)
- **Evidence (Scenario 11):**
  - `grep -E 'pipeline-paused' skills/*/SKILL.md` → **18 references across 4 skills** (the 6 firing sites each emit 3 lines: comment, gate, `--arg event "pipeline-paused"`). All 6 sites contain the curl invocation with `--proto "=http,https"` (SSRF defense), `--max-time 5` (no runaway latency), and `|| echo "[WARN] Webhook delivery failed"` (advisory-failure semantics).
  - Variable scoping verified at `skills/fix-bugs/SKILL.md:220-266`: the firing block defines `ASKED_BY_AGENT`, `ASKED_AT_STEP`, `ITERATION`, and `WEBHOOK_URL` immediately above the `jq -nc` payload builder, AND uses `RAW_QUESTION` defined 33 lines earlier (still in scope; no re-shadowing). `ITERATION` is `${ITERATION:-0}` defensive-defaulted in the `--argjson`.
  - **NEW finding (low-severity):** the `<!-- @snippet:webhook-curl -->` marker is followed by an INLINED jq+curl pipeline rather than a snippet expansion. The marker is therefore informational-only at this site (no programmatic enforcement that the inlined block matches the snippet). This is consistent with the cycle-0 finding that snippet citation counts drift (Scenario 10) — but is acceptable here because the inlined version is locally readable. Future maintenance hazard if the snippet evolves.

### Scenario 4 (HIGH security): `sanitize_block_reason()` lowercase + JSON leaks

- **Status: FIXED**
- **Evidence:** `core/post-publish-hook.md:243-273` rewritten to 17 patterns (was 14). New patterns: `[REDACTED-LOWER-VAR]` (line 270, regex `[A-Za-z_][A-Za-z0-9_]*([Pp][Aa][Ss][Ss]([Ww][Oo][Rr][Dd])?|[Ss][Ee][Cc][Rr][Ee][Tt]|[Tt][Oo][Kk][Ee][Nn]|[Kk][Ee][Yy])`), `[REDACTED-JSON-FIELD]` (line 271, JSON key/value form), `[REDACTED-PRIVATE-KEY-END]` (line 266, mirrors the BEGIN pattern).
- **Functional adversarial battery (extracted function, sourced and executed):**
  - `db_password=hunter2` → `db_password=[REDACTED-LOWER-VAR]` ✓
  - `{"password": "secret_xyz"}` → `{"password": "[REDACTED-JSON-FIELD]"}` ✓
  - `-----END PRIVATE KEY-----` → `[REDACTED-PRIVATE-KEY-END]` ✓
  - `PASSWORD=secret123` → `PASSWORD=[REDACTED-VAR]` (regression check passes)
  - JWT input still redacts to `[REDACTED-JWT]` (regression check passes)
  - `AWS_SECRET_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE` → `AWS_SECRET_ACCESS_KEY=[REDACTED-LOWER-VAR]` (rule-order observation: LOWER-VAR catches it before AWS_VAR — output is still redacted, just with a different tag than ideal; not a leak).
  - `my_api_key=secret123` → `my_[REDACTED-APIKEY]` (the APIKEY rule catches it; `my_` prefix leaks but the key value is redacted; acceptable).
- **Multi-line PGP body limitation:** explicitly documented at line 275 as v6.9.1+ enhancement. Operators are guided to use upstream defenses at the issue-tracker comment layer.

### Scenario 5 (HIGH): awk trim cuts by line not section

- **Status: FIXED**
- **Evidence:** `core/post-publish-hook.md:283-299` replaced the broken `awk '/^## /{i++} i>=NR-50'` with section-count-aware logic:
  ```bash
  total_sections=$(grep -c '^## ' "$file" 2>/dev/null || echo 0)
  if [ "$total_sections" -gt 50 ]; then
    cutoff=$((total_sections - 50))
    awk -v cutoff="$cutoff" '
      /^## / { section_num++ }
      section_num > cutoff
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
  ```
- **Functional simulation:** seeded a history with 60 sections (4 lines each, 240 total lines). After trim: **exactly 50 sections retained** (`run-11..run-60`). Old broken pattern `awk '/^## /{i++} i>=NR-50'` against the same input yields **17 sections** — empirical confirmation that the cycle-0 bug existed and the cycle-1 fix corrects it. Atomic `.tmp` + `mv` preserved.

### Scenario 7 (MEDIUM): `parse_pause_timeout()` case-sensitivity

- **Status: STILL-BROKEN** (graceful-fallback semantics; not promoted to high)
- **Evidence:** Function at `skills/autopilot/SKILL.md:272-296` reads `if [[ "$raw" =~ ^([0-9]+)[[:space:]]+(hours?|days?)$ ]]`. The `[[ =~ ]]` operator in bash is case-sensitive; no `tr 'A-Z' 'a-z'` or `shopt -s nocasematch` was added.
- **Adversarial test:**
  - `30 days` → `2592000` ✓
  - `30 Days` → `[WARN] Invalid Pause timeout '30 Days'; using default 30 days` → 2592000 (silent-loss-of-config; same as cycle-0)
  - `1 HOUR` → `[WARN] Invalid Pause timeout '1 HOUR'; using default 30 days` → 2592000 (same)
  - `1 hour` → `3600` ✓
- **Why not blocking:** failure mode is graceful — operator gets the default, plus a clearly-prefixed `[WARN]` log line. Pipeline never aborts. Risk is "operator believed they configured 365 days, actually got 30 days." Cycle-1 revision report does NOT list this in `bugs_fixed` so it was knowingly out-of-scope. Recommend pickup in v6.9.1 with two-line fix: `unit="${BASH_REMATCH[2],,}"` (bash 4 lowercase) OR `unit=$(printf '%s' "${BASH_REMATCH[2]}" | tr '[:upper:]' '[:lower:]')` (POSIX-portable).

---

## Deferred from cycle-0 (per fast-follow list — NOT in cycle-1 scope)

### Scenario 8 (MEDIUM): multi-line `context:` truncation
- **Status: DEFERRED.** Same code path as cycle-0. Acceptable since `core/agent-states.md` documents `context` as "max 500 chars" and most agent emissions are single-line. Recommend awk-block extraction in v6.9.1.

### Scenario 9 (HIGH): autopilot-vs-resume race condition
- **Status: DEFERRED.** Per fast-follow list. Mitigation requires adding compare-and-swap (`jq 'if .status=="paused" then ... end'`) to autopilot's abort write OR a per-issue lock. Cycle-1 partially mitigated by Scenario 1 fix: now that `asked_at` is correctly written, the spurious-abort race window is dramatically reduced (only fires on genuinely-old paused issues, not on every cron tick).

### Scenario 10 (MEDIUM): snippet citation count drift
- **Status: DEFERRED.** Per fast-follow list. The new inlined webhook firing blocks (Scenario 11 fix) compound the drift problem — they include `<!-- @snippet:webhook-curl -->` markers but inline the body. Recommend pickup in v6.9.1.

### Scenario 12 (MEDIUM): circuit breaker has zero implementation
- **Status: DEFERRED.** Per fast-follow list. The new pipeline-paused firing sites are NOT integrated into a shared bash counter; if Webhook URL is dead, each pause adds ~5s of latency. Acceptable for v6.9.0 since pause is rare relative to step-completed.

---

## NEW failure scenarios introduced by cycle-1 changes

### NEW-1 (LOW): `<!-- @snippet:webhook-curl -->` marker drift in inlined firing blocks
- **Severity:** LOW (maintenance hazard, not runtime)
- **Trigger:** Future maintainer edits `core/snippets/webhook-curl.md` expecting the change to propagate; but the 6 cycle-1 firing sites contain INLINED jq+curl that is locally readable but does NOT auto-update.
- **Mitigation:** Either (a) make the snippet self-expanding via a build step, or (b) add a CI check that diffs the inlined block against the snippet body. Recommend cycle-2 OR v6.9.1 pickup.

### NEW-2 (LOW): rule-ordering tag-quality issue in sanitize_block_reason
- **Severity:** LOW (no leak; suboptimal tag)
- **Trigger:** `AWS_SECRET_ACCESS_KEY=AKIA...` is matched by the new `[REDACTED-LOWER-VAR]` rule (line 270) BEFORE the more-specific `[REDACTED-AWS-VAR]` rule (line 260) gets a chance — because the LOWER-VAR rule appears later in the pipeline and re-matches the tag's adjacent input. Wait — actually re-checking: rules apply in order, AWS_VAR is at line 260, LOWER-VAR at 270. Re-test: `AWS_SECRET_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE` → `AWS_SECRET_ACCESS_KEY=[REDACTED-LOWER-VAR]`. The AWS_VAR rule matches `AWS_(SECRET|ACCESS_KEY)_?ID?=` — note `_?ID?` requires an optional ID suffix. `AWS_SECRET_ACCESS_KEY` does NOT match because the regex expects `AWS_SECRET_ID` or `AWS_ACCESS_KEY_ID`, not `AWS_SECRET_ACCESS_KEY`. So the LOWER-VAR rule correctly catches it. Not actually a bug — output is `[REDACTED-LOWER-VAR]` which is still safe; just a less-specific tag than ideal. Recommend tightening AWS_VAR regex in v6.9.1 to `AWS_(SECRET|ACCESS)(_KEY)?(_ID)?=`.

### NEW-3 (NONE): variable-scope leakage check
- **Verified clean.** `RAW_QUESTION`, `ASKED_BY_AGENT`, `ASKED_AT_STEP`, `ITERATION`, `WEBHOOK_URL` are all defined within the `if [ -n "${Webhook_URL:-}" ] ...; then` block (or just before it). `RAW_QUESTION` is set at line 220 of fix-bugs/SKILL.md; the firing block at line 251-273 reads it. No `local` or function scope; bash global scope is intentional. Defensive `${ITERATION:-0}` guards `--argjson`. No new bugs.

### NEW-4 (NONE): sed pattern collision check
- **Verified clean.** Tested input `db_token=abc and {"token": "xyz"}` → `db_token=[REDACTED-LOWER-VAR] and {"token": "[REDACTED-JSON-FIELD]"}`. Tested input with `[REDACTED-LOWER-VAR]` literal already present → not re-matched (the bracketed token doesn't match any of the 17 patterns). Tested input `stuff db_password=[REDACTED-LOWER-VAR] more` → output unchanged. No re-match cascades.

### NEW-5 (NONE): pipeline-resumed webhook event
- **Out of scope per spec.** When resume-ticket transitions back to `running`, no `pipeline-resumed` event fires. Spec does not require this. Note for v6.9.1 backlog: operators consuming `pipeline-paused` may want a paired `pipeline-resumed` for state-machine completeness; current workaround is to consume the next `step-completed` event.

### NEW-6 (LOW): `${Webhook_URL}` vs `${WEBHOOK_URL}` casing inconsistency
- **Severity:** LOW (works in practice)
- **Trigger:** The firing site at `skills/fix-ticket/SKILL.md:231` reads `${Webhook_URL:-}` (matching the original config-key casing from CLAUDE.md), then assigns `WEBHOOK_URL="${Webhook_URL}"` and uses `${WEBHOOK_URL}` in curl. Both refer to the same logical config but cycle through TWO bash variable names. Future maintainer might accidentally introduce drift if they only update one. Cosmetic; not breaking.

---

## Critical findings (HIGH+) — should block release or fast-follow

| # | Scenario | Severity | Cycle-1 Status | Action |
|---|----------|----------|----------------|--------|
| 1 | `asked_at` never written | CRITICAL | **FIXED** | none |
| 6 | `Question:` vs `^question:` case mismatch | CRITICAL | **FIXED** | none |
| 2 | clarifications_consumed double-increment | HIGH | **FIXED** | none |
| 3 | `.iteration` field doesn't exist | HIGH | **FIXED** | none |
| 4 | sanitize_block_reason credential leaks | HIGH | **FIXED** (3 new patterns; multi-line PGP body still bypasses, documented) | v6.9.1 multi-line awk |
| 5 | awk trim cuts by line not section | HIGH | **FIXED** | none |
| 11 | pipeline-paused webhook firing | HIGH | **FIXED** (6 sites wired) | none |
| 9 | autopilot-vs-resume race | HIGH | DEFERRED (window dramatically reduced by Scenario 1 fix) | v6.9.1 |

Combined: the headline NEEDS_CLARIFICATION feature is **functionally end-to-end correct in cycle-1**. The new e2e test scenario (`tests/scenarios/v6.9.0-needs-clarification-e2e.sh`) actually executes the bash code and feeds adversarial inputs — a discipline shift from cycle-0's doc-only assertions. Harness 183/183 PASS.

---

## Recommendations for v6.9.1 (delta from cycle-0)

- **Already on cycle-0 list (still pending):** Scenarios 7 (parse_pause_timeout case), 8 (multi-line context), 9 (race), 10 (snippet citation), 12 (circuit breaker), multi-line PGP body redaction.
- **NEW from cycle-1:** snippet marker drift in inlined webhook firing blocks (NEW-1), AWS_VAR regex tightening (NEW-2), `pipeline-resumed` event for state-machine completeness (NEW-5), `${Webhook_URL}/${WEBHOOK_URL}` variable-naming hygiene (NEW-6).
- **BSD `date` portability:** autopilot's `date -d "$asked_at" +%s` works on GNU date (Linux + Git-Bash on Windows) but fails on BSD/macOS, returning 0 → premature abort on macOS hosts. Document explicitly in `docs/guides/autopilot.md` OR add a `gdate` fallback OR use `python3 -c "import datetime, time; print(int(datetime.datetime.fromisoformat(...).timestamp()))"`. (Confirmed working on current Git-Bash Windows platform.)
- **Phase 8 discipline:** the cycle-1 e2e scenario IS the discipline-overhaul stub. Future v6.x should expand the pattern: every claim of "feature X works" should have a scenario that sources the actual bash code from the source-of-truth markdown and feeds adversarial inputs (NOT just `grep -F "feature X"` doc presence).

---

## Verdict + JSON

```json
{
  "dimension": "robustness",
  "score": 0.88,
  "verdict": "PASS",
  "cycle": 1,
  "previous_cycle_score": 0.52,
  "improvement": "+0.36",
  "scenarios_fixed": 7,
  "scenarios_partially_fixed": 1,
  "scenarios_still_broken": 1,
  "scenarios_deferred": 4,
  "new_low_findings": 4,
  "new_critical_findings": 0,
  "completed_at": "2026-04-20T13:15:00Z",
  "blocking_for_release": [],
  "fast_follow_v691": [
    "Scenario 7 (parse_pause_timeout case-insensitivity — graceful fallback so non-blocking)",
    "Scenario 8 (multi-line context truncation)",
    "Scenario 9 (autopilot-vs-resume race — window reduced by Scenario 1 fix)",
    "Scenario 10 (snippet citation count enforcement)",
    "Scenario 12 (circuit breaker implementation)",
    "Multi-line PGP/SSH key body redaction",
    "BSD date portability for autopilot pause-age computation",
    "NEW-1: snippet marker drift in inlined webhook firing blocks",
    "NEW-2: AWS_VAR regex tightening",
    "NEW-5: pipeline-resumed webhook event for state-machine completeness",
    "NEW-6: Webhook_URL/WEBHOOK_URL variable-naming hygiene"
  ],
  "harness_baseline": "183/183 PASS",
  "e2e_scenario_added": "tests/scenarios/v6.9.0-needs-clarification-e2e.sh",
  "notes": "All cycle-0 CRITICAL + 4 of 5 HIGH bugs FIXED. The e2e scenario actually executes bash code and feeds adversarial inputs (discipline shift from cycle-0). Score moved from 0.52 (FAIL/CONDITIONAL_PASS) to 0.88 (PASS). Above the 0.7 floor and meeting the 0.85+ stretch goal."
}
```

DONE
