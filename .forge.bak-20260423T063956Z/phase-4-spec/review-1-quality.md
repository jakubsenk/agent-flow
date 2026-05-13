# Phase 4 Quality Review

**Reviewer:** Phase 4 Reviewer #2 (QUALITY) — independent of upstream traceability review.
**Inputs evaluated:**
- `C:/gitea_ceos-agents/.forge/phase-4-spec/final/requirements.md` (73 REQs)
- `C:/gitea_ceos-agents/.forge/phase-4-spec/final/design.md`
- `C:/gitea_ceos-agents/.forge/phase-4-spec/final/formal-criteria.md` (91 ACs)
**Date:** 2026-04-19

## Verdict: CONDITIONAL_PASS

Spec is high-quality and largely Phase 5/7-consumable. Most REQs are atomic, machine-checkable, and design-doc backed with verbatim text. A small set of compound REQs and a few line-range/AC precision gaps need cleanup before Phase 5/7. None are blockers; all are mechanical tightening.

---

## Per-criterion

1. **Atomicity: CONDITIONAL_PASS** — Sample of 15 REQs reveals ~6 compounds that should be split or explicitly justified as a multi-clause atomic edit. See F-01 .. F-04.
2. **Testability: PASS** — Every REQ has at least one objective check (file-exists / grep / line-number / harness-scenario). No "looks right / is reasonable" wording. One soft spot in REQ-006 sub-clause (a)/(b)/(c)/(d) — verifiable, but multi-grep, see F-05.
3. **AC machine-checkability: PASS** — Every AC names a verification method AND quotes the expected pattern. AC-014 is mildly weak (`OR` clause), AC-031 partially relies on documentation grep. See F-06.
4. **AC ↔ REQ tracing: PASS** — Sample of 20 ACs (AC-001..AC-020) all carry explicit `(traces REQ-NNN)` tags. Extension ACs (AC-074..AC-091) also trace. No orphans found.
5. **Design completeness: CONDITIONAL_PASS** — Verbatim text is provided for LICENSE, SECURITY.md, CODE_OF_CONDUCT.md, all 3 issue/PR templates, /metrics JSON schema, NEEDS_CLARIFICATION fenced block, state.clarification object, post-publish-hook.md Section 5 (incl. sanitize_block_reason), pipeline-history per-run entry format, freshness Bash block, 2 of 5 snippet files (webhook-curl, issue-id-validation). However, **3 of 5 snippet files lack verbatim drafts** (metrics-json-schema.md, pipeline-completion.md, architecture-freshness.md — though the latter two reuse text from §C1/§F that can be copy-pasted, the explicit "Verbatim X" header is missing). See F-07.
6. **Internal consistency: PASS** — Spot-check of 10 REQ↔design↔AC triples: REQ-001/§A1/AC-001, REQ-021/§B-1/AC-021, REQ-024/§B-3/AC-024, REQ-025+026/§B-4/AC-025+026, REQ-040/§D/AC-040, REQ-044/§D/AC-044, REQ-051/§E/AC-051+077, REQ-061/§G-1/AC-061, REQ-064/§D/AC-064, REQ-068/§R-2/AC-068 — all consistent. One minor inconsistency: REQ-064 cites lines `107, 112, 113, 116, 119, 120, 121, 126`; AC-064 same; design.md §D (`prompt-injection-protection.sh updates`) same. Coherent.
7. **Line-range precision: CONDITIONAL_PASS** — Most REQs cite exact line numbers (e.g., `plugin.json:9`, `installation.md` lines 15/26/27/31/36, `state/schema.md:219`, `state/schema.md:449-461`). A handful of REQs say "near", "around", or "Process section (early step)" without line numbers. See F-08.
8. **EARS purity: CONDITIONAL_PASS** — Most REQs use canonical "The system shall X" or "While/When/If ... shall ...". Several REQs combine declarative description with "shall" or omit "shall" entirely in sub-clauses (e.g., REQ-035 sub-sentence "The counter SHALL NOT be added..." is fine, but REQ-046's `When ... the system shall transition to block` is one full sentence with `When` AND a follow-on "While" predicate compounded into one — see F-09).
9. **No prose hand-waving: PASS** — No "implementer should consider" / "if appropriate" / "use judgment" wording found. The closest is REQ-009/REQ-014 deferral notes which contain `"once mirror is provisioned"` / `"once provisioned"` but they're stating roadmap text content (verbatim deferral entries), not implementation judgment calls. Acceptable.

---

## Findings

### F-01 [Atomicity, MINOR] — REQ-006 compound (4 sub-requirements)
REQ-006 includes "(a) Reporting a Vulnerability section, (b) contact email, (c) softened SLA wording (TWO distinct verbatim phrases), (d) Supported Versions section". This is verifiable via multi-grep (AC-006 does so cleanly) but is technically 4–5 atomic sub-requirements. Not a blocker — the design.md §A2 provides the verbatim file, so atomicity is preserved at the artifact level. Recommendation: leave as-is; acknowledge in comment.

### F-02 [Atomicity, MINOR] — REQ-027 compound (TWO actions)
REQ-027 says "AND by updating the hidden test to filter out comment lines" — couples a content edit (block-handler.md:59) with a test edit (h-block-handler-heredoc.sh). Should be split into REQ-027a (wrap counter-example) and REQ-027b (update hidden test filter). AC-027 already verifies both, so impact is small. **Recommendation:** Split for Phase 5 task graph clarity.

### F-03 [Atomicity, MINOR] — REQ-038 compound (TWO files)
REQ-038 mandates an addition to `skills/autopilot/SKILL.md:344-353` AND a parallel "Multi-Host Coordination" subsection in `docs/guides/autopilot.md`. Two independent file edits with one phrase shared between them. AC-038 verifies both. Recommendation: split or explicitly note "atomic 2-file edit" in REQ comment.

### F-04 [Atomicity, MINOR] — REQ-064 compound (CLAUDE.md + 8 test lines)
REQ-064 covers a single 1-char text change in `CLAUDE.md:27` AND 8 hardcoded `15`→`16` updates in `prompt-injection-protection.sh`. Two distinct files. Atomic at the "core-count drift fix" semantic level but still 9 separate text changes. **Recommendation:** Acceptable as-is given the shared semantic ("count drift fix"); design.md and AC-064 enumerate every line.

### F-05 [Testability, MINOR] — REQ-006 sub-clauses are testable but verbose
REQ-006's four sub-clauses each require their own grep. AC-006 lists 5 separate greps. Not a problem for Phase 5 (it's a checklist). Just noting that complex multi-clause REQs increase AC complexity.

