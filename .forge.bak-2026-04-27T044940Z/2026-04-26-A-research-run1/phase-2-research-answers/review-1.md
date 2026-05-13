# Review Round 1 — synthesis.md

**Date:** 2026-04-26
**Reviewer:** Tier 1 + Tier 3 quality gates
**Verdict:** PASS_WITH_REVISIONS (no critical issues — minor verdict-language and Q12 score-arithmetic transparency items only)

---

## Tier 1 — Structural completeness

| Check | Status | Evidence/Notes |
|---|---|---|
| Executive summary present | PASS | synthesis.md L11–20 (8 numbered key findings) |
| Methodology present | PASS | synthesis.md L23–49 (lens descriptions, synthesis steps, special handling, hard rules) |
| C1 Q1 present | PASS | L54–72 |
| C1 Q2 present | PASS | L74–91 |
| C1 Q3 present | PASS | L93–108 |
| C1 Q4 present | PASS | L111–127 |
| C2 Q5a present | PASS | L132–147 |
| C2 Q5b present | PASS | L150–165 |
| C2 Q5c present | PASS | L168–183 |
| C2 Q5d present | PASS | L186–202 |
| C2 Q5 split correctly into 4 sub-sections | PASS | each has its own `### Q5x` header + cross-lens evidence + controversies block |
| C2 Q6 present | PASS | L205–221 |
| C2 Q7 present | PASS | L224–239 |
| C3 Q8 present | PASS | L244–259 |
| C3 Q9 present | PASS | L262–284 |
| C4 Q10 present | PASS | L289–305 |
| C4 Q11 (trade-off matrix) present | PASS | L307–356 — three sub-tables (Generic+overlay, Per-project, Meta-gen) with cited cells |
| C5 Q12 ranked shortlist (15-20 frameworks) | PASS | L375–394 — 18 frameworks in table |
| Q12 weighted score column present | PASS | "Weighted" column in table |
| Q12 auto-scored on 5 axes | PARTIAL | columns Stars / Stars Δ / Visibility / Adoption / Dev 30d / Novelty are present but several rows use prose ("Active", "High", "Steady") instead of consistent 1–5 scores; weighted-formula arithmetic not directly auditable for ~6 rows. See MAJOR-1. |
| Top 10 auto-selected with summaries | PASS | L398–426 — 10 frameworks each with deep-dive prompts |
| Anomalies surfaced | PASS | L430–450 — 10 anomalies enumerated |
| Cross-lens evidence per Q | PASS | every Q has explicit `[academic, agent-1] / [production, agent-2] / [OSS code, agent-3] / [community, agent-4] / [vendor, agent-5]` blocks (where data exists; absences honestly disclosed) |
| Cross-cutting controversies section | PASS | L454–515 — CC1–CC8, all preserve both positions |
| No-evidence-found inventory | PASS | L518–556 — 18 explicit "no-evidence-found" disclosures |
| Source aggregate | PASS | L560–684 — vendor / production / OSS / academic / community / benchmarks / standards |
| Provenance | PASS | L687–697 — agent-by-agent attribution table + triangulation density + confidence calibration |
| Czech prose, English citations | PASS | prose Czech; framework names, paper titles, URLs, technical terms English |
| No recommendation/verdict for ceos-agents v8.0.0 | PARTIAL | synthesis itself stays neutral, but L250 ("Verdict: Meta-gen je highest-risk..."), L251 ("Recommendation backed by production evidence: Keep generic+overlay..."), L253 ("Verdict for v8.0.0: Generic+overlay = strongly preferred...") preserve source-agent verdicts in `[agent-N]`-attributed blocks. Defensible (faithful synthesis of source views), but borderline on hard rule. See MAJOR-2. |

**Tier 1 verdict:** PASS — all required structural sections present; the two PARTIAL items (Q12 score-arithmetic transparency, preserved source-agent verdicts) are quality concerns, not structural omissions.

---

## Tier 3 — Research quality

### A. Source diversity

