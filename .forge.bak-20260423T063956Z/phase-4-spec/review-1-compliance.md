# Phase 4 Compliance Review

## Verdict: PASS

The Phase 4 spec faithfully implements the Phase 3 brainstorm decisions and the Gate 1 user answers, including the deliberate Q4 deviation (ADOPT ALL 5 snippets). All 11 scope categories are covered, the Agent C non-negotiable security hardenings are present and traceable, the 8-line count-drift fix is enumerated exactly, and the 4 backward-compat negative invariants are explicit. AC count (91) >= REQ count (73). EARS phrasing is correct on the sample. Traceability is complete: every REQ has a "Traces to:" line.

A handful of LOW/MEDIUM findings are noted but do not warrant a revision cycle — they are either documentation polish opportunities or risk mitigations that can be picked up in Phase 5/Phase 7.

---

## Coverage matrix

| Category | REQ-IDs | AC-IDs | Status |
|----------|---------|--------|--------|
| A1 License | REQ-001..005 (5) | AC-001..005, AC-083 (6) | OK |
| A2 SECURITY.md | REQ-006..009 (4) | AC-006..009 (4) | OK |
| A3 Repository URL | REQ-010..014 (5) | AC-010..014 (5) | OK |
| A4 CODE_OF_CONDUCT.md | REQ-015..016 (2) | AC-015..016 (2) | OK |
| A5 Issue/PR templates | REQ-017..020 (4) | AC-017..020, AC-082 (5) | OK |
| B v6.8.1 polish bundle | REQ-021..028 (8) | AC-021..028, AC-074, AC-075, AC-084, AC-089 (12) | OK |
| C1 /metrics --format json | REQ-029..031 (3) | AC-029..031, AC-085 (4) | OK |
| C2 Webhook circuit breaker | REQ-032..035 (4) | AC-032..035, AC-090 (5) | OK |
| C3 outcome:failed | REQ-036..037 (2) | AC-036..037, AC-091 (3) | OK |
| C4 Multi-host lock DEFER | REQ-038..039 (2) | AC-038..039 (2) | OK |
| D NEEDS_CLARIFICATION | REQ-040..050 (11) | AC-040..050, AC-078, AC-087 (13) | OK |
| E pipeline-history.md | REQ-051..055 (5) | AC-051..055, AC-077, AC-086 (7) | OK |
| F architecture freshness | REQ-056..060 (5) | AC-056..060, AC-088 (6) | OK |
| G Cross-cutting (snippets, count, CLAUDE.md) | REQ-061..066 (6) | AC-061..066, AC-076 (7) | OK |
| R Release | REQ-067..069 (3) | AC-067..069, AC-080 (4) | OK |
| BC Backward-compat negatives | REQ-070..073 (4) | AC-070..073, AC-081 (5) | OK |

All 11 in-scope categories (A1, A2, A3, A4, A5, B, C1, C2, C3, C4, D, E, F) have >=1 REQ + >=1 AC. (G, R, BC are in addition to the 11 mandatory categories.)

---

## Mandatory checks

1. **11 categories covered**: PASS — All 11 (A1, A2, A3, A4, A5, B, C1, C2, C3, C4, D, E, F) have >=1 REQ and >=1 AC, enumerated above. G/R/BC are additional categories beyond the mandatory 11 and also covered.

2. **Q4 deviation (5 snippets)**: PASS — REQ-061 explicitly creates ALL 5 snippet files: `core/snippets/webhook-curl.md`, `core/snippets/issue-id-validation.md`, `core/snippets/metrics-json-schema.md`, `core/snippets/pipeline-completion.md`, `core/snippets/architecture-freshness.md`. `requirements.md:314` cites Gate 1 Q4 (b) ADOPT ALL deviation. AC-061 (file-exists, all 5) and AC-079 (each non-empty + has heading) verify. Design.md G-1 enumerates the 5 files with line-count budgets and content. Phase 4 has correctly applied the user's deviation from Judge default (c) PARTIAL.

