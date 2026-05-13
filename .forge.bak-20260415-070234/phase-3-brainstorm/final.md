# Phase 3 — Brainstorm: Judge Verdict

## Scoring Matrix

| Topic | Token Economist | Quality Advocate | Pragmatic Maintainer | Winner |
|-------|----------------|-----------------|---------------------|--------|
| Agent definitions | 4/5 | 5/5 | 4/5 | Quality Advocate |
| Config templates | 5/5 | 3/5 | 4/5 | Token Economist |
| Core contracts | 4/5 | 5/5 | 4/5 | Quality Advocate |
| Skill files | 4/5 | 5/5 | 5/5 | Pragmatic Maintainer |
| Output templates | 5/5 | 4/5 | 5/5 | Token Economist + Pragmatic Maintainer (split) |

## Per-Topic Verdicts

### Topic 1: Agent Definitions

**Winner: Quality Advocate (5/5)**

All three agents reach the same conclusion — NO-GO on format change — but the Quality Advocate provides the most rigorous justification. The argument about `## Constraints` as a semantic signal activating behavioral restriction framing (trained on millions of instructional documents) versus `constraints:` activating data-description framing (trained on configuration files) is the strongest individual argument in the entire brainstorm. It goes beyond token counting to identify a real comprehension mechanism.

The Token Economist earns credit for intellectual honesty — conceding cleanly against their own thesis with measured data (87-93% prose, 2% overhead, ~630 tokens). The Pragmatic Maintainer's "show me a pipeline failure" challenge is pragmatically sound but less analytically deep.

**Recommendation:** No change to agent definitions. The format is the product.

### Topic 2: Config Templates

**Winner: Token Economist (5/5)**

This is the most contested topic and the one where the verdict matters most. All three agents agree on the data: ~35% overhead, ~260 tokens/run in consumers, 12+ file blast radius. They disagree on what to do about it.

The Token Economist wins because of one decisive move: reframing the version impact. The research and the Pragmatic Maintainer both classified the config change as MAJOR. The Token Economist correctly identified that adding dual-format support (accept both tables AND colon notation) while updating examples to prefer the new format is a MINOR change, not MAJOR. No existing consumer config breaks. The LLM reads both formats natively. The "breaking change" only exists if you remove table support, which nobody is proposing.

The Quality Advocate's strongest counter — the `State transitions` key containing colons inside colon notation — is a legitimate concern but not fatal. The value `In Progress: add label:in-progress, Blocked: add label:blocked` has four colons serving different roles. However, the same ambiguity exists TODAY in the table cell, and the LLM already handles it correctly because the section heading provides context. The colon notation does not make this worse — the ambiguity is inherent in the value, not the container format.

The Pragmatic Maintainer's "has anyone complained?" test is reasonable as a conservative filter, but it sets the bar too high for improvements that compound over time. Nobody complains about a 260-token tax per run because it is invisible. That does not mean it is not real.

However, I temper the Token Economist's urgency. The 1.9 million tokens/year figure assumes a full 15-section config read 20 times daily for 365 days. That is an upper bound, not a typical case. The realistic saving for a moderate user (10 runs/day, 10-section config) is closer to 500,000 tokens/year — still meaningful, but not the headline number.

**Recommendation:** Implement dual-format support as MINOR change. Update examples to colon notation. Do NOT remove table support. This is NOT in scope for the current v6.5.1 PATCH but should be the next planned MINOR release.

### Topic 3: Core Contracts

**Winner: Quality Advocate (5/5)**

All three agents agree: NO-GO. The data is unambiguous — YAML schema would increase token cost by 40-60%. The Quality Advocate's walkthrough of the state-manager write process (converting natural-language conditionals into a YAML condition/action tree) is the most concrete demonstration of why structured formats fail for procedural content. The Token Economist concedes "completely" and the Pragmatic Maintainer calls it "optimization noise." When all three agree and the data supports them, the verdict is straightforward.

**Recommendation:** No change to core contracts. The inline typing convention is already optimal.

### Topic 4: Skill Files

**Winner: Pragmatic Maintainer (5/5)**

The Quality Advocate makes the strongest analytical argument (numbered lists match training data distribution; the branching logic in fix-bugs is imperative pseudocode that cannot be expressed in YAML without inventing a custom DSL). But the Pragmatic Maintainer adds the critical practical dimension: the real problem is file SIZE (925 lines, 770 lines), not file FORMAT, and the solution is blocked on an unanswered runtime question.