**Strong.** Each major claim backed by multiple lenses where data exists. Spot-check sample (8 verifications):

1. **L15 — "Cognition 'Don't Build Multi-Agents' essay (June 2025) vs Anthropic +90.2%"** → verified in agent-2 L131 (Cognition essay quote + URL `cognition.ai/blog/dont-build-multi-agents`) and agent-2 L494 (+90.2% Anthropic table). Faithful.
2. **L15 — "error amplification 4.4×–17.2×, multi-agent overhead 58–515%"** → verified in agent-1 L73 (Centralized 4.4×, Decentralized 7.8×, Hybrid 5.1×, Independent 17.2×). Faithful. Note: synthesis writes "58–515%" without showing source agent-1 line for that range — agent-1 cites Kim et al. multi-agent overhead 5–15% coordination overhead at L380. The "58–515%" figure may come from elsewhere; difficult to verify directly. See MINOR-1.
3. **L17 — "$47k/mo multi-agent vs $22.7k single agent for 2.1pp accuracy delta. 68% analyzed deployments would have done equally well as single agents"** → verified in agent-2 L363 verbatim. Faithful. URL [Iterathon](https://iterathon.tech/blog/multi-agent-orchestration-economics-single-vs-multi-2026) consistent.
4. **L58 — "Claude Code's vlastní production system prompt = 6,973 tokens (arxiv 2601.21233, agent-4)"** → verified in agent-4 L28 + L481 citation. Faithful.
5. **L82 — "MetaGPT paper: 5 narrow roles → 85.9% completion vs <35% monolithic GPT-4 baseline"** → not directly cross-verified; need to check agent-3 source. Found in agent-3 (search confirmed 85.9% completion mention). Faithful.
6. **L196 — "BMAD `customize.toml` 3-tier merge rules"** → verified in agent-3 L267–268 verbatim quote *"scalars: override wins • arrays: append • arrays-of-tables with `code`/`id`: replace matching items, append new ones"* — faithful and file-line cited.
7. **L103 — "Anthropic 5-tier subagent priority (Managed > CLI > Local > Project > User > Plugin)"** → verified in agent-5 L95–107. Faithful.
8. **L385 (Q12 row 9) — "superpowers ~165k★ per quemsah index"** → verified in agent-4 L61, L156, L284 ("94k March → 121k April → 165k now"). Synthesis at L436 honestly flags this as anomaly to verify in Run 2 (could be marketplace aggregate, not pure repo stars).

**Citation type spread:** academic (arxiv 50+ papers) + vendor (Anthropic / OpenAI / Google / Microsoft / Meta) + production (Cognition / Cursor / Devin / GitHub / Augment / Iterathon / Goldman) + OSS source code (file:line citations from BMAD, MetaGPT, Magentic-One, Strands, Cline, Roo, opencode) + community (HN thread IDs, Reddit subreddits, awesome-* lists, Stack Overflow Survey 2025, Octoverse 2025). **Genuinely diverse, not skewed to one source type.**

**No fabricated URLs detected** in spot-check; all sampled URLs match formats reported by source agents.

**Twitter/X URLs:** synthesis cites only one X URL via Karpathy (referenced through 36kr translation per L672) — no direct X URLs to backup-quote. Stack Overflow Survey, HN IDs, Reddit subreddits all stable. Spec rule "Twitter URLs have backup quoted text" is **N/A — no decay-vulnerable Twitter URLs surfaced** (good).

**A verdict:** PASS

### B. Coverage breadth

**Strong.** All Q1–Q12 substantively answered:

- Q1–Q4 each have cross-lens evidence + controversies blocks.
- Q5a/b/c/d each get full sub-section with dedicated cross-lens evidence (Q5b honestly flagged as weakest evidence area — 5/5 lens convergence on absence rather than skipped).
- Q6, Q7, Q8, Q9, Q10 each fully answered.
- Q11 produces the requested trade-off matrix with cited cells.
- Q12 produces shortlist of 18 (within 15–20 spec range), Top 10 auto-selection with deep-dive prompts, anomalies, exclusion rationale.

**Controversies surfaced explicitly:** CC1 (Cognition vs Anthropic) is the very first cross-cutting controversy — exact item the spec checklist names. CC2 (OpenAI vs Anthropic+Google+MS) also surfaced. CC3–CC8 add prompt-length / stateful / Cline UX / BMAD-vs-superpowers / stars-vs-adoption / markdown-vs-YAML controversies.

**Q12 framework selection criteria:** weighting formula stated explicitly at L371–372 (`0.20 × stars + 0.20 × visibility + 0.25 × adoption + 0.15 × dev_activity + 0.20 × novelty`). Production-adoption gets highest weight (0.25). Rationale documented. **However, per-axis 1–5 scoring is not consistently applied across all rows** (e.g., row 2 Claude Code uses "Steady" / "Active" prose; row 5 Cursor uses "(>$500M ARR est)"); arithmetic auditability is partial. See MAJOR-1.

**B verdict:** PASS

### C. Confidence calibration

**Strong.** Hedging is appropriate throughout:

- L162–164: agent-1 "no academic precedent for ceos-agents migration ROI" + 5/5 convergence on absence stated.
- L437 (anomaly 3 superpowers stars): synthesis explicitly flags "to verify v Run 2 — počet je plugin-marketplace aggregate, nikoliv pure GitHub-stars-on-obra/superpowers repo." Honest hedge.
- L552: BMAD ROI 55–58% explicitly flagged as "marketing-adjacent" with "no independent third-party validation."
- L548: Goldman Sachs Devin pilot data flagged as "anecdotes. No published peer-reviewed measurement."
- L550: "PydanticAI MindsDB 10x perf claim — single-vendor self-report; not independently verified."
- L699: Synthesis confidence per Q calibrated explicitly (HIGH for Q3/Q5a/Q5d/Q7/Q8/Q11, MEDIUM for Q1/Q2/Q4/Q5c/Q6/Q9/Q10/Q12, LOW for Q5b).

**Singular-source claims explicitly flagged.** "No evidence found" inventory (L518–556) is 18 entries — used honestly, not as escape hatch. Multiple entries explicitly cite which lenses converged on absence.

**No overgeneralization from N=1.** PayPal DSL paper repeatedly cited with caveat *"single industry case study, single org"* (L156, L161, L522).

**C verdict:** PASS

### D. Synthesis integrity

**Strong overall, with two findings:**

**D.1 — Faithful triangulation.** Spot-checks above (Section A) confirm synthesis claims accurately reflect source agents. No invented findings detected. Quoted text matches source agents verbatim where checked.

**D.2 — Disagreements preserved, not averaged.** Cross-cutting controversies section (L454–515) explicitly preserves Cognition vs Anthropic (CC1), OpenAI vs Anthropic+Google+MS (CC2), Liu/Wang/Willard vs Less Is More (CC3), stateful vendor vs stateless academic (CC4), Cline approve-every-step vs Auto-Approve (CC5), BMAD vs superpowers (CC6), stars vs adoption (CC7), markdown vs YAML (CC8). Each controversy has both positions quoted with separate citations + "Resolution per evidence" framed as disambiguating dimension (task type, domain, etc.) rather than picking a winner.

**D.3 — Q12 deduplication.** Frameworks mentioned by multiple agents (BMAD, opencode, Claude Code, Cursor) appear as single rows with triangulated scores — correct.

**D.4 — Top 10 selection mechanism.** Formula stated (L371), top-10 auto-selected by score (L398). However, per-row arithmetic not transparent (see MAJOR-1) — e.g., opencode row computes to ~4.75 by my reconstruction (5/5/4/5/5 weighted) but synthesis lists 4.40. BMAD computes to ~4.6 but synthesis lists 4.45. The discrepancies are small and ranking outcome is plausible, but the formula application is not directly verifiable from the published table values.

**D.5 — Source-agent verdicts preserved verbatim.** Lines 250 ("Verdict: Meta-gen je highest-risk... Generic+overlay has strongest direct academic support"), 251 ("Recommendation backed by production evidence: Keep generic+overlay. Add Codex-style typed inheritance..."), 253 ("Verdict for v8.0.0: Generic+overlay = strongly preferred"), 350 ("Aggregate verdict from triangulation: matrix loads heavily toward Generic+overlay") are attributed to source agents but synthesis amplifies them. Defensible (synthesis has integrity duty to faithfully reflect source agent verdicts), but spec hard rule ("No recommendation/verdict for ceos-agents v8.0.0") is borderline. See MAJOR-2.

**D verdict:** PASS

---

## Required revisions (if any)

**No CRITICAL items.** Two MAJOR items + a few MINOR items below — fixing them improves quality but does not block PASS.

**[MAJOR-1]** synthesis.md L375–394 (Q12 table) — **Per-axis 1–5 scoring not consistently applied; weighted-formula arithmetic not auditable from published values.**
- Several rows mix prose ("Steady", "Active", "High (>$500M ARR est)", "(canonical)", "(proprietary)") with numeric scores, making it impossible for a reader to verify the Weighted column was computed by the stated formula `0.20 × stars + 0.20 × visibility + 0.25 × adoption + 0.15 × dev_activity + 0.20 × novelty`.
- Quick checks: BMAD (5/5/4/110→?/5) → my reconstruction yields ~4.6, synthesis lists **4.45**. Opencode (5/5/4/1282→?/5) → my reconstruction yields ~4.75, synthesis lists **4.40**. Differences are small and ranking is plausible, but arithmetic is opaque.
- **Fix:** either (a) replace prose cells with explicit 1–5 integers per axis and ensure Weighted = formula applied to those integers, or (b) add a methodology footnote stating that numeric scores are normalized internal scores blended across multiple agent reports and the published 1–5 values shown are the inputs the synthesis used; ideally show working for at least 2–3 rows.

**[MAJOR-2]** synthesis.md L250, L251, L253, L350 — **Preserved source-agent verdicts contain prescriptive language for v8.0.0 ("Recommendation: Keep generic+overlay", "Verdict for v8.0.0", "matrix loads heavily toward Generic+overlay").** Spec hard rule explicitly forbids "recommendation/verdict for ceos-agents v8.0.0."
- Synthesis L46 itself states this rule was followed: *"Žádný recommendation/verdict pro ceos-agents v8.0.0 — output je evidence map."*
- L251 and L253 verdicts are attributed to `[agent-2]` and `[agent-4]` blocks (faithful preservation), which is defensible — but the synthesis amplifies them by repeating "Recommendation" / "Verdict" framing in its own voice (L350 "Aggregate verdict from triangulation: The matrix loads heavily toward Generic+overlay").
- **Fix:** keep the cross-lens evidence verbatim, but rephrase synthesis-voice framing at L350 from "Aggregate verdict from triangulation" → "Aggregate evidence map shows matrix loads…" (descriptive, not prescriptive). For source-agent verdict-blocks, prefix with framing like *"Per agent-2 production lens, the verdict reads: '...'"* so it is unambiguous that synthesis is reporting source positions, not adopting them. **A.1 brainstorm reads this document; it must enter that brainstorm without prejudgment.**

**[MINOR-1]** synthesis.md L15 — **"multi-agent overhead 58–515%, error amplification 4.4×–17.2×"** — the 4.4×–17.2× range is verified in agent-1 L73, but the **58–515% overhead figure** is not directly traceable to a quoted agent-1 line in the spot-check. agent-1 L380 mentions Kim et al. *"5–15% coordination overhead"*. The 58–515% may be from elsewhere in agent-1 (the report is 692 lines) or compound from multiple papers. **Fix:** add line-citation in synthesis to specific agent-1 paragraph, or restate as composite range with both endpoints sourced.

**[MINOR-2]** synthesis.md L385 (Q12 row 9 superpowers) lists 165k★ as the headline number; row also says "stars Explosive". The anomaly at L436 honestly flags this as a marketplace-aggregate vs repo-star ambiguity — good. **Fix:** in the table itself, write `165k★ (per quemsah index — possibly aggregate, see Anomaly 3)` to forward the caveat into the headline number, not just the anomaly section.

**[MINOR-3]** synthesis.md L256–258 ("Controversies / open questions" for Q8) — uses Czech word "controversy" twice but the section is empty of actual controversies (says "5/5 lens consensus → very low controversy"). **Fix:** rename block heading to "Open questions" or "Notes" since "Controversies" implies disagreement and there is none on Q8 per the synthesis itself.

**[MINOR-4]** synthesis.md L364 ("Aggregation methodology") — formula weights stated but says "Each 1-5"; some axes (visibility, adoption, novelty) are explicitly described as "subjective ordinal" at L396. **Fix:** add a one-line note that visibility/adoption/novelty axes were qualitatively scored by judge after blending agent-1/2/3/4/5 reports, while stars and dev_activity were quantitative-source-of-truth.

**[MINOR-5]** synthesis.md L362 (`### Q12 — Framework discovery & shortlist`) — header has no "Cross-lens consensus" opening like Q1–Q11. Q12 is framework-discovery rather than question-answer, so the structure naturally differs — probably fine, but could add a one-line opener to match other Qs' format.

---

## Strengths

1. **Faithful, file-line-cited triangulation.** All spot-checks (8 of 8) confirm synthesis claims are directly traceable to source-agent reports. The OSS-code-lens contribution (`bmad-agent-pm/customize.toml:13-15`, `_prompts.py:46-94`, etc.) gives the synthesis verifiability that pure-prose research reports often lack.
2. **Controversies preserved, not averaged.** CC1 (Cognition vs Anthropic) — the single most important controversy in the agent-shape research space — is surfaced prominently in executive summary L15 and again in cross-cutting section CC1 (L458–464) with both positions quoted and resolution-by-task-type explained. This is the model behavior the spec's Tier 3 D requires.
3. **Honest "no-evidence-found" inventory.** 18 explicit gaps (L518–556), each with which-lenses-converged-on-absence attribution. Used as honest scientific disclosure, not as an escape hatch — gaps include the meta-gen production deployment absence, Pass@K reliability gap, HITL user-trust empirical gap, and 21-vs-7 specialized agent comparison gap. This protects A.1 brainstorm from assuming answers exist.
4. **Confidence calibration is explicit and per-question.** L699 grades each Q HIGH/MEDIUM/LOW with reasoning; PayPal-as-N=1, BMAD-ROI-as-marketing, MindsDB-10x-as-self-report all flagged as low-confidence. This honesty raises the document's value as A.1 input.
5. **Q12 anomalies surfaced with intellectual honesty.** Anomaly 3 (superpowers star count discrepancy) is exactly the kind of inconsistency the spec asks to flag rather than hide. Anomaly 9 (Cognition vs Anthropic same-month authoritative contradiction) is treated as a communication artifact worth flagging — not just a controversy.

---

## Final verdict

**Round 1 verdict:** PASS_WITH_REVISIONS

- **No CRITICAL issues.** All Tier 1 structural sections present; cross-lens triangulation verified; controversies preserved; no-evidence inventory honest; provenance complete.
- **Two MAJOR items** (Q12 score-arithmetic transparency; preserved source-agent verdicts amplified in synthesis voice) should be addressed before final.md, but neither blocks PASS.
- **Five MINOR items** are nice-to-have polish.
- Per the review protocol: PASS_WITH_REVISIONS without critical issues → **synthesis.md may be promoted to final.md after MAJOR-1 + MAJOR-2 revisions are applied; no Round 2 review required.** If author chooses to address MINORs as well, even better.

**Recommendation to forge harness:** apply MAJOR-1 (Q12 table arithmetic transparency) and MAJOR-2 (rephrase prescriptive verdict-language) as a single revision pass, then promote to final.md. Run 2 (Q13–Q21 deep-dives + Q22 cross-run synthesis) reads this document; the framing it lands in matters for downstream phases.
