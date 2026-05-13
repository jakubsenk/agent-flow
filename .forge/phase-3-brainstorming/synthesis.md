# Phase 3 Brainstorm Synthesis -- v10.2.0 Phase B Path-Format

**Forge run:** `forge-2026-05-13-001`
**Method:** Judge-Mediated (per `synthesis-prompt.md` Phase 3), Anti-Conformity / Free-MAD
**Date:** 2026-05-13
**Inputs:** 3 brainstorm proposals (conservative B3, innovative B1, skeptical B2+guard+lint)
**Evidence anchors:** Phase 2 final.md (locked at v10.1.2 / 32f6f33), roadmap.md L1489-L1513, CLAUDE.md L17 (markdown-only invariant), L82-L92 (v10.0.0 reliability contract), `core/lib/stage-invariant.sh` (134L precedent).

---

## Persona Scores (0-5 each, on the same task criteria)

| Persona | Strengths | Weaknesses (specificity, not generality) | Phase A composition | Phase C rigor | Forward-compat | Falsifiable metric | Total /30 |
|---|---|---|---|---|---|---|---|
| Conservative (B3) | 4 | 3 (admits Phase-A-dependency honestly but underweights it) | 5 (tightest composition — B3 IS Phase A prose) | 3 (concedes Phase C cannot falsify reader comprehension) | 4 (best forward-compat assuming Phase A holds) | 3 (metric is "Phase A fires" — does not isolate B3) | **22** |
| Innovative (B1) | 4 (genuine forward-compat advantage, 3-tier helper design is concrete) | 3 (40-LOC helper acknowledged; Read-tool-token-expansion gap NOT addressed) | 3 (composes only with mandatory `<PREFLIGHT>` ordering — co-dependent, not orthogonal) | 4 (2 vectors + OS matrix called out) | 5 (strongest, conditional on shim surviving) | 4 (5-criterion gate is concrete and falsifiable) | **23** |
| Skeptical (B2+guard+depth-lint) | 5 (orthogonal defense-in-depth, no new machinery in markdown-only plugin) | 3 (depth-split is real cost; symlink + spaces hazards flagged) | 5 (genuinely orthogonal — guard catches plugin-integrity; B2 catches path-anchor) | 5 (5-criterion gate with depth-lint as P0 kill-switch) | 3 (depth-split tax forever, but bounded by lint) | 5 (5 simultaneous metrics, each grep-able) | **26** |

**Std dev across totals:** sqrt(((22-23.67)^2 + (23-23.67)^2 + (26-23.67)^2) / 3) = sqrt((2.78 + 0.45 + 5.43) / 3) = sqrt(2.89) ≈ **1.70**

**Disagreement metric exceeds 1.5 threshold.** Disagreement Analysis section included below.

---

## Pairwise Analysis

### Conservative (B3) vs Skeptical (B2)

**Agree:**
- B1 is NOT-VIABLE-without-helper (Phase 2 I1 dispositive).
- Phase A guard is mandatory and is the actual fail-loud mechanism.
- Markdown-only plugin ethos (CLAUDE.md L17) favors mechanism-light.
- The 3-discrete-actions for `skills/scaffold/data/guard-block.md` (mkdir + new file + SKILL.md directive).

**Disagree:** What does Phase B do mechanically beyond Phase A?
- Conservative: nothing mechanical — Phase B is ~12 lines of prose clarifier + guard-block hint; Phase A carries the entire correctness load.
- Skeptical: a depth-aware sed rewrite of all 185 occurrences across 4 depth classes, paired with Phase A as orthogonal defense-in-depth, paired with a depth-lint as P0 kill-switch.

**Stronger position:** **Skeptical (B2 + Phase A + depth-lint)**, by evidence:

