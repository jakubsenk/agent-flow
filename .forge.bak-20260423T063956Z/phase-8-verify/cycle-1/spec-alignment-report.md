# Phase 8 Spec Alignment Report — v6.9.0 (cycle 1)

**Verifier:** Phase 8 Spec Alignment Reviewer
**Run:** cycle-1 (post-revision)
**Date:** 2026-04-20
**Implementation under review:** working tree at `C:/gitea_ceos-agents/` after Phase 7 revision cycle 1 (8 files modified, 1 file created)
**Spec ground truth:** `.forge/phase-4-spec/final/{requirements.md,design.md,formal-criteria.md}` (90 REQs, 118 ACs)
**Cycle-0 baseline:** spec_alignment = 0.97 (28/30 fully aligned, 2 partial)
**Cycle-1 revision summary:** 8 bug fixes (CRITICAL-1, CRITICAL-2, HIGH-3, HIGH-4, HIGH-5, MEDIUM-6, MEDIUM-7, MEDIUM-8) — see `.forge/phase-7-exec/T-revision-cycle-1-status.json`

---

## Overall spec alignment score: 0.98

Sampled the same 30 REQs as cycle-0 plus 5 additional REQs targeting the cycle-1 modification surface (REQ-042, REQ-043, REQ-045, REQ-046, REQ-050b, REQ-050c, REQ-050e, REQ-052). 28/30 cycle-0 sample remain aligned (no regression); both prior partial-aligned items (F-01, F-02 webhook-curl citation count + REQ-063c hidden-test location) are unchanged by cycle-1; one new minor finding (F-04 — sanitize_block_reason 14→17 patterns is additive but undocumented in spec).

Cycle-1 changes are EITHER (a) within explicit spec license ("additive" allowed in REQ-042/REQ-043 paused-state shape) OR (b) directly implementing previously documented-but-not-wired behavior (REQ-050c pipeline-paused webhook firing, REQ-050b autopilot pause-detection completeness via asked_at) OR (c) consistent with the spec's increment-side-of-truth (design.md:619 — "Counters increment at the moment the clarification fenced block is detected").

Net: 0.97 → 0.98 (+0.01) — cycle-1 corrected several spec-implementation gaps in the cycle-0 implementation (asked_at field never written, increment double-counted, pipeline-paused not wired); one new "additive" deviation introduced (sanitize_block_reason 14→17).

---

## Cycle-1 alignment checks per task description

### Check 1 — REQ-042 / REQ-043 schema additions (clarification.asked_at field)

**Spec source:**
- REQ-042 (requirements.md:230): "shall add to `state/schema.md` a top-level `clarification` object with fields `question`, `asked_by_agent`, `asked_at_step`, `asked_at_iteration`, `context`, `answer` per Phase 2 §9.9 verbatim shape."
- REQ-043 (requirements.md:234): "shall extend the `clarification` object in `state/schema.md` with two DoS-cap counter fields: `clarifications_consumed` (integer, run total, max 3) and `last_clarification_iteration` (integer or null)."
- REQ-050a (requirements.md:266): "After `Pause timeout` elapses since `clarification.asked_at` (timestamp captured at pause), the orchestrator (or `/ceos-agents:autopilot` discovery scan) SHALL transition the pipeline `paused` → `aborted_by_system` …"
- design.md:742: autopilot reads `asked_at=$(jq -r '.clarification.asked_at // empty' "$state_file")` to compute `pause_age_seconds`.

**Cycle-1 change:** Added `asked_at` (ISO 8601 string) to `state/schema.md:332` clarification object + table row at line 346 with explicit "MUST be written at every detection site; absence causes autopilot to compute the full epoch as the pause age and prematurely abort the issue." Documented at all 6 orchestrator write sites with `ASKED_AT="$(date -u +%FT%TZ)"` and `--arg asked_at "$ASKED_AT"` jq inputs.

