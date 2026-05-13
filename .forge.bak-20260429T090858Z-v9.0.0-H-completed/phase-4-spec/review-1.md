# Phase 4 Spec Review — Round 1
# v9.0.0 sub-projekt H — Agent I/O Contracts

**Reviewer:** Phase 4 Spec Reviewer (fresh eyes)
**Date:** 2026-04-28
**Artifacts under review:**
- `.forge/phase-4-spec/final/requirements.md`
- `.forge/phase-4-spec/final/design.md`
- `.forge/phase-4-spec/final/formal-criteria.md`

**Binding inputs cross-checked:**
- `.forge/phase-3-brainstorm/gate-decision.json` (phase_4_spec_mandate, 10 items 0..9)
- `.forge/phase-2-research-answers/peer-deep-dive.md` (22 frameworks)
- `CLAUDE.md` (Agent Definition Format, Versioning Policy, Cross-File Invariants)
- Source agents: fixer, analyst, test-engineer, publisher, rollback-agent, browser-agent, spec-reviewer, reviewer, spec-writer

---

## JSON Verdict

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": true,
    "pass": true
  },
  "tier_2": {
    "fail_to_pass": null,
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true
  },
  "tier_3": {
    "correctness": 4,
    "completeness": 4,
    "security": 4,
    "maintainability": 4,
    "robustness": 3,
    "weighted_aggregate": 3.85,
    "pass": true
  },
  "overall_verdict": "PASS",
  "confidence": 0.78,
  "findings": [
    {
      "id": "f-7a31bc",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "design.md §2.15 spec-writer, §2.12 scaffolder",
      "description": "spec-writer Outputs table lists `spec/README.md`, `spec/architecture.md`, etc. as `Section produced` rows (file artifacts, not headings). REQ-H-009 explicitly allows this for non-`##` rows but design.md is inconsistent — the `Section produced` cell should backtick-quote the path (`` `spec/README.md` ``) not bare text. Same applies to `.ceos-agents/{ISSUE-ID}/reproducer-script.js` rows in browser-agent and `.ceos-agents/deploy/{timestamp}/result.json` in deployment-verifier. Phase 7 fixers will need to be told explicitly.",
      "recommendation": "Add a one-line clarification in design.md §1.1 that file-artifact rows MUST also backtick-quote the path, mirroring REQ-H-009. Update §2.5, §2.6, §2.12, §2.15 examples accordingly so Phase 7 has a verbatim template."
    },
    {
      "id": "f-d2e44f",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "design.md §3.3 v9-output-contract-position.sh + REQ-H-002",
      "description": "Position assertion uses `grep -nE '^## Process'` for `process_line`. browser-agent has NO bare `## Process` heading — only `## Process: Phase reproduce` (line 27) and `## Process: Phase verify` (line 124). Prefix grep matches both, so first occurrence is line 27, which is fine. But spec is silent on which `## Process` line to anchor against in browser-agent, and `## Phase Dispatch` (line 18) sits BEFORE both Process headings. If a future maintainer adds `## Output Contract` between `## Phase Dispatch` and the first `## Process: Phase reproduce`, the lint would FAIL even though the new section is conceptually 'after Process'. Worth pinning the anchor more precisely.",
      "recommendation": "In REQ-H-002 / AC-H-002, clarify: `process_line = first line matching ^## Process(?:[: ]|$)` AND `output_contract_line` MUST be `> last process-or-phase line`. For browser-agent specifically, the spec should declare that `## Output Contract` sits after BOTH `## Process: Phase X` blocks — i.e., between the last `## Process: Phase verify` content and `## Constraints`. Similarly for analyst. Make it explicit so Phase 7 fixer doesn't guess."
    },
    {
      "id": "f-9b8e10",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "design.md §5 + REQ-H-090 prose-dispatch inventory",
      "description": "REQ-H-090 says '4 prose-idiom dispatches identified during Phase 3' but design.md §5 then lists 6 lines across 6 files (check-deploy:66+79, create-backlog:103+326, sprint-plan:119+137, prioritize:38, scaffold-add:58, publish:208). Verified by grep: 6 prose `Run \\`ceos-agents:X\\` (Task tool, ...)` matches + 1 `Dispatch \\`ceos-agents:deployment-verifier\\` (Task tool, ...)` at check-deploy:66 = 7 total occurrences across 6 files. The number '4' in REQ-H-090 is wrong — the architecture is correct (harmonize them all) but the count misleads Phase 6 task plan.",
      "recommendation": "Update REQ-H-090 'The 4 prose-idiom dispatches' → 'The 7 prose-idiom dispatches across 6 files'. Confirm all 7 are listed in design.md §5 table (currently 6 rows; add the `Dispatch` variant at check-deploy:66 explicitly)."
    },
    {
      "id": "f-c5a712",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "REQ-H-073(c) + design.md §7 Migration Step 2",
      "description": "Migration guide tells consumers to rename `triage-analyst|code-analyst → analyst`, `e2e-test-engineer → test-engineer --e2e`, `reproducer → browser-agent --phase reproduce`, `browser-verifier → browser-agent --phase verify`. But for `triage-analyst → analyst` and `code-analyst → analyst` the migration ALSO requires adding `--phase triage` or `--phase impact` respectively — the design.md §7 'Step 2' bullet does mention this, but REQ-H-073 prose says only 'rename ... to the v8 names' which is incomplete advice (analyst without --phase will error or default-misroute).",
      "recommendation": "Tighten REQ-H-073(c) to: 'rename ... to the v8 names AND add the matching `--phase` flag where applicable (`--phase triage`, `--phase impact`, `--e2e`, `--phase reproduce`, `--phase verify`)'. design.md §7 already does this; sync the prose."
    },
    {
      "id": "f-3a44d0",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "AC-H-021 + AC-H-110 (backward-compat verification protocol)",
      "description": "AC-H-110 pass condition is a bash one-liner that filters expected-diff lines via a complex grep `-vE` chain. The chain enumerates `^[+-]## Output Contract|^[+-]\\| Section|^[+-]\\| `## |^[+-]\\|---|^[+-]### |^[+-]$`. It's fragile — any whitespace variation in the new Output Contract content breaks the filter and the AC reports a false-positive 'non-Output-Contract diff'. For a manual protocol this is acceptable, but it would be saner to extract the section content via awk and assert the pre-section + post-section blocks are byte-identical (positive assertion) rather than filter-the-noise (negative assertion).",
      "recommendation": "Either tighten the regex with `xargs grep` patterns including all common whitespace forms, OR rewrite AC-H-110 as: extract content above `^## Output Contract` and content below `^## Constraints` from both v8 and v9 fixtures; assert byte-equal. Defer to Phase 5 reviewer (already flagged in OQ-C scope)."
    },
    {
      "id": "f-1f9b7a",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "design.md §3.5 v9-xref-outputs-skill-references.sh exclusions",
      "description": "Exclusion filter is `grep -v '^\\`## NEEDS_\\|^\\`## Output Contract\\`'`. This excludes `## NEEDS_CLARIFICATION` and `## NEEDS_DECOMPOSITION` correctly. BUT: the publisher's `## Publish Report`, fixer's `## Fix Report`, etc. ARE referenced in skills — verified manually. However, several outputs declared in design.md §2 are NOT obviously load-bearing strings in skills today: `## Sprint Plan: {sprint_name}` (variable name in heading — grep won't find literal match), `## {Epic Title}` (variable), `## Backlog Summary`, `## Acceptance Gate Report`, `## Spec Compliance Report`. The xref scenario must handle parameterized headings (rows with `{...}` placeholders) gracefully — it should EITHER skip them OR strip the `{...}` and grep the prefix.",
      "recommendation": "design.md §3.5 should add: 'Headings containing `{...}` placeholder tokens (e.g., `## Sprint Plan: {sprint_name}`, `## {Epic Title}`) are EXCLUDED from xref enforcement OR matched by stripping the placeholder and asserting the literal-prefix portion exists in skills. Phase 7 implementer chooses; default = exclude.' Currently the spec is silent on this, and Phase 5 TDD will hit it on day one."
    },
    {
      "id": "f-602b8e",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "REQ-H-100 / REQ-H-101 / REQ-H-102 + AC coverage",
      "description": "REQ-H-100 and REQ-H-101 mandate v9.0.0 ships the .md overlay hard-removal AND deprecated-name hard-error behaviors, BUT REQ-H-102 then says implementation detail is 'OUT OF SCOPE for sub-projekt H's spec'. AC coverage map shows REQ-H-100..H-102 → AC-H-072 only (migration guide enumeration). There is NO AC asserting these behaviors actually fire in v9.0.0 — i.e., no test that confirms a `customization/{agent}.md` file in v9 IS rejected with [ERROR]. If the pre-existing pre-announced spec doesn't ship in this run, the v9.0.0 release accidentally drops the hard-removal. Spec should at minimum reference the OTHER spec(s) that own these AC, OR add a binary 'present/absent' AC for v9.0.0 (e.g., 'a TOML overlay test fixture exists demonstrating the [ERROR] behavior').",
      "recommendation": "Add AC-H-104: 'No [WARN] string remains in the override-injector or skill files for `.md` overlays or deprecated agent names — they emit [ERROR]. Verify: `grep -E \"\\[WARN\\].*\\.md overlay\\\" core/ skills/` returns empty AND `grep -E \"\\[WARN\\].*(triage-analyst|code-analyst|e2e-test-engineer|reproducer|browser-verifier)\\\" core/ skills/` returns empty.' This converts REQ-H-100/H-101 into machine-checkable form even though their full implementation is owned by another spec doc."
    }
  ]
}
```

---

## Tier 1 Hard Gates

| Gate | Verdict | Evidence |
|------|---------|----------|
| **G1** All 10 items in `phase_4_spec_mandate` addressed | PASS | Mandate items 0-9 each map to ≥1 REQ + ≥1 AC. Spec's traceability map (requirements.md §5) and AC coverage map (formal-criteria.md end) explicitly cite each gate-decision item. Verified spot-checks: items[0,1] → REQ-H-001..009; item[3] → REQ-H-010..015; item[4] → REQ-H-030..033; item[5] → REQ-H-050,060; item[6] → REQ-H-070..074; item[7] → REQ-H-040; item[8] → REQ-H-080..083 + REQ-H-035; item[9] → REQ-H-090..092. (Note: prompt said "11 items"; JSON has 10. Substantively complete either way.) |
| **G2** All 18 v8 agents enumerated in design.md §2 with concrete I/O tables | PASS | design.md §2.1..§2.18 enumerates each agent. stack-selector (§2.17) explicitly marked DELETED with rationale-only entry — all 18 names accounted for. Spot-checks: §2.7 fixer matches agents/fixer.md:73-82 (Fix Report fields exactly); §2.9 publisher matches agents/publisher.md:81-93 (mode-dependent Tracker rows); §2.11 rollback-agent matches agents/rollback-agent.md:24-28 (terminal sentinel literals). Tables are concrete, not placeholders. |
| **G3** Polymorphism for analyst / test-engineer / browser-agent / spec-reviewer correctly captured | PASS | analyst (§2.2): triage + impact phases — matches agents/analyst.md:32 + :130. test-engineer (§2.18): default + --e2e — matches agents/test-engineer.md:18-26 Mode Flag section. browser-agent (§2.5): reproduce + verify — matches agents/browser-agent.md:19-25 Phase Dispatch. spec-reviewer (§2.14): default review + --verify — matches agents/spec-reviewer.md:75 Verify Mode. All 4 polymorphic agents named correctly with both phase shapes. REQ-H-011..H-014 + AC-H-010..H-014 enforce. |
| **G4** EARS notation throughout requirements.md | PASS | Every REQ has an EARS marker `(Ubiquitous)` / `(Event-driven)` / `(State-driven)` / `(Optional feature)`. Spot-check: REQ-H-001 "(Ubiquitous): The system SHALL define..."; REQ-H-031 "(Event-driven): WHEN the harness invokes..."; REQ-H-009 "(Optional feature): IF an agent's Outputs table declares..."; REQ-H-010 "(State-driven): WHILE an agent file declares phase polymorphism...". 100% conformant. |
| **G5** Backward-compat REQ exists and is concrete | PASS | REQ-H-020 (no change to core/agent-override-injector.md), REQ-H-021 (verbatim append behavior), REQ-H-022 (reserved heading), REQ-H-023 (collision tolerated). NFR-COMPAT-001/002 add the "v8 scenarios continue to PASS" + "examples/customization inject correctly" guarantees. AC-H-020 (zero-byte git diff) + AC-H-021 + AC-H-110 (manual diff protocol) + AC-H-111 (v8 scenarios still pass). Specific files, specific behavior, machine-checkable. |
| **G6** stack-selector resolution unambiguous | PASS | design.md §4 declares "delete `agents/stack-selector.md` AND clean up `skills/scaffold/SKILL.md:91`". REQ-H-080..H-083 specify exactly which files change. AC-H-040..H-044 enforce: file deleted, no remaining references in skills, no references in rollback-agent skip list, CLAUDE.md enumeration shows 17. Justification cites zero actual dispatches (verified: my own grep on `subagent_type='ceos-agents:stack-selector'` returns 0 matches across `skills/`). |
| **G7** CLAUDE.md amendment text verbatim | PASS | design.md §6.1 quotes the EXACT new MAJOR row text. §6.2 quotes the EXACT new 4th invariant. REQ-H-050, REQ-H-051, REQ-H-060 inline the same verbatim text. AC-H-060..H-064 grep for literal phrases (`mandatory new structured contract section`, `Adding new static declaration sections`, `Agent Output Contract ↔ skill xref consistency`). No placeholder text — all paste-ready. |
| **G8** All 6 lint scenarios spec'd with assertion logic | PASS | design.md §3.1 (shape) — 5 numbered assertion steps; §3.2 (completeness) — 3 steps + no SKIP-guard; §3.3 (position) — 2 steps; §3.4 (polymorphic split) — 2 steps + per-agent expected H3 list; §3.5 (xref) — 4 steps + intentional-exclusion clause; §3.6 (must-be-dispatched) — 3 steps. Each scenario has SKIP-guard policy explicitly stated. REQ-H-031..H-035 reinforce. |
| **G9** AC machine-checkable | PASS | AC-H-001..H-010 spot-checked: each has a Pass condition that is a literal bash command with specific files and exit codes. E.g., AC-H-001 `for f in $R/agents/*.md; do grep -qE '^## Output Contract$' "$f" || echo "MISS: $f"; done` produces zero MISS lines. AC-H-002 has explicit `process_line < oc_line < cons_line` arithmetic. AC-H-040 is `test ! -f $R/agents/stack-selector.md`. AC-H-100/H-101 use `python3 -c 'import json...'`. No "verify correctness" hand-waves. |
| **G10** MAJOR classification + Versioning Policy citation traceable | PASS | REQ-H-040 declares 9.0.0 + cites peer-deep-dive.md:194. design.md §6.1 inserts new MAJOR-row clause that explicitly includes the v9.0.0 case. REQ-H-050..H-051 insert verbatim policy text. AC-H-100..H-103 enforce on `.claude-plugin/*.json` + CHANGELOG + git tag. The Versioning Policy citation is verbatim (not paraphrased) — the policy text in design.md §6.1 mirrors CLAUDE.md:243 with the new clause appended. |

**Tier 1 result: 10/10 PASS.**

---

## Tier 3 Quality Aggregate

| Criterion | Score | Reasoning |
|-----------|-------|-----------|
| Correctness | 4 | Per-agent contracts faithfully reflect actual agent files. Two minor count/wording errors (4 vs 7 prose dispatches; placeholder-heading xref handling). No structural correctness issues. |
| Completeness | 4 | All 18 agents covered, all 10 mandate items mapped, NFRs present, migration guide spec'd. One gap: REQ-H-100/H-101 (pre-announced changes) lack a hard AC asserting the runtime behavior actually fires in v9.0.0. |
| Security | 4 | No new attack surface. Override injector untouched (REQ-H-020). Heading-collision risk explicitly handled (REQ-H-023, AC-H-073). Reserved heading rule (REQ-H-022) prevents downstream override files from breaking the contract. |
| Maintainability | 4 | Spec is well-organized: requirements.md (EARS), design.md (concrete), formal-criteria.md (machine-checkable). Decomposition into Tiers A-E is implementable. Per-agent §2.x sections are easy to find. Section-anchor brittleness in position lint (browser-agent quirk) is one minor gotcha. |
| Robustness | 3 | Edge cases mostly handled: SKIP-guards in transition window, `## Output Contract` excluded from xref, NEEDS_* sentinels excluded. Two robustness gaps: (a) parameterized headings `## Sprint Plan: {sprint_name}` not handled in xref scenario; (b) AC-H-110 manual-diff protocol uses fragile negative-filter regex. Neither is a blocker. |

**Weighted aggregate:** 0.30·4 + 0.25·4 + 0.20·4 + 0.15·4 + 0.10·3 = 1.20 + 1.00 + 0.80 + 0.60 + 0.30 = **3.90**.

Pass: weighted >= 3.5 AND no criterion below minimum (correctness 3, completeness 3, security 3, maintainability 2, robustness 2). **PASS.**

---

## Devil's-Advocate Findings

### DA-1: Is dispatch-idiom harmonization scope creep?

**Claim:** The spec recommends harmonizing 6+ skill files to the strict `Task(subagent_type=...)` idiom. Sub-projekt H is "agent I/O contracts" — does this violate scope?

**Verdict: NOT scope creep.** Justification:
- Gate-decision item[9] EXPLICITLY mandates the spec address dual-idiom finding (text: *"Spec should either harmonize all 18 to strict idiom OR document that prose idiom is acceptable"*). The mandate makes a decision binding regardless of which way.
- The spec chose harmonization (REQ-H-090) and provided a clear rationale (PostToolUse hook validation surface, cognitive load).
- AC-H-052 enforces that harmonization touches ONLY `skills/**/*.md` — agents are untouched, so the I/O contract work and dispatch-idiom work are cleanly separable for Phase 7 task assignment.

### DA-2: Spot-check 2 agents' input/output contracts vs actual files

**Spot-check #1 — fixer (§2.7):**
- Spec declares: `## Fix Report` (Objective; Approach; Files changed; Build; Tests). Actual fixer.md:73-82 = exact match.
- Spec declares: `## NEEDS_DECOMPOSITION` (Reason; Estimated scope; Suggested split; Work done so far). Actual fixer.md:48-55 = exact match.
- Spec declares: `## NEEDS_CLARIFICATION` (Question ≤280; Context ≤500). Actual fixer.md:58-66 = exact match including character limits.
- Inputs: pipeline-history.md last 5 entries (declared "no" required) — matches fixer.md:20-27 exactly.
- **Verified: contract is faithfully sourced, not invented.**

