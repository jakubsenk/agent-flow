# Phase 2 — Research Synthesis: Final Recommendation

## Verdict: PARTIAL GO

## Executive Summary

All three agents converge on the same core finding: the current markdown + YAML frontmatter format is not a compromise — it is the correct and locked format for this plugin. Claude Code's runtime hard-requires `.md` file naming and YAML frontmatter for skill and agent discovery, making format migration structurally impossible without changes to the runtime itself. The only category where a format change produces material token savings is config templates (3% of the total budget), but even there, Agent 3 surfaced a critical scope problem: the format is enforced in five places across agents, skills, core, and docs, making it a MAJOR cross-cutting change rather than a simple template update. Two low-risk, high-clarity content improvements — scaffolder step renumbering and a contributor note in fix-bugs — are confirmed IN SCOPE for this forge run. The highest-priority structural improvement, Machine Output sections, requires a separate MAJOR version (7.0.0) due to the versioning policy and an unresolved design decision on whether skills parse the new section.

The contradiction between Agent 2 (implement Machine Output now) and Agent 3 (defer Machine Output) is resolved in favor of Agent 3: Agent 2's priority ranking is correct on impact order, but Agent 3's feasibility analysis identifies a blocking design question and correct MAJOR version trigger that Agent 2 did not fully account for.

## Format Migration Decision

| Category | Verdict | Reasoning |
|----------|---------|-----------|
| agents/ (21 files, ~31,800 tokens, 27%) | NO-GO | Hard runtime constraint: `.md` + YAML frontmatter non-negotiable. 87–93% is narrative prose — the program itself. Format change would degrade LLM instruction-following with ~2% token saving (~630 tokens). Net negative. |
| skills/ (28 files, ~75,500 tokens, 63%) | NO-GO | Same hard runtime constraint. 90–96% prose. Format change degrades complex pipeline branching logic at exactly the files where correct LLM behavior is most critical (fix-bugs, scaffold, implement-feature). ~1,500 token saving — not meaningful. |
| core/ (11 files, ~8,200 tokens, 7%) | NO-GO | Prose already beats YAML on token efficiency. The inline typing convention (`**field** (type, required): description`) encodes four attributes per phrase — more efficient than explicit YAML schema. Migration would increase token cost by 40–60%. |
| examples/configs/ (8 files, ~3,600 tokens, 3%) | DEFERRED (not this run) | Token savings are real (~35%, ~1,250 tokens across templates; ~260 tokens/run in consuming projects). However: the format is enforced in core/config-reader.md, agents/scaffolder.md, skills/onboard/SKILL.md, docs/architecture.md, and docs/guides/troubleshooting.md. Full implementation requires 12+ file changes, breaks all existing consumer configs, and triggers a MAJOR version bump. Not appropriate scope for this run. |

## Non-Format Improvements

| Improvement | Decision | Version Impact | Risk |
|-------------|----------|----------------|------|
| Add `## Machine Output` sections to triage-analyst, code-analyst, fixer, reviewer | DEFERRED — separate v7.0.0 | MAJOR (new output section in agent output format contract per versioning policy) | MEDIUM-HIGH — touches fixer loop and reviewer branching in fix-bugs and implement-feature; design question unresolved (do skills parse the new section or is it supplemental?) |
| Fix scaffolder.md duplicate `4b` step numbering | IN SCOPE | PATCH | VERY LOW — 2-line change, no downstream references to internal step labels confirmed by grep |
| Add contributor note to fix-bugs/SKILL.md explaining atomic-write repetition | IN SCOPE | PATCH | VERY LOW — 1-line HTML comment addition, documentation-only, no functional change |
| Add explicit Constraints rule in triage-analyst for Reproduction steps JSON format | OPTIONAL — can batch with PATCH | PATCH | LOW — additive Constraints line, reduces parse failures in browser-verifier/reproducer |
| Remove or enforce `Issues found: {count}` field in reviewer.md | OPTIONAL — can batch with PATCH | PATCH | LOW — single-line removal or constraint addition |
| Config template format migration (tables → colon notation) | DEFERRED — separate MAJOR | MAJOR | CRITICAL — breaks all existing consumer configs; requires 12+ file changes across 5 areas |
| File decomposition for scaffold/SKILL.md (925 lines) and fix-bugs/SKILL.md (770 lines) | DEFERRED — runtime research first | MINOR+ | HIGH — Claude Code multi-file skill loading capability unconfirmed; breaking risk if runtime does not support it |

## Implementation Scope for This Forge Run

Two changes are confirmed IN SCOPE. Both are PATCH-level, single-file edits with no downstream dependencies.

### Change A — Fix scaffolder.md duplicate step numbering

**File:** `agents/scaffolder.md`

**Edits:**
- Change `4b. Generate quality scorecard:` → `5. Generate quality scorecard:`
- Change `5. Output:` → `6. Output:`

Final sequential scheme: 1, 2, 3, 4, 5 (scorecard), 6 (output).

