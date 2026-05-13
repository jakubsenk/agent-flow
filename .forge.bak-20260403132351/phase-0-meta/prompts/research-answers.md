# Phase 1: Research Answers

## RA-1: YouTrack Sub-Issue Parent Parameter via MCP

**Finding:** `docs/reference/trackers.md` Sub-Issue Capabilities table says:
- YouTrack: `parent: {issue-id}`
- The note says: "The parent parameter names are MCP tool conventions. The LLM uses these when invoking the tracker's MCP create-issue tool."

Step 4e in `skills/scaffold/SKILL.md` (line 533) says: "If tracker supports native sub-issues (YouTrack, Jira, Linear, Redmine): create sub-issue with parent set to epic issue ID using the tracker's native parent parameter."

**Root cause:** The instruction is correct but too implicit. The LLM executing the scaffold pipeline needs to:
1. Know it must pass `parent: {EPIC-ISSUE-ID}` as a parameter to the MCP create-issue tool
2. The current instruction says "using the tracker's native parent parameter" but does not tell the LLM to look up the parameter name from trackers.md or explicitly state it

**Fix direction:** Make Step 4e explicitly state the parameter name per tracker, or explicitly reference the trackers.md table with a concrete example.

## RA-2: YouTrack Cascade Close Behavior

**Finding:** Step 8b line 743: "For trackers with native sub-issues (YouTrack, Jira, Linear, Redmine): closing the parent epic typically cascades to children. Do NOT explicitly close story sub-issues."

**Root cause:** This is factually incorrect. YouTrack does NOT auto-cascade close from parent to children. Neither does Jira by default (it depends on workflow configuration). The user confirmed this from real-world experience.

**Fix direction:** Remove the cascade assumption. Explicitly close all story sub-issues for ALL trackers, not just GitHub/Gitea.

## RA-3: Existing Implementation Comment Patterns

**Finding:** The `implement-feature` pipeline has:
- Block comments posted via Block Comment Template (line 390-396)
- Post-verify comments (line 374-381): `[ceos-agents] Feature verified. Verify command: {command}. Output: {first 500 chars}.`
- But the general pattern is: the publisher creates a PR which links to the issue — the PR itself serves as the "what was done" record.

In scaffold pipeline: there is NO publisher step per-feature (features are committed locally, not PR'd). The only tracker interaction is: create issues (4e) and close issues (8b). There is no step that posts implementation results as comments.

**Fix direction:** Add a new step between Step 7 (implementation) and Step 8b (close) that posts an implementation summary comment on each completed story/epic issue. Use the `[ceos-agents]` prefix for consistency.

## RA-4: Language Fidelity in Agent Definitions

**Finding:** No agent has any language/locale instruction. The onboard skill has "Language rules" (line 191-196) but those are about config key naming (English keys), not about content language fidelity.

The project convention (from CLAUDE.md) is: "Language: Czech for user communication, English for all code/file content." But this is a convention for the ceos-agents repo itself, not a runtime instruction for generated projects.

When a user provides input in Czech, spec-writer and other agents may produce Czech text in specs and issue titles, but without explicit instruction to preserve diacritics, the LLM may drop them.

**Fix direction:** Add a language fidelity constraint to spec-writer (which generates spec content that flows into issue titles and descriptions): "When the user's input contains diacritics or non-ASCII characters, preserve them exactly. Never strip or simplify diacritics (e.g., never write 'uzivatel' when the input says 'uzivatel')." Also add this to the scaffold SKILL.md Step 4e for issue creation.

## RA-5: Design System Patterns in Scaffold

**Finding:** The scaffolder generates:
- Batch 1: Build config, entry point, project structure
- Batch 2: .gitignore, .env.example, database config
- Batch 3: Smoke test, test infra, linter config
- Batch 4: Dockerfile, .dockerignore, CI config
- Batch 5: README.md, CLAUDE.md

No mention of CSS, design system, UI framework, Tailwind, or any visual design tooling. The spec-writer mentions "UX requirements" in the acceptance criteria format section but has no design system section.

**Fix direction:**
1. In spec-writer: add an optional "Design & UX" section to the spec template for web/frontend projects. This should specify: CSS framework (Tailwind, etc.), color palette, typography, layout approach, responsive breakpoints.
2. In scaffolder: when stack includes a web framework, add a batch for design system setup (CSS framework config, base styles, layout components). Add a scorecard check for design system presence.