The Token Economist pivots correctly from format change to content restructuring (boilerplate extraction, file decomposition), estimating 5,000-8,000 token savings. This is a valuable insight. But the Pragmatic Maintainer's response — "open a research task, do not speculate" — is the right call for this run. Decomposing a 925-line file based on an assumption about Claude Code's multi-file loading capability could break skill registration silently with no error message. That risk assessment is correct and decisive.

The Token Economist's boilerplate extraction idea (the 16x "Follow atomic write protocol" repetition) is addressed by the Pragmatic Maintainer's more nuanced response: the repetition is intentional LLM-directed design, not accidental duplication. Adding a contributor note to prevent well-meaning cleanup is the right intervention — not extracting the repetition.

**Recommendation:** No format change. Add contributor note about intentional repetition (PATCH). Open a research task on multi-file skill loading before any decomposition work.

### Topic 5: Output Templates

**Winner: Token Economist and Pragmatic Maintainer (split verdict, 5/5 each)**

This is where the brainstorm produces its most valuable output. All three agents agree on the diagnosis: machine-readable tokens embedded in prose output (APPROVE, REQUEST_CHANGES, BLOCK, FULFILLED, NEEDS_DECOMPOSITION, Quality gate: UNCLEAR) are the highest actual risk in the current format. Silent pipeline branching failures from token drift are not theoretical — they are an inherent fragility of string-matching prose output.

The Token Economist wins on the design proposal. The `## Machine Output` section as flat `key: value` pairs (not JSON, not full YAML) is the right format choice. It is grep-parseable, naturally generated by the LLM, and avoids the JSON escaping failures the Quality Advocate correctly warns about. The concrete 4-line example (`verdict: APPROVE`, `ac_fulfilled: 3/4`, `issues_count: 0`) is clean and actionable.

The Pragmatic Maintainer wins on the implementation strategy. The unresolved design question — do skills parse `## Machine Output` actively or is it supplemental? — IS load-bearing. The Pragmatic Maintainer correctly identifies that the supplemental approach gives marginal benefit while the active parsing approach requires touching the 5 hardest files in the plugin. The right answer (active parsing) demands a dedicated v7.0.0 scope.

The Pragmatic Maintainer also identifies the best immediate action: add explicit token-spelling constraints to agent definitions as a PATCH. "MUST use exactly one of: APPROVE, REQUEST_CHANGES, BLOCK as the Verdict value — no variations, no additional qualifiers." This reduces drift probability NOW with zero blast radius, buying time until v7.0.0 is ready.

The Quality Advocate's point about JSON escaping failures is well-taken and supports the Token Economist's choice of flat key-value over JSON. But the Quality Advocate's overall position — keep everything as-is, add Machine Output as markdown bullet lists — undersells the importance of active skill parsing. A supplemental anchor that skills ignore is documentation, not infrastructure.

**Recommendation:** Two-phase approach. PATCH (v6.5.1): add token-spelling constraints to reviewer, fixer, acceptance-gate, spec-reviewer agents. MAJOR (v7.0.0): implement `## Machine Output` sections with flat key-value format AND update skills to parse them actively as authoritative signal, with prose parsing as fallback.

## Unified Recommendation

### For This Forge Run (v6.5.1 PATCH)

Execute these changes, ordered by priority:

1. **Fix scaffolder.md duplicate step numbering** — Change `4b.` to `5.` and `5.` to `6.` in `agents/scaffolder.md`. Correctness fix, 2-line edit, no dependencies.

2. **Add contributor note to fix-bugs/SKILL.md** — Insert HTML comment near first occurrence of "Follow atomic write protocol" explaining intentional repetition. Prevents misguided cleanup.

3. **Add token-spelling constraints to agents** — Add explicit Constraints lines to:
   - `agents/reviewer.md`: "MUST use exactly one of: APPROVE, REQUEST_CHANGES, BLOCK as the Verdict value. No variations, no additional qualifiers."
   - `agents/fixer.md`: "MUST use the exact string NEEDS_DECOMPOSITION when signaling decomposition need. No variations."
   - `agents/acceptance-gate.md`: "MUST use exactly FULFILLED, PARTIALLY, or NOT ADDRESSED for each AC verdict. No variations."
   - `agents/spec-reviewer.md`: "MUST use exactly REVISE or APPROVE as the verdict. In --verify mode, MUST use exactly IMPLEMENTED, PARTIALLY, or MISSING per requirement."

