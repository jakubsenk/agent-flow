# Phase 4 Devil's Advocate Review — Round 2

## Verdict: CONDITIONAL_PASS

The Round 2 revision is impressively thorough — all 3 CRITICAL and all 6 HIGH findings from Round 1 are addressed with appropriate REQ additions, design.md verbatim function rewrites, and matching ACs. The paused-state lifecycle is now closed (timeout default + Autopilot skip + dedicated `pipeline-paused` webhook + explicit `pipeline-completed`-on-pause negative invariant). `sanitize_block_reason()` is verifiably POSIX-portable (verbatim function body inspected; no `\b`/`\S`/`\d`/`\w` constructs). Credential coverage is expanded from 9 → 14 patterns with explicit redaction tags + verbatim regexes. Snippet citation format is locked (`<!-- @snippet:<name> -->`), `## Used by:` self-documentation is mandatory, and a count-assertion test scenario (REQ-063c / AC-063c) exists.

However, the round-2 fixes introduce **2 new MEDIUM findings** that should be addressed before Phase 5: (1) an internal contradiction in scope-creep accounting — the spec target line still says "18 optional Automation Config sections" while explicitly adding a NEW `### Pause Limits` optional section (which would bump count to 19); REQ-064 only updates the core-contracts count (15 → 16), not the optional sections count, AND AC-071 enumerates exactly 18 optional sections without including Pause Limits, AND design.md §1307 still cites "5 required + 18 optional structure MUST hold". (2) Pause timeout has no min/max validation — `Pause timeout: 0 hours` is silently accepted, causing instant auto-abort of all paused issues on first Autopilot pass (degenerate-but-non-deadlocking).

Both are easy fixes (1-line REQ updates + 1 AC tweak). No CRITICAL or HIGH regressions; no new SSRF or injection vectors of concern.

## Severity tally
- CRITICAL: 0
- HIGH: 0
- MEDIUM: 2
- LOW: 1

---

## Round-1 finding disposition