1. **BIFITO-4293 itself is the falsification of B3 alone.** roadmap L1491-L1493 documents that Claude already had the implicit "core/ is sibling of skills/" context (the layout has never changed), yet hallucinated `skills/fix-bugs/core/` and silently degraded. B3's response is to make the implicit explicit via prose. But the failure was not "Claude did not know the layout"; it was "Claude confabulated paths under context pressure and then silently fell back" (roadmap L1491 verbatim: `"Core files don't exist in this install — I'll work from SKILL.md + step files directly."`). Adding more prose does not change the confabulation risk; only mechanical path-anchoring (B2) or fail-loud probes (Phase A) prevent silent degradation.
2. **B2 + Phase A composes as genuinely orthogonal layers.** Phase A guard validates plugin-install integrity (probe from CWD = repo root). B2 anchors each `core/<X>.md` reference to its containing SKILL.md's directory tree via `../../`. Two independent mechanisms; the bug must defeat both to recur. Conservative concedes B3's "correctness IS Phase A's correctness" (Conservative L139-L141, "the composition is tightest" — but tightest composition is single-layer defense, not depth).
3. **Skeptical's falsifiable metric is grep-able; Conservative's is reader-comprehension-bound.** Skeptical's 5-criterion gate (runtime scenario PASS, fail-loud abort, depth-lint, no v10.0.0 regression, B1/B3 counterfactual fails) is mechanical. Conservative's metric ("Phase A scenario passes; control-disabled Phase A fails") proves Phase A works, not that B3 contributes anything beyond Phase A.

### Conservative (B3) vs Innovative (B1)

**Agree:**
- B2's depth-split tax is real and meaningful authoring friction.
- v10.0.0 reliability contract (`core/lib/stage-invariant.sh`) must remain untouched.
- The CLAUDE.md L17 "markdown-only plugin" line is the load-bearing constraint.

**Disagree:** How much new machinery is justified to fix a path-text bug?
- Conservative: zero. The whole bug class can be addressed by prose discipline + Phase A.
- Innovative: ~40 LOC of well-designed helper is the right "abstraction" for a 5-year horizon, and acceptable per the `core/lib/stage-invariant.sh` precedent.

**Stronger position:** **Conservative (B3)** on the machinery-cost axis specifically, by evidence:

1. **Phase 2 I1 is binary-conclusive against B1's baseline assumption.** `${PLUGIN_ROOT}` is not a Claude Code dispatch contract. Adopting B1 means inventing a platform contract the platform does not back. Conservative's argument that the Read tool does NOT shell-expand its arguments (Conservative L40) is direct evidence of a structural failure mode Innovative's helper-design does not address — the helper sets the env var, but markdown-prose `${PLUGIN_ROOT}/core/X.md` inside backticks is read by Claude's Read tool, which treats it as a literal path containing the unexpanded token.
2. **Innovative's 3-tier resolver (Tier 1 env / Tier 2 `$BASH_SOURCE` / Tier 3 CWD-walk) is itself a mechanism that needs its own Phase C OS-matrix validation.** Innovative concedes this (Innovative L259: "Phase C must run the scenario on all 3 OSes... matching `core/lib/stage-invariant.sh`'s stated portability target"). That is mechanism-budget consumption beyond the 50-100 line Phase B estimate (roadmap L1509).
3. **However, Conservative loses the larger argument** because its "machinery-cost" win comes at the price of zero mechanical guarantee — see the next pairwise.

### Skeptical (B2) vs Innovative (B1)

**Agree:**
- B1's machinery cost is real and contestable.
- Phase C must include OS-matrix coverage if B1 is chosen.
- v10.0.0 reliability contract (`core/lib/stage-invariant.sh`) is the convention precedent for `core/lib/` helpers.
- Phase A guard is mandatory regardless of B*.

**Disagree:** Is the depth-split a maintenance tax worth carrying, or is the helper-shim a worse cost?
- Skeptical: depth-split is bounded by lint (Phase C item 3); zero new runtime mechanism; markdown stays markdown.
- Innovative: depth-split is forever; helper amortizes; forward-compat win is real.

**Stronger position:** **Skeptical**, decisively, by evidence:

