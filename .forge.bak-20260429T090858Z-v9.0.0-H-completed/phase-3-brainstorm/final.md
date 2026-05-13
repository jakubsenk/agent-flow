# Phase 3 Synthesis — Judge Verdict for v9.0.0 sub-projekt H

**Judged:** 2026-04-28
**Scope:** Whether and how to formalize I/O contracts across 18 ceos-agents agent definitions; what version this ships under.

---

## Comparative Table

| Dimension | Conservative (A) | Innovative (B) | Skeptical (C) |
|-----------|------------------|----------------|---------------|
| **WHETHER** | NO new sections — fix three stale scenarios + document de-facto contract in `docs/reference/agents.md` | YES — full formalization, `## Inputs` + `## Outputs` on all 18 agents, mandatory | PARTIAL — `## Outputs` only (no `## Inputs`) on 4 high-traffic agents (fixer, reviewer, analyst, test-engineer), optional |
| **Schema language** | Typed prose list in docs (no in-file schema) | Typed markdown table (5 cols: Field/Type/Required/Mode/Description) + generated JSON Schema 2020-12 sidecar at `agents/contracts/{name}.schema.json` | Typed markdown table (3 cols: Section/When/Required), no JSON Schema |
| **Location** | None in agents; `docs/reference/agents.md` only | Dedicated `## Inputs` + `## Outputs` between `## Expertise` and `## Process`; per-mode split for polymorphic agents; sidecar registry generated | Dedicated `## Outputs` between `## Process` and `## Constraints`; no frontmatter, no sidecar |
| **Validation** | Static lint only — fix 3 stale + add `agents-canonical-output-headings.sh` (4 scenarios total) | 5 new scenarios: shape, completeness, output-name xref, polymorphic split, registry-generated drift detector + section-order update | 4-5 new scenarios with section-level `exit 77` SKIP-guard: shape, xref-skill-references, position, customization-collision; refuses LLM self-validation explicitly |
| **BC strategy** | Zero agent file changes; injector untouched; trivially BC | Additive mandatory across 18 agents in one PR sequence; injector untouched (append-only, structure-blind per Q6); no override file changes | Additive optional, SKIP-guarded; injector untouched; explicit guard against `## Project-Specific Instructions` rename |
| **Versioning** | PATCH (v8.0.1 polish queue); reserves v9.0.0 for `.md` overlay hard-removal + deprecated agent name hard-errors (already pre-announced) | MAJOR (v9.0.0 as MEMORY allocates) — mandatory enforcement = MAJOR per amended Versioning Policy + Hyrum's Law against v10 | MINOR (v8.1.0); reserves v9.0.0 for the same pre-announced breaking changes A cites |
| **Test strategy** | 4 scenarios, all in existing harness pattern; reuses canonical-headings xref idiom; ~40 lines bash each | 5 new scenarios + `section-order.sh` update; transition SKIPs deleted in v9.1.0; sidecar drift detector runs `extract-contracts.sh` | 4 new scenarios with `exit 77` section-level SKIPs; xref scenario is the operational ROI center; refuses sidecar drift detection as scope creep |

---

## Convergence Analysis

**Agreement (load-bearing):**

1. **All three personas agree the override injector is safe.** C4/Q6 settles BC mechanically — append-only, structure-blind, `## Inputs`/`## Outputs` are unused heading names in current override examples. No persona disputes this.
2. **All three agree the three pre-v8 stale scenarios (`frontmatter-completeness.sh`, `section-order.sh`, `read-only-agents.sh`) must be fixed regardless of the I/O contract decision.** This is cleanup debt independent of OQ1.
3. **All three agree LLM runtime self-validation is not a real validation mechanism.** C1/Q2 settles this — Task tool returns raw LLM output verbatim. A doesn't propose it; B uses lint xref, not LLM enforcement; C explicitly refuses.
4. **All three agree the typed markdown table is the contract format if any sections are added** (constraint C2/Q10). B and C both use it; A doesn't add sections at all so the question is moot.
5. **All three agree v9.0.0's pre-announced breaking changes (`.md` overlay removal, deprecated agent name hard errors) ship regardless.** A and C explicitly reserve v9.0.0 for those; B bundles I/O contracts on top.

