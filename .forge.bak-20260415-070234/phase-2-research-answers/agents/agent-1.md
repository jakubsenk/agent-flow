# Phase 2 — Format Comparison Matrix & Per-Category Recommendations

## 1. Format Comparison Matrix

Scores are 1 (worst) to 5 (best) for each dimension. Evaluated independently for each file category.

### 1.1 agents/ (21 files, ~31,800 tokens, 27% of budget)

| Dimension | Markdown+YAML frontmatter | Pure YAML body | JSON body |
|---|---|---|---|
| Token efficiency | 4 | 3 | 2 |
| LLM comprehension | 5 | 2 | 1 |
| Human editability | 5 | 2 | 1 |
| Ecosystem compatibility | 5 | 1 | 1 |
| Error resilience | 4 | 2 | 1 |
| **Total** | **23** | **10** | **6** |

Score rationale:
- Token efficiency: Markdown prose is near-optimal for narrative; the 7–13% structured fraction does not warrant a separate format.
- LLM comprehension: Numbered steps in markdown activate procedural following; YAML encodes process steps as data, degrading sequential adherence.
- Ecosystem compatibility: Claude Code runtime requires `.md` files and YAML frontmatter for agent discovery — YAML/JSON body is irrelevant because the file extension cannot change.
- Error resilience: Silent YAML indentation errors are common in multi-level process steps; markdown numbered lists fail visibly (obvious to contributor).

### 1.2 skills/ (28 files, ~75,500 tokens, 63% of budget)

| Dimension | Markdown+YAML frontmatter | Pure YAML body | JSON body |
|---|---|---|---|
| Token efficiency | 4 | 3 | 2 |
| LLM comprehension | 5 | 2 | 1 |
| Human editability | 4 | 2 | 1 |
| Ecosystem compatibility | 5 | 1 | 1 |
| Error resilience | 3 | 2 | 1 |
| **Total** | **21** | **10** | **6** |

Score rationale:
- Token efficiency: 4 not 5 because large files (scaffold 925 lines, fix-bugs 770 lines) contain structural redundancy (state.json instructions repeated ~15×) that inflates token cost independent of format — addressable by content restructuring, not format change.
- Error resilience: 3 rather than 4 because of known machine-token fragility (inline `APPROVE/BLOCK/NEEDS_DECOMPOSITION` signals embedded in prose without schema anchors) — this is a content problem, not a format problem, but it reduces the effective reliability score of the current format.
- Ecosystem compatibility: Same hard constraint as agents — `.md` file naming is non-negotiable.

### 1.3 core/ (11 files, ~8,200 tokens, 7% of budget)

| Dimension | Markdown prose | YAML schema | JSON schema |
|---|---|---|---|
| Token efficiency | 5 | 3 | 2 |
| LLM comprehension | 5 | 3 | 2 |
| Human editability | 5 | 3 | 1 |
| Ecosystem compatibility | 5 | 3 | 3 |
| Error resilience | 5 | 3 | 2 |
| **Total** | **25** | **15** | **10** |

Score rationale:
- Token efficiency: The inline typing convention (`**field** (type, required): description`) encodes four attributes in one natural-language phrase. YAML/JSON schema equivalents require 3–5× more tokens to encode the same information for typed field contracts.
- Ecosystem compatibility: Core files are consumed only by the LLM during pipeline runs, not by the Claude Code runtime directly — so format is not technically constrained. However, markdown is still dominant because prose wins on every other dimension.
- All scores for YAML and JSON are degraded vs. agents/skills because core files contain highly condensed contract prose where natural-language density beats schema verbosity.

### 1.4 examples/configs/ (8 files, ~3,600 tokens, 3% of budget)

| Dimension | Markdown tables (current) | Key:Value colon notation | Full YAML | JSON |
|---|---|---|---|---|
| Token efficiency | 2 | 4 | 5 | 3 |
| LLM comprehension | 4 | 4 | 3 | 3 |
| Human editability | 3 | 5 | 2 | 1 |
| Ecosystem compatibility | 5 | 5 | 3 | 2 |
| Error resilience | 4 | 4 | 2 | 1 |
| **Total** | **18** | **22** | **15** | **10** |

