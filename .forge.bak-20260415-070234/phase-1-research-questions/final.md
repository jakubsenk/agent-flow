# Phase 1 — Research Questions: Synthesis

## Executive Summary

The current mixed format — YAML frontmatter plus markdown body — is not a compromise; it is the correct and near-optimal format for this plugin. Claude Code's plugin runtime imposes a hard requirement on `.md` file naming and YAML frontmatter for both skills and agents, making format migration away from markdown structurally impossible without runtime-level changes. Across the 119,100-token corpus, the only content type where an alternative format would produce material token savings is the `| Key | Value |` table pattern used in config files (~35% savings), but this applies to only 3% of the total token budget. Markdown with YAML frontmatter maximizes LLM instruction-following fidelity, human maintainability, and diff readability simultaneously. The real pain points are not serialization format issues — they are structural scale problems (scaffold/fix-bugs files exceeding 700 lines), ambiguous machine-readable output tokens, and inconsistent step-numbering conventions in large skill files.

---

## Q1: Token Economics

**Corpus baseline:** 119,100 estimated tokens across 68 files (agents: ~31,800 tokens; skills: ~75,500 tokens; core: ~8,200 tokens; examples/configs: ~3,600 tokens). Skills dominate at 63% of the plugin token budget.

**Format efficiency findings by content type:**

| Content Type | Current Format | Best Alternative | Savings |
|---|---|---|---|
| Agent/skill YAML frontmatter | YAML | YAML | 0% — already optimal |
| Process steps / narrative instructions | Markdown prose | No change | 0% — prose is optimal |
| Output templates (structured reports) | Markdown fenced block | YAML | ~18–25% |
| Config key→field contract mappings (config-reader style) | Prose with arrow notation | Prose (stays) | 0% — prose beats YAML by 22–36% |
| Contract typed fields (Input/Output contracts) | Prose (type + desc) | Prose (stays) | 0% — prose beats YAML by 43–63% |
| Config data tables (Key\|Value tables) | Markdown tables | YAML | **~35%** |

**Key finding:** The `| Key | Value |` markdown table format in config files is the only content type where a format change produces material savings. It costs ~40% more tokens than `Key: Value` colon notation or YAML. However, this format affects only the examples/configs category (3,600 tokens / ~3% of total budget). Even a 35% saving yields ~1,250 tokens across all 8 template files — real but not operationally significant for the plugin itself.

**Practically significant target:** The consuming project's CLAUDE.md config section, which is read on every pipeline invocation. Converting those `| Key | Value |` tables to `Key: Value` colon notation would save ~260 tokens per run, compounding across all pipeline executions.

**Counterintuitive result:** The prose arrow notation used in `core/config-reader.md` (`key → field (default: N)`) encodes more information per token than YAML or JSON for key-value contract documentation, because English grammar's implicit subject-predicate-object structure has lower overhead than formal schema syntax when field names are natural-language phrases.

**The dominant token cost driver is instructional prose volume, not format overhead.** Skills alone are 63% of the budget because they contain extensive pipeline logic, conditional branches, and agent invocation sequences. Reducing token cost requires reducing instruction complexity — a content question, not a serialization question.

---

## Q2: LLM Comprehension Quality

**Markdown is the highest-fidelity format for procedural instruction-following by LLMs.** This is not a subjective preference — it reflects the training data distribution. LLMs have been trained on vast quantities of markdown documentation, tutorials, and specifications. Numbered lists and headed sections activate procedural reasoning; the model follows them sequentially rather than treating them as data to extract.

**YAML for procedural content degrades instruction-following.** LLMs are trained to treat YAML as data to read and extract, not instructions to execute step by step. A process encoded as `- step: "Read bug details"` loses the sequential imperative framing that cues procedural behavior. In complex decision trees (like the fixer loop or scaffold infra setup), YAML encoding would cause the LLM to extract values rather than follow the logic.

**JSON is worse than YAML for this use case.** JSON has no concept of ordered human-readable steps. Its verbosity (keys, quotes, commas, brackets) introduces visual noise that competes with the actual instruction content for the model's attention.

**YAML frontmatter is optimal for metadata extraction** (5–7 flat scalar keys). The `---` delimiter creates an unambiguous metadata/content boundary. Claude Code's well-established convention for YAML frontmatter (shared with Jekyll, Hugo, MDX) means the LLM has strong priors for parsing it without conflating it with body content.

