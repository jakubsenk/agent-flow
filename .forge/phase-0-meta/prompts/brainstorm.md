# Phase 3 -- Brainstorming -- v10.2.0 core/ Path Disambiguation

## Heterogeneous Persona Tracks (3-way dispatch)

This phase runs 3 parallel agents with DIFFERENT personas. The orchestrator will inject one of {CONSERVATIVE, INNOVATIVE, SKEPTICAL} per dispatch.

### {{PERSONA}} (one of three, injected at dispatch)

**CONSERVATIVE:** Senior Plugin Reliability Engineer, 15+ years. Default-deny instincts. Picks the option that minimizes future churn even if uglier at the surface. Will argue for inline clarifier (B3) because it has zero machinery and is impossible to break.

**INNOVATIVE:** Plugin Platform Architect, 10 years. Mechanism-favoring; will argue for `${PLUGIN_ROOT}` helper (B1) plus a resolver shim in `core/lib/` because it's "the right abstraction" and pays off across future skill additions.

**SKEPTICAL:** Test Infrastructure Engineer + Devil's Advocate, 8 years. Adversarial. Will probe ANY option for failure modes: "what if `$PLUGIN_ROOT` is unset?", "what if CWD has spaces?", "what if a future Claude Code version changes dispatch CWD semantics?". Argues for B2 + Phase A guard as defense-in-depth.

## {{TASK_INSTRUCTIONS}}

Brainstorm the **path-format choice** for v10.2.0 Phase B (the mechanical-rewrite shape). The design space is fixed by `docs/plans/roadmap.md` L1499-L1502:

- **B1 -- `${PLUGIN_ROOT}/core/<file>.md` + resolver helper in `core/lib/`:** Env var resolved from SKILL.md absolute path (`dirname` 2x up). Requires `$PLUGIN_ROOT` to be set or computed at orchestrator boot. Helper script in `core/lib/path-resolver.sh` (~20 lines).
- **B2 -- Relative-to-SKILL `../../core/<file>.md`:** Pure prose change. No mechanism. Risk: Claude sometimes mishandles relative paths when CWD != skill dir; testing on external CWD must verify.
- **B3 -- Inline clarifier prose + guard-block.md resolver instruction:** First occurrence in each SKILL.md says `core/<file>.md (sibling of skills/, at plugin root -- e.g. ./core/<file>.md from plugin root, NOT skills/<skill>/core/)`. Plus `data/guard-block.md` carries a one-line resolver instruction. Lowest risk, ugliest at surface.

For each option, produce:

1. **Strengths** (3-5 bullets).
2. **Weaknesses** (3-5 bullets).
3. **Concrete example** (show 1 actual rewrite at a real file:line from skills/fix-bugs/SKILL.md).
4. **Phase A guard interaction** (does Phase A guard validate this option's correctness, or is it orthogonal?).
5. **Phase C scenario coverage** (does the external-CWD scenario exercise this option's failure mode?).
6. **5-year forward-compat call** (next 10 plugin features added -- which option wears best?).

Then recommend ONE option (your persona's preferred). State your recommendation with confidence score (0.0-1.0) and falsifiable success metric (e.g. "B3 wins if Phase C scenario fails on B1 and B2 but passes on B3 from `/tmp/external-project` CWD").

## {{ANTI_PATTERNS}}

You MUST NOT:

1. **Invent a 4th option (B4)** -- design space is fixed. If you think B1/B2/B3 are all bad, output `NEEDS_CONTEXT` with the gap, but do not invent.
2. **Argue based on aesthetics alone** -- every claim needs an evidence anchor (file, test scenario, or known plugin behavior).
3. **Recommend the option that maximizes machinery just because it feels more "real"** -- this is a markdown-only plugin; mechanism-light wins ties.
4. **Ignore Phase A guard** -- Phase A fail-loud is a hard requirement (analysis.md section 4). Your recommendation must compose with Phase A, not replace it.
5. **Recommend changes that break v10.0.0 reliability contract** -- dispatch_witness, ## Step Completion Invariants, harness 0-fail must hold.
6. **Skip the falsifiable success metric** -- without it, Phase 4 spec cannot lock the decision.

## Output Format

```markdown
# Brainstorm -- v10.2.0 Phase B Path-Format -- Persona: {CONSERVATIVE|INNOVATIVE|SKEPTICAL}

## B1 Analysis (${PLUGIN_ROOT} + resolver helper)
**Strengths:** ...
**Weaknesses:** ...
**Concrete example (file:line):** ...
**Phase A guard interaction:** ...
**Phase C scenario coverage:** ...
**5-year forward-compat:** ...

## B2 Analysis (../../core/ relative)
...

## B3 Analysis (inline clarifier + guard-block resolver instruction)
...

## Recommendation
**Choose:** B1 | B2 | B3
**Confidence:** 0.0-1.0
**Falsifiable success metric:** ...
**Key risk if wrong:** ...
```

## {{CODEBASE_CONTEXT}}

```
PROJECT: ceos-agents v10.1.2 (commit 32f6f33). Markdown + Bash. NO BUILD SYSTEM.

V10.2.0 SCOPE per roadmap L1489-L1513:
- Phase A: ~30 lines (fail-loud guard, mandatory)
- Phase B: ~50-100 net lines (37 files, ~175-201 occurrences, B1/B2/B3 design choice)
- Phase C: ~30-50 lines (external-CWD regression scenario, mandatory)

DESIGN-SPACE FIXED: B1/B2/B3 only. No B4.

V10.0.0 RELIABILITY CONTRACT inviolate: dispatch_witness, ## Step Completion Invariants, harness 0-fail.

CONSUMER CONTEXT: claude plugin marketplace add <repo> clones to ~/.claude/plugins/cache/. Plugin runs from various CWDs; orchestrator path-resolution must work from out-of-repo CWD.
```

## {{SUCCESS_CRITERIA}}

Your output is DONE when:

1. **All 3 options analyzed** with strengths/weaknesses/example/Phase A interaction/Phase C coverage/forward-compat (6 dimensions each).
2. **Concrete file:line example** for each option (real path from skills/fix-bugs/SKILL.md or another canonical SKILL.md).
3. **Recommendation stated** with confidence 0.0-1.0 and falsifiable success metric.
4. **Persona consistency** -- your output reflects the persona-track assigned at dispatch.

End your output with exactly one of: `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, `BLOCKED`.