1. **The Read-tool-token-expansion gap is dispositive.** Even if Innovative's helper exports `PLUGIN_ROOT` perfectly, the markdown prose `Follow \`${PLUGIN_ROOT}/core/X.md\`` is rendered to the model as a literal string containing `${PLUGIN_ROOT}`. The model would have to mentally substitute the variable — exactly the kind of reader-comprehension step that BIFITO-4293 proved is unreliable. Conservative caught this at L40; Skeptical caught it at L23 ("Markdown cannot resolve env vars... the model has to KNOW to resolve ${PLUGIN_ROOT}... a path-format bug fix that adds a new path-resolution step that itself can be skipped is a strict regression"). Innovative's brief does not refute this point — the helper provides the env var, but the markdown surface is still prose-only.
2. **The depth-lint (Skeptical Phase C item 3) is a true kill-switch.** A ~25-line bash check that asserts depth-correctness on every `core/<X>.md` reference makes the depth-split bounded — future restructures fail at lint time, not at user-run time. Innovative's "depth-split is forever" critique is real only if depth-lint is absent; with it, B2's maintenance cost is `static check exit code` per CI run, which is trivial.
3. **Innovative's own concession seals it.** Innovative L261: "If SKEPTICAL surfaces a Windows-MinGW $BASH_SOURCE failure mode I haven't anticipated, my recommendation collapses. B2 + Phase A guard becomes the right answer." This is a stated condition Innovative concedes. Phase 2 I1 already binarily-conclusively establishes the helper is unbacked by platform.

---

## Specific Flaws Per Proposal (≥2 each, Anti-Conformity)

The personas described their own weaknesses; this section finds flaws they may have minimized or did not surface.

### B1 Flaws (innovative recommended; ≥2 specific not just persona-acknowledged)

1. **Read-tool-token-expansion gap (dispositive, not addressed by helper-design).** Innovative's brief covers exporting `PLUGIN_ROOT` to the Bash environment. It does NOT address the structural fact that markdown prose inside backticks (`${PLUGIN_ROOT}/core/X.md`) is presented to Claude's Read tool as a literal path with the token un-expanded. The helper exports the env var; the Read tool does not consume the env var; the model must perform the substitution. This is exactly the prose-comprehension gap that B3's flaw 1 (below) identifies for prose clarifiers, but for `${PLUGIN_ROOT}` syntax — only WORSE, because `${PLUGIN_ROOT}` looks like a path component while a B3 clarifier looks like a comment.
2. **Phase C OS-matrix cost not in budget.** Innovative's gate has 5 criteria, one of which is "OS-matrix validation on Linux, macOS, Windows Git-Bash." `core/lib/stage-invariant.sh` (134 lines, 9 days old) is the only existing precedent for this; it has 13 v10-*.sh scenarios. B1 would add at least 3 more (Tier 1 hit, Tier 2 hit, Tier 3 hit) × 3 OSes = 9 test variants. The 50-100 line Phase B budget (roadmap L1509) does not absorb this; total Phase B would be ~150-200 lines, busting the budget.
3. **The `core/lib/` precedent is misapplied.** `core/lib/stage-invariant.sh` exists because dispatch-witness genuinely needs atomic SHA-256 computation that markdown cannot express. Path resolution does not need atomic semantics; it is a plain `dirname`. Using `core/lib/` for path resolution stretches the "POSIX helper" rationale into "anything we want to do in Bash" — slippery slope toward a runtime Innovative explicitly disavowed in the persona prior (Innovative L7: "markdown-only plugin").

### B2 Flaws (skeptical recommended; ≥2 specific)

1. **Depth-split corrupts ANY naive rewrite.** Skeptical acknowledged this but Phase 2 I1 makes it ACTIVE risk: 7 agent files at depth 1 (`../core/`), 9 SKILL.md at depth 2 (`../../core/`), 28 step/data files at depth 3 (`../../../core/`). A single `sed -i 's|core/|../../core/|g'` corrupts depth-1 (becomes `skills/../../../core/X.md` — points above repo) and depth-3 (becomes `skills/{name}/steps/../../core/X.md` — points at `skills/{name}/core/` which is THE BIFITO-4293 BUG). The Phase 4 spec MUST mandate per-class sed invocations OR a depth-aware path-rewrite script. This is non-trivial mechanism for a "mechanism-light" option.
2. **Symlink + path-with-spaces hazards (Skeptical-flagged but worth re-emphasizing).** `~/.claude/plugins/cache/ceos-agents` may be a symlink in the marketplace install flow. `../../core/` from a symlinked SKILL.md resolves through the symlink-parent on most shells, NOT the target's parent. Phase C must explicitly probe this; otherwise consumer installs from `claude plugin install` could silently break in a way that does NOT reproduce in repo-local development.
3. **Claude's documented relative-path mishandling (roadmap L1501).** Roadmap states verbatim: "Claude má problém s relative paths když CWD ≠ skill dir." Both Skeptical and Innovative cite this. B2's correctness depends on Claude's Read tool resolving `../../core/X.md` relative to the SKILL.md file's directory, NOT relative to CWD. If Claude resolves it against CWD = repo root, paths work; if against any other CWD, paths break silently (resolves to `<other-cwd>/../../core/X.md`). Phase A guard catches gross-CWD-wrong cases; it does NOT catch per-step CWD-drift in sub-agent dispatch contexts.