**Disagreement (load-bearing):**

- **D1 (the WHETHER question):** A says NO, B says YES-all-18, C says PARTIAL-4-agents. This is the core fork.
- **D2 (Versioning):** A=PATCH, B=MAJOR, C=MINOR. Maps directly to D1.
- **D3 (Coverage breadth):** B wants all 18 agents covered to give v10 Node.js Runtime a stable contract surface; C wants only the 4 agents whose output headings skills already grep; A wants zero new agent-file coverage and lint-only of de-facto headings.
- **D4 (`## Inputs` inclusion):** B mandates it; C explicitly refuses it as duplicative of `## Process — Phase: X`; A doesn't add either section.
- **D5 (sidecar JSON Schema artifact):** B yes (for v10 ingestion); A and C no.
- **D6 (Mandatory vs optional):** B mandatory for the version-correctness argument; A and C optional/none for the YAGNI argument.

**Phase 2 evidence resolution:**

- **D1 / D6 resolved by Q1 + Q3 + Q5 + Q8.** Q1 documents zero observable failures attributable to output-shape drift across three forge cycles. Q3 establishes industry default is **optional + same-file co-location** (MCP `outputSchema`, CrewAI `output_pydantic`, smolagents `structured_output=False`). Q5 confirms **declaration-mandatory + runtime-advisory** is the production consensus. Q8 explicitly lists the policy gap and notes that calling optional contracts MAJOR is a semver lie. Together: the evidence does not support B's all-18-mandatory framing. It also does not support A's zero-formalization stance, because Q1 acknowledges harness-coverage masking. The evidence supports a targeted optional addition — i.e., closer to C than to either extreme, but with B's coverage breadth concern partially honored.
- **D3 resolved by Q11 + the codebase grep evidence.** Q11 + skill source review shows skills currently grep these output section names by exact heading: `## Fix Report` (fixer), `## Code Review` (reviewer), `## Triage Analysis` / `## Impact Report` (analyst per phase), `## Test Report` (test-engineer), `## NEEDS_CLARIFICATION` (multiple), `## NEEDS_DECOMPOSITION` (fixer). This is C's "4 high-traffic agents" set plus the cross-cutting NEEDS_* signals, NOT all 18. Publisher, rollback-agent, scaffolder, etc. have skill-side parsing that treats their output as opaque prose — a contract there would be self-attesting metadata (A's pet peeve).
- **D4 resolved by Q4.** The polymorphism surface is in Process steps that already say "Read the {kind of input}" and the dispatching skill already passes that input. `## Inputs` would be a second source of truth for information that already lives in the dispatch step. C's refusal is technically correct given Q4's finding.
- **D5 resolved by Q2 + Q3.** Q2 confirms no parser exists in the plugin runtime. Q3 notes MCP/CrewAI co-locate I/O schemas in the same file with no sidecar. The v10 Node.js Runtime is in a separate repo and (per MEMORY) "scope delegated to forge phase 1 research" — generating a JSON Schema sidecar today commits to a contract surface for a consumer that hasn't designed itself yet. B's strongest argument (Hyrum's Law for v10) is real but premature: lock-in happens when v10 ships, not when v9.0.0 ships, and Q3 shows the industry pattern is to add the schema in the consumer's release MINOR (the way MCP added `outputSchema` in 2025-06-18), not preemptively.
- **D2 resolved by Q8 + the resolution in D1/D6.** Once D6 lands on optional, MINOR is mandatory per the Versioning Policy strict reading. v9.0.0 stays allocated to the pre-announced breaking changes (the path A and C both endorse).

---

## Recommended Synthesis

### WHETHER verdict: PARTIAL (closer to C than to A or B)

YES, formalize — but narrowly, optionally, and with operational ROI as the gate. Q1's zero-failures finding rules out B's all-18-mandatory framing as "premature formalization that locks in the wrong abstraction" (A's pet peeve, well-supported here). But A's zero-action stance ignores the legitimate coverage gap — three forge cycles produced no output-shape failures partly because the harness has no mechanism to detect them, and Q11 shows skills already grep specific output section headings as load-bearing strings. The right move is C's targeted scope (the 4 agents whose output headings skills actually grep) with a slightly broader xref discipline that catches drift on cross-cutting signals (`## NEEDS_CLARIFICATION`, `## NEEDS_DECOMPOSITION`). Optional, lint-only, MINOR — and v9.0.0 is left intact for the pre-announced breaking changes (`.md` overlay hard removal + deprecated agent name hard errors), where it semantically belongs.

### HOW design

- **Schema language:** Typed markdown table (no JSON Schema, no sidecar). Three columns: `| Section | When emitted | Required fields |` with the section name backtick-quoted in the first column (e.g., `` `## Fix Report` ``). Format constraint per C2/Q10 (grep-extractable via `grep -oE '\`## [A-Za-z ]+\`'`).
- **Contract location:** Dedicated `## Outputs` section in agent body, positioned **between `## Process` and `## Constraints`** (per persona C, matching natural reading flow: behavior → outputs → invariants). Per-mode split for analyst (`## Outputs — Phase: triage`, `## Outputs — Phase: impact`) mirroring the existing `## Process — Phase: X` convention (C3/Q4). **No `## Inputs` section** — Q4 + persona C's argument: the input contract already lives in Process steps and dispatch wiring; a duplicate declaration creates a second source of truth.
- **Validation mechanism:** Static lint via `tests/scenarios/` only. No LLM self-validation. No dispatcher runtime check (Q2 makes this infeasible without a new wrapper). Five scenarios:
  1. `v9-outputs-section-shape.sh` — for each agent file, if `## Outputs` exists assert table column header matches `Section | When emitted | Required fields` and at least one row backtick-quotes a `## Heading`. SKIP via `exit 77` if section absent.
  2. `v9-xref-outputs-skill-references.sh` — extract every backtick-quoted `## Heading` from any agent's `## Outputs`; assert each appears in at least one `skills/**/SKILL.md`. This is the operational-ROI center: catches the drift class C identified (heading rename without consumer update). No SKIP — if zero declarations exist, scenario reports "0 declarations, 0 references checked, PASS".
  3. `v9-outputs-section-position.sh` — if `## Outputs` exists, assert it sits between `## Process` and `## Constraints`. SKIP-guard if absent.
  4. `v9-outputs-polymorphic-split.sh` — for analyst (and any future agent declaring per-phase Process), assert `## Outputs — Phase: X` exists for each `## Phase Dispatch` mode. SKIP-guard if `## Outputs` absent.
  5. `v9-customization-heading-collision.sh` — assert no file under `examples/customization/` or `examples/agent-overrides/` contains `## Outputs` or `## Project-Specific Instructions` literals (collision guard per Q6).
  Plus update `section-order.sh` to tolerate the optional `## Outputs` insertion point between Process and Constraints; plus fix the three stale 21-agent enumerations (independent debt, do it in same PR per A and C's agreement).
- **Backward-compat strategy:** Additive optional, SKIP-guarded at section level (C9/Q10). Customization/ overrides are unaffected (C4/Q6 — append-only, structure-blind). v8.0.0 agent files remain valid (their tests SKIP for absent `## Outputs`); migration for consuming projects is zero-touch (Q7). Initial rollout populates `## Outputs` on the **5 agents whose headings skills grep**: fixer (`## Fix Report`, `## NEEDS_DECOMPOSITION`), reviewer (`## Code Review`), analyst (`## Triage Analysis`, `## Impact Report` per phase), test-engineer (`## Test Report`), and one cross-cutting addition the personas didn't all converge on: any agent that may emit `## NEEDS_CLARIFICATION` (per the v6.9.0 cross-cutting feedback loop) declares it. Other 13 agents are ungated — they may add `## Outputs` in future minors when skill-side parsing surface justifies it.
- **Versioning verdict:** **MINOR — v8.1.0.** Per Q8 strict reading: optional declaration sections do not fire MAJOR (no external tooling parses them today; override injector is structure-blind). MEMORY's "v9.0.0 = sub-projekt H" allocation is **reframed**: v9.0.0 stays reserved for the pre-announced breaking changes (`.md` overlay hard removal, deprecated agent name hard errors per Q7). I/O contracts ship as v8.1.0 alongside the queued v8.0.1 polish items if scope allows, or as a separate v8.1.0 release. **Versioning Policy amendment is required** in the same PR (per Q8) — add the resolution recommendation text to CLAUDE.md classifying static declaration sections as MINOR when optional/unenforced.
- **Test strategy:** Five scenarios above + the three stale-scenario fixes + section-order.sh update + Versioning Policy amendment + Cross-File Invariants amendment (add invariant: "every backtick-quoted `## Heading` in any agent's `## Outputs` table must be referenced by at least one `skills/**/SKILL.md`"). All scenarios follow the existing bash harness pattern (`tests/scenarios/*.sh`, `exit 0/77`/fail).

### Trade-offs accepted

- **Gain:** Operational ROI from day one — `v9-xref-outputs-skill-references.sh` catches the only drift class with documented business value (heading rename desyncs from skill-side grep). Coverage gap from Q1 partially closed (5 high-traffic agents have grep-checkable output contracts; the 13 low-traffic agents remain "uncontracted" but were never the failure surface). Industry-standard posture (optional + co-located + advisory, matching MCP/CrewAI/smolagents per Q3+Q5). v9.0.0 stays semantically clean for its pre-announced breaking changes — no semver lie, no "what does v9.0.0 actually break" ambiguity. Override injector is mechanically untouched; v8.0.0 customization/ files keep working byte-for-byte.
- **Give up:** B's v10 Node.js Runtime ingestion story — a future v10 consumer cannot rely on machine-validated JSON Schema sidecars from this release. Mitigation: when v10's contract surface is designed in its own forge phase 1 (per MEMORY), it can promote `## Outputs` from advisory to mandatory in v10's MAJOR bump and generate sidecars then (the MCP 2025-06-18 pattern). 13 of 18 agents have no `## Outputs` declaration in v8.1.0 — drift in publisher/scaffolder/rollback-agent output headings is undetected by the harness. Mitigation: skill-side parsing surface for those agents is minimal today; if a future skill starts grepping their headings, that PR adds a `## Outputs` section as part of the same change. We accept B's "Hyrum's Law later" objection — but Q3's industry evidence shows "later" is the standard answer, not premature commitment.

### Phase 4 Spec mandate

Phase 4 must operationalize **the 5-scenario lint package + 5-agent initial `## Outputs` rollout + Versioning Policy amendment + Cross-File Invariants amendment** as v8.1.0. The spec must encode: (a) the table contract format with the three columns and the backtick-quoted heading convention; (b) the per-mode split rule for polymorphic agents (analyst); (c) the SKIP-guard pattern at section level for v8.0.0 → v8.1.0 forward-compat; (d) the explicit policy that v9.0.0's MEMORY allocation is reframed onto the pre-announced `.md` overlay hard removal + deprecated agent name hard errors, and that I/O contracts ship as v8.1.0 MINOR.

---

## Final Summary (under 100 words)

Recommend PARTIAL formalization at MINOR (v8.1.0): add an optional `## Outputs` markdown table to the 5 agents whose output headings skills already grep (fixer, reviewer, analyst, test-engineer, and any agent emitting `## NEEDS_CLARIFICATION`/`## NEEDS_DECOMPOSITION`), validated by 5 lint scenarios with section-level `exit 77` SKIP-guards. No `## Inputs` (duplicates Process). No JSON Schema sidecar (premature for v10). Override injector untouched. Versioning Policy amended same PR. v9.0.0 stays allocated to pre-announced breaking changes (`.md` overlay removal, deprecated agent names). Closer to persona C than A or B; B's Hyrum's-Law-for-v10 is real but answerable later, the way MCP did with `outputSchema`.