Score rationale:
- Token efficiency: `| Key | Value |` markdown tables are ~35–40% more expensive than `Key: Value` colon notation for the same data. Full YAML is theoretically most token-efficient but requires structural overhead (indentation, `---` delimiters) that erodes the advantage for small flat configs.
- Human editability: Markdown tables require manual pipe alignment; `Key: Value` is the most natural editing format. Full YAML has indentation-sensitive errors that are silent.
- Ecosystem compatibility: Both markdown and colon notation are compatible — config templates are read and written by humans following instructions, not parsed by a runtime.
- Error resilience: Markdown table misaligned pipes are cosmetically degraded but functionally valid. YAML indentation errors are silent failures. JSON trailing commas are fatal.

---

## 2. Per-Category Recommendations

### 2.1 agents/ — KEEP

**Verdict:** KEEP  
**Recommended format:** Markdown with YAML frontmatter (no change)

**Expected token savings:** 0 tokens / 0%  
Format change produces no material savings. The 7–13% structured fraction (frontmatter + output templates) is already in YAML, which is optimal for flat metadata. The 87–93% narrative fraction is optimal as prose.

**Quality impact:** Neutral if kept. Any migration to YAML/JSON body would significantly degrade LLM instruction-following fidelity for procedural steps, model selection signals, and constraint lists. The risk-adjusted expected value of format change is negative.

**Migration effort:** Not applicable (KEEP verdict). If migration were attempted: HIGH effort — 21 files, each requires rewriting process steps as YAML sequences, testing procedural adherence, and updating all downstream skills that invoke agents by name via the Task tool. No tooling available for automated migration; manual only.

**Risk assessment:** LOW (for KEEP decision). Ecosystem hard constraint independently blocks migration regardless of quality analysis. No action needed.

**Recommended improvements (not format changes):**
- Add `## Machine Output` section to triage-analyst, code-analyst, fixer, and reviewer output templates. This addresses the machine-token fragility (P1 from Phase 1) without format change.
- Fix duplicate `4b` step label in scaffolder.md (P3). This is a content correction, not a format issue.
- Remove or validate `Issues found: {count}` field in reviewer.md (P9). Add a Constraints rule requiring the count to match the listed issues.

---

### 2.2 skills/ — KEEP

**Verdict:** KEEP  
**Recommended format:** Markdown with YAML frontmatter (no change)

**Expected token savings:** 0 tokens / 0% from format change  
The 4–10% structured fraction does not justify format migration. The token cost driver (63% of total plugin budget) is instructional prose volume in large pipeline files, not format overhead. Reducing token cost requires reducing instruction complexity — a content question.

Separate from format: structural refactoring of large files (scaffold, fix-bugs) could reduce token cost by 15–25% within those files through elimination of repeated boilerplate and extraction of shared patterns into core contracts. Estimated savings: ~5,000–8,000 tokens (7–11% of skills budget, 4–7% of total plugin budget). This is achievable without any format change.

**Quality impact:** KEEP maintains current instruction-following quality. Any YAML/JSON migration for skill bodies would degrade decision-branch execution quality in the most complex pipeline files (fix-bugs, scaffold, implement-feature) — precisely the files where correct LLM behavior is most critical.

**Migration effort:** Not applicable (KEEP verdict). Ecosystem constraint independently blocks migration.

**Risk assessment:** LOW (for KEEP decision). Ecosystem hard constraint blocks migration. The actual reliability risks (machine-token fragility, large file scale) are content-level issues, not format issues.

**Recommended improvements (not format changes):**
- Add contributor note at top of fix-bugs/SKILL.md explaining the intentional repetition of state.json instructions (P4). Reduces cognitive load without removing functional content.
- Fix step labeling in fix-bugs/SKILL.md: rename `3b-tracker` to `3c` and resequence downstream sub-steps (P7). Requires audit of downstream references.
- Standardize pseudocode style in scaffold/SKILL.md: use fenced code blocks for all procedural pseudocode, unfenced prose for descriptive text only (P6).
- Consider decomposition of scaffold/SKILL.md into phase files when runtime include/continuation loading support is confirmed (P2). This is a phase 2 research question, not an immediate action.

---

### 2.3 core/ — KEEP

**Verdict:** KEEP  
**Recommended format:** Markdown prose (no change)

**Expected token savings:** 0 tokens / 0%  
Core files already use the most token-efficient format for their content type. The prose arrow notation (`key → field (default: N)`) and inline typing convention (`**field** (type, required): description`) encode more information per token than YAML or JSON equivalents. Migrating to YAML schema would increase token cost by an estimated 40–60% for contract documentation.

