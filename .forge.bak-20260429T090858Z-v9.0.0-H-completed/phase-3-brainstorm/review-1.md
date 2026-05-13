# Phase 3 Brainstorm Review — Round 1

**Reviewer roles:** Standard Reviewer + Devil's Advocate (combined pass)
**Artifact:** `.forge/phase-3-brainstorm/synthesis.md`
**Date:** 2026-04-28

---

## JSON Verdict

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": true,
    "pass": true,
    "notes": "All 5 Tier-1 hard gates met: comparative table is full (7 dims x 3 personas, no empty cells); convergence analysis names which Phase 2 Q resolves each disagreement (D1->Q1+Q3+Q5+Q8, D3->Q11, D4->Q4, D5->Q2+Q3, D2->Q8); recommended synthesis is implementable (5 specific scenario filenames, specific section position, specific Phase 4 mandate); WHETHER verdict is explicit (PARTIAL with Q1/Q11/Q8 justification); BC strategy is concrete (additive optional, SKIP-guarded, customization/ untouched, override injector mechanism cited)."
  },
  "tier_2": {
    "fail_to_pass": null,
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true,
    "notes": "Phase 3 is design-only; no test execution applicable."
  },
  "tier_3": {
    "correctness": 4,
    "completeness": 3,
    "security": 4,
    "maintainability": 3,
    "robustness": 3,
    "weighted_aggregate": 3.5,
    "pass": true
  },
  "overall_verdict": "PASS",
  "confidence": 0.78,
  "findings": [
    {
      "id": "f-7c1a44",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "synthesis.md:68 (Backward-compat strategy / agent count)",
      "description": "Initial rollout target is described inconsistently. Body text says '5 agents whose headings skills grep: fixer, reviewer, analyst, test-engineer, and any agent emitting NEEDS_CLARIFICATION/NEEDS_DECOMPOSITION'. The 'any agent emitting NEEDS_CLARIFICATION' phrase is unscoped — Q1/Q11 indicate multiple agents emit that signal (it is cross-cutting per v6.9.0). Phase 4 Spec mandate then refers to '5-agent initial Outputs rollout' as if 5 is determinate. Phase 4 will need to enumerate the exact agent set (4 named + which subset of 14 also emit cross-cutting signals).",
      "recommendation": "Phase 4 spec must explicitly enumerate the v8.1.0 rollout set. Suggest: keep the 4 named (fixer, reviewer, analyst, test-engineer) as the table-emitters, and treat NEEDS_CLARIFICATION/NEEDS_DECOMPOSITION as cross-cutting *signal* declarations rather than per-agent Outputs sections — i.e., declare them once in CLAUDE.md (or in agents/README.md) as universal escape-hatch outputs that any agent may emit, rather than re-declaring across N agents. This avoids the 'fuzzy 5+N' count."
    },
    {
      "id": "f-3e9b21",
      "severity": "MINOR",
      "criterion": "maintainability",
      "location": "synthesis.md:69 (Versioning Policy amendment in same PR)",
      "description": "Synthesis mandates 'Versioning Policy amendment is required in the same PR' as the v8.1.0 release. The v8.0.1 polish queue (per MEMORY) includes item #6: 'CLAUDE.md residual 21 agents cleanup' — also a CLAUDE.md edit. If v8.0.1 polish lands first, v8.1.0 rebases cleanly; if v8.1.0 lands first, v8.0.1 must rebase. Risk is bounded but real for in-flight parallel work. Synthesis does not mention sequencing.",
      "recommendation": "Phase 4 spec should add an explicit sequencing constraint: either (a) v8.0.1 polish ships first and v8.1.0 rebases, OR (b) v8.1.0 absorbs the 6 deferred polish items as part of the same release (the synthesis already opens this door with 'alongside the queued v8.0.1 polish items if scope allows'). Picking one resolves the merge-conflict risk."
    },
    {
      "id": "f-5d2e08",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "synthesis.md:64-66 (scenarios 3 and 4 — position + polymorphic-split)",
      "description": "Two of the five scenarios have weak teeth in v8.1.0 baseline. Scenario 3 (position) only fires on agents that have ## Outputs; with 4-5 agents in scope, it checks 4-5 files and SKIPs 13. Scenario 4 (polymorphic-split) effectively tests one agent (analyst) since test-engineer's --e2e variant emits the same ## Test Report per Q4 (not a true polymorphic Outputs split). These scenarios are not theater, but their cost-vs-coverage ratio is the lowest of the five and could be pruned without operational loss.",
      "recommendation": "Phase 4 spec may keep scenarios 3 and 4 for forward-compat hygiene, but should explicitly note their low immediate coverage and that they primarily exist as guardrails for future rollout (when more agents adopt ## Outputs). Alternatively, fold scenario 3 into the existing section-order.sh update (already mandated) instead of a separate file, reducing scenario count from 5 to 4."
    },
    {
      "id": "f-9a4f72",
      "severity": "INFO",
      "criterion": "completeness",
      "location": "synthesis.md:55 (WHETHER verdict scope vs user's input)",
      "description": "User input is 'rozhodnout jestli to dělat a jak' framed under v9.0.0 sub-projekt H. Synthesis answers 'jestli' (PARTIAL) and 'jak' (5 scenarios + 4-5 agents) clearly, then reframes the version target from v9.0.0 (per MEMORY) to v8.1.0. This is technically scope-expansion of the brief (the brief assumed v9.0.0 was the version), BUT Phase 2 OQ1 explicitly delegated this binary to Phase 3, and the Q8 policy gap analysis supports the reframe with primary-source evidence. Acceptable, but the user should confirm the v9.0.0 -> v8.1.0 reallocation explicitly before Phase 4 commits to it. MEMORY item 'v9.0.0 = sub-projekt H' is now factually superseded by this synthesis.",
      "recommendation": "Phase 4 spec should open with an explicit user-confirmation gate on the v9.0.0 -> v8.1.0 reallocation, before encoding the rest of the design. If the user wants v9.0.0 to remain sub-projekt H regardless of optional/mandatory split, the synthesis can still be used by re-targeting the same content as v9.0.0 MINOR (since v9.0.0 already has pre-announced breaking changes, an optional Outputs section folded into v9.0.0 alongside .md overlay removal is also coherent — and avoids the v8.1.0 release vehicle entirely)."
    },
    {
      "id": "f-2b8c5e",
      "severity": "INFO",
      "criterion": "correctness",
      "location": "synthesis.md:68 (spec-analyst exclusion)",
      "description": "Spec-analyst is not in the rollout set. Per CLAUDE.md, spec-analyst posts AC as a separate comment to the issue tracker — that output is consumed by the tracker integration, not a skill grep. Q11 evidence does not list any spec-analyst output heading as skill-grepped. The exclusion is defensible, but Phase 4 spec should briefly justify it so reviewers don't second-guess.",
      "recommendation": "One sentence in Phase 4 spec rollout-set rationale: 'spec-analyst output is consumed by tracker integrations, not skill prose-grep, and is therefore out of scope for v8.1.0 ## Outputs lint coverage.'"
    },
    {
      "id": "f-1e3a90",
      "severity": "INFO",
      "criterion": "security",
      "location": "synthesis.md:60-62 (## Outputs section position)",
      "description": "Synthesis places ## Outputs between ## Process and ## Constraints, citing 'natural reading flow: behavior -> outputs -> invariants'. Persona B placed it between ## Expertise and ## Process ('API surface before behavior'). Persona A doesn't place it. Persona C placed it between Process and Constraints (matches synthesis). The choice is defensible but worth a one-line rationale in Phase 4 — primarily because section-order.sh currently asserts the 4-section order Goal/Expertise/Process/Constraints; inserting between Process and Constraints means the new order becomes Goal/Expertise/Process/[Outputs?]/Constraints, which is a localized assertion update.",
      "recommendation": "Phase 4 spec should explicitly write the new asserted section sequence and confirm the section-order.sh update is a 'tolerate optional Outputs at this exact position' rule, not a 'mandatory at this position' rule (since v8.1.0 ships only 4-5 of 18 agents with the section)."
    }
  ]
}
```

---

## Devil's Advocate Pass — Findings by Angle

**Angle 1 — Is recommendation just persona C verbatim?** No. Judge expanded C's 4 agents to 5 (added NEEDS_CLARIFICATION/DECOMPOSITION emitters), expanded C's 4 scenarios to 5 (added customization-collision guard, kept polymorphic-split that C also had, kept position check), added Versioning Policy amendment as PR-bound (C did not), added Cross-File Invariants amendment (C did not). Real synthesis value-add. F-7c1a44 flags the count fuzziness as the cost of that expansion.

**Angle 2 — Does PARTIAL dodge user's "rozhodnout jestli a jak"?** No. Synthesis explicitly answers YES (formalize, narrowly), with concrete scope + version. Phase 2 OQ1 framed exactly this binary; synthesis picks a side and defends it with primary-source evidence (Q1, Q3, Q5, Q8, Q11). f-9a4f72 flags the v9.0.0->v8.1.0 reallocation as a scope-expansion the user should confirm, but it is not a dodge.

**Angle 3 — Are 5 agents right? Test-engineer in, spec-analyst out?** Defensible. Q11 evidence (skills/fix-ticket and skills/fix-bugs grep `## Test Report` from test-engineer; no skill grep cited for spec-analyst output headings — it writes to tracker, not to skill consumers). f-2b8c5e flags this should be explicitly justified in Phase 4.