| F-ID | Round 1 severity | Round 2 status | Evidence |
|------|------------------|----------------|----------|
| F-01 | CRITICAL | **FIXED** | REQ-050a (Pause timeout default 30 days, optional section), REQ-050b (Autopilot detect+skip+log `[INFO] Skipping`), REQ-050c (NEW `pipeline-paused` webhook event with sanitized payload), REQ-050d (explicit `pipeline-completed` MUST NOT fire on pause invariant). Design.md §664-731 all 4 sub-requirements verbatim. ACs AC-049a, AC-050a, AC-050b, AC-050c + 3 new harness scenarios. |
| F-02 | CRITICAL | **FIXED** | design.md §803-836 verbatim function body inspected — uses `(^|[[:space:]])` instead of `\b`, `[^[:space:]]+` instead of `\S+`, `[0-9]` instead of `\d`. Explicit `LC_ALL=C` set. AC-052a is a NEGATIVE grep asserting `\\(b\|S\|d\|w)` returns NO matches. POSIX portability test recommendation includes BSD compatibility note + macOS CI matrix recommendation + fallback validation input `PASSWORD=secret123` (no leading boundary). |
| F-03 | CRITICAL | **FIXED** | REQ-052 lists 14 patterns explicitly; design.md §828-832 verbatim regexes for JWT (`eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+`), SSH/PGP (`-----BEGIN [A-Z ]*PRIVATE KEY[A-Z ]*-----`), Stripe (`sk_live_[A-Za-z0-9]+`), Google API (`AIza[A-Za-z0-9_-]{35}`), OAuth refresh (`1//0[A-Za-z0-9_-]+`). AC-052 grep enumeration covers all 14 redaction tags + harness-scenario test inputs include all 5 new pattern fixtures. Multi-line block redaction documented as best-effort (acceptable). |
| F-04 | HIGH | **FIXED** | REQ-050e defines unambiguously: `iteration = the fixer-reviewer iteration counter; the value increments per fixer attempt within a single phase invocation`. On `resume-ticket --clarification`, `state.iteration` MUST increment by 1 BEFORE re-dispatch; iteration budget +1 per clarification (max +3 total = budget 8). Design.md §733-749 + AC-046a + harness scenario `v690-clarification-iteration-semantics.sh` asserting (a)/(b)/(c) all three predicates. |
| F-05 | HIGH | **FIXED** | REQ-055a (issue tracker COMMENT bounded to first 100 chars + sanitized), REQ-055b (pipeline-completed payload excludes block.detail), REQ-055c (pipeline-history.md exclusion restate), REQ-055d (state/schema.md contract rewritten as INCLUDE/EXCLUDE table with 8 channel rows including the NEW `pipeline-paused` webhook). Design.md §389-415 verbatim 8-row table. AC-055a/b/c/d + harness scenarios `v690-block-comment-redaction.sh` and `v690-pipeline-completed-payload-exclusion.sh`. |
| F-06 | HIGH | **FIXED** | REQ-060a mandates docs/architecture.md substantive refresh covering NEEDS_CLARIFICATION + pipeline-history feedback arrow + circuit-breaker label + snippets sub-cluster + 15→16 core count. AC-060a verifies via grep (4 substantive terms) AND `git log -1 --format=%H -- docs/architecture.md` returns a commit at-or-after v6.9.0 tag. Freshness counter resets as a side effect. |
| F-07 | HIGH | **FIXED** | REQ-063b mandates exact citation marker form `<!-- @snippet:<name> -->`; each snippet self-documents via `## Used by:` heading. REQ-063c adds hidden test `tests/scenarios/v690-snippet-citation-counts.sh` asserting expected counts 20/4/1/3/2. REQ-063d adds NEW `core/snippets/README.md` with rollback procedure (`git show v6.9.0:core/snippets/<name>.md`). Design.md §1130-1168 verbatim README content. AC-063b/c/d + AC-095. |
| F-08 | HIGH | **FIXED** | AC-080 restructured as AC-080a (12+ Added items including `pipeline-paused`, `Pause Limits`), AC-080b (14+ Changed items including `block.detail` HARD CONTRACT cite + 15→16 count change), AC-080c (4+ Known Issues deferrals), AC-080d (explicit cites of Sensitive field exclusion contract + count change rationale). Coverage well above the 15-term Round-1 baseline. |
| F-09 | MEDIUM | NOT FIXED (accepted with rationale) | EXTERNAL INPUT marker injection escape — Round 2 disposition log accepts as Phase 7 implementation note. Acceptable trade-off; consumer-side defense partially mitigates. |
| F-10 | MEDIUM | **FIXED** | REQ-063a adds explicit `shopt -u globstar`, `shopt -u nullglob`, `shopt -u dotglob` guards + `find core -maxdepth 1 -name '*.md' -type f` portable replacement. AC-063a greps for all 4 patterns + asserts `ls core/*.md` removed. |
| F-11 | MEDIUM | NOT FIXED (accepted) | example.invalid user-confusion install-doc note deferred to Phase 7 vicinity edits. Acceptable. |
| F-12 | MEDIUM | PARTIALLY FIXED | AC-070 now enumerates the 5 required section names verbatim (Issue Tracker, Source Control, PR Rules, PR Description Template, Build & Test) — verifier prose tightened. Better than Round 1's count-only check. |
| F-13 | MEDIUM | NOT FIXED (accepted — v6.9.1 deferral) | Per-run circuit alert fatigue documented in Known Issues. Acceptable. |
| F-14 | MEDIUM | **FIXED** | Coverage matrix footer (formal-criteria.md §786) explicitly documents trade-off: ~30 of ~110 ACs are harness-scenario; harness ACs SHOULD count 3x in security/correctness sub-scores. REQ-069 floor (≥161) clarified as non-blocking ceiling. |
| F-15 | MEDIUM | **FIXED** | REQ-027 split into REQ-027a + REQ-027b; REQ-027b tightens filter from `<!--` to `<!-- COUNTER-EXAMPLE:` per Devil's-Advocate F-15 directly. |
| F-16 | LOW | NOT FIXED (subsumed) | Snippet citation contract for SKILL.md prose vs executable code subsumed by REQ-063b/c/d marker form. Acceptable. |
| F-17 | LOW | NOT FIXED (accepted) | Line-number reference shift — Phase 7 first-step verification per Quality F-18. Acceptable. |
| F-18 | LOW | NOT FIXED (accepted) | --clarification quote-escaping — Phase 7 implementation note. Acceptable. |