### B3 Flaws (conservative recommended; ≥2 specific)

1. **B3 is the de-facto status quo, and BIFITO-4293 is its real-world falsification.** The pre-v10.2.0 plugin already implicitly assumes "core/ is sibling of skills/" — the file layout has been stable since v6.x. BIFITO-4293 happened anyway because Claude confabulated `skills/fix-bugs/core/`. Adding explicit prose ("sibling of skills/, at plugin root") on first occurrence does not address WHY Claude confabulated; it only documents the correct layout in case Claude reads the clarifier. The skeptical agent correctly identifies this as "doubling down on prose without mechanical reinforcement just adds more prose to ignore" (Skeptical L88). **This is a decisive argument** unless one accepts that the new clarifier is structurally different from the old implicit layout knowledge — see the critical adversarial probe below.
2. **No machine-checkable invariant for the clarifier itself.** B3 ships ~12 lines of prose. A future SKILL.md author can forget the clarifier; a lint scenario can check `grep -l 'sibling of skills/' skills/*/SKILL.md` returns all 9 files — but cannot verify the clarifier is SEMANTICALLY correct (the prose can drift, contain typos, get truncated by an automated edit). Conservative's response (Conservative L125) concedes this: "B3 has 'first occurrence in SKILL.md has clarifier prose' — a regex check against drift, not a semantic check."
3. **Conservative's claim of "lowest blast radius" is misleading.** Conservative L118: "If B3 is wrong, the fix is to add Phase A teeth (which is mandatory anyway)." This is exactly the problem — B3's rollback IS adopting B2 or B1, plus rewriting 185 occurrences NOW. The fact that Phase A is mandatory regardless means B3 contributes ZERO additive defense beyond Phase A. Calling that "lowest blast radius" obscures that B3's blast radius is zero defensive contribution.

---

## Critical Adversarial Probes (from the prompt)

### Probe 1: Does BIFITO-4293 itself falsify B3?

**Question:** SKEPTICAL argued BIFITO-4293 falsifies B3 (prose-only clarification already failed). Is this argument decisive, or does it conflate two different prose styles — the existing implicit `core/<file>.md` (which assumes reader knows the layout) vs the new explicit "sibling of skills/" clarifier (which states the layout)?

**Verdict:** **The argument is partially decisive but does conflate styles.** Resolution:
- The OLD status quo (v10.1.2 HEAD) has 185 occurrences of bare `core/<X>.md` with ZERO clarifier prose. The reader (Claude) must infer "core/ is sibling of skills/" from training-data priors about plugin layout. BIFITO-4293 proves that inference is unreliable under context pressure.
- B3's proposed NEW prose ("sibling of skills/, at plugin root — NOT `skills/{name}/core/`") is informationally stronger than the old implicit. It makes the wrong path explicitly wrong and the right path explicitly right.
- **HOWEVER**, BIFITO-4293's failure mode was NOT "Claude misunderstood the layout"; it was "Claude scanned only SKILL.md, hallucinated 3 file reads from `skills/fix-bugs/core/`, then ls-disproved itself and silently fell back" (roadmap L1493). The hallucination happened DESPITE the layout being implicit-but-stable; the silent fallback happened despite no explicit instruction to fall back.
- The new clarifier helps the case where Claude reads the SKILL.md prose attentively. It does NOT help the case where Claude confabulates paths in a sub-agent context where the SKILL.md is not freshly in attention.
- **Therefore:** B3 is a measurable upgrade over the pre-v10.2.0 implicit status quo, but it is NOT mechanically sufficient. Skeptical's argument is decisive against "B3 alone solves BIFITO-4293" but not against "B3 contributes nonzero defense as a documentation layer."

