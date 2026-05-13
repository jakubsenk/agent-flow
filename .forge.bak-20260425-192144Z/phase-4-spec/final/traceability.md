# v6.10.0 — Traceability (Section 6)

**Companion to:** `requirements.md`, `formal-criteria.md`, `design.md`.

Every REQ → ≥1 AC → ≥1 planned Phase 5 test-scenario filename.
Every AC appears exactly once.
Every REQ appears exactly once.

Planned Phase 5 test-scenario filenames (P5-S*) reference either existing scenarios (modified in v6.10.0) or net-new scenarios specified here. Static-review checks (no test file needed) are labeled `P5-R-{id}` for "Phase 5 review / static check".

---

## Track 1 — Test Discipline Overhaul

| REQ | ACs | Planned Phase 5 test/check | Test type |
|-----|-----|---------------------------|-----------|
| REQ-T1-1 | AC-T1-1-1, AC-T1-1-2 | `tests/scenarios/v6.9.0-changelog-completeness.sh` (exit 77) + `tests/scenarios/v6.9.0-plugin-repo-url-invalid-tld.sh` (exit 77) + `tests/scenarios/ac-v692-autopilot-bash-dispatch.sh` (exit 77) + `tests/scenarios/v6.9.0-webhook-proto-coverage.sh` (exit 77) — verified via harness SKIP count | enumeration + functional |
| REQ-T1-2 | AC-T1-2-1, AC-T1-2-2 | Each of the 16 REWRITE scenarios as P5-S targets (pre-existing paths, diff-verified as newly functional) — see §A below | diff + functional |
| REQ-T1-3 | AC-T1-3-1, AC-T1-3-2 | Each of the 8 EXTEND scenarios — see §B below | diff + functional |
| REQ-T1-4 | AC-T1-4-1, AC-T1-4-2, AC-T1-4-3 | `tests/scenarios/v6.10.0-fixtures-helpers-contract.sh` (NET-NEW — validates fixtures.sh 3-helper API) + static-review P5-R-1 | functional + enumeration |
| REQ-T1-5 | AC-T1-5-1 | `tests/scenarios/v6.10.0-no-awk-source-in-rewrites.sh` (REQ-T1-7) provides the primary gate; scope = `V6100_TOUCHED` (single defn in requirements.md §1) | enumeration |
| REQ-T1-6 | AC-T1-6-1 | `tests/scenarios/v6.10.0-no-awk-source-in-rewrites.sh` + static-review P5-R-2 | enumeration |
| REQ-T1-7 | AC-T1-7-1, AC-T1-7-2, AC-T1-7-3 | `tests/scenarios/v6.10.0-no-awk-source-in-rewrites.sh` (NET-NEW) | functional |
| REQ-T1-8 | AC-T1-8-1 | Phase 8 Commander verification — `.forge/phase-8-verify/final/report.md` review (P5-R-3) | external-research |
| REQ-T1-9 | AC-T1-9-1, AC-T1-9-2 | `./tests/harness/run-tests.sh` output analysis (P5-R-4) | functional |
| REQ-T1-10 | AC-T1-10-1, AC-T1-10-2 | `tests/scenarios/v6.9.0-doc-count-drift.sh` (EXTENDED in place) | enumeration + functional |
| REQ-T1-11 | AC-T1-11-1 | `git diff` check at Phase 5 review (P5-R-5) | diff |
| REQ-T1-12 | AC-T1-12-1 | `./tests/harness/run-tests.sh` output — SKIP count ≥ 4 (P5-R-6) | functional |
| REQ-T1-13 | AC-T1-13-1, AC-T1-13-2 | `tests/scenarios/v6.10.0-contributing-security-section.sh` (NET-NEW) | enumeration |
| REQ-T1-14 | AC-T1-14-1 | Same scenario as REQ-T1-13 with regex on CI-enforcement negative phrase | enumeration |
| REQ-T1-15 | AC-T1-15-1 | `tests/scenarios/v6.10.0-changelog-v6100-entry.sh` (NET-NEW) — grep `CHANGELOG.md` for v6.10.0 + effort annotation | enumeration |
| REQ-T1-16 | AC-T1-16-1 | `git diff` check per KEEP scenario (P5-R-7) | diff |
| REQ-T1-17 | AC-T1-17-1 | `tests/scenarios/v6.10.0-fixtures-helpers-contract.sh` (same as REQ-T1-4) — enumeration arm | enumeration |
| REQ-T1-18 | AC-T1-18-1 | `tests/scenarios/v6.10.0-fixtures-helpers-contract.sh` (enumeration arm) | enumeration |

