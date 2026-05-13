# Phase 1: Research Questions

## RQ-1: YouTrack Sub-Issue Parent Parameter via MCP
**Question:** How does the YouTrack MCP server (`@vitalyostanin/youtrack-mcp`) accept parent parameters when creating issues? Is the parameter name `parent`, `parentIssue`, or something else?
**Why it matters:** Issue #2 — the instruction says "create sub-issue with parent set to epic issue ID using the tracker's native parent parameter" but the LLM may not know the exact MCP tool parameter name.
**Search strategy:** Check `docs/reference/trackers.md` Sub-Issue Capabilities table. Check Step 4e in scaffold SKILL.md for exact wording. Check if there are any MCP tool examples in the repo.

## RQ-2: YouTrack Cascade Close Behavior
**Question:** Does YouTrack actually cascade-close child issues when a parent issue is closed?
**Why it matters:** Issue #3 — Step 8b assumes it does, but the user reports it does not.
**Search strategy:** Check Step 8b wording. This is a factual claim about YouTrack behavior that needs to be corrected based on user feedback.

## RQ-3: Existing Implementation Comment Patterns
**Question:** Do other pipelines (fix-ticket, implement-feature) post comments to tracker issues after implementation? What format do they use?
**Why it matters:** Issue #4 — need to understand the pattern to add consistent commenting to scaffold pipeline.
**Search strategy:** Check `skills/implement-feature/SKILL.md` and `skills/fix-ticket/SKILL.md` for comment posting patterns.

## RQ-4: Language Fidelity in Agent Definitions
**Question:** Are there any existing language/locale instructions in any agent definitions or skills? How does the onboard skill handle language?
**Why it matters:** Issue #5 — need to understand if there's an existing pattern for language handling.
**Search strategy:** Check all agents and skills for language-related instructions. Check onboard skill's "Language rules" section.

## RQ-5: Design System Patterns in Scaffold
**Question:** What does the scaffolder currently generate for web projects (frontend/fullstack)? Is there any CSS or design-related output?
**Why it matters:** Issue #1 — need to understand what scaffolder currently produces to know where to add design quality instructions.
**Search strategy:** Check scaffolder.md Batch 1-5 for any UI/design content. Check spec-writer for any design/UX sections.