**Angle 4 — Is v9.0.0 reallocation scope creep?** Partial yes. Brief assumes v9.0.0; synthesis reframes to v8.1.0 with v9.0.0 reserved for pre-announced breaking changes. Phase 2 OQ1 + Q8 do support this reframe with evidence, AND the pre-announced breaking changes (.md overlay hard removal, deprecated agent name hard errors) are already documented. But MEMORY explicitly allocates v9.0.0 to sub-projekt H; this synthesis supersedes that allocation. f-9a4f72 recommends user-confirmation before Phase 4 commits.

**Angle 5 — Can lint-only validation actually fail on a real bug?** Partial yes.
- Scenario 2 (xref-outputs-skill-references) — REAL teeth. Catches the documented drift class (heading rename desync).
- Scenario 1 (shape) — REAL teeth. Asserts table column structure.
- Scenario 5 (customization-collision) — REAL teeth. Catches override file misuse.
- Scenarios 3 (position) + 4 (polymorphic-split) — light teeth in v8.1.0 baseline. f-5d2e08 flags this and recommends folding scenario 3 into section-order.sh update.

Net: the lint package is not theater overall, but 2/5 scenarios are guardrails-for-future rather than immediate value.

**Angle 6 — Same-PR CLAUDE.md amendment risks merge conflicts with v8.0.1 polish?** Yes, real. f-3e9b21 documents this. Mitigation: Phase 4 must pick a sequencing strategy (either polish-first-rebase, or absorb-polish-into-v8.1.0).

---

## Final Summary (under 120 words)

The synthesis SHOULD be the basis of the Phase 4 spec, with three modifications: (1) Phase 4 must enumerate the exact rollout set — pick either "4 agents + cross-cutting NEEDS_* declared once globally" OR "explicit list of N agents that emit those signals"; the current "5 + any agent emitting" is unimplementable as written. (2) Phase 4 must include an explicit user-confirmation gate on the v9.0.0 -> v8.1.0 reallocation since this supersedes MEMORY allocation. (3) Phase 4 must define a sequencing strategy with v8.0.1 polish (rebase-first OR absorb). All Tier 1 gates pass; findings are MINOR/INFO. Devil's-Advocate angles surfaced real concerns but none rise to CRITICAL. Synthesis is sound, evidence-grounded, and closer to persona C than B is the right call given Q1 + Q3 + Q5 + Q8.