**Test verification:** `frontmatter-completeness.sh`, `scaffold-v2-spec-loop.sh`

---

### Change B — Add contributor note to fix-bugs/SKILL.md

**File:** `skills/fix-bugs/SKILL.md`

**Edit:** Insert one HTML comment near the first occurrence of "Follow atomic write protocol" (approx. line 459) explaining that the repetition is intentional LLM design, not accidental duplication. Do not consolidate or remove any instance.

Suggested text:
```
<!-- Contributor note: "Follow atomic write protocol from core/state-manager.md" appears at each state.json write step intentionally. This is LLM-directed repetition for reliable per-step compliance — not accidental duplication. Do not consolidate. -->
```

**Test verification:** `pipeline-consistency.sh`, `happy-path.sh`

---

**Optional additions (can be batched in same PATCH commit if done):**
- `agents/triage-analyst.md` — add one Constraints line: "MUST output Reproduction steps as a JSON array literal, not prose"
- `agents/reviewer.md` — remove `Issues found: {count}` field from output template OR add Constraints rule requiring count to match the listed issues

## Deferred Items

| Item | Why Deferred | Prerequisite Before Implementing |
|------|-------------|----------------------------------|
| Machine Output sections (triage-analyst, code-analyst, fixer, reviewer) | MAJOR version trigger (v7.0.0 required). Unresolved design question: do skills parse `## Machine Output` or is it supplemental documentation? If skills must be updated to use it, affects fix-bugs, implement-feature, fix-ticket, analyze-bug — high regression risk in the most complex branching logic. | (1) Decide: skills parse the new section actively, or it is a supplemental anchor only. (2) If active: design full parsing update for 4 skills. (3) Plan as dedicated v7.0.0 forge run. |
| Config template format migration (tables → colon notation) | MAJOR version trigger. Breaks all existing consumer configs on plugin update. Requires 12+ file changes: core/config-reader.md, agents/scaffolder.md, skills/onboard/SKILL.md, CLAUDE.md, docs/architecture.md, docs/getting-started.md, docs/guides/troubleshooting.md, potentially skills/migrate-config/SKILL.md, plus all 8 example templates. | (1) Design migration path for existing consumer configs. (2) Update migrate-config skill to convert table format → colon notation. (3) Plan as MAJOR release with migration guide in docs/guides/. |
| File decomposition (scaffold/SKILL.md 925 lines, fix-bugs/SKILL.md 770 lines) | Claude Code runtime capability for multi-file skill loading unconfirmed. If runtime requires single SKILL.md per directory, decomposition breaks skill registration silently. | (1) Research: does Claude Code support skill file includes or continuation loading? (2) If yes: define inter-phase dependency contracts for in-memory variables (tracker_type, sc_remote, etc. in scaffold Step 0-INFRA). (3) Plan as separate forge research task. |
| Bold text convention documentation | Phase 1 identified `**bold**` is overloaded for 5 structural roles. No consensus on whether a documented convention reduces LLM misinterpretation risk sufficiently to justify the documentation cost. | Validate whether LLM behavior actually diverges on bold token roles in practice. Low priority until evidence exists. |

## Key Insight

The plugin's token cost is an instructional prose cost, not a serialization overhead cost — and the only material structural risk in the current format is silent pipeline branching failures caused by unschematized machine-readable tokens (APPROVE/REQUEST_CHANGES/BLOCK, FULFILLED/PARTIALLY/NOT ADDRESSED, NEEDS_DECOMPOSITION, Quality gate: UNCLEAR) embedded in prose output templates with no schema enforcement. Format migration solves nothing. Fixing the machine-readable token fragility solves the actual highest-risk problem — but that fix is a MAJOR version event that must be scoped independently.

## Phase 3 Guidance

The brainstorm phase should focus on:

1. **Machine Output section design** — This is the highest-priority deferred item. The brainstorm should answer the one unresolved design question: "Do orchestrating skills actively prefer `## Machine Output` over prose parsing, or does the new section serve only as a reliable supplemental anchor?" Both options have tradeoffs (skill complexity vs. reliability guarantee). A concrete interface proposal — exact key names, position in template, parsing instruction to skills — is needed before any implementation planning.

2. **v7.0.0 scope boundary** — If Machine Output is confirmed for v7.0.0, the brainstorm should determine whether any of the deferred PATCH-level improvements (triage-analyst Reproduction steps constraint, reviewer Issues found fix) should be pulled into v7.0.0 as a bundle, or released earlier as a standalone PATCH (v6.5.1).

3. **Config migration path design** — The brainstorm should assess whether `Key: Value` colon notation migration is worth a MAJOR release given the modest token savings. If the user's primary motivation is human editability (not token savings), there may be a lighter-weight approach — e.g., documenting colon notation as an accepted alternative format in core/config-reader.md without changing the canonical prescription, making it a MINOR or PATCH change instead of MAJOR.

The brainstorm does NOT need to re-examine format migration for agents, skills, or core — those questions are closed.