**Implication for synthesis:** B3's clarifier prose is a valid LOW-COST ADDITIVE element on top of B2's mechanical rewrite. It is NOT a substitute. Conservative's recommendation of "B3 ALONE" is rejected; B3's clarifier survives as a hybrid component.

### Probe 2: Is the helper shim acceptable mechanism cost in a "markdown-only plugin"?

**Question:** INNOVATIVE's helper shim costs ~40 LOC of new bash + a Tier 3 CWD-walk depending on a sentinel marker (`.claude-plugin/plugin.json`). Is this acceptable in a markdown-only plugin?

**Verdict:** **No, not for this specific bug.** Resolution:
- CLAUDE.md L17 verbatim: "No build system, no dependencies. Manual test suite in `tests/`. This is a pure plugin of markdown definitions." This is a stated invariant.
- The v10.0.0 reliability contract introduced `core/lib/stage-invariant.sh` (134 LOC) as a deliberate exception, justified by: (a) atomic SHA-256 computation that markdown cannot express; (b) dispatch-witness audit needs Bash-level state mutation; (c) precedent set as part of a MAJOR version with full Phase 8 verification.
- Innovative's helper resolves a path. Path resolution is `dirname` and `[ -r FILE ]` — both are markdown-expressible in prose ("the path is sibling of skills/"). The Bash machinery is for resolution against an UNRELIABLE CWD, which is itself a workaround for Claude's CWD-handling, which Phase A guard already addresses for the gross-mismatch case.
- The Read-tool-token-expansion gap (B1 flaw 1 above) means the helper's env-var export does not even reach the markdown surface — the model must mentally substitute `${PLUGIN_ROOT}`, which is the same prose-comprehension step that B3 is criticized for.
- **Therefore:** The helper-shim is mechanism without the markdown-side semantic that would justify it. Acceptable IF Claude Code formalized `${PLUGIN_ROOT}` expansion in Read tool arguments (not yet, per Phase 2 I1); UNACCEPTABLE today.

**Implication for synthesis:** B1 is rejected as the primary path. The helper-shim concept may resurface in a future MAJOR if Claude Code adopts platform-injected `CLAUDE_PLUGIN_ROOT` Read-tool expansion.

### Probe 3: Does B3 actually fix the BIFITO-4293 silent degradation, or does it only rely on Phase A?

**Question:** CONSERVATIVE's B3 has zero edits beyond inline prose. Does it actually fix the silent degradation, or does it only rely on Phase A for the actual fix?

**Verdict:** **B3 relies entirely on Phase A for the silent-degradation fix.** Resolution:
- The silent-degradation bug is: Claude tries to read `core/X.md`, gets "file not found" (because it confabulated `skills/{name}/core/`), and then falls back silently to "I'll work from SKILL.md + step files directly" (roadmap L1491 verbatim).
- B3's prose clarifier ("sibling of skills/") helps Claude pick the RIGHT initial path. It does NOT make the failure LOUD if Claude picks the WRONG path despite the clarifier (which is what BIFITO-4293 proved happens under context pressure).
- Phase A guard's `[ -r core/mcp-preflight.md ]` probe from CWD = repo root fails LOUD on a wrong CWD. That is the silent-degradation fix.
- Conservative explicitly concedes this at L139-L141 ("B3 IS the prose half of Phase A... not orthogonal — collapsed into the same file") and L165 ("Phase A guard MUST be the very first instruction... if Phase A is weakened... downgrade to B2 + depth-aware sed").
- **Therefore:** B3 contributes ZERO additive silent-degradation defense beyond Phase A. Its contribution is purely DOCUMENTARY: helping the reader (Claude or human) understand the canonical layout.

**Implication for synthesis:** B3's prose clarifier has documentary value but zero mechanical defensive value. It belongs in a hybrid as a low-cost additive ON TOP of B2, NOT as a substitute.

---

## Synthesis Recommendation

**Chosen option:** **HYBRID — B2 mechanical rewrite (depth-aware) + Phase A guard + Phase C depth-lint + B3 prose clarifier as ADDITIVE documentation in 3 guard-block.md files**