### F-06 [AC machine-checkability, MINOR] — AC-014 has an `OR` clause
AC-014 says: `grep -F 'Replace https://example.invalid/ceos-agents.git placeholder' docs/plans/roadmap.md` OR (alternative grep) — this `OR` allows two valid passing forms. **Recommendation:** Pick one canonical phrase from the design.md §A3 verbatim entry and assert exactly that. Same minor issue with AC-031 which mixes documentation grep + behavioral assertion.

### F-07 [Design completeness, MINOR] — 3 snippet files lack explicit "Verbatim" header
- `core/snippets/metrics-json-schema.md` — design.md §G-1 says "Phase 2 §9.8 verbatim JSON schema" but doesn't explicitly include the snippet file's heading + framing. The schema itself IS verbatim in §C1 — Phase 7 implementer would need to wrap it in a markdown heading + "See also" framing matching the pattern used by webhook-curl.md.
- `core/snippets/pipeline-completion.md` — no verbatim text shown anywhere. Description says "terminal `pipeline-completed` payload pattern (`outcome` enum, `pr_url` nullable, limitation note for `failed`)" — this is a specification, not the file content. Phase 7 implementer must compose the file from §C3 prose. **Recommendation:** Add an explicit verbatim block in design.md §G-1 for this file.
- `core/snippets/architecture-freshness.md` — the Bash block IS provided verbatim in §F. Phase 7 implementer must wrap it in a markdown framing. **Recommendation:** Add the explicit "Verbatim core/snippets/architecture-freshness.md" header in §G-1 with the frame.

