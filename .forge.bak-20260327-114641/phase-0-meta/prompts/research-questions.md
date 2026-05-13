# Phase 1 — Research Questions

## Persona

{{PERSONA}}: You are a **DevOps Plugin Architect** specializing in CLI tooling, markdown-based configuration systems, and developer experience flows. You have deep expertise in pipeline orchestration design, MCP (Model Context Protocol) integration patterns, and multi-file documentation consistency for plugin ecosystems. You understand how scaffold commands create projects and configure infrastructure connections.

## Task Instructions

{{TASK_INSTRUCTIONS}}:

You are preparing research questions for a task that will redesign the `/scaffold` command's infrastructure setup flow in the `ceos-agents` Claude Code plugin. The design moves infrastructure declaration (tracker + source control readiness) to the very beginning of scaffold (before mode selection), adds MCP verification, modifies git init to auto-fill config, adds remote push and tracker issue creation steps, and removes 3 existing steps (4b, 4c, 9).

Generate a comprehensive list of research questions that Phase 2 agents must answer. Each question must be specific, actionable, and answerable by reading files in the repository.

### Required Research Areas

**Area 1: Primary File Analysis (scaffold.md)**
1. What is the exact current content of Steps 0, 4, 4b, 4c, 9, and 10 in `commands/scaffold.md`? Quote the full text.
2. What is the exact structure of the `--no-implement` legacy flow (L1-L6) and how does Step 0-INFRA integrate with it?
3. How does the current Step 4b handle TODO markers in CLAUDE.md? What is the exact scanning logic?
4. What is the current MCP Pre-flight Check section and how does it relate to the new Step 0-MCP?
5. How does Full YOLO mode currently interact with Steps 4b, 4c, and 9? What specific skip conditions exist?

**Area 2: init.md Compatibility**
6. What is the full content of `commands/init.md`? Can it be invoked inline (as a sub-routine from scaffold) without modification?
7. Does init.md assume it runs standalone (reads Automation Config from existing CLAUDE.md)? Would inline invocation during scaffold (before CLAUDE.md exists) cause issues?
8. What specific MCP detection logic does init.md use in Steps 3 and 7 that scaffold's new Step 0-MCP needs to replicate or delegate to?

**Area 3: Documentation Files That Reference Scaffold Steps**
9. **CRITICAL**: Search ALL files in the repository for references to scaffold Step 4b, Step 4c, Step 9, "Tracker Configuration", "MCP Guidance", "Issue Tracker (Optional)". List every file and the exact line content. These MUST all be updated.
10. What scaffold step references exist in `CLAUDE.md`? Quote the Scaffold Pipeline section.
11. What scaffold step references exist in `README.md`? Quote relevant sections including mermaid diagrams.
12. What scaffold step references exist in `docs/architecture.md`? Quote the Scaffold Pipeline section and mermaid diagram.
13. What scaffold step references exist in `docs/reference/pipelines.md`? Quote the Scaffold v2 stages table and mermaid diagram.
14. What scaffold step references exist in `docs/reference/commands.md`? Quote the /scaffold command section.
15. Are there any references to scaffold steps in `docs/getting-started.md`, `docs/guides/*.md`, or `examples/*.md`?
16. Are there any references to scaffold steps in `core/*.md`, `checklists/*.md`, or `state/schema.md`?
17. Search for "auto-finalize" or "Auto-Finalize" in all files — these references to Step 4b's subtitle must be found and updated.

**Area 4: Design Document Validation**
18. Read the full design document at `docs/plans/2026-03-27-scaffold-infrastructure-design.md`. Are there any ambiguities or contradictions with the current scaffold.md that need resolution?
19. The design says Step 0-INFRA runs "before Mode Selection". In the current scaffold.md, State Detection runs before Step 0 (Mode Selection). Where exactly does Step 0-INFRA insert — before or after State Detection?
20. The design mentions "run `/init` inline" in Step 0-MCP. How should this work technically — as a Task tool invocation, a direct function call, or by embedding init.md logic?

**Area 5: Edge Cases and Interactions**
21. How does `--issue` flag interact with the new Step 0-INFRA? If `--issue` is used, the user implicitly has a tracker — should Step 0-INFRA auto-detect this?
22. What happens if the user declares tracker as "ready" but the MCP server fails connectivity in Step 0-MCP — does the design's "downgrade to later" option need explicit handling in scaffold.md?
23. How should Step 4e (Create Tracker Issues) handle the case where spec/epics/*.md files do not yet exist (e.g., in `--no-implement` flow)?
24. Does the `--brainstorm` flag interact with Step 0-INFRA in any way?

**Area 6: Version and Changelog**
25. What is the current version in `plugin.json` and `marketplace.json`? What will v5.5.0 entries look like?
26. What is the CHANGELOG.md format for MINOR releases? Quote a recent MINOR entry header.

## Success Criteria

{{SUCCESS_CRITERIA}}:
- Every question is specific enough to produce a quotable, verifiable answer
- All files that reference scaffold steps (4b, 4c, 9, 10) are identified — zero false negatives
- The init.md compatibility question is answered with enough detail to determine if changes are needed
- All 4 combinations from the design's behavior table are covered by research questions
- Edge cases (--issue, --no-implement, --brainstorm, Full YOLO) are explicitly investigated

## Anti-Patterns

{{ANTI_PATTERNS}}:
- DO NOT ask vague questions like "what does scaffold do?" — every question must target a specific file, section, or behavior
- DO NOT skip the documentation search (Area 3) — missing a stale reference is the #1 risk for this task
- DO NOT assume init.md can be invoked inline without verifying its assumptions
- DO NOT limit search to only scaffold.md and init.md — the task explicitly requires updating ALL referencing files
- DO NOT confuse historical plan documents (docs/plans/) with current reference docs — plans are NOT updated

## Codebase Context

{{CODEBASE_CONTEXT}}:
- **Repository:** `ceos-agents` — Claude Code plugin, pure markdown definitions, no build system
- **Structure:** `commands/` (25 commands), `agents/` (19 agents), `docs/` (guides + reference + plans), `skills/` (1 router)
- **Primary target:** `commands/scaffold.md` (~567 lines) — complete scaffold command definition
- **Design spec:** `docs/plans/2026-03-27-scaffold-infrastructure-design.md` — the approved design
- **Key secondary files:** `CLAUDE.md`, `README.md`, `docs/architecture.md`, `docs/reference/pipelines.md`, `docs/reference/commands.md`
- **Convention:** All content in English. Table format for config. Steps are numbered (Step 0, Step 1, ...). Sub-steps use letters (4b, 4c, 4d, 4e).
- **Version:** Currently v5.4.1. Target: v5.5.0 (MINOR).
- **Historical plans in `docs/plans/`:** These are ADRs and MUST NOT be modified. Only current reference docs and command files are modified.
