```json
{
  "reviewer": "phase-4-compliance-round2",
  "review_target": "phase-4-spec/final/{requirements,design,formal-criteria}.md (revision 1)",
  "authoritative_source": "phase-3-brainstorm/final.md + gate-decision.json",
  "round": 2,
  "prior_round_verdict": "FAIL (1 MINOR: f-compliance-O traceability)",
  "tier_1": {
    "A_token_field_tokens_used": {"pass": true, "notes": "`tokens_used` everywhere in COST-R2/R5/R7; all state.json examples in §4.1/§4.2 use tokens_used. `tokens_estimated` appears ONLY in §8.6 as a documented forge-divergence note and Section 7 row 1 rationale — never as a ceos field name."},
    "B_schema_version_1_0": {"pass": true, "notes": "COST-R1 still mandates `\"1.0\"`; NOT_IN_SCOPE #8 retained; Section 7 row 2 retained; AC-14 grep expects exactly `\"1.0\"` and bans `\"1.1\"`. No drift during revision."},
    "C_event_granularity_top_level_only": {"pass": true, "notes": "WEBHOOK-R6 unchanged; NOT_IN_SCOPE #2 retained; AC-12 greps for absence of per-iteration fires."},
    "D_core_refactor_extend_post_publish": {"pass": true, "notes": "Design §3.2 still MODIFY (not NEW) for `core/post-publish-hook.md`; NOT_IN_SCOPE #7 retained; requirements.md line 104. No new `core/pipeline-events.md` file anywhere in spec."},
    "E_payload_run_id_outcome": {"pass": true, "notes": "§4.3/4.4/4.5 show run_id on all three events; `outcome` on pipeline-completed. `run_id` semantics refined to `{issue_id}_{ISO8601}` — see round-2 gate-1-drift analysis below; this is a refinement, not an overturn."},
    "F_dry_run_full_short_circuit": {"pass": true, "notes": "AUTOPILOT-R11 enumerates all 4 negations (no lock, no state, no webhook, no dispatch); AC-8 asserts lock absence + webhook absence."},
    "G_feature_query_absent_warn": {"pass": true, "notes": "AUTOPILOT-R7 WARN preserved; AUTOPILOT-R8 WARN preserved and now traced via AC-31."},
    "H_lock_mkdir_directory_owner_120_trap": {"pass": true, "notes": "§4.6 DIRECTORY retained; §4.8 shows portable bash `mkdir` + awk `mktime` (no GNU-date, no PowerShell); AUTOPILOT-R2/R4/R5 intact; trap installed only AFTER successful mkdir (revision tightening); trap verifies ownership before rm -rf (revision tightening — preserves Gate 1 intent). No PowerShell anywhere in spec."},
    "I_metrics_additive_no_format_json": {"pass": true, "notes": "§3.4 step 3b additive; COST-R7 heuristic fallback; NOT_IN_SCOPE #4 retained. `--format json` appears only as forbidden."},
    "J_summary_inline_no_separate_artifact": {"pass": true, "notes": "COST-R6 + §4.2 put summary_table in state.json.pipeline; NOT_IN_SCOPE #5 retained; `pipeline-summary.json` appears only as forbidden."},
    "K_autopilot_disable_model_invocation": {"pass": true, "notes": "AUTOPILOT-R1 mandates `disable-model-invocation: true`; AC-1 greps for it."},
    "L_batch_events_not_in_spec": {"pass": true, "notes": "NOT_IN_SCOPE #3 retained; no autopilot-started/completed EARS anywhere. `autopilot-started`/`autopilot-completed` appear only as forbidden."},
    "M_ears_count": {"pass": true, "notes": "AUTOPILOT 13 (R1..R13), WEBHOOK 8 (R1..R8), COST 12 (R1..R12) = 33 total. Above ≥20 threshold. Revision added R13, R10, R11, R12 to meet quality/devil's-advocate findings."},
    "N_ac_count_with_verify": {"pass": true, "notes": "38 ACs, each with explicit `$ ...` verification command."},
    "O_full_traceability": {"pass": true, "notes": "ROUND 1 FAILURE RESOLVED. EARS→AC map: AUTOPILOT-R1→AC-1/22/23/24; R2→AC-2/30; R3→AC-3; R4→AC-4; R5→AC-5/34; R6→AC-21; R7→AC-7; R8→AC-31 (NEW); R9→AC-6; R10→AC-21/35; R11→AC-8/21; R12→AC-32 (NEW); R13→AC-36. WEBHOOK-R1→AC-9; R2/R3/R4→AC-10/25; R5→AC-11/26; R6→AC-12; R7→AC-33 (NEW); R8→AC-13. COST-R1→AC-14; R2→AC-15; R3→AC-16; R4→AC-15; R5→AC-17; R6→AC-18; R7/R8→AC-19; R9→AC-20; R10→AC-37; R11→AC-19; R12→AC-38. ALL 33 EARS traced."},
    "P_file_coverage": {"pass": true, "notes": "All files listed in spec Section 3 (SKILL files, core/*, state/schema.md, CLAUDE.md, skills.md, config.md, pipelines.md, CHANGELOG.md, plugin.json, marketplace.json, tests/, docs/guides/autopilot.md) appear in design §3.1–§3.7. `skills/workflow-router/SKILL.md` and `docs/reference/pipelines.md` were added during revision (f-quality-3)."},
    "Q_lock_cleanup_trap_exit": {"pass": true, "notes": "AUTOPILOT-R5 explicit; §4.8 `install_trap` function registers EXIT trap only AFTER successful mkdir; trap body verifies pid ownership before rm -rf. AC-5 (grep) + AC-34 (runtime) cover both."},
    "R_schema_version_stays_with_rationale": {"pass": true, "notes": "Requirements §7 row 2 stays `\"1.0\"` with rationale; NOT_IN_SCOPE #8 retained; COST-R9 clarifies /resume-ticket doesn't read schema_version."},
    "S_not_in_scope_count_and_match": {"pass": true, "notes": "22 NOT_IN_SCOPE items (expanded from round-1 count 18 with §6.19 tracker-lock, §6.20 circuit breaker, §6.21 SSRF guard, §6.22 MCP retry — all from devil's-advocate findings 2/4/7). Items 1–12 map to Gate 1 rejections; items 13–22 cover WONTFIX/forge.json/deferrals + revision additions."},
    "T_version_bump_6_7_2_to_6_8_0": {"pass": true, "notes": "requirements.md line 4 + design §3.6 rows 9–10 bump `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` to 6.8.0. AC-27 asserts 2 matches of `\"version\": \"6.8.0\"`."},
    "aggregate_pass": true
  },
  "tier_2": "not applicable for spec review",
  "tier_3": {
    "correctness": 5,
    "completeness": 5,
    "security": 5,
    "maintainability": 5,
    "robustness": 5,
    "notes": "Completeness restored to 5/5 — all 33 EARS now traced; new NOT_IN_SCOPE entries formally bound the deferred concerns (SSRF, circuit breaker, MCP retry, tracker-level lock) to v6.9.0 with explicit Known-Limitations pointers. Revision tightened lock snippet to be race-free, CWD-safe, ownership-verified, and clock-skew-buffered — all improvements over round-1 that do NOT change Gate 1 semantics."
  },
  "overall_verdict": "PASS",
  "confidence": 0.96,
  "findings": [],
  "gate_1_drift_detected": false,
  "gate_1_refinement_analysis": {
    "item": "run_id semantics",
    "gate_1_text": "approved — include run_id on all 3 events (gate-decision.json row 1)",
    "brainstorm_stated_rationale": "enables re-run correlation; consumers cannot distinguish two runs of the same ID without run_id (final.md §'Gate 1 Discussion Points for user')",
    "brainstorm_sample_value": "\"run_id\": \"PROJ-42\" (equal to issue_id in the example payloads)",
    "revision_change": "run_id = \"{issue_id}_{started_at_ISO8601}\" (design.md Canonical Definitions + §4.3/4.4/4.5)",
    "verdict": "REFINEMENT, NOT OVERTURN",
    "reasoning": "Gate 1 approved run_id INCLUSION with the explicit STATED purpose of re-run correlation. A run_id equal to issue_id cannot actually distinguish re-runs — it would be a hollow/no-op field that contradicts Gate 1's stated intent. The revision's {issue_id}_{ISO8601} formulation is the faithful implementation of the Gate 1 purpose. Devil's-advocate finding f-devilsadvocate-1 correctly identified this semantic gap in the brainstorm's sample payloads. Known-Limitations §8.1 documents the sub-second collision caveat. This refinement STRENGTHENS the Gate 1 decision rather than overturning it."
  },
  "same_error_twice_stop_check": {
    "triggered": false,
    "round_1_finding": "f-compliance-O — AUTOPILOT-R8, AUTOPILOT-R12, WEBHOOK-R7 untraced",
    "round_2_status": "ALL THREE now traced via AC-31 (R8), AC-32 (R12), AC-33 (R33). Round-1 finding fully remediated. No repeated failure."
  },
  "new_findings_from_revision": {
    "count": 0,
    "notes": "Revision introduced AC-31..AC-38, AUTOPILOT-R13, COST-R10/R11/R12, NOT_IN_SCOPE §6.19–§6.22, Known-Limitations §8.1–§8.9, Canonical Definitions preamble, and a rewritten §4.8 lock snippet. Every addition is traceable to a reviewer finding (compliance/quality/devil's-advocate) or a Gate 1 intent refinement. No Gate 1 decision was overturned; no new Tier-1 drift detected."
  },
  "recommended_action": "PASS — proceed to Gate 2 aggregation with confidence 0.96. Spec is Gate-1-faithful across all 20 Tier-1 checks. Round-1 MINOR traceability finding fully resolved by 3 new ACs (plus 5 additional ACs addressing quality/devil's-advocate findings). run_id refinement is a legitimate Gate 1 tightening, not an overturn."
}
```

## Reviewer notes (round 2)

### Round-1 finding remediation

**f-compliance-O (MINOR, traceability):** RESOLVED.

The round-1 review identified three EARS IDs lacking any AC `Traces:` link — AUTOPILOT-R8, AUTOPILOT-R12, WEBHOOK-R7. The revision added exactly the three ACs the round-1 remediation section recommended:

- **AC-31** traces AUTOPILOT-R8 via `tests/scenarios/autopilot-feature-limit-no-query.sh`
- **AC-32** traces AUTOPILOT-R12 via `tests/scenarios/autopilot-mcp-unreachable.sh`
- **AC-33** traces WEBHOOK-R7 via `tests/scenarios/webhook-no-step-skipped.sh`

All three scenarios appear in design.md §3.7 test inventory. The corresponding EARS text in requirements.md §2 is unchanged; only trace bookkeeping was added.

### Full round-2 EARS → AC coverage map (all 33 EARS covered)

AUTOPILOT-R1 → AC-1, 22, 23, 24 | R2 → AC-2, 30 | R3 → AC-3 | R4 → AC-4 | R5 → AC-5, 34 | R6 → AC-21 | R7 → AC-7 | **R8 → AC-31** | R9 → AC-6 | R10 → AC-21, 35 | R11 → AC-8, 21 | **R12 → AC-32** | R13 → AC-36

WEBHOOK-R1 → AC-9 | R2/R3/R4 → AC-10, 25 | R5 → AC-11, 26 | R6 → AC-12 | **R7 → AC-33** | R8 → AC-13

COST-R1 → AC-14 | R2 → AC-15 | R3 → AC-16 | R4 → AC-15 | R5 → AC-17 | R6 → AC-18 | R7/R8/R11 → AC-19 | R9 → AC-20 | R10 → AC-37 | R12 → AC-38

### Gate 1 drift check — all 12 decisions still intact

1. Token field `tokens_used` — PRESERVED (all COST-R* + §4.1 examples).
2. `schema_version "1.0"` — PRESERVED (COST-R1, NOT_IN_SCOPE #8, §7 row 2).
3. Top-level events only — PRESERVED (WEBHOOK-R6, NOT_IN_SCOPE #2).
4. Extend `core/post-publish-hook.md` — PRESERVED (§3.2 MODIFY; no new pipeline-events.md).
5. Payload = roadmap-min + run_id + outcome — PRESERVED (§4.3–4.5); run_id semantics REFINED (see below).
6. Dry-run full short-circuit — PRESERVED (AUTOPILOT-R11).
7. Autopilot `disable-model-invocation: true` — PRESERVED (AUTOPILOT-R1).
8. Feature-Workflow absence = `[WARN]` — PRESERVED (AUTOPILOT-R7/R8).
9. Lock mechanism = `mkdir` portable bash — PRESERVED (§4.6, §4.8; no PowerShell anywhere).
10. `/metrics` additive, no `--format json` — PRESERVED (§3.4, NOT_IN_SCOPE #4).
11. Summary in `state.json.pipeline.summary_table` — PRESERVED (COST-R6, NOT_IN_SCOPE #5).
12. No batch events — PRESERVED (NOT_IN_SCOPE #3).

### Gate 1 refinement — `run_id` value format

The revision changed `run_id` from a hollow `issue_id`-equivalent (as shown in the brainstorm's sample payloads) to `"{issue_id}_{started_at_ISO8601}"`. This was surfaced by the Devil's Advocate as f-devilsadvocate-1.

**Verdict: REFINEMENT, NOT OVERTURN.**

Gate 1 row 5 approved "run_id on all 3 events" with the explicit rationale in the brainstorm final.md "Gate 1 Discussion Points" section: *"enables re-run correlation; consumers cannot distinguish two runs of the same ID without run_id."* A `run_id` equal to `issue_id` mathematically cannot enable re-run correlation — it is a no-op field that contradicts the stated purpose. The revision's `{issue_id}_{ISO8601}` formulation makes the field actually perform its approved function. Known-Limitations §8.1 documents the sub-second collision edge case.

### No new Tier-1 findings

The revision introduced substantive additions (AC-31..AC-38, AUTOPILOT-R13, COST-R10/R11/R12, four new NOT_IN_SCOPE entries, nine Known-Limitations sections, a rewritten §4.8 lock snippet, a Canonical Definitions preamble with full Stage→Agent→Model table). Every addition is attributable to a named reviewer finding (compliance / quality / devil's-advocate) or to a refinement of an approved Gate 1 decision. No Tier-1 drift detected; no new compliance concerns introduced.

### STOP-3 (Same Error Twice) check — NOT TRIGGERED

Round 1 MINOR finding `f-compliance-O` (traceability gap on three EARS IDs) is fully remediated in round 2. No repeated failure. Escalation #2 is not warranted.

### Tier-3 scoring rationale (round 2)

- **Correctness (5/5):** Every Gate 1 decision faithfully rendered; run_id refinement is a legitimate tightening.
- **Completeness (5/5):** Round-1 docked point restored — all 33 EARS now traced; new NOT_IN_SCOPE entries formally scope deferred concerns.
- **Security (5/5):** Lock semantics race-free and ownership-verified; webhook URL operator-trust note + §6.21 SSRF defer documented; dry-run has zero side effects.
- **Maintainability (5/5):** Canonical Definitions preamble removes Stage/Agent ambiguity; file-level diff table is diff-able; every EARS has ID; NOT_IN_SCOPE count grew to 22 with explicit forward pointers.
- **Robustness (5/5):** Defensive usage reads, trap-race fixes, clock-skew buffer, empty-lock recovery, cross-host WARN — all documented in §4.8 + AUTOPILOT-R5/R13.

### Recommendation

**PASS.** Proceed to Gate 2. No further revision required on the compliance dimension.
