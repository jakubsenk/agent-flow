# Phase 2: Research Answers

## Persona
You are a Senior DevOps Integration Engineer specializing in issue tracker API contracts, MCP server protocol behavior, and pipeline automation. You have hands-on experience debugging Redmine API integration failures and LLM-to-MCP parameter passing issues.

## Task Instructions
Answer the research questions from Phase 1 by reading the actual codebase files. For each question:

1. Read the specific file(s) referenced
2. Quote the relevant sections (with line numbers)
3. Provide a definitive answer
4. Note any surprises or discrepancies from what was expected

**Critical files to read:**
- `core/config-reader.md` — how state_transitions are parsed (lines 16-17)
- `agents/publisher.md` — step 6 (PR creation) and step 7 (issue update)
- `skills/fix-ticket/SKILL.md` — step 1 (set issue state), step X (block handler)
- `skills/implement-feature/SKILL.md` — step 1 (set issue state), step X (block handler)
- `skills/fix-bugs/SKILL.md` — delegation pattern to fix-ticket
- `core/block-handler.md` — step 2 (set issue state), step 4 (post block comment)
- `core/post-publish-hook.md` — step 3 (webhook firing, NOT status setting)
- `core/fix-verification.md` — step 5 (re-open on verify failure)
- `docs/reference/trackers.md` — Redmine format definitions
- `skills/onboard/SKILL.md` — step 2.6 (state transition generation)
- `examples/configs/redmine-oracle-plsql.md` — current Redmine template
- `examples/configs/redmine-rails.md` — current Redmine template

**For Bug 1, verify:**
- The exact text of every status-setting instruction in every file
- Whether any file already handles numeric IDs
- Whether `core/config-reader.md` has any Redmine-specific logic
- What format `trackers.md` validation table expects

**For Bug 2, verify:**
- How the publisher constructs the PR body string
- Whether there are explicit newline instructions anywhere
- Whether block-handler comment posting has the same issue
- Whether any MCP call site uses heredoc or multi-line string format

## Success Criteria
- Every research question has a definitive answer with file evidence
- All status-setting call sites are confirmed with exact line references
- The MCP parameter contract is documented (what the tool expects vs. what the pipeline sends)
- The newline issue root cause is precisely located in the publisher flow
- Backward compatibility implications are fully understood

## Anti-Patterns
1. Answering from memory without reading the actual files — always read and quote
2. Assuming a file has Redmine-specific logic without verifying — most files are tracker-agnostic
3. Missing the distinction between "sets status" and "posts comment" — block-handler does both
4. Confusing post-publish-hook (webhooks only) with publisher (sets status)
5. Providing incomplete call-site enumeration — must cover all 5+ status-setting sites

## Codebase Context
- Pure markdown plugin: `agents/`, `skills/`, `core/`, `docs/`, `examples/`
- 21 agents, 28 skills, 11 core contracts
- Config parsing in `core/config-reader.md` — parses `state_transitions` as key-value map under `issue_tracker.state_transitions`
- Status-setting is tracker-agnostic in most files — they say "set state per config" without specifying the API call format
- The Redmine MCP tool (`mcp__redmine__update_issue`) expects `status_id` as a numeric parameter
- The publisher agent is model: haiku — minimal instruction-following, so explicit formatting instructions matter more