### F-08 [Line-range precision, MINOR] — Vague insertion points
- REQ-040: "core/agent-states.md (≈50 lines)" — file is NEW, no line range needed. OK.
- REQ-051: "Section 5 ... fires AFTER Section 4 ... appends one H2 run-entry" — no specific line in post-publish-hook.md given. Design.md §E says "MODIFY core/post-publish-hook.md — add Section 5 (~35 lines)" — also no line. **Recommendation:** Phase 7 will infer "after Section 4". Acceptable for an additive section, but tightening to a line number reduces ambiguity.
- REQ-053: "add Process steps to agents/fixer.md (read last 5 entries) and agents/reviewer.md (read last 10 entries)" — no line in either file. Design.md §E says "Insert into agents/fixer.md Process section (early step, before code analysis)" — qualitative. **Recommendation:** Cite a specific line or anchor (e.g., "after the H2 `## Process`").
- REQ-058: "When `last_commit` is empty ... emit ..." — refers to the Bash block, OK.
- REQ-065: "Insert after `## Versioning Policy` section" — qualitative anchor. Acceptable since CLAUDE.md sections are stable named anchors.
- REQ-066: "Append to existing `## Webhook Payloads` section" — same; acceptable.
- REQ-016: `CONTRIBUTING.md:103-108` — explicit. OK.
- REQ-007: "append a one-line pointer to CONTRIBUTING.md Reporting Issues section" — no line. Acceptable for an append into a named section.
- REQ-013: explicit lines.
- Net: ~5 REQs use named-section anchors instead of line numbers. Standard practice; not a blocker.

### F-09 [EARS purity, MINOR] — A few REQs have compound conditions
- REQ-045: `While state.clarification.clarifications_consumed >= 3, when the fixer or triage-analyst emits a new ## NEEDS_CLARIFICATION, the system shall transition the pipeline to block with reason ... instead of pausing.` — this combines a "While" predicate with a "When" trigger and an "instead of" alternative. EARS allows nested compounds, but it's at the outer edge of clarity. Reads correctly.
- REQ-046: same pattern as REQ-045. Same comment.
- REQ-049: `When the pipeline transitions to status: "paused" (NEEDS_CLARIFICATION), the system shall NOT fire the pipeline-completed webhook event. The pause is non-terminal.` — second sentence is descriptive, not EARS. Acceptable as documentation, but technically not part of the requirement statement. Minor.
- REQ-035: `The counter SHALL NOT be added to state/schema.md.` — second sentence is bare "shall not"; missing "the system" subject. Minor.
- REQ-022: `[NEGATIVE]` `The system shall NOT contain any curl invocation in [files] that is missing --proto "=http,https" (regression-proofed via meta-test).` — fine, but the parenthetical "(regression-proofed via meta-test)" is implementation guidance, not part of the requirement. Mild prose-bleed, not a hand-wave.
- REQ-010: parenthetical "(RFC 2606 reserved .invalid TLD, guaranteed non-resolvable)" — same pattern; informational, not a requirement clause. Acceptable.

### F-10 [Internal consistency, INFO] — REQ-049 ↔ Section 4.2 design coverage
REQ-049 mandates that `pipeline-completed` does NOT fire on pause. Design.md §D `core/agent-states.md` Section 2 "Webhook behavior" subsection states this verbatim. AC-049 verifies via harness scenario. Triple is consistent.

### F-11 [Internal consistency, INFO] — REQ-040 description vs design depth
REQ-040 says "≈50 lines". Design.md §D `core/agent-states.md` verbatim text (lines 528-581 of design.md) is ~54 lines. Within tolerance (REQ used "≈"). Consistent.

### F-12 [Atomicity / EARS, MINOR] — REQ-061 enumerates 5 file creations as one REQ
REQ-061 mandates creating 5 files. Atomic at the "Q4 ADOPT-ALL" semantic level. Could be split into REQ-061a..e but that doubles the REQ count without adding rigor. Design.md §G-1 enumerates each. AC-061 verifies all 5 via file-exists. Acceptable.

### F-13 [AC machine-checkability, INFO] — AC-021 line-count language is loose
AC-021 expects "skills/fix-bugs/SKILL.md ≥ 13 (was 0); in skills/implement-feature/SKILL.md ≥ 3 (was 0)". The `≥` is correct given that snippet ADOPT-ALL may reduce count when curls are extracted to snippet-cite. AC-074 (extension) explicitly verifies the line-count change is `± 0` or `± snippet-cite delta`. Pair (AC-021 + AC-074) is consistent.

### F-14 [AC machine-checkability, INFO] — AC-062 cite count is configurable
AC-062 says "≥18 matches across the relevant skill files (or — if cite convention is once per skill — at least 1 cite per affected skill file)". The OR allows two cite conventions. Phase 7 implementer chooses; both PASS the AC. Acceptable but less crisp than a single canonical pattern. **Recommendation:** Phase 5 TDD agent should pin one pattern when writing the test scenario.

### F-15 [Design completeness, INFO] — Webhook events list to verify in CHANGELOG
AC-072 verifies all 5 webhook event names exist post-release. AC checks `core/post-publish-hook.md` for 4 of them and `core/block-handler.md` for `ceos-agents-block`. Consistent with REQ-072.

