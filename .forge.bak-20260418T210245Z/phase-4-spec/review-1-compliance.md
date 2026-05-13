```json
{
  "reviewer": "phase-4-compliance",
  "review_target": "phase-4-spec/final/{requirements,design,formal-criteria}.md",
  "authoritative_source": "phase-3-brainstorm/final.md + gate-decision.json",
  "tier_1": {
    "A_token_field_tokens_used": {"pass": true, "notes": "Every state.json/ceos example uses tokens_used; no tokens_estimated appears as a ceos field name."},
    "B_schema_version_1_0": {"pass": true, "notes": "COST-R1 mandates '1.0'; Section 7 ledger row 2 rationale; NOT_IN_SCOPE #8."},
    "C_event_granularity_top_level_only": {"pass": true, "notes": "Section 1.2 + WEBHOOK-R6 forbid per-iteration fires; NOT_IN_SCOPE #2."},
    "D_core_refactor_extend_post_publish": {"pass": true, "notes": "Section 3.2 modifies core/post-publish-hook.md; NOT_IN_SCOPE #7 forbids new pipeline-events.md."},
    "E_payload_run_id_outcome": {"pass": true, "notes": "Sections 4.3/4.4/4.5 show run_id on all three events; outcome present on pipeline-completed."},
    "F_dry_run_full_short_circuit": {"pass": true, "notes": "AUTOPILOT-R11 enumerates all 4 negations (no lock, no state, no webhook, no dispatch)."},
    "G_feature_query_absent_warn": {"pass": true, "notes": "AUTOPILOT-R7 and AUTOPILOT-R8 emit [WARN] and continue."},
    "H_lock_mkdir_directory_owner_120_trap": {"pass": true, "notes": "Section 4.6 declares directory; 4.8 shows mkdir bash with trap EXIT; AUTOPILOT-R2/R4/R5 mandate 120-min stale + trap cleanup."},
    "I_metrics_additive_no_format_json": {"pass": true, "notes": "Section 3.4 Step 3b additive; COST-R7/R8 heuristic fallback; NOT_IN_SCOPE #4 forbids --format json."},
    "J_summary_inline_no_separate_artifact": {"pass": true, "notes": "COST-R6 + Section 4.2 put summary_table in state.json.pipeline; NOT_IN_SCOPE #5 forbids pipeline-summary.json."},
    "K_autopilot_disable_model_invocation": {"pass": true, "notes": "AUTOPILOT-R1 mandates disable-model-invocation: true; AC-1 greps for it."},
    "L_batch_events_not_in_spec": {"pass": true, "notes": "NOT_IN_SCOPE #3; no autopilot-started/completed EARS requirement."},
    "M_ears_count": {"pass": true, "notes": "AUTOPILOT 12 (≥8), WEBHOOK 8 (≥6), COST 9 (≥6); total 29 (≥20)."},
    "N_ac_count_with_verify": {"pass": true, "notes": "30 ACs, each with explicit `$ ...` verification command."},
    "O_full_traceability": {"pass": false, "notes": "AUTOPILOT-R8 (Feature limit without Feature query WARN), AUTOPILOT-R12 (MCP unreachable exit 3), and WEBHOOK-R7 (no step-skipped event) have zero ACs with matching Traces field. Three EARS IDs untraced — fails 'every EARS appears in at least one AC Traces'."},
    "P_file_coverage": {"pass": true, "notes": "All files listed in spec.md Section 3 (SKILL files, core/*, state/schema.md, CLAUDE.md, skills.md, CHANGELOG.md, tests/) appear in design.md Section 3.1–3.7."},
    "Q_lock_cleanup_trap_exit": {"pass": true, "notes": "AUTOPILOT-R5 explicit; Section 4.8 shows `trap 'rm -rf \"$LOCK_DIR\"' EXIT`."},
    "R_schema_version_stays_with_rationale": {"pass": true, "notes": "requirements.md Section 7 ledger row 2 states stays '1.0' with rationale (no version check, additive, roadmap line 714 PATCH, /resume-ticket is 5-field reader)."},
    "S_not_in_scope_count_and_match": {"pass": true, "notes": "18 NOT_IN_SCOPE items — well over ≥7; items 1–12 map to Gate 1 rejections; items 13–18 cover WONTFIX/forge.json/deferrals."},
    "T_version_bump_6_7_2_to_6_8_0": {"pass": true, "notes": "requirements.md line 4 + design.md Section 3.6 bump plugin.json/marketplace.json to 6.8.0 via /ceos-agents:version-bump."},
    "aggregate_pass": false
  },
  "tier_2": "not applicable for spec review",
  "tier_3": {
    "correctness": 5,
    "completeness": 4,
    "security": 5,
    "maintainability": 5,
    "robustness": 5,
    "notes": "Completeness docked one point for the 3 untraced EARS IDs. All Gate 1 decisions are faithfully rendered; lock semantics, payload shapes, and scope boundaries are unambiguous and Phase-5-ready."
  },
  "overall_verdict": "FAIL",
  "confidence": 0.93,
  "findings": [
    {
      "id": "f-compliance-O",
      "severity": "MINOR",
      "check": "O_full_traceability",
      "summary": "Three EARS IDs lack any AC Traces link: AUTOPILOT-R8, AUTOPILOT-R12, WEBHOOK-R7.",
      "evidence": {
        "AUTOPILOT-R8": "requirements.md L60 — '[WARN] Feature limit={N} configured but no Feature query'. Searched all 30 ACs for 'AUTOPILOT-R8' in Traces — zero matches.",
        "AUTOPILOT-R12": "requirements.md L64 — '[STOP] MCP unreachable ... exit 3'. No AC Traces references AUTOPILOT-R12. Note: AC-21 lists R6/R10/R11 only.",
        "WEBHOOK-R7": "requirements.md L74 — 'NOT emit any step-skipped webhook'. No AC Traces references WEBHOOK-R7 (AC-12 covers only WEBHOOK-R6)."
      },
      "remediation": "Add three targeted ACs or extend existing ACs' Traces fields: (1) AC for AUTOPILOT-R8 — grep or test that Feature-limit-with-no-query emits the WARN line; (2) AC for AUTOPILOT-R12 — test that MCP-unreachable stub produces exit 3 and `[STOP] MCP unreachable` on stderr and that no lock directory is created; (3) AC for WEBHOOK-R7 — grep all four pipeline SKILL.md files showing no 'step-skipped' fire-site emission."
    }
  ],
  "gate_1_drift_detected": false,
  "recommended_action": "FAIL-with-minor-fix: spec is Gate-1-faithful across all 19 substantive checks (A..N, P..T). Only traceability bookkeeping failed. Fix is mechanical: add 3 ACs. No Tier-1 MAJOR (Gate 1 drift) findings."
}
```