**The `| Key | Value |` table format is reliable for structured extraction** because rigid column structure combined with section heading context provides two independent signals. The redundancy reduces hallucination risk in config parsing.

**Known failure modes in the current format:**
- Deeply nested bullet lists (4+ levels) can cause step-number confusion in large skill files. `fix-bugs/SKILL.md` steps 3a, 3b, 3b-tracker, 3c, 3d exhibit this.
- Inline code spans used as machine-readable tokens are fragile to case variation (e.g., `Unclear` vs. `UNCLEAR`). No schema enforcement exists.
- Fenced code blocks using `markdown` syntax inside a markdown document can cause the LLM to treat example output as an instruction to execute, particularly when the block contains `## Fix Report` (which looks like an active heading).
- HTML comment wrappers (`<!-- ... -->`) around optional config sections risk processing inactive content as active in some model configurations.
- `style:` frontmatter field influence on output tone is implicit and model-dependent — weak signal with no explicit reference in body.

---

## Q3: Ecosystem Compatibility

**This is a hard constraint. Markdown format is non-negotiable for the Claude Code plugin runtime.**

Evidence that markdown `.md` files are a hard requirement:

1. All 28 skills use exactly `skills/{name}/SKILL.md`. All 21 agents use `agents/{name}.md`. No alternative format exists anywhere in the corpus.
2. The `.agents-md/` tracking directory (containing `history.jsonl`) is named for markdown agents and exclusively records `.md` file paths with hash fingerprints.
3. The `disable-model-invocation: true`, `allowed-tools:`, and `argument-hint:` YAML frontmatter keys are Claude Code runtime directives that have no meaning outside YAML frontmatter — they cannot be expressed in a JSON body.
4. The plugin.json and marketplace.json contain only package-level metadata and do not specify format — meaning the format convention is baked into the Claude Code runtime itself, not configurable per-plugin.

**Format change impact table:**

| Change | Impact |
|--------|--------|
| Rename `SKILL.md` to `SKILL.yaml` | Skill not discovered — slash command fails to register |
| Remove YAML frontmatter from skill files | `name`, `allowed-tools`, `disable-model-invocation`, `argument-hint` not parsed — skill fails to register or registers with wrong capabilities |
| Remove YAML frontmatter from agent files | `name`, `model`, `description` not read — agent absent from Task tool picker |
| Convert agent body to JSON | LLM receives JSON instructions — procedural adherence degrades significantly |
| Convert skill body to YAML | LLM-invoked skills: instruction-following degrades; `disable-model-invocation` skills: no LLM impact but no benefit either |

**No format migration path away from markdown exists without changes to the Claude Code runtime itself.** This makes Q3 a resolved constraint: the current format is locked in place by the ecosystem.

---

## Q4: Hybrid Format Viability

**Per-category verdict:**

| Category | Structured % | Narrative % | Hybrid Viable? | Max Savings | Budget Share |
|---|---|---|---|---|---|
| agents/ (21 files, ~31,800 tokens) | 7–13% | 87–93% | No | ~2% per file | 27% of total |
| skills/ (28 files, ~75,500 tokens) | 4–10% | 90–96% | No | ~2% per file | 63% of total |
| core/ (11 files, ~8,200 tokens) | 15–25% | 75–85% | No — prose wins | ~0% (prose optimal) | 7% of total |
| examples/configs/ (8 files, ~3,600 tokens) | 85–92% | 8–15% | Yes | ~35% | 3% of total |

**Agents and skills:** The narrative IS the program. Process steps, conditional branches, agent invocation sequences, error handling prose — these are inherently language-dependent and cannot be compressed via format change without losing semantic fidelity. The structured fraction (7–13% for agents, 4–10% for skills) is too small to justify dual-format complexity.

**Core files:** Counterintuitively, the current prose format beats both YAML and JSON for contract documentation. The inline typing convention (`**field** (type, required): description`) collapses four attributes into one natural-language phrase, which is more token-efficient than explicit YAML schema. Hybrid would make core files larger and harder to read.

**Config templates:** The only category where hybrid is viable. At 85–92% structured content, the `| Key | Value |` table overhead is real (~35% savings available). However: (a) this is 3% of the plugin's token budget, (b) the markdown table format serves a human-editing function for users who must manually configure their CLAUDE.md, and (c) the human-readability benefit likely outweighs the token cost at this content volume.