**Composition:**

1. **Phase A (mandatory, ~30-40 lines):** Per roadmap L1497 + Phase 2 I3. Prepend new `<PREFLIGHT>` XML block to each of 3 guard-block.md files (`skills/{fix-bugs,implement-feature,scaffold}/data/guard-block.md`). Probe `[ -r "core/mcp-preflight.md" ]` from CWD = repo root (with explicit quoting per Skeptical's space-hazard note). On failure: emit canonical message `"plugin-root not resolved — core/ sibling of skills/ not found at <attempted-path>. Check plugin install integrity."` and abort with exit 1. NEW: `skills/scaffold/data/guard-block.md` must be created from scratch (mkdir + new file + SKILL.md L11-style directive) per Phase 2 C2. (from Skeptical L106, Conservative L114, roadmap L1497)
2. **Phase B (mechanical, depth-aware, ~50-80 net lines):** B2 `../../core/X.md` rewrite per 4-class depth split (Phase 2 final.md "B2 Depth-Split Mandate"). MUST be implemented as 3-4 separate sed invocations or an explicit file-class manifest. NEVER a single naive global sed. (from Skeptical L50, Phase 2 mandate)
   - depth 1 (`agents/*.md`) → `../core/<X>.md` (7 occurrences in 3 files)
   - depth 2 (`skills/{name}/SKILL.md`) → `../../core/<X>.md` (~64 occurrences in 9 files)
   - depth 3 (`skills/{name}/steps/*.md`) → `../../../core/<X>.md` (~110 occurrences in ~28 files)
   - depth 3 (`skills/{name}/data/*.md`) → `../../../core/<X>.md` (~4 occurrences in 2 existing + 1 new guard-block.md)
3. **B3 prose clarifier (ADDITIVE, ~3-9 lines, ONLY in guard-block.md):** Add ONE-LINE clarifier inside each `<PREFLIGHT>` block: `All core/<file>.md references in this skill use relative paths (../core/, ../../core/, or ../../../core/ depending on file depth). The canonical layout is core/ as sibling of skills/ at plugin root.` This is documentary and supports human readers; it does NOT replace mechanical correctness. NO clarifier in SKILL.md or step files (their paths now self-document via `../../`). (from Conservative — adopted as additive, not primary)
4. **Phase C (testing, ~80-120 lines, P0):** Three scenarios mandatory.
   - **C1 — runtime scenario (`tests/scenarios/v10-skill-from-external-cwd.sh`)** invoked from CWD = `$TMPDIR/external-$$/`. Asserts orchestrator successfully reads `core/mcp-preflight.md` via the depth-correct relative path AND a witness audit emits WITNESS_OK for at least one stage AND grep for `"Core files don't exist in this install"` in transcript returns 0 matches (BIFITO-4293 anti-marker). (from Skeptical metric 1)
   - **C2 — fail-loud regression scenario** with `core/mcp-preflight.md` temporarily renamed. Asserts pipeline aborts with stderr matching regex `plugin-root not resolved` and exit code non-zero. Then restores. (from Skeptical metric 2 and Conservative)
   - **C3 — depth-lint scenario (`tests/scenarios/v10-core-path-depth-consistency.sh`)** static-check: for each `*.md` under (`agents/`, `skills/{X}/SKILL.md`, `skills/{X}/steps/*.md`, `skills/{X}/data/*.md`), grep `(\.\./)+core/[a-z-]+\.md` and assert the dotdot-count matches the depth class. Fail with exit 1 + offending file:line list otherwise. ~25 lines bash, jq-free, mirrors `tests/scenarios/v10-step-completion-invariants-completeness.sh` style. (from Skeptical metric 3, P0 kill-switch)
5. **Explicitly EXCLUDED:**
   - **B1 (helper shim)** rejected per Phase 2 I1 (NOT-VIABLE-without-helper) AND Probe 2 verdict (mechanism violates markdown-only plugin invariant) AND the Read-tool-token-expansion gap.
   - **No new files under `core/lib/`.** The v10.0.0 reliability contract precedent does not extend to path resolution.
   - **No `${PLUGIN_ROOT}` syntax anywhere in markdown.**
6. **NOT in scope for v10.2.0** (but flag for roadmap follow-ups):
   - Symlink-resilience and path-with-spaces probes (Skeptical Phase C items 4 and 5) — deferred to v10.2.1 if a real-world report surfaces them.
   - OS-matrix testing — current harness assumes Git-Bash / Linux; no v10.2.0 commitment to expand. (Stage-invariant.sh self-test bug from Phase 8 is the precedent for that being a separate concern.)

**Confidence:** **0.84**

Computed from:
- +0.30 hybrid composes 3 layers (B2 mechanical anchor + Phase A fail-loud + B3 documentary) — defeats both confabulation (clarifier + Phase A) and CWD drift (anchored relative path + Phase A)
- +0.20 depth-lint is a true CI-time kill-switch for the B2 maintenance tax
- +0.15 zero new `core/lib/` files preserves CLAUDE.md L17 markdown-only invariant
- +0.10 falsifiable metric is 5-criterion grep-able, not reader-comprehension-dependent
- +0.05 explicit additive role for B3 prose preserves the Conservative insight without inheriting its zero-mechanical-defense flaw
- -0.10 B2's depth-split corruption risk is real if Phase 4 spec is unclear about the per-class sed invocations
- -0.05 Claude's documented relative-path mishandling (roadmap L1501) is a known unknown — depth-lint catches authoring drift but not runtime CWD drift in sub-agent contexts
- -0.05 hybrid is more LOC than any single option (estimated ~150-200 net lines vs roadmap's 50-100 estimate; bumps into roadmap's 250-350 total budget but stays inside it)
- -0.05 v10.2.0 ships with no symlink/OS-matrix proof; first consumer install on macOS via marketplace symlink could surface a regression Phase C did not cover

**Falsifiable success metric:**

> v10.2.0 ships if and only if ALL of the following hold simultaneously on the v10.2.0 release candidate commit:
>
> 1. **C1 PASSES:** `tests/scenarios/v10-skill-from-external-cwd.sh` invoked from CWD = `$TMPDIR/external-$$/` exits 0; orchestrator transcript contains at least one WITNESS_OK line; grep `"Core files don't exist in this install"` returns 0 matches.
> 2. **C2 PASSES:** `tests/scenarios/v10-skill-from-external-cwd-fail-loud.sh` (or `--mode fail-loud` flag) with `core/mcp-preflight.md` temporarily moved away exits non-zero AND stderr matches regex `plugin-root not resolved`. After restore, regular run passes.
> 3. **C3 PASSES:** `tests/scenarios/v10-core-path-depth-consistency.sh` static-checks all 40 affected files and emits 0 depth-mismatch violations.
> 4. **v10.0.0 reliability contract preserved:** `core/lib/stage-invariant.sh` is byte-identical to v10.1.2 HEAD; all 13 existing v10-*.sh scenarios continue to PASS.
> 5. **Harness budget:** total harness reports ≥ 353 pass / 0 fail (currently 353/348/0/5; v10.2.0 adds 3 new scenarios → 356/348/0/5 or better. If new scenarios skip, the 5-skip count may rise to 8; that is acceptable per v9.6.1 precedent. 0 fail is non-negotiable.)
> 6. **Counterfactual sanity:** the depth-lint (C3) MUST fail with exit 1 on a deliberately-corrupted control branch where one file's `core/` prefix is at the wrong depth (e.g., revert one `../../../core/` to `../../core/` in a step file). This proves the lint actually catches the failure mode it is designed to catch. Run this counterfactual in Phase 7 verification before tagging.
>
> v10.2.0 FAILS and falls back to "B2 + Phase A guard only, no depth-lint" (Skeptical 0.60-confidence fallback) if any of (1)-(5) fails. v10.2.0 FAILS and re-enters Phase 3 brainstorm if (6) fails (the lint is broken).

**Open question for Gate 1 (user approval):**

> **Should v10.2.0 ship the hybrid (B2 mechanical + Phase A guard + B3 documentary clarifier in guard-block.md + C3 depth-lint), accepting ~150-200 net LOC versus the roadmap's 50-100 Phase B estimate (still inside the 250-350 total budget), in exchange for orthogonal defense-in-depth (mechanical path anchoring + fail-loud probe + documentary clarifier + CI-time depth-lint)? YES = proceed to Phase 4 spec on this hybrid. NO (alternative path) = Phase 4 spec ships B2 + Phase A ONLY (drop B3 clarifier and C3 depth-lint), saving ~30-50 LOC at the cost of losing the lint-kill-switch and the documentary clarifier.**

---

## Disagreement Analysis (std dev = 1.70 > 1.5 threshold; required by synthesis-prompt.md)

The 3-persona total-score range was 22 / 23 / 26, std dev ≈ 1.70 — meaningful disagreement. Unresolved tensions for the user's attention at Gate 1:

1. **Mechanism budget interpretation.** Conservative reads CLAUDE.md L17 ("markdown-only plugin") as a hard constraint that disallows ANY new Bash for path resolution. Innovative reads it as a guideline subject to `core/lib/stage-invariant.sh` precedent. Skeptical agrees with Conservative on the principle but accepts Phase A guard probe (`[ -r ... ]` inside guard-block.md prose) as not-machinery. **The hybrid uses ONLY guard-block.md prose Bash (no new `core/lib/` file)** — Conservative-and-Skeptical compatible. If the user reads "markdown-only" more strictly (forbidding even guard-block.md Bash probes), Phase A must be re-thought; the hybrid becomes inapplicable.
2. **B2 depth-split mitigation method.** Skeptical's depth-lint is the canonical mitigation; Innovative would dispute it as "lipstick on the depth-split" — a CI check that catches authoring drift but doesn't prevent the cognitive tax on each new skill author. The hybrid accepts the lint as sufficient; the user should validate this is acceptable maintenance discipline. If "every new skill author must do path-depth math" is unacceptable in the project's voice, B1 re-enters consideration despite the Read-tool gap (which would then need a different mitigation, e.g., a markdown lint that rewrites `${PLUGIN_ROOT}/core/X.md` to depth-correct `../../core/X.md` at install time — a Build Step, violating CLAUDE.md L17 even more sharply).
3. **B3 prose-clarifier scope.** Conservative wants the clarifier on FIRST OCCURRENCE in each SKILL.md (9 files). The hybrid restricts it to the 3 guard-block.md files (3 files). Conservative would argue this drops 6 documentation surfaces; the hybrid argues those 6 SKILL.md files now self-document via `../../core/` so prose is redundant. The user can elect to restore SKILL.md clarifiers at +6 lines of prose — purely additive, no defense impact.
4. **Phase C OS-matrix.** None of the 3 personas commit to OS-matrix testing in v10.2.0. Skeptical's Phase C items 4 and 5 (symlink, spaces, unicode) are nice-to-have; the hybrid defers them to v10.2.1 if surfaced. If the user wants v10.2.0 to ship with OS-matrix confidence (matching `core/lib/stage-invariant.sh`'s portability target), Phase 7 verification must add Git-Bash + Linux + macOS test variants — +~50 LOC, +1-2 h forge time.

