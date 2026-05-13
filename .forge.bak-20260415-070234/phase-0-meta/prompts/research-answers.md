# Phase 2 — Research Synthesis

{{PERSONA}}
You are a senior systems architect synthesizing research findings into actionable recommendations for the ceos-agents plugin format evaluation.

{{TASK_INSTRUCTIONS}}

## Input

You have the research answers from Phase 1 (research-questions). Synthesize them into a structured recommendation.

## Synthesis Requirements

### 1. Format Comparison Matrix

Create a matrix evaluating each format (Markdown, YAML, JSON) against each file category (agents, skills, core, configs) on these dimensions:
- Token efficiency (fewer tokens = better, score 1-5)
- LLM comprehension (better instruction-following = better, score 1-5)
- Human editability (easier to maintain = better, score 1-5)
- Ecosystem compatibility (works with Claude Code = better, score 1-5)
- Error resilience (fewer silent errors = better, score 1-5)

### 2. Per-Category Recommendation

For each file category, produce a clear recommendation:
- **KEEP** (markdown is optimal or change is not justified)
- **MIGRATE** (a different format is clearly better — specify which)
- **HYBRID** (structured parts should change, narrative should stay markdown — specify boundaries)

Each recommendation must include:
- The recommended format
- Expected token savings (absolute and percentage)
- Expected quality impact (positive, neutral, or negative — with reasoning)
- Migration effort estimate (number of files, estimated lines changed)
- Risk assessment (what could go wrong)

### 3. Priority Ordering

If multiple categories warrant changes, rank them by:
- Impact (token savings * invocation frequency)
- Risk (lower risk = do first)
- Effort (less effort = do first)

### 4. Go/No-Go Decision

Based on the full analysis, make a clear recommendation:
- **GO:** Proceed with implementation (specify which categories and in what order)
- **NO-GO:** Keep markdown everywhere (explain why the costs outweigh benefits)
- **PARTIAL GO:** Implement changes for some categories only (specify which)

Include a sentence summarizing the single most important insight from the research.

{{SUCCESS_CRITERIA}}
- Every file category has a clear KEEP/MIGRATE/HYBRID recommendation
- Token savings estimates are grounded in Phase 1 measurements
- The go/no-go decision is unambiguous
- If GO or PARTIAL GO, the implementation scope is fully defined

{{ANTI_PATTERNS}}
- Do NOT recommend changes that would break Claude Code plugin compatibility
- Do NOT recommend format changes for content that is primarily natural language
- Do NOT over-optimize for token savings at the cost of LLM comprehension quality
- Do NOT let sunk-cost bias ("we already wrote it in markdown") prevent warranted changes

{{CODEBASE_CONTEXT}}
Same as Phase 1. The synthesis should reference specific files and measurements from the research answers.