3. **Q3 8-line enumeration**: PASS — REQ-064 enumerates all 8 lines exactly: 107, 112, 113, 116, 119, 120, 121, 126. AC-064 verifies via `sed -n '107p;112p;113p;116p;119p;120p;121p;126p'` followed by grep counts (8 instances of "16", 0 instances of "15"). Verified against actual file `tests/scenarios/prompt-injection-protection.sh` (127 lines): all 8 line numbers do contain "15" tokens at correct positions. Design.md D section (line 657-664) re-enumerates verbatim. Zero missed lines.

4. **Agent C non-negotiables (8)**:
   - Jira regex dot-only reject: PASS — REQ-026 mandates `! "$ISSUE_ID" =~ ^\.+$` guard at all 4 sites; design.md B-4 spells out the exact conditional `[[ "$ISSUE_ID" =~ ^[A-Za-z0-9#._-]+$ && ! "$ISSUE_ID" =~ ^\.+$ ]]`; AC-026 + AC-075 (12 inputs accept/reject enumeration).
   - NEEDS_CLARIFICATION DoS cap (3/run, 1/iter): PASS — REQ-043 mandates `clarifications_consumed` and `last_clarification_iteration` counter fields inside the `clarification` state object; REQ-045 enforces per-run cap with exact reason string; REQ-046 enforces per-iteration cap. AC-043, AC-045, AC-046 verify. Design.md `state/schema.md` clarification object addition (line 591-608) carries both counters.
   - NEEDS_CLARIFICATION receiver-side EXTERNAL INPUT recognition in fixer.md + triage-analyst.md: PASS — REQ-048 mandates verbatim Constraints text in BOTH agent files. AC-048 grep verifies both. Design.md (line 622-625) provides verbatim text.
   - /metrics --format json `block.detail` exclusion as HARD CONTRACT in state/schema.md: PASS — REQ-030 explicitly states "This exclusion is a HARD CONTRACT documented inline at the `block.detail` field definition in `state/schema.md`" and enumerates the 3 bound consumers (a, b, c). AC-030 verifies via grep `Sensitive field exclusion contract` in state/schema.md. Design.md C1 (line 393-403) provides the verbatim hard-contract paragraph. Not advisory.
   - pipeline-history.md credential redaction with 9-pattern table: PASS — REQ-052 enumerates all 9 patterns by name (URL-embedded credentials, env-var assignments, Bearer tokens, Authorization headers, AWS access key IDs, AWS env-vars, Slack tokens, GitHub tokens, generic API key prefixes). AC-052 grep-checks all 9 [REDACTED-*] tags + 5 input-output round-trip cases. Design.md E (line 706-721) provides the full `sanitize_block_reason()` Bash function with all 9 sed lines.
   - SPDX exact-match canonical "MIT" guard: PASS — REQ-002 mandates exact literal `"MIT"`; REQ-004 [NEGATIVE] rejects all variants enumerated (MIT-License, mit, MIT-1.0, MIT License). AC-002, AC-003, AC-004 + AC-083 dedicated SPDX scenario. Design.md A1 (line 70-75) provides verification pseudocode.
   - Bug template PII warning + PR template no-secrets checkbox: PASS — REQ-019 mandates verbatim PII warning line in BOTH bug_report.md files. REQ-020 mandates `- [ ] No secrets committed` checkbox in BOTH PR template files. AC-019, AC-020 grep verify.
   - SECURITY.md softened SLA wording: PASS — REQ-006 mandates the softened phrasing verbatim: `"acknowledge reports within 5 business days"` and `"fix, public mitigation guidance, OR coordinated-disclosure timeline extension by mutual agreement"`. AC-006 multi-grep verifies both phrases. Design.md A2 (line 89-105) provides the verbatim SECURITY.md content.