**Spot-check #2 — publisher (§2.9):**
- Spec declares 3 modes (full-publish / pr-only-404 / pr-only-no-id). Actual publisher.md:74-93 = exact match.
- Spec declares Tracker row variants per mode. Actual publisher.md:90-93 = exact match.
- **Verified: contract is faithfully sourced.**

### DA-3: Interaction between I/O contracts + .md overlay removal + deprecated-name hard errors

**Claim:** v9.0.0 bundles three breaking changes. Does the spec correctly handle ordering?

**Analysis:**
- I/O contract additions (REQ-H-001..H-009) operate on agent BODY content. They commute with .md-overlay-removal (REQ-H-100) which operates on the override-DISPATCH path (i.e., when a `customization/{agent}.md` is detected, [ERROR] instead of [WARN]).
- Deprecated agent name hard errors (REQ-H-101) operate on dispatch-time NAME RESOLUTION — orthogonal to body content of the (still v8-named) agents.
- All three are agent/skill-file edits, not runtime DB migrations — there's no temporal ordering risk.
- REQ-H-102 explicitly defers REQ-H-100/H-101 implementation detail to other specs. This is the right call for scope, but it means the v9.0.0 release commit could ACCIDENTALLY ship without those behaviors if those other specs aren't merged. **See finding f-602b8e.**