### §A — REWRITE scenario mapping (REQ-T1-2 — 16 scenarios per Phase 2 table)

| # | Scenario path | Tier | fixtures.sh helpers used |
|---|---------------|------|-----------------------|
| 1 | `v6.9.0-autopilot-skip-paused.sh` | A+B | make_state_json, setup_scratch, require_jq |
| 2 | `v6.9.0-bc-no-removed-agent-output.sh` | B | (inline; no helpers needed) |
| 3 | `v6.9.0-bc-no-removed-webhook-event.sh` | B | (inline) |
| 4 | `v6.9.0-bc-no-renamed-section.sh` | B | (inline) |
| 5 | `v6.9.0-circuit-breaker-non-blocking.sh` | A+B | make_state_json, setup_scratch, require_jq |
| 6 | `v6.9.0-circuit-breaker-semantics.sh` | B | (inline) |
| 7 | `v6.9.0-metrics-format-json.sh` | A+B | require_jq (may use setup_scratch); constructs synthetic metrics JSON via jq -n |
| 8 | `v6.9.0-needs-clarification-dos-cap.sh` | A+B | make_state_json, setup_scratch, require_jq |
| 9 | `v6.9.0-needs-clarification-fixer.sh` | B | (inline) |
| 10 | `v6.9.0-needs-clarification-resume.sh` | B+C | setup_scratch |
| 11 | `v6.9.0-needs-clarification-triage.sh` | A+B | make_state_json, setup_scratch, require_jq |
| 12 | `v6.9.0-outcome-failed-trap.sh` | B | (inline) |
| 13 | `v6.9.0-pause-timeout-validation.sh` | B+C | setup_scratch (**RESOLVED per REQ-T1-5 path (a):** Phase 2 T1-A1-conservative proposal used `awk '/^parse_pause_timeout\(\) \{/,/^}$/'; . $SCRATCH/parse.sh` pattern — PROHIBITED by REQ-T1-5 anti-pattern constraint. Phase 5 MUST instead inline a fresh bash implementation of `parse_pause_timeout()` matching the contract at `skills/autopilot/SKILL.md:parse_pause_timeout()` and test boundary values (1h / 30d / 365d / invalid) directly. The scenario additionally asserts via `grep -q 'parse_pause_timeout() {' skills/autopilot/SKILL.md` that the production source has the canonical signature. See REQ-T1-5 resolution paragraph.) |
| 14 | `v6.9.0-pipeline-history-append.sh` | A+B | setup_scratch; constructs synthetic pipeline-history via jq -n |
| 15 | `v6.9.0-pipeline-history-pii-scope.sh` | A+B | make_state_json (with block.detail field), setup_scratch, require_jq (RESTORED from Phase 2 table — F2 fix) |
| 16 | `v6.9.0-pipeline-paused-webhook.sh` | A+B | make_state_json (status="paused"), setup_scratch (curl-fire simulation may use process substitution) (RESTORED from Phase 2 table — F2 fix) |

Tier-A scenarios (8 required by REQ-T1-18): #1, #5, #7, #8, #11, #14, #15, #16 — all have `jq -n` construction + `jq -e/-r` assertions. Count = 8 (lower bound satisfied exactly). Phase 5 MAY additionally promote #10 or #13 to Tier-A if practical.

### §B — EXTEND scenario mapping (REQ-T1-3)

| # | Scenario path | Extension |
|---|---------------|-----------|
| 1 | `v6.9.0-bc-no-new-required-key.sh` | Add for-loop enumerating 19 optional section names |
| 2 | `v6.9.0-block-handler-counter-example.sh` | Add assertion that counter-example content IS inside HTML-comment markers |
| 3 | `v6.9.0-cross-file-invariants.sh` | Add `diff -q` byte-parity check for template file pairs |
| 4 | `v6.9.0-external-input-marker-receiver.sh` | Loop over 10 pre-patched agents + assert verbatim text |
| 5 | `v6.9.0-jira-dotted-regex-accept.sh` | Add dotted-key negative cases |
| 6 | `v6.9.0-jira-regex-dot-only-reject.sh` | Add `..` and `...` edge cases |
| 7 | `v6.9.0-jq-compact-form.sh` | Add negative check for jq -n without -c |
| 8 | `v6.9.0-pipeline-history-credential-redaction.sh` | Add 3 cycle-1 new credential patterns |

