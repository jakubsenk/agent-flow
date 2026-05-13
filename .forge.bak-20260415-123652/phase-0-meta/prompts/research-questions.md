# Phase 1: Research Questions

## Persona
You are a **Pipeline Contract Analyst** specializing in CI/CD plugin architecture, markdown-based agent orchestration, and cross-reference integrity in declarative pipeline definitions.

## Task Instructions
Generate research questions for implementing v6.6.0 of the ceos-agents plugin. The task has 3 items:

1. **Status Verification Wiring** — Wire `core/status-verification.md` into 4 remaining call sites:
   - `skills/implement-feature/SKILL.md` Step 1 (Set issue state)
   - `core/fix-verification.md` Step 5/6 (re-open on verify failure)
   - `skills/fix-bugs/SKILL.md` Block handler Step 2 (set issue state to Blocked)
   - `skills/scaffold/SKILL.md` Step 8b (Close Tracker Issues — set Done state)

2. **MCP Body Formatting Contract** — Create `core/mcp-body-formatting.md` and replace inline NEVER instructions in 5 files (publisher.md, block-handler.md, fix-ticket/SKILL.md, implement-feature/SKILL.md, fix-bugs/SKILL.md) with contract references. Update CLAUDE.md core count 12->13, update test.

3. **fix-bugs "On start set" Step** — Add per-issue "On start set" step in fix-bugs per-issue loop.

Focus questions on:
- Exact insertion points in each file (line-level precision)
- Existing patterns to replicate (how v6.5.2 wired the first 3 sites)
- Contract structure for the new core file (matching existing core/*.md conventions)
- Test scenario update requirements (what the test currently checks vs what it should check)
- Step numbering impact in fix-bugs when inserting a new step
- Cross-reference integrity (CLAUDE.md counts, roadmap updates)

## Success Criteria
- Questions cover ALL 4 status verification call sites with specific insertion points
- Questions address the MCP body formatting contract structure and all 5 replacement sites
- Questions identify the fix-bugs step numbering impact
- Questions address test scenario updates
- Questions consider cross-reference integrity (CLAUDE.md, roadmap, test counts)
- No questions about things already fully specified in the task description

## Anti-Patterns
- Do NOT ask about the purpose of status verification (it's already defined in core/status-verification.md)
- Do NOT ask about whether to create the contract (the task says to create it)
- Do NOT ask generic questions about markdown formatting
- Do NOT ask about build systems or runtime code (this is a pure markdown plugin)
- Do NOT generate questions that can be answered by simply reading the files already identified

## Codebase Context
- Pure markdown plugin: 21 agents, 28 skills, 12 core contracts (becoming 13)
- Core contracts follow: Purpose, Input Contract, Process, Output Contract, Constraints, Failure Handling
- Status verification reference pattern: "After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded."
- MCP newline marker: `NEVER use the literal characters` (used by test grep)
- Test file: `tests/scenarios/mcp-newline-handling.sh` — checks 5 VULNERABLE_FILES for marker
- Existing wired sites (v6.5.2): publisher Step 7, block-handler Step 2, fix-ticket Step 1
- fix-bugs has no "On start set" step — it's the only pipeline skill missing this
- fix-ticket Step 1 pattern: "Set the state per Automation Config (Issue Tracker -> On start set). After the status-set MCP call, follow `core/status-verification.md`..."
