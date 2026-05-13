# Phase 4 Compliance Review — Round 2

## Verdict: PASS

The Round-2 revision applied the F-04 MEDIUM (shopt guards) fix faithfully and added 14 brand-new REQs + 1 split (REQ-027a/b) without regressing any Round-1 PASS. All 5 new revision categories trace cleanly to upstream Devil's-Advocate sources (F-01, F-03, F-04, F-05, F-06, F-07) plus Round-1 Compliance F-04. The MINOR semver invariants are preserved: `Pause Limits` is OPTIONAL, `pipeline-paused` is additive, `aborted_by_system` is additive to the status enum with `schema_version` unchanged. AC count is 115 (was 91, +24 net). REQ count is 88 (was 73, +15 net). All Round-1 mandatory checks remain satisfied.

One LOW finding (F-09 below) is bookkeeping drift between requirements.md header (`18 optional`) and the new REQ-050a (`19th optional`), but this is descriptive metadata only — neither REQ-070 nor REQ-071 is violated, and AC-050a verifies the new section exists. Not blocking.

---

## Round-2 fixes verification

- **F-04 (shopt guards): PASS** — design.md G-2 (lines 1171-1198) now contains the round-2 revision with explicit `shopt -u globstar 2>/dev/null || true`, `shopt -u nullglob 2>/dev/null || true`, `shopt -u dotglob 2>/dev/null || true` (lines 1182-1184) immediately after `set -euo pipefail`. The fragile `ls core/*.md` is replaced with `find core -maxdepth 1 -name '*.md' -type f | wc -l` (line 1190). REQ-063a is the new requirement (requirements.md:370) tracing to "Devil's-Advocate F-10 (globstar fragility) + Compliance F-04 (defensive shopt guards) + Phase 3 Cross-cutting #1". AC-063a (formal-criteria.md:480-487) greps for all 3 shopt guards + the find command, AND asserts the old `ls core/*.md` is removed. Hardened assertion explicitly = 16 (not ≥16) per design.md:1195. F-04 is fully addressed; the LOW Round-1 follow-up is now hard-enforced rather than recommended.

- **Paused lifecycle traced (REQ-050a/b/c/d/e): PASS** — All 5 new REQs trace correctly to upstream Devil's-Advocate F-01 (paused state lifecycle) and F-04 (clarification iteration semantics):
  - REQ-050a → "D + Devil's-Advocate F-01 (paused state lifecycle — timeout default)" — adds `### Pause Limits` optional config section + `Pause timeout` (default 30 days) + `aborted_by_system` status + `clarification_timeout` abort_reason. Schema-version stays "1.0" (additive). Verified at design.md:664-678.
  - REQ-050b → "D + Devil's-Advocate F-01 (Autopilot paused detection)" — autopilot reads state.json, skips `paused`, emits `[INFO] Skipping {issue_id}: awaiting clarification`. Verified at design.md:680-703 with full bash skeleton.
  - REQ-050c → "D + Devil's-Advocate F-01 (pipeline-paused webhook event)" — NEW additive `pipeline-paused` webhook event with sanitized payload (`paused_at`, `clarification.question` via sanitize_block_reason, `iteration`). REQ-049 invariant explicitly preserved in REQ-050c body ("REQ-049 still holds: `pipeline-completed` MUST NOT fire on pause"). Verified at design.md:705-731.
  - REQ-050d → "D + Devil's-Advocate F-01 (explicit pipeline-completed-on-pause invariant)" — restates REQ-049 as explicit BC negative. AC-049a verifies via grep + harness scenario.
  - REQ-050e → "D + Devil's-Advocate F-04 (clarification iteration semantics)" — defines unambiguously `iteration = fixer-reviewer iteration counter` + iteration increment on resume + budget extension max +3. Verified at design.md:733-749 with explicit edge-case (5 + 3 = 8 cap).
  
  All 5 REQs cleanly originate from the round-1 review's Devil's-Advocate F-01 and F-04 callouts. No phantom traces.