5. **Backward-compat invariants (4 negative REQs)**: PASS
   - REQ-070 [NEGATIVE — BC]: no new REQUIRED Automation Config key. AC-070.
   - REQ-071 [NEGATIVE — BC]: no rename of existing optional Automation Config section. AC-071.
   - REQ-072 [NEGATIVE — BC]: no removal/rename of webhook event names. AC-072 (all 5 event names enumerated).
   - REQ-073 [NEGATIVE — BC]: no change to existing agent output sections. AC-073 + AC-081 (publisher template stability extension).

6. **Gate 1 deferrals as roadmap entries**: PASS
   - A3 canonical URL → v6.9.1: REQ-014 [DEFER-DOC] with verbatim entry text in design.md A3 (line 152-154).
   - SECURITY.md secondary contact → v6.9.1: REQ-009 [DEFER-DOC] with verbatim text. AC-009 verifies.

7. **AC count >= REQ count**: PASS — 91 ACs >= 73 REQs (ratio ~1.25:1). Coverage matrix in formal-criteria.md confirms.

8. **EARS phrasing sample (10 REQs)**: PASS — Sampled REQ-001 ("shall include"), REQ-006 ("shall include"), REQ-021 ("shall add"), REQ-026 ("shall reject ... by adding"), REQ-035 ("shall reset"), REQ-045 ("While ... when ... shall transition"), REQ-046 ("While ... when ... shall transition"), REQ-049 ("When ... shall NOT fire"), REQ-058 ("When ... shall emit"), REQ-070 ("shall NOT add"). All use proper EARS keywords. REQ-045 and REQ-046 correctly combine "While" (state precondition) with "When" (event trigger), then "shall ... transition". REQ-049, REQ-058 use "When ... shall". REQ-070..073 use shall NOT properly.

