# Phase 1: Research Questions

## Persona
You are a Senior Research Engineer (12+ years) with deep experience in LLM tool-call contracts, JSON Schema, agent-orchestration frameworks (LangChain, AutoGen, OpenAI Assistants, Anthropic Tool Use), and IaC/declarative-spec design. You read primary sources, never marketing pages. You have a healthy skepticism toward "everyone is doing X" arguments unless backed by concrete examples in production agent systems.

## Codebase Context
ceos-agents Claude Code plugin v8.0.0 (released 2026-04-27, on main branch). Pure markdown plugin - no build system, no dependencies. 18 agents under agents/*.md, each with YAML frontmatter (name, description, model, style) and body sections in fixed order: ## Goal -> ## Expertise -> ## Process (numbered steps) -> ## Constraints (NEVER rules + Block Comment Template). Outputs are prose-embedded markdown code blocks inside Process "Output:" steps - de-facto contracts (e.g., ## Triage Analysis, ## Fix Report, ## Code Review), but they are NOT machine-validated and naming is inconsistent. Mode-dependent input pattern: agents read context flags like Mode: feature / Mode: scaffold for implicit polymorphism. EXTERNAL INPUT START/END markers are mandatory in every agent for prompt-injection defense.

29 skills under skills/, each with SKILL.md (orchestration) that dispatches agents via the Claude Code Task tool. core/agent-override-injector.md is the SOLE extension point for per-project customization - it reads customization/{agent-name}.md and appends as ## Project-Specific Instructions. v8.0.0 customization/ overrides MUST keep working unmodified - this is the hard backward-compat constraint.

Tests: bash harness at tests/harness/run-tests.sh, 297 scenarios in tests/scenarios/*.sh. Each scenario sets REPO_ROOT via $(cd "$(dirname "$0")/../.." && pwd), defines a fail() helper, runs assertions via grep -qE / find / wc -l / diff -q, exits 0=PASS, 77=SKIP, anything else=FAIL. Naming convention: {prefix}-{topic}-{aspect}.sh (e.g., v8-agents-enumeration.sh, v8-agents-analyst-shape.sh, frontmatter-completeness.sh, read-only-agents.sh).

Cross-File Invariants section in CLAUDE.md currently has 3 invariants (License SPDX, Maintainer email, Issue/PR template parity). New I/O contract invariants must be added here.

Versioning Policy in CLAUDE.md: agent OUTPUT format contract changes that external tooling/Agent Overrides may parse = MAJOR. Adding optional config sections = MINOR. Adding required keys to Automation Config = MAJOR. The version target is v9.0.0 per user MEMORY (sub-projekt H), but whether the increment is MAJOR or MINOR depends on whether the new I/O contracts are mandatory or optional.

Docs reference structure (docs/reference/): agents.md, automation-config.md, skills.md, pipeline.md, pipelines.md, hooks.md, trackers.md, config.md, execution-loop.md - these must be kept in sync with agent shape (per feedback_doc_completeness.md doc-count drift discipline).

## Task Instructions
Generate 8-12 research questions that will, when answered in Phase 2, give the brainstorm phase enough grounding to produce a defended recommendation on:
1. WHETHER to formalize agent I/O contracts at all (the "do nothing" baseline must be a credible option).
2. HOW to formalize them (schema language, location in agent files, validation mechanism).
3. Backward-compatibility strategy for v8.0.0 customization/ Agent Overrides.
4. Versioning impact (MAJOR vs MINOR per CLAUDE.md Versioning Policy).
5. Test strategy for the bash harness.

Each question must be:
- ANSWERABLE from public sources or codebase inspection (not "what is the meaning of contracts" - too abstract).
- LOAD-BEARING for at least one design decision in Phase 3 brainstorm.
- DISTINCT - no duplicates, no near-duplicates.

Anti-patterns to avoid:
- "What is JSON Schema?" - too basic, well-known.
- "What is the best contract format?" - unanswerable without context; rephrase as "What contract format does Anthropic Tool Use use, and what are its tradeoffs?".
- Questions that pre-suppose the answer (e.g., "Why is JSON Schema better than YAML?").
- Questions about ceos-agents internals that are already in the codebase context above.

## Required Output Sections
Produce a numbered list of 8-12 questions, each with:
- **Question:** the precise question text
- **Why it matters:** which design decision in Phase 3 this question informs
- **Source hint:** where to look (e.g., "Anthropic docs on tool use", "AutoGen agent_io_contracts.py", "ceos-agents v8 forge run archive", "JSON Schema 2020-12 spec")

## Success Criteria
- Exactly 8-12 questions
- All five concern areas above are covered (whether/how/backcompat/versioning/tests) - at least 1 question per area
- Each question is unambiguous and has a recognizable answer shape
- No question is redundant with codebase context already provided

## Anti-Patterns
1. Researching what JSON Schema IS instead of how it is USED in agent contracts.
2. Asking yes/no questions when a comparison would yield more signal.
3. Skipping the "do nothing" baseline question (the user explicitly said "rozhodnout jestli to delat").
4. Asking about Claude Code internals that are not publicly documented.
5. More than one question per concern area without clear distinction.
6. Questions that require speculation rather than evidence.