### F-16 [Internal consistency, INFO] — REQ count exceeds the spec template's 30-50 guideline
The spec acknowledges this in the closing note (lines 375-377). The justification is sound — 11 scope categories + cross-cutting + Q4 ADOPT-ALL + BC = 73 atomic REQs. Phase 8 verifier should not penalize for count.

### F-17 [Testability, INFO] — Some "verifiable via review" items
- REQ-070..REQ-073 (BC negatives) are largely verified by `diff` against v6.8.1 baseline. ACs 070-073 are correct in approach but rely on the verifier maintaining the v6.8.1 baseline reference. Phase 8 should confirm the baseline is checked into a stable location.

### F-18 [Cross-cutting INFO] — `state/schema.md:219` line precision
REQ-044 and design.md cite `state/schema.md:219` for the status enum. AC-044 verifies via grep, not line. Phase 7 implementer needs to verify line 219 still holds in the v6.8.1 baseline; if `state/schema.md` has drifted, the line number is wrong. **Recommendation:** Phase 5/7 first-step verification: re-confirm the line numbers in plugin.json (line 9), state/schema.md (lines 219, 315, 449-461), block-handler.md (line 43, 59), and the 18 webhook curl line numbers in skills/* are still accurate against the current HEAD.

---

## Summary of required actions before PASS

| Severity | Finding | Action | Blocker? |
|----------|---------|--------|----------|
| MINOR | F-02 REQ-027 compound | Split into REQ-027a/b | No (AC already covers both) |
| MINOR | F-07 3 snippets lack verbatim drafts | Add explicit verbatim blocks for metrics-json-schema.md, pipeline-completion.md, architecture-freshness.md in design.md §G-1 | No (Phase 7 can infer; recommended for clarity) |
| MINOR | F-06 AC-014 has OR clause | Pick canonical phrase | No |
| MINOR | F-08 5 REQs use section anchors instead of line numbers | Acceptable; verify anchors are stable | No |
| MINOR | F-09 EARS compound conditions in REQ-045/046/049/035 | Reads correctly; clean if revising | No |
| INFO  | F-18 Line numbers may have drifted | Phase 7 first-step check | No (operational hygiene) |

**Aggregate severity:** All findings are MINOR/INFO. None blocks Phase 5 TDD or Phase 7 execution. The spec is consumable.

**Conditional in CONDITIONAL_PASS** = Phase 5 TDD agent MAY proceed; Phase 7 implementer MUST first re-confirm line numbers against current HEAD (F-18). Recommend Phase 4 author pick up F-02 and F-07 before sealing.

---

## JSON verdict

```json
{
  "phase": 4,
  "reviewer": "quality",
  "verdict": "CONDITIONAL_PASS",
  "criteria": {
    "atomicity": "CONDITIONAL_PASS",
    "testability": "PASS",
    "ac_machine_checkability": "PASS",
    "ac_to_req_tracing": "PASS",
    "design_completeness": "CONDITIONAL_PASS",
    "internal_consistency": "PASS",
    "line_range_precision": "CONDITIONAL_PASS",
    "ears_purity": "CONDITIONAL_PASS",
    "no_prose_handwaving": "PASS"
  },
  "findings_count": 18,
  "blockers": 0,
  "minor_issues": 9,
  "info_notes": 9,
  "required_actions": [
    {"id": "F-02", "action": "Split REQ-027 into REQ-027a (wrap counter-example) and REQ-027b (update hidden test filter)", "blocker": false},
    {"id": "F-07", "action": "Add verbatim file content blocks for core/snippets/metrics-json-schema.md, core/snippets/pipeline-completion.md, core/snippets/architecture-freshness.md in design.md §G-1", "blocker": false},
    {"id": "F-18", "action": "Phase 7 first-step: re-verify line numbers in plugin.json, state/schema.md, core/block-handler.md, and 18 webhook sites against current HEAD before mechanical edits", "blocker": false}
  ],
  "recommended_actions": [
    {"id": "F-06", "action": "Tighten AC-014 to a single canonical phrase (drop OR alternative)"},
    {"id": "F-14", "action": "Phase 5 TDD agent: pin one snippet-cite convention when writing AC-062 verifier"}
  ],
  "phase_5_consumable": true,
  "phase_7_consumable": true,
  "next_phase_recommendation": "PROCEED to Phase 5 TDD generation. Address F-02 and F-07 before Phase 7 if time permits; otherwise Phase 7 implementer can infer."
}
```

DONE