**Single most impactful actionable change:** Switching from `| Key | Value |` markdown table format to `Key: Value` colon notation in config files. This saves ~35% on config tokens with minimal readability impact and would compound across consuming projects' CLAUDE.md pipeline reads.

---

## Q5: Human Maintainability

**Markdown is the clearly superior format for a no-build-system, no-linter plugin** maintained by contributors who edit files directly.

**Markdown advantages:**
- Natural reading flow with no structure decoding required
- Headings as visual anchors — contributors locate the right section in seconds
- Fenced code blocks allow embedded templates without escaping problems
- Numbered lists are trivially editable (add a line, renumber if needed)
- Diff readability is unambiguous — a single sentence change produces a single-line diff

**YAML body weaknesses for this use case:**
- Multi-level nesting (required for the scaffolder's 8-batch logic) has silent indentation errors that parse correctly but map to wrong parents
- Multi-line prose requires literal block scalars (`|`) or folded scalars (`>`) — unfamiliar to non-YAML-specialist contributors
- Embedding fenced code blocks requires careful escaping — error-prone even for experienced editors
- Diff readability degrades: a change to one sentence in a `|`-scalar block shows the entire block as modified

**JSON body weaknesses:**
- No comment support — all inline rationale notes would be lost
- No multi-line strings — embedded code blocks require `\n`-encoded strings
- Trailing comma errors are the most common editing mistake with no linter to catch them
- Noisy diffs from structural `}` and `]` tokens on their own lines

**Error rate ranking:** markdown tables (low) < YAML frontmatter 4 keys (very low) < YAML body for process steps (high) < JSON (highest)

**The one genuine markdown pain point:** The `| Key | Value |` table format requires manual column alignment for readability. Misaligned pipes are syntactically valid but visually degraded. This is the correct tradeoff — the error is cosmetic, not functional.

---

## Q6: Specific Problem Areas

Prioritized by impact (highest first):

**P1 — Machine-readable output tokens embedded in prose (cross-agent, HIGH reliability risk)**
The following tokens are parsed by orchestrating skills to make branching decisions but are embedded in prose-formatted markdown without schema enforcement:
- `Quality gate: UNCLEAR` (triage-analyst → fix-bugs step 2)
- `root cause confirmed: NO` (code-analyst → fix-bugs step 3)
- `## NEEDS_DECOMPOSITION` (fixer → fix-bugs step 4 — fragile to capitalization)
- `APPROVE / REQUEST_CHANGES / BLOCK` (reviewer → fixer loop)
- `FULFILLED / PARTIALLY / NOT ADDRESSED` (reviewer → acceptance-gate)

Case variation, surrounding punctuation, and template deviation all create potential silent parse failures. Recommended fix: add a `## Machine Output` section to each affected agent's output template containing only the machine-parsed tokens as bare key-value pairs on dedicated lines, separate from the prose sections.

**P2 — skills/scaffold/SKILL.md scale (925 lines, structural problem)**
The file exceeds working memory capacity for safe editing. Dependencies between Step 4 (line ~600) and Step 0-INFRA (line 60) are invisible across that distance. The root cause is not format but volume. File decomposition into phase files (infra-setup, spec-phase, implementation-phase, finalization) would address this more effectively than any serialization change.

**P3 — agents/scaffolder.md duplicate step numbering**
Two sections are labeled `4b` — one for CLAUDE.md generation and one for the quality scorecard. This creates LLM step-dependency ambiguity and contributor confusion. Correcting step numbering to be sequential and non-duplicated is a low-effort, high-clarity fix.

**P4 — skills/fix-bugs/SKILL.md repeated boilerplate (~200 lines)**
The phrase "Follow atomic write protocol from `core/state-manager.md`" appears at least 15 times. This repetition is correct for LLM clarity but makes the file harder to read for contributors navigating pipeline logic. A contributor-facing note at the top of the file explaining the repetition pattern would reduce cognitive load without removing any functional content.

**P5 — Config file compound cell values (state transitions)**
```
| State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked`, ... |
```
A key→value map encoded as a comma-separated string inside a pipe-delimited table cell. The colon is overloaded as both part of the label name and as the separator between name and action. Redesigning this as a sub-table or `Key: Value` colon notation would improve editability and reduce parse ambiguity.

**P6 — skills/scaffold/SKILL.md inconsistent pseudocode style**
Fenced pseudocode blocks (used for git commands) coexist with unfenced prose pseudocode (used for MCP downgrade logic). The inconsistency creates LLM reading uncertainty about whether content is procedural or descriptive. Standardizing to fenced blocks for all pseudocode would eliminate this.

**P7 — skills/fix-bugs/SKILL.md non-standard step labeling**
Steps 3a, 3b, 3b-tracker, 3c, 3d break the alphabetical sub-step pattern. The `3b-tracker` suffix is undocumented. A contributor adding a new sub-step must infer the naming convention. Adding a one-line convention comment at the first step would resolve this.

**P8 — triage-analyst Reproduction steps field: structured data in a prose field**
The `Reproduction steps` field expects a JSON array literal (`[{action: "navigate", target: "/"}, ...]`) embedded in a markdown bullet. Downstream agents (browser-verifier, reproducer) parse this. The format is documented by one example but has no formal constraint. A clearer prose constraint ("MUST output as a JSON array literal, not prose") would reduce parse failures.

**P9 — reviewer.md `Issues found` field creates consistency trap**
`Issues found: {count}` is decorative (skills count issues from the list, not this field) but a reviewer that lists 3 issues but writes `Issues found: 2` produces subtly wrong output with no detection mechanism. Either remove the field or add a Constraints rule requiring it to match the list count.

---

## Q7: Output Format Templates

**Current pattern:** All agent output templates use ` ```markdown ` fenced code blocks inside the Process section, containing `{placeholder}` tokens for variable substitution. This is a consistent and functional pattern.

**Template inventory:**

| Agent | Template Section | Heading Token | Machine-Parsed? |
|---|---|---|---|
| triage-analyst | `## Triage Analysis` | Quality gate verdict | Yes — branching signal |
| code-analyst | `## Impact Report` | `root cause confirmed: YES/NO` | Yes — branching signal |
| fixer | `## Fix Report` or `## NEEDS_DECOMPOSITION` | Heading itself | Yes — loop control |
| reviewer | `## Code Review` | `Verdict: APPROVE/REQUEST_CHANGES/BLOCK`, `FULFILLED/PARTIALLY/NOT ADDRESSED` | Yes — loop control + gate input |

**Format effectiveness per template:**

- **Fix Report (fixer.md):** Simplest and most reliably produced. Five prose fields with two fixed-value fields (Build, Tests). No structural change needed. The `## NEEDS_DECOMPOSITION` alternative heading is the reliability risk — case sensitivity makes it fragile.
- **Triage Analysis (triage-analyst.md):** Generally reliable. The `Reproduction steps` JSON array field is the weak point (see Q6 P8). The dual structure (prose field + embedded JSON literal) is the fundamental tension.
- **Impact Report (code-analyst.md):** The `Reproduction trace` format (`Step N: {step} → system state: {data} → code: {method} → input: {args} → output: {result}`) has a cross-field consistency constraint (`root cause confirmed` in the trace must match the Sanity check verdict) with no enforcement mechanism. The `root cause confirmed: NO` token is a critical branch signal.
- **Code Review (reviewer.md):** Highest machine-parsing dependency. `Verdict` field is parsed as a prose bullet — deviation from the three allowed values (`APPROVE`, `REQUEST_CHANGES`, `BLOCK`) causes silent skill logic failures. `AC Fulfillment` section omission when AC exist leaves the acceptance-gate without input, with no defined fallback.

**Recommended targeted intervention (does not require format change):**
Add a `## Machine Output` section at the end of each affected agent's output template containing bare key-value pairs for all machine-parsed tokens. Example for reviewer:
```
## Machine Output
verdict: APPROVE
ac_fulfilled_count: 3
```
This preserves the existing prose template (consumed by next agents as context), adds reliable parsing anchors for skill branching logic, and requires no ecosystem format change. It is smaller and lower-risk than adopting YAML schemas while addressing the actual reliability gap.

---

## Consensus Matrix

| Question | Finding | Confidence | Actionable? |
|---|---|---|---|
| Q1: Token Economics | YAML frontmatter and prose are already near-optimal. `\| Key \| Value \|` tables are the only material inefficiency (~35% savings, affects 3% of budget). | High | Yes — switch config tables to `Key: Value` colon notation |
| Q2: LLM Comprehension | Markdown + YAML frontmatter maximizes instruction-following fidelity. YAML/JSON bodies degrade procedural adherence. | High | No change needed; document failure modes |
| Q3: Ecosystem Compatibility | `.md` file format and YAML frontmatter are hard runtime requirements. No migration path exists. | High (hard constraint) | Constraint — blocks all format migration proposals |
| Q4: Hybrid Format Viability | Hybrid not viable for agents/skills/core (narrative dominates). Viable but low-value for config templates. | High | Optional — colon notation in configs is the practical win |
| Q5: Human Maintainability | Markdown is clearly superior for a no-build-system, no-linter plugin. YAML/JSON bodies have high error rates for complex nested content. | High | No change needed to format; fix scaffolder step numbering |
| Q6: Specific Problem Areas | Machine-readable token fragility is the highest-priority structural risk. Scale of scaffold/fix-bugs files is second. | High | Yes — add `## Machine Output` sections; decompose large files |
| Q7: Output Format Templates | Templates are functional; machine-parsed tokens embedded in prose are fragile to deviation. `## Machine Output` section is targeted fix. | Medium-High | Yes — add machine output sections to affected agents |

---

## Key Tensions

**Tension 1: Token efficiency vs. human editability in config files**
Agent 1 found that YAML saves ~35% on config token cost. Agent 3 found that YAML body editing has high error rates for contributors unfamiliar with indentation-sensitive syntax. The resolution: `Key: Value` colon notation (not full YAML) captures most of the token savings while preserving edit simplicity. Neither agent explicitly proposed this compromise — it is the synthesis conclusion.

**Tension 2: Machine-readable tokens vs. prose output templates**
Agent 3 identified that reviewer/code-analyst templates serve two audiences (next agent as prose context, orchestrating skill as structured parser) with conflicting format needs. Agent 2 confirmed that switching to pure YAML schemas would degrade LLM instruction-following. The resolution is a non-format change: adding a dedicated `## Machine Output` section that does not require changing the existing prose template format.

**Tension 3: Comprehensiveness vs. navigability in large skill files**
Agents 2 and 3 both noted that scaffold (925 lines) and fix-bugs (770 lines) are at the edge of LLM working memory for complex edits. The repetition in fix-bugs (state.json instructions ~15 times) is simultaneously the correct LLM design pattern and a contributor readability problem. No format change resolves this — it requires file decomposition or explicit contributor-facing comments.

**Tension 4: Structured data enforcement vs. format lock-in**
Agent 3 identified that `Reproduction steps` in triage-analyst and `Verdict` in reviewer would benefit from structured schemas. Agent 2 confirmed that YAML schemas for these fields would require hybrid documents that are harder to parse than either pure format. The resolution is prose-level constraints (explicit Constraints rules) rather than schema changes.

---

## Recommended Research for Phase 2

1. **Machine Output Section — design and validation**
   Specific questions: What exact token strings must be in `## Machine Output` for each affected agent? Which skills parse which tokens, and at which lines? Is adding a new section to agent output templates a MAJOR version change (new output section in agent output format contract)? Design the section format so it is grep-able and case-insensitive-match-safe.

2. **File decomposition feasibility for scaffold/fix-bugs**
   Specific questions: Can `skills/scaffold/SKILL.md` be split into phase files that Claude Code loads sequentially? Does the runtime support skill file includes or continuation loading? What are the inter-phase dependency contracts? Would decomposition require a MINOR version bump (new skill structure) or is it transparent?

3. **Config notation migration**
   Specific questions: Would changing example config templates from `| Key | Value |` to `Key: Value` colon notation require a documentation update in `core/config-reader.md`? Does `config-reader.md` explicitly describe the table parsing algorithm, and would colon notation require updating that contract? Would this be a PATCH (docs only) or MINOR change?

4. **Scaffolder step numbering audit**
   Map all step numbers in `agents/scaffolder.md` and `skills/scaffold/SKILL.md` for consistency. Identify all duplicated labels and produce a corrected numbering scheme before any edits.

5. **Bold text convention documentation**
   Agent 3 identified that `**bold**` is overloaded for 5 distinct structural roles (section labels, conditionals, constraints, definitions, sub-step labels) with no distinguishing convention. Phase 2 should determine whether adding a documented convention (e.g., ALL-CAPS bold for machine-parsed tokens, title-case for section labels) would meaningfully reduce LLM misinterpretation risk or whether the current contextual disambiguation is adequate.
