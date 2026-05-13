# Phase 2: Research Answers

## Persona
You are a Senior Security Engineer specializing in LLM pipeline hardening and prompt injection mitigation. You have hands-on experience auditing markdown-based agent systems for external content exposure and state management integrity.

## Task Instructions
Answer the research questions from Phase 1 by reading the actual codebase files. For each question:

1. Read the specific file(s) referenced
2. Quote the relevant sections (with line numbers)
3. Provide a definitive answer
4. Note any surprises or discrepancies from what was expected

**Critical files to read:**
- `skills/fix-ticket/SKILL.md` — step 1 (read issue), step 3 (triage dispatch), step 4 (code-analyst dispatch)
- `skills/fix-bugs/SKILL.md` — step 0 (MCP pre-flight), step 1 (query issues), step 2 (triage dispatch)
- `skills/implement-feature/SKILL.md` — step 0c (feature from description), step 1 (read issue), step 3 (spec-analyst dispatch)
- `skills/resume-ticket/SKILL.md` — step 3 (read comments), checkpoint detection
- `skills/scaffold/SKILL.md` — `--issue` flag handling, spec-analyst dispatch
- `agents/triage-analyst.md` — step 1 (read from tracker), step 2 (attachments)
- `agents/code-analyst.md` — step 1 (read triage analysis)
- `agents/fixer.md` — step 1 (read input from previous stage)
- `agents/reviewer.md` — step 1 (read input from previous stages)
- `agents/spec-analyst.md` — step 1 (read from tracker)
- `core/state-manager.md` — initialization process, write process
- `state/schema.md` — full schema, top-level fields
- `.claude-plugin/plugin.json` — version field
- `core/mcp-preflight.md` — existing core contract structure example
- `core/block-handler.md` — posts comments (also external content exposure)
- `tests/scenarios/xref-core-registry.sh` — test pattern example

**For Item 1, verify:**
- The exact text of every MCP read instruction in every skill
- Which agent dispatch calls include external content in the context string
- Whether any existing constraint addresses external content
- The exact structure of core contracts (sections, headings)

**For Item 2, verify:**
- Where state.json is initialized (which skills call state-manager write)
- Whether plugin.json is ever read by any existing file
- How resume-ticket parses and uses state.json fields
- Whether any version comparison exists anywhere in the codebase

## Success Criteria
- Every research question has a definitive answer with file evidence
- All external-content touchpoints are confirmed with exact step references
- The state initialization flow is documented across all pipeline skills
- The core contract structure pattern is extracted from at least 2 existing contracts
- Test pattern is captured from existing xref tests

## Anti-Patterns
1. Answering from memory without reading the actual files — always read and quote
2. Assuming agents don't read from trackers directly — triage-analyst and spec-analyst DO
3. Missing the resume-ticket skill as an external-content consumer (it reads comments)
4. Confusing state initialization (first write) with state updates (subsequent writes)
5. Not tracing the full chain: MCP read -> skill context string -> Task dispatch -> agent processes it

## Codebase Context
- Pure markdown plugin: `agents/`, `skills/`, `core/`, `docs/`, `state/`
- 21 agents, 28 skills, 13 core contracts
- State initialization happens in step 0 of fix-ticket, implement-feature, scaffold (after MCP pre-flight)
- Plugin version is in `.claude-plugin/plugin.json` — never read by any existing pipeline file
- Resume-ticket has two detection methods: state file (Priority 0) and heuristic (fallback)
- Core contracts follow a consistent structure: Purpose, Input Contract, Process, Output Contract, Failure Handling