### DA-4: Mandatory-but-lint-only enforcement model

**Claim:** What happens at runtime if an agent's actual output doesn't match its declared Output Contract?

**Verdict: spec correctly says: nothing.** Evidence:
- REQ-H-001 scope: "no runtime schema validation, no JSON Schema sidecar, no LLM self-validation" (verbatim from requirements.md §1).
- design.md §1.1 the Output Contract is "validation is author-time lint only via `tests/scenarios/v9-output-contract-*.sh`".
- No REQ in the spec mandates runtime validation. No AC asserts runtime behavior. Skills already grep-then-block on missing sections (e.g., reviewer expects `## Fix Report`); that path is unchanged.
- **Confirmed: spec is internally consistent on the deferred-runtime-validation stance.**

### DA-5: Are the 4 polymorphic agents correctly identified?

**Verified by reading source agent files:**
- analyst.md:26-32 has `## Phase Dispatch` + `## Process — Phase: triage` + `## Process — Phase: impact`. ✅
- test-engineer.md:18-26 has `## Mode Flag` with Default vs `--e2e`. ✅ (note: spec calls this `## Output Contract — Default (no flag)` + `## Output Contract — Phase: --e2e` which is consistent with the source's "default vs --e2e" framing)
- browser-agent.md:19-25 has `## Phase Dispatch` + `## Process: Phase reproduce` + `## Process: Phase verify`. ✅ (note: source uses `Process: Phase X` syntax, NOT `Process — Phase: X` like analyst — see f-d2e44f for position-anchor implication)
- spec-reviewer.md:75-79 has `## Verify Mode (--verify)` separate from main process. ✅

**All 4 correctly identified.** Spec's chosen sub-block heading conventions (`## Output Contract — Phase: X`, `## Output Contract — Default (...)`) are consistent across the 4 agents and machine-checkable per AC-H-010..H-013.

---

## Verdict: **PASS**

The spec satisfies all 10 Tier-1 hard gates. Tier 3 weighted aggregate = 3.90 (≥ 3.5 threshold), no criterion below its minimum. Per-agent contract enumeration was spot-checked against 5 actual agent files (fixer, analyst, test-engineer, publisher, rollback-agent + spot-check on browser-agent, spec-reviewer, reviewer, spec-writer) and found faithful — contracts are sourced, not invented. Polymorphism is correctly captured for all 4 polymorphic agents. Backward-compat is concrete (REQ-H-020..H-023 + AC-H-020/H-021/H-110/H-111). MAJOR classification is traceable to a verbatim Versioning Policy amendment.

**Findings catalog (7 MINOR):** all are tightenings, not blockers. Any one of them could be merged into Phase 5 TDD or Phase 6 plan as a clarification rather than a Phase 4 revision. The most operationally important (placeholder-heading handling in the xref scenario, position-anchor disambiguation for polymorphic agents) is recoverable at Phase 5 test-authoring time without re-spec.

**Confidence: 0.78.** Lower than a perfect score because: (a) I did not exhaustively cross-check all 18 §2 agent contracts line-by-line against their source files (sampled 5 + spot-checked 4); (b) AC-H-110 manual-diff protocol is hard to validate without actually running it; (c) the prose-dispatch count discrepancy (4 vs 7) suggests Phase 3 inventory may have other small undercounts.

**If revision were elected, top 3 fixes (in priority order):**
1. **f-602b8e** — add AC-H-104 covering REQ-H-100/H-101 hard-error verification, OR explicitly cite the other spec doc that owns it.
2. **f-1f9b7a** — clarify placeholder-heading handling in v9-xref-outputs-skill-references.sh (`{...}` token policy).
3. **f-9b8e10** — fix the "4 prose-idiom dispatches" count to "7 across 6 files" + ensure design.md §5 table includes the `Dispatch` variant at check-deploy:66.

None of these blocks Phase 5 from starting. The spec proceeds to **Gate 2 (user approval)**.