**Disposition summary:** 3/3 CRITICAL FIXED, 6/6 HIGH FIXED (F-04 fully, F-05 fully, F-06 fully, F-07 fully, F-08 fully). 5/7 MEDIUM addressed; 2 deferred with rationale. 0/3 LOW addressed (acceptable per Round 2 disposition log).

---

## New attack-surface findings (introduced by Round 2 revision)

### F-19. MEDIUM — Scope-creep accounting contradiction: NEW `### Pause Limits` optional Automation Config section bumps count 18 → 19, but spec line 5, REQ-064, AC-071, and design.md §1307 all still assert "18 optional sections"

- Severity: MEDIUM
- Category: spec-internal-consistency / discoverability
- Evidence:
  - `requirements.md:5`: `Target after release: 21 agents / 29 skills / 16 core contracts / 18 optional Automation Config sections` — but REQ-050a explicitly adds `### Pause Limits` (line 266: `The system shall add a NEW optional Automation Config section ### Pause Limits ...`).
  - `design.md:1307`: `REQ-070 — no new required Automation Config key. Verified by diffing the "Automation Config" section in CLAUDE.md against the v6.8.1 baseline; the 5 required + 18 optional structure MUST hold.` — wrong, structure is now 5 required + 19 optional.
  - `formal-criteria.md:563` (AC-071): `Expected: ALL 18 existing optional section names present (Phase 2 baseline list — Retry Limits, Module Docs, Hooks, Custom Agents, Notifications, Worktrees, E2E Test, Browser Verification, Error Handling, Extra labels, Feature Workflow, Decomposition, Pipeline Profiles, Metrics, Agent Overrides, Local Deployment, Sprint Planning, Autopilot).` — Pause Limits NOT in the enumeration. AC passes only because it asserts "all 18 EXISTING present" (NEGATIVE — no rename), so the new Pause Limits doesn't violate AC-071, but the count is now genuinely 19, and no AC asserts "Pause Limits IS the 19th".
  - `requirements.md:386` (REQ-064): updates ONLY `CLAUDE.md:27` text from `15 shared pipeline pattern contracts` → `16 shared pipeline pattern contracts`. Does NOT update the analogous "18 optional Automation Config sections" claim that lives in CLAUDE.md and ceos-agents memory and `examples/configs/*.md` headers.
  - The CLAUDE.md project memory header line "18 optional config sections in total" (CLAUDE.md actually contains: `There are 18 optional config sections in total. All sections use table format ...`) is NOT explicitly updated by any REQ to say 19.
- Concern: After v6.9.0 ships, the CLAUDE.md "18 optional config sections" sentence becomes stale, the Coverage Matrix coverage of optional sections is mis-counted, and a future v6.10.x reviewer applying AC-071 finds 19 sections present but the AC still says 18. This is the SAME class of bug as REQ-064 was fixing (15 → 16 for core contracts) — except now applied to the optional-sections count and not addressed. The Round 2 disposition log notes "Pause Limits adds NEW optional Automation Config section — bumps count 18 → 19" was raised in the round-1 brief but no corresponding REQ exists. Per memory `feedback_doc_completeness.md`: "audit ALL doc files for stale counts/tables before committing".
- Recommendation: Add a NEW REQ-064a (or extend REQ-064): "The system shall update CLAUDE.md text from `18 optional config sections in total` → `19 optional config sections in total` AND analogous count claims in `examples/configs/*.md` template headers (if any) AND update design.md §1307 from `5 required + 18 optional` → `5 required + 19 optional`." Tighten AC-071 to enumerate 19 sections (existing 18 + Pause Limits) OR add AC-071a asserting `### Pause Limits` is present in CLAUDE.md optional sections table. Update `requirements.md:5` target line to `19 optional Automation Config sections`. ~5-line spec change, no scope expansion beyond what's already in the spec.