## Reviewer notes

### Summary of compliance

All 12 Gate 1 decisions from `.forge/phase-3-brainstorm/gate-decision.json` and the Judge's decision matrix are reproduced in the spec with fidelity:

1. **Token field name** → `tokens_used` everywhere (COST-R2, all state.json examples, ledger row 1).
2. **Schema version** → stays `"1.0"` (COST-R1, AC-14, ledger row 2, NOT_IN_SCOPE #8).
3. **Event granularity** → top-level only (WEBHOOK-R6, NOT_IN_SCOPE #2).
4. **core/ refactor** → extend `core/post-publish-hook.md` (design.md §3.2, NOT_IN_SCOPE #7).
5. **Payload shape** → roadmap minimum + `run_id` on all 3 + `outcome` on `pipeline-completed` (§4.3/4.4/4.5).
6. **Dry-run** → full short-circuit (AUTOPILOT-R11).
7. **Autopilot disable-model-invocation** → `true` (AUTOPILOT-R1).
8. **Feature-Workflow absence** → `[WARN]` + bug-only (AUTOPILOT-R7).
9. **Lock mechanism** → `mkdir`-based bash, DIRECTORY at `.ceos-agents/autopilot.lock/`, `owner.json` inside, 120-min stale, `trap ... EXIT` cleanup (§4.6, §4.8, AUTOPILOT-R2/R4/R5; revised from judge's PowerShell as mandated by gate-decision.json).
10. **/metrics** → additive + heuristic fallback; no `--format json` (COST-R7/R8, NOT_IN_SCOPE #4).
11. **Summary output** → `state.json.pipeline.summary_table` inline (§4.2, NOT_IN_SCOPE #5).
12. **Batch events** → NOT added (NOT_IN_SCOPE #3).

### Single failure

**Check O (traceability)**: three EARS IDs — AUTOPILOT-R8, AUTOPILOT-R12, WEBHOOK-R7 — are not referenced in any AC's `Traces:` field. This is a MINOR bookkeeping defect. All three requirements are defensible and unambiguous in Section 2; they simply lack an AC stub. Fix is additive and non-structural.

### Recommended fix for Phase 5 TDD gate

Before proceeding, add (or extend) three acceptance criteria:

- **AC-31**: `AUTOPILOT-R8` — `Feature limit > 0` without `Feature query` emits the specified `[WARN]` and exits cleanly.
- **AC-32**: `AUTOPILOT-R12` — MCP ping failure exits 3 with `[STOP] MCP unreachable` on stderr and creates no lock directory.
- **AC-33**: `WEBHOOK-R7` — grep the four pipeline `SKILL.md` files for any `step-skipped` emission site; expect zero matches.

With these three ACs added, the spec reaches full AC-to-EARS coverage and becomes Phase-5-ready.

### Tier-3 scoring rationale

- **Correctness (5/5)**: every Gate 1 decision is correctly reproduced; zero drift.
- **Completeness (4/5)**: docked for the three untraced EARS IDs; otherwise complete across Sections 1–7.
- **Security (5/5)**: lock semantics are race-free (atomic `mkdir`); advisory webhook failure prevents pipeline-blocking DoS; dry-run has zero side-effects.
- **Maintainability (5/5)**: file-level diff table is diff-able against an implementation; every EARS has an ID; NOT_IN_SCOPE is explicit.
- **Robustness (5/5)**: defensive reads for `result.usage`, `trap EXIT` cleanup, stale-lock recovery, forward-compat doc paragraph.