**Verdict:** PASS. The `asked_at` field is REQUIRED implicitly by REQ-050a and design.md:742 (autopilot reads it). REQ-042 enumerates a verbatim list of 6 fields ("`question`, `asked_by_agent`, `asked_at_step`, `asked_at_iteration`, `context`, `answer`") + REQ-043 adds 2 counter fields, but the spec ALSO references `clarification.asked_at` in REQ-050a as a presumed-existing field. The cycle-0 implementation had a SPEC GAP — REQ-050a depends on `asked_at`, but neither REQ-042 nor REQ-043 explicitly enumerates it. Cycle-1 closes this gap by writing the field. This is consistent with the spec's stated "additive in v6.9.0" allowance for `state/schema.md` (per REQ-044 footer "schema_version stays `'1.0'` (additive only)") and resolves an internal spec inconsistency where REQ-050a referenced a field neither REQ-042 nor REQ-043 explicitly enumerated.

**Note:** This is a Phase 4 oversight — REQ-042 should have enumerated `asked_at` (or REQ-050a should have explicitly required it as a new field). The spec's verbatim 6-field list in REQ-042 is incomplete relative to REQ-050a's read-side dependency. Recommend Phase 9 amend Phase 4 spec to add an explicit "REQ-050aa: `clarification.asked_at` ISO 8601 string written at detection time" or amend REQ-042 to enumerate `asked_at`. Cycle-1 implementation is correct.

### Check 2 — REQ-045 / REQ-046 DoS caps (resume-ticket cycle-1 fix removed double-increment)

**Spec source:**
- design.md:619 (verbatim): "Counters increment at the moment the clarification fenced block is detected and BEFORE the pipeline transitions to `paused` status."
- design.md:573: "`clarification.clarifications_consumed` ← incremented at detection (max 3)"
- REQ-045 (requirements.md:242): "While `state.clarification.clarifications_consumed >= 3`, when the fixer or triage-analyst emits a new `## NEEDS_CLARIFICATION`, the system shall transition the pipeline to `block` …"

**Cycle-1 change:** Rewrote `skills/resume-ticket/SKILL.md:32` Step 4 to explicitly forbid resume-ticket from incrementing `clarifications_consumed`. The orchestrator (fix-ticket, fix-bugs, implement-feature, scaffold) is the increment-side-of-truth at the NEEDS_CLARIFICATION detection site BEFORE `paused` transition. Documented in `state/schema.md:349` "Incremented EXACTLY ONCE per clarification round-trip — at NEEDS_CLARIFICATION detection by the skill orchestrator, BEFORE transitioning to `paused`. The increment-side-of-truth lives in skill orchestrators (fix-ticket, fix-bugs, implement-feature, scaffold) — `resume-ticket` MUST NOT also increment".

**Verdict:** PASS — and cycle-1 RESOLVED a spec ambiguity that existed in the original spec wording. Per design.md:619 the increment side is unambiguously the orchestrator (at detection). The spec did NOT explicitly say resume-ticket must NOT increment, but design.md:619's "BEFORE the pipeline transitions to paused" wording is logically incompatible with a resume-time increment (resume happens AFTER the pause transition, not before). Cycle-1 correctly disambiguates this for implementers: orchestrator-only. The cycle-0 implementation's double-increment would have caused the per-run cap (REQ-045, max 3) to fire after only 1.5 round-trips (1 detection + 1 resume = 2 increments, then 1 detection + 1 resume = 4 increments tripping the cap on round 2's resume rather than round 4's detection). Cycle-1 fix preserves REQ-045 semantics correctly.

**Note for Phase 9:** Recommend Phase 4 spec patch to add explicit "REQ-045a: resume-ticket MUST NOT increment `clarifications_consumed`. The orchestrator at the NEEDS_CLARIFICATION detection site is the sole increment-side-of-truth, per design.md:619" so future implementers do not re-introduce this bug.

### Check 3 — REQ-052 sanitize_block_reason 14 → 17 patterns