- **Credential patterns (REQ-052 expanded 9→14): PASS** — REQ-052 (requirements.md:294) now enumerates all 14 patterns by name and replacement tag with explicit POSIX-portability mandate ("MUST use POSIX-portable regex constructs only — `[[:space:]]`, `[^[:space:]]`, `[0-9]`, anchored alternation, NEVER `\b`, `\S`, `\d`, `\w`"). The +5 patterns (10 JWT, 11 SSH/PGP private-key BEGIN, 12 Stripe live, 13 Google API, 14 OAuth refresh) all trace to "Devil's-Advocate F-03 (expanded credential pattern coverage)" + F-02 (POSIX portability). Documented best-effort caveats appear inline (private-key multi-line "impractical in `sed -E`", OAuth-refresh "covers only Google form"). AC-052 (formal-criteria.md:347-376) enumerates all 14 redaction tags + 12 input-output round-trip cases. AC-052a verifies POSIX-portable absence-of-`\b\S\d\w` via awk-region grep. Design.md L-805-811 documents the round-2 rewrite + 9→14 expansion explicitly.

- **Snippet citation (REQ-063a/b/c/d): PASS** —
  - REQ-063a → shopt guards (covered above).
  - REQ-063b → "Devil's-Advocate F-07 (snippet citation format spec)" — mandates exact HTML-comment marker form `<!-- @snippet:<snippet-name> -->` at all 30 citation sites + each snippet self-documents via `## Used by:` heading. Verified at requirements.md:373-375 and design.md:1135-1143 (Citation format section in snippets/README.md). Snippet examples (e.g., issue-id-validation.md:986-991) demonstrate the contract.
  - REQ-063c → "Devil's-Advocate F-07 (snippet validity test)" — NEW hidden test `tests/scenarios/v690-snippet-citation-counts.sh` asserts counts: webhook-curl 20 / issue-id-validation 4 / metrics-json-schema 1 / pipeline-completion 3 / architecture-freshness 2. Verified at design.md:1145-1157.
  - REQ-063d → "Devil's-Advocate F-07 (rollback contract)" — NEW `core/snippets/README.md` with rollback procedure `git show v6.9.0:core/snippets/<name>.md` + re-inline-before-delete. Verified at design.md:1159-1168.
  
  All 4 sub-REQs trace to F-07 cleanly.

- **Architecture refresh (REQ-060a): PASS** — REQ-060a (requirements.md:349-350) traces to "Devil's-Advocate F-06 (architecture freshness substantive refresh)". Mandates 6 substantive content additions (NEEDS_CLARIFICATION node, pipeline-history feedback arrow, circuit-breaker label, snippets sub-cluster, skill-count refresh 28→29, core-contract count 15→16) with concrete verification (`git log -1 --format=%H` returns v6.9.0 commit hash, plus 4 grep terms: NEEDS_CLARIFICATION, pipeline-history, circuit, snippets). Verified at design.md:908-929. AC-060a (formal-criteria.md:449-451) provides machine-checkable git-ancestor verification.

- **block.detail 4-channel contract (REQ-055a/b/c/d): PASS** —
  - REQ-055a → "Devil's-Advocate F-05 (issue tracker comment unclosed channel)" — `Detail: {first-100-chars-redacted}` via `sanitize_block_reason()`. Verified at requirements.md:309-311.
  - REQ-055b → "Devil's-Advocate F-05 (webhook payload exclusion explicit)" — `pipeline-completed` payload excludes `block.detail`. Verified at requirements.md:313-315.
  - REQ-055c → "Devil's-Advocate F-05 (pipeline-history.md exclusion explicit)" — restates REQ-055 for comprehensive enumeration. Verified at requirements.md:317-319.
  - REQ-055d → "Devil's-Advocate F-05 (comprehensive channel enumeration)" — NEW comprehensive INCLUDE/EXCLUDE table with 7 channels including the new `pipeline-paused` (EXCLUDE). Verified at requirements.md:321-323 and design.md:393-415 (full table with INCLUDE rationales, EXCLUDE rationales). 4 new ACs (AC-055a/b/c/d) cover all 4 sub-REQs with harness scenarios. The new table at design.md:400-409 includes `pipeline-paused` as EXCLUDE (correctly handles the new webhook event).