---

## Track 2 — Agent Dispatch Enforcement

| REQ | ACs | Planned Phase 5 test/check | Test type |
|-----|-----|---------------------------|-----------|
| REQ-T2-1 | AC-T2-1-1, AC-T2-1-2 | `tests/scenarios/pipeline-agent-dispatch-models.sh` (MODIFIED in place) | enumeration + functional |
| REQ-T2-2 | AC-T2-2-1, AC-T2-2-2, AC-T2-2-3 | `tests/scenarios/v6.10.0-layer1-imperative-dispatch-coverage.sh` (NET-NEW — grep-counts imperative template tokens across 5 Layer-1 files) | enumeration |
| REQ-T2-3 | AC-T2-3-1, AC-T2-3-2 | Same scenario as REQ-T2-2 with per-file count assertions | enumeration |
| REQ-T2-4 | AC-T2-4-1, AC-T2-4-2, AC-T2-4-3, AC-T2-4-4, AC-T2-4-5 | `tests/scenarios/v6.10.0-validate-dispatch-hook-contract.sh` (NET-NEW — exercises hook with synthetic state.json + contract grep checks) | functional + enumeration |
| REQ-T2-5 | AC-T2-5-1, AC-T2-5-2 | `tests/scenarios/v6.10.0-state-schema-dispatched-at-additive.sh` (NET-NEW — greps `state/schema.md`) | enumeration |
| REQ-T2-6 | AC-T2-6-1, AC-T2-6-2, AC-T2-6-3 | `tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh` (NET-NEW — validates opt-in positioning + advisory check-setup line) | enumeration |
| REQ-T2-7 | AC-T2-7-1, AC-T2-7-2 | `tests/scenarios/v6.10.0-skill-dispatch-enforcement.sh` (NET-NEW — Layer 4 itself) | functional |
| REQ-T2-8 | AC-T2-8-1 | `.forge/phase-4-spec/research/dispatch-hook-api.md` (external research deliverable) | external-research |
| REQ-T2-FALLBACK | AC-T2-FALLBACK-1 | Conditional — only runs if REQ-T2-8 returned LOW/MEDIUM. Same scenario as REQ-T2-6 with conditional branch | enumeration |
| REQ-T2-9 | AC-T2-9-1, AC-T2-9-2 | `.forge/phase-4-spec/research/autopilot-hook-interaction.md` (external research deliverable) + `tests/scenarios/v6.10.0-autopilot-audit-disclosure.sh` (NET-NEW) | external-research + enumeration |
| REQ-T2-10 | AC-T2-10-1 | `tests/scenarios/v6.10.0-layers-3-5-deferred-disclosure.sh` (NET-NEW — greps roadmap.md) | enumeration |
| REQ-T2-11 | AC-T2-11-1 | `git diff v6.9.2..HEAD -- skills/autopilot/SKILL.md` (P5-R-8) | diff |
| REQ-T2-12 | AC-T2-12-1 | `tests/scenarios/v6.10.0-hooks-reference-doc-content.sh` (NET-NEW) | enumeration |
| REQ-T2-13 | AC-T2-13-1 | `tests/scenarios/v6.10.0-dispatch-enforcement-guide-content.sh` (NET-NEW) | enumeration |

---

## Track 3 — Prompt-injection Constraint

