# Agent 3 — The Pragmatic Maintainer

## Core Thesis

The research phase answered the question definitively: format migration is structurally impossible for agents and skills (runtime hard-locks `.md` + YAML frontmatter), economically pointless for core (prose is already more token-efficient than YAML schema), and disproportionately expensive for config templates (12+ file blast radius for 3% budget savings). The format debate is closed. The only remaining questions are about content improvements, and those must pass a simple test: **is there a demonstrated problem causing real pipeline failures, or are we polishing a surface that already works?**

---

## Topic 1: Agent Definitions

**Position: No change. The current format is the product.**

21 agent files. All follow the same structure. All have YAML frontmatter that Claude Code requires. 87-93% of the content is instructional prose — the actual behavioral programming of the LLM. You cannot "optimize" prose into a more compact format without degrading the instructions.

The research confirmed agent definitions carry ~2% format overhead. Reformatting would save approximately 630 tokens across all 21 files while introducing risk of degraded instruction-following. That is not a tradeoff any rational maintainer accepts.

If someone argues "but the bold-text convention is overloaded for 5 structural roles" — show me a pipeline failure caused by bold-text ambiguity. Until then, it is a theoretical concern that does not justify touching 21 files to document a convention that Claude already handles correctly in practice.

**Verdict: Do nothing.**

---

## Topic 2: Config Templates

**Position: Not now, and probably not ever as a standalone change.**

The numbers: 35% savings on 3% of the token budget. That is ~1,250 tokens across 8 template files, and ~260 tokens per consuming project at runtime. Against this you have:

- 12+ files to update (core/config-reader.md, agents/scaffolder.md, skills/onboard/SKILL.md, CLAUDE.md, docs/architecture.md, docs/guides/troubleshooting.md, all 8 templates, potentially migrate-config)
- A MAJOR version bump (breaks every existing consumer's Automation Config)
- A migration path that needs designing and testing
- The migrate-config skill needs updating to handle format conversion

The research correctly identified this as the highest blast-radius change in the entire proposal. For 260 tokens per run.

The one argument I take seriously: human editability. Tables are harder to write by hand than `Key: Value` pairs. But this is a developer experience issue, not a format efficiency issue. If we want to improve DX, the lighter-weight approach is to accept both formats in config-reader.md (document colon notation as an alternative), which is a MINOR change, not a MAJOR one. Even then — has anyone actually complained about the table format? The onboard wizard generates it automatically. The templates provide copy-paste examples.

**Verdict: If DX complaints materialize, add dual-format support as MINOR. Do not migrate the canonical format.**

---

## Topic 3: Core Contracts

**Position: No change. This is optimization noise.**

32KB total across 11 files. The research found that the inline typing convention (`**field** (type, required): description`) is already more token-efficient than explicit YAML schema by 40-60%. Migrating to YAML would INCREASE token cost.

There is nothing to do here. The current format is already the optimal one. Anyone arguing for changes in core is arguing against their own data.

**Verdict: Do nothing.**

---

## Topic 4: Skill Files

**Position: The real problem is file size, not format. But the solution is blocked.**

scaffold/SKILL.md is 925 lines. fix-bugs/SKILL.md is 770 lines. These are the two largest files in the plugin. The research correctly identifies that format changes would save ~1,500 tokens across all 28 skill files — meaningless when scaffold alone is 49KB of dense pipeline branching logic.

The actual problem: a 925-line file is hard to maintain, hard to review, and hard to reason about. But the solution — decomposing into multiple files — is blocked on a fundamental question: does Claude Code support multi-file skill loading? If the runtime requires exactly one SKILL.md per skill directory, decomposition breaks skill registration silently with no error message.

This needs a research task, not a brainstorm position. Someone needs to test whether Claude Code can load `SKILL.md` that `include`s or references other files in the same directory. Until that question is answered, any discussion of file decomposition is premature.

In the meantime: the files work. They are large but they are correct. Large and correct beats small and broken.

**Verdict: Open a research task on Claude Code multi-file skill loading. Do not touch skill files until the answer is known.**

---

## Topic 5: Output Templates / Machine-Readable Tokens

**Position: This is the one real problem. But the solution needs careful design, not a quick fix.**

I agree with the research synthesis: the highest actual risk in the current format is silent pipeline branching failures caused by unschematized machine-readable tokens embedded in prose output templates. The tokens in question:

- `APPROVE` / `REQUEST_CHANGES` / `BLOCK` (reviewer, acceptance-gate)
- `FULFILLED` / `PARTIALLY` / `NOT ADDRESSED` (reviewer, acceptance-gate)
- `NEEDS_DECOMPOSITION` (fixer)
- `Quality gate: UNCLEAR` / `Quality gate: PASS` (triage-analyst)
- `REVISE` / `APPROVE` (spec-reviewer)
- `IMPLEMENTED` / `PARTIALLY` / `MISSING` (spec-reviewer --verify mode)

These tokens are consumed by skills through string matching in prose output. If an agent's output drifts — uses "APPROVED" instead of "APPROVE", or "NOT_ADDRESSED" instead of "NOT ADDRESSED" — the pipeline silently takes the wrong branch or falls through to a default. That is a real failure mode, not a theoretical one.

However, I disagree with the idea of rushing to implement `## Machine Output` sections. Here is why:

**The unresolved design question is load-bearing.** Do orchestrating skills actively parse `## Machine Output` as the authoritative signal, replacing their current prose-scanning logic? Or is the new section supplemental documentation that helps the LLM be more consistent but skills still scan prose?

- If skills parse it: you need to update fix-bugs, fix-ticket, implement-feature, scaffold, analyze-bug — the five most complex and most critical skill files. A regression in any of them breaks the entire pipeline. This is a HIGH risk change that demands its own forge run with full test coverage.
- If it is supplemental: you get some consistency improvement from the LLM seeing the structured section, but skills still rely on prose scanning, so the fundamental fragility remains. The cost-benefit is marginal.

The correct answer is: skills should parse `## Machine Output` as the authoritative signal. But this means touching the 5 hardest files in the plugin, which means a dedicated v7.0.0 scope with its own test plan.

**What we can do now (PATCH-level):** Add explicit constraints in agent definitions that nail down the exact token spelling. For example, triage-analyst already has the `UNCLEAR` token documented clearly (lines 42-44 in the current file). The reviewer could benefit from a similar explicit constraint: "MUST use exactly one of: APPROVE, REQUEST_CHANGES, BLOCK as the Verdict value — no variations, no additional qualifiers." This is a zero-risk, zero-blast-radius change that reduces drift probability without requiring any skill file changes.

**Verdict: Add token-spelling constraints to agents as PATCH. Design `## Machine Output` as v7.0.0 scope with full skill parsing update.**

---

## Non-Format Improvements: Prioritized Assessment

### 1. Scaffolder duplicate 4b fix — DO IT

The step numbering goes 1, 2, 3, 4, 4b, 5. It should be 1, 2, 3, 4, 5, 6. This is a 2-line edit with no downstream dependencies (confirmed by grep — no external references to internal step labels). It is a correctness fix. Do it.

### 2. Atomic write boilerplate note — DO IT

The phrase "Follow atomic write protocol from `core/state-manager.md`" appears 16 times in fix-bugs/SKILL.md. This is intentional LLM-directed repetition, not accidental duplication. A one-line HTML comment explaining this to future contributors costs nothing and prevents a well-meaning contributor from "cleaning up" the repetition and breaking state management reliability. Do it.

### 3. Triage-analyst reproduction steps JSON constraint — DO IT (optional batch)

Adding one line to Constraints: "MUST output Reproduction steps as a JSON array literal, not prose." This tightens the contract between triage-analyst and browser-verifier/reproducer. Low risk, low effort. Batch it with the PATCH if convenient.

### 4. Reviewer `Issues found: {count}` field — DO IT (optional batch)

This field exists in the output template but has no constraint enforcing that the count matches the actual listed issues. Either remove the field (it adds no value — the skill can count the issues itself) or add a constraint. I lean toward removal — one less thing to get wrong, one less token per reviewer output. Batch with the PATCH.

### 5. Machine Output sections — DEFER to v7.0.0

As argued above. This is the right solution to the right problem, but it requires a dedicated scope with full skill parsing updates. Do not rush it into a PATCH.

### 6. Config format change — DEFER indefinitely

As argued above. The cost-benefit does not justify a MAJOR version bump. Revisit only if dual-format support becomes a DX priority.

### 7. File decomposition — DEFER pending research

As argued above. Blocked on runtime capability confirmation. Open a research task, do not speculate.

### 8. Bold text convention documentation — DO NOT DO

No demonstrated problem. No evidence of LLM misinterpretation. Documentation of a convention that nobody needs documented is negative value — it is one more thing to maintain that helps nobody.

---

## The v7.0.0 Scope Question

The research asks whether PATCH-level improvements (items 1-4 above) should be bundled into v7.0.0 or released as a standalone v6.5.1.

**Release them as v6.5.1 now.** They are independent of Machine Output sections. They have zero interaction with the v7.0.0 changes. Holding back zero-risk correctness fixes to batch them with a high-risk MAJOR release is backwards — it means users wait longer for easy wins, and the MAJOR release gets cluttered with unrelated changes that make regression debugging harder.

Ship the easy stuff early. Ship the hard stuff when it is ready.

---

## The Config Migration Path Question

The research asks whether the brainstorm should design a migration path for table-to-colon config notation.

**No.** The migration path question is premature because the migration itself is not justified. If we ever decide to do this (which I doubt), the path is obvious: (1) add dual-format support to config-reader.md, (2) update migrate-config skill to offer conversion, (3) deprecate table format in documentation, (4) remove table support in the next MAJOR. But designing this path now is planning for a journey we have no reason to take.

---

## Summary: What to Do

| Action | Version | Risk | Do When |
|--------|---------|------|---------|
| Fix scaffolder step numbering (4b -> 5, 5 -> 6) | PATCH (v6.5.1) | Very low | This forge run |
| Add contributor note re: atomic write repetition | PATCH (v6.5.1) | Very low | This forge run |
| Add JSON constraint to triage-analyst reproduction steps | PATCH (v6.5.1) | Low | This forge run (optional batch) |
| Remove or constrain reviewer `Issues found: {count}` | PATCH (v6.5.1) | Low | This forge run (optional batch) |
| Add explicit token-spelling constraints to reviewer, fixer, acceptance-gate | PATCH (v6.5.1) | Low | This forge run (optional batch) |
| Design and implement `## Machine Output` sections | MAJOR (v7.0.0) | Medium-High | Dedicated forge run |
| Config format migration | MAJOR (never?) | Critical | Only if DX complaints materialize |
| Skill file decomposition | MINOR+ | High | After runtime research confirms feasibility |
| Bold text convention docs | None | N/A | Never (no demonstrated problem) |

The pragmatic path: ship 2-5 small improvements now as v6.5.1. Plan Machine Output as v7.0.0. Defer everything else until evidence demands action.