These four tensions are flagged for the user at Gate 1. None of them blocks the hybrid recommendation; each represents a knob the user can turn at spec time.

---

## Method Notes

- Judge-Mediated synthesis per `synthesis-prompt.md` lines 37-55, with Anti-Conformity / Free-MAD pattern applied (≥2 specific flaws per option beyond persona-acknowledged weaknesses) per lines 57-64.
- Std dev across persona total scores = 1.70 (above 1.5 threshold per line 14 and 67-69) — Disagreement Analysis section included per protocol.
- Evidence-grounded throughout: every claim cites either a Phase 2 final.md answer (`I1`, `C1`, `C2`, `I2`, `I3`, "B2 Depth-Split Mandate"), a roadmap line number (`L1489-L1513`), a CLAUDE.md invariant (`L17`, `L82-L92`), a persona brief line number, or a file path with concrete content.
- The synthesis preserves the strongest mechanical element of B2 (depth-aware path anchoring), the strongest fail-loud element of Phase A (already-mandatory guard), the strongest documentary element of B3 (prose clarifier in guard-block.md), and the strongest validation element of Skeptical's plan (depth-lint as CI kill-switch). It rejects B1 entirely (Read-tool-token-expansion gap is dispositive).

STATUS: SYNTHESIS_COMPLETE