---

## Anti-regression scan

Each row from Round-1 coverage matrix re-verified against Round-2 spec:

| Category | Round-1 Status | Round-2 Re-verification | Status |
|----------|----------------|-------------------------|--------|
| A1 License (REQ-001..005, AC-001..005, AC-083) | OK | All 5 REQs unchanged; ACs intact | OK |
| A2 SECURITY.md (REQ-006..009, AC-006..009) | OK | Unchanged | OK |
| A3 Repository URL (REQ-010..014, AC-010..014) | OK | Unchanged; placeholder still `example.invalid` | OK |
| A4 CODE_OF_CONDUCT.md (REQ-015..016, AC-015..016) | OK | Unchanged | OK |
| A5 Issue/PR templates (REQ-017..020, AC-017..020, AC-082) | OK | Unchanged | OK |
| B v6.8.1 polish bundle (REQ-021..028) | OK | REQ-027 split into REQ-027a + REQ-027b (Quality F-02 atomicity); AC-027a + AC-027b sub-ACs replace single AC-027. Trace `B-6 + Phase 2 §Q-B-5` preserved on both halves; F-15 tightening applied to REQ-027b. | OK (improved) |
| C1 /metrics --format json (REQ-029..031, AC-029..031, AC-085) | OK | Unchanged. REQ-030 hard contract still cited. The contract paragraph itself was REWRITTEN by REQ-055d into table form, but the anchor phrase "Sensitive field exclusion contract" is preserved per AC-030 grep + AC-055d re-grep. | OK |
| C2 Webhook circuit breaker (REQ-032..035) | OK | Unchanged | OK |
| C3 outcome:failed (REQ-036..037) | OK | Unchanged | OK |
| C4 Multi-host lock DEFER (REQ-038..039) | OK | Unchanged | OK |
| D NEEDS_CLARIFICATION (REQ-040..050, AC-040..050, AC-078, AC-087) | OK | Original 11 REQs unchanged; +5 sub-REQs (050a/b/c/d/e) layer additively; +5 sub-ACs (046a, 049a, 050a/b/c) verify; AC-093 + AC-092 extension scenarios named. No regression. | OK (extended) |
| E pipeline-history.md (REQ-051..055) | OK | Original 5 REQs unchanged; REQ-052 9→14 patterns IS A CHANGE but ADDITIVE (the original 9 are preserved verbatim, +5 added in slots 10-14); AC-052 expanded from 9 grep tags to 14; AC-052a (POSIX) added; +REQ-055a/b/c/d for 4-channel contract additive only; AC-055a/b/c/d added; AC-094 named. No regression to original 5. | OK (extended) |
| F architecture freshness (REQ-056..060) | OK | Original 5 REQs unchanged; REQ-060a additive substantive refresh + AC-060a; freshness counter logic unchanged. No regression. | OK (extended) |
| G Cross-cutting (REQ-061..066) | OK | Original 6 REQs unchanged; REQ-063 still `[NEGATIVE — TEST-INFRASTRUCTURE]` with same content, NOW augmented (not replaced) by REQ-063a (defensive shopt guards) + REQ-063b/c/d (citation format/test/rollback). AC-076 + AC-079 unchanged. AC-095 named. No regression to AC-061..066. | OK (extended) |
| R Release (REQ-067..069, AC-067..069) | OK | Original 3 REQs unchanged. AC-080 single-AC was restructured into AC-080a/b/c/d for finer enumeration (per Devil's-Advocate F-08 CHANGELOG completeness) — this is REFINEMENT (not regression); the original AC-080 grep terms are preserved across the 4 sub-ACs and EXTENDED to ~30 terms. The `^\*\*MINOR\*\* — Pipeline Intelligence` regex still matches design.md:1234. | OK (refined) |
| BC Backward-compat negatives (REQ-070..073, AC-070..073, AC-081) | OK | All 4 BC REQs unchanged. REQ-072 specifically validated against new `pipeline-paused` event addition — REQ-050c is ADDITIVE (does not rename/remove the existing 5 events: pipeline-started, step-completed, pipeline-completed, pr-created, ceos-agents-block). AC-072 still passes. | OK |

**Round-1 mandatory check anti-regression:**

- 11 categories covered: still PASS.
- Q4 deviation (5 snippets): still PASS — REQ-061 unchanged; +REQ-063a/b/c/d add HOW-cited spec but do not alter the 5-snippet decision.
- Q3 8-line enumeration: still PASS — REQ-064 unchanged; design.md:751-763 preserves all 8 line numbers (107, 112, 113, 116, 119, 120, 121, 126).
- Agent C non-negotiables (8): still PASS — Jira regex dot-only reject (REQ-026), DoS cap (REQ-043), receiver-side EXTERNAL INPUT (REQ-048), `/metrics` block.detail HARD CONTRACT (REQ-030 + now reinforced by REQ-055d table), credential redaction (REQ-052 expanded 9→14 — strict superset), SPDX exact-match (REQ-002), bug PII + PR no-secrets (REQ-019/020), SECURITY.md softened SLA (REQ-006). All 8 present and unweakened.
- BC invariants (4 negatives): still PASS — see BC row above.
- Gate 1 deferrals as roadmap entries: still PASS — REQ-009 + REQ-014 unchanged.
- AC count >= REQ count: PASS — 115 ACs >= 88 REQs (ratio ~1.31:1, slightly tighter than 1.25:1 in Round-1 but still comfortable).
- EARS phrasing sample: PASS — sampled REQ-050a ("After ... elapses ... SHALL transition"), REQ-050b ("BEFORE ... MUST read ... MUST skip"), REQ-050c ("fires once per ... transition"), REQ-055a ("MUST be changed to"), REQ-055d ("MUST update"), REQ-060a ("shall, as part of v6.9.0 release content, refresh"), REQ-063a ("shall add explicit defensive ... guards at the top of"), REQ-063b ("shall specify the EXACT citation format ... at all 30 citation sites"). All read correctly. Some compound REQs (e.g., REQ-050a, REQ-052) are wordy but each remains atomic in spec contract terms.
- Traceability no orphans: PASS — every new REQ has a `*Traces to:*` line. Spot-checked REQ-027a/b, REQ-050a/b/c/d/e, REQ-055a/b/c/d, REQ-060a, REQ-063a/b/c/d. All cite either Devil's-Advocate F-NN, Compliance F-04, Quality F-02, or upstream Phase 3 / Gate 1.

---

## MINOR semver re-check

- **Pause Limits is OPTIONAL: PASS** — REQ-050a explicitly states "The new section is OPTIONAL — absence preserves v6.8.x default behavior (no auto-abort), so MINOR semver invariant is preserved." Design.md:671 ships the section with the literal `### Pause Limits (optional)` heading (the parenthetical "(optional)" word is in the heading text). REQ-070 [NEGATIVE — BC] (no new REQUIRED key) is upheld. AC-050a (formal-criteria.md:321-323) verifies presence of `### Pause Limits` heading + `Pause timeout` + default `30 days`. AC-070 verifies no new required-section heading via the 5-row count check.
  
  **Minor bookkeeping drift (F-09 below)**: requirements.md:5 still reads "18 optional Automation Config sections" as the v6.9.0 target. With REQ-050a's added `Pause Limits` section, the post-release count would be 19. AC-071 (formal-criteria.md:563) enumerates the 18 baseline sections (not 19). This is descriptive metadata drift, not a contract violation: REQ-070 (no new REQUIRED) and REQ-071 (no rename of existing) still hold; the new optional section is purely additive. NOT BLOCKING — flagged as F-09 LOW for Phase 7/Phase 8 cleanup.

- **pipeline-paused is additive: PASS** — REQ-050c explicitly states "additive, MINOR-compatible". Design.md:707 confirms "additive — preserves the BC negative REQ-072 since no existing event renamed/removed". REQ-072 [NEGATIVE — BC] enumerates the existing 5 event names (pipeline-started, step-completed, pipeline-completed, pr-created, ceos-agents-block) and asserts none is removed/renamed. Adding a NEW 6th event name does NOT violate REQ-072. AC-072 (formal-criteria.md:565-572) greps for the 5 baseline names; adding `pipeline-paused` to the codebase does not break this assertion. The `On events` config remains backward-compatible: the new event is OPTIONAL (REQ-050c: "absence preserves v6.8.x default"). REQ-049 + REQ-050d explicitly preserve the existing semantics: `pipeline-completed` MUST NOT fire on pause. The 4-channel contract table at design.md:406 includes `pipeline-paused` as EXCLUDE for `block.detail`, completing the comprehensive enumeration.

- Schema-version stays "1.0": PASS — REQ-044 + REQ-050a + REQ-050c all explicitly preserve `"schema_version": "1.0"` (additive enum members for status: `paused`, `aborted_by_system`; additive optional fields). AC-044 + AC-050a both verify via `grep -F '"schema_version": "1.0"'`.

---

## Findings (new)

### F-09 [LOW — DOCUMENTATION] requirements.md target line 5 still says "18 optional" but Pause Limits is the new 19th
**Severity:** LOW (documentation polish)
**Location:** requirements.md:5; design.md:1307; formal-criteria.md:563 (AC-071)
**Issue:** REQ-050a creates a NEW optional section `### Pause Limits`. The post-v6.9.0 optional-section count is therefore 19, not 18. Three locations still reference "18 optional Automation Config sections":
- requirements.md:5 (Target after release line)
- design.md:1307 (REQ-070 verification prose: "the 5 required + 18 optional structure MUST hold")
- formal-criteria.md:563 (AC-071 enumerates 18 baseline section names; should be 18 baseline + 1 new = 19)

**Why not blocking:** REQ-070 (no new REQUIRED key) is upheld. REQ-071 (no rename of existing optional section) is upheld — adding a 19th does not rename any of the 18. The MINOR semver invariant is preserved. The drift is purely descriptive metadata.

**Recommendation:** Phase 7/Phase 8 cleanup — update the 3 locations to "19 optional" OR add explicit acknowledgement "(was 18 in v6.8.1, +1 for Pause Limits in v6.9.0)". AC-071 should append `Pause Limits` to its enumerated list with a note "added in v6.9.0".

**Action:** Phase 7 implementation note; not blocking Phase 4 verdict.

### F-10 [LOW — DOCUMENTATION] design.md:3 frontmatter says "73 REQs" but file now describes 88
**Severity:** LOW (informational)
**Location:** design.md:3
**Issue:** Design.md line 3 still reads "Companion to: `requirements.md` (73 REQs)" — this is the Round-1 baseline; should be 88 after Round-2 additions.
**Action:** Phase 7 doc-polish; cosmetic only.

### F-11 [LOW — RISK] AC-063 hardened to `==16` (not `≥16`) is correct, but AC-076 still says `wc -l == 16` against `ls core/*.md` (NOT `find -maxdepth 1`)
**Severity:** LOW
**Location:** formal-criteria.md:606 (AC-076)
**Issue:** AC-076 verifies the core-contract count via `ls core/*.md | wc -l == 16`, but Round-2 REQ-063a explicitly REPLACED `ls core/*.md` with `find core -maxdepth 1 -name '*.md' -type f`. AC-076 uses the OLD form. If Phase 7 implements AC-063a's `find` form in `prompt-injection-protection.sh` (mandatory), AC-076's `ls`-based assertion still works on most platforms but is less defensive. Inconsistency is minor.
**Action:** Phase 7 TDD agent should consider tightening AC-076 to also use `find -maxdepth 1`. Not blocking.

### F-12 [LOW — RISK] AC-063b grep for `## Used by:` is checked, but only 1 of 5 snippet draft files (issue-id-validation.md) verifiably contains it in the design.md verbatim text
**Severity:** LOW
**Location:** design.md G-1 verbatim drafts (lines 946-994 + later), formal-criteria.md AC-063b (lines 489-497)
**Issue:** Design.md provides verbatim drafts for `webhook-curl.md`, `issue-id-validation.md`, and per the Round-2 revision history (line 463) "explicit verbatim drafts in design.md G-1 for `core/snippets/metrics-json-schema.md`, `core/snippets/pipeline-completion.md`, `core/snippets/architecture-freshness.md`". Only verified `## Used by:` in `issue-id-validation.md` draft directly (design.md:986). The other 4 snippet verbatim drafts also need to carry `## Used by:` headings to satisfy AC-063b — Phase 7 implementer must remember to add this heading to ALL 5 snippet files, not just the issue-id-validation example shown verbatim.
**Action:** Phase 7 implementation note; AC-063b's grep WILL fail at Phase 8 if any of the 5 snippet files lacks `## Used by:`. Phase 5 TDD agent should write a TDD test that fails until all 5 are added. Not blocking spec.

---

## JSON verdict

```json
{
  "review_id": "phase-4-review-2-compliance",
  "reviewer": "compliance",
  "phase": 4,
  "round": 2,
  "verdict": "PASS",
  "verdict_score": 0.94,
  "round_2_fixes_verified": {
    "f04_shopt_guards": "PASS",
    "paused_lifecycle_traced": "PASS",
    "credential_patterns_9_to_14": "PASS",
    "snippet_citation_format_validity_rollback": "PASS",
    "architecture_refresh_substantive": "PASS",
    "block_detail_4_channel_contract": "PASS"
  },
  "anti_regression": {
    "all_round1_categories_still_pass": "PASS",
    "all_8_agent_c_non_negotiables_unweakened": "PASS",
    "all_4_bc_negatives_still_pass": "PASS",
    "ac_ge_req_ratio": "PASS (115 vs 88, ratio 1.31:1)",
    "ears_phrasing_new_reqs": "PASS",
    "traceability_no_orphans": "PASS"
  },
  "minor_semver_recheck": {
    "pause_limits_is_optional": "PASS",
    "pipeline_paused_is_additive": "PASS",
    "schema_version_stays_1_0": "PASS"
  },
  "findings_count": {
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 4,
    "informational": 0
  },
  "findings_round_1_resolved_or_carried": {
    "f01_low_resolved_no": "carried — citation-completeness meta-grep recommendation still open for Phase 5 TDD",
    "f02_low_resolved_no": "carried — REQ-021 ≥18 vs exactly-18; AC-022 meta-test still preferred",
    "f03_low_resolved_no": "carried — AC-076 enumeration uses '...'; F-11 above tightens",
    "f04_medium_resolved_yes": "RESOLVED — REQ-063a added; design.md G-2 hard-enforces shopt guards + find -maxdepth",
    "f05_low_resolved_no": "carried — sub-header phrasing acceptable",
    "f06_low_resolved_partial": "PARTIAL — AC-080 restructured into AC-080a/b/c/d for finer grep enumeration; informal-grep still applies to some sub-ACs but tightened overall",
    "f07_low_resolved_no": "carried — REQ count 73 → 88, justification documented",
    "f08_low_resolved_no": "carried — Phase 8 verifier prompt should distinguish additive Constraints from BC violation"
  },
  "blocking_findings": [],
  "non_blocking_findings": [
    "F-09 (LOW): requirements.md/design.md/AC-071 still reference '18 optional' — should be 19 after Pause Limits addition; cosmetic drift only",
    "F-10 (LOW): design.md:3 frontmatter still says '73 REQs' — should be 88; cosmetic",
    "F-11 (LOW): AC-076 uses old `ls core/*.md` form; AC-063a mandates `find -maxdepth 1` — inconsistency, both forms work on most platforms",
    "F-12 (LOW): AC-063b requires `## Used by:` heading in ALL 5 snippet files; design.md verbatim demonstrates only issue-id-validation; Phase 7 implementation reminder needed for the other 4"
  ],
  "recommend_next": "Advance to Phase 5 (TDD). Round-2 spec is implementable as-is. Phase 5 TDD agent should: (1) write failing tests for AC-063a shopt guards FIRST (drives the F-04 fix into prompt-injection-protection.sh), (2) write failing tests for AC-063b `## Used by:` in all 5 snippets (drives F-12 fix), (3) cleanup F-09/F-10 cosmetic drift in Phase 7."
}
```

DONE