9. **Traceability**: PASS — Every REQ from REQ-001 through REQ-073 has a "Traces to:" line below it linking to the roadmap category (A1, A2, ..., G, R, BC) plus often a sub-anchor (Phase 2 §, Gate 1 Qn, Agent-C non-negotiable, Devil's-Advocate F-n). Spot-checked REQ-001/-005/-021/-026/-040/-048/-061/-070 — all carry trace lines. Zero orphans.

---

## Findings

### F-01 [LOW — DOCUMENTATION] AC-026 grep target inconsistent with REQ-026's explicit "all 4 sites"
**Severity:** LOW
**Location:** formal-criteria.md AC-026 (lines 163-165) vs requirements.md REQ-026
**Issue:** REQ-026 mandates the dot-only reject guard `! "$ISSUE_ID" =~ ^\.+$` "in all four skills". AC-026's primary verification only greps `core/snippets/issue-id-validation.md` (the canonical snippet location after Q4 ADOPT-ALL). If a skill site fails to cite the snippet (or inlines a partial regex without the guard), AC-026's grep will still PASS because the snippet itself is fine. The "OR canonical snippet" wording in the AC header acknowledges this but makes the contract effectively snippet-only.
**Mitigation:** AC-022 (proto coverage meta-test) would catch missing-citation drift for curl, but no equivalent meta-test enforces issue-id-validation citation completeness. Add a defensive grep in AC-026 or REQ-062 verifier that asserts "every skill that previously inlined the regex now cites `core/snippets/issue-id-validation.md`".
**Action:** Optional Phase 5 TDD addition; not a hard FAIL because AC-062 cites "≥4 matches" requirement which provides citation count enforcement.

### F-02 [LOW — DOCUMENTATION] REQ-021 says "all 18" but enumerates 18; AC-021 says "≥18 added curls"
**Severity:** LOW
**Location:** requirements.md REQ-021 vs formal-criteria.md AC-021
**Issue:** REQ-021 enumerates exactly 18 sites (2 + 13 + 3). The line-list is canonical-from-Phase-2-V-1. AC-021 verifies "≥13" (was 0) for fix-bugs etc. The ≥ semantics are slightly looser than the REQ's exact-list semantic. After Q4 snippet adoption replaces inline curls with citations, the literal `curl --proto` count in skill files may drop to 0 (because curls are now cited via snippet), at which point AC-021 may FAIL incorrectly.
**Mitigation:** AC-022 (proto-coverage meta-test) is the resilient verifier; it greps any literal `curl ` line and asserts `--proto` accompaniment. If snippets-only, the meta-test still verifies the snippet itself carries `--proto`. Recommend Phase 5 TDD agent prefer AC-022 over AC-021 for the regression test.
**Action:** Documentation note for Phase 5 TDD agent; not blocking.

### F-03 [LOW — DESIGN] AC-076 hardcodes "16" total core .md files but does not validate the prior 15 enumeration
**Severity:** LOW
**Location:** formal-criteria.md AC-076
**Issue:** AC-076 asserts `ls core/*.md | wc -l` returns exactly 16 — but lists only the new file (`agent-states.md`) and gives partial enumeration of the other 15 (`agent-handoff.md, autopilot-spec.md, block-handler.md, code-review-protocol.md, ... + the new agent-states.md`). The `...` is unverified; if the v6.8.1 baseline had drift unnoticed, the test could pass with the wrong 16.
**Mitigation:** Phase 8 verifier should diff `ls core/*.md` between v6.8.1 tag and HEAD and assert the diff is exactly `+core/agent-states.md` (plus the directory, which is not in the file glob).
**Action:** Phase 5 / Phase 8 strengthening; not blocking.

### F-04 [MEDIUM — RISK] AC-063 verification of non-recursive glob is cautious but does not run with `globstar` enabled
**Severity:** MEDIUM
**Location:** formal-criteria.md AC-063, design.md G-2
**Issue:** Design.md G-2 acknowledges `globstar` as a potential concern but defers to "verify this assumption holds; if globstar is somehow enabled in the test harness, narrow to ...". REQ-063 [NEGATIVE — TEST-INFRASTRUCTURE] is correctly framed as a contract. However, AC-063 only checks `wc -l` returns 16 — if a developer later enables `shopt -s globstar` in `tests/harness/run-tests.sh`, the count silently becomes 21 (16 + 5 snippets) and the regression goes undetected unless someone re-runs the count check.
**Mitigation:** Recommend Phase 5 TDD agent add a defensive `shopt -u globstar` at the top of prompt-injection-protection.sh OR explicitly use `find core -maxdepth 1 -name '*.md' | wc -l` which is depth-bounded.
**Action:** Strong recommendation for Phase 5; not a blocker because design.md flagged the verification mandate at G-2.

### F-05 [LOW — DOCUMENTATION] REQ-067 CHANGELOG sub-header phrasing differs slightly from Phase 2 §Q-G-2
**Severity:** LOW
**Location:** requirements.md REQ-067 vs design.md R-1 (line 887)
**Issue:** REQ-067 says the sub-header should be `**MINOR** — Pipeline Intelligence + OSS Readiness`. Design.md provides the verbatim CHANGELOG entry with this exact phrasing. AC-067's regex `^\*\*MINOR\*\* — Pipeline Intelligence` matches. Consistent — no actual issue. Noted only because the wording is novel (Phase 3 final.md TL;DR mentions "Pipeline Intelligence + OSS Readiness" as a one-liner; Phase 4 elevated this to the canonical CHANGELOG sub-header). Acceptable; documenting that this is a Phase 4 invention not directly traceable to a Phase 2 string.
**Action:** None required.

### F-06 [LOW — RISK] AC-080 grep "snippets (G Q4 ADOPT-ALL)" expects literal "snippets" in CHANGELOG
**Severity:** LOW
**Location:** formal-criteria.md AC-080
**Issue:** Design.md R-1 CHANGELOG entry includes "sub-namespace canonical snippets" (line 896) — so the grep will match. But AC-080's enumeration of required terms is informal; the grep MUST be tightened to actual `grep -F` patterns in the test script. Phase 5 TDD agent should convert AC-080's bullet list into concrete grep assertions.
**Action:** Phase 5 TDD work; not blocking.

### F-07 [LOW — POLISH] REQ count exceeds Phase 4 spec.md guideline 30-50
**Severity:** LOW (informational)
**Location:** requirements.md (line 375-377)
**Issue:** Total REQ count is 73, exceeding the Phase 4 anti-pattern guideline of 30-50. Requirements.md self-acknowledges this with a justification footnote citing the 11-category mandatory coverage + Q4 deviation (5 snippets) + 6 BC/release REQs. Each REQ remains atomic per anti-pattern #2.
**Action:** Justification documented; accept.

### F-08 [LOW — RISK] REQ-073 BC negative for "agent output sections" is structurally checked, but new sections added by REQ-048 may be misread as a violation
**Severity:** LOW
**Location:** requirements.md REQ-048 + REQ-073
**Issue:** REQ-048 ADDS a new Constraints line to fixer.md and triage-analyst.md (receiver-side EXTERNAL INPUT recognition). REQ-073 [NEGATIVE — BC] asserts no agent output section changes. Adding a Constraints line is technically not a "change to existing output section" (it's a new constraint inside the existing Constraints section), but a naive Phase 8 verifier could flag the agent file diff as a BC violation. AC-073 is narrowly scoped to "## Acceptance Criteria" and "## AC Fulfillment" headings only, which avoids this conflict — good design.
**Action:** Phase 8 verifier prompt should explicitly distinguish "new Constraints line in existing section" from "rename/remove of canonical output section". Not a blocking finding.

---

## JSON verdict

```json
{
  "review_id": "phase-4-review-1-compliance",
  "reviewer": "compliance",
  "phase": 4,
  "verdict": "PASS",
  "verdict_score": 0.92,
  "checklist_results": {
    "categories_11_covered": "PASS",
    "q4_deviation_5_snippets": "PASS",
    "q3_8_line_enumeration": "PASS",
    "agent_c_non_negotiables": {
      "jira_regex_dot_only_reject": "PASS",
      "needs_clarification_dos_cap": "PASS",
      "needs_clarification_receiver_side_external_input": "PASS",
      "metrics_block_detail_hard_contract": "PASS",
      "pipeline_history_credential_redaction_9_pattern": "PASS",
      "spdx_exact_match_canonical_mit": "PASS",
      "bug_pii_warning_pr_no_secrets_checkbox": "PASS",
      "security_md_softened_sla": "PASS"
    },
    "bc_invariants_4_negative": "PASS",
    "gate_1_deferrals_roadmap_entries": "PASS",
    "ac_ge_req_ratio": "PASS (91 vs 73)",
    "ears_phrasing_sample_10": "PASS",
    "traceability_no_orphans": "PASS"
  },
  "findings_count": {
    "critical": 0,
    "high": 0,
    "medium": 1,
    "low": 7,
    "informational": 0
  },
  "blocking_findings": [],
  "non_blocking_findings": [
    "F-01 (LOW): AC-026 grep snippet-only — recommend citation-completeness meta-grep",
    "F-02 (LOW): AC-021 ≥18 vs REQ-021 exactly-18 mismatch under snippet-cite mode — defer to AC-022 meta-test",
    "F-03 (LOW): AC-076 enumeration of prior 15 core files uses '...' — Phase 8 should diff against v6.8.1 tag",
    "F-04 (MEDIUM): AC-063 globstar defensive `shopt -u globstar` recommended in prompt-injection-protection.sh",
    "F-05 (LOW): REQ-067 sub-header phrasing is Phase 4 invention — acceptable",
    "F-06 (LOW): AC-080 informal grep enumeration — Phase 5 TDD should harden to grep -F",
    "F-07 (LOW): REQ count 73 exceeds 30-50 guideline — justified by category coverage",
    "F-08 (LOW): REQ-073 BC negative + REQ-048 additive Constraints — Phase 8 prompt should distinguish"
  ],
  "recommend_next": "Advance to Phase 5 (TDD). Phase 5 TDD agent should incorporate F-01, F-04, F-06 strengthenings into test scenario authoring."
}
```

DONE