| REQ | ACs | Planned Phase 5 test/check | Test type |
|-----|-----|---------------------------|-----------|
| REQ-T3-1 | AC-T3-1-1, AC-T3-1-2 | `tests/scenarios/v6.10.0-roadmap-canonical-source-correction.sh` (NET-NEW) | enumeration |
| REQ-T3-2 | AC-T3-2-1 | `tests/scenarios/prompt-injection-protection.sh` (REWRITTEN — enumeration over all agents) | enumeration |
| REQ-T3-3 | AC-T3-3-1, AC-T3-3-2 | `tests/scenarios/prompt-injection-protection.sh` (REWRITTEN) + pre/post baseline comparison (P5-R-9) | enumeration |
| REQ-T3-4 | AC-T3-4-1 | `tests/scenarios/v6.10.0-external-input-bullet-placement.sh` (NET-NEW — per-agent section-placement check) | enumeration |
| REQ-T3-5 | AC-T3-5-1 | Same scenario as REQ-T3-4 with fenced-block carve-out check | enumeration |
| REQ-T3-6 | AC-T3-6-1 | `tests/scenarios/v6.10.0-no-frontmatter-changes-11-agents.sh` (NET-NEW — diff check against frontmatter range) | diff |
| REQ-T3-7 | AC-T3-7-1 | `tests/scenarios/prompt-injection-protection.sh` (REWRITTEN — AC-4 block) | enumeration |
| REQ-T3-8 | AC-T3-8-1 | `tests/scenarios/v6.10.0-no-receiver-side-bullet-in-11.sh` (NET-NEW — negative grep on 11 new agents) | enumeration |
| REQ-T3-9 | AC-T3-9-1 | `tests/scenarios/prompt-injection-protection.sh` (REWRITTEN — byte-identical regression on 10 pre-patched) | enumeration |
| REQ-T3-10 | AC-T3-10-1, AC-T3-10-2, AC-T3-10-3 | `tests/scenarios/prompt-injection-protection.sh` (REWRITTEN) itself | functional + enumeration |
| REQ-T3-11 | AC-T3-11-1 | `tests/scenarios/prompt-injection-protection.sh` (REWRITTEN — final pass count assertion) | enumeration |
| REQ-T3-12 | AC-T3-12-1, AC-T3-12-2 | `tests/scenarios/v6.10.0-residual-risk-disclosure.sh` (NET-NEW — greps `core/agent-states.md` + `docs/plans/roadmap.md`) | enumeration |

---

## Meta (cross-cutting)

| REQ | ACs | Planned Phase 5 test/check | Test type |
|-----|-----|---------------------------|-----------|
| REQ-META-1 | AC-META-1-1, AC-META-1-2, AC-META-1-3 | `tests/scenarios/v6.10.0-roadmap-corrections-unified.sh` (NET-NEW) | enumeration |
| REQ-META-2 | AC-META-2-1, AC-META-2-2, AC-META-2-3 | `tests/scenarios/v6.9.0-bc-no-new-required-key.sh` (EXTENDED) + `v6.9.0-bc-no-removed-agent-output.sh` (REWRITTEN) + `v6.9.0-bc-no-removed-webhook-event.sh` (REWRITTEN) | enumeration + functional |
| REQ-META-3 | AC-META-3-1 | `tests/scenarios/v6.10.0-changelog-v6100-entry.sh` (same scenario as REQ-T1-15) | enumeration |
| REQ-META-4 | AC-META-4-1 | 5 existing invariant scenarios: `v6.9.0-plugin-license-spdx-canonical.sh`, `v6.9.0-marketplace-license-mirror.sh`, `v6.9.0-security-md.sh`, `v6.9.0-cross-file-invariants.sh`, `v6.9.0-issue-pr-templates.sh` | functional |
| REQ-META-5 | AC-META-5-1 | `tests/scenarios/v6.9.0-doc-count-drift.sh` (EXTENDED) | enumeration |

---

## Summary — planned Phase 5 test-scenario filename enumeration

### Existing scenarios modified (31 — post revision round 1)

