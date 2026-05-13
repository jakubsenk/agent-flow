# Phase 1 — Research Questions

{{PERSONA}}
You are a senior prompt engineer and LLM systems architect investigating serialization format trade-offs for LLM-consumed prompt files.

{{TASK_INSTRUCTIONS}}

## Context

The `ceos-agents` plugin is a pure-markdown Claude Code plugin. ALL its functional files (agent definitions, skill orchestration, core contracts, config templates) are markdown. These files are read directly by an LLM (Claude Code) as prompts — there is NO runtime parser, NO code that processes them. The LLM IS the runtime.

**File inventory (all .md):**
- `agents/` — 21 files, 125KB total. Format: YAML frontmatter (name, description, model, style) + markdown body (Goal, Expertise, Process, Constraints sections).
- `skills/` — 28 files (SKILL.md), 296KB total. Format: YAML frontmatter (name, description, allowed-tools, argument-hint) + markdown body with numbered steps, decision trees, templates, code blocks.
- `core/` — 11 files, 32KB total. Format: Pure markdown with Purpose, Input Contract, Process, Output Contract, Failure Handling sections.
- `examples/configs/` — 8 files, ~15KB total. Format: Markdown with `| Key | Value |` tables under `###` section headings.
- `docs/` — Human-readable documentation (NOT consumed as prompts by the LLM).

The user asks: Would YAML or JSON be better for any of these file categories? Would it reduce token consumption? Improve output quality?

## Research Questions

Answer ALL of the following questions with evidence and reasoning. For each question, cite specific files from the repository where relevant.

### Q1: Token Economics — Quantitative Comparison

For each file category (agents, skills, core, configs), take 2-3 representative files and estimate the token count difference if the same content were expressed in:
- (a) Current markdown format
- (b) YAML format
- (c) JSON format

Use Claude's tokenizer heuristic (~4 characters per token for English, ~3.5 for structured/symbolic content). Show the math.

**Important nuance:** Consider that some content is inherently natural language (process steps, constraint descriptions) and CANNOT be meaningfully converted to structured format without losing fidelity. Only structured/tabular content is a fair comparison target.

### Q2: LLM Comprehension Quality

Based on your knowledge of how Claude and other LLMs process different formats:
- Does markdown, YAML, or JSON lead to better instruction-following for procedural content (numbered steps, decision trees)?
- Does format affect the LLM's ability to extract structured data (like frontmatter fields, config key-value pairs)?
- Are there known failure modes where one format causes the LLM to hallucinate, skip steps, or misinterpret instructions?

### Q3: Claude Code Plugin Ecosystem Compatibility

- What format does Claude Code expect for skill files (SKILL.md)? Is there a hard requirement for markdown?
- What format does the YAML frontmatter use in agent files? Could the entire agent file be YAML?
- Does Claude Code's Task tool have format preferences for agent definitions?
- Would a format change break plugin discovery, marketplace listing, or installation?

### Q4: Hybrid Format Viability

Evaluate a hybrid approach where:
- Structured metadata (frontmatter, config tables, contract I/O specs) uses YAML or JSON
- Narrative content (process steps, constraints, expertise descriptions) stays as markdown

For each file category, identify what percentage of content is "structured" vs "narrative."

### Q5: Human Maintainability

- Which format is easiest for contributors to read and edit without tooling?
- Which format has the lowest error rate for manual editing (indentation errors in YAML, bracket matching in JSON, table alignment in markdown)?
- Consider that this plugin has NO build system — there is no linter or validator. Errors in files are only caught when the LLM reads them.

### Q6: Specific Problem Areas in Current Format

Examine the current markdown files for specific pain points:
- Are the `| Key | Value |` tables in config templates causing issues? (e.g., alignment, escaping)
- Is the YAML frontmatter in agents/skills adequate or could it carry more structured data?
- Are there cases where the markdown structure is ambiguous or could be misinterpreted by the LLM?
- Look at the largest files (scaffold SKILL.md at 49KB, fix-bugs SKILL.md at 38KB) — would a different format help manage complexity?

### Q7: Output Format (Agent Output Templates)

Several agents define output templates in their Process section (e.g., fixer's "Fix Report", triage-analyst's output). These are currently markdown code blocks. Would defining these as YAML/JSON schemas improve output consistency?

{{SUCCESS_CRITERIA}}
- Every question has a concrete, evidence-based answer
- Token count estimates use actual file content, not hypotheticals
- Ecosystem compatibility is verified against Claude Code's actual requirements
- The hybrid approach is evaluated per file category with percentage breakdowns
- Pain points in the current format are identified with specific file references

{{ANTI_PATTERNS}}
- Do NOT assume format change is inherently good — the null hypothesis is "markdown is fine"
- Do NOT ignore that the consumer is an LLM, not a parser — traditional format comparison logic does not apply
- Do NOT evaluate formats on criteria that are irrelevant for LLM consumption (e.g., "JSON has schema validation" is irrelevant when there is no validator)
- Do NOT conflate "human-authored configuration" (consumed once by a parser) with "LLM prompt content" (consumed every invocation as natural language context)

{{CODEBASE_CONTEXT}}
Key files to examine:
- `agents/fixer.md` — representative agent definition (6KB, YAML frontmatter + 4 sections)
- `agents/scaffolder.md` — largest agent (15KB)
- `skills/scaffold/SKILL.md` — largest skill (49KB)
- `skills/fix-bugs/SKILL.md` — second largest skill (38KB)
- `skills/analyze-bug/SKILL.md` — smallest skill (2KB)
- `core/config-reader.md` — core contract with structured I/O specs (6KB)
- `core/state-manager.md` — core contract (3KB)
- `examples/configs/github-nextjs.md` — config template with tables
- `CLAUDE.md` — main project instructions with Automation Config contract definition (13KB)
- `.claude-plugin/plugin.json` — already JSON, for ecosystem reference
