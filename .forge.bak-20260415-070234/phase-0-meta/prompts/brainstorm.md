# Phase 3 — Brainstorm

{{PERSONA}}
You are a panel of three expert agents debating format strategy for the ceos-agents plugin. Each agent has a distinct perspective.

{{TASK_INSTRUCTIONS}}

## Brainstorm Setup

Based on the research synthesis from Phase 2, three agents debate the implementation approach. Each agent argues from their perspective, then a judge selects the best approach.

### Agent A: The Token Economist
Argues for maximum token reduction. Favors structured formats (YAML/JSON) wherever they save tokens. Values efficiency above all.

### Agent B: The Prompt Quality Advocate
Argues for maximum LLM comprehension quality. Favors whatever format the LLM understands best. Will sacrifice token efficiency for better instruction-following. Points out that markdown IS the native language of LLM training data.

### Agent C: The Pragmatic Maintainer
Argues for minimal disruption and maximum maintainability. Favors changes only where the current format has demonstrable problems. Points out that every format change is a migration with risk and future maintenance cost.

## Debate Topics

1. **Agent definitions (agents/*.md):** The YAML frontmatter is already structured. Should the body also be structured (full YAML)? Or is the current hybrid (YAML frontmatter + markdown body) optimal?

2. **Config templates (examples/configs/*.md):** The `| Key | Value |` markdown tables are arguably the worst of all worlds — hard to parse for humans AND LLMs. Should these be pure YAML?

3. **Core contracts (core/*.md):** These have structured sections (Input Contract, Output Contract) mixed with narrative (Process, Failure Handling). Is a hybrid format viable here?

4. **Skill files (skills/*/SKILL.md):** These are the largest files (up to 49KB) and most natural-language-heavy. Is there ANY format that would improve them, or is markdown clearly optimal for procedural instructions?

5. **Output templates in agent definitions:** Should the "expected output" format blocks in agent Process sections be formalized as schemas (YAML/JSON) rather than markdown code blocks?

## Judge Instructions

After all three agents have argued, the judge must:
1. Score each agent's argument per topic (1-5 for persuasiveness)
2. Select the winning approach per topic with reasoning
3. Produce a unified recommendation that the spec phase can formalize

{{SUCCESS_CRITERIA}}
- All three perspectives are genuinely argued (not strawmen)
- Each debate topic gets arguments from all three agents
- The judge provides a clear, reasoned verdict per topic
- The unified recommendation is actionable and specific

{{ANTI_PATTERNS}}
- Do NOT let one perspective dominate all topics — different topics may have different winners
- Do NOT ignore the ecosystem constraint (Claude Code expects markdown SKILL.md files)
- Do NOT propose changes without considering the migration cost in a no-build-system repo
- Do NOT conflate "theoretically better" with "practically worth doing"

{{CODEBASE_CONTEXT}}
Focus on concrete examples from the codebase:
- `agents/fixer.md` frontmatter vs body
- `examples/configs/github-nextjs.md` table format
- `core/config-reader.md` structured contracts
- `skills/scaffold/SKILL.md` large procedural file
- `skills/analyze-bug/SKILL.md` small skill for comparison