1. `v6.9.0-changelog-completeness.sh` — exit 77 added (RETIRE)
2. `v6.9.0-plugin-repo-url-invalid-tld.sh` — exit 77 added (RETIRE)
3. `ac-v692-autopilot-bash-dispatch.sh` — exit 77 added (RETIRE)
4. `v6.9.0-webhook-proto-coverage.sh` — exit 77 added (RETIRE)
5. `v6.9.0-autopilot-skip-paused.sh` — REWRITE (Tier A+B)
6. `v6.9.0-bc-no-removed-agent-output.sh` — REWRITE
7. `v6.9.0-bc-no-removed-webhook-event.sh` — REWRITE
8. `v6.9.0-bc-no-renamed-section.sh` — REWRITE
9. `v6.9.0-circuit-breaker-non-blocking.sh` — REWRITE (Tier A+B)
10. `v6.9.0-circuit-breaker-semantics.sh` — REWRITE
11. `v6.9.0-metrics-format-json.sh` — REWRITE (Tier A+B)
12. `v6.9.0-needs-clarification-dos-cap.sh` — REWRITE (Tier A+B)
13. `v6.9.0-needs-clarification-fixer.sh` — REWRITE
14. `v6.9.0-needs-clarification-resume.sh` — REWRITE
15. `v6.9.0-needs-clarification-triage.sh` — REWRITE (Tier A+B)
16. `v6.9.0-outcome-failed-trap.sh` — REWRITE
17. `v6.9.0-pause-timeout-validation.sh` — REWRITE (inline redefine-and-test per REQ-T1-5 path (a))
18. `v6.9.0-pipeline-history-append.sh` — REWRITE (Tier A+B)
19. `v6.9.0-pipeline-history-pii-scope.sh` — REWRITE (Tier A+B) [RESTORED F2]
20. `v6.9.0-pipeline-paused-webhook.sh` — REWRITE (Tier A+B) [RESTORED F2]
21. `v6.9.0-bc-no-new-required-key.sh` — EXTEND
22. `v6.9.0-block-handler-counter-example.sh` — EXTEND
23. `v6.9.0-cross-file-invariants.sh` — EXTEND
24. `v6.9.0-external-input-marker-receiver.sh` — EXTEND
25. `v6.9.0-jira-dotted-regex-accept.sh` — EXTEND
26. `v6.9.0-jira-regex-dot-only-reject.sh` — EXTEND
27. `v6.9.0-jq-compact-form.sh` — EXTEND
28. `v6.9.0-pipeline-history-credential-redaction.sh` — EXTEND
29. `v6.9.0-doc-count-drift.sh` — EXTEND-in-place (REQ-T1-10)
30. `pipeline-agent-dispatch-models.sh` — grep-pattern update
31. `prompt-injection-protection.sh` — REWRITTEN (enumeration, Track 3)

(4 RETIRE + 16 REWRITE + 8 EXTEND + 1 doc-drift EXTEND + 1 pre-track + 1 prompt-injection = 31 touched existing scenarios.)

### Net-new scenarios (19 — FROZEN; binding for REQ-T1-9 arithmetic)

1. `tests/scenarios/v6.10.0-no-awk-source-in-rewrites.sh` (REQ-T1-7)
2. `tests/scenarios/v6.10.0-fixtures-helpers-contract.sh` (REQ-T1-4, T1-17, T1-18)
3. `tests/scenarios/v6.10.0-contributing-security-section.sh` (REQ-T1-13, T1-14)
4. `tests/scenarios/v6.10.0-changelog-v6100-entry.sh` (REQ-T1-15, META-3)
5. `tests/scenarios/v6.10.0-layer1-imperative-dispatch-coverage.sh` (REQ-T2-2, T2-3)
6. `tests/scenarios/v6.10.0-validate-dispatch-hook-contract.sh` (REQ-T2-4)
7. `tests/scenarios/v6.10.0-state-schema-dispatched-at-additive.sh` (REQ-T2-5)
8. `tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh` (REQ-T2-6)
9. `tests/scenarios/v6.10.0-skill-dispatch-enforcement.sh` (REQ-T2-7 — the Layer 4 test)
10. `tests/scenarios/v6.10.0-autopilot-audit-disclosure.sh` (REQ-T2-9, REQ-T2-10 AC-T2-10-2 — T2-ADV-3 unconditional)
11. `tests/scenarios/v6.10.0-layers-3-5-deferred-disclosure.sh` (REQ-T2-10)
12. `tests/scenarios/v6.10.0-hooks-reference-doc-content.sh` (REQ-T2-12)
13. `tests/scenarios/v6.10.0-dispatch-enforcement-guide-content.sh` (REQ-T2-13)
14. `tests/scenarios/v6.10.0-roadmap-canonical-source-correction.sh` (REQ-T3-1)
15. `tests/scenarios/v6.10.0-external-input-bullet-placement.sh` (REQ-T3-4, T3-5)
16. `tests/scenarios/v6.10.0-no-frontmatter-changes-11-agents.sh` (REQ-T3-6)
17. `tests/scenarios/v6.10.0-no-receiver-side-bullet-in-11.sh` (REQ-T3-8)
18. `tests/scenarios/v6.10.0-residual-risk-disclosure.sh` (REQ-T3-12)
19. `tests/scenarios/v6.10.0-roadmap-corrections-unified.sh` (REQ-META-1)