### F-20. MEDIUM — Pause timeout has no min/max validation; `Pause timeout: 0 hours` silently accepted causing instant auto-abort of all paused issues on first Autopilot pass

- Severity: MEDIUM
- Category: spec-gap / operational
- Evidence:
  - `design.md:675`: `| Pause timeout | `30 days` (operator-configurable: `<N> hours`/`<N> days`) | `30 days` |` — no min, no max specified.
  - `design.md:692`: `pause_timeout_seconds=$(parse_pause_timeout "${PAUSE_TIMEOUT:-30 days}")  # default 30 days` — `parse_pause_timeout` is referenced but not defined; no validation specified.
  - `design.md:693-696`: `if [ "$pause_age_seconds" -gt "$pause_timeout_seconds" ]; then ...` — if `pause_timeout_seconds == 0`, EVERY paused issue with `pause_age >= 1 second` immediately gets promoted to `aborted_by_system` on the next Autopilot scan.
  - REQ-050a doesn't mention min/max bounds, doesn't reject invalid input formats (e.g., `Pause timeout: -5 hours`, `Pause timeout: forever`, `Pause timeout: ` (empty)).
- Concern: Not a deadlock per the brief's wording — the opposite (instant kill, the degenerate other extreme). But still a usability footgun: an operator typo `Pause timeout: 0 hours` (intending `30 hours` perhaps) silently destroys ALL paused-state issues on the next Autopilot run with no warning. Combined with `On error: skip` (Autopilot default), the operator may never even see the failures. This is exactly the kind of edge case Devil's Advocate is supposed to flag for the new optional config section.
- Recommendation: Add a NEW REQ-050f: "The `Pause timeout` value MUST be validated by the orchestrator: minimum `1 hour`, maximum `365 days`. If the value is invalid (zero, negative, unparseable, out-of-range), the orchestrator MUST log `[WARN] Invalid Pause timeout '<value>' — falling back to default 30 days` and use the default. The validation MUST happen BEFORE the comparison `pause_age_seconds > pause_timeout_seconds`." Also add to `parse_pause_timeout()` design pseudocode: input validation + fallback. Add AC-050a extension covering 4 invalid inputs (zero, negative, garbage string, out-of-range) all falling back to 30 days.

### F-21. LOW — `pipeline-paused` webhook event is added without explicit binding to `--proto "=http,https"` SSRF defense; webhook-curl snippet citation count stays at 20 (not 21), suggesting the new pipeline-paused curl invocation may not use the canonical snippet