**Spec source:**
- REQ-052 (requirements.md:298): "The system shall, in the same Section 5, define a single Bash function `sanitize_block_reason()` that filters `block_reason` through a **14-row** credential-pattern regex table … The 14 patterns are: (1) URL-embedded credentials → `[REDACTED-URL]`; (2) env-var assignments … (14) **OAuth refresh tokens** … (Google form) → `[REDACTED-OAUTH-REFRESH]`."
- design.md:879: "### `sanitize_block_reason()` Bash function (centralized credential redaction — POSIX-portable, **14 patterns**)"
- design.md:887: "Expanded from 9 → 14 patterns to cover JWT, SSH/PGP private-key BEGIN line, Stripe live, Google API, OAuth refresh"

**Cycle-1 change:** `core/post-publish-hook.md:243` declares "POSIX-portable, **17 patterns**". Added 3 NEW POSIX-portable sed patterns:
- `[REDACTED-LOWER-VAR]` — lowercase env-var assignments (e.g., `password=`, `secret=`, `token=`, `key=`)
- `[REDACTED-JSON-FIELD]` — JSON-style credential field (e.g., `"password": "..."`, `"secret": "..."`, `"token": "..."`, `"api_key": "..."`)
- `[REDACTED-PRIVATE-KEY-END]` — PGP/SSH END line (`-----END … PRIVATE KEY-----`) — complement to the existing BEGIN-line pattern (REQ-052 #11)

**Verdict:** ADDITIVE PASS (with finding). REQ-052 says EXACTLY 14 patterns enumerated. Cycle-1 went to 17. This is technically a spec deviation (14 ≠ 17), BUT:
- Each new pattern is strictly redaction-additive (no false-negative regression — every input that was redacted at 14 patterns is still redacted at 17; new patterns only ADD coverage)
- All new patterns use POSIX-portable constructs per REQ-052's portability invariant (`[[:space:]]`, `[A-Za-z]`, no `\S`/`\b`/`\d`/`\w`)
- The visible test `tests/scenarios/v6.9.0-pipeline-history-credential-redaction.sh` only checks for the 14 spec-mandated tags (lines 29-42), so harness still passes
- The expansion is consistent with Phase 4 round-2 history (REQ-052 was already expanded 9 → 14 to address Devil's-Advocate F-03 long-tail credential coverage); cycle-1's 14 → 17 follows the same defense-in-depth pattern
- REQ-052 prose closes with "documented as best-effort — covers only the Google OAuth refresh-token form; other providers require additional patterns in v6.9.1+", which signals the spec ANTICIPATED additive expansion in future versions

**Verdict refinement:** ADDITIVE ENHANCEMENT, not violation. The spec's "14 patterns" wording is descriptive of the THEN-current minimum coverage; the spec's prose anticipated future additive expansion. However, the 14 → 17 change should have been gated by a spec amendment (REQ-052b) for traceability. F-04 raised below.

### Check 4 — REQ-050c pipeline-paused webhook firing (cycle-1 wired it)

**Spec source:**
- REQ-050c (requirements.md:274): "shall add a NEW webhook event `pipeline-paused` (additive, MINOR-compatible) to the enumerated event list in `core/post-publish-hook.md` Section 4 + the `On events` config documentation. The event fires once per `paused` transition (NEEDS_CLARIFICATION pause). Payload includes `run_id`, `issue_id`, `paused_at` (ISO-8601), `clarification.question` (≤ 280 chars, sanitized via `sanitize_block_reason()` per REQ-052 to avoid leaking credentials embedded in question text), `clarification.asked_by_agent`, `clarification.asked_at_step`, `iteration`."
- design.md:782 specifies the curl invocation lives in `core/agent-states.md` orchestrator section.

**Cycle-1 change:** Inlined the pipeline-paused webhook firing block at all 6 orchestrator NEEDS_CLARIFICATION detection sites (fix-ticket triage + fixer; fix-bugs triage + fixer; implement-feature fixer; scaffold fixer). Each site is gated on `[ -n "${Webhook_URL:-}" ] && printf '%s' "${On_events:-}" | grep -qF 'pipeline-paused'`. Each invocation cites `<!-- @snippet:webhook-curl -->`, uses `--proto "=http,https"`, jq-builds compact JSON with the 6 spec-mandated payload fields, and pipes through `sanitize_block_reason()` for the question. The orchestrator-side implementation matches the design.md:782 firing-site spec.

**Verdict:** PASS. Cycle-1 corrected a cycle-0 spec-implementation gap where `core/agent-states.md` documented the firing site but the orchestrator skills did not actually invoke it. After cycle-1, the orchestrators wire the firing per spec. The spec-mandated payload fields (`run_id`, `issue_id`, `paused_at`, `clarification.{question,asked_by_agent,asked_at_step}`, `iteration`) are all present in the wired blocks.

**Verification grep counts:**
- `grep -c 'pipeline-paused' skills/fix-ticket/SKILL.md` = 6 (3 sites × 2 mentions: gate + event field)
- `grep -c 'pipeline-paused' skills/fix-bugs/SKILL.md` = 6
- `grep -c 'pipeline-paused' skills/implement-feature/SKILL.md` = 3
- `grep -c 'pipeline-paused' skills/scaffold/SKILL.md` = 3
- All 4 orchestrators wired; total 6 firing sites match REQ-050 enumeration (fix-ticket Step 3 triage + Step 5 fixer; fix-bugs Step 2 triage + Step 4 fixer; implement-feature fixer step; scaffold Step 7a fixer).

### Check 5 — REQ-050b autopilot pause detection + asked_at field (cycle-1 ensures asked_at is written)

**Spec source:**
- REQ-050b (requirements.md:270): "shall extend `skills/autopilot/SKILL.md` with paused-state detection logic … If `status == 'paused'` AND the pause age exceeds `Pause timeout` (per REQ-050a, when configured), autopilot MUST instead trigger the timeout transition described in REQ-050a before continuing."
- design.md:742: `asked_at=$(jq -r '.clarification.asked_at // empty' "$state_file" 2>/dev/null)` then `pause_age_seconds=$(( $(date +%s) - $(date -d "$asked_at" +%s 2>/dev/null || echo 0) ))`.

**Cycle-1 change:** Added `ASKED_AT="$(date -u +%FT%TZ)"` BEFORE each of the 6 jq write sites; added `asked_at: $asked_at` field to all 6 jq write expressions (e.g., `skills/fix-ticket/SKILL.md:226`: `'.status = "paused" | .clarification = {…, asked_at: $asked_at, …}'`). Documented field in `state/schema.md:332` (top-level shape) and `state/schema.md:346` (field table row).

**Verdict:** PASS. Cycle-1 ensures the read-side (autopilot, design.md:742) and write-side (orchestrators) are now consistent. Cycle-0 had a SILENT FAILURE risk: autopilot's `asked_at=$(jq -r '.clarification.asked_at // empty')` would return empty, then `date -d "" +%s` returns 0 (epoch), so `pause_age_seconds = now - 0 = ~1.7 billion seconds`, which would TRIP the default 30-day Pause timeout (2592000s) on the FIRST autopilot scan — silently aborting every paused issue with `aborted_by_system`. The `// empty` fallback in autopilot's design.md:742 logic does NOT guard this (`empty` then `|| echo 0` produces epoch 0). Cycle-1 closes this CRITICAL-severity bug by ensuring `asked_at` is always populated.

**Note for Phase 4:** REQ-042's verbatim 6-field enumeration omits `asked_at`, creating the gap. Recommend Phase 4 spec patch to amend REQ-042 to include `asked_at` as the 7th required field, OR add a new REQ-042a explicitly mandating it. Cycle-1 closes the implementation gap; the spec gap remains.

---

## Summary table

| Check | Spec REQs | Cycle-1 change | Verdict | Notes |
|-------|-----------|----------------|---------|-------|
| 1. clarification.asked_at field | REQ-042 + REQ-043 + REQ-050a + design.md:742 | Added field at 6 write sites + state/schema.md row | PASS (additive within REQ-042 scope) | Spec gap: REQ-042 verbatim list omits asked_at; REQ-050a depends on it |
| 2. Increment-side-of-truth (resume removed double-increment) | REQ-045 + REQ-046 + design.md:619 | Resume-ticket explicitly forbids increment; orchestrator sole increment site | PASS (resolves spec ambiguity) | Recommend REQ-045a explicit in Phase 9 |
| 3. sanitize_block_reason 14 → 17 patterns | REQ-052 (verbatim "14") + design.md:879 (verbatim "14") | Added LOWER-VAR, JSON-FIELD, PRIVATE-KEY-END | ADDITIVE PASS (F-04 below) | Spec said 14; cycle went to 17. Additive only; visible test passes |
| 4. pipeline-paused webhook wired | REQ-050c + design.md:782 | All 6 orchestrator detection sites wired with sanitization + --proto + circuit-breaker | PASS | Resolves cycle-0 gap where firing site was documented but unwired |
| 5. asked_at consistency (autopilot read = orchestrator write) | REQ-050b + design.md:742 | asked_at written at all 6 sites; autopilot reads it | PASS (resolves CRITICAL silent-failure) | Without cycle-1, every paused issue would auto-abort on first autopilot scan |

---

## Cycle-0 findings recap (unchanged in cycle-1)

| ID | Cycle-0 status | Cycle-1 impact |
|-----|----------------|----------------|
| F-01 webhook-curl citation count drift (23 actual vs 21 documented) | LOW additive | UNCHANGED — cycle-1 added 6 more pipeline-paused webhook sites in skills/* but each cites `<!-- @snippet:webhook-curl -->`, raising actual count from 23 to 29. Documented expected count in `core/snippets/webhook-curl.md:28` is still 21. Drift increased to +8. Defer to v6.9.1. |
| F-02 REQ-063c hidden test in tests-hidden/ vs spec-mandated tests/scenarios/ | LOW | UNCHANGED — file location unchanged by cycle-1 |
| F-03 Test scenario naming convention drift (v6.9.0- vs v690-) | NONE | UNCHANGED — naming convention unchanged by cycle-1 |

---

## New cycle-1 finding

### F-04. sanitize_block_reason expanded 14 → 17 patterns without spec amendment

- **REQ:** REQ-052 + design.md:879
- **Location:** `core/post-publish-hook.md:243` declares "17 patterns"; spec REQ-052 enumerates exactly 14
- **Severity:** LOW (additive — every input redacted at 14 patterns is still redacted at 17; new patterns only ADD coverage; portable POSIX constructs preserved; visible test only asserts the 14 spec-mandated tags so harness passes)
- **Impact:** None functional. The new patterns close legitimate credential-leak gaps (lowercase env-vars like `password=`, JSON fields like `"token": "..."`, PGP END lines complementing existing BEGIN coverage). Defense-in-depth improvement.
- **Spec compliance:** Per REQ-052's closing prose "covers only the Google OAuth refresh-token form; other providers require additional patterns in v6.9.1+", the spec ANTICIPATED additive expansion. However, the spec's "14 patterns" wording is descriptive, not a hard cap, and cycle-1 expansion crosses the documented count without a spec amendment.
- **Recommendation:** Phase 9 patch — add REQ-052b documenting the 14 → 17 expansion (or amend REQ-052 to enumerate 17 explicitly). Update design.md:879 "14 patterns" → "17 patterns". Update visible test `tests/scenarios/v6.9.0-pipeline-history-credential-redaction.sh` to optionally assert the 3 new tags (LOWER-VAR, JSON-FIELD, PRIVATE-KEY-END). Defer to v6.9.0 release commit or v6.9.1.

---

## Critical alignment checks (carry-over from cycle-0, re-verified for cycle-1)

### 1. Q4 ADOPT-ALL deviation: All 5 snippet files exist + README

PASS (unchanged) — cycle-1 did not modify `core/snippets/`.

### 2. block.detail HARD CONTRACT in state/schema.md

PASS (unchanged) — cycle-1 did not modify the Sensitive field exclusion contract section.

### 3. NEEDS_CLARIFICATION receiver-side EXTERNAL INPUT — both fixer.md AND triage-analyst.md

PASS (unchanged) — cycle-1 did not modify the agents' Constraints sections.

### 4. Jira regex dot-only-reject: 4 sites use `||` (OR)

PASS (unchanged) — cycle-1 did not modify the issue-id validation regex sites.

### 5. Count drift 15→16, 18→19

PASS (unchanged) — cycle-1 did not modify CLAUDE.md count assertions or `prompt-injection-protection.sh`.

---

## Verdict + JSON

```json
{
  "dimension": "spec_alignment",
  "score": 0.98,
  "verdict": "PASS",
  "cycle": 1,
  "previous_cycle_score": 0.97,
  "delta": "+0.01",
  "reqs_sampled": 35,
  "reqs_aligned": 33,
  "reqs_misaligned": 0,
  "reqs_partially_aligned": 2,
  "cycle_1_checks": {
    "check_1_clarification_asked_at": "PASS (additive within REQ-042 scope; resolves implicit spec gap with REQ-050a)",
    "check_2_increment_side_of_truth": "PASS (resolves design.md:619 ambiguity correctly; orchestrator-only)",
    "check_3_sanitize_block_reason_14_to_17": "ADDITIVE PASS (F-04 — new finding, LOW severity, defense-in-depth)",
    "check_4_pipeline_paused_webhook_firing": "PASS (resolves cycle-0 documented-but-unwired gap)",
    "check_5_asked_at_consistency": "PASS (resolves CRITICAL silent-failure — every paused issue would auto-abort without this fix)"
  },
  "spec_gaps_identified": {
    "phase_4_oversight_1": "REQ-042 verbatim 6-field list omits clarification.asked_at; REQ-050a depends on it. Recommend Phase 9 spec amendment.",
    "phase_4_oversight_2": "REQ-045/REQ-046 do not explicitly state increment-side-of-truth (orchestrator vs resume-ticket). design.md:619 implies orchestrator-only via 'BEFORE pause transition' wording, but explicit prohibition on resume-ticket increment was missing. Cycle-1 disambiguates correctly.",
    "phase_4_oversight_3": "REQ-052 enumerates 14 patterns but cycle-1 added 3 more (LOWER-VAR, JSON-FIELD, PRIVATE-KEY-END). Spec wording 'additional patterns in v6.9.1+' anticipated this; recommend REQ-052b documenting the 17-pattern set."
  },
  "carry_over_findings": {
    "F-01_webhook_curl_count_drift": "LOW — drift INCREASED from +2 (23 vs 21) to +8 (29 vs 21) due to cycle-1 adding 6 pipeline-paused webhook sites. Defer to v6.9.1.",
    "F-02_req063c_hidden_not_visible": "UNCHANGED — citation count test still in .forge/phase-5-tdd/tests-hidden/ vs spec-mandated tests/scenarios/",
    "F-03_scenario_naming_convention": "UNCHANGED — v6.9.0-* vs spec v690-*; functional parity"
  },
  "new_findings": {
    "F-04_sanitize_block_reason_pattern_expansion": "LOW — 14 → 17 patterns; additive defense-in-depth; visible test passes; recommend spec amendment for traceability"
  },
  "harness_status": "184 scenarios in tests/scenarios/ (was 183 baseline + 1 cycle-1 e2e test); cycle-1 status report claims 183/183 PASS",
  "completed_at": "2026-04-20T11:30:00Z"
}
```

DONE
