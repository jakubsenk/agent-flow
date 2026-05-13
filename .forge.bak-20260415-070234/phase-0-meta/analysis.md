# Phase 0 — Task Analysis

## Task Type Classification

**Primary:** research
**Secondary:** refactor (conditional — only if research findings justify changes)

**Rationale:** The user wants a structured analysis of whether the plugin's file formats (markdown for agent definitions, skills, core contracts, config templates) should change to YAML or JSON. This is fundamentally a research question with a conditional implementation tail. The research must produce actionable, evidence-based recommendations before any refactoring occurs.

## Complexity Assessment

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Scope | 4/5 | Touches potentially ALL files in the repo (21 agents, 28 skills, 11 core, 8 configs, docs, CLAUDE.md). Even a partial format change affects dozens of files. |
| Ambiguity | 4/5 | The question is open-ended — "would YAML/JSON be better?" requires defining "better" across multiple axes. No predetermined answer exists. LLM-as-runtime is an unusual domain with limited prior art for format optimization. |
| Risk | 3/5 | This is a pure-markdown plugin with no build/runtime. Format changes cannot break production code, but they CAN degrade prompt quality if the LLM interprets a new format worse. Risk is in prompt quality regression, not system breakage. |
| **Composite** | **3.7/5** | |

## Fast-Track Eligibility

**Eligible:** NO

**Precondition evaluation:**
- Single-file change? NO — potential changes span 60+ files across 5 directories.
- Obvious fix? NO — this is an open-ended research question with no predetermined answer.
- Low risk? MODERATE — no runtime breakage risk, but prompt quality regression risk.
- Under 50 lines of change? NO — any format migration would be hundreds of lines.

**Verdict:** Full pipeline required. Research phase is critical — must NOT skip directly to implementation.

## Domain Identification

**Primary domain:** LLM prompt engineering / token economics
**Secondary domains:** Developer tooling UX, configuration management, serialization formats

**Key domain insight:** This plugin is NOT consumed by a parser — it is consumed by an LLM (Claude Code). The "runtime" is a large language model reading markdown files as system prompts. This fundamentally changes the format evaluation calculus:
- Token efficiency matters because every token in a prompt costs money and consumes context window.
- But LLM comprehension quality matters MORE — a format that saves 10% tokens but reduces instruction-following quality by 5% is a net negative.
- There is no "parsing speed" or "type safety" benefit — the LLM doesn't parse, it reads.

## Codebase Context Assessment

**Repository structure:**
- 21 agent definitions in `agents/` (125KB total, markdown with YAML frontmatter)
- 28 skills in `skills/` (296KB total, pure markdown with numbered steps)
- 11 core contracts in `core/` (32KB total, pure markdown)
- 8 config templates in `examples/configs/` (markdown with `| Key | Value |` tables)
- Plugin metadata in `.claude-plugin/` (already JSON)
- Total prompt content: ~453KB of markdown

**File categories by function:**
1. **Agent prompts** (agents/*.md): System prompts for LLM agents. YAML frontmatter + natural language body.
2. **Skill orchestration** (skills/*/SKILL.md): Detailed step-by-step instructions for Claude Code. Natural language with decision trees, templates, code blocks.
3. **Core contracts** (core/*.md): Shared patterns describing input/output contracts. Structured but narrative.
4. **Config templates** (examples/configs/*.md): User-facing templates with `| Key | Value |` tables.
5. **Documentation** (docs/**): Human-readable guides and references. Not consumed by LLM as prompts.

**Critical observation:** Categories 1-4 are LLM-consumed prompts. Category 5 is human-consumed documentation. Format evaluation should focus on categories 1-4.

## Confidence Scoring

| Question | Score | Reasoning |
|----------|-------|-----------|
| Do I understand what needs to be built/changed? | 0.75 | Clear research question, but implementation scope depends entirely on research findings. The "what changes" is unknown until Phase 1-2 complete. |
| Do I know where in the codebase to make changes? | 0.90 | File locations are fully mapped. The question is which categories benefit from format change, not where they are. |
| Are requirements unambiguous enough to proceed? | 0.65 | The user's question is intentionally open-ended. We must define evaluation criteria ourselves. Multiple valid conclusions are possible. |

**Composite confidence:** 0.65 (min of all scores)

This is below the 0.7 threshold, but the nature of a research task means ambiguity is expected and will be resolved in Phase 1 (research). No clarification from the user is needed — the task IS to resolve the ambiguity.

## Security Evaluation

**Not applicable.** This is a research/refactor task on markdown prompt files. No code execution, no API keys, no user data, no network access involved. Security tier evaluation skipped.

## Key Research Questions (for Phase 1)

1. **Token economics:** How do markdown, YAML, and JSON compare in token count for equivalent content? Measure on actual agent/skill/core files.
2. **LLM comprehension:** Does format affect instruction-following quality? Are there studies or empirical evidence?
3. **Hybrid approach viability:** Could structured metadata (frontmatter, config tables) use YAML/JSON while narrative sections stay markdown?
4. **Ecosystem compatibility:** Claude Code's skill format uses markdown with YAML frontmatter. Would changing break compatibility?
5. **Human maintainability:** Which format is easiest for contributors to read and edit?
6. **Incremental migration:** If changes are warranted, can they be applied incrementally to one file category at a time?

## Implementation Boundary

**CRITICAL CONSTRAINT:** If research concludes "keep markdown" (partially or fully), that IS a valid outcome. The pipeline must NOT force changes where none are warranted. The research phase must produce a clear recommendation matrix per file category, and only categories with clear benefit get changed in the execution phase.