4. **Add JSON constraint to triage-analyst** — Add Constraints line: "MUST output Reproduction steps as a JSON array literal, not prose."

5. **Clean up reviewer Issues found field** — Remove `Issues found: {count}` from reviewer output template (the skill can count issues itself; one fewer thing to get wrong).

All five changes are PATCH-level, independent, and zero-blast-radius.

### For Future MINOR Release (v6.6.0 — Config Dual-Format)

1. Update `core/config-reader.md` to explicitly accept both `| Key | Value |` table format AND `Key: Value` colon notation.
2. Update all 8 `examples/configs/*.md` templates to use colon notation as the canonical examples.
3. Update `agents/scaffolder.md` to generate colon notation for new projects.
4. Update `skills/onboard/SKILL.md` to generate colon notation.
5. Update docs (architecture.md, troubleshooting.md, CLAUDE.md) to show colon notation as preferred, table format as accepted alternative.
6. Do NOT remove table format support. Existing consumer configs continue working unchanged.

This is a MINOR change because no existing consumer config breaks. The contract expands (accepts more formats), it does not narrow.

### For Future v7.0.0 (Machine Output Design)

1. **Design decision (must be resolved first):** Skills parse `## Machine Output` actively as the authoritative signal. Prose parsing becomes fallback only. This is the only option that justifies the MAJOR version bump — a supplemental-only section adds cost without solving the fragility problem.

2. **Format:** Flat `key: value` pairs under a `## Machine Output` heading. Not JSON (escaping risk). Not YAML (parsing complexity). Not markdown bullet lists (unnecessary prefix overhead).

3. **Agents to update:** triage-analyst, code-analyst, fixer, reviewer, acceptance-gate, spec-reviewer (6 agents that produce machine-parsed tokens).

4. **Skills to update:** fix-bugs, fix-ticket, implement-feature, scaffold, analyze-bug (5 skills that consume machine tokens). Each skill's parsing logic changes from prose string-matching to heading-anchored key extraction with prose fallback.

5. **Key design questions to resolve before implementation:**
   - Exact key names and allowed values for each agent's Machine Output section (create a registry).
   - Error handling: what does a skill do when `## Machine Output` is missing but prose tokens are present? (Answer: use prose fallback, log warning.)
   - Should Machine Output be validated against a schema at test time? (Answer: yes, add test scenarios.)

6. **Scope:** Dedicated forge run. Do not bundle with unrelated changes.

### Permanently Rejected

| Proposal | Why Rejected |
|----------|-------------|
| YAML body for agent definitions | 87-93% is instructional prose. YAML degrades LLM comprehension of conditional logic, behavioral constraints, and sequential processes. Token savings (~2%) do not justify comprehension risk. Claude Code runtime hard-requires .md format regardless. |
| YAML schema for core contracts | Would INCREASE token cost by 40-60%. The inline typing convention is already more efficient than explicit schema. Strictly worse on every axis. |
| Full YAML/JSON conversion of skill files | 90-96% is procedural prose with branching logic. No structured format can express imperative pseudocode with conditionals more efficiently than numbered markdown lists. The LLM's training data overwhelmingly uses markdown for instructional content. |
| JSON output format replacing markdown output | Introduces escaping failures, structural rigidity (trailing commas), and downstream parsing complexity. The LLM generates markdown natively; forcing JSON output adds a format-translation step with non-zero failure rate. |
| Removing table format support for config (hard cutover) | Breaks every existing consumer config. Unnecessary when dual-format support achieves the same goal without breakage. |
| Bold text convention documentation | No demonstrated pipeline failure from bold-text ambiguity. Documentation of a convention nobody needs documented is negative value. |

## The Verdict in One Sentence

The plugin's format is fundamentally correct — ship five small PATCH fixes now (step numbering, contributor note, token-spelling constraints, triage JSON constraint, reviewer field cleanup), plan dual-format config as the next MINOR, and design Machine Output with active skill parsing as a dedicated v7.0.0 scope.