(19 net-new — reflects scope expansion from judge baseline due to user REWRITE=16 override + explicit Track 2 Layer 2 content verification.)

**Note on harness count (aligned with REQ-T1-9 and design §8.4):** Baseline 185 + 19 net-new − 0 file-deletions (RETIRE uses exit 77) = **204 scenarios** in harness. This is the FROZEN single source of truth — REQ-T1-9 is now hard equality (204), AC-T1-9-1 asserts `==204`, design §8.4 enumerates the 19 net-new. All three documents aligned after revision round 1 F3+F10 reconciliation.

### Static / review checks (9)

- P5-R-1: Manual review of `tests/lib/fixtures.sh` against REQ-T1-4 API surface.
- P5-R-2: Manual scan of new/rewritten scenarios for forbidden source patterns (REQ-T1-6).
- P5-R-3: Phase 8 Commander verification of anti-pattern gate (REQ-T1-8).
- P5-R-4: Harness output count check (REQ-T1-9).
- P5-R-5: Git diff review of `v6.9.0-needs-clarification-e2e.sh` (REQ-T1-11).
- P5-R-6: SKIP count check in harness output (REQ-T1-12).
- P5-R-7: Git diff review of 13 KEEP scenarios (REQ-T1-16).
- P5-R-8: Git diff review of `skills/autopilot/SKILL.md` (REQ-T2-11).
- P5-R-9: Pre/post baseline comparison for Track 3 (REQ-T3-3).

### External-research deliverables (2)

- `.forge/phase-4-spec/research/dispatch-hook-api.md` (REQ-T2-8)
- `.forge/phase-4-spec/research/autopilot-hook-interaction.md` (REQ-T2-9)

---

## Orphan check

- **Orphan REQs (zero ACs):** 0 — every REQ has ≥ 1 AC above.
- **Orphan ACs (zero REQ parent):** 0 — every AC is listed under exactly one REQ.
- **Orphan ACs (zero test):** 0 — every AC maps to at least one scenario, external-research deliverable, or static-review P5-R check above.

---

## Coverage statistics (post revision round 1)

| Track | REQs | ACs | Test scenarios (total) | Static reviews | External research |
|-------|------|-----|-----------------------|----------------|-------------------|
| Track 1 | 18 | 30 | 24 existing + 4 net-new + 1 doc-drift-extend | 7 P5-R | 0 |
| Track 2 | 13 | 23 | 1 existing + 11 net-new | 2 P5-R | 2 |
| Track 3 | 12 | 18 | 1 existing REWRITE + 5 net-new | 1 P5-R | 0 |
| Meta | 5 | 8 | 5 existing + 1 net-new + 1 shared | (included above) | 0 |
| **Total** | **48** | **79** | **31 existing + 19 net-new + 1 doc-drift-extend** | **9 P5-R** | **2 external research** |

Test-type distribution (AC-level, post-revision):
- Functional: 18 ACs
- Diff: 9 ACs
- Enumeration: 48 ACs
- External-research: 4 ACs

**Revision round 1 changes:** Track 1 existing scenarios count increased from 22 → 24 (2 REWRITE restorations — `pipeline-history-pii-scope`, `pipeline-paused-webhook`). Track 2 ACs increased from 21 → 23 (+AC-T2-3-3 file-set completeness, +AC-T2-10-2 T2-ADV-3 unconditional). Total ACs 77 → 79. Harness target hard-frozen at 204 (REQ-T1-9, AC-T1-9-1/2, design §8.4).

All targets (per spec.md template Section 3): **≥1 AC per REQ ✓**, **≥1 test per AC ✓**, **AC test-type cited ✓**, **expected assertion cited ✓**, **expected failure mode cited ✓**, **scope freeze from roadmap ✓**, **out-of-scope list CLOSED ✓**, **MINOR-justification dedicated REQ (META-2) ✓**, **V6100_TOUCHED single scope definition ✓ (F4)**, **Research artifact schema defined ✓ (F5)**, **Commander gate-execution protocol explicit ✓ (F9)**.