- Severity: LOW
- Category: security
- Evidence:
  - `requirements.md:274` (REQ-050c): defines payload but does NOT explicitly require `--proto "=http,https"` on the curl invocation that fires it.
  - `design.md:710-731`: payload spec only — no curl invocation example, no citation of `core/snippets/webhook-curl.md`.
  - `design.md:1133` (snippet README): `webhook-curl: 20 expected citation count` — unchanged from Round 1. The new `pipeline-paused` webhook firing site is the 21st webhook invocation in v6.9.0, but the count target remains 20.
  - REQ-022 [NEGATIVE] meta-test asserts NO `curl ` in skills/core lacks `--proto "=http,https"` — this WOULD catch a missing `--proto` on a `pipeline-paused` curl, BUT only if the curl is in skills/* or core/post-publish-hook.md or core/block-handler.md. If the new curl is added in a not-yet-enumerated location (e.g., a new `core/agent-states.md` orchestrator subsection), the meta-test misses it.
- Concern: Defense-in-depth gap. The Round 2 spec correctly enumerates `pipeline-paused` as a new webhook event but doesn't extend the SSRF-defense + circuit-breaker contract to it explicitly. The implicit reliance on REQ-022's negative meta-test is fragile if the implementation locates the new curl outside the meta-test's grep scope.
- Recommendation: (a) Extend REQ-050c to add: "The `pipeline-paused` webhook curl invocation MUST use `--proto "=http,https"` (cite `core/snippets/webhook-curl.md`) AND MUST be subject to the in-memory circuit breaker per REQ-032." (b) Bump the webhook-curl expected citation count from 20 to 21 in REQ-063c / AC-063c / `design.md:1151` table / `core/snippets/webhook-curl.md` `## Used by:` heading. (c) Extend REQ-022 meta-test scope to include `core/agent-states.md` (the new core file).

---

## Specific recheck answers (per task brief)

### 1. Paused-state lifecycle (F-01)
- **Timeout exists with default value (30 days):** YES (REQ-050a, design.md §675).
- **Autopilot SKILL.md update required (skip paused with log entry):** YES (REQ-050b, design.md §680-703).
- **`pipeline-paused` webhook event added (additive):** YES (REQ-050c, design.md §705-731). Subject to F-21 caveat (no explicit --proto binding).
- **`pipeline-completed` MUST NOT fire on `paused` is explicit:** YES (REQ-050d + AC-049a + design.md §730 + design.md §1058 source code comment).

### 2. sanitize_block_reason POSIX portability (F-02)
- **Function body uses ONLY POSIX-portable sed constructs:** YES (verified by reading design.md §814-833 verbatim). No `\b`, `\S`, `\d`, `\w`. Uses `(^|[[:space:]])`, `[^[:space:]]+`, `[0-9]`, `[[:space:]]`. Explicit `LC_ALL=C`.
- **BSD compatibility test or grep included:** YES (AC-052a NEGATIVE grep `awk '/sanitize_block_reason\(\)/,/^}/' core/post-publish-hook.md | grep -E '\\\\(b|S|d|w)' returns NO matches`). CI matrix recommendation (ubuntu-latest + macos-latest) included as Phase 7 guidance with single-platform fallback test (`PASSWORD=secret123` no-leading-boundary input).

### 3. Credential pattern coverage (F-03)
- **Pattern list expanded to ~14 patterns:** YES (REQ-052 explicitly enumerates 14; design.md §818-832 verbatim regexes).
- **Specifically present:**
  - JWT (`eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+` → `[REDACTED-JWT]`): YES (line 828)
  - SSH/PGP private keys (`-----BEGIN [A-Z ]*PRIVATE KEY[A-Z ]*-----` → `[REDACTED-PRIVATE-KEY]`): YES (line 829, with documented multi-line caveat)
  - Stripe live keys (`sk_live_[A-Za-z0-9]+` → `[REDACTED-STRIPE-LIVE]`): YES (line 830)
  - Google API keys (`AIza[A-Za-z0-9_-]{35}` → `[REDACTED-GOOGLE-API-KEY]`): YES (line 831)
  - OAuth refresh tokens (`1//0[A-Za-z0-9_-]+` → `[REDACTED-OAUTH-REFRESH]`): YES (line 832, Google form only — best-effort documented in REQ-052)
- All 5 new patterns have BOTH a regex AND a redaction tag. AC-052 grep enumeration covers all 14.

### 4. Clarification iteration semantics (F-04)
- **Iteration unambiguously defined:** YES. REQ-050e: `iteration = the fixer-reviewer iteration counter; the value increments per fixer attempt within a single phase invocation`. Mirrored in design.md §738-748 and AC-046a verifier prose.
- Bonus: explicit `state.iteration += 1 BEFORE re-dispatch` decision documented + iteration budget extension formula (5 + max 3 = 8) + harness scenario verifying all three predicates.

### 5. block.detail unclosed channels (F-05)
- **REQ-055a-d enumerate ALL channels:** YES.
  - /metrics JSON: REQ-030 (existing) + REQ-055d table row "EXCLUDE"
  - issue tracker block COMMENT: REQ-055a (INCLUDE — first 100 chars only, redacted)
  - pipeline-completed webhook payload: REQ-055b (EXCLUDE — explicit BC NEGATIVE)
  - pipeline-history.md: REQ-055c (EXCLUDE — restate)
- **Each has explicit ACT or NEG clause:** YES — all 4 channels mapped to ACs (AC-055, AC-055a, AC-055b, AC-055c, AC-055d). REQ-055d adds COMPREHENSIVE 8-row INCLUDE/EXCLUDE table covering ALL 8 channels (the 4 above + `issue-blocked` webhook + `pipeline-paused` webhook + state.json on disk + future analytics/export). Design.md §400-409 verbatim table.

### 6. Architecture freshness substantive refresh (F-06)
- **REQ requires v6.9.0 to refresh `docs/architecture.md` content:** YES (REQ-060a).
- Substantive items required: NEEDS_CLARIFICATION node, pipeline-history feedback arrow, circuit-breaker label, snippets sub-cluster, count refresh 15 → 16. AC-060a verifies via grep (4 substantive terms) AND `git log -1 ... -- docs/architecture.md` returns commit at-or-after v6.9.0 tag (freshness counter resets as side effect; semantic staleness also addressed).

### 7. Snippet citation format/rollback/validity (F-07)
- **Citation format specified:** YES (REQ-063b: `<!-- @snippet:<name> -->` exact form).
- **Hidden test scenario for citation count assertion:** YES (REQ-063c → `tests/scenarios/v690-snippet-citation-counts.sh`; expected counts 20/4/1/3/2 enumerated).
- **Rollback note exists:** YES (REQ-063d → NEW `core/snippets/README.md` with verbatim rollback procedure: `git show v6.9.0:core/snippets/<name>.md` + re-inline at every cited site BEFORE deleting/modifying).

### 8. CHANGELOG completeness (F-08)
- **AC-080 expanded to ~30 items:** YES. Restructured as AC-080a (12+ Added items) + AC-080b (14+ Changed items) + AC-080c (4+ Known Issues deferrals) + AC-080d (explicit cite of Sensitive field exclusion contract + 15 → 16 count change explanation). All Round 1 missing items now enumerated: `agent-states.md`, `clarification`, `Cross-File Invariants`, `prompt-injection-protection.sh`, `15→16 count change`, all 4 deferrals, `block.detail` exclusion contract — plus 2 new Round 2 items (`pipeline-paused`, `Pause Limits`).

### 9. New attack-surface check (Devil's Advocate special duty)

- **New SSRF vector?** PARTIAL (F-21): `pipeline-paused` webhook curl not explicitly bound to `--proto` discipline; expected citation count stays at 20 not 21.
- **New injection path?** NO. Snippet citation marker `<!-- @snippet:NAME -->` — `NAME` is a fixed literal from a 5-element whitelist (`webhook-curl`, `issue-id-validation`, `metrics-json-schema`, `pipeline-completion`, `architecture-freshness`); never user-controlled. No injection risk.
- **New deadlock?** NO; but degenerate edge case (F-20): `Pause timeout: 0 hours` silently accepted causes instant auto-abort. Spec must validate min/max.
- **New scope creep beyond the 11 categories?** YES (F-19): `### Pause Limits` is a NEW optional Automation Config section bumping count 18 → 19. Was NOT acknowledged in the CLAUDE.md update REQ (REQ-064 only touches the 15→16 core-contracts count). AC-071 still enumerates exactly 18; spec target line still says "18 optional".
- **New BC violation?** NO. All 4 BC NEGATIVE REQs (REQ-070..073) still hold:
  - REQ-070 (no new REQUIRED key): Pause Limits is OPTIONAL — preserved.
  - REQ-071 (no rename of existing optional): all 18 existing names preserved per AC-071 grep.
  - REQ-072 (no rename/remove existing webhook events): `pipeline-paused` is ADDITIVE, not a rename.
  - REQ-073 (no change to existing agent output sections): preserved.

---

## What was preserved well (Round 2 reaffirms Round 1 strengths)

- **All 9 Round 1 findings dispositioned**: 6 fully fixed (F-01..F-08 minus F-04 which was already F-04 in HIGH tier), 2 deferred with rationale (F-09 EXTERNAL INPUT marker injection escape; F-11 example.invalid user-confusion install-doc note). Even LOW findings have explicit Round 2 disposition entries.
- **Verbatim function bodies in design.md** (sanitize_block_reason() §814-833, paused-state detection §684-703, snippet README §1130-1168) — Phase 7 implementer has direct copy-paste anchors with no ambiguity.
- **Coverage matrix (formal-criteria.md §764-786)** explicitly tracks Round-1 vs Round-2 deltas per category, makes scope changes auditable.
- **Trade-off notes** (e.g., harness vs grep AC weighting per Devil's-Advocate F-14, multi-line credential redaction documented as best-effort with v6.9.1 deferral, OAuth refresh covers Google form only) demonstrate honest spec-honesty without scope inflation.
- **REQ-027 atomicity split** (REQ-027a content edit + REQ-027b test edit) follows Quality F-02 directly with no loss of traceability.

---

## JSON verdict

```json
{
  "verdict": "CONDITIONAL_PASS",
  "reviewer": "devils-advocate-2",
  "phase": "phase-4-spec-round-2",
  "severity_tally": {
    "CRITICAL": 0,
    "HIGH": 0,
    "MEDIUM": 2,
    "LOW": 1
  },
  "round_1_disposition": {
    "F-01": "FIXED",
    "F-02": "FIXED",
    "F-03": "FIXED",
    "F-04": "FIXED",
    "F-05": "FIXED",
    "F-06": "FIXED",
    "F-07": "FIXED",
    "F-08": "FIXED",
    "F-09": "DEFERRED",
    "F-10": "FIXED",
    "F-11": "DEFERRED",
    "F-12": "PARTIALLY_FIXED",
    "F-13": "DEFERRED",
    "F-14": "FIXED",
    "F-15": "FIXED",
    "F-16": "DEFERRED",
    "F-17": "DEFERRED",
    "F-18": "DEFERRED"
  },
  "must_fix_before_phase_5": [],
  "should_fix_before_phase_5": [
    "F-19: Pause Limits NEW optional section bumps Automation Config count 18 → 19, but spec target line + REQ-064 + AC-071 + design.md §1307 still say 18 (MEDIUM)",
    "F-20: Pause timeout has no min/max validation; '0 hours' silently accepted causes instant auto-abort of all paused issues (MEDIUM)"
  ],
  "may_fix_before_phase_5": [
    "F-21: pipeline-paused webhook curl invocation not explicitly bound to --proto SSRF defense; webhook-curl snippet citation count stays at 20 (should be 21) (LOW)"
  ],
  "preserved_well": [
    "All 3 CRITICAL Round-1 findings FIXED with verbatim design.md function bodies",
    "All 6 HIGH Round-1 findings FIXED with matching ACs and harness scenarios",
    "Coverage matrix tracks Round-1 vs Round-2 deltas explicitly per category",
    "REQ-027 atomicity split honored without losing traceability",
    "Honest scope-honesty notes (multi-line credential best-effort, OAuth Google-only)"
  ],
  "summary": "Round 2 fully addresses all 3 CRITICAL and all 6 HIGH Round-1 findings. Verdict raised from REVISION_REQUIRED to CONDITIONAL_PASS. Two new MEDIUM scope-creep accounting findings (F-19 optional sections count contradiction + F-20 Pause timeout missing min/max validation) and one LOW SSRF defense-in-depth gap (F-21 pipeline-paused webhook --proto binding) introduced by Round 2 fixes; all are 1-5 line spec adjustments with no architectural redesign. Recommend a brief Round 3 cleanup OR carry forward as Phase 7 implementation notes. No CRITICAL or HIGH regressions. No new injection vectors. No new deadlocks. No new BC violations. Estimated cleanup effort: 0.5-1h equivalent (3 REQ tweaks + 2 AC tweaks + spec target line + design.md §1307 line)."
}
```

DONE