**Quality impact:** KEEP maintains the highest contract documentation density. YAML/JSON migration would increase token cost, reduce natural-language readability, and introduce schema verbosity with no LLM comprehension benefit (these files are read as reference context, not as procedural instructions).

**Migration effort:** Not applicable (KEEP verdict). Even without the ecosystem constraint, migration would be net-negative on every evaluation dimension.

**Risk assessment:** VERY LOW. No action needed. Core files are the most stable part of the plugin — low change frequency, no format issues identified.

---

### 2.4 examples/configs/ — HYBRID (optional)

**Verdict:** HYBRID (optional quality-of-life improvement, not required)  
**Recommended format:** `Key: Value` colon notation for config data sections (replacing `| Key | Value |` markdown tables)

**Expected token savings:**
- Plugin config templates: ~1,250 tokens across 8 files (35% of config category, 1% of total plugin budget)
- Consuming project CLAUDE.md (read on every pipeline invocation): ~260 tokens per pipeline run
- At 20 pipeline runs/day: ~5,200 tokens/day saved in consuming projects

The savings within the plugin itself are low (1% of total budget). The savings in consuming projects compound across every pipeline execution and are the primary justification for this change.

**Quality impact:** Neutral to slightly positive. `Key: Value` colon notation is easier to write and edit than pipe-delimited tables. Config template values with embedded commas (e.g., state transitions) become unambiguous — no longer competing with the pipe delimiter. The human-editability improvement is the strongest argument for this change.

One quality concern: the compound state transition cell format (`State transitions | In Progress: add label:in-progress, Blocked: add label:blocked, ... |`) is already ambiguous with the pipe delimiter. Converting to colon notation eliminates this ambiguity. This addresses P5 from Phase 1 as a side effect.

**Migration effort:** LOW  
- 8 config template files to update
- `core/config-reader.md` must be audited: if it describes a table-parsing algorithm, it must be updated to describe colon notation parsing. If it describes the semantic contract only (keys and defaults), no update is needed.
- `docs/reference/` and `docs/guides/` must be checked for screenshots or verbatim config examples that show table format
- `CLAUDE.md` config contract section documents the format by example — update examples
- No agent or skill logic changes required (the LLM parses config naturally in either format)
- Estimated effort: 4–6 hours of edits and documentation updates

**Risk assessment:** LOW-MEDIUM  
- Risk: Consuming projects with existing `| Key | Value |` CLAUDE.md configs continue to work because the LLM reads both formats natively. No breaking change.
- Risk: `core/config-reader.md` parsing contract update could be missed, creating doc/behavior drift. Mitigate by treating `core/config-reader.md` as a required edit in the same commit.
- Versioning: This is a PATCH change if applied to examples only (no contract change). If `core/config-reader.md` is updated to prescribe colon notation as the canonical format, it becomes a MINOR change (new optional alternative documented). It is NOT a MAJOR change because colon notation is a backward-compatible format — existing table-format configs continue to work.
- Do NOT migrate the examples if it would create user confusion about what format their existing CLAUDE.md should use. A migration guide note in `docs/guides/` is recommended.

---

## 3. Summary Decision Table

| Category | Verdict | Format Change? | Token Savings | Version Impact | Priority |
|---|---|---|---|---|---|
| agents/ | KEEP | No | 0% | None | Content fixes only (Machine Output sections, step numbering) |
| skills/ | KEEP | No | 0% direct; ~4–7% via content restructuring | None for format; PATCH for content fixes | Content fixes first, decomposition research second |
| core/ | KEEP | No | 0% (prose already optimal) | None | No action needed |
| examples/configs/ | HYBRID (optional) | Yes — tables → colon notation | ~35% in category; ~1% of plugin; ~260 tokens/run in consuming projects | PATCH (examples only) or MINOR (if core/config-reader.md updated) | Low urgency; high value per effort for consuming projects |

**Primary finding:** The correct action is not format migration — it is targeted content improvements to the existing markdown format. The highest-priority items are:
1. `## Machine Output` sections in triage-analyst, code-analyst, fixer, reviewer (reliability — addresses P1)
2. Scaffolder step numbering deduplication (correctness — addresses P3)
3. Config table → colon notation (token efficiency in consuming projects — addresses P5 as side effect, optional)

All format migration proposals for agents/, skills/, and core/ are blocked by the Claude Code ecosystem hard constraint and are additionally net-negative on quality metrics. No further evaluation of those migration paths is warranted.